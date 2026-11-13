* App: each study plan has an overview (its analyses counted by role) and
  "Download everything (.zip)" (`R/plan-bundle.R`): the plan file, written
  first and checked for in the finished zip; a study-wide planning document
  as Markdown and Word (the plan's name and description, a table of
  analyses with role, N, unit, target and backend, the largest comparable
  N or why there is none, joint power when it was calculated for the plan
  as it stands, each card's methods paragraph, and the references merged
  from the results' own citations); `references.txt`; and each analysis's
  own "Download everything" under `analyses/`, made from its saved spec
  and result without recalculating. Opening the zip opens the plan file at
  its top. `planning_methods_text()` gives a card's full methods paragraph
  on its own, and the Word documents now keep Markdown tables.
