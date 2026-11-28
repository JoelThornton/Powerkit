* `convert_effect()` takes one regression coefficient's t statistic
  (with its error df) or partial r into its partial R-squared
  (`single_coefficient`, effectsize's `t_to_r()`), and group 2's
  proportion, with group 1's, into a yes/no predictor's odds ratio in
  logistic regression (`single_predictor`, `from = "p2"`). The schema's
  conversion `from` takes `"p2"`.
* App: E24's one-coefficient question offers the t with its df and the
  partial correlation; E27 offers the two groups' proportions for a
  yes/no predictor; E63's and E67's SD boxes give the worked example E33
  gives; E19 and E20 say why they need the means. test-other-ways-in.R.
