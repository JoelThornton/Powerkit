# Pairwise rank comparisons as test versions (17 November 2026): after the
# Kruskal-Wallis test on E18 (a Mann-Whitney test of each pair, or Dunn's
# test) and after Friedman's test on E54 (a signed-rank test of each pair,
# or Conover's test). The researcher chooses; neither is preselected.

pair_values <- function(ep, method, pair) {
  v <- modifyList(form_examples[[ep]], list(goal = "power", n = if (ep == "E18") "90" else "30",
    test_version = method, comparison = pair, p_adjust = "holm", score_shape = "skewed"))
  v
}

test_that("each pairwise rank test is a choice, not a default, and asks for the pair, the adjustment and the shape", {
  for (ep in c("E18", "E54")) {
    fields <- form_fields(form_groups(forms, ep))
    version <- Filter(function(f) identical(f$id, "test_version"), fields)[[1]]
    methods <- if (ep == "E18") c("mann_whitney", "dunn") else c("wilcoxon_signed_rank", "conover")
    expect_true(all(methods %in% names(version$choices)), label = ep)
    expect_false(isTRUE(version$default %in% methods), label = ep)
    expect_true(all(methods %in% names(version$choice_notes)), label = ep)
    for (m in methods) {
      values <- list(test_version = m)
      shown <- vapply(Filter(function(f) f$id %in% c("comparison", "p_adjust", "score_shape"), fields),
        function(f) field_applies(f, values), logical(1))
      expect_true(all(shown) && length(shown) == 3, label = paste(ep, m))
    }
  }
})

test_that("the input screen builds the spec of the pair's rank test", {
  fields <- form_fields(form_groups(forms, "E18"))
  levels <- parse_levels(form_examples$E18$A_levels)
  spec <- build_spec(forms, "E18", fields, pair_values("E18", "dunn", paste(levels[1], levels[3], sep = ", ")))
  expect_identical(spec$target_test$effect, "pairwise")
  expect_identical(spec$target_test$method, "dunn")
  expect_identical(spec$population$score_shape, "skewed")
  expect_length(unlist(spec$target_test$comparison), 2)
  fields54 <- form_fields(form_groups(forms, "E54"))
  levels54 <- parse_levels(form_examples$E54$A_levels)
  spec54 <- build_spec(forms, "E54", fields54, pair_values("E54", "conover", paste(levels54[1], levels54[2], sep = ", ")))
  expect_identical(spec54$target_test$method, "conover")
  expect_identical(spec54$target_test$effect, "pairwise")
  # The result names the test and the shape assumed.
  name <- pairwise_test_name(spec54)
  expect_match(name, "Conover's test", fixed = TRUE)
  expect_match(name, "simulated assuming", fixed = TRUE)
  expect_match(pairwise_test_name(spec), "Dunn's test", fixed = TRUE)
  expect_true(is_rank_test(spec))
})

test_that("the analysis search finds the pairwise rank tests by name", {
  names <- vapply(tree$test_versions, `[[`, "", "name")
  expect_true(all(c("Dunn's test", "Conover's test", "Pairwise Mann-Whitney tests", "Pairwise Wilcoxon signed-rank tests") %in% names))
})
