* Welch's t-test with equal groups now reports its critical effect size
  (the smallest observed d that would be significant). It is Student's
  value, which Welch's test gives exactly when the two groups' observed
  SDs are equal, and is stated as such; unequal groups still give none.
* Welch's t-test needs four people in the smaller group (eight in all
  with equal groups), so that pwrss's `power.t.welch()` always has the
  three degrees of freedom it needs; a smaller sample is refused in plain
  English instead of failing inside pwrss.
* App: the smallest-effect result says beside it which observed effect
  would be significant in any one study; factorial sample sizes say they
  are whole groups, where G*Power's total can be a few lower; the ANCOVA
  result shows that Shieh's method differs from G*Power's (Known
  difference 15); an empty "How you adjusted it" says where the box is
  and why it is asked.
