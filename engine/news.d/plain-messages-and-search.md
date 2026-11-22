* `search_n()`: when the probit fit to the points within 20% of the
  estimate has no upper limit inside that grid (its points are noisy at
  few replications), points above the estimate are simulated and the
  fit is repeated, up to twice. A Bland-Altman sample size at 200
  replications stopped with "could not pin down the required n" for two
  of four seeds; all four now return 32 to 34. Searches that succeeded
  before are unchanged, as the extra points are added only when the
  local interval was missing.
* Messages: the impossible-correlations check of moderation names the
  correlations by their spec paths, which the app turns into its field
  labels, and the unequal-cells ANOVA's sensitivity message asks for the
  power or the sample size in words rather than goal types.
* App: `plain_engine_message()` also replaces a field named by the last
  part of its path, a list entered in several fields (named by its
  parent path) and a choice named by its value (for a field the message
  names) with what the screen shows.
* App: the SEM card's number of items for a CFA's fit is capped at 100:
  `semPower.getDf()` takes 3 s at 100 items, 12 s at 150 and minutes
  beyond, and the check runs as fields change. More items go through
  the card's degrees-of-freedom route.
* A simulated search that still finds no answer says what it simulated
  (`unsettled_search_message()`): the highest power and where, when the
  target was never reached (power can level off below it, as in an
  interrupted time series with few points before the change), or the
  range it crossed the target in. The smallest-detectable-effect search
  says the same. The app's interrupted-time-series example (helper
  values) now uses a drop of 5, which reaches 80%; a drop of 3 levels off
  below it.
