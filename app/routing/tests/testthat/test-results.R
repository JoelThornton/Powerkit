# The result screen for the end points that calculate (forms.yaml,
# `calculates`): the app's result equals the engine called directly with the
# same spec and seed, and the downloaded R script reproduces it.
#
# Kept light: few replications (the numbers aren't checked for accuracy
# here; the engine's validation tests do that). Skipped where the engine
# isn't available, except on GitHub's app-tests job, where it must be.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
script <- engine_function("export_script", file.path(repo_dir, "engine"))
citations <- engine_function("export_citations", file.path(repo_dir, "engine"))
skip_without_run <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

# The example spec for an end point, with few replications and a goal.
light_spec <- function(ep, goal = list(type = "power", n = 48L)) {
  v <- form_examples[[ep]]
  fields <- form_fields(form_groups(forms, ep))
  spec <- build_spec(forms, ep, fields, v)
  spec$goal <- goal
  if (!ep %in% c("E7", "E8")) spec$options$nrep <- 100L
  spec
}

quiet_run <- function(spec) withCallingHandlers(run(spec), warning = function(w) invokeRestart("muffleWarning"))

# Run an exported script in a fresh R session; TRUE if it reports that it
# reproduced powerkit's result.
script_reproduces <- function(text) {
  file <- tempfile(fileext = ".R")
  writeLines(text, file)
  out <- withr::with_envvar(
    c(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), RENV_CONFIG_AUTOLOADER_ENABLED = "false"),
    system2(file.path(R.home("bin"), "Rscript"), c("--vanilla", shQuote(file)), stdout = TRUE, stderr = TRUE)
  )
  any(grepl("Reproduced powerkit's result.", out, fixed = TRUE))
}

wired <- unlist(forms$calculates)

test_that("E1-E9, E18, E23-E26, E48 and E49 calculate; E10-E14 preview first, then a full run or an R script", {
  expect_setequal(wired, c(paste0("E", 1:9), "E18", "E23", "E24", "E25", "E26", "E48", "E49"))
  for (ep in paste0("E", 10:14)) {
    expect_false(form_calculates(forms, ep), label = ep)
    expect_true(runs_long(forms, ep), label = ep)
  }
  # Only E9 runs in the background with no preview, with its usual run times.
  expect_identical(names(forms$background), "E9")
  for (ep in paste0("E", 1:8)) expect_false(runs_in_background(forms, ep), label = ep)
  expect_equal(usual_seconds(forms, "E9", "power"), 5)
  expect_equal(usual_seconds(forms, "E9", "sample_size"), 80)
  expect_true(is.na(usual_seconds(forms, "E9", "sensitivity")))
  # The maintainer's choices (17 October 2026): a preview of about 100
  # replications; the full run in the app for mediation power at a fixed N
  # only; the R script for everything else.
  expect_identical(preview_nrep(forms), 100L)
  for (ep in paste0("E", 10:12)) {
    expect_true(full_run_in_app(forms, ep, "power"), label = ep)
    expect_false(full_run_in_app(forms, ep, "sample_size"), label = ep)
    expect_true(full_seconds(forms, ep, "power") > 0, label = ep)
  }
  # A preview for power only: a required N goes straight to the R script.
  for (ep in paste0("E", 10:14)) {
    expect_true(has_preview(forms, ep, "power"), label = ep)
    expect_true(preview_seconds(forms, ep, "power") > 0, label = ep)
    expect_false(has_preview(forms, ep, "sample_size"), label = ep)
    for (goal in c("power", "sample_size")) {
      if (!full_run_in_app(forms, ep, goal)) expect_match(script_run_time(forms, ep, goal), "one core", label = paste(ep, goal))
    }
  }
  for (ep in c("E13", "E14")) expect_false(full_run_in_app(forms, ep, "power"), label = ep)
})

test_that("E9 in the background: the app's result equals the engine's, and the script reproduces it", {
  skip_without_run()
  skip_on_cran()
  spec <- light_spec("E9")
  spec$options$seed <- 1L
  job <- start_background_calculation(spec, seed = 1L, engine_dir = file.path(repo_dir, "engine"))
  job$wait(120000)
  calc <- collect_background_calculation(job)
  expect_identical(calc$status, "ok")
  expect_identical(calc$result$provenance$backend, "InteractionPoweR")
  expect_identical(calc$spec$options$seed, 1L)
  direct <- quiet_run(spec)
  expect_equal(calc$result$curve, direct$curve)
  expect_identical(calc$result$provenance$spec_hash, direct$provenance$spec_hash)
  expect_true(script_reproduces(script(calc$spec, calc$result)))
})

test_that("a background run can be cancelled, and a failed process gives a plain-English message", {
  skip_on_cran()
  job <- callr::r_bg(function() Sys.sleep(60))
  expect_true(job$is_alive())
  job$kill()
  expect_false(job$is_alive())
  calc <- collect_background_calculation(job)
  expect_identical(calc$status, "error")
  expect_match(calc$message, "stopped unexpectedly", fixed = TRUE)
  expect_false(grepl("Error in|Traceback", calc$message))
})

