* The PROCESS-style OLS percentile bootstrap for mediation has a power
  check independent of power4mome: simple mediation simulated in base R
  and analysed by OLS with a casewise percentile bootstrap written out
  (`independent_mediation_bootstrap_power()`, chunk `process_bootstrap`).
  The validation log's table of independent checks now covers every card
  that runs, which finishes the audit in docs/next.md item 24.
