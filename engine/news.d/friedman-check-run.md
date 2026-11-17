* Fixed: Friedman's test (E54) with heavy-tailed scores often refused to
  run, saying powerkit's translation had not reproduced the population.
  The check run's standard errors for each condition's SD and the average
  correlation assumed normal scores; heavy-tailed deviations (t, 3 df)
  have no finite fourth moment, so the sample SDs and correlation vary far
  more and the check failed by chance on about half of the seeds. The SD's
  error now allows for the scores' kurtosis and the correlation's comes
  from its influence function, as the check of Yuen's paired test already
  did (`rank_check_run()`). The check passes on every seed tried for each
  shape and still flags scores drawn with the wrong correlation.
