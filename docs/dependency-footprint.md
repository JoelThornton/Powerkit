# Dependency and setup assessment

Written by `scripts/dependency-footprint.R` from `renv.lock` and `engine/DESCRIPTION`; a test checks the counts are current.

The engine declares 28 direct Imports and 39 Suggests; `renv.lock` pins 305 packages, which the online app's manifest is written from when it is published. The lock includes development and validation tools as well as runtime dependencies.

| Scope | Locked packages in dependency closure |
|---|---:|
| Full locked environment | 305 |
| Current engine Imports and their locked dependencies | 228 |
| Engine Imports and Suggests (every backend) and their locked dependencies | 302 |
| Candidate formula-only roots (not an installable profile) | 9 |

These counts measure metadata reachability, not download bytes, installed disk size, startup time, redundancy or security risk. Shared transitive dependencies are counted once. Base R packages are outside the lock graph.

## Recommendation

Keep the complete locked environment for deployment and validation. The online app installs every backend: `app/routing/optional-packages.R` names the engine's Suggests so the app's manifest includes them, and a test keeps that list in step with `engine/DESCRIPTION`.

Decided (9 November 2026, replacing the card-by-card rule of 7 November 2026): every backend that only some designs use is in Suggests, moved in one pull request to prepare the engine for CRAN, whose check asks packages with many Imports to make as many as possible optional. Each run checks the packages its backend lists before calling any of them, and a missing one stops it with a plain message naming what to install (`engine/R/optional-packages.R`). `remotes::install_github(..., dependencies = TRUE)` installs them all. `renv.lock` still pins every one.

A package stays in Imports when many designs need it. A few packages in Suggests (nnet, pbkrtest, quantreg and survival) are installed anyway, because packages in Imports need them; they are optional to powerkit's own code, which is what CRAN's check counts.

Browser-development tools and tests are excluded from the deployment bundle. Prefer that concrete reduction over deleting scientific fixtures or undocumented package removals. Installing the complete environment once and restarting without reinstalling is already covered on Windows and macOS.

## Acceptance criteria before introducing optional profiles

Measure cold install time, downloaded bytes, installed size and startup on clean supported Windows/macOS/Linux environments using the same R and lock versions. Record cache state, machine and uncertainty. Verify every advertised route, standalone script, saved-project restore, and an honest refusal for absent backends. A dependency closure estimate alone does not meet these criteria.
