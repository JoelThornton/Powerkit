# Labs (experimental): pre-replication notes (R/labs.R).

test_that("the three questions appear word for word from Karhulahti et al. (2025)", {
  html <- as.character(labs_ui(tree))
  for (q in labs_questions) expect_match(html, q, fixed = TRUE)
  expect_equal(labs_questions$goals, "What are the epistemic goals in replication and how is the original study related to them?")
  expect_equal(labs_questions$quality, "Is the chosen finding or study sufficiently high in methodological quality for replication?")
  expect_equal(labs_questions$value, "Why has replication been chosen to reach the desired epistemic goals?")
})

test_that("nothing is required, scored or marked complete", {
  html <- as.character(labs_ui(tree))
  expect_no_match(html, "aria-required|required=|\\(required\\)", perl = TRUE)
  expect_no_match(html, "score[ds]? (out of|of )|complete[d]?\\b|incomplete|badge", ignore.case = TRUE, perl = TRUE)
  # The outcome starts unchosen, and all three outcomes are offered.
  expect_no_match(html, "checked=\"checked\"", fixed = TRUE)
  for (o in labs_outcomes) expect_match(html, o, fixed = TRUE)
})

test_that("the citation comes from refs.bib", {
  bib <- readLines(file.path(repo_dir, "engine", "inst", "citations", "refs.bib"), encoding = "UTF-8")
  expect_true(any(grepl(paste0("@Article{", labs_ref_key, ","), bib, fixed = TRUE)))
  citation <- labs_citation(file.path(repo_dir, "engine", "inst", "citations", "refs.bib"))
  expect_match(citation, "Pre-replication: Anything Goes, Once", fixed = TRUE)
  expect_match(citation, "10.15626/MP.2024.4155", fixed = TRUE)
})

test_that("the smallest detectable effect matches the engine's own sensitivity", {
  skip_if(is.null(engine_function("run_spec")), "needs powerkit's engine")
  run <- engine_function("run_spec")
  # Two groups, 40 analysed in total: the same as the input screen's
  # smallest-effect goal for that design.
  calc <- labs_sde(forms, "E2", "40", "0.8", "0.05")
  expect_equal(calc$status, "ok")
  fields <- unlist(lapply(form_groups(forms, "E2", 2L, list()), `[[`, "fields"), recursive = FALSE)
  values <- utils::modifyList(form_examples$E2, list(goal = "sensitivity", n = "40", power = "0.8", d = "", method = "student_t"))
  direct <- run_calculation(build_spec(forms, "E2", fields, values), run = run, seed = forms$default_seed)
  expect_equal(abs(calc$result$sensitivity$effect), abs(direct$result$sensitivity$effect), tolerance = 1e-8)
  expect_match(labs_sde_sentence(tree, calc, "0.8"), "With 40 analysed", fixed = TRUE)
  expect_match(labs_provenance(calc), "seed", fixed = TRUE)
  # Every offered test runs; chi-square and two proportions take their extra entries.
  for (ep in setdiff(labs_tests, c("E5", "E6"))) expect_equal(labs_sde(forms, ep, "60")$status, "ok", info = ep)
  expect_equal(labs_sde(forms, "E5", "60", p1 = "0.3")$status, "ok")
  expect_equal(labs_sde(forms, "E6", "60", rows = "2", cols = "3")$status, "ok")
  # A missing sample size is a plain-words problem, not an error.
  expect_equal(labs_sde(forms, "E1", "")$status, "problems")
})

