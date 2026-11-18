* App: replication plan review fixes. The planner's guidance goes
  through `rep_note()` (one sentence in view, the rest under "More";
  folded behind an info button with explanations off, except caveats
  and prompts) and its text fields through `rep_field()`, as the input
  screens' fields are laid out. `replication_analyses_ui` gains "both"
  (a significance test and a Bayes factor): the engine is called as for
  a test, with the Bayes factor's prior scale (`original_prior_scale`),
  and the Bayes factor (`rep_bf_both`, optional) is recorded in the
  write-up. With the notes' outcome "Not worth replicating",
  `replication_report()` returns the negative pre-replication report,
  the downloads are named for it, the R script is not offered and the
  planning steps say they aren't needed.
