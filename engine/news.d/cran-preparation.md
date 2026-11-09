* Preparing the engine for CRAN. Thirty backends that only some designs
  use move from Imports to Suggests (ARTool, brunnermunzel, gsl,
  ICC.Sample.Size, irtpwr, JustifyAlpha, kappaSize, longpower, MBESS,
  mclust, metafor, metapower, mirt, nnet, pbkrtest, PITS, PMCMRplus,
  POMADE, powerSurvEpi, powRICLPM, presize, pscl, PUMP, quantreg,
  semPower, statpsych, survival, TOSTER, vegan, WebPower), leaving 25
  non-base Imports; installing the engine alone now brings 228 locked
  packages rather than 300 (`docs/dependency-footprint.md`). `run_spec()`
  checks the packages its backend lists before calling any of them, and
  `joint_power()` checks PUMP; a missing package stops the run with the
  error class `powerkit_missing_package` and a message naming what to
  install, as does a backend call that can't load its package
  (`R/optional-packages.R`). The app's `optional-packages.R` names every
  Suggests package so the online app still installs them all, and a test
  keeps it in step with `DESCRIPTION`.
* The install line in exported run scripts, the app's "run it yourself"
  steps and the README is now
  `remotes::install_github("JoelThornton/Powerkit", subdir = "engine", dependencies = TRUE)`.
* Every exported function has an example; examples that need a package in
  Suggests are guarded with `requireNamespace()`, and the `\dontrun{}`
  examples of `write_project()` and `write_study_plan()` now run.
* On CRAN (`NOT_CRAN` not `"true"`), `tests/testthat.R` runs 23 quick test
  files that need only Imports; GitHub's checks still run every file.
* `DESCRIPTION`: the maintainer's address is a monitored one, URL and
  BugReports fields are added, and GPArotation, hypergeo, Matrix and withr,
  which tests use, are declared in Suggests.
