* A MANOVA (`template` "manova") can be given by Pillai's V
  (`population > metric` "pillai_v", `population > pillai_v`) instead of
  the groups' means. Power, the sample size and the smallest detectable V
  are computed by Faul, Erdfelder, Lang and Buchner's (2007, refs.bib
  Faul2007_gpower) formula, Table 5, Pillai's V with the O'Brien and Shieh
  algorithm: f^2(V) = V / (s - V), F with a c and s (N - r - a + s)
  degrees of freedom and noncentrality N s f^2(V)
  (`pillai_backend()`). It agrees with Spower's simulation of the same
  MANOVA from means whose population V is known, and with two groups it
  equals the exact Hotelling's T-squared (`test-backend-pillai-v.R`). The
  exported script reproduces it with base R, and the citations export
  names the paper as the formula's source. `pillai_v_from_means()` gives
  the population V of a table of means.
