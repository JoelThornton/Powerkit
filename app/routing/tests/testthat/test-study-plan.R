# The study plan any card can join (R/study-plan.R): the plan lists each
# analysis, names the largest sample size counted in people, says that
# joint power isn't calculated, and saves through the engine.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
write_plan <- engine_function("write_study_plan", file.path(repo_dir, "engine"))
read_plan <- engine_function("read_study_plan", file.path(repo_dir, "engine"))
skip_without_engine_plan <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

fake_entry <- function(label, n, comparable = TRUE, headline = paste("You need", n)) {
  list(endpoint = "E2", label = label, headline = headline, goal = "sample_size", n = n, comparable = comparable)
}

test_that("the plan names the largest sample size counted in people", {
  html <- as.character(study_plan_ui(list(fake_entry("A t-test", 128), fake_entry("A correlation", 194), fake_entry("A cluster trial", 900, comparable = FALSE))))
  expect_match(html, "<strong>N = 194</strong>, for A correlation", fixed = TRUE)
  expect_match(html, "counts groups, not people", fixed = TRUE)
  expect_match(html, "powerkit doesn't calculate it for these designs yet", fixed = TRUE)
  expect_match(html, "Add another analysis", fixed = TRUE)
  expect_match(html, "Save study plan", fixed = TRUE)
})

test_that("one analysis has no joint-power note, and an empty plan says how to add one", {
  one <- as.character(study_plan_ui(list(fake_entry("A t-test", 128))))
  expect_no_match(one, "powerkit doesn't calculate it", fixed = TRUE)
  empty <- as.character(study_plan_ui(list()))
  expect_match(empty, "Your plan is empty", fixed = TRUE)
  expect_no_match(empty, "download_study_plan", fixed = TRUE)
})

test_that("the bar under a result adds the analysis once and links to the plan", {
  expect_match(as.character(study_plan_bar_ui(list(), FALSE)), "Add this to my study plan", fixed = TRUE)
  added <- as.character(study_plan_bar_ui(list(fake_entry("A t-test", 128)), TRUE))
  expect_match(added, "Added to your study plan.", fixed = TRUE)
  expect_match(added, "See your study plan (1 analysis)", fixed = TRUE)
  expect_no_match(added, "Add this to my study plan", fixed = TRUE)
})

test_that("results from two cards save as one plan file and open again", {
  skip_without_engine_plan()
  entry_for <- function(ep) {
    spec <- build_spec(forms, ep, form_fields(form_groups(forms, ep)), form_examples[[ep]])
    spec$goal <- list(type = "sample_size", power = 0.8)
    spec$options$seed <- 5L
    calc <- run_calculation(spec, run, seed = 5L)
    plan_entry(tree, ep, calc, list(app = "routing-prototype", endpoint = ep))
  }
  entries <- list(entry_for("E2"), entry_for("E3"))
  expect_true(all(vapply(entries, function(e) is.numeric(e$n), logical(1))))
  expect_match(entries[[1]]$headline, "participants", fixed = TRUE)
  path <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(path))
  write_plan(plan_analyses(entries), file = path)
  reopened <- lapply(read_plan(path)$analyses, function(p) plan_entry_from_project(tree, p))
  expect_identical(vapply(reopened, `[[`, "", "endpoint"), c("E2", "E3"))
  expect_identical(vapply(reopened, function(e) e$n, numeric(1)), vapply(entries, function(e) e$n, numeric(1)))
  expect_match(as.character(study_plan_ui(reopened)), "Sample size from the saved result", fixed = TRUE)
})

test_that("joint power is offered only for one randomised comparison on several outcomes", {
  t_entry <- function(d) c(fake_entry("A t-test", 266), list(spec = list(template = "independent_t", goal = list(type = "power", n = 266))))
  r_entry <- c(fake_entry("A correlation", 194), list(spec = list(template = "correlation")))
  expect_true(joint_power_offered(list(t_entry(), t_entry())))
  expect_false(joint_power_offered(list(t_entry())))
  expect_false(joint_power_offered(list(t_entry(), r_entry)))
  offered <- as.character(study_plan_ui(list(t_entry(), t_entry())))
  expect_match(offered, "Calculate joint power", fixed = TRUE)
  expect_no_match(offered, "doesn't calculate it for these designs yet", fixed = TRUE)
  expect_match(as.character(study_plan_ui(list(t_entry(), r_entry))), "doesn't calculate it for these designs yet", fixed = TRUE)
})

