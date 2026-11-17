# Analysis identity stays visible beside the answer and in the methods text.
is_corrected_count_test <- function(spec) {
  identical(spec$design, "basic_test") && isTRUE(spec$target_test$method %in%
    c("z_test_corrected", "pearson_chi_square_corrected"))
}

count_test_sentence <- function(spec) {
  if (!identical(spec$design, "basic_test")) return(NULL)
  method <- spec$target_test$method
  if (identical(spec$template, "two_proportions") && method %in% c("z_test", "z_test_corrected")) {
    return(paste("The planned two-proportion test is",
      if (is_corrected_count_test(spec)) paste0("with continuity correction (R's prop.test(correct = TRUE)), with fixed group sizes, ",
        if (identical(spec$options$method, "simulation")) "simulated." else "worked out exactly over every possible result.")
      else "without continuity correction; use this only if the study's analysis will also omit the correction. R's prop.test() applies it by default."))
  }
  if (identical(spec$template, "chi_square_independence") &&
      method %in% c("pearson_chi_square", "pearson_chi_square_corrected")) {
    return(if (is_corrected_count_test(spec)) paste(
      "The planned 2 by 2 Pearson chi-square test includes continuity correction (R's chisq.test(correct = TRUE)).",
      paste0("The total sample size is fixed and row and column totals vary; power is ",
        if (identical(spec$options$method, "simulation")) "simulated." else "worked out exactly over every possible table.",
        " For fixed group sizes, use the two-proportions design."))
    else paste("The planned Pearson chi-square test is without continuity correction.",
      "R's chisq.test() applies it by default to 2 by 2 tables only; match your planned analysis."))
  }
  NULL
}
