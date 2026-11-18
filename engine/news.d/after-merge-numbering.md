* Versions are given after each merge rather than by each pull request:
  `.github/workflows/after-merge.yaml` runs the new `scripts/after-merge.R`
  on main, which numbers the waiting change notes with
  `scripts/close-batch.R` (minor when a merged pull request has the
  "minor" label), adds the decision entries waiting in the new
  `docs/decisions.d/` to `docs/decisions.md`, dates `docs/status.md` and
  regenerates `docs/release-support-inventory.json`, then tags the
  release. Pull requests no longer conflict over the version, NEWS.md,
  whats-new.yaml or those shared lines. `scripts/tag-releases.sh` now tags
  the version main is on as well, since it no longer changes.
  `test-release-support.R` checks the inventory a pull request's code
  produces rather than the committed file. `docs/status.md` was cut to
  its current state; its history moved to `docs/archive/status-history.md`.