test_that("the progress bar is an estimate from the usual run time, and says so", {
  expect_equal(progress_estimate(40, 80), 0.5)
  expect_equal(progress_estimate(200, 80), 0.95)   # never shows done before it is
  expect_true(is.na(progress_estimate(10, NA_real_)))
  expect_identical(progress_text(12.4, 80), "Running for 12 seconds. This usually takes about 80 seconds.")
  expect_match(progress_text(90, 80), "taking longer than the usual 80 seconds", fixed = TRUE)
  html <- as.character(calculating_background_ui(80))
  expect_match(html, "Estimated progress", fixed = TRUE)
  expect_match(html, "<progress", fixed = TRUE)
  expect_match(html, "calc_cancel", fixed = TRUE)
  expect_match(as.character(cancelled_ui()), "Calculation cancelled", fixed = TRUE)
})

test_that("each wired end point: the app's result equals the engine's, and the script reproduces it", {
  skip_without_run()
  skip_on_cran()
  for (ep in wired) {
    spec <- light_spec(ep)
    calc <- run_calculation(spec, run, seed = 11L)
    expect_identical(calc$status, "ok", label = ep)
    # The app drew no seed of its own here: it used the one given, and
    # recorded it in the spec it ran.
    expect_identical(calc$spec$options$seed, 11L, label = ep)
    direct <- quiet_run(calc$spec)
    expect_equal(calc$result$curve, direct$curve, label = ep)
    expect_identical(calc$result$provenance$spec_hash, direct$provenance$spec_hash, label = ep)
    expect_true(script_reproduces(script(calc$spec, calc$result)), label = paste(ep, "script"))
  }
})

test_that("a sample-size result and a sensitivity result are worded from the engine's numbers", {
  skip_without_run()
  spec <- light_spec("E2", goal = list(type = "sample_size", power = 0.8))
  calc <- run_calculation(spec, run, seed = 3L)
  words <- result_sentences(calc$spec, calc$result)
  n <- calc$result$n_required$n
  expect_match(words[["headline"]], sprintf("You need %s participants in total (%s per group) for 80%% power", n, n / 2), fixed = TRUE)
  expect_match(words[["detail"]], sprintf("95%% interval for the required N is %s to %s", calc$result$n_required$lower, calc$result$n_required$upper), fixed = TRUE)
  direct <- quiet_run(calc$spec)
  expect_identical(calc$result$n_required, direct$n_required)

  spec <- light_spec("E7", goal = list(type = "sensitivity", n = 200L, power = 0.8))
  calc <- run_calculation(spec, run, seed = 3L)
  words <- result_sentences(calc$spec, calc$result)
  expect_match(words[["headline"]], "With 200 participants in total (50 per cell), the smallest effect you could detect with 80% power, with a two-sided test at alpha = .05, is", fixed = TRUE)
  expect_match(words[["headline"]], sprintf("Cohen's f = %.3f", calc$result$sensitivity$cohen_f), fixed = TRUE)
})

test_that("an exact required N shows the power it actually gives (G5); a simulated one doesn't", {
  skip_without_run()
  spec <- light_spec("E4", goal = list(type = "sample_size", power = 0.8))
  spec$options$nrep <- NULL
  calc <- run_calculation(spec, run, seed = 3L)
  n <- calc$result$n_required$n
  at_n <- calc$result$curve$power[calc$result$curve$n == n]
  expect_gte(at_n, 0.8)
  expect_identical(actual_power_sentence(calc$spec, calc$result), sprintf("With %s participants, power is %.1f%%.", n, 100 * at_n))

  spec <- light_spec("E7", goal = list(type = "sample_size", power = 0.8))
  calc <- run_calculation(spec, run, seed = 3L)
  n <- calc$result$n_required$n
  at_n <- calc$result$curve$power[calc$result$curve$n == n]
  sentence <- actual_power_sentence(calc$spec, calc$result)
  expect_identical(sentence, sprintf("With %s per cell, power is %.1f%%.", n / 4, 100 * at_n))
  html <- as.character(result_panel_ui(tree, forms, "E7", form_fields(form_groups(forms, "E7")), form_examples[["E7"]], calc))
  expect_match(html, sentence, fixed = TRUE)

  spec <- light_spec("E2", goal = list(type = "sample_size", power = 0.8))
  spec$options$method <- "simulation"
  calc <- run_calculation(spec, run, seed = 3L)
  expect_null(actual_power_sentence(calc$spec, calc$result))
})

