#!/usr/bin/env bash
# Sets up R for a Claude Code cloud session on Powerkit, so each new thread
# doesn't rebuild it by hand. Paste the line below into the project's cloud
# environment "Setup script" (Project settings > environment):
#
#   bash scripts/setup-cloud-session.sh
#
# What it does, and why:
# - Installs R from Ubuntu's apt (R 4.3.x). The cloud network blocks the
#   CRAN apt repository and Posit's binaries, so a newer R isn't available.
#   CI uses the R version in renv.lock; local results never count as
#   validation.
# - Installs the packages in _dependencies.R from cran.r-project.org (the
#   only CRAN mirror the network allows), from source, into a user library.
# - power4mome declares R >= 4.4. It is installed from source with that line
#   relaxed and a definition of `%||%` added (base R only has it from 4.4).
#   This patched copy is for running tests locally only.
# Safe to run twice: installed packages are skipped.
set -euo pipefail

LIB="${POWERKIT_R_LIB:-$HOME/R/powerkit-lib}"
mkdir -p "$LIB"

if ! command -v Rscript >/dev/null 2>&1; then
  sudo_cmd=""; [ "$(id -u)" -ne 0 ] && sudo_cmd="sudo"
  $sudo_cmd apt-get update -qq
  DEBIAN_FRONTEND=noninteractive $sudo_cmd apt-get install -y -qq \
    r-base r-base-dev libcurl4-openssl-dev libssl-dev libxml2-dev \
    libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev \
    libpng-dev libtiff5-dev libjpeg-dev libv8-dev cmake >/dev/null
fi

# Profile: the CRAN mirror the network allows, and the user library first.
PROFILE="$HOME/.Rprofile-powerkit"
cat > "$PROFILE" <<RPROF
options(repos = c(CRAN = "https://cran.r-project.org"), Ncpus = $(nproc))
.libPaths(c("$LIB", .libPaths()))
RPROF
grep -q "R_PROFILE_USER" "$HOME/.bashrc" 2>/dev/null || cat >> "$HOME/.bashrc" <<ENV
export R_PROFILE_USER="$PROFILE"
export RENV_ACTIVATE_PROJECT=FALSE
export NOT_CRAN=true
export LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV
export R_PROFILE_USER="$PROFILE" RENV_ACTIVATE_PROJECT=FALSE LANG=C.UTF-8 LC_ALL=C.UTF-8

cd "$(dirname "$0")/.."

# Packages whose current CRAN version needs a newer R than apt's: install
# an older release from the CRAN archive first (Deriv 4.3.x needs R 4.5;
# Superpower and Spower depend on it through doBy).
Rscript -e '
if (!requireNamespace("Deriv", quietly = TRUE))
  install.packages("https://cran.r-project.org/src/contrib/Archive/Deriv/Deriv_4.2.0.tar.gz",
                   repos = NULL, type = "source")
'

# Everything _dependencies.R names, plus devtools-free test tools.
Rscript -e '
pkgs <- sub("^library\\(([^)]+)\\).*", "\\1", grep("^library\\(", readLines("_dependencies.R"), value = TRUE))
pkgs <- setdiff(unique(c(pkgs, "testthat", "withr")), "power4mome")
missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)
still <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(still)) stop("Could not install: ", paste(still, collapse = ", "))
'

# power4mome, patched for R 4.3 (see the note at the top).
if ! Rscript -e 'quit(status = !requireNamespace("power4mome", quietly = TRUE))'; then
  tmp="$(mktemp -d)"
  # download.packages() hides packages that need a newer R, so build the
  # URL from the unfiltered index.
  Rscript -e "
v <- available.packages(filters = 'duplicates')['power4mome', 'Version']
download.file(sprintf('https://cran.r-project.org/src/contrib/power4mome_%s.tar.gz', v),
              file.path('$tmp', 'power4mome.tar.gz'), quiet = TRUE)
"
  tar -xzf "$tmp/power4mome.tar.gz" -C "$tmp"
  sed -i 's/R (>= 4\.4[^)]*)/R (>= 4.1)/' "$tmp/power4mome/DESCRIPTION"
  printf '\n`%%||%%` <- function(x, y) if (is.null(x)) y else x\n' > "$tmp/power4mome/R/zzz-null-default.R"
  # Its dependencies first (installing from a folder doesn't fetch them).
  Rscript -e "
d <- read.dcf('$tmp/power4mome/DESCRIPTION', fields = c('Depends', 'Imports'))
deps <- trimws(sub('\\\\(.*', '', unlist(strsplit(paste(na.omit(d), collapse = ','), ','))))
deps <- setdiff(deps[nzchar(deps)], c('R', rownames(installed.packages(priority = 'base'))))
missing <- deps[!vapply(deps, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)
"
  R CMD INSTALL "$tmp/power4mome"
fi

# The engine itself, so the app tests find it.
R CMD INSTALL --no-test-load engine >/dev/null
echo "powerkit R setup done: $(Rscript -e 'cat(R.version.string)')"
