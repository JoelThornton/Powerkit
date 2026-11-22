## 2026-11-22 · Multiple regression's Bayes factors: measured predictors too

The decision of the same day to plan multiple regression's F tests with
measured predictors by default (Departure 39) covers the card's Bayes
factors, which answer the same questions and had taken the predictors as
fixed in the same way.

- **R-squared against 0:** the Bayes factor rises with F, so its power is
  the F test's measured-predictor integral with the F at which BF10
  reaches the threshold in place of the critical value. Still exact.
- **An R-squared increase or one coefficient:** each simulated study now
  draws the noncentralities of its sums of squares first, as the
  predictors vary, then the sums of squares as before; checked against
  `lm()` and `lmBF()` on data sets with new normal predictors in each.
- **Size:** a few people, as for the F tests: 193 against 189 for
  R-squared .10 with three predictors at a threshold of 10.
- **Input screen:** the question about the predictors is asked for the
  Bayes factors too, preselecting neither answer; predictors set by the
  design keep the fixed-predictor answer.
