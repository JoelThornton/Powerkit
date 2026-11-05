# "Add a Bayes factor?" on p-value results (bayes_companion_card_ui(),
# bayes_companion_ui()). The numbers are the engine's bayes_companion().

test_that("the card appears on p-value plans of designs with an exact Bayes factor version", {
  spec_for <- function(ep, ...) {
    v <- modifyList(form_examples[[ep]], list(...))
    build_spec(forms, ep, form_fields(form_groups(forms, ep)), v)
  }
  result <- list(goal_type = "sample_size", n_required = list(n = 90))
  for (ep in c("E1", "E2", "E3", "E4", "E5", "E25", "E18")) {
    expect_false(is.null(bayes_companion_card_ui(tree, ep, spec_for(ep), result)), label = ep)
  }
  # Not on the Bayes factor version itself, a rank test, or a table
  # (simulated, too slow to offer here).
  expect_null(bayes_companion_card_ui(tree, "E1", spec_for("E1", method = "bayes_factor", evidence_threshold = "10", prior_scale = "0.707"), result))
  expect_null(bayes_companion_card_ui(tree, "E1", spec_for("E1", method = "wilcoxon_signed_rank", score_shape = "normal"), result))
  expect_null(bayes_companion_card_ui(tree, "E6", spec_for("E6"), result))
})

test_that("the Bayes factor side reads its chances, the size for both, the agreement and the plan's wording", {
  spec <- build_spec(forms, "E1", form_fields(form_groups(forms, "E1")), form_examples$E1)
  result <- list(goal_type = "sample_size", n_required = list(n = 90))
  comp <- engine_function("bayes_companion")(spec, 90, target = 0.8)
  html <- as.character(bayes_companion_ui(spec, result, comp))
  expect_match(html, "With 90 participants, analysing the same data with the Bayes factor t-test", fixed = TRUE)
  expect_match(html, "Evidence that there is no effect, if there is none", fixed = TRUE)
  expect_match(html, sprintf("needs %s participants for a Bayes factor of 3", comp$n_for_both$n_bayes[1]), fixed = TRUE)
  expect_match(html, "How often the two would agree (Bayes factor of 3)", fixed = TRUE)
  expect_match(html, "The main analysis is a two-sided one-sample t-test at alpha = .05.", fixed = TRUE)
  expect_match(html, "at least an 80% chance of reaching 3", fixed = TRUE)
  # 90 can't reach a Bayes factor of 10 for no effect, and says so.
  expect_match(html, "can(&#39;|')t reach a Bayes factor of 10 for no effect")
  # A plan with no Bayes counterpart says why, in words.
  expect_match(as.character(bayes_companion_ui(spec, result, list(available = FALSE, reason = "Because."))), "Because.", fixed = TRUE)
  expect_identical(with_article("80%"), "an 80%")
  expect_identical(with_article("75%"), "a 75%")
})