test_that("the joint power from the engine is stated with each outcome's power and its source", {
  skip_without_engine_plan()
  joint <- engine_function("joint_power", file.path(repo_dir, "engine"))
  spec_for <- function(d) {
    spec <- build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), form_examples[["E2"]])
    spec$population <- list(metric = "standardised", d = d)
    spec
  }
  entries <- list(list(label = "Recall", spec = spec_for(0.4), n = 266), list(label = "Mood", spec = spec_for(0.3), n = 200))
  expect_identical(plan_largest_n(entries), 266)
  calc <- joint(plan_specs(entries), rho = 0.3, n = plan_largest_n(entries))
  words <- joint_power_sentence(calc, entries)
  expect_match(words[["headline"]], "With N = 266 and outcomes correlated 0.3, the chance that every analysis is significant is", fixed = TRUE)
  expect_match(words[["detail"]], "for Recall;", fixed = TRUE)
  expect_match(words[["detail"]], "Calculated by PUMP", fixed = TRUE)
})

test_that("joint power for a multisite trial is offered and says how PUMP's power differs with few groups", {
  skip_without_engine_plan()
  joint <- engine_function("joint_power", file.path(repo_dir, "engine"))
  spec_for <- function(d) {
    values <- modifyList(form_examples[["E34"]], list(assignment = "multisite", icc_effect = "0.02", d = as.character(d)))
    build_spec(forms, "E34", form_fields(form_groups(forms, "E34")), values)
  }
  entries <- list(list(label = "Wellbeing", spec = spec_for(0.3), n = 400), list(label = "Attendance", spec = spec_for(0.25), n = 400))
  expect_identical(entries[[1]]$spec$template, "multisite")
  expect_true(joint_power_offered(entries))
  calc <- joint(plan_specs(entries), rho = 0.3, n = plan_largest_n(entries))
  expect_identical(calc$design, "d2.1_m2fr")
  words <- joint_power_sentence(calc, entries)
  expect_match(words[["detail"]], "with few groups each outcome's power here is a little below its card's", fixed = TRUE)
  expect_no_match(words[["detail"]], "Welch", fixed = TRUE)
})

test_that("the plan names each analysis in plain words, puts the largest N first, and each can be removed", {
  expect_identical(plan_label(tree, "E2"), tree$endpoints$E2$plain_name)
  expect_false(identical(plan_label(tree, "E2"), "E2"))
  html <- as.character(study_plan_ui(list(fake_entry("A t-test", 128), fake_entry("A correlation", 194))))
  expect_match(html, "result-hero plan-hero", fixed = TRUE)
  expect_match(html, "the largest of your 2 analyses", fixed = TRUE)
  expect_match(html, "Sets the sample size", fixed = TRUE)
  expect_match(html, "plan_remove&#39;, 2,", fixed = TRUE)
  expect_match(html, "Remove A correlation from the plan", fixed = TRUE)
  expect_match(as.character(study_plan_ui(list())), "Add this to my study plan", fixed = TRUE)
})

test_that("a precision result shows its sample size first and can join the plan", {
  skip_without_engine_plan()
  fields <- form_fields(form_groups(forms, "E46"))
  values <- modifyList(form_examples$E46, list(goal = "precision_n", width = "0.2", conf_level = "0.95",
    just_type = "smallest_effect_of_interest", just_source = "A survey of similar staff."))
  spec <- build_spec(forms, "E46", fields, values)
  spec$options$seed <- 5L
  calc <- run_calculation(spec, run, seed = 5L)
  expect_identical(calc$status, "ok")
  html <- as.character(result_panel_ui(tree, forms, "E46", fields, values, calc))
  expect_match(html, "result-sections", fixed = TRUE)
  expect_match(html, "result-figure-value", fixed = TRUE)
  expect_match(html, "Width no more than 0.2", fixed = TRUE)
  expect_match(html, "study_plan_bar", fixed = TRUE)
  # The write-up comes before the downloads, as on a power result.
  expect_lt(regexpr("writeup_short", html), regexpr("download_script", html))
  entry <- plan_entry(tree, "E46", calc, list(app = "routing-prototype", endpoint = "E46"))
  expect_equal(entry$n, calc$result$n_required$n)
  expect_match(entry$headline, "confidence interval", fixed = TRUE)
  expect_identical(entry$label, tree$endpoints$E46$plain_name)
})
