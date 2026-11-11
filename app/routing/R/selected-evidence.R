# Warning identity is available before numerical inputs are complete. Only
# declared analysis/type selectors are applied; no population value is imputed.
selected_warning_spec <- function(form, fields, values) {
  spec <- form$base
  identity_path <- function(path) !is.null(path) && grepl(
    "^(design|template|variables[.][^.]+[.]type|target_test[.](method|correction))$", path)
  for (f in fields) {
    value <- values[[f$id]]
    if (blank(value) || !field_applies(f, values)) next
    if (identity_path(f$path)) spec <- set_path(spec, split_path(f$path), field_value(f, value, values))
    for (extra in f$sets[[as.character(value)]]) if (identity_path(extra$path) && field_applies(extra, values))
      spec <- set_path(spec, split_path(extra$path), extra$value)
  }
  spec
}

# Show the selected complete spec, not the card's broader default badge.
selected_evidence_ui <- function(forms, id, fields, values) {
  warning_spec <- selected_warning_spec(forms$forms[[id]], fields, values)
  warnings <- planning_warnings_ui(warning_spec)
  pending <- p(class = "selected-evidence small",
    "Evidence depends on your test version and assumptions. Complete the required answers to see which recorded checks cover these settings.")
  spec <- tryCatch({
    if (length(form_problems(fields, values))) NULL else {
      candidate <- build_spec(forms, id, fields, values)
      if (identical(check_spec(candidate, fields)$status, "ok")) candidate else NULL
    }
  }, error = function(e) NULL)
  if (is.null(spec)) return(tagList(warnings, pending))
  lookup <- engine_function("analysis_evidence")
  record <- if (!is.null(lookup)) tryCatch(lookup(spec), error = function(e) NULL)
  if (is.null(record)) return(tagList(warnings, pending))
  tagList(warnings,
    p(class = "selected-evidence small", "Selected settings: evidence is limited to recorded cases. A card's status does not validate every test version or assumption."),
    evidence_ui(record, "Checks covering my selected settings"))
}
