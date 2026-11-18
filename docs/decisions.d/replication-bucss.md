## 2026-11-18 · Replication plans: ANOVA originals and publication-bias-corrected sample sizes (BUCSS)

Queue item 28, carrying out the 17 November decision above ("BUCSS").

- **ANOVA originals.** A new design, "An ANOVA effect", takes the
  original's F, or its partial eta-squared with the F test's error
  degrees of freedom, for a main effect or interaction in a
  between-subjects, within-subjects or mixed design (one or two
  factors). The replication's sample size for a significant F test is
  BUCSS's own (`ss_buc_one_way_anova()`, `ss_buc_factorial_anova()`,
  `ss_buc_rm_anova()`, `ss_buc_mixed_anova()`), at the assurance the
  researcher chooses (80%, BUCSS's default, to start). The plan's other
  goals need a one-number estimate with a standard error and are not
  offered; a one-degree-of-freedom contrast entered under "Another
  design" still has them. A partial eta-squared is moved to F with
  eta / (1 - eta) * df2 / df1 (Lakens, 2013), df1 being the effect's
  degrees of freedom in the design.
- **Beside t-test and correlation goals.** For an original analysed
  with a test, the plan shows BUCSS's corrected sample size for a
  significant result at 50% and 80% assurance, and the write-up reports
  it for comparison. It does not set the plan's sample size; that stays
  with the main criterion and belief, so the purpose-first page of
  17 November is unchanged. BUCSS's test is two-sided, so a one-sided
  replication is planned as BUCSS's two-sided test at twice its level
  (the same critical value in the original's direction).
- **A conceptual replication of an ANOVA original changes no setting.**
  BUCSS's assurance allows for the original's sampling error and
  publication bias (Anderson, Kelley & Maxwell, 2017); nothing in BUCSS
  allows for a changed procedure changing the true effect, which is what
  makes a conceptual replication harder to plan. Raising the assurance
  for every conceptual replication would buy a larger sample with a
  number that does not answer that question, and would make "conceptual
  means 90%" a new convention with no basis. So the assurance stays at
  BUCSS's default of 80% unless the researcher chooses another, from
  the table of every level the results show, and the page says so in
  plain words. It points to the two routes that do address the change:
  planning from the smallest effect that would matter, as an ordinary
  power analysis on the original's card, and, for an effect with one
  degree of freedom, entering its estimate and F under "Another design",
  which has every goal and the variation between studies. The
  conceptual-replication button (the shrunk belief and more variation
  between studies) stays for the one-number designs, where it sets the
  parameter that describes the change.
- **ANOVA cards.** E7, E8, E18, E20, E21, E22, E54 and E55 are marked
  `anova` in `forms.yaml`'s `replication_effects`, so a plan opened from
  one starts on "An ANOVA effect"; entering them under "Another design"
  is not flagged as a mismatch. The three-factor ANOVA (E56) is left
  out: BUCSS's general functions need the effect's degrees of freedom
  worked out by hand, which is for a later change.
- **Validation.** Every number is BUCSS's: tests check powerkit's
  results against direct calls, and against the figures recorded on
  17 November (86 and 152 people for Shnabel et al.'s interaction). A
  published example is left as a placeholder for the maintainer to
  transcribe (`test-validation-replication.R`).
