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
* App: a focused field that would sit under a sticky `.action-bar` is
  scrolled clear of it (`focus_js`, with `scroll-padding-bottom` on pages
  that have one), meeting WCAG 2.4.11. `replication_assurances_ui` lists
  50% first, in the order of the comparison tables; 80% stays selected.
* App: the replication planner's labels and choices are concise and the
  same in both modes (decisions.d/concise-labels.md); what they explained
  is in field help or textarea placeholders, and explanatory paragraphs
  take the class `plain-only`, hidden with explanations off. A test caps
  labels and choices at 75 characters. Four criterion labels are shorter
  (`replication_goal_labels`); `replication_goal_written()` adds the
  threshold to the replication and sceptical Bayes factors by criterion.
