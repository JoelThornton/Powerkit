# Bayes factors (R/bayes-mode.R): an opt-in switch on both ways to find an
# analysis (from 12 November 2026; on the start screen before); with it
# on, a card with a Bayes factor version opens its input screen on that
# version, and a card without one says so.

test_that("the switch is on both ways to find an analysis, off unless chosen, and not on the start screen", {
  off <- as.character(bayes_mode_toggle_ui(FALSE))
  expect_match(off, "I'll analyse with Bayes factors", fixed = TRUE)
  expect_match(off, "pkSetBayesMode(this.checked)", fixed = TRUE)
  # Kept for the browser tab, so a reload keeps it.
  expect_match(bayes_mode_js, "sessionStorage.getItem('powerkit-bayes-mode')", fixed = TRUE)
  expect_no_match(off, " checked[ />=]", perl = TRUE)
  expect_match(as.character(bayes_mode_toggle_ui(TRUE)), " checked[ />=]", perl = TRUE)
  expect_no_match(as.character(start_ui(tree)), "bayes_mode_switch", fixed = TRUE)
  expect_match(as.character(known_ui(tree)), "bayes_mode_switch", fixed = TRUE)
  first <- names(tree$nodes)[1]
  expect_match(as.character(node_ui(tree, first, list())), "bayes_mode_switch", fixed = TRUE)
  expect_no_match(as.character(node_ui(tree, first, list(list(node = first, answer = "x")))), "bayes_mode_switch", fixed = TRUE)
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "known_ui(tree, state$history, if (isTRUE(state$skip_screening)) NULL else state$ctx, state$bayes_mode)", fixed = TRUE)
  expect_match(code, "bayes_mode = FALSE", fixed = TRUE)
  expect_match(code, "tags$script(HTML(bayes_mode_js))", fixed = TRUE)
})

test_that("with Bayes factors on, the list shows only the designs with a Bayes factor version", {
  all <- as.character(known_ui(tree))
  on <- as.character(known_ui(tree, bayes_on = TRUE))
  shown <- function(html) unique(regmatches(html, gregexpr('data-ep="E[0-9]+"', html))[[1]])
  ids <- sub('data-ep="(E[0-9]+)"', "\\1", shown(on))
  expect_setequal(ids, intersect(names(tree$endpoints), names(tree$bayes_designs)))
  expect_gt(length(shown(all)), length(ids))
  expect_match(on, sprintf("Showing the %d of %d analyses with a Bayes factor version", length(ids), length(tree$endpoints)), fixed = TRUE)
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
  expect_match(version$default_source, "analyse with Bayes factors", fixed = TRUE)
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
