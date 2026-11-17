* A rank test's result (the Wilcoxon signed-rank test on E1 and E3,
  Mann-Whitney on E2, Kruskal-Wallis on E18, Friedman on E54) gives, under
  Details, the same plan by the card's default test, by formula assuming
  normal scores, and says why the two differ from the numbers themselves:
  a little less power with normal scores, because ranks use only the
  order; more with skewed or heavy-tailed scores; and for Friedman's test,
  which ranks within each person, noticeably less even with normal scores
  (`rank_comparison_line()` in `app/routing/R/results.R`; one more engine
  call). The default test's result on those cards offers the rank test in
  one line, to be chosen before the data are seen, citing Rochon, Gondan
  and Kieser (2012, added to refs.bib from its Crossref and PubMed
  records) for how choosing the test after a normality test alters the
  error rates of the test then run (`rank_switch_ui()`).
