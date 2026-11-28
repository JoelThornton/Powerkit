## 2026-11-28 · Write-ups name methods, not other programs

A methods paragraph is read as a description of what was done, so a
sentence such as "as in G*Power" or "JASP's default" tells the reader
which program another person might use rather than what the analysis
did. The write-ups now state each choice by its method.

- **Write-ups** (the short and full methods paragraphs, the ethics
  paragraph, the planning document and the study plan report): no
  program other than the packages that calculated the result. A departure
  from common practice is still stated, as conventions.md requires, in
  the words of `departures_methods` in forms.yaml where its screen text
  names another program; known differences use `known_differences_methods`,
  reworded the same way. The full write-up's headings read "Where these
  methods differ from common defaults" and "Where other methods give a
  different answer".
- **Input screens and cards:** asides that only said a choice matches
  another program ("as in G*Power") are gone from labels, choices, help
  and starting-value notes. Another program is named where its answer
  differs (the results screen's departures and known differences, and the
  notes on five fields: the two-group and two-variance test choice, the
  one-way ANOVA's test version, and how covariates or predictors come
  about), and in validation records and a formula's published source.
- **Guard:** app/routing/tests/testthat/test-writeup-software.R checks the
  write-up's departures and known differences, its own wording, every
  input screen's labels, choices and help, and the cards.
- **Not changed:** the R script's comments, which explain each argument
  for someone reproducing or comparing the calculation, and screen text
  that names an analysis by the program researchers know it from (PROCESS
  model numbers, JASP's default priors).
