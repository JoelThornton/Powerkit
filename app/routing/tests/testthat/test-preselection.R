# Choices the researcher makes, not the screen (22 November 2026): where
# tests answer the same question and none is clearly better, or where
# the answer depends on the researcher's claim, the input starts empty.

field_of <- function(ep, id) {
  f <- Filter(function(f) identical(f$id, id), form_fields(form_groups(forms, ep)))
  expect_length(f, 1)
  f[[1]]
}

test_that("equivalent tests start unchosen, with the usual one marked where there is one", {
  unchosen <- list(E33 = "binary_test", E67 = "binary_test", E68 = "three_test", E41 = "two_test", E62 = "two_test",
    E75 = "glmm_test", E70 = "multinomial_test", E32 = "cat_test", E71 = "irt_stat")
  for (ep in names(unchosen)) {
    f <- field_of(ep, unchosen[[ep]])
    expect_null(f$default, label = ep)
    expect_true(isTRUE(f$required), label = ep)
  }
  for (ep in c("E33", "E67", "E68", "E41", "E62")) {
    expect_match(field_of(ep, unchosen[[ep]])$choices$wald, "the usual one", fixed = TRUE, label = ep)
  }
})

test_that("the likelihood-ratio test stays selected on E63, and the screen says why", {
  f <- field_of("E63", "binary_test")
  expect_identical(f$default, "likelihood_ratio")
  expect_match(f$help, "6.2%", fixed = TRUE)
  expect_false(grepl("usual", f$choices$wald))
})

test_that("pairwise comparisons ask whether to adjust, with Holm's recommended", {
  for (ep in c("E18", "E54", "E63")) {
    f <- field_of(ep, "p_adjust")
    expect_null(f$default, label = ep)
    expect_true(isTRUE(f$required), label = ep)
    expect_match(f$choices$holm, "recommended if you correct", fixed = TRUE, label = ep)
    expect_match(f$help, "your claim", fixed = TRUE, label = ep)
  }
})

test_that("a whole study with two or more main analyses starts with no claim rule", {
  answers <- list(x = "cond2", outcome = "score", mediators = "one", moderator = "none", covariate = "none")
  html <- as.character(guided_analyses_ui(tree, answers, character(), character(), list(), NULL))
  expect_false(grepl('value="each" checked', html, fixed = TRUE))
  expect_match(html, "Say above what your study's claim needs", fixed = TRUE)
  # The plan screen copes with a rule not chosen yet.
  ids <- vapply(tree$guided$analyses, `[[`, "", "id")
  plan <- as.character(guided_plan_ui(tree, answers, ids[1:2], ids[1:2], list(), NULL))
  expect_match(plan, "not chosen yet", fixed = TRUE)
})

test_that("a guided plan saved without a rule reopens without one", {
  ids <- vapply(tree$guided$analyses, `[[`, "", "id")
  state <- list(route = "plan", start = list(aim = "plan"), ctx = list(), history = list(),
    answers = list(), ticked = ids[1], primary = ids[1], asks = list(), rule = NULL,
    plan_values = list(), plan_shared = list(), plan_results = list(), ws_values = list(),
    ws_names = list(), ws_spec = NULL, ws_result = NULL)
  file <- tempfile(fileext = ".powerkit.json")
  write_guided_plan(state, file)
  restored <- restore_guided_plan(read_guided_plan_record(file), tree)
  expect_type(restored, "list")
  expect_null(restored$rule)
  state$rule <- "all"
  write_guided_plan(state, file)
  expect_identical(restore_guided_plan(read_guided_plan_record(file), tree)$rule, "all")
})
