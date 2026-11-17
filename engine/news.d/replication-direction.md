* `replication_planning()` counts a replication or sceptical Bayes factor
  as a success only in the original's direction: BayesRepDesign's
  `ssdBFr()`, `porsBFr()`, `ssdBFs()` and `porsBFs()` are called with
  `paradox = FALSE`, where the package defaults to `TRUE` (Departure 31,
  `docs/conventions.md`). Sample sizes for those goals can rise sharply
  under the shrunk belief (26,086 against 7,393 for an original d = 0.3
  with 90 per group and tau = 0.1). The scripts, the validation chunk's
  simulation and the app's result and methods paragraph follow.
