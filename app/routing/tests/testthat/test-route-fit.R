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
    "The closest analysis Powerkit has", fixed = TRUE)
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

test_that("a fixed sample on a card without the smallest-effect goal says so, and the range follows the goal it repeats", {
  # E24 has both goals since 16 November 2026, so the range says "The same".
  goals <- Filter(function(f) identical(f$id, "goal"), form_fields(form_groups(forms, "E24")))[[1]]
  expect_true("sensitivity" %in% names(goals$choices))
  expect_match(goals$choices$sensitivity_curve, "^The same")
  # The cross-lagged panel model (E74) has no smallest-effect goal yet.
  situation <- Filter(function(f) identical(f$id, "situation"), form_fields(form_groups(forms, "E74")))[[1]]
  expect_match(situation$choice_notes$fixed, "doesn't yet give the smallest effect", fixed = TRUE)
  with_goal <- Filter(function(f) identical(f$id, "situation"), form_fields(form_groups(forms, "E2")))[[1]]
  expect_null(with_goal$choice_notes)
})

test_that("the safety net offers search and the methods map", {
  ui <- as.character(card_ui(tree, tree$safety_net$endpoint, history = list(list(node = "s1", answer = tree$safety_net$label))))
  expect_match(ui, "route:known", fixed = TRUE)
  expect_match(ui, "safety_open_map", fixed = TRUE)
})

# The finder keeps what the researcher told it (finder audit, 21 November
# 2026): the answers set the input screen, a fact a card can't take is
# asked before a card is called a fit, and a part of the study no card
# plans is named.

test_that("the finder's outcome and assignment answers set the input screen", {
  expect_identical(finder_form_values(forms, "E33", list(outcome = "yesno", assignment = "between")),
    list(outcome_type = "binary", crossed_participants = "between_factor"))
  expect_identical(finder_form_values(forms, "E33", list(outcome = "score", assignment = "within")),
    list(outcome_type = "continuous", crossed_participants = "within_factor"))
  expect_identical(finder_form_values(forms, "E63", list(outcome = "yesno", assignment = "between"))$crossed_participants, "between_factor")
  expect_identical(finder_form_values(forms, "E75", list(outcome = "ordinal", times = "twice")), list(glmm_outcome = "categorical"))
  expect_identical(finder_form_values(forms, "E75", list(outcome = "count", assignment = "between")),
    list(glmm_outcome = "count", glmm_people = "between_factor"))
  expect_identical(finder_form_values(forms, "E34", list(outcome = "yesno")), list(outcome_type = "proportion"))
  expect_identical(finder_form_values(forms, "E62", list(outcome = "yesno"))$two_outcome, "binary")
  # An answer a card has no choice for sets nothing.
  expect_identical(finder_form_values(forms, "E34", list(outcome = "count")), list())
  expect_identical(finder_form_values(forms, "E2", list(outcome = "score")), list())
  # Every fill names a field the card has and a value among its choices.
  for (key in names(finder_form_fills)) for (ep in names(finder_form_fills[[key]])) {
    fill <- finder_form_fills[[key]][[ep]]
    field <- Filter(function(f) identical(f$id, fill$field), form_fields(form_groups(forms, ep)))
    expect_length(field, 1)
    expect_true(all(fill$values %in% names(field[[1]]$choices)), label = paste(key, ep))
  }
})

test_that("the input screen opened from the finder says which answers it set", {
  note <- as.character(finder_filled_note_ui(forms, "E33", list(outcome_type = "binary", crossed_participants = "between_factor")))
  expect_match(note, "Set from your answers", fixed = TRUE)
  expect_match(note, "On each trial, the outcome is", fixed = TRUE)
  # A value changed since (a test version, say) isn't claimed.
  note <- as.character(finder_filled_note_ui(forms, "E33", list(outcome_type = "binary"), list(outcome_type = "continuous")))
  expect_identical(note, character(0))
})

