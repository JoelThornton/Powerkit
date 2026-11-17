* `replication_planning()` offers bfpwr's Bayes factor t-test goals
  (`bf_repeat`, `bf_null`) for every t-test original (two groups, one
  sample, pairs), at the default prior scale 0.707 when the original
  reported no Bayes factor, so a replication of a frequentist study can
  plan a default Bayes factor. The script names the test as "a default
  Bayes factor t-test" or "the original's Bayes factor test repeated".
* Replication plans (app) ask the researcher's purpose first and give one
  sample size, from one main criterion under one chosen belief; each
  criterion under "Also report" is given as its chance at that sample
  size, from a second engine call at that n. A criterion that can show
  absence starts ticked (Departure 30, `docs/conventions.md`): the Bayes
  factor for no effect, else the replication Bayes factor, with a Bayes
  factor main criterion, and the equivalence test otherwise, bounded by
  d33 (Simonsohn, 2015) when no smallest effect is entered. The
  smallest effect and the evidence threshold are asked only when a chosen
  criterion uses them; references and the write-up's table follow the
  chosen criteria. The table of every criterion under every belief is
  folded under the answer.
