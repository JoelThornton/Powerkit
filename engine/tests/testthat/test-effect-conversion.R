conversion_spec <- function(template, conversion, type = "meta_analysis") {
  spec <- read_spec(example_path(template), validate = FALSE)
  spec$population[[conversion_templates[[template]]$effect]] <- NULL
  spec$effect_justification <- list(type = type, source = "A published result", conversion = conversion)
  spec
}

test_that("each conversion is effectsize's own, with its call recorded", {
  cases <- list(
    list("independent_t", "t", 2.5, 58L, effectsize::t_to_d(2.5, 58)[[1]], "effectsize::t_to_d(t = 2.5, df_error = 58)"),
    list("independent_t", "F", 6.25, 58L, effectsize::F_to_d(6.25, 1, 58)[[1]], "effectsize::F_to_d(f = 6.25, df = 1, df_error = 58)"),
    list("independent_t", "r", 0.3, NULL, effectsize::r_to_d(0.3), "effectsize::r_to_d(r = 0.3)"),
    list("independent_t", "odds_ratio", 2, NULL, effectsize::oddsratio_to_d(2), "effectsize::oddsratio_to_d(OR = 2)"),
    list("one_sample_t", "t", 2.5, 29L, effectsize::t_to_d(2.5, 29, paired = TRUE)[[1]], "effectsize::t_to_d(t = 2.5, df_error = 29, paired = TRUE)"),
    list("paired_t", "t", 2.5, 29L, effectsize::t_to_d(2.5, 29, paired = TRUE)[[1]], "effectsize::t_to_d(t = 2.5, df_error = 29, paired = TRUE)"),
    list("paired_t", "F", 6.25, 29L, effectsize::F_to_d(6.25, 1, 29, paired = TRUE)[[1]], "effectsize::F_to_d(f = 6.25, df = 1, df_error = 29, paired = TRUE)"),
    list("correlation", "t", 2.5, 58L, effectsize::t_to_r(2.5, 58)[[1]], "effectsize::t_to_r(t = 2.5, df_error = 58)"),
    list("correlation", "F", 6.25, 58L, effectsize::F_to_r(6.25, 1, 58)[[1]], "effectsize::F_to_r(f = 6.25, df = 1, df_error = 58)"),
    list("correlation", "d", 0.5, NULL, effectsize::d_to_r(0.5), "effectsize::d_to_r(d = 0.5)"),
    list("correlation", "odds_ratio", 2, NULL, effectsize::oddsratio_to_r(2), "effectsize::oddsratio_to_r(OR = 2)")
  )
  for (case in cases) {
    out <- convert_effect(case[[2]], case[[3]], case[[1]], df_error = case[[4]])
    label <- paste(case[[1]], case[[2]])
    expect_equal(out$value, case[[5]], label = label)
    expect_identical(out$function_used, case[[6]], label = label)
    expect_identical(out$package$name, "effectsize")
  }
  # Unequal groups reach r_to_d() and d_to_r() with their sizes.
  expect_equal(convert_effect("r", 0.3, "independent_t", n1 = 20, n2 = 60)$value, effectsize::r_to_d(0.3, 20, 60))
})

test_that("validation puts the converted effect in the population, once", {
  spec <- validate_spec(conversion_spec("independent_t", list(from = "t", value = 2.5, df_error = 58L)))
  expect_equal(spec$population$d, effectsize::t_to_d(2.5, 58)[[1]])
  expect_equal(spec$effect_justification$conversion$result, spec$population$d)
  expect_identical(spec_hash(validate_spec(unclass(spec))), spec_hash(spec))
  result <- run_spec(spec)
  expect_identical(result$effect_conversion$effect_name, "Cohen's d")
  expect_identical(result$effect_conversion$from_name, "a t statistic")
  expect_equal(result$effect_conversion$value, 2.5)
  expect_equal(result$effect_conversion$converted, spec$population$d)
  expect_true("effectsize" %in% names(result$provenance$packages))
  expect_match(export_citations(result), "effectsize, which converted the effect size", fixed = TRUE)
})

test_that("a converted effect then takes safeguard power from it", {
  spec <- conversion_spec("correlation", list(from = "t", value = 3, df_error = 98L), type = "prior_study")
  spec$effect_justification$safeguard <- list(n = 100L, protection = 0.8)
  spec <- validate_spec(spec)
  converted <- effectsize::t_to_r(3, 98)[[1]]
  expect_equal(spec$effect_justification$safeguard$estimate, converted)
  expect_lt(spec$population$r, converted)
})

test_that("conversion problems are explained in plain words", {
  expect_spec_problem(conversion_spec("independent_t", list(from = "t", value = 2.5)),
    "Converting a t statistic needs its error degrees of freedom ('df_error').")
  expect_spec_problem(conversion_spec("independent_t", list(from = "d", value = 0.5)),
    "For this design, an effect size can be converted from a t statistic, an F statistic, r or an odds ratio, not from Cohen's d.")
  both <- conversion_spec("independent_t", list(from = "t", value = 2.5, df_error = 58L))
  both$population$d <- 0.5
  expect_spec_problem(both, "Give one: the conversion fills in the effect size.")
  other <- read_spec(example_path("anova_2x2_between"), validate = FALSE)
  other$effect_justification$conversion <- list(from = "t", value = 2.5, df_error = 58L)
  expect_spec_problem(other, "not for this design yet")
})