test_that("the result screen shows the number, inputs, backend, validation status, departures and exports", {
  skip_without_run()
  spec <- light_spec("E5")
  fields <- form_fields(form_groups(forms, "E5"))
  calc <- run_calculation(spec, run, seed = 5L)
  html <- as.character(result_panel_ui(tree, forms, "E5", fields, form_examples$E5, calc))
  expect_match(html, "the study has", fixed = TRUE)
  expect_match(html, "not \"observed power\"|not &quot;observed power&quot;")
  expect_match(html, "Calculated by the R package\\s*<strong>stats</strong>")
  expect_match(html, "base R's formula, stats::power.prop.test(), no simulation", fixed = TRUE)
  expect_match(html, "Seed: 5.", fixed = TRUE)
  expect_no_match(html, "Calculated by simulation with", fixed = TRUE)
  expect_match(html, "Calculated with a formula", fixed = TRUE)          # Departure 9
  expect_match(html, "the z test as G*Power runs it", fixed = TRUE)      # Departure 11
  expect_match(html, "Validated. ", fixed = TRUE)                       # basic chunk rerun after #42
  expect_match(html, "No continuity correction", fixed = TRUE)            # Departure 5
  expect_match(html, "in group 1 (0 to 1): 0.6", fixed = TRUE)            # an input it used
  expect_match(html, "download_script", fixed = TRUE)
  expect_match(html, "download_citations", fixed = TRUE)
  expect_match(html, "Short version (for the paper)", fixed = TRUE)
  expect_match(html, "Departures from the established tools&#39; defaults:|Departures from the established tools' defaults:")
  expect_match(html, calc$result$provenance$spec_hash, fixed = TRUE)
  for (key in c("result_wording", "n_rounding", "power_curve")) expect_match(html, setting_by_key(tree, key)$question |> htmltools::htmlEscape(), fixed = TRUE, label = key)
  # Citations come from the engine's export.
  expect_match(citations(calc$result, format = "text"), "citation(\"stats\")", fixed = TRUE)
})

test_that("E5 can use Cohen's h instead of the z test; unequal groups use pwrss (Departure 11)", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E5"))
  choice <- Filter(function(f) identical(f$id, "proportions_formula"), fields)[[1]]
  exact <- modifyList(form_examples$E5, list(calc_method = "exact"))
  expect_true(field_applies(choice, exact))
  expect_false(field_applies(choice, modifyList(exact, list(calc_method = "simulation"))))
  values <- modifyList(exact, list(proportions_formula = "arcsine"))
  spec <- build_spec(forms, "E5", fields, values)
  spec$goal <- list(type = "power", n = 48L)
  calc <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(calc$result$provenance$backend_function, "pwr::pwr.2p2n.test")
  html <- as.character(result_panel_ui(tree, forms, "E5", fields, values, calc))
  expect_match(html, "pwr's formula, pwr::pwr.2p2n.test(), no simulation", fixed = TRUE)
  unequal <- modifyList(exact, list(allocation_ratio = 2))
  spec <- build_spec(forms, "E5", fields, unequal)
  spec$goal <- list(type = "power", n = 48L)
  expect_identical(run_calculation(spec, run, seed = forms$default_seed)$result$provenance$backend, "pwrss")
})

test_that("E1-E6 simulate with Spower when chosen, and say so under the result (B15)", {
  skip_without_run()
  values <- c(form_examples$E5, list(calc_method = "simulation"))
  fields <- form_fields(form_groups(forms, "E5"))
  spec <- build_spec(forms, "E5", fields, values)
  spec$goal <- list(type = "power", n = 48L)
  spec$options$nrep <- 100L
  calc <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(calc$result$provenance$backend, "Spower")
  html <- as.character(result_panel_ui(tree, forms, "E5", fields, values, calc))
  expect_match(html, "Calculated by simulation with 100 replications; a different seed can shift the result slightly.", fixed = TRUE)
  expect_match(html, "Seed: 1.", fixed = TRUE)
  expect_no_match(html, "Calculated with a formula", fixed = TRUE)         # Departure 9 doesn't apply
  expect_no_match(html, "the z test as G*Power runs it", fixed = TRUE)     # nor Departure 11
  # Welch's t-test has no formula: the choice isn't shown, and it simulates.
  e2 <- form_fields(form_groups(forms, "E2"))
  choice <- Filter(function(f) identical(f$id, "calc_method"), e2)[[1]]
  expect_false(field_applies(choice, form_examples$E2))                   # Welch's
  expect_true(field_applies(choice, modifyList(form_examples$E2, list(method = "student_t"))))
})

test_that("the same answers give the same result: a fixed default seed (B15)", {
  expect_identical(forms$default_seed, 1L)
  seed <- Filter(function(f) identical(f$id, "seed"), form_fields(form_groups(forms, "E9")))[[1]]
  expect_identical(seed$default, 1L)
  expect_identical(seed$path, "options.seed")
  # A screen with the seed left at its default puts it in the spec.
  values <- c(form_examples$E9, list(seed = "1"))
  fields <- form_fields(form_groups(forms, "E9"))
  expect_identical(build_spec(forms, "E9", fields, values)$options$seed, 1L)
  # A spec without a seed gets the default, never a random one.
  calc <- run_calculation(list(), run = function(spec) spec$options$seed)
  expect_identical(calc$spec$options$seed, 1L)
  skip_without_run()
  spec <- light_spec("E1")
  spec$options$method <- "simulation"
  first <- run_calculation(spec, run, seed = forms$default_seed)
  second <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(first$result$curve, second$result$curve)
})

test_that("departure 1 shows only for the interaction; the mixed design shows departure 2", {
  e7 <- light_spec("E7")
  expect_true(any(grepl("Sommet", departures_for(forms, "E7", e7))))
  e7$target_test$effect <- "main_effect_A"
  expect_false(any(grepl("Sommet", departures_for(forms, "E7", e7))))
  expect_true(any(grepl("ANOVA_exact2", departures_for(forms, "E8", light_spec("E8")))))
})

