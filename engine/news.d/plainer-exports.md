* Exports: the R script's evidence comments (`evidence_record_text()`) use
  the planning document's plain labels and states, omit the registry's
  repeated note for a category with no linked record, give the scope in
  words, and replace the registry's developer-facing limits with two
  sentences on what the checks cover; the registry's identifiers come
  last. The simulated data set's script comment and help say plainly that
  the data are made from the values entered. In the app, the planning
  document, study plan report and whole-study report reword their opening
  disclaimer, assumption, attrition and closing notes, and the full
  methods paragraph names the package whose population check ran (queue
  item 26, exports).
* App: the simulation accuracy group's second note moved into the
  `simulation_accuracy` field's help (form help, queue item 26).
* Docs: `adding-a-test.md` gives a style rule for Updates entries
  (title of 70 characters or fewer, at most 100 words, what a researcher
  sees, no internal names), and `test-whats-new.R` checks the length and
  internal names in entries still waiting in `whats-new.d/`.
