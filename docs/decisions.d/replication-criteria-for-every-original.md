## 2026-11-19 · Replication plans: criteria that fit every kind of original

A review of the replication plan across every design and every way an
original can be analysed (a p-value, a Bayes factor, a posterior, or
both) found combinations whose usual criteria failed or reported nothing
that could show the effect is absent. The rules are now:

- **The criterion that can show absence is one planned for no effect.**
  With a Bayes factor main criterion it is the Bayes factor t-test for
  no effect where the design has one (two groups, one group, pairs, a
  1-df ANOVA effect); otherwise the equivalence test. This replaces the
  17 November rule's replication Bayes factor for a correlation or
  another design: the engine plans that Bayes factor's chance of
  evidence *for* the original's effect, not its chance of evidence
  against it, so it could not show absence with a planned chance
  (conventions.md, Departure 30). An interim version (18 November)
  reported nothing in its place.
- **"Confirm" for a Bayesian original whose own test can't be repeated**
  (a correlation or another design, from a posterior) uses the
  replication Bayes factor, keeping a Bayesian original's plan Bayesian;
  it was significance before 18 November.
- **"Show it is absent" for a Bayesian original** uses the Bayes factor
  t-test for no effect where the design has one, as "confirm" uses the
  Bayes factor t-test for an effect. Elsewhere it stays the equivalence
  test, which for a Bayesian original needs the researcher's smallest
  effect (d33 rests on a significance test): the planner now asks for it
  before running, instead of failing after.
- **Criteria the original can't give are greyed out** in the list (the
  Bayes factor t-test for a correlation or another design; small
  telescopes for a Bayesian original or another design), and a Bayes
  factor original of a correlation or another design is told at once to
  give its posterior or its test instead (a Bayes factor gives the
  effect only for a t-test).

Recommendation: these defaults, because each keeps the plan within the
framework the original was analysed in and every reported criterion has
a planned chance. The maintainer may prefer the equivalence test for
every "absent" plan; that is one line in `replication_resolve_goals()`.
