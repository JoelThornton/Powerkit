* `write_study_plan()` takes an optional `replication` list, the app's
  record of a replication plan (the pre-replication notes', the
  planner's fields and the original's card), kept as given;
  `read_study_plan()` returns it as `replication` (`NULL` when absent).
  Absent, it is not written.
* App: replication plans (queue item 23). A replication plan is a study
  plan with a `replication` record, started from the Study plans page,
  Labs or the input screen's signpost. Its page holds the
  pre-replication notes and the replication planner's sections, which
  leave Labs (`R/study-plan-replication.R`, `replication_notes_ui()`,
  `replication_planner_sections()`). The original's design is found
  with the design finder's questions and planned on its card, whose
  effect fields are labelled as the original's and whose result joins
  the plan. The write-up adds the original's analysis as its card
  planned it, and Download everything adds the write-up. With no
  analysis yet, the plan is saved as the Labs planner's file with the
  record beside it, so the previous version opens it; files the Labs
  planner saved open as new replication plans. No calculation changes.
