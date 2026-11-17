* New validation chunk `replication` (`test-validation-replication.R`)
  for `replication_planning()`. Each goal's chance (significance, pooled,
  agreement, replication Bayes factor, too small to matter), under each
  design prior, is checked against a simulation of Pawel, Consonni and
  Held's (2026) normal-normal model written separately: true effects
  drawn from the design prior, replication estimates around them, and the
  paper's success rules applied to the draws. The classical goal and small
  telescopes are also checked against t-tests on simulated people; the
  normal approximation's excess over the t-test is bounded at the 2
  points recorded in conventions.md. Published examples (Pawel, Consonni
  and Held's worked example; Simonsohn, 2015; a sceptical Bayes factor)
  are `TODO_PUBLISHED_VALUE` placeholders.
