* The list of every analysis finds test versions by their own names
  (tree.yaml's new `test_versions`: endpoint, form value, name and search
  words). A search for Brunner-Munzel, Mann-Whitney, Kruskal-Wallis,
  Friedman, Spearman, Kendall, Fisher's exact test, the aligned rank
  transform, PERMANOVA, quantile regression, HC3 standard errors or a
  zero-inflated model shows a "Test version" line under the analysis that
  holds it. Choosing the line opens the card with a note and then the
  input screen with that version chosen, together with any question the
  choice depends on (`test_version_fields()`, `version_form_values()`,
  `version_card_note()` in `app/routing/R/ui.R`). The search now matches
  each typed word at the start of a word rather than anywhere, so "sign"
  no longer matches "design"; "nonparametric", "non-parametric" and
  "rank based" find every rank-based version, and the ordinal regression
  card answers to "proportional odds".
