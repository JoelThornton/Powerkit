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

# The input screen shows only the warnings that apply to the answers so
# far (a known limitation of the chosen method). The checks recorded for
# exactly these settings are on the result ("Checks recorded for exactly
# these settings"), not above the form while it is being filled in (15
# November 2026).
selected_evidence_ui <- function(forms, id, fields, values) {
  tagList(planning_warnings_ui(selected_warning_spec(forms$forms[[id]], fields, values)))
}
