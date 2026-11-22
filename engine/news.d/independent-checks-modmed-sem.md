* Validation: PROCESS model 7 is now checked against studies simulated
  separately from power4mome (the product of X and W entering M, both
  regressions fitted by `lm()`, and a Monte Carlo interval for the index
  of moderated mediation), with correlated X and W. The SEM model-fit
  tests (exact, close and not-close fit) are checked against MacCallum,
  Browne and Sugawara's (1996) noncentral chi-square written out
  separately from semPower. Both run in their designs' validation chunks
  (`process_7`, `sem_fit`); `docs/validation-log.md` records them.
* The moderated mediation forms' XW -> M field now says what the path
  is (the coefficient of the product of standardised X and W, the
  product not standardised again), which the PROCESS model 7 check
  confirmed with correlated X and W.
