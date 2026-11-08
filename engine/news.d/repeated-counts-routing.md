* The design finder no longer ends at "No matching design" for a count or
  an outcome in ordered categories measured twice or more on the same
  people. A difference goes to a new card (E75, a generalised mixed model,
  which powerkit doesn't calculate yet; it names simr and mixpower), and a
  relationship to the within-person card (E41), as for a score. The guided
  route does the same, and also sends groups measured twice on a yes/no
  outcome to E75.
* A yes/no outcome measured twice, with a relationship as the aim, now
  reaches the within-person card instead of logistic regression, which
  assumes separate people.
* Two tests walk every answer in "Help me choose" and every combination in
  the guided route, and fail when one reaches "No matching design" without
  the user choosing it, unless it is on a short list of known gaps.
