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
  # The outcome starts unchosen, and all three outcomes are offered. (The
  # picture of power's alpha starts at .05, and the Bayesian planning tool's
  # hypothesis and threshold at their defaults.)
  checked <- regmatches(html, gregexpr("<input[^>]*checked=\"checked\"[^>]*>", html))[[1]]
  expect_true(all(grepl("name=\"(picture_alpha|bayes_alternative|bayes_threshold)\"", checked)))
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
  expect_length(labs_tools, 5)
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

test_that("the methods map is drawn from the design finder and reaches every analysis it can", {
  graph <- map_graph(tree)
  ids <- vapply(graph$nodes, `[[`, "", "id")
  kinds <- vapply(graph$nodes, `[[`, "", "kind")
  on_map <- ids[kinds == "endpoint"]
  # Every end point the design finder can reach from its questions is on
  # the map (the screening ends included), once each.
  reached <- setdiff(reachable(tree, start_node(tree))$endpoints, tree$safety_net$endpoint)
  expect_setequal(setdiff(reached, on_map), character())
  expect_false(any(duplicated(ids)))
  # Every edge joins two nodes on the map.
  ends <- unlist(lapply(graph$edges, function(e) c(e$source, e$target)))
  expect_true(all(ends %in% ids))
  # Each analysis carries a tag for every filter, from the filters' values.
  for (n in graph$nodes[kinds == "endpoint"]) {
    expect_true(length(n$rq) > 0, info = n$id)
    expect_true(all(unlist(n$outcome) %in% names(map_filters$outcome)), info = n$id)
    expect_true(all(unlist(n$times) %in% names(map_filters$times)), info = n$id)
    expect_true(n$status %in% names(map_filters$status), info = n$id)
  }
  # The tags follow the questions: comparing two separate groups on a score
  # is measured once, on a score.
  e2 <- graph$nodes[[which(ids == "E2")]]
  expect_true("once" %in% unlist(e2$times))
  # The plain list draws each question once; later visits point back to it.
  flat <- function(k) c(if (identical(k$kind, "question")) k$id, unlist(lapply(k$children, flat)))
  questions <- flat(map_tree(tree))
  expect_false(any(duplicated(questions[!questions %in% map_screening])))
  # Each analysis's status is shown in words, and opens its page.
  html <- as.character(map_ui(tree))
  expect_match(html, "Calculates in powerkit", fixed = TRUE)
  expect_match(html, "Not in powerkit yet", fixed = TRUE)
  expect_match(html, "vendor/cytoscape.min.js", fixed = TRUE)
  expect_true(grepl("pkMapOpen(&#39;E2&#39;)", html, fixed = TRUE) || grepl("pkMapOpen('E2')", html, fixed = TRUE))
  expect_match(html, "The map as a list", fixed = TRUE)
  expect_true(file.exists(file.path("..", "..", "www", "vendor", "cytoscape.min.js")) ||
    file.exists(file.path("www", "vendor", "cytoscape.min.js")))
  expect_match(as.character(map_page_ui(tree, "E2")), tree$endpoints$E2$plain_name, fixed = TRUE)
  expect_null(map_page_ui(tree, ""))
  # Labs lists it, and nothing on the map is calculated.
  expect_match(as.character(labs_ui(tree)), "Open Methods map", fixed = TRUE)
  expect_no_match(paste(deparse(map_ui), collapse = "\n"), "engine_function", fixed = TRUE)
})

