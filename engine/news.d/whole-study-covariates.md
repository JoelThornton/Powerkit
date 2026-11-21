* Whole-study simulation (experimental): up to three covariates, C1 to
  C3, scores measured on each person. Each predicts every mediator and
  the outcome in the population, with its correlations with X, W, the
  baseline and the other covariates (`population > correlations`, e.g.
  `X<->C1`, `C1<->C2`), and every analysis adjusts each of its equations
  for them, as PROCESS does. A two-group X may differ on them (each is
  regressed on the exogenous variables before it). Validation in
  `test-validation-whole-study-covariates.R` (chunk `whole_study`).
