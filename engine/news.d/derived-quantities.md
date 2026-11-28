* `implied_effect_size()` also gives the quantities other screens' numbers
  imply, as `kind = "derived"` items: mediation's indirect effects (the
  product of the standardised paths on each route, and their total), two
  proportions' odds ratio, difference and Cohen's h, a table's Cohen's w,
  a one-factor MANOVA's Pillai's V, a cluster trial's design effect and a
  2 x 2 logistic table's interaction odds ratio, each from the function
  the engine already uses for it. test-implied-effect.R checks each
  against its definition.
* App: those screens show them as the numbers are typed ("From these
  numbers: ..."). test-implied-derived.R.