test_that("mediation shows departures 6 and 8, parallel mediators 7, and the interaction Known difference 1", {
  for (ep in c("E10", "E11", "E12", "E13", "E14")) {
    shown <- departures_for(forms, ep, light_spec(ep))
    expect_true(any(grepl("lavaan (maximum likelihood)", shown, fixed = TRUE)), info = ep) # Departure 6
    expect_true(any(grepl("Boos and Zhang", shown, fixed = TRUE)), info = ep)              # Departure 8
    expect_equal(any(grepl("residuals correlate", shown, fixed = TRUE)), ep == "E11", info = ep) # Departure 7
    expect_length(known_differences_for(forms, ep), 0)
  }
  expect_match(known_differences_for(forms, "E9"), "Fixed-model calculations", fixed = TRUE)
  expect_length(known_differences_for(forms, "E1"), 0)
  # Every departure and known difference a form names has its text.
  for (ep in names(forms$forms)) {
    expect_true(all(unlist(forms$forms[[ep]]$departures) %in% names(forms$departures)), info = ep)
    expect_true(all(unlist(forms$forms[[ep]]$known_differences) %in% names(forms$known_differences)), info = ep)
  }
})

test_that("an engine error is shown in plain English, without a stack trace", {
  calc <- run_calculation(list(), run = function(spec) stop(structure(class = c("powerkit_error", "error", "condition"), list(message = "Plain message.", call = NULL))), seed = 1L)
  html <- as.character(result_panel_ui(tree, forms, "E1", list(), list(), calc))
  expect_match(html, "Plain message.", fixed = TRUE)
  calc <- run_calculation(list(), run = function(spec) stop("internal detail"), seed = 1L)
  expect_no_match(calc$message, "internal detail", fixed = TRUE)
  expect_identical(run_calculation(list(), run = NULL)$status, "error")
})

# E10-E14 ------------------------------------------------------------------------

# A mediation spec small enough for a test: few replications and Monte Carlo
# draws.
tiny_long_spec <- function(ep, goal = list(type = "power", n = 60L)) {
  spec <- light_spec(ep, goal)
  spec$options$ci_draws <- 100L
  spec$options$seed <- 7L
  spec
}

test_that("the preview uses the recorded seed and few replications, and equals run_spec()", {
  skip_without_run()
  skip_on_cran()
  spec <- tiny_long_spec("E10")
  spec$options$nrep <- 1000L
  pspec <- preview_spec(spec, preview_nrep(forms))
  expect_identical(pspec$options$nrep, 100L)
  expect_identical(pspec$options$seed, 7L)
  expect_identical(pspec$options$ci_draws, 100L)
  job <- start_background_calculation(pspec, seed = 1L, engine_dir = file.path(repo_dir, "engine"))
  job$wait(240000)
  calc <- collect_background_calculation(job)
  expect_identical(calc$status, "ok")
  direct <- quiet_run(pspec)
  expect_equal(calc$result$curve, direct$curve)
  expect_identical(calc$result$provenance$seed, 7L)
  # Shown as a range from the engine, never as a single number.
  interval <- engine_function("power_interval", file.path(repo_dir, "engine"))
  range <- preview_range(calc$result, interval)
  expect_equal(range, interval(direct))
  sentence <- preview_sentence(range, 100L)
  expect_match(sentence, sprintf("Rough preview from 100 simulations: power is likely between %s and %s. Don't report this; run the full analysis.", percent(range[["lower"]]), percent(range[["upper"]])), fixed = TRUE)
  # E10 power: the full run is offered, with the wait stated, and the preview
  # itself has no downloads.
  html <- as.character(preview_panel_ui(forms, "E10", calc, spec, range))
  expect_match(html, "Rough preview (not a result)", fixed = TRUE)
  expect_match(html, sprintf("Run the full analysis (%s)", duration_text(full_seconds(forms, "E10", "power"))), fixed = TRUE)
  expect_match(html, "runs 1,000 simulations", fixed = TRUE)
  expect_no_match(html, "download_script|download_citations|download_run_script")
})

test_that("a required N goes straight to the R script; moderated mediation's preview offers it too", {
  for (ep in c("E10", "E13")) {
    spec <- list(goal = list(type = "sample_size", power = 0.8), options = list(seed = 3L))
    html <- as.character(no_preview_ui(forms, ep, spec))
    expect_match(html, "There is no rough preview for a required sample size", fixed = TRUE, label = ep)
    expect_match(html, "Download R script to run the full analysis on your computer", fixed = TRUE, label = ep)
    expect_match(html, htmltools::htmlEscape(script_run_time(forms, ep, "sample_size")), fixed = TRUE, label = ep)
    expect_match(html, "same spec and seed (3)", fixed = TRUE, label = ep)
    expect_match(html, "remotes::install_github", fixed = TRUE, label = ep)
    expect_no_match(html, "Rough preview|full_run", label = ep)
  }
  calc <- list(status = "ok", notes = character(), result = list(
    goal_type = "power", curve = data.frame(n = 120, power = 0.5, mcse = 0.05),
    provenance = list(nrep = 100L, seed = 1L)))
  html <- as.character(preview_panel_ui(forms, "E13", calc, list(options = list(seed = 1L)), c(lower = 0.4, upper = 0.6)))
  expect_match(html, "Rough preview from 100 simulations: power is likely between 40% and 60%", fixed = TRUE)
  expect_match(html, "Download R script to run the full analysis on your computer", fixed = TRUE)
  expect_match(html, htmltools::htmlEscape(script_run_time(forms, "E13", "power")), fixed = TRUE)
  expect_no_match(html, "full_run", fixed = TRUE)
  # A failed preview gives a plain-English message.
  html <- as.character(preview_panel_ui(forms, "E10", list(status = "error", message = "Something plain."), list(), NULL))
  expect_match(html, "The preview didn&#39;t finish|The preview didn't finish")
})

