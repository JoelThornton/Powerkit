* Mediation and moderated mediation (power4mome): the Monte Carlo interval
  of each simulated study's indirect effect, index of moderated mediation or
  difference between conditional indirect effects is computed directly from
  manymome's own draws (`fast-mediation-test.R`), with manymome's percentile
  rule (`boot::boot.ci(type = "perc")`). Every replication's estimate,
  interval and decision is the same as manymome's (to about 1e-17;
  `test-fast-mediation-test.R` checks nine designs), and each simulated
  study is 3 to 7 times faster, because manymome's general code formats
  labels for every draw. Bootstrap intervals and OLS fits use the original
  tests unchanged. The slowness is raised with manymome's author
  (`docs/upstream-questions.md`, power4mome question 7).
