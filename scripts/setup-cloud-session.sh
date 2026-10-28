#!/usr/bin/env bash
# Sets up R for a Claude Code cloud session on Powerkit, so a new session
# starts with R and every package ready instead of installing them itself.
# Put this line in the cloud environment's "Setup script" (the setup script
# doesn't start in the repository folder, so the path is absolute):
#
#   bash /home/user/Powerkit/scripts/setup-cloud-session.sh || true
#
# The environment caches the result when setup finishes within about five
# minutes, so later sessions start with R already on disk.
#
# Safe to run again: it stops early if R and the packages are already there.
#
# Fast route (about a minute): copy R out of the image CI already builds,
# ghcr.io/joelthornton/powerkit-ci (.github/ci/Dockerfile). That image has
# the R version in renv.lock and every locked package at its locked version,
# so a session tests against what CI tests against and nothing is compiled.
# The image is public, so no login is needed. Its tag is the hash of
# renv.lock and the Dockerfile that ci-image.yaml computes, so the copy
# matches the lockfile on the checked-out branch; if that image hasn't been
# built yet, the last tag the registry lists is used. Only R's own folder
# (/usr/local/lib/R, which holds the packages), R and Rscript, and shared
# libraries (and their alternatives links) the session doesn't already have
# are copied; nothing already there is overwritten (both are Ubuntu 24.04).
#
# The image's layers download from pkg-containers.githubusercontent.com,
# which the cloud environment's network must allow (Network access: Custom,
# with the host under Allowed domains and the default list included). If it
# can't be reached, the script says so and exits without failing: the
# fallback, scripts/setup-cloud-session-apt.sh, builds R 4.3 and the
# packages from source in 20-30 minutes, too long for a setup script (it
# would hold up every session start and never be cached). Pass
# --build-from-source to run that fallback here instead.
set -euo pipefail

cd "$(dirname "$0")/.."

IMG="joelthornton/powerkit-ci"
sudo_cmd=""; [ "$(id -u)" -ne 0 ] && sudo_cmd="sudo"

if command -v Rscript >/dev/null 2>&1 &&
   R_PROFILE_USER="$HOME/.Rprofile-powerkit" Rscript -e 'loadNamespace("power4mome")' >/dev/null 2>&1; then
  echo "powerkit R setup: already done"
  exit 0
fi

ghcr() {
  curl -fsSL -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.docker.distribution.manifest.list.v2+json" \
    "https://ghcr.io/v2/$IMG/$1"
}
json() { python3 -c "import sys, json; m = json.load(sys.stdin); $1"; }

from_ci_image() {
  token="$(curl -fsS "https://ghcr.io/token?scope=repository:$IMG:pull" |
    json 'print(m["token"])')" || return 1

  tag="$(python3 -c '
import hashlib
h = b"".join(hashlib.sha256(open(f, "rb").read()).digest()
             for f in ["renv.lock", ".github/ci/Dockerfile"])
print(hashlib.sha256(h).hexdigest()[:16])')"
  if ! index="$(ghcr "manifests/$tag" 2>/dev/null)"; then
    echo "powerkit R setup: no CI image for this renv.lock yet; using the newest listed" >&2
    tag="$(ghcr tags/list | json 'print(m["tags"][-1])')" || return 1
    index="$(ghcr "manifests/$tag")" || return 1
  fi

  # A multi-platform index points to one manifest per platform: take amd64.
  manifest="$index"
  digest="$(printf '%s' "$index" | json '
print("" if "layers" in m else next(x["digest"] for x in m["manifests"]
      if x.get("platform", {}).get("architecture") == "amd64"))')"
  if [ -n "$digest" ]; then manifest="$(ghcr "manifests/$digest")" || return 1; fi
  layers="$(printf '%s' "$manifest" | json 'print(" ".join(l["digest"] for l in m["layers"]))')"

  stage="$(mktemp -d)"
  for layer in $layers; do
    ghcr "blobs/$layer" > "$stage/layer.tgz" || { rm -rf "$stage"; return 1; }
    tar -xzf "$stage/layer.tgz" -C "$stage" --no-same-owner \
      --wildcards 'usr/local/*' 'usr/lib/x86_64-linux-gnu/*' 'etc/alternatives/*' 2>/dev/null || true
    rm -f "$stage/layer.tgz"
  done
  [ -x "$stage/usr/local/lib/R/bin/exec/R" ] || { rm -rf "$stage"; return 1; }

  $sudo_cmd mkdir -p /usr/local/lib/R
  $sudo_cmd cp -a "$stage/usr/local/lib/R/." /usr/local/lib/R/
  $sudo_cmd cp -a "$stage/usr/local/bin/R" "$stage/usr/local/bin/Rscript" /usr/local/bin/
  $sudo_cmd cp -an "$stage/usr/lib/x86_64-linux-gnu/." /usr/lib/x86_64-linux-gnu/
  # BLAS and LAPACK are reached through Debian's alternatives links.
  [ -d "$stage/etc/alternatives" ] && $sudo_cmd cp -an "$stage/etc/alternatives/." /etc/alternatives/
  $sudo_cmd ldconfig
  rm -rf "$stage"

  # The image's default package source (Posit Package Manager) is blocked
  # here, so installs go to the CRAN mirror the network allows; renv isn't
  # activated because the packages are in R's own library.
  cat > "$HOME/.Rprofile-powerkit" <<'RPROF'
options(repos = c(CRAN = "https://cran.r-project.org"))
RPROF
  grep -q "Rprofile-powerkit" "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" <<ENV
export R_PROFILE_USER="$HOME/.Rprofile-powerkit"
export RENV_ACTIVATE_PROJECT=FALSE
export NOT_CRAN=true
export LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV
  export R_PROFILE_USER="$HOME/.Rprofile-powerkit" RENV_ACTIVATE_PROJECT=FALSE

  # The engine itself, so the app tests find it.
  ${sudo_cmd:+$sudo_cmd -E} /usr/local/bin/R CMD INSTALL --no-test-load engine >/dev/null ||
    echo "powerkit R setup: engine not installed; run R CMD INSTALL engine" >&2
  /usr/local/bin/Rscript -e 'for (p in c("power4mome", "Spower", "Superpower", "testthat")) loadNamespace(p)' \
    -e 'cat("powerkit R setup done:", R.version.string, "from the CI image", commandArgs(TRUE), "\n")' "$tag"
}

if ! from_ci_image; then
  if [ "${1:-}" = "--build-from-source" ]; then
    echo "powerkit R setup: CI image not reachable; building from source instead" >&2
    bash scripts/setup-cloud-session-apt.sh
  else
    echo "powerkit R setup: CI image not reachable (is pkg-containers.githubusercontent.com allowed?)." >&2
    echo "Run: bash scripts/setup-cloud-session-apt.sh to build R from source (20-30 minutes)." >&2
  fi
fi
