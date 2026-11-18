## 2026-11-18 · Replication plans: an ANOVA original's full goals, and the smallest effect for one with several degrees of freedom

Queue item 28, the first of its remaining parts. Until now an ANOVA
original had one goal (a significant F test, BUCSS's corrected sample
size), while a t-test original had every goal, three beliefs, variation
between studies and its own smallest effect. Nothing about an ANOVA
justified the difference for most effects researchers replicate.

- **An effect with one numerator degree of freedom goes through every
  goal.** A factor with two levels, or a 2 x 2 interaction, is a
  comparison of two means, and its F is the square of that comparison's
  t, F(1, df) = t² (Lakens, 2013). The engine
  (`replication_planning()` with `design = "anova_between"`,
  `"anova_within"` or `"anova_mixed"`) moves the effect to the
  comparison it is and plans it as that t-test original, t = sqrt(F),
  converted to d as for any t statistic (Lakens, 2013). Which comparison
  each effect is:
  - a between-subjects factor with two levels: two groups, the two
    marginal means;
  - a between-subjects 2 x 2 interaction: two groups, d being half the
    difference between the simple effects (its standard error with N / 4
    a cell is that of two groups of N / 2);
  - a within-subjects factor with two levels or 2 x 2 interaction:
    pairs, each person's difference (or difference of differences), d_z;
  - in a mixed design, the between-subjects factor with two groups: two
    groups on each person's mean;
  - the within-subjects factor with two conditions: pairs, each person's
    change;
  - the 2 x 2 interaction: two groups on each person's change.
  No new maths is involved: the conversions are the published ones the
  t-test originals already use. BUCSS's correction stays beside the
  goals and is the ANOVA's own function. For the mixed 2 x 2 interaction
  it gives the same numbers as the two-group t (the error df are the
  same), which the tests check. The goals judged against the original's
  effect work on its estimate and standard error, so the ANOVA's error
  degrees of freedom matter only to small telescopes and the Bayes
  factor t-test, through the t-test's df. Where the two differ (a
  between-subjects factor averaged over another, the mixed design's
  within-subjects factor with three or more groups), the result says so
  and by how much. A one-sided test in the original's direction is now
  allowed for these effects, in BUCSS as for a t-test (its two-sided
  test at twice the level).
- **An effect with several degrees of freedom gains a goal from the
  smallest effect that would matter.** It has no one number for the
  other goals, so the plan offers two routes to a significant F test,
  side by side. One is BUCSS's correction of the original, as before.
  The other is the researcher's smallest effect that would matter, as a
  partial eta-squared, through the matching ANOVA card's own F test
  (`replication_anova_smallest()`: `run_spec()` on a spec given by its
  partial eta-squared, so pwrss's `power.f.ancova()` or
  `power.f.mixed.anova()`). There is no default value: the smallest
  effect that matters is the researcher's judgement, and the original's
  effect is not a guide to it. Within-subjects and mixed designs take it
  as those analyses report it (`eta_source = "published"`), so no
  correlation between measurements is asked for. A within-subjects
  design with two factors has no card that takes a partial
  eta-squared, so the plan says to plan it from its means on its card.
- **The design list says where the designs it doesn't name go.**
  - An ANCOVA's effect with one degree of freedom (the adjusted
    difference between two groups) is one number, so "Another design"
    gives it every goal. BUCSS has no ANCOVA function, so there is no
    corrected figure.
  - With three or more groups, the one comparison the hypothesis is
    about is entered the same way.
  - No published method plans a replication from a MANOVA's result, so
    a MANOVA is planned as an ordinary power analysis on its card, from
    the smallest effect that would matter, or its one focal outcome and
    comparison is replicated as its own design.
- **A conceptual replication of a 1-df ANOVA original** is planned as
  any one-number original's is: the shrunk belief and more variation
  between studies. One with several degrees of freedom still changes no
  setting, and now points to the smallest-effect goal on the same page.
