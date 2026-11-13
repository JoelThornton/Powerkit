* `write_study_plan()` takes optional `id`, `name` and `description`, and
  keeps each analysis's `plan_role` (`"primary"`, `"secondary"` or
  `"check"`) and `plan_note`; `read_study_plan()` returns them (`roles`
  and `notes` have one element per analysis, `NA` where absent). Absent
  fields are not written and the format version is unchanged, so a file
  saved now opens in the previous version, which ignores them.
* App: several named study plans (`R/study-plans.R`). A Study plans page
  (`?page=plans`, a tab hidden from the tab row) opens from the top bar
  and lists every plan kept in the browser; each plan has a page with its
  name, description, largest comparable N, joint power where offered, and
  each analysis with a role, a note, Open and Remove. Opening an analysis
  restores its card, answers and saved result as a project file does; a
  changed result offers "Update it in the plan" or "Add it as a new
  analysis". The browser keeps one key per plan
  (`powerkit-study-plan:<id>`) and an index (`powerkit-study-plans`)
  within a 3 MB budget; the old single plan becomes "My study plan", and
  its key is removed only after the new one is written. Opening a plan
  file never overwrites a plan: a different version with the same id is
  kept beside it. Each plan shows whether it has been saved to a file,
  the top bar marks unsaved plans, and the app asks the browser for
  persistent storage (`navigator.storage.persist()`).