test_that("the notes follow where the user landed", {
  answers <- list(labs_finding = "Priming changes walking speed", labs_goals = "Theory test")
  go <- labs_markdown(answers, "go", citation = "CITATION", date = as.Date("2026-10-20"))
  expect_match(go, "preregistration or introduction", fixed = TRUE)
  expect_match(go, "Priming changes walking speed", fixed = TRUE)
  expect_match(go, "_(left blank)_", fixed = TRUE)
  expect_match(go, "The questions are from: CITATION", fixed = TRUE)
  not_worth <- labs_markdown(answers, "not_worth", citation = "CITATION")
  expect_match(not_worth, "negative pre-replication report", fixed = TRUE)
  expect_match(not_worth, labs_outcomes[["not_worth"]], fixed = TRUE)
  # Only "go ahead" and "change the plan" offer the sample-size button.
  expect_match(as.character(labs_next_ui("go", TRUE)), "labs_plan", fixed = TRUE)
  expect_match(as.character(labs_next_ui("change", FALSE)), "labs_plan", fixed = TRUE)
  expect_no_match(as.character(labs_next_ui("not_worth", TRUE)), "labs_plan", fixed = TRUE)
  expect_no_match(as.character(labs_next_ui(NULL, TRUE)), "labs_plan", fixed = TRUE)
  # The panel's number goes into the notes when it was calculated.
  with_sde <- labs_markdown(answers, "go", sde = list(sentence = "SDE LINE.", provenance = "PROV."), citation = "C")
  expect_match(with_sde, "SDE LINE. PROV.", fixed = TRUE)
})

test_that("the main route's only link into Labs is shown for a previous study", {
  fields <- unlist(lapply(form_groups(forms, "E2", 2L, list()), `[[`, "fields"), recursive = FALSE)
  just_type <- Filter(function(f) identical(f$id, "just_type"), fields)[[1]]
  html <- as.character(field_ui(just_type, ""))
  expect_match(html, "input.f_just_type == &#39;prior_study&#39;|input.f_just_type == 'prior_study'", perl = TRUE)
  expect_match(html, "go_labs", fixed = TRUE)
  expect_match(html, "Hide this", fixed = TRUE)
})

test_that("the Labs citation falls back, never errors, when the engine is only partly loaded", {
  fake <- new.env()
  local_mocked_bindings(asNamespace = function(...) fake, .package = "base")
  expect_match(labs_citation(labs_refs_path()), "doi.org/10.15626/MP.2024.4155", fixed = TRUE)
})

test_that("the tabs that are the same for everyone are built once, not per visitor", {
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  ui_body <- sub("(?s).*ui <- function\\(req\\) fluidPage\\((.*?)\nserver <- function.*", "\\1", code, perl = TRUE)
  for (call in c("about_ui(", "labs_ui(", "whats_new_ui(", "feedback_tab_ui(", "settings_table_ui(")) {
    expect_false(grepl(call, ui_body, fixed = TRUE), label = call)
  }
})


# A Labs menu, and planning from the notes without losing work (22 October 2026)

test_that("Labs opens on a list of tools; the notes appear once their tool is chosen", {
  html <- as.character(labs_ui(tree))
  menu_at <- regexpr("labs-menu", html); tool_at <- regexpr("labs_finding", html)
  expect_gt(menu_at, 0); expect_gt(tool_at, menu_at)
  expect_match(html, 'data-display-if="!input.labs_tool"', fixed = TRUE)
  expect_match(html, "data-display-if=\"input.labs_tool == &#39;prereplication&#39;\"|data-display-if=\"input.labs_tool == 'prereplication'\"")
  expect_match(html, "Open Pre-replication notes", fixed = TRUE)
  expect_match(html, "All Labs tools", fixed = TRUE)
  expect_length(labs_tools, 1)
  expect_match(labs_js, "powerkit-labs-tool", fixed = TRUE)
})

test_that("planning from the notes carries the user's own words, never a number into a box", {
  answers <- list(labs_study = "Smith (2020)", labs_finding = "Training raises recall.", labs_smallest = "d = 0.2, a third of a grade")
  seed <- labs_seed_reasoning(answers)
  expect_identical(seed, "Replicating: Training raises recall (original study: Smith (2020)). The smallest effect that would matter, from my pre-replication notes: d = 0.2, a third of a grade")
  expect_null(labs_seed_reasoning(list()))
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  # Only the reasoning box is filled.
  expect_match(code, "list(just_source = state$labs_seed)", fixed = TRUE)
  # A plan in progress is replaced only after asking.
  expect_match(code, "if (plan_in_progress()) showModal(labs_replace_modal()) else labs_start_plan()", fixed = TRUE)
  expect_match(as.character(labs_replace_modal()), "Your pre-replication notes are kept either way.", fixed = TRUE)
  expect_match(as.character(labs_return_ui(TRUE, TRUE)), "Back to the notes", fixed = TRUE)
})
