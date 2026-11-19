* App: replication plans are named from `rep_study` and `rep_keeps`
  (`replication_auto_name()`) while the name is the default or was set
  this way. `plan_edit()` with a name stops the automatic naming. A
  summary card (`replication_overview_ui()`) shows what has been entered
  and the current sample size, from the planner server's new `answer`
  reactive. `replication_criteria_settings()` returns the criterion the
  purpose gives (`for_purpose`) and any `chosen` instead, which the Goals
  card states.
* App: with explanations off, each box with notes (`.form-group-box`,
  `.rep-routes`, `.rep-answer`, `.plan-action-group` and `.plan-note`)
  gets one corner info button that opens its notes, replacing the
  per-note "More context" links.
* App: the plan's Delete button moves beside the title. Step 1 no longer
  shows a second "Next" button once a decision is chosen. BUCSS's empty
  cells now read "None: once corrected, no effect is left to plan for".
