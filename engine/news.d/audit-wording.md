* Engine: Spower designs report the studies Spower redrew because their
  analysis failed (an NA p-value or an error, counted in Spower's ERRORS)
  as failed studies, so the result says how many could be analysed: the
  random-intercept cross-lagged panel model (E74) among them. The power
  is still over the studies analysed (`spower_counts()`).
* Engine: E25's evidence for no effect counts a BF01 equal to the
  threshold, as the results' "at least" says; bfpwr's `pbinbf01()` upper
  tail is strict (differs only at an exact tie).
* App: wording the 19 November 2026 audit found wrong: E51's correlations
  named as the value under no difference and the value expected (the
  order matters in the unpooled method); E2's converter asks for a
  Student's (pooled) t; E61's moderator slope is on Fisher's z scale for
  a correlation; E77's calibration slope doesn't change pmvalsampsize's
  sample size (upstream-questions.md, pmvalsampsize question 2); E69's
  agreement note tests each limit at half the level; E74's help says
  measurement error can bias a cross-lagged path either way; precision
  results from presize say the width holds at the values assumed, not
  on average (queue item 29).
