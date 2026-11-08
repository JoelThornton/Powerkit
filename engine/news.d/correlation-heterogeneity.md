* Effects that vary between studies now cover the correlation template:
  `population > tau` is an SD on Fisher's z, and power follows McShane and
  Böckenholt's (2014) normal model through `pwr.r.test()` with a scaled
  significance level and correlation (`heterogeneity_adjustment_r()`).
  The R script reproduces it with pwr alone. Rank correlations and the
  Bayes factor test are refused in plain words.
* The heterogeneity record gains `range` (the goal's answer with no,
  small, medium and large variation and with the value entered, Kenny and
  Judd's 25% of a small, medium and large effect), `range_goal`, `scale`
  and `source`.