test_that("E10's full run in the background equals run_spec() with the same spec and seed", {
  skip_without_run()
  skip_on_cran()
  spec <- tiny_long_spec("E10")
  job <- start_background_calculation(spec, seed = 1L, engine_dir = file.path(repo_dir, "engine"))
  job$wait(240000)
  calc <- collect_background_calculation(job)
  expect_identical(calc$status, "ok")
  direct <- quiet_run(spec)
  expect_equal(calc$result$curve, direct$curve)
  expect_identical(calc$result$provenance$spec_hash, direct$provenance$spec_hash)
  expect_true(script_reproduces(script(calc$spec, calc$result)))
})

test_that("the downloaded R script runs the full analysis and reproduces run_spec()", {
  skip_without_run()
  skip_on_cran()
  run_script <- engine_function("export_run_script", file.path(repo_dir, "engine"))
  spec <- tiny_long_spec("E13")
  text <- run_script(spec, run_time = script_run_time(forms, "E13", "power"))
  expect_match(text, script_run_time(forms, "E13", "power"), fixed = TRUE)
  # Run it in a fresh R session, on the engine's source where powerkit isn't
  # installed.
  if (length(find.package("powerkit", lib.loc = .libPaths(), quiet = TRUE)) == 0) {
    text <- sub("library(powerkit)", sprintf("pkgload::load_all(%s, quiet = TRUE, export_all = FALSE, helpers = FALSE)",
      encodeString(file.path(repo_dir, "engine"), quote = "\"")), text, fixed = TRUE)
  }
  dir <- tempfile("run-script-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))
  writeLines(text, file.path(dir, "run.R"))
  out <- withr::with_dir(dir, withr::with_envvar(
    c(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), RENV_CONFIG_AUTOLOADER_ENABLED = "false"),
    suppressWarnings(system2(file.path(R.home("bin"), "Rscript"), c("--vanilla", "run.R"), stdout = TRUE, stderr = TRUE))
  ))
  expect_true(file.exists(file.path(dir, "powerkit-result.rds")), info = paste(tail(out, 15), collapse = "\n"))
  saved <- readRDS(file.path(dir, "powerkit-result.rds"))
  direct <- quiet_run(spec)
  expect_equal(saved$curve, direct$curve)
  expect_identical(saved$provenance$spec_hash, direct$provenance$spec_hash)
  expect_true(file.exists(file.path(dir, "powerkit-reproduce.R")))
})

test_that("waits are stated in seconds or minutes", {
  expect_identical(duration_text(75), "about 75 seconds")
  expect_identical(duration_text(734), "about 12 minutes")
  expect_identical(progress_text(130, 734), "Running for 2 minutes. This usually takes about 12 minutes.")
  expect_identical(progress_text(1, 734), "Running for 1 second. This usually takes about 12 minutes.")
  html <- as.character(calculating_background_ui(734, "Running the full analysis (1,000 simulations)\u2026"))
  expect_match(html, "Running the full analysis (1,000 simulations)", fixed = TRUE)
  expect_match(html, "This usually takes about 12 minutes on one core.", fixed = TRUE)
})

test_that("with attrition, the result shows the number analysed and the number to recruit", {
  skip_without_run()
  spec <- light_spec("E2", goal = list(type = "sample_size", power = 0.8))
  spec$options$nrep <- NULL
  spec$options$attrition <- 0.1
  calc <- run_calculation(spec, run, seed = 3L)
  r <- calc$result$recruitment
  n <- calc$result$n_required$n
  expect_equal(r$n_analysed, n)
  expect_equal(r$n_recruit, 2 * ceiling(n / 2 / 0.9 - 1e-9))
  lines <- recruitment_lines(calc$result)
  expect_identical(lines[["analysed"]], sprintf("Analysed: %s participants (%s per group).", n, n / 2))
  expect_match(lines[["recruit"]], sprintf("To recruit: %s participants (%s per group), allowing for 10%% attrition", r$n_recruit, r$n_recruit / 2), fixed = TRUE)
  expect_match(lines[["caveat"]], "common but crude heuristic", fixed = TRUE)
  expect_match(lines[["caveat"]], "doi:10.1002/ijop.70017", fixed = TRUE)
  html <- as.character(result_panel_ui(tree, forms, "E2", form_fields(form_groups(forms, "E2")), form_examples[["E2"]], calc))
  expect_match(html, "To recruit:", fixed = TRUE)
  expect_match(script(calc$spec, calc$result), "n_recruit <- sum(groups_recruit)", fixed = TRUE)

  # No attrition: nothing about recruiting.
  spec$options$attrition <- NULL
  calc <- run_calculation(spec, run, seed = 3L)
  expect_null(recruitment_lines(calc$result))
  html <- as.character(result_panel_ui(tree, forms, "E2", form_fields(form_groups(forms, "E2")), form_examples[["E2"]], calc))
  expect_no_match(html, "To recruit:", fixed = TRUE)
})

