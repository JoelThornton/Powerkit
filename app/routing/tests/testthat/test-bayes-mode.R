# Bayes mode (R/bayes-mode.R): an opt-in switch on the start screen; with it
# on, a card with a Bayes factor version opens its input screen on that
# version, and a card without one says so.

test_that("the switch is on the start screen, off unless chosen", {
  off <- as.character(bayes_mode_toggle_ui(FALSE))
  expect_match(off, "Bayes mode: I'll analyse with Bayes factors", fixed = TRUE)
  expect_match(off, "pkSetBayesMode(this.checked)", fixed = TRUE)
  # Kept for the browser tab, so a reload keeps it.
  expect_match(bayes_mode_js, "sessionStorage.getItem('powerkit-bayes-mode')", fixed = TRUE)
  expect_no_match(off, " checked[ />=]", perl = TRUE)
  expect_match(as.character(bayes_mode_toggle_ui(TRUE)), " checked[ />=]", perl = TRUE)
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "bayes_mode_toggle_ui(isolate(state$bayes_mode))", fixed = TRUE)
  expect_match(code, "bayes_mode = FALSE", fixed = TRUE)
  expect_match(code, "tags$script(HTML(bayes_mode_js))", fixed = TRUE)
})

test_that("in Bayes mode a card with a Bayes factor version opens on it", {
  d <- tree$bayes_designs$E2
  expect_false(is.null(d))
  values <- bayes_mode_form_values(tree, "E2", list(), TRUE)
  expect_identical(values[[d$field]], "bayes_factor")
  # Off, nothing changes; a test version already chosen is kept.
  expect_length(bayes_mode_form_values(tree, "E2", list(), FALSE), 0)
  kept <- stats::setNames(list("student_t"), d$field)
  expect_identical(bayes_mode_form_values(tree, "E2", kept, TRUE)[[d$field]], "student_t")
  # The values give the Bayes factor spec.
  fields <- form_fields(form_groups(forms, "E2"))
  spec <- build_spec(forms, "E2", fields, modifyList(form_examples$E2, values))
  expect_identical(spec$target_test$method, "bayes_factor")
  expect_match(as.character(bayes_mode_card_note(tree, "E2", TRUE)), "opens with this design's Bayes factor version", fixed = TRUE)
  expect_null(bayes_mode_card_note(tree, "E2", FALSE))
})

test_that("a card without a Bayes factor version says so in Bayes mode", {
  with_form <- names(forms$forms)[names(forms$forms) %in% names(tree$endpoints)]
  without <- setdiff(with_form, names(tree$bayes_designs))
  expect_gt(length(without), 0)
  ep <- without[1]
  expect_match(as.character(bayes_mode_card_note(tree, ep, TRUE)), "no Bayes factor version of this design yet", fixed = TRUE)
  expect_length(bayes_mode_form_values(tree, ep, list(), TRUE), 0)
})

test_that("in Bayes mode the t-tests wait for how unsure you are about the effect", {
  groups <- form_groups(forms, "E2")
  plain <- Filter(function(f) identical(f$id, "effect_sd"), form_fields(groups))[[1]]
  expect_equal(plain[["default"]], 0)
  mode <- Filter(function(f) identical(f$id, "effect_sd"), form_fields(bayes_mode_groups(groups, TRUE)))[[1]]
  expect_null(mode[["default"]])
  expect_true(isTRUE(mode$required))
  expect_match(mode$default_source, "powerkit won't suggest an SD", fixed = TRUE)
  # Empty, the screen asks for it before planning.
  values <- modifyList(form_examples$E2, list(method = "bayes_factor", effect_sd = ""))
  expect_true(length(form_problems(form_fields(bayes_mode_groups(groups, TRUE)), values)) > 0)
  # The test version's note says why the Bayes factor is chosen.
  version <- Filter(function(f) identical(f$path, "target_test.method"), form_fields(bayes_mode_groups(groups, TRUE)))[[1]]
  expect_identical(version[["default"]], "bayes_factor")
  expect_match(version$default_source, "Bayes mode", fixed = TRUE)
  # Off, nothing changes.
  expect_identical(bayes_mode_groups(groups, FALSE), groups)
  # The correlation and the proportions too.
  for (ep in c("E4", "E5", "E25")) {
    sds <- Filter(function(f) f$id %in% bayes_mode_prior_fields, form_fields(bayes_mode_groups(form_groups(forms, ep), TRUE)))
    expect_length(sds, 1)
    expect_null(sds[[1]][["default"]])
  }
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "bayes_mode_groups(form_groups(forms, state$endpoint", fixed = TRUE)
})
