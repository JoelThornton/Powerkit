* New: pairwise rank comparisons after the Kruskal-Wallis test (E18,
  `oneway_between`: methods `mann_whitney` and `dunn`) and after
  Friedman's test (E54, `oneway_within`: methods `wilcoxon_signed_rank`
  and `conover`), with `target_test > effect` "pairwise", a
  `comparison` and a `p_adjust`. Simulated with Spower by the new
  experiment `p_rank_pairs()`, which adjusts the p-values of every pair
  together and returns the chosen pair's; Dunn's and Conover's tests are
  PMCMRplus's. Scores take `population > score_shape`, as for the
  omnibus rank tests, and the exported R script reproduces the result.
  New validation file `test-validation-rank-pairs.R` in the rank chunk.
