#!/usr/bin/env bash
# Tags each finished powerkit version and publishes it as a GitHub release.
#
# A version is finished once main has moved on to the next one: the first
# pull request of a batch sets the new number in engine/DESCRIPTION, and the
# rest of the batch keep it (docs/adding-a-test.md, "Version numbers"). So
# version X.Y.Z is tagged vX.Y.Z at the last commit on main's first-parent
# history whose engine/DESCRIPTION still says X.Y.Z, and the version main
# is on now stays untagged until the next one starts. The release notes
# are that version's section of engine/NEWS.md at the tagged commit.
#
# Run from a full clone of main (fetch-depth 0). Safe to run again: a
# version that already has its tag and release is left alone, and release
# tags can't be moved or deleted (the "Protect release tags" ruleset).
#
#   scripts/tag-releases.sh            # create missing tags and releases
#   scripts/tag-releases.sh --dry-run  # list what would be created

set -euo pipefail

dry_run=false
[[ "${1:-}" == "--dry-run" ]] && dry_run=true

semver='^[0-9]+\.[0-9]+\.[0-9]+$'
version_at() {
  { git show "$1:engine/DESCRIPTION" 2>/dev/null || true; } | awk '/^Version:/ {print $2}'
}

current=$(version_at HEAD)
declare -A last_commit=()
while read -r commit; do
  v=$(version_at "$commit")
  [[ "$v" =~ $semver ]] && last_commit[$v]=$commit
done < <(git rev-list --first-parent --reverse HEAD)

# Finished versions, oldest first.
finished=$(printf '%s\n' "${!last_commit[@]}" | grep -vxF "$current" | sort -V || true)

for v in $finished; do
  tag="v$v"
  commit=${last_commit[$v]}
  has_tag=false
  git rev-parse -q --verify "refs/tags/$tag" > /dev/null && has_tag=true
  has_release=false
  if ! $dry_run && gh release view "$tag" > /dev/null 2>&1; then
    has_release=true
  fi
  $has_tag && $has_release && continue

  if $dry_run; then
    echo "$tag -> $(git log -1 --format='%h %cs %s' "$commit")"
    continue
  fi

  if ! $has_tag; then
    git tag -a "$tag" "$commit" -m "powerkit $v"
    git push origin "refs/tags/$tag"
  fi

  notes=$(mktemp)
  {
    echo "Prototype release: powerkit is in development and its results are"
    echo "not yet fully validated (see docs/validation-log.md)."
    echo
    git show "$commit:engine/NEWS.md" 2>/dev/null |
      awk -v head="# powerkit $v" '
        $0 == head { on = 1; next }
        on && /^# powerkit / { on = 0; done = 1 }
        on && !done { print }
      '
  } > "$notes"
  gh release create "$tag" --verify-tag --prerelease \
    --title "powerkit $v" --notes-file "$notes"
  rm -f "$notes"
done
