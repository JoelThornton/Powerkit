* App: the result screen separates keeping a result from the documents
  made from it (`R/keep-result.R`). "Keep this result", at the foot of
  the answer card, holds Save project file (now the screen's primary
  button), Copy a link and Add to my study plan, with a status that
  changes from "Not saved yet" once one is used; "Documents for your
  study" holds the planning document, the R script, citations and a new
  "Download everything (.zip)" (project file, planning document as
  Markdown and Word, R script, citations, the simulated data set where
  there is one, and a README). "Open a saved or shared project" accepts
  that zip and opens the one project file inside it. The last current
  result is kept in the browser's local storage beside the autosaved
  draft, and the "Continue your plan?" offer brings the result back when
  it matches the draft's answers; the browser asks before leaving a
  result that hasn't been kept. No engine change.
