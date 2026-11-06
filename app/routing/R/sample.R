# Shared presentation metadata. All scientific counts/allocation come from
# the engine; these helpers never calculate power or recruitment.
result_sample_n <- function(result, required_only = FALSE) {
  required <- identical(result$goal_type, "sample_size") ||
    (identical(result$goal_type, "precision") && !is.na(result$precision$target_width %||% NA))
  if (required && is.list(result$n_required)) return(result$n_required$n)
  if (isTRUE(required_only)) return(NULL)
  if (is.list(result$curve) || is.data.frame(result$curve)) return(result$curve$n[1])
  result$precision$n %||% NA_real_
}

sample_description <- function(spec, describe = engine_function("sample_structure")) {
  unknown <- list(unit = "analysis units", note = "This count is kept separate because its sample structure could not be identified.", compatibility_key = NULL)
  if (is.null(describe) || is.null(spec)) return(unknown)
  tryCatch(describe(spec), error = function(e) unknown)
}

plan_sample <- function(spec, describe = engine_function("sample_structure")) sample_description(spec, describe)
plan_n <- function(result) result_sample_n(result, required_only = TRUE)
n_analysed <- function(result) result_sample_n(result)
