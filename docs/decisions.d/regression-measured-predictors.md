## 2026-11-22 · Multiple regression: measured predictors by default

The independent check of the multiple regression card (E24, queue item 24)
found that its F tests, pwrss's `power.f.regression()` and G*Power's fixed
model (noncentrality f² N), give about 1 to 2 points more power than
studies whose predictors are measured afresh each time: 75.3% against
73.8% simulated for two predictors added to three at N = 150 (20,000
studies). The maintainer chose measured predictors as the default, with
G*Power's fixed version kept as an option.

- **Method:** the fixed-predictor power averaged over multivariate normal
  predictors (Shieh, 2007): given the predictors the noncentrality is f²
  times a chi-square on N − 1 − (k − q) df, so power is one integral. No
  package powerkit builds on computes it (pwrss 1.3.3, MBESS 5.0.1 and
  WebPower 0.9.4 take the fixed model), so it is written in the engine
  from the published result and checked against simulated studies.
- **Input screen:** the card asks whether the predictors are measured or
  set by the design, preselecting neither, as the ANCOVA card does for
  its covariates (18 November 2026, nothing preselected where the study
  decides). A spec without the setting is planned with measured
  predictors.
- **Recorded as** Departure 39 (conventions.md), shown on the result
  screen and in the methods paragraph. The Bayes factor versions on the
  same card still take the predictors as fixed; changing them is queued.
