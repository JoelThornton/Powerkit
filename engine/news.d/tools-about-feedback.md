* Tools starts a replication plan again: a "Replication planner" card,
  first under "For planning", opens a new replication plan
  (`labs_replication_card()`).
* About's "What it can plan" folds the coloured list of every analysis
  that calculates, by family (`about_plans_ui()`, restored).
* The capability table on About has one row per analysis, with its usual
  name, the test versions it offers and how it runs
  (`capability_summary()`). Its search ranks rows whose name matches
  before rows whose test versions match, before rows that match only in
  their limits, so "anova" lists the ANOVAs first. The full per-choice
  table downloads as a spreadsheet (`capability_table_csv()`, readable
  column names), from a button outside the fold.
* Feedback: once a message is stored, Send becomes "Sent" and is disabled,
  and a green panel confirms it, until the message is edited (`fb_sent`).
