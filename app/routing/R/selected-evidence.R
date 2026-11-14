# Warning identity is available before numerical inputs are complete. Only
# declared analysis/type selectors are applied; no population value is imputed.
# The method, the factors' levels and the SDs and correlations entered are
# applied too, because whether a corrected repeated-measures test is
# approximated (Departure 28) depends on them.
selected_warning_spec <- function(form, fields, values) {
  spec <- form$base
  identity_path <- function(path) !is.null(path) && grepl(
    "^(design|template|variables[.][^.]+[.](type|levels)|target_test[.](method|correction)|options[.]method|population[.](sd|r))$", path)
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
  # Nothing is said about checks until the answers name a calculation.
  pending <- NULL
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
    explanation_ui("selected-evidence-info", "Evidence for these settings",
      p(class = "selected-evidence small", "Selected settings: evidence is limited to recorded cases. A card's status does not validate every test version or assumption.")),
    evidence_ui(record, "Checks covering my selected settings"))
}
