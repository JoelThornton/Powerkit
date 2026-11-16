* The app's "If the effect were different" and "What if the true effect is
  smaller?" panels, which had worked on the basic tests only, now work on
  the formula cards whose effect is one number: multiple regression (the
  R-squared, a coefficient's partial R-squared or the R-squared increase),
  logistic and Poisson regression (the odds or rate ratio, on the side of 1
  the plan is on, so weaker means closer to 1), the ANOVAs given by partial
  eta-squared, moderated regression given by the R-squared change, one
  proportion, two proportions and two correlations. `explore_effect()` now
  carries each card's own range, the value meaning no effect and how to set
  the effect in the spec (dropping any conversion, such as Cohen's
  f-squared, so the value set is the one run); every curve is still the
  engine's. Means-based ANOVA and ANCOVA, the Bayes factor versions beyond
  the basic tests and the simulated designs have no panels yet
  (`docs/next.md`, item 11). Tests: `test-explore-more-cards.R`.