test_that("the smallest detectable effect for a basic test, with no effect size given", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- form_examples[["E2"]]
  values$method <- "student_t"; values$goal <- "sensitivity"; values$n <- "128"; values$power <- "0.8"; values$d <- ""
  calc <- run_calculation(build_spec(forms, "E2", fields, values), seed = forms$default_seed)
  expect_equal(calc$status, "ok")
  expect_equal(calc$result$sensitivity$effect, pwr::pwr.t.test(n = 64, d = NULL, power = 0.8)$d)
  html <- as.character(result_panel_ui(tree, forms, "E2", fields, values, calc))
  expect_match(html, "the smallest effect you could detect with 80% power", fixed = TRUE)
  expect_match(html, "is d = 0.499. The effect: Cohen's d", fixed = TRUE)
})

test_that("the range of sample sizes shows the smallest effect at 80% and 95% power", {
  fields <- form_fields(form_groups(forms, "E4"))
  values <- form_examples[["E4"]]
  values$just_type <- "none"; values$just_source <- ""; values$r <- ""; values$goal <- "sensitivity_curve"; values$n_max <- "160"
  calc <- run_sensitivity_curve(build_spec(forms, "E4", fields, values), seed = forms$default_seed)
  expect_equal(calc$status, "ok")
  tab <- calc$curve_table
  expect_equal(tab$n, c(20, 40, 60, 80, 100, 120, 140, 160))
  expect_equal(tab$power_80[8], pwr::pwr.r.test(n = 160, r = NULL, power = 0.8)$r)
  expect_true(all(tab$power_95 > tab$power_80))
  expect_true(all(diff(tab$power_80) < 0))
  html <- as.character(result_panel_ui(tree, forms, "E4", fields, values, calc))
  expect_match(html, "The smallest effect you could detect at each sample size", fixed = TRUE)
  # No reasoning written: no saving or exporting yet.
  expect_match(html, "To save this plan, download its R script or get its write-up", fixed = TRUE)
  expect_no_match(html, "download_project", fixed = TRUE)
  values$just_source <- "No earlier study measures this; the pool is fixed at 160."
  html <- as.character(result_panel_ui(tree, forms, "E4", fields, values, calc))
  expect_match(html, "download_project", fixed = TRUE)
})

test_that("an effect size from one earlier study gets a short warning", {
  expect_match(source_note(list(just_type = "prior_study")), "BUCSS", fixed = TRUE)
  expect_null(source_note(list(just_type = "meta_analysis")))
})

# Screen D: plain reading, the .80/.95 line, and no verdict words ------------

test_that("the result reads in plain words, shows 80% and 95% side by side, the reasoning and what power can't tell you", {
  spec <- light_spec("E2", goal = list(type = "sample_size", power = 0.9))
  spec$target_test$method <- "student_t"
  values <- form_examples[["E2"]]
  values$just_source <- "Smallest difference our clinic would act on."
  calc <- run_calculation(spec, seed = forms$default_seed)
  calc$cost_line <- cost_line(calc$spec, calc$result, seed = forms$default_seed)
  n80 <- 2 * ceiling(pwr::pwr.t.test(d = 0.4, power = 0.8)$n)
  n95 <- 2 * ceiling(pwr::pwr.t.test(d = 0.4, power = 0.95)$n)
  expect_match(calc$cost_line, sprintf("80%% power needs %s participants", n80), fixed = TRUE)
  expect_match(calc$cost_line, sprintf("95%% power needs %s", n95), fixed = TRUE)
  html <- as.character(result_panel_ui(tree, forms, "E2", form_fields(form_groups(forms, "E2")), values, calc))
  expect_match(html, "about 9 in 10 studies like this would get a significant result", fixed = TRUE)
  expect_match(html, "Your reasoning: “Smallest difference our clinic would act on.”", fixed = TRUE)
  expect_match(html, "tell you whether your measures are valid", fixed = TRUE)
})

test_that("no output template uses a verdict word", {
  # The new design (docs/decisions.md, 18 October 2026, decision 8): the
  # app describes a plan, it never grades it. User text is left out.
  verdict <- "\\b(justified|approved|adequate|adequately|sufficiently powered|sufficient power|well[- ]powered)\\b"
  templates <- c(
    plain_reading(0.8), power_limits, not_observed_power,
    source_note(list(just_type = "prior_study")),
    unlist(lapply(c("each", "any", "all"), function(cl) claim_result_note(list(claim = cl, n_tests = "3"), 0.05 / 3))),
    unlist(lapply(c("each", "any", "all"), function(cl) claim_groups(cl)[[1]]$note)),
    unlist(forms$departures), unlist(forms$known_differences),
    vapply(c("smallest_effect_of_interest", "meta_analysis", "prior_study", "pilot_study", "none"),
      function(t) reasoning_line(list(just_type = t)), ""),
    unlist(forms$known_differences_methods)
  )
  for (ep in c("E1", "E4")) {
    for (goal in list(list(type = "sample_size", power = 0.8), list(type = "power", n = 60L), list(type = "sensitivity", n = 60L, power = 0.8))) {
      calc <- run_calculation(light_spec(ep, goal = goal), seed = forms$default_seed)
      templates <- c(templates, result_sentences(calc$spec, calc$result))
      for (jt in c("smallest_effect_of_interest", "none")) {
        v <- modifyList(form_examples[[ep]], list(just_type = jt, just_source = "x", claim = "any", n_tests = "2"))
        templates <- c(templates, writeup_text(forms$forms[[ep]], calc$spec, calc$result,
          form_fields(form_groups(forms, ep)), v, departures_for(forms, ep, calc$spec)))
      }
    }
  }
  hits <- templates[grepl(verdict, templates, ignore.case = TRUE, perl = TRUE)]
  expect_length(hits, 0)
})

