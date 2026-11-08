* Mediation with a two-group X (simple mediation, `process_4`, and the
  moderated mediation templates) takes `population > group_d`: Cohen's d
  of the groups on the mediator (`M`, in place of `X->M`) and on the
  outcome overall (`Y`, in place of `X->Y`). `run_spec()` finds the
  standardised paths that give these d from a simulated sample of 100,000
  people drawn by power4mome with the run's seed (`resolve_group_d()`,
  as the whole-study simulation does), records them in
  `result > group_d`, and `export_script()` uses the paths found. The
  spec hash is the spec as given. Checks before the search use small
  placeholder paths in the direction of each d.
