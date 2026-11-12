* Pearson's correlation (`basic_test / correlation`) is computed from the
  exact distribution of r by `pwrss::power.exact.onecor()`, as G*Power,
  for power, the sample size, the smallest detectable correlation (searched
  with the same call) and a justified alpha. `options >
  correlation_formula = "fisher_z"` keeps `pwr::pwr.r.test()`. A
  correlation with `population > tau` stays on Fisher's z. The exported
  script calls the same function. Departure 10 is retired.
