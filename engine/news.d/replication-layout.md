* App: the replication planner in the input screens' style. Each step
  has a numbered title (`rep_section_title()`) and its questions are in
  titled cards (`rep_card()`); every choice is shown as the input
  screens' tiles, by CSS on the same radio buttons; number boxes are
  sized for a number (`rep-num`, with a number keyboard on phones where
  the value can't be negative); "Show the sample size" sits in one
  action bar with what is still needed (`replication_still_needed()`),
  as the input screens' bar does; the answer is in its own card; finished
  steps are ticked in the step bar (`replication_steps_done()`); and the
  result tables scroll sideways on phones.
