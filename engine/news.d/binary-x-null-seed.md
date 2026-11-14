* The model-7 yes/no-X Type I error check in
  `test-validation-modmed-binary.R` uses seed 1500 (chosen by the
  maintainer before it was run) instead of 1703, whose 1,000 null studies
  were rejected 7.5% of the time and failed the nightly run on the same
  draw every night. The rate is 5.38% in 20,000 studies; with seed 1500
  the check gives .051 against its .0707 limit.
