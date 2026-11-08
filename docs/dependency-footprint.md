# Dependency and setup assessment

Written by `scripts/dependency-footprint.R` from `renv.lock` and `engine/DESCRIPTION`; a test checks the counts are current.

The engine declares 58 direct Imports; `renv.lock` pins 305 packages, which the online app's manifest is written from when it is published. The lock includes development and validation tools as well as runtime dependencies.

| Scope | Locked packages in dependency closure |
|---|---:|
| Full locked environment | 305 |
| Current engine Imports and their locked dependencies | 300 |
| Candidate formula-only roots (not an installable profile) | 9 |

These counts measure metadata reachability, not download bytes, installed disk size, startup time, redundancy or security risk. Shared transitive dependencies are counted once. Base R packages are outside the lock graph.

## Recommendation

Keep the complete locked environment for deployment and validation. A smaller optional basic-formula installation is worth prototyping separately, but is not currently supported: all engine Imports must load, so merely omitting packages breaks installation. Do not advertise a partial install command.

Decided (7 November 2026): a backend that only one card uses moves from Imports to Suggests when a pull request next touches that card, with a `requireNamespace()` guard and a plain message saying which package to install; `renv.lock` still pins it for the app. Nothing is moved in a pull request of its own.

A safe optional profile requires explicit backend capability metadata, moving truly optional packages from Imports to Suggests, guarded namespace access and clear unavailable-backend messages, plus isolated installation and script-export tests for each profile. Preserve the complete environment and numerical regression checks. Select a profile from actual requested analyses, not from package count alone.

Browser-development tools and tests are excluded from the deployment bundle. Prefer that concrete reduction over deleting scientific fixtures or undocumented package removals. Installing the complete environment once and restarting without reinstalling is already covered on Windows and macOS.

## Acceptance criteria before introducing optional profiles

Measure cold install time, downloaded bytes, installed size and startup on clean supported Windows/macOS/Linux environments using the same R and lock versions. Record cache state, machine and uncertainty. Verify every advertised route, standalone script, saved-project restore, and an honest refusal for absent backends. A dependency closure estimate alone does not meet these criteria.