test_that("the explore panel shows power by N for another effect size, without touching the plan", {
  spec <- light_spec("E2", goal = list(type = "sample_size", power = 0.8))
  spec$target_test$method <- "student_t"
  calc <- run_calculation(spec, seed = forms$default_seed)
  df <- explore_curve(calc$spec, calc$result, 0.6, seed = forms$default_seed)
  expect_equal(df$power[1], pwr::pwr.t.test(n = df$n[1] / 2, d = 0.6)$power)
  expect_true(all(diff(df$power) > 0))
  expect_equal(calc$spec$population$d, 0.4) # the plan is unchanged
  expect_match(as.character(explore_ui(calc$spec)), "Exploring doesn&#39;t change your plan|Exploring doesn't change your plan")
  # Not offered for simulation or for designs other than the t-tests and the correlation.
  expect_null(explore_ui(light_spec("E7")))
  sim <- spec; sim$options$method <- "simulation"
  expect_null(explore_ui(sim))
})

# The write-up (methods paragraph; decided 18 October 2026) ----------------

test_that("the write-up states the test, alpha, power and its reason, the effect with the reasoning, N and the software", {
  spec <- light_spec("E2", goal = list(type = "sample_size", power = 0.8))
  spec$target_test$method <- "student_t"
  calc <- run_calculation(spec, seed = forms$default_seed)
  values <- modifyList(form_examples[["E2"]], list(just_source = "Smallest difference our clinic would act on.",
    power_reason = "the usual convention in our field."))
  fields <- form_fields(form_groups(forms, "E2"))
  w <- writeup_text(forms$forms$E2, calc$spec, calc$result, fields, values, departures_for(forms, "E2", calc$spec))
  n <- 2 * ceiling(pwr::pwr.t.test(d = 0.4, power = 0.8)$n)
  expect_match(w[["short"]], "An a priori power analysis was conducted for an independent-samples t-test (two-sided, \u03b1 = .05).", fixed = TRUE)
  expect_match(w[["short"]], "Cohen's d = 0.4", fixed = TRUE)
  expect_match(w[["short"]], "\u201cSmallest difference our clinic would act on.\u201d For a target", fixed = TRUE)
  expect_match(w[["short"]], "target power of 80%, chosen because the usual convention in our field,", fixed = TRUE)
  expect_match(w[["short"]], sprintf("%s participants are needed in total (%s per group)", n, n / 2), fixed = TRUE)
  expect_match(w[["short"]], sprintf("pwr (version %s", calc$result$provenance$packages[["pwr"]]), fixed = TRUE)
  expect_match(w[["short"]], "described in the supplement", fixed = TRUE)
  expect_match(w[["full"]], "Departures from the established tools' defaults: Calculated with a formula", fixed = TRUE)
  expect_match(w[["full"]], calc$result$provenance$spec_hash, fixed = TRUE)
  expect_no_match(paste(w, collapse = " "), "noncentrality|critical value", ignore.case = TRUE)
})

test_that("the write-up needs the reasoning, and words the fixed-N route and the claim", {
  spec <- light_spec("E4", goal = list(type = "sensitivity", n = 80L, power = 0.8))
  spec$target_test$alpha <- 0.025 # build_spec() divides alpha for "any of 2"
  calc <- run_calculation(spec, seed = forms$default_seed)
  fields <- form_fields(form_groups(forms, "E4"))
  values <- modifyList(form_examples[["E4"]], list(just_type = "none", situation = "fixed", claim = "any", n_tests = "2"))
  values$just_source <- ""
  expect_null(writeup_text(forms$forms$E4, calc$spec, calc$result, fields, values))
  values$just_source <- "Our participant pool has 80 students a year."
  w <- writeup_text(forms$forms$E4, calc$spec, calc$result, fields, values)
  expect_match(w[["short"]], "A sensitivity power analysis", fixed = TRUE)
  expect_match(w[["short"]], "fixed by resource constraints at 80 participants", fixed = TRUE)
  expect_match(w[["short"]], sprintf("r = %s", format(round(calc$result$sensitivity$effect, 3), nsmall = 2)), fixed = TRUE)
  expect_match(w[["short"]], "No effect size was chosen in advance", fixed = TRUE)
  expect_match(w[["short"]], "divided by 2 (Bonferroni), giving \u03b1 = .025", fixed = TRUE)
})

test_that("the regression interaction's write-up carries the known difference's sentence", {
  expect_match(forms$known_differences_methods[["1"]], "predictors drawn afresh", fixed = TRUE)
  expect_equal(names(forms$known_differences_methods), names(forms$known_differences))
  for (ep in names(forms$forms)) expect_true(nzchar(forms$forms[[ep]]$methods_name %||% ""), label = ep)
})

