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

test_that("a Bayes factor t-test result shows how the plan changes with the prior's width", {
  rob <- data.frame(prior = c("Medium (JASP's default), your prior", "Wide"), scale = c(0.707, 1),
    for_effect = c(0.8, 0.78), for_null = c(0, 0.58), misleading = c(0.002, 0.001))
  spec <- list(target_test = list(evidence_threshold = 10))
  html <- as.character(bayes_robustness_ui(spec, rob))
  expect_match(html, "Does the prior matter?", fixed = TRUE)
  expect_match(html, "BF01 of at least 10, if there is no effect", fixed = TRUE)
  expect_match(html, "<td>58%</td>", fixed = TRUE)
  expect_null(bayes_robustness_ui(spec, NULL))
  # The SD of the design prior is read as a range on the screen.
  html <- as.character(form_ui(tree, forms, "E1", form_groups(forms, "E1"), list(method = "bayes_factor")))
  expect_match(html, 'id="f_effect_sd_reading"', fixed = TRUE)
  expect_match(html, "95%% sure|95% sure")
})

test_that("a Bayes factor t-test result offers the same plan as a sequential design", {
  v <- modifyList(form_examples$E2, list(method = "bayes_factor", evidence_threshold = "10", prior_scale = "0.707", effect_sd = "0.1"))
  v$welch_sd_ratio <- NULL
  spec <- build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), v)
  result <- list(goal_type = "sample_size", n_required = list(n = 200))
  html <- as.character(bayes_sequential_card_ui(spec, result))
  expect_match(html, "Check as you go?", fixed = TRUE)
  expect_match(html, "or at 100 in each group at most", fixed = TRUE)
  args <- bayes_sequential_args(spec, 200, 20, 5, 6)
  expect_identical(args$n_max, 100)
  expect_identical(args$type, "two.sample")
  expect_equal(args$effect, 0.4)
  expect_equal(args$effect_sd, 0.1)
  expect_equal(args$threshold, 10)
  expect_equal(args$threshold_null, 6)
  # The engine accepts them (a small run).
  args$nsim <- 200
  plan <- do.call(engine_function("bayes_sequential"), args)
  expect_identical(plan$n_max, 100)
  # Not on p-value plans.
  freq <- build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), form_examples$E2)
  expect_null(bayes_sequential_card_ui(freq, result))
})

test_that("a Bayes factor t-test planned for one exact effect offers the average over an uncertain effect", {
  spec_with <- function(sd) {
    v <- modifyList(form_examples$E2, list(method = "bayes_factor", evidence_threshold = "10", prior_scale = "0.707", effect_sd = sd))
    v$welch_sd_ratio <- NULL
    build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), v)
  }
  result <- list(goal_type = "sample_size", n_required = list(n = 200))
  html <- as.character(bayes_uncertain_ui(spec_with("0"), result))
  expect_match(html, "Not sure of the effect?", fixed = TRUE)
  expect_match(html, "bayes_uncertain_sd", fixed = TRUE)
  expect_match(html, "assurance", fixed = TRUE)
  # Not when the plan already spreads the effect, and not on a p-value test.
  expect_null(bayes_uncertain_ui(spec_with("0.1"), result))
  expect_null(bayes_uncertain_ui(build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), form_examples$E2), result))
  # The engine's answer, in words: the average chance at the plan's n,
  # and the n for the target on average.
  skip_if(is.null(engine_function("run_spec")), "needs powerkit's engine")
  run <- engine_function("run_spec")
  spec <- spec_with("0")
  spec$population$effect_sd <- 0.2
  with_goal <- function(spec, goal) { spec$goal <- goal; spec }
  at_n <- run(with_goal(spec, list(type = "power", n = 200L)))
  needed <- run(with_goal(spec, list(type = "sample_size", power = 0.8)))
  words <- bayes_uncertain_words(spec, 0.2, at_n, needed)
  expect_match(words[1], "give or take 0.2, a study of 200 people in total has", fixed = TRUE)
  expect_match(words[2], sprintf("you would need %s people in total", whole(needed$n_required$n)), fixed = TRUE)
  # Averaging changes the chance (here, below 50%, it raises it).
  expect_false(isTRUE(all.equal(at_n$curve$power, run(with_goal(spec_with("0"), list(type = "power", n = 200L)))$curve$power)))
})
