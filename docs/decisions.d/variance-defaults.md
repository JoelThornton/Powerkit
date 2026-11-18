## 2026-11-18 · Defaults the researcher can see; the Brown-Forsythe test first for two variances

- **How powerkit sets defaults.** A preselected test is fine when it sits
  in the input screen's dropdown, where the researcher sees it every time
  and changes it in one click. What powerkit avoids is G\*Power's
  pattern: defaults in an options menu few people open, or method choices
  a card makes without showing them. So: preselect where the literature
  shows one method is better (Welch's tests, the Brown-Forsythe test);
  preselect nothing where the researcher's study decides the answer (the
  ANCOVA's measured or fixed covariates); and put every method choice a
  card makes on its input screen (`next.md` item 27). Cards say which
  tests they can run and leave the choice to the researcher, without
  extra warnings steering them.
- **Two variances (E53).** The Brown-Forsythe test is now preselected,
  with Levene's test and the F test in the same dropdown (Departure 32):
  the F test's false-positive rate was 12% with skewed and 43% with
  heavy-tailed scores at alpha .05, against about 5% for the
  Brown-Forsythe test, at a small cost in power with normal scores
  (0.466 against 0.518 at 200 people, variances 1.5 and 1).
- **Not an assumption-check category.** Testing equal variances before a
  t-test or ANOVA is the use most people know (SPSS prints Levene's test
  beside every independent-samples t-test), but powerkit plans studies,
  and its t-test and one-way ANOVA already preselect Welch's tests
  (`Delacre2017_welch`, `Delacre2019_welch_f`). The card stays one
  analysis, spread as the research question; the search finds it under
  Levene's test, the Brown-Forsythe test, the F test of two variances,
  equality and homogeneity of variances, and opens it with that test
  chosen. McNemar's three tests are searchable the same way.
- **One-sided tests.** Only the F test and McNemar's exact test have a
  one-sided version, so the direction question is shown with them alone.
