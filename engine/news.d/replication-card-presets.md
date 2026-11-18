* App: a replication plan's original analysis is chosen from the
  searchable list of every analysis first (`rep_pick_design`), with a
  note naming the plan, and the design finder's questions second
  (`rep_find_design`). The card's input screen starts on the
  sample-size question at the plan's significance level and chance of
  success, and on E1 to E4 with the original's d, d_z or r as the plan
  holds it (`replication_form_values()`, `replication_card_effect_field()`);
  values already chosen are kept. The plan's five sections are drawn as
  numbered steps (still radio buttons) with a "Next" button under each
  (`replication_next_step_ui()`). Queue item 28.
