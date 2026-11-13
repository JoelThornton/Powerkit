* `write_study_plan()` takes an optional `guided` list, the app's record
  of a guided whole-study plan, kept as given; `read_study_plan()` returns
  it as `guided` (`NULL` when absent). Absent, it is not written.
* App: "Plan my whole study" joins a study plan. When the guided route
  first reaches its list of analyses it fills the plan whose "Add an
  analysis" was pressed, or makes "Whole-study plan, <date>"; the guided
  record (now with the last whole-study run's summary) is kept in the
  plan and updated as the guided plan changes, and each analysis
  calculated from it joins the plan with the guided plan's role. The
  plan's page shows the guided plan, its last whole-study result and
  "Open the guided plan". "Save this plan" and its link on the guided
  screens save the study plan. A plan with a guided plan but no
  calculated analysis is saved as a guided-plan file carrying the plan's
  id, name and description, so the previous version still opens it; an
  older guided-plan file opens as a new whole-study plan.
