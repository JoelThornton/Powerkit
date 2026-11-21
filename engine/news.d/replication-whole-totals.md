* Engine: `replication_planning()` searches each BayesRepDesign goal over
  whole totals with the pors*() chance functions (every total up to 1,000,
  a 400-point grid beyond with each change pinned by bisection) instead of
  the ssd*() searches. The planned size is the smallest total from which
  every larger one meets the goal; smaller totals that also meet it are
  reported in the new `goals$also` column, and a goal met only by smaller
  replications has reason `"within_range"`. This fixes a pooled goal
  reported as out of reach where ssdMeta() fails (a strong original), a
  pooled goal missed at moderate sizes, and unequal groups whose search
  started above the smallest replication. porsMeta() is called one standard
  error at a time for an estimate below zero (upstream-questions.md,
  BayesRepDesign questions 2 and 3). The exported scripts search the same
  way and give the same numbers (queue item 29).
