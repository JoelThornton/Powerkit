* Continuous integration: the engine's tests run in five parts and the
  app's tests in two, each part running four test files at a time in
  separate R processes (`.github/ci/run-test-part.R`). Files are dealt to
  the lanes by their recorded times (`.github/ci/engine-test-times.csv`,
  `.github/ci/app-test-times.csv`). The slowest test files are split into
  smaller files so that no single file sets the length of a run. Every
  test still runs on every pull request.
