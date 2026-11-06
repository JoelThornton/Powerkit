# Dependency and setup assessment

Measured from renv.lock SHA-256 5f27cd42b2a8b772d1ec7f231bd6931eb1a723c59b94b1eeb7a339416b848413

The engine declares 54 direct Imports; the deployment manifest contains 298 packages. The lock includes development and validation tools as well as runtime dependencies.

| Scope | Locked packages in dependency closure |
|---|---:|
| Full locked environment | 299 |
| Current engine Imports and their locked dependencies | 297 |
| Candidate formula-only roots (not an installable profile) | 9 |

These counts measure metadata reachability, not download bytes, installed disk size, startup time, redundancy or security risk. Shared transitive dependencies are counted once. Base R packages are outside the lock graph.

## Recommendation

Keep the complete locked environment for deployment and validation. A smaller optional basic-formula installation is worth prototyping separately, but is not currently supported: all engine Imports must load, so merely omitting packages breaks installation. Do not advertise a partial install command.

A safe optional profile requires explicit backend capability metadata, moving truly optional packages from Imports to Suggests, guarded namespace access and clear unavailable-backend messages, plus isolated installation and script-export tests for each profile. Preserve the complete environment and numerical regression checks. Select a profile from actual requested analyses, not from package count alone.

Browser-development tools and tests are excluded from the deployment bundle. Prefer that concrete reduction over deleting scientific fixtures or undocumented package removals. Installing the complete environment once and restarting without reinstalling is already covered on Windows and macOS.

## Acceptance criteria before introducing optional profiles

Measure cold install time, downloaded bytes, installed size and startup on clean supported Windows/macOS/Linux environments using the same R and lock versions. Record cache state, machine and uncertainty. Verify every advertised route, standalone script, saved-project restore, and an honest refusal for absent backends. A dependency closure estimate alone does not meet these criteria.