test_that("plan from a published result: the engine converts and gives the safeguard value", {
  html <- as.character(labs_ui(tree))
  expect_match(html, "Open Effect size converter", fixed = TRUE)
  expect_match(html, "data-display-if=\"input.labs_tool == &#39;published&#39;\"|data-display-if=\"input.labs_tool == 'published'\"")
  # Each kind of study offers its own effect size and the forms its card converts.
  for (design in names(published_designs)) {
    expect_setequal(unlist(published_from_choices(design)), c("as_is", conversion_choices[[design]]))
  }
  convert <- engine_function("convert_effect")
  safeguard <- engine_function("safeguard_effect")
  out <- published_result(list(pub_design = "independent_t", pub_from = "t", pub_value = "2.5", pub_df = "58",
    pub_n1 = "30", pub_n2 = "30", pub_protection = "0.8"), convert, safeguard)
  expect_length(out$problems, 0)
  expect_match(out$lines[1], "Converted: Cohen's d = 0.645, with the psych package's t2d(), by the formula in Lakens (2013).", fixed = TRUE)
  lower <- safeguard(convert("t", 2.5, "independent_t", df_error = 58)$value, "independent_t", n1 = 30, n2 = 30, protection = 0.8)$lower
  expect_match(out$lines[2], sprintf("plan with Cohen's d = %s", format(round(lower, 3), nsmall = 2)), fixed = TRUE)
  expect_match(out$lines[2], "for an 80% chance", fixed = TRUE)
  expect_match(out$lines[3], "Published effects tend to be larger", fixed = TRUE)
  # Groups of different sizes enter the conversion: d = t sqrt(1/n1 + 1/n2).
  uneven <- published_result(list(pub_design = "independent_t", pub_from = "t", pub_value = "3", pub_df = "38",
    pub_n1 = "10", pub_n2 = "30", pub_protection = "0.8"), convert, safeguard)
  expect_match(uneven$lines[1], "Converted: Cohen's d = 1.095", fixed = TRUE)
  # An r is still converted by effectsize.
  from_r <- published_result(list(pub_design = "independent_t", pub_from = "r", pub_value = "0.3"), convert, safeguard)
  expect_match(from_r$lines[1], "with the effectsize package's r_to_d() (Ben-Shachar", fixed = TRUE)
  # An ANOVA's F, with both dfs; no safeguard there yet.
  anova <- published_result(list(pub_design = "oneway_between", pub_from = "F", pub_value = "4.2", pub_df1 = "2", pub_df = "57"), convert, safeguard)
  expect_match(anova$lines[1], "partial eta-squared = 0.128", fixed = TRUE)
  expect_match(anova$lines[2], "Safeguard power isn't available for partial eta-squared yet", fixed = TRUE)
  # Plain problems, no stack traces.
  expect_match(published_result(list(pub_design = "paired_t", pub_from = "t", pub_value = "2.5"), convert, safeguard)$problems,
    "Enter its error degrees of freedom", fixed = TRUE)
  expect_match(published_result(list(pub_value = "2.5"), convert, safeguard)$problems[1], "Choose the kind of study first.", fixed = TRUE)
  # A wide interval: no safeguard value, and the reason.
  wide <- published_result(list(pub_design = "correlation", pub_from = "as_is", pub_value = "0.1", pub_n = "20"), convert, safeguard)
  expect_match(wide$lines[1], "includes zero", fixed = TRUE)
})


test_that("the picture of power shows the engine's curves and numbers, and computes nothing itself", {
  html <- as.character(labs_ui(tree))
  expect_match(html, "Open Power visualiser", fixed = TRUE)
  expect_match(html, "data-display-if=\"input.labs_tool == &#39;picture&#39;\"|data-display-if=\"input.labs_tool == 'picture'\"")
  picture <- engine_function("power_picture")
  skip_if(is.null(picture), "powerkit's engine isn't available here")
  p64 <- picture(64, 0.5, alpha = 0.05)
  text <- as.character(picture_numbers(p64))
  expect_match(text, sprintf("%.1f%%", 100 * p64$power), fixed = TRUE)
  expect_match(text, sprintf("%.3f", p64$d_crit), fixed = TRUE)
  expect_match(text, "(Lakens, 2013)", fixed = TRUE)
  # The plot draws without error.
  file <- tempfile(fileext = ".png")
  grDevices::png(file)
  on.exit(unlink(file))
  expect_no_error(picture_plot(p64))
  grDevices::dev.off()
  # Lakens (2013) is in refs.bib.
  bib <- paste(readLines(file.path(repo_dir, "engine", "inst", "citations", "refs.bib"), encoding = "UTF-8"), collapse = "\n")
  expect_match(bib, "@Article{Lakens2013_effectsizes", fixed = TRUE)
})

