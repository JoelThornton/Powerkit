conversion_spec <- function(template, conversion, type = "meta_analysis") {
  spec <- read_spec(example_path(template), validate = FALSE)
  spec$population[[conversion_templates[[template]]$effect]] <- NULL
  spec$effect_justification <- list(type = type, source = "A published result", conversion = conversion)
  spec
}

test_that("each conversion is its package's own, with its call recorded", {
  # t or F into d or d_z: psych's t2d(), the exact relation between t and
  # d (one group or pairs of n = df + 1: t / sqrt(n); two equal groups of
  # N = df + 2 in all: 2 t / sqrt(N)).
  cases <- list(
    list("independent_t", "t", 2.5, 58L, 2 * 2.5 / sqrt(60), "psych::t2d(t = 2.5, n = 60)", "psych"),
    list("independent_t", "F", 6.25, 58L, 2 * 2.5 / sqrt(60), "psych::t2d(t = 2.5, n = 60)", "psych"),
    list("independent_t", "r", 0.3, NULL, effectsize::r_to_d(0.3), "effectsize::r_to_d(r = 0.3)"),
    list("independent_t", "odds_ratio", 2, NULL, effectsize::oddsratio_to_d(2), "effectsize::oddsratio_to_d(OR = 2)"),
    list("one_sample_t", "t", 2.5, 29L, 2.5 / sqrt(30), "psych::t2d(t = 2.5, n1 = 30)", "psych"),
    list("paired_t", "t", 2.5, 29L, 2.5 / sqrt(30), "psych::t2d(t = 2.5, n1 = 30)", "psych"),
    list("paired_t", "F", 6.25, 29L, 2.5 / sqrt(30), "psych::t2d(t = 2.5, n1 = 30)", "psych"),
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
    expect_identical(out$package$name, if (length(case) > 6) case[[7]] else "effectsize", label = label)
  }
  # Unequal groups reach r_to_d() and d_to_r() with their sizes, and t2d()
  # as d = t sqrt(1 / n1 + 1 / n2).
  expect_equal(convert_effect("r", 0.3, "independent_t", n1 = 20, n2 = 60)$value, effectsize::r_to_d(0.3, 20, 60))
  out <- convert_effect("t", 3, "independent_t", df_error = 38L, n1 = 10L, n2 = 30L)
  expect_equal(out$value, 3 * sqrt(1 / 10 + 1 / 30))
  expect_identical(out$function_used, "psych::t2d(t = 3, n1 = 10, n2 = 30)")
  # A Welch t has fewer df than n1 + n2 - 2; the group sizes still give d.
  expect_equal(convert_effect("t", 3, "independent_t", df_error = 25L, n1 = 10L, n2 = 30L)$value, 3 * sqrt(1 / 10 + 1 / 30))
})

test_that("t into d by n, not by the error df: the size of the difference from effectsize's t_to_d()", {
  # effectsize's t_to_d() divides by sqrt(df) rather than sqrt(n), and
  # assumes equal groups (conventions.md, "Effect-size conversion").
  # One group of 20, t = 3: 0.671 here against 0.688 (2.6% larger).
  one <- convert_effect("t", 3, "one_sample_t", df_error = 19L)$value
  expect_equal(one, 0.6708204, tolerance = 1e-6)
  expect_equal(effectsize::t_to_d(3, 19, paired = TRUE)[[1]], 0.6882472, tolerance = 1e-6)
  # Two equal groups of 20: 0.949 against 0.973.
  expect_equal(convert_effect("t", 3, "independent_t", df_error = 38L)$value, 0.9486833, tolerance = 1e-6)
  expect_equal(effectsize::t_to_d(3, 38)[[1]], 0.9733285, tolerance = 1e-6)
  # Groups of 10 and 30: 1.095 against 0.973, which ignores the sizes.
  expect_equal(convert_effect("t", 3, "independent_t", df_error = 38L, n1 = 10L, n2 = 30L)$value, 1.0954451, tolerance = 1e-6)
  # The gap closes as n grows: under 0.3% with 200 in one group.
  big <- convert_effect("t", 3, "one_sample_t", df_error = 199L)$value
  expect_lt(abs(effectsize::t_to_d(3, 199, paired = TRUE)[[1]] / big - 1), 0.003)
})

test_that("validation puts the converted effect in the population, once", {
  spec <- validate_spec(conversion_spec("independent_t", list(from = "t", value = 2.5, df_error = 58L)))
  expect_equal(spec$population$d, 2 * 2.5 / sqrt(60))
  expect_equal(spec$effect_justification$conversion$result, spec$population$d)
  expect_identical(spec_hash(validate_spec(unclass(spec))), spec_hash(spec))
  result <- run_spec(spec)
  expect_identical(result$effect_conversion$effect_name, "Cohen's d")
  expect_identical(result$effect_conversion$from_name, "a t statistic")
  expect_equal(result$effect_conversion$value, 2.5)
  expect_equal(result$effect_conversion$converted, spec$population$d)
  expect_false(result$effect_conversion$earlier)
  expect_true("psych" %in% names(result$provenance$packages))
  expect_false("effectsize" %in% names(result$provenance$packages))
  expect_match(export_citations(result), "psych, which converted the effect size", fixed = TRUE)

  # r into d is still effectsize's, and cited as such.
  spec <- validate_spec(conversion_spec("independent_t", list(from = "r", value = 0.3)))
  result <- run_spec(spec)
  expect_true("effectsize" %in% names(result$provenance$packages))
  expect_match(export_citations(result), "effectsize, which converted the effect size", fixed = TRUE)
})

test_that("a plan saved with an earlier conversion keeps its value, and the result says so", {
  spec <- conversion_spec("one_sample_t", list(from = "t", value = 2.5, df_error = 29L))
  # As powerkit 0.24.0 converted it, with effectsize's t / sqrt(df).
  spec$effect_justification$conversion$result <- effectsize::t_to_d(2.5, 29, paired = TRUE)[[1]]
  spec$population$d <- spec$effect_justification$conversion$result
  result <- run_spec(validate_spec(spec))
  expect_equal(result$effect_conversion$converted, 2.5 / sqrt(29))
  expect_true(result$effect_conversion$earlier)
  expect_equal(result$effect_conversion$now, 2.5 / sqrt(30))
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
  expect_spec_problem(conversion_spec("independent_t", list(from = "t", value = 2.5, df_error = 58L, n1 = 10L)),
    "Give both group sizes ('effect_justification > conversion > n1' and 'effect_justification > conversion > n2'), or neither for equal groups.")
  expect_spec_problem(conversion_spec("independent_t", list(from = "t", value = 2.5, df_error = 58L, n1 = 10L, n2 = 30L)),
    "With groups of 10 and 30, a t or F statistic has at most 38 error degrees of freedom, not 58.")
  expect_spec_problem(conversion_spec("paired_t", list(from = "t", value = 2.5, df_error = 29L, n1 = 10L, n2 = 20L)),
    "are only used for two groups: the independent t-test or the correlation.")
  other <- read_spec(example_path("anova_2x2_between"), validate = FALSE)
  other$effect_justification$conversion <- list(from = "t", value = 2.5, df_error = 58L)
  expect_spec_problem(other, "not for this design yet")
})
