* The R scripts for the Bayes factor ANOVA, factorial and repeated-measures
  ANOVA, three-factor ANOVA, ANCOVA, regression, R-squared change, two
  proportions and contingency tables now describe their default priors
  (r scale 0.5 for effects, 0.354 for covariates and coefficients, prior
  concentration 1) as the default in the BayesFactor package and JASP,
  instead of as JASP's. These are BayesFactor's own defaults
  (`rscaleFixed = "medium"`, `rscaleCont = "medium"`,
  `priorConcentration = 1`), which JASP uses. `bayes_robustness()` labels
  the medium width "Medium (the usual default)".