test_that("the picture of power also shows a correlation, from the engine's power_picture_r()", {
  html <- as.character(labs_ui(tree))
  expect_match(html, "A correlation (Pearson&#39;s r)|A correlation \\(Pearson's r\\)")
  picture <- engine_function("power_picture_r")
  skip_if(is.null(picture), "powerkit's engine isn't available here")
  p84 <- picture(84, 0.3, alpha = 0.05)
  text <- as.character(picture_numbers(p84))
  expect_match(text, sprintf("%.1f%%", 100 * p84$power), fixed = TRUE)
  expect_match(text, sprintf("%.3f", p84$r_crit), fixed = TRUE)
  expect_match(text, "Smallest significant r", fixed = TRUE)
  file <- tempfile(fileext = ".png")
  grDevices::png(file)
  on.exit(unlink(file))
  expect_no_error(picture_plot(p84))
  grDevices::dev.off()
})

test_that("Bayesian planning shows the engine's outcomes under the belief and with no effect, and no single power figure", {
  html <- as.character(labs_ui(tree))
  expect_match(html, "Bayesian planning", fixed = TRUE)
  expect_match(html, "data-display-if=\"input.labs_tool == &#39;bayes&#39;\"|data-display-if=\"input.labs_tool == 'bayes'\"")
  for (id in c("bayes_type", "bayes_n", "bayes_scale", "bayes_effect", "bayes_effect_sd", "bayes_threshold", "bayes_target", "bayes_run")) {
    expect_match(html, sprintf("id=\"%s\"", id), fixed = TRUE)
  }
  # The analysis prior and the design prior are asked for apart.
  expect_match(html, "The analysis prior", fixed = TRUE)
  expect_match(html, "The design prior", fixed = TRUE)
  plan_of <- engine_function("bayes_planning")
  skip_if(is.null(plan_of), "powerkit's engine isn't available here")
  plan <- plan_of(120, effect = 0.5, effect_sd = 0.15)
  text <- as.character(bayes_numbers(plan))
  pct <- function(x) sprintf("%.1f%%", 100 * x)
  for (x in unlist(plan$outcomes[c("for_effect", "for_null", "neither")])) expect_match(text, pct(x), fixed = TRUE)
  expect_match(text, "If the effect is about 0.5 (give or take 0.15)", fixed = TRUE)
  expect_match(text, "If there is no effect", fixed = TRUE)
  expect_match(text, "misleading", fixed = TRUE)
  expect_match(text, sprintf("under your belief: %s in each group", plan$n_needed), fixed = TRUE)
  expect_match(text, "can never reach 10 in favour of no effect", fixed = TRUE)
  expect_match(text, "Pawel", fixed = TRUE)
  expect_no_match(text, "\\bpower(ed)? (is|of)\\b|justified|adequate|sufficient power|well-powered", perl = TRUE)
  expect_no_match(text, "few points lower", fixed = TRUE)
  expect_match(as.character(bayes_numbers(plan_of(20, effect = 0.5))), "few points lower", fixed = TRUE)
  expect_no_error(bayes_priors_plot(plan))
  expect_no_error(bayes_curves_plot(plan))
  expect_no_error(bayes_priors_plot(plan_of(40, effect = 0.3, alternative = "greater")))
  # The engine's refusals come back in the form's words, never R's.
  refusal <- tryCatch(plan_of(2), error = bayes_problem)
  expect_match(refusal, "^The sample size should be")
  expect_match(bayes_problem(simpleError("subscript out of bounds")), "something went wrong", fixed = TRUE)
})
