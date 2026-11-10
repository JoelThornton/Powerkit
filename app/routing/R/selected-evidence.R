# Show the selected complete spec, not the card's broader default badge.
selected_evidence_ui <- function(forms, id, fields, values) {
  pending <- p(class = "selected-evidence small",
    "Evidence depends on your test version and assumptions. Complete the required answers to see which recorded checks cover these settings.")
  spec <- tryCatch({
    if (length(form_problems(fields, values))) NULL else {
      candidate <- build_spec(forms, id, fields, values)
      if (identical(check_spec(candidate, fields)$status, "ok")) candidate else NULL
    }
  }, error = function(e) NULL)
  if (is.null(spec)) return(pending)
  lookup <- engine_function("analysis_evidence")
  record <- if (!is.null(lookup)) tryCatch(lookup(spec), error = function(e) NULL)
  if (is.null(record)) return(pending)
  tagList(
    if (!is.null(note <- gg_planning_note(spec))) div(class = "alert alert-warning selected-method-warning", role = "status", note),
    p(class = "selected-evidence small", "Selected settings: evidence is limited to recorded cases. A card's status does not validate every test version or assumption."),
    evidence_ui(record, "Checks covering my selected settings"))
}
