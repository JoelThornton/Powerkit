* Group treatment trials with a score (template `group_treatment`) now
  test the difference with the Welch-Satterthwaite degrees of freedom,
  keeping `irgtt.cont()`'s variance (Departure 38). `irgtt.cont()`'s own
  df are about half as many and gave too little power with few groups
  (51.2% against 54.8% at 10 groups of 8; up to about 12 points with 4
  to 6 groups). The backend recorded is `stats`, and the exported script
  computes the power in base R. Yes/no outcomes still use `irgtt.bin()`.
* Validation: the cluster-randomised, multisite and group treatment
  trials with a score are now checked against trials simulated
  separately from powertools (`cluster` and `multisite` chunks).
