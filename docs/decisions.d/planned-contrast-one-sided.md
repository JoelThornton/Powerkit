## 2026-11-22 · The planned contrast offers a one-sided test

The planned contrast card (E19) was two-sided only, because pwrss's
`power.t.contrasts()` has no one-sided option. A planned contrast is
usually a directional prediction (a linear trend up the doses, two
treatments above a control), and its one-sided power is the same
noncentral t with the critical value at alpha, so the card now offers the
direction choice every directional card has, with nothing preselected. The
same change bypasses a fault in pwrss 1.3.3: without covariates,
`power.t.contrasts()` gives the power at alpha 0.05 whatever alpha it is
passed (docs/upstream-questions.md, pwrss). The engine passes the
function's own noncentrality and df to pwrss's `power.t.test()`; at alpha
0.05, two-sided, results are unchanged. Not a departure: the test and its
noncentrality are pwrss's.