test_that("a yes/no outcome on trials, in groups or answered twice is asked how many categories", {
  yn <- "Yes/no, or one of several categories"
  expect_identical(follow_answers(tree, c(yn, "Many trials or stimuli per person")), "s2_trials_cat")
  expect_identical(follow_answers(tree, c(yn, "Independent people", "Twice", "A difference between groups or conditions")), "q3_cat_twice")
  expect_identical(follow_answers(tree, c(yn, "People within groups")), "c_cat")
  for (path in list(c(yn, "Many trials or stimuli per person", "One of three or more categories"),
                    c(yn, "Independent people", "Twice", "A difference between groups or conditions", "Three or more"),
                    c(yn, "People within groups", "One of three or more categories"))) {
    f <- follow_with_context(tree, path)
    expect_identical(f$id, "E-unsure", label = paste(path, collapse = " > "))
    msg <- route_fit_messages(tree, f$id, f$ctx)
    expect_length(msg, 1)
    expect_identical(msg, tree$finder_gaps[[f$ctx$gap]])
  }
  expect_match(tree$finder_gaps$paired_categories, "Stuart-Maxwell", fixed = TRUE)
  expect_match(tree$finder_gaps$paired_categories, "Bowker", fixed = TRUE)
  # A count in groups is asked what the hypothesis involves, and the card
  # says it takes a score or yes/no.
  f <- follow_with_context(tree, c("A count", "People within groups", "A condition or treatment given to groups, or within groups",
    "No: one level of groups (for example, classes, or clinics)"))
  expect_identical(f$id, "E34")
  expect_match(route_fit_messages(tree, "E34", f$ctx), "You said your outcome is a count", fixed = TRUE)
  expect_match(route_fit_messages(tree, "E62", list(outcome = "count")), "You said your outcome is a count", fixed = TRUE)
})

test_that("the app opens the input screen set to the finder's answers", {
  shiny::testServer(routing_dir, {
    session$setInputs(pick = "route:choose")
    session$setInputs(pick = "aim:predict")
    for (label in c("Yes/no, or one of several categories", "Many trials or stimuli per person", "Yes or no (two categories)",
                    "Two conditions, and each person is in one of them")) {
      opts <- visible_options(tree, tree$nodes[[state$node]], state$ctx)
      session$setInputs(pick = paste0("opt:", which(vapply(opts, function(o) identical(o$label, label), logical(1)))))
    }
    expect_identical(state$endpoint, "E33")
    session$setInputs(pick = "form")
    expect_identical(state$form_values$outcome_type, "binary")
    expect_identical(state$form_values$crossed_participants, "between_factor")
  })
})

test_that("one group's change, and mediation over time, say what the within-person card plans", {
  base <- c("A score or scale", "Independent people", "Many times", "Measurements over time, to see how people change")
  expect_identical(follow_answers(tree, base), "t2")
  f <- follow_with_context(tree, c(base, "One group's scores change over time"))
  expect_identical(f$id, "E41")
  msg <- route_fit_messages(tree, "E41", f$ctx)
  expect_length(msg, 1)
  expect_match(msg, "per SD of X", fixed = TRUE)
  expect_match(msg, "average change", fixed = TRUE)
  expect_identical(finder_form_values(forms, "E41", f$ctx), list(two_outcome = "continuous", two_level_effect = "within_effect"))
  # Two groups' slopes: E35, with no note.
  f <- follow_with_context(tree, c(base, "Two groups change at different rates"))
  expect_identical(f$id, "E35")
  expect_length(route_fit_messages(tree, "E35", f$ctx), 0)
  # Mediation measured twice: the indirect effect isn't on E41, and the
  # baseline-regression note (about prediction, not mediation) is not shown.
  for (times in list("Twice", c("Many times", "The same people in three or more conditions"))) {
    f <- follow_with_context(tree, c("A score or scale", "Independent people", times, "That an effect works through something else (mediation)"))
    expect_identical(f$id, "E41")
    msg <- route_fit_messages(tree, "E41", f$ctx)
    expect_length(msg, 1)
    expect_match(msg, "doesn't calculate an indirect effect", fixed = TRUE)
    expect_null(finder_form_values(forms, "E41", f$ctx)$two_level_effect)
    expect_no_match(as.character(route_fit_ui(tree, "E41", f$ctx)), "ep:E24", fixed = TRUE)
  }
  f <- follow_with_context(tree, c("A score or scale", "Independent people", "Twice", "Both: it works through something that depends on something else"))
  expect_match(route_fit_messages(tree, f$id, f$ctx), "indirect effect", fixed = TRUE)
})