test_that("the designs added later get a write-up with short effect names and their known difference", {
  skip_without_run()
  for (ep in c("E18", "E23", "E24", "E25", "E26", "E48", "E49")) {
    spec <- build_spec(forms, ep, form_fields(form_groups(forms, ep)), form_examples[[ep]])
    calc <- run_calculation(spec, run, seed = 1L)
    fields <- form_fields(form_groups(forms, ep))
    values <- modifyList(form_examples[[ep]], list(just_source = "A pilot study."))
    known <- vapply(unlist(forms$forms[[ep]]$known_differences), function(k) forms$known_differences_methods[[k]], character(1))
    w <- writeup_text(forms$forms[[ep]], calc$spec, calc$result, fields, values, known_methods = known)
    expect_match(w[["short"]], forms$forms[[ep]]$methods_name, fixed = TRUE, label = ep)
    expect_no_match(w[["short"]], "(0 to 1", fixed = TRUE, label = ep)
    if (ep %in% c("E25", "E26")) expect_match(w[["short"]], "exact test of counts", fixed = TRUE, label = ep)
    if (ep %in% c("E18", "E23", "E24")) expect_no_match(w[["short"]], "sided", fixed = TRUE, label = ep) # F tests have no sides
  }
})

test_that("one-way ANOVA, regression, one proportion and McNemar run on the engine, with their notes", {
  skip_without_run()
  calc <- run_calculation(light_spec("E18"), run, seed = 1L)
  expect_identical(calc$result$provenance$backend, "Superpower")
  expect_match(result_sentences(calc$spec, calc$result)[["headline"]], "(16 per group)", fixed = TRUE)
  spec <- build_spec(forms, "E26", form_fields(form_groups(forms, "E26")), form_examples$E26)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.exact.mcnemar")
  # G*Power's exact option gives 129 for these values (test-backend-wave2.R).
  expect_equal(calc$result$n_required$n, 129)
  html <- as.character(result_panel_ui(tree, forms, "E26", form_fields(form_groups(forms, "E26")), form_examples$E26, calc))
  expect_match(html, "exact tests of counts", fixed = TRUE)           # Known difference 2
  expect_match(html, "Validation in progress. ", fixed = TRUE)
  expect_match(html, "pwrss's formula, pwrss::power.exact.mcnemar(), no simulation", fixed = TRUE)
  for (ep in c("E24", "E25")) {
    calc <- run_calculation(light_spec(ep), run, seed = 1L)
    expect_identical(calc$result$provenance$backend, "pwrss", label = ep)
  }
  # One-way ANCOVA, on pwrss's Shieh method.
  calc <- run_calculation(light_spec("E23"), run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.f.ancova.shieh")
  # Welch's t-test by formula, if chosen.
  values <- c(form_examples$E2, list(welch_method = "exact"))
  spec <- build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), values)
  spec$goal <- list(type = "power", n = 48L)
  expect_identical(run_calculation(spec, run, seed = 1L)$result$provenance$backend_function, "pwrss::power.t.welch")
})

test_that("Fisher's exact test (E5's option) runs on pwrss, with its own notes", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E5"))
  values <- modifyList(form_examples$E5, list(method = "fisher_exact", p1 = "0.3", p2 = "0.6", just_source = "A pilot study."))
  calc <- run_calculation(build_spec(forms, "E5", fields, values), run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.exact.fisher")
  html <- as.character(result_panel_ui(tree, forms, "E5", fields, values, calc))
  expect_match(html, "Fisher's exact test are exact tests of counts", fixed = TRUE) # Known difference 2
  expect_no_match(html, "continuity correction", fixed = TRUE)                   # Departure 5 is the z test's
  expect_no_match(html, "pooled variance", fixed = TRUE)                         # so is Departure 11
  w <- writeup_text(forms$forms$E5, calc$spec, calc$result, fields, values,
    known_methods = vapply(known_difference_keys(forms, "E5", calc$spec), function(k) forms$known_differences_methods[[k]], character(1)))
  expect_match(w[["short"]], "Fisher's exact test of two proportions", fixed = TRUE)
  expect_match(w[["short"]], "exact test of counts", fixed = TRUE)
  # With the z test, Known difference 2 doesn't apply.
  z <- build_spec(forms, "E5", fields, form_examples$E5)
  expect_length(known_difference_keys(forms, "E5", z), 0)
})

test_that("goodness of fit and two correlations run on pwrss, with their notes", {
  skip_without_run()
  fns <- c(E48 = "pwrss::power.chisq.gof", E49 = "pwrss::power.z.twocors")
  for (ep in names(fns)) {
    fields <- form_fields(form_groups(forms, ep))
    calc <- run_calculation(build_spec(forms, ep, fields, form_examples[[ep]]), run, seed = 1L)
    expect_identical(calc$result$provenance$backend_function, fns[[ep]], label = ep)
    expect_gt(calc$result$n_required$n, 0)
    html <- as.character(result_panel_ui(tree, forms, ep, fields, form_examples[[ep]], calc))
    expect_match(html, "Validation in progress. ", fixed = TRUE, label = ep)
  }
})
