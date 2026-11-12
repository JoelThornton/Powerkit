* App: results arrive sooner. The warm spare R process now runs one
  small example while it waits, so the spec checker (the JSON schema,
  compiled in V8) and Superpower's first-call setup are ready before a
  calculation starts; they took 1.3 of the 1.4 seconds of a t-test's
  sample size in a fresh process. A sample-size search that takes more
  than a second (Superpower's ANOVAs, InteractionPoweR) now shows its
  result first, with "Working out the sample sizes for 80%, 90% and 95%
  power" where the comparison table goes; the table's two further
  searches run next in the background and fill it in. On the example
  values, a t-test's answer came in 0.9 seconds instead of 2.1, and the
  2 x 2 mixed ANOVA's in 2.5 seconds instead of about 7. Welch's ANOVA
  (the one-way ANOVA's default), the trend test and two paired variances
  have usual run times (forms.yaml, `simulated_times`), so their progress
  bars estimate and say how long the run usually takes.
