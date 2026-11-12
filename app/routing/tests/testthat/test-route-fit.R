# No route quietly drops what the user said (coverage audit, 12 November
# 2026; R/route-fit.R): the card it ends on can hold the answers, or says
# what it can't do and where to go instead.

ends_with_context <- function(tree, ctx, route = "choose") {
  out <- list()
  walk <- function(id, ctx, seen) {
    id <- resolve_target(tree, id, ctx, route)
    if (is.na(id) || id %in% seen) return(invisible())
    if (is_endpoint_id(id)) {
      out[[length(out) + 1]] <<- list(ep = id, ctx = ctx)
      return(invisible())
    }
    node <- tree$nodes[[id]]
    if (is.null(node)) return(invisible())
    for (o in visible_options(tree, node, ctx, safety = FALSE)) walk(o$`next`, apply_sets(ctx, o), c(seen, id))
  }
  walk(start_node(tree), ctx, character())
  out
}

test_that("every route with the equivalence aim ends on a card that can do it, or says it can't", {
  ends <- ends_with_context(tree, list(goal = "equivalence"))
  expect_gt(length(ends), 20)
  silent <- Filter(function(e) {
    ep <- tree$endpoints[[e$ep]]
    can <- identical(e$ep, "E36") && equivalence_covers(e$ctx)
    !can && !identical(ep$status, "not_in_powerkit") && !length(route_fit_messages(tree, e$ep, e$ctx))
  }, ends)
  expect_length(silent, 0)
  # E36 names the design it can't take.
  expect_match(route_fit_messages(tree, "E36", list(goal = "equivalence", outcome = "score", times = "many_conditions")),
    "three or more conditions", fixed = TRUE)
  expect_length(route_fit_messages(tree, "E36", list(goal = "equivalence", outcome = "score", times = "twice")), 0)
  expect_match(route_fit_messages(tree, "E43", list(goal = "equivalence")), "no equivalence version", fixed = TRUE)
  # Detecting an effect says nothing.
  expect_length(route_fit_messages(tree, "E43", list(goal = "detect")), 0)
})

test_that("a card built for a score names an outcome it can't take", {
  for (ep in c("E35", "E45", "E74")) {
    expect_match(route_fit_messages(tree, ep, list(outcome = "count")), "You said your outcome is a count", fixed = TRUE, label = ep)
    expect_length(route_fit_messages(tree, ep, list(outcome = "score")), 0)
  }
  expect_match(route_fit_messages(tree, "E34", list(outcome = "ordinal")), "ordered categories", fixed = TRUE)
  expect_length(route_fit_messages(tree, "E34", list(outcome = "yesno")), 0)
  expect_match(route_fit_messages(tree, "E26", list(outcome = "yesno", times = "many_conditions")), "compares two", fixed = TRUE)
  # The card's heading changes with it.
  expect_match(as.character(card_ui(tree, "E35", history = list(list(node = "s1", answer = "A count")), fits = FALSE)),
    "The closest analysis powerkit has", fixed = TRUE)
})

test_that("counts and ratings over many trials reach the repeated counts card, and E41 points to regression", {
  trials <- tree$nodes$s2_trials
  for (outcome in c("count", "ordinal")) {
    targets <- vapply(visible_options(tree, trials, list(outcome = outcome), safety = FALSE), `[[`, character(1), "next")
    expect_true("E75" %in% targets, label = outcome)
  }
  ui <- as.character(route_fit_ui(tree, "E41", list(outcome = "score", times = "twice")))
  expect_match(ui, "ep:E24", fixed = TRUE)
})

test_that("Plan my whole study says what it can't do: other aims, and Bayes factors", {
  note <- guided_single_note(tree, list(), list(aim = "estimate"))
  expect_match(note, "Estimate how big something is", fixed = TRUE)
  expect_no_match(note, "separate people", fixed = TRUE)
  expect_identical(guided_single_note(tree, list(grouping = "clusters"), list(aim = "predict")), tree$guided$single_analysis_note)
  expect_null(guided_single_note(tree, list(grouping = "independent"), list(aim = "predict")))
  expect_null(guided_single_note(tree, list(grouping = "independent"), list(aim = "replicate")))
  expect_null(whole_study_bayes_note(FALSE))
  expect_match(as.character(whole_study_bayes_note(TRUE)), "use p-values", fixed = TRUE)
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "whole_study_bayes_note(state$bayes_mode)", fixed = TRUE)
})

test_that("a fixed sample on a card without the smallest-effect goal says so, and E24's label stands alone", {
  goals <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, "E24")))[[1]]
  expect_false(any(grepl("^The same", unlist(goals$choices))))
  situation <- Filter(function(f) identical(f$id, "situation"), form_fields(form_groups(forms, "E27")))[[1]]
  expect_match(situation$choice_notes$fixed, "doesn't yet give the smallest effect", fixed = TRUE)
  with_goal <- Filter(function(f) identical(f$id, "situation"), form_fields(form_groups(forms, "E2")))[[1]]
  expect_null(with_goal$choice_notes)
})

test_that("the safety net offers search and the methods map", {
  ui <- as.character(card_ui(tree, tree$safety_net$endpoint, history = list(list(node = "s1", answer = tree$safety_net$label))))
  expect_match(ui, "route:known", fixed = TRUE)
  expect_match(ui, "safety_open_map", fixed = TRUE)
})
