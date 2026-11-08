* Welch's t-test is worked out by pwrss's formula (`power.t.welch()`)
  unless `options > method = "simulation"` asks for Spower's simulation;
  before, it was simulated unless the formula was requested. The two
  agree (the `welch_spreads` validation chunk), and the formula has no
  random error and takes a fraction of a second.

* Welch's t-test gains the smallest detectable effect
  (`welch_sensitivity()`: d searched with pwrss's own power, keeping the
  spread ratio and the group sizes) and a justified alpha (JustifyAlpha's
  `optimal_alpha()` on `power.t.welch()`), with scripts that reproduce
  both.

* The two-group card plans for Welch's t-test by default, Student's as a
  choice (Departure 21, `docs/conventions.md`; `Delacre2017_welch` in
  `refs.bib`). `test-welch-default.R` shows the size of the difference:
  none with equal spreads and equal groups, and 147 rather than 144
  people for d = 0.5 when group 2 is twice the size of group 1.
