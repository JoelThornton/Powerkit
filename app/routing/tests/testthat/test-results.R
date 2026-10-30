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
  # The generic tests (E50) have no sample size and nothing to simulate.
  if (ep == "E50") return(spec)
  # A cluster-randomised trial's size is a whole number of groups.
  if (ep == "E34" && !is.null(goal$n)) goal$n <- 80L
  # A factorial logistic regression needs ten people in every cell.
  if (ep == "E47" && !is.null(goal$n)) goal$n <- 60L
  spec$goal <- goal
  if (!ep %in% c("E7", "E8", "E36")) spec$options$nrep <- 100L
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
simulated <- names(forms$simulations$endpoints)

test_that("calculating designs calculate; simulated designs preview first, then a full run or an R script", {
  expect_setequal(c(wired, simulated), names(forms$forms))
  for (ep in simulated) {
    expect_false(form_calculates(forms, ep), label = ep)
    expect_true(runs_long(forms, ep), label = ep)
  }
  # E9 and E15 run in the background with no preview, with their usual run times.
  expect_identical(names(forms$background), c("E9", "E15"))
  for (ep in paste0("E", 1:8)) expect_false(runs_in_background(forms, ep), label = ep)
  expect_equal(usual_seconds(forms, "E9", "power"), 5)
  expect_equal(usual_seconds(forms, "E9", "sample_size"), 80)
  expect_equal(usual_seconds(forms, "E9", "sensitivity"), 2)
  # The maintainer's choices (17 October 2026): a preview of about 100
  # replications; the full run in the app for mediation power at a fixed N
  # only; the R script for everything else.
  expect_identical(preview_nrep(forms), 100L)
  for (ep in c(paste0("E", 10:12), "E16", "E33")) {
    expect_true(full_run_in_app(forms, ep, "power"), label = ep)
    expect_false(full_run_in_app(forms, ep, "sample_size"), label = ep)
    expect_true(full_seconds(forms, ep, "power") > 0, label = ep)
  }
  # A preview for power only: a required N goes straight to the R script.
  for (ep in simulated) {
    expect_true(has_preview(forms, ep, "power"), label = ep)
    expect_true(preview_seconds(forms, ep, "power") > 0, label = ep)
    expect_false(has_preview(forms, ep, "sample_size"), label = ep)
    for (goal in c("power", "sample_size")) {
      if (!full_run_in_app(forms, ep, goal)) expect_match(script_run_time(forms, ep, goal), "one core", label = paste(ep, goal))
    }
  }
  for (ep in c("E13", "E14", "E40")) expect_false(full_run_in_app(forms, ep, "power"), label = ep)
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

test_that("a required N shows the power it actually gives (G5), with an interval when simulated", {
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
  est <- calc$result$n_required
  expect_match(actual_power_sentence(calc$spec, calc$result), sprintf(
    "power is about %.1f%% (95%% interval %.1f%% to %.1f%%, from the curve fitted to the simulations)",
    100 * est$power, 100 * est$power_lower, 100 * est$power_upper), fixed = TRUE)
})

test_that("technical details show the package's df, critical value and noncentrality, or say why not", {
  skip_without_run()
  calc <- run_calculation(light_spec("E7"), run, seed = 3L)
  d <- calc$result$details
  html <- as.character(technical_details_ui(calc$result))
  expect_match(html, "Technical details (for checking against G*Power or R)", fixed = TRUE)
  expect_match(html, sprintf("Degrees of freedom: %s and %s.", d$df[1], d$df[2]), fixed = TRUE)
  expect_match(html, "Noncentrality parameter:", fixed = TRUE)
  expect_match(html, paste("Reported by", d$source), fixed = TRUE)
  full <- as.character(result_panel_ui(tree, forms, "E7", form_fields(form_groups(forms, "E7")), form_examples[["E7"]], calc))
  expect_match(full, "Technical details", fixed = TRUE)

  spec <- light_spec("E2")
  spec$options$method <- "simulation"
  calc <- run_calculation(spec, run, seed = 3L)
  expect_match(as.character(technical_details_ui(calc$result)), "Not applicable: this result was simulated", fixed = TRUE)
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
  # Departures that change the answer stay in view, with a pointer from the
  # answer; the ones that don't (9, 11) are folded.
  expect_match(html, "slightly different answer for this design", fixed = TRUE)
  minor <- regmatches(html, regexpr("result-departures-minor.*?</details>", html))
  expect_match(minor, "Calculated with a formula", fixed = TRUE)
  expect_match(minor, "the z test as G*Power runs it", fixed = TRUE)
  expect_no_match(minor, "No continuity correction", fixed = TRUE)
  expect_match(html, "in group 1 (0 to 1): 0.6", fixed = TRUE)            # an input it used
  expect_match(html, "download_script", fixed = TRUE)
  expect_match(html, "download_citations", fixed = TRUE)
  expect_match(html, "download_simulated_data", fixed = TRUE)            # the simulated data set
  expect_match(html, "Simulated, not real data.", fixed = TRUE)
  expect_match(html, "Short version (for the paper)", fixed = TRUE)
  expect_match(html, "Departures from the established tools&#39; defaults:|Departures from the established tools' defaults:")
  expect_match(html, calc$result$provenance$spec_hash, fixed = TRUE)
  # The settings for the maintainer show only in the maintainer's view.
  result_settings <- c("result_wording", "n_rounding", "power_curve")
  for (key in result_settings) expect_no_match(html, setting_by_key(tree, key)$question |> htmltools::htmlEscape(), fixed = TRUE, label = key)
  html_maintainer <- withr::with_options(list(powerkit.maintainer_view = TRUE),
    as.character(result_panel_ui(tree, forms, "E5", fields, form_examples$E5, calc)))
  # All three were decided on 22 October 2026, so they show as decisions.
  for (key in result_settings) {
    s <- setting_by_key(tree, key)
    expect_match(html_maintainer, htmltools::htmlEscape(s$options[[s$value]]), fixed = TRUE, label = key)
  }
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
  for (ep in c("E10", "E11", "E12", "E13", "E14", "E40", "E16")) {
    shown <- departures_for(forms, ep, light_spec(ep))
    expect_true(any(grepl("lavaan (maximum likelihood)", shown, fixed = TRUE)), info = ep) # Departure 6
    expect_true(any(grepl("Boos and Zhang", shown, fixed = TRUE)), info = ep)              # Departure 8
    expect_equal(any(grepl("residuals correlate", shown, fixed = TRUE)), ep %in% c("E11", "E40"), info = ep) # Departure 7
    expect_length(known_differences_for(forms, ep), 0)
  }
  expect_match(known_differences_for(forms, "E9"), "Fixed-model calculations", fixed = TRUE)
  # The smallest detectable effect has its own wording: it uses the formula.
  expect_match(known_differences_for(forms, "E9", list(goal = list(type = "sensitivity"))), "comes from InteractionPoweR's fixed-model formula", fixed = TRUE)
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

test_that("two proportions and chi-square give the range of sample sizes with no effect size", {
  fields <- form_fields(form_groups(forms, "E6"))
  values <- modifyList(form_examples[["E6"]], list(just_type = "none", probabilities = "", goal = "sensitivity_curve", n_max = "160"))
  calc <- run_sensitivity_curve(build_spec(forms, "E6", fields, values), seed = forms$default_seed)
  expect_equal(calc$status, "ok")
  df <- (length(parse_levels(values$X_levels)) - 1) * (length(parse_levels(values$Y_levels)) - 1)
  expect_equal(calc$curve_table$power_80[8], pwr::pwr.chisq.test(N = 160, w = NULL, df = df, power = 0.8)$w)
  expect_match(as.character(result_panel_ui(tree, forms, "E6", fields, values, calc)), "Smallest w, 80% power", fixed = TRUE)

  fields <- form_fields(form_groups(forms, "E5"))
  values <- modifyList(form_examples[["E5"]], list(just_type = "none", p2 = "", goal = "sensitivity_curve", n_max = "400"))
  calc <- run_sensitivity_curve(build_spec(forms, "E5", fields, values), seed = forms$default_seed)
  expect_equal(calc$status, "ok")
  tab <- calc$curve_table
  expect_true(all(tab$power_80 > as.numeric(values$p1)))
  expect_true(all(diff(tab$power_80) < 0))
  html <- as.character(result_panel_ui(tree, forms, "E5", fields, values, calc))
  expect_match(html, "Group 2's proportion, 80% power", fixed = TRUE)
  expect_match(html, "Group 2's proportion needed (group 1's kept at 0.6). Larger samples can detect smaller differences", fixed = TRUE)
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
    unlist(claim_notes()),
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
  expect_no_match(w[["short"]], "supplement|depart", ignore.case = TRUE)
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

test_that("the write-up gives the reasons for a changed alpha or a one-sided test", {
  spec <- light_spec("E2", goal = list(type = "sample_size", power = 0.8))
  spec$target_test$method <- "student_t"
  spec$target_test$alpha <- 0.01
  spec$target_test$alternative <- "greater"
  calc <- run_calculation(spec, seed = forms$default_seed)
  fields <- form_fields(form_groups(forms, "E2"))
  values <- modifyList(form_examples[["E2"]], list(just_source = "Smallest difference our clinic would act on.",
    alpha = "0.01", alpha_reason = "this is a new claim.", alternative = "greater",
    alternative_reason = "the hypothesis predicts that training raises scores"))
  w <- writeup_text(forms$forms$E2, calc$spec, calc$result, fields, values)
  expect_match(w[["short"]], "(one-sided, effect positive, α = .01). The significance level of .01 was chosen because this is a new claim. A one-sided test was used because the hypothesis predicts that training raises scores.", fixed = TRUE)
  # No sentence when the settings are back at their defaults, even with old text in the boxes.
  values <- modifyList(values, list(alpha = "0.05", alternative = "two_sided"))
  expect_length(writeup_choices(fields, values), 0)
})

test_that("the regression interaction's write-up carries the known difference's sentence", {
  expect_match(forms$known_differences_methods[["1"]], "predictors drawn afresh", fixed = TRUE)
  expect_equal(names(forms$known_differences_methods), names(forms$known_differences))
  for (ep in names(forms$forms)) expect_true(nzchar(forms$forms[[ep]]$methods_name %||% ""), label = ep)
})

test_that("the designs added later get a write-up with short effect names and their known difference", {
  skip_without_run()
  for (ep in c("E18", "E19", "E20", "E21", "E23", "E24", "E25", "E26", "E27", "E28", "E34", "E36", "E48", "E49", "E51", "E52", "E53", "E54", "E55", "E56")) {
    spec <- build_spec(forms, ep, form_fields(form_groups(forms, ep)), form_examples[[ep]])
    calc <- run_calculation(spec, run, seed = 1L)
    fields <- form_fields(form_groups(forms, ep))
    values <- modifyList(form_examples[[ep]], list(just_source = "A pilot study."))
    known <- vapply(unlist(forms$forms[[ep]]$known_differences), function(k) forms$known_differences_methods[[k]], character(1))
    w <- writeup_text(forms$forms[[ep]], calc$spec, calc$result, fields, values, known_methods = known)
    expect_match(w[["short"]], forms$forms[[ep]]$methods_name, fixed = TRUE, label = ep)
    expect_no_match(w[["short"]], "(0 to 1", fixed = TRUE, label = ep)
    if (ep %in% c("E25", "E26")) expect_match(w[["short"]], "exact test of counts", fixed = TRUE, label = ep)
    if (ep %in% c("E18", "E20", "E21", "E23", "E24", "E54", "E55", "E56")) expect_no_match(w[["short"]], "sided", fixed = TRUE, label = ep) # F tests have no sides
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
  # Two-way ANCOVA, from the same screen with two factors.
  fields <- form_fields(form_groups(forms, "E23"))
  expect_equal(form_problems(fields, form_example_ancova_two), character())
  spec <- build_spec(forms, "E23", fields, form_example_ancova_two)
  expect_identical(spec$template, "factorial_ancova")
  expect_identical(spec$variables$B$type, "between_factor")
  expect_identical(spec$target_test$effect, "interaction")
  spec$goal <- list(type = "power", n = 120L)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.f.ancova.shieh")
  expect_true(all(calc$result$check_run$ok))
  # Welch's t-test by formula, if chosen.
  values <- c(form_examples$E2, list(welch_method = "exact"))
  spec <- build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), values)
  spec$goal <- list(type = "power", n = 48L)
  expect_identical(run_calculation(spec, run, seed = 1L)$result$provenance$backend_function, "pwrss::power.t.welch")
})

test_that("the rank tests (E1, E2, E3 and E18's test version) are simulated with Spower, with their own notes", {
  skip_without_run()
  for (ep in names(form_examples_rank)) {
    fields <- form_fields(form_groups(forms, ep))
    values <- form_examples_rank[[ep]]
    expect_equal(form_problems(fields, values), character(), info = ep)
    spec <- build_spec(forms, ep, fields, values)
    expect_identical(spec$population$score_shape, values$score_shape, info = ep)
    expect_null(spec$options$method, info = ep)
    spec$goal <- list(type = "power", n = 60L)
    spec$options$nrep <- 100L
    calc <- run_calculation(spec, run, seed = 1L)
    expect_identical(calc$result$provenance$backend, "Spower", info = ep)
    expect_true(all(calc$result$check_run$ok), info = ep)
    html <- as.character(result_panel_ui(tree, forms, ep, fields, values, calc))
    expect_match(html, "powerkit simulates the rank test itself", fixed = TRUE, info = ep) # Known difference 5
    expect_no_match(html, "Calculated with a formula", fixed = TRUE, info = ep)          # Departure 9
    expect_no_match(html, "exact dataset is built", fixed = TRUE, info = ep)              # Departure 3
    expect_null(explore_effect(calc$spec))
    w <- writeup_text(forms$forms[[ep]], calc$spec, calc$result, fields, values)
    expect_match(w[["short"]], "simulated assuming", fixed = TRUE, info = ep)
  }
  # The t-test and ANOVA have no shape question, and no Known difference 5.
  for (ep in names(form_examples_rank)) {
    spec <- build_spec(forms, ep, form_fields(form_groups(forms, ep)), form_examples[[ep]])
    expect_null(spec$population$score_shape, info = ep)
    expect_length(known_difference_keys(forms, ep, spec), 0)
  }
  # The signed-rank screens offer no skewed shape (the test assumes symmetry).
  shape <- Filter(function(f) identical(f$id, "score_shape"), form_fields(form_groups(forms, "E1")))[[1]]
  expect_false("skewed" %in% names(shape$choices))
})

test_that("Welch's F (E18's test version) is simulated with Spower from each group's SD", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E18"))
  values <- modifyList(form_examples$E18, list(test_version = "welch_f", sds = "4, 6, 9", sd = NULL, method = NULL))
  expect_equal(form_problems(fields, values), character())
  spec <- build_spec(forms, "E18", fields, values)
  expect_equal(unlist(spec$population$sds), c(4, 6, 9))
  expect_null(spec$population[["sd"]])
  expect_null(spec$options$method)
  spec$goal <- list(type = "power", n = 60L)
  spec$options$nrep <- 100L
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "Spower::Spower(Spower::p_anova.test(var.equal = FALSE))")
  expect_true(all(calc$result$check_run$ok))
  html <- as.character(result_panel_ui(tree, forms, "E18", fields, values, calc))
  expect_no_match(html, "exact dataset is built", fixed = TRUE) # Departure 3
  w <- writeup_text(forms$forms$E18, calc$spec, calc$result, fields, values)
  expect_match(w[["short"]], "Welch's one-way ANOVA", fixed = TRUE)
  # Each group's SD is asked only for Welch's F; the F test keeps one SD.
  sds <- Filter(function(f) identical(f$id, "sds"), fields)[[1]]
  expect_false(field_applies(sds, form_examples$E18))
})

test_that("equivalence for a correlation or two proportions (E36) runs on TOSTER's z tests, in its own words", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E36"))
  expected <- list(
    tost_correlation = c("TOSTER::power_z_cor", "show that the true correlation lies inside", "r = \u00b10.2", "of a correlation"),
    tost_two_proportions = c("TOSTER::power_twoprop", "show that the true difference lies inside", "p2 \u2212 p1 = \u00b10.1", "of two independent proportions")
  )
  for (name in names(expected)) {
    values <- tost_z_examples[[name]]
    expect_equal(form_problems(fields, values), character(), info = name)
    spec <- build_spec(forms, "E36", fields, values)
    expect_identical(spec$template, name)
    calc <- run_calculation(spec, run, seed = 1L)
    expect_identical(calc$result$provenance$backend_function, expected[[name]][1], info = name)
    words <- result_sentences(calc$spec, calc$result)
    expect_match(words[["headline"]], expected[[name]][2], fixed = TRUE, info = name)
    expect_match(words[["headline"]], expected[[name]][3], fixed = TRUE, info = name)
    w <- writeup_text(forms$forms$E36, calc$spec, calc$result, fields, values)
    expect_match(w[["short"]], expected[[name]][4], fixed = TRUE, info = name)
  }
  # Two equal groups.
  spec <- build_spec(forms, "E36", fields, tost_z_examples$tost_two_proportions)
  result <- run_calculation(spec, run, seed = 1L)$result
  expect_match(result_sentences(spec, result)[["headline"]], sprintf("(%s per group)", result$n_required$n / 2), fixed = TRUE)
})

test_that("repeated measures with three or more conditions show the MANOVA approach beside the univariate F", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E54"))
  spec <- build_spec(forms, "E54", fields, form_examples$E54)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_false(is.null(calc$result$manova))
  words <- result_sentences(calc$spec, calc$result)
  expect_match(words[["detail"]], "The MANOVA approach, which doesn't, has", fixed = TRUE)
  w <- writeup_text(forms$forms$E54, calc$spec, calc$result, fields, form_examples$E54)
  expect_match(w[["full"]], "the MANOVA approach (Pillai's trace)", fixed = TRUE)
  # A between-participants design has no MANOVA sentence.
  spec <- build_spec(forms, "E18", form_fields(form_groups(forms, "E18")), form_examples$E18)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_no_match(result_sentences(calc$spec, calc$result)[["detail"]], "MANOVA", fixed = TRUE)
})

test_that("non-inferiority (E36) runs on pwrss's one-sided tests, worded for one direction", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E36"))
  expected <- list(noninf_independent = "pwrss::power.t.student", noninf_two_proportions = "pwrss::power.z.twoprops")
  for (name in names(expected)) {
    values <- noninf_examples[[name]]
    expect_equal(form_problems(fields, values), character(), info = name)
    spec <- build_spec(forms, "E36", fields, values)
    expect_identical(spec$template, name)
    expect_identical(spec$target_test$method, "non_inferiority")
    calc <- run_calculation(spec, run, seed = 1L)
    expect_identical(calc$result$provenance$backend_function, expected[[name]], info = name)
    words <- result_sentences(calc$spec, calc$result)
    expect_match(words[["headline"]], "no worse than the comparison by more than the margin", fixed = TRUE, info = name)
    expect_no_match(paste(words, collapse = " "), "equivalence bounds", fixed = TRUE)
    w <- writeup_text(forms$forms$E36, calc$spec, calc$result, fields, values)
    expect_match(w[["short"]], "a non-inferiority test (one-sided, against the margin)", fixed = TRUE, info = name)
  }
})

test_that("measurement invariance over two occasions (E37) runs on semPower.powerLI()", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E37"))
  values <- sem_examples$occasions
  expect_length(form_problems(fields, values), 0)
  spec <- build_spec(forms, "E37", fields, values)
  expect_null(spec$options$allocation_ratio)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "semPower::semPower.powerLI")
  words <- result_sentences(calc$spec, calc$result)
  expect_match(words[["headline"]], "equal loadings on the two occasions", fixed = TRUE)
  expect_match(words[["detail"]], "on two occasions (the factor correlating 0.6 between them)", fixed = TRUE)
})

test_that("Spearman's and Kendall's correlations (E4) and the Pitman-Morgan test (E57) are simulated with Spower", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E4"))
  for (method in c("spearman", "kendall")) {
    values <- modifyList(form_examples$E4, list(method = method))
    expect_equal(form_problems(fields, values), character(), info = method)
    spec <- build_spec(forms, "E4", fields, values)
    expect_identical(spec$target_test$method, method)
    expect_null(spec$options$method)
    spec$goal <- list(type = "power", n = 60L)
    spec$options$nrep <- 100L
    calc <- run_calculation(spec, run, seed = 1L)
    expect_match(calc$result$provenance$backend_function, sprintf("method = \"%s\"", method), fixed = TRUE)
  }
  # The test version is Pearson's r unless chosen.
  calc_field <- Filter(function(f) identical(f$id, "calc_method"), fields)[[1]]
  expect_identical(calc_field$shown_if, list(field = "method", is = "pearson"))

  fields <- form_fields(form_groups(forms, "E57"))
  expect_equal(form_problems(fields, form_examples$E57), character())
  spec <- build_spec(forms, "E57", fields, form_examples$E57)
  spec$goal <- list(type = "power", n = 60L)
  spec$options$nrep <- 100L
  calc <- run_calculation(spec, run, seed = 1L)
  expect_match(calc$result$provenance$backend_function, "Pitman-Morgan", fixed = TRUE)
  expect_true(all(calc$result$check_run$ok))
  w <- writeup_text(forms$forms$E57, calc$spec, calc$result, fields, form_examples$E57)
  expect_match(w[["short"]], "the Pitman-Morgan test of two paired variances", fixed = TRUE)
})

test_that("the Bayes factor t-tests (E1, E2 and E3's test version) run on bfpwr, with no alpha", {
  skip_without_run()
  for (ep in c("E1", "E2", "E3")) {
    fields <- form_fields(form_groups(forms, ep))
    values <- modifyList(form_examples[[ep]], list(method = "bayes_factor", evidence_threshold = "10", prior_scale = "0.707",
                                                   effect_sd = "0", just_source = "A meta-analysis.", alpha = NULL))
    expect_equal(form_problems(fields, values), character(), info = ep)
    # The significance level isn't asked for the Bayes factor version.
    alpha <- Filter(function(f) identical(f$id, "alpha"), fields)[[1]]
    expect_false(field_applies(alpha, values), info = ep)
    spec <- build_spec(forms, ep, fields, values)
    expect_null(spec$target_test$alpha, info = ep)
    expect_identical(spec$target_test$evidence_threshold, 10, info = ep)
    calc <- run_calculation(spec, run, seed = 1L)
    expect_identical(calc$result$provenance$backend, "bfpwr", info = ep)
    words <- result_sentences(calc$spec, calc$result)
    expect_match(words[["headline"]], "chance of strong evidence", fixed = TRUE, info = ep)
    expect_match(words[["detail"]], "If there were no effect", fixed = TRUE, info = ep)
    html <- as.character(result_panel_ui(tree, forms, ep, fields, values, calc))
    expect_match(html, "treating the effect estimate as normally distributed", fixed = TRUE, info = ep) # Known difference 6
    expect_match(html, "plans for exactly the effect you entered", fixed = TRUE, info = ep)            # Departure 15
    expect_no_match(html, "Calculated with a formula", fixed = TRUE, info = ep)                        # Departure 9
    known <- vapply(known_difference_keys(forms, ep, calc$spec), function(k) forms$known_differences_methods[[k]], character(1))
    w <- writeup_text(forms$forms[[ep]], calc$spec, calc$result, fields, values, known_methods = known)
    expect_match(w[["short"]], "Bayes factor design analysis", fixed = TRUE, info = ep)
    expect_match(w[["short"]], "BF10 ≥ 10", fixed = TRUE, info = ep)
    expect_no_match(w[["short"]], "α", fixed = TRUE, info = ep)
    expect_no_match(w[["ethics"]], "NA", fixed = TRUE, info = ep)
    expect_match(w[["ethics"]], "strong evidence", fixed = TRUE, info = ep)
  }
  # With uncertainty about the effect, Departure 15 (the default) doesn't apply.
  values <- modifyList(form_examples$E1, list(method = "bayes_factor", evidence_threshold = "10", prior_scale = "0.707", effect_sd = "0.1", alpha = NULL))
  spec <- build_spec(forms, "E1", form_fields(form_groups(forms, "E1")), values)
  expect_false("15" %in% names(departures_for(forms, "E1", spec)))
  # Other test versions keep alpha and have no Known difference 6.
  spec <- build_spec(forms, "E2", form_fields(form_groups(forms, "E2")), form_examples$E2)
  expect_false("6" %in% known_difference_keys(forms, "E2", spec))
  expect_false("15" %in% names(departures_for(forms, "E2", spec)))
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

test_that("two dependent correlations run on pwrss's unpooled Steiger test, with Departure 12, for either kind", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E51"))
  spec <- build_spec(forms, "E51", fields, form_examples$E51)
  expect_identical(spec$template, "overlapping_correlations")
  expect_identical(spec$variables$Z$type, "continuous")
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.z.twocors.steiger")
  html <- as.character(result_panel_ui(tree, forms, "E51", fields, form_examples$E51, calc))
  expect_match(html, "Validated. ", fixed = TRUE)
  expect_match(html, "139 and 875", fixed = TRUE)                          # Departure 12
  # The G*Power manual's example without a shared variable (28.3.1): 886.
  values <- c(list(comparison = "nonoverlapping_correlations", X1_label = "Stress at 14", Y1_label = "Sleep at 14",
    X2_label = "Stress at 16", Y2_label = "Sleep at 16", r_X1_Y1 = "0.1", r_X2_Y2 = "0.2", r_X1_X2 = "0.5",
    r_X1_Y2 = "0.4", r_Y1_X2 = "-0.4", r_Y1_Y2 = "0.8", alternative = "greater"), closing_ok)
  spec <- build_spec(forms, "E51", fields, values)
  expect_null(spec$variables$Z)
  expect_equal(run_calculation(spec, run, seed = 1L)$result$n_required$n, 886)
})

test_that("equivalence tests run on TOSTER for each comparison, with their own wording", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E36"))
  values <- modifyList(form_examples$E36, list(just_source = "The smallest difference teachers would act on."))
  spec <- build_spec(forms, "E36", fields, values)
  expect_identical(spec$template, "tost_independent")
  expect_identical(spec$variables$X$type, "binary")
  expect_null(spec$target_test$alternative)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "TOSTER::power_t_TOST")
  # TOSTER's own answer: 69.2 per group, rounded up to 70 (test-backend-toster.R).
  expect_equal(calc$result$n_required$n, 140)
  s <- result_sentences(calc$spec, calc$result)
  expect_match(s[["headline"]], "(70 per group)", fixed = TRUE)
  expect_match(s[["headline"]], "inside the equivalence bounds", fixed = TRUE)
  expect_match(s[["headline"]], "d = \u00b10.5", fixed = TRUE)
  expect_match(s[["detail"]], "TOSTER's formula, TOSTER::power_t_TOST(), no simulation", fixed = TRUE)
  # The plain reading is about showing equivalence, and fewer succeed
  # nearer a bound (not with a smaller effect).
  expect_match(s[["reading"]], "would show that the difference lies inside the equivalence bounds", fixed = TRUE)
  expect_match(s[["reading"]], "closer to a bound, fewer would", fixed = TRUE)
  expect_no_match(s[["reading"]], "significant result", fixed = TRUE)
  html <- as.character(result_panel_ui(tree, forms, "E36", fields, values, calc))
  expect_match(html, "Validation in progress. ", fixed = TRUE)
  w <- writeup_text(forms$forms$E36, calc$spec, calc$result, fields, values)
  expect_match(w[["short"]], "an equivalence test (two one-sided tests, TOST) of two independent groups (each one-sided test at \u03b1 = .05)", fixed = TRUE)
  expect_match(w[["short"]], "equivalence bound (\u00b1) = 0.5", fixed = TRUE)
  expect_no_match(w[["short"]], "two-sided", fixed = TRUE)
  expect_match(w[["ethics"]], "too small to matter", fixed = TRUE)
  # The same people measured twice, in the outcome's own units: the bound
  # is divided by the SD of the differences, as the effect is.
  paired <- modifyList(values, list(comparison = "tost_paired", effect_units = "raw", raw_bound = "25",
    raw_mean_1 = "450", raw_mean_2 = "455", raw_sd_kind = "difference", raw_sd_difference = "60", goal = "power", n = "80"))
  spec <- build_spec(forms, "E36", fields, paired)
  expect_identical(spec$template, "tost_paired")
  expect_identical(spec$variables$X$type, "within_factor")
  expect_null(spec$options$allocation_ratio)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_equal(calc$result$curve$power, TOSTER::power_t_TOST(n = 80, delta = 5, sd = 60, eqb = c(-25, 25), alpha = 0.05, type = "paired")$power)
  s <- result_sentences(calc$spec, calc$result)
  expect_match(s[["headline"]], "\u00b125 in your outcome's units (d_z = \u00b10.417)", fixed = TRUE)
  expect_match(s[["detail"]], "The equivalence bound of 25 is 0.417 in the same units.", fixed = TRUE)
  # One mean against a fixed value: no grouping variable.
  one <- modifyList(values, list(comparison = "tost_one_sample", d = "0.1", bound = "0.4", goal = "power", n = "120"))
  spec <- build_spec(forms, "E36", fields, one)
  expect_null(spec$variables$X)
  expect_identical(spec$target_test$effect, "mean")
  expect_equal(run_calculation(spec, run, seed = 1L)$result$curve$power,
    TOSTER::power_t_TOST(n = 120, delta = 0.1, sd = 1, eqb = c(-0.4, 0.4), alpha = 0.05, type = "one.sample")$power)
  # A difference outside the bounds is refused in plain words.
  outside <- build_spec(forms, "E36", fields, modifyList(values, list(d = "0.6")))
  expect_match(run_calculation(outside, run, seed = 1L)$message, "has to lie inside the bounds", fixed = TRUE)
})

test_that("a planned contrast runs on pwrss, and refuses weights that don't add up to 0", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E19"))
  spec <- build_spec(forms, "E19", fields, form_examples$E19)
  expect_equal(unlist(spec$target_test$weights), c(-3, -1, 1, 3))
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.t.contrasts")
  expect_gt(calc$result$n_required$n, 0)
  html <- as.character(result_panel_ui(tree, forms, "E19", fields, form_examples$E19, calc))
  expect_match(html, "Validated. ", fixed = TRUE)
  # Weights that don't add up to 0 are refused in plain English.
  bad <- build_spec(forms, "E19", fields, modifyList(form_examples$E19, list(weights = "-1, 0, 0, 2")))
  expect_error(run(bad), "must add up to 0", fixed = TRUE)
})

test_that("Poisson regression runs on pwrss, with the exposure and a yes/no predictor", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E28"))
  calc <- run_calculation(build_spec(forms, "E28", fields, form_examples$E28), run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.z.poisson")
  n_one_year <- calc$result$n_required$n
  expect_gt(n_one_year, 0)
  html <- as.character(result_panel_ui(tree, forms, "E28", fields, form_examples$E28, calc))
  expect_match(html, "Validation in progress. ", fixed = TRUE)
  # Following people for longer means more events, so fewer people.
  values <- modifyList(form_examples$E28, list(mean_exposure = "2"))
  calc <- run_calculation(build_spec(forms, "E28", fields, values), run, seed = 1L)
  expect_lt(calc$result$n_required$n, n_one_year)
  values <- modifyList(form_examples$E28, list(X_type = "binary", X_label = "Condition", X_level1 = "Control",
    X_level2 = "Peer support", x_prob = "0.5"))
  spec <- build_spec(forms, "E28", fields, values)
  expect_identical(spec$variables$X$type, "binary")
  expect_identical(run_calculation(spec, run, seed = 1L)$result$provenance$backend_function, "pwrss::power.z.poisson")
})

test_that("a cluster-randomised trial runs on powertools, with the groups and the design effect", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E34"))
  spec <- build_spec(forms, "E34", fields, form_examples$E34)
  expect_identical(spec$template, "cluster_randomised")
  expect_identical(spec$population$cluster_size, 20)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "powertools::crt.parallel.cont")
  n <- calc$result$n_required$n
  expect_equal(n %% 40, 0)
  words <- result_sentences(calc$spec, calc$result)
  expect_match(words[["headline"]], sprintf("(%s groups of 20, %s groups in each condition)", n / 20, n / 40), fixed = TRUE)
  expect_match(words[["detail"]], "The design effect is 1.95", fixed = TRUE)
  expect_match(words[["detail"]], "intraclass correlation 0.05", fixed = TRUE)
  html <- as.character(result_panel_ui(tree, forms, "E34", fields, form_examples$E34, calc))
  expect_match(html, "Validation in progress. ", fixed = TRUE)
  values <- modifyList(form_examples$E34, list(just_source = "A pilot study."))
  w <- writeup_text(forms$forms$E34, calc$spec, calc$result, fields, values)
  expect_match(w[["short"]], "the design effect is 1.95", fixed = TRUE)
  # A total that isn't a whole number of groups is refused in plain words.
  bad <- build_spec(forms, "E34", fields, modifyList(form_examples$E34, list(goal = "power", n = "410")))
  expect_error(run(bad), "whole number of groups of 20", fixed = TRUE)
})

test_that("a yes/no outcome in groups runs on powertools' .bin() functions from the same screen", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E34"))
  values <- modifyList(form_examples$E34, list(outcome_type = "proportion", p1 = "0.3", p2 = "0.45", sigma_u_groups = "0.3"))
  values$d <- NULL; values$icc <- NULL
  spec <- build_spec(forms, "E34", fields, values)
  expect_identical(spec$population$metric, "proportion")
  expect_identical(spec$variables$Y$type, "binary")
  expect_identical(spec$target_test$method, "logistic_mixed")
  expect_null(spec$population$d)
  expect_null(spec$population$cluster_size_sd)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$status, "ok")
  expect_identical(calc$result$provenance$backend_function, "powertools::crt.parallel.bin")
  words <- result_sentences(calc$spec, calc$result)
  expect_match(words[["detail"]], "SD of 0.3 on the log-odds scale", fixed = TRUE)
  w <- writeup_text(forms$forms$E34, calc$spec, calc$result, fields, modifyList(values, list(just_source = "A pilot study.")))
  expect_match(w[["short"]], "analysed as yes/no", fixed = TRUE)
  # People randomised within groups: the effect's SD across groups.
  values_ms <- modifyList(values, list(assignment = "multisite", sigma_u_effect = "0.3"))
  values_ms$sigma_u_groups <- NULL
  spec_ms <- build_spec(forms, "E34", fields, values_ms)
  expect_identical(spec_ms$population$sigma_u, 0.3)
  expect_identical(run_calculation(spec_ms, run, seed = 1L)$result$provenance$backend_function, "powertools::multisite.bin")
})

test_that("a multisite trial runs on powertools from the same screen, with the effect's variation asked for", {
  skip_without_run()
  values <- modifyList(form_examples$E34, list(assignment = "multisite", icc = "0.1", icc_effect = "0.02"))
  fields <- form_fields(form_groups(forms, "E34"))
  spec <- build_spec(forms, "E34", fields, values)
  expect_identical(spec$template, "multisite")
  expect_identical(spec$target_test$method, "multisite_t")
  expect_identical(spec$population$icc_effect, 0.02)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "powertools::multisite.cont")
  n <- calc$result$n_required$n
  expect_equal(n %% 20, 0)
  words <- result_sentences(calc$spec, calc$result)
  expect_match(words[["headline"]], sprintf("(%s groups of 20, half of each group in each condition)", n / 20), fixed = TRUE)
  expect_match(words[["detail"]], "The design effect is 1.28", fixed = TRUE)
  w <- writeup_text(forms$forms$E34, calc$spec, calc$result, fields, modifyList(values, list(just_source = "A pilot study.")))
  expect_match(w[["short"]], "randomised within each group", fixed = TRUE)
  # The effect's variation is asked for only when people are randomised within groups.
  expect_null(build_spec(forms, "E34", fields, form_examples$E34)$population$icc_effect)
})

test_that("SEM model fit runs on semPower, for a CFA or a model given by its df, and says it is power to reject the model", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E37"))
  spec <- build_spec(forms, "E37", fields, form_examples$E37)
  expect_equal(spec$population$indicators, 12)
  expect_null(spec$population$df)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "semPower::semPower.postHoc")
  expect_equal(calc$result$sem$df, 51)
  words <- result_sentences(calc$spec, calc$result)
  expect_match(words[["headline"]], "to detect the misfit you entered, with the chi-square test of exact model fit", fixed = TRUE)
  expect_match(words[["detail"]], "a CFA of 12 items on 3 correlated factors (51 degrees of freedom)", fixed = TRUE)
  expect_match(words[["detail"]], "A model that is not rejected is not shown to be right", fixed = TRUE)
  expect_no_match(paste(words, collapse = " "), "two-sided|the effect you entered")
  w <- writeup_text(forms$forms$E37, calc$spec, calc$result, fields, modifyList(form_examples$E37, list(just_source = "The smallest misfit worth detecting.")))
  expect_match(w[["short"]], "a population RMSEA of 0.05", fixed = TRUE)
  expect_match(w[["ethics"]], "If our model is wrong by the amount we set", fixed = TRUE)
  # Another model, given by its degrees of freedom.
  values <- modifyList(form_examples$E37, list(model_kind = "df", df = "24"))
  spec <- build_spec(forms, "E37", fields, values)
  expect_equal(spec$population$df, 24)
  expect_null(spec$population$indicators)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_match(result_sentences(calc$spec, calc$result)[["detail"]], "a model with 24 degrees of freedom", fixed = TRUE)
})

test_that("E37's other questions run on semPower's own functions, each with its test and model in words", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E37"))
  expected <- list(
    invariance = c("semPower::semPower.powerMI", "metric invariance (equal loadings in the two groups", "2 of them loading 0.5 in the second group"),
    scalar = c("semPower::semPower.powerMI", "scalar invariance (equal intercepts", "having intercepts higher by 0.3 item SDs"),
    factor_correlation = c("semPower::semPower.powerCFA", "the correlation between the two factors against zero", "two factors measured by 4 items and 5 items"),
    latent_regression = c("semPower::semPower.powerRegression", "predictor 1's latent slope against zero", "2 latent predictors (standardised slopes 0.2, 0.3; the predictors correlating 0.3)")
  )
  for (name in names(expected)) {
    values <- sem_examples[[name]]
    expect_length(form_problems(fields, values), 0)
    spec <- build_spec(forms, "E37", fields, values)
    calc <- run_calculation(spec, run, seed = 1L)
    expect_identical(calc$result$provenance$backend_function, expected[[name]][1], label = name)
    words <- result_sentences(calc$spec, calc$result)
    expect_match(words[["headline"]], expected[[name]][2], fixed = TRUE, label = name)
    expect_match(words[["detail"]], expected[[name]][3], fixed = TRUE, label = name)
    expect_no_match(paste(words, collapse = " "), "misfit|two-sided", label = name)
    w <- writeup_text(forms$forms$E37, calc$spec, calc$result, fields, modifyList(values, list(just_source = "The smallest difference worth detecting.")))
    expect_match(w[["short"]], expected[[name]][2], fixed = TRUE, label = name)
    expect_match(w[["short"]], expected[[name]][3], fixed = TRUE, label = name)
  }
  # Unequal groups for invariance: whole groups in the ratio given.
  spec <- build_spec(forms, "E37", fields, sem_examples$scalar)
  expect_equal(spec$options$allocation_ratio, 1.5)
  calc <- run_calculation(spec, run, seed = 1L)
  n <- calc$result$n_required$n
  expect_equal(n %% 5, 0)
  expect_match(result_sentences(calc$spec, calc$result)[["headline"]], sprintf("(%s in group 1 and %s in group 2)", n * 2 / 5, n * 3 / 5), fixed = TRUE)
})

test_that("logistic regression runs on pwrss, with Known difference 3 only when other predictors overlap", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E27"))
  calc <- run_calculation(build_spec(forms, "E27", fields, form_examples$E27), run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.z.logistic")
  expect_gt(calc$result$n_required$n, 0)
  expect_length(known_difference_keys(forms, "E27", calc$spec), 0)
  html <- as.character(result_panel_ui(tree, forms, "E27", fields, form_examples$E27, calc))
  expect_match(html, "Validated. ", fixed = TRUE)
  expect_no_match(html, "395 against 375", fixed = TRUE)
  # With R-squared above 0, the result screen and the write-up say so.
  values <- modifyList(form_examples$E27, list(r2_other = "0.1", just_source = "A pilot study."))
  calc <- run_calculation(build_spec(forms, "E27", fields, values), run, seed = 1L)
  expect_identical(known_difference_keys(forms, "E27", calc$spec), "3")
  html <- as.character(result_panel_ui(tree, forms, "E27", fields, values, calc))
  expect_match(html, "395 against 375", fixed = TRUE)
  w <- writeup_text(forms$forms$E27, calc$spec, calc$result, fields, values,
    known_methods = forms$known_differences_methods[["3"]])
  expect_match(w[["short"]], "not yet been resolved", fixed = TRUE)
  # A yes/no predictor names its groups and gives the split.
  values <- modifyList(form_examples$E27, list(X_type = "binary", X_label = "Condition", X_level1 = "Control",
    X_level2 = "Reminder", x_prob = "0.5"))
  spec <- build_spec(forms, "E27", fields, values)
  expect_identical(spec$variables$X$type, "binary")
  expect_equal(spec$population$x_prob, 0.5)
  expect_identical(run_calculation(spec, run, seed = 1L)$result$provenance$backend_function, "pwrss::power.z.logistic")
})

test_that("the variance tests run on Spower, with Known difference 4", {
  skip_without_run()
  for (ep in c("E52", "E53")) {
    calc <- run_calculation(light_spec(ep), run, seed = 1L)
    expect_match(calc$result$provenance$backend_function, "Spower::p_var.test(", fixed = TRUE, label = ep)
    fields <- form_fields(form_groups(forms, ep))
    html <- as.character(result_panel_ui(tree, forms, ep, fields, form_examples[[ep]], calc))
    expect_match(html, "Validated. ", fixed = TRUE, label = ep)
    expect_match(html, "G*Power computes them exactly", fixed = TRUE, label = ep)
  }
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

test_that("E9: the smallest detectable interaction, labelled as the fixed-model formula", {
  fields <- form_fields(form_groups(forms, "E9"))
  goal <- Filter(function(f) identical(f$id, "goal"), fields)[[1]]
  expect_true("sensitivity" %in% names(goal$choices))
  expect_false("sensitivity_curve" %in% names(goal$choices))
  values <- modifyList(form_examples[["E9"]], list(goal = "sensitivity", n = "300", power = "0.8"))
  expect_length(form_problems(fields, values), 0)
  calc <- run_calculation(build_spec(forms, "E9", fields, values), seed = forms$default_seed)
  expect_equal(calc$status, "ok")
  expect_true(calc$result$sensitivity$approximation)
  html <- as.character(result_panel_ui(tree, forms, "E9", fields, values, calc))
  expect_match(html, "is the correlation of the interaction with Y = 0.1", fixed = TRUE)
  expect_match(html, "fixed-model formula (InteractionPoweR::power_interaction_r2(), no simulation)", fixed = TRUE)
  expect_match(html, "comes from InteractionPoweR&#39;s fixed-model formula|comes from InteractionPoweR's fixed-model formula")
  expect_match(html, "The smallest detectable effect was found with a fixed-model formula", fixed = TRUE)
})

# "Does this still apply?" (the new design, 18 October 2026) -----------------

test_that("changing the effect size after writing the reasoning flags it, without wiping it", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- modifyList(form_examples[["E2"]], list(just_source = "Smallest difference our clinic would act on."))
  # No reasoning: nothing to flag or remember.
  expect_null(source_check(NULL, "E2", fields, modifyList(values, list(just_source = "")))$record)
  first <- source_check(NULL, "E2", fields, values)
  expect_false(first$stale)
  expect_identical(first$record$effect[["d"]], "0.4")
  expect_false(source_check(first$record, "E2", fields, values)$stale)
  changed <- source_check(first$record, "E2", fields, modifyList(values, list(d = "0.6")))
  expect_true(changed$stale)
  expect_identical(changed$was, "Cohen's d = 0.4")
  expect_identical(changed$record, first$record) # still the values the reasoning was written for
  # Editing the reasoning, or another design, starts afresh.
  expect_false(source_check(first$record, "E2", fields, modifyList(values, list(d = "0.6", just_source = "New pilot data.")))$stale)
  expect_false(source_check(first$record, "E1", fields, modifyList(values, list(d = "0.6")))$stale)

  # The result screen keeps the reasoning, asks, and holds saving and the write-up.
  stale <- modifyList(values, list(d = "0.6", method = "student_t", source_stale = TRUE, source_was = "Cohen's d = 0.4"))
  calc <- run_calculation(build_spec(forms, "E2", fields, stale), seed = forms$default_seed)
  html <- as.character(result_panel_ui(tree, forms, "E2", fields, stale, calc))
  expect_match(html, "Does your reasoning still apply?", fixed = TRUE)
  expect_match(html, "(it was Cohen's d = 0.4; it is now Cohen's d = 0.6)", fixed = TRUE)
  expect_match(html, "Smallest difference our clinic would act on.", fixed = TRUE)
  expect_match(html, "source_still_applies", fixed = TRUE)
  expect_no_match(html, "download_script|download_project|writeup_short")
  expect_no_match(html, "export-needs-reasoning", fixed = TRUE)
  html <- as.character(result_panel_ui(tree, forms, "E2", fields, modifyList(stale, list(source_stale = FALSE)), calc))
  expect_no_match(html, "Does your reasoning still apply?", fixed = TRUE)
  expect_match(html, "writeup_short", fixed = TRUE)
})

test_that("guess first: the guess is shown next to the answer and goes nowhere else", {
  fields <- form_fields(form_groups(forms, "E2"))
  expect_true("guess" %in% vapply(fields, `[[`, "", "id"))
  values <- modifyList(form_examples[["E2"]], list(guess = "60"))
  expect_length(form_problems(fields, values), 0)
  spec <- build_spec(forms, "E2", fields, values)
  expect_identical(spec, build_spec(forms, "E2", fields, form_examples[["E2"]]))
  calc <- run_calculation(spec, seed = forms$default_seed)
  n <- calc$result$n_required$n
  html <- as.character(result_panel_ui(tree, forms, "E2", fields, values, calc))
  expect_match(html, sprintf("Your guess: 60 participants. The answer: %s", whole(n)), fixed = TRUE)
  expect_no_match(paste(writeup_text(forms$forms[["E2"]], calc$spec, calc$result, fields, values), collapse = " "), "guess", fixed = TRUE)
  # No guess, no line.
  expect_no_match(as.character(result_panel_ui(tree, forms, "E2", fields, form_examples[["E2"]], calc)), "Your guess", fixed = TRUE)
  # Power: a guess above 1 is a percentage.
  expect_equal(guess_line(list(guess = "80"), list(goal_type = "power", curve = data.frame(power = 0.34))), "Your guess: 80% power. The answer: 34%.")
  expect_equal(guess_line(list(guess = "0.8"), list(goal_type = "power", curve = data.frame(power = 0.34))), "Your guess: 80% power. The answer: 34%.")
  expect_equal(guess_gap(100, 394), "3.9 times your guess")
  expect_equal(guess_gap(100, 105), "close to your guess")
  expect_equal(guess_gap(100, 130), "30% more than your guess")
  expect_equal(guess_gap(100, 40), "60% fewer than your guess")
})

test_that("the generic tests give power or the noncentrality needed, with no sample size", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E50"))
  calc <- run_calculation(build_spec(forms, "E50", fields, form_examples$E50), run, seed = 1L)
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.t.test")
  lines <- result_sentences(calc$spec, calc$result)
  expect_match(lines[["headline"]], "With a noncentrality parameter of 2.5, a t test with 30 degrees of freedom (two-sided)", fixed = TRUE)
  expect_no_match(lines[["headline"]], "participants", fixed = TRUE)
  w <- writeup_text(forms$forms$E50, calc$spec, calc$result, fields, form_examples$E50)
  expect_match(w[["short"]], "a generic t test with 30 degrees of freedom (two-sided, α = .05), from a noncentrality parameter", fixed = TRUE)
  expect_true(is.na(w[["ethics"]])) # no participants to describe
  v <- modifyList(form_examples$E50, list(goal = "sensitivity", generic_test = "f", ncp = "", df1 = "2", df2 = "40"))
  calc <- run_calculation(build_spec(forms, "E50", fields, v), run, seed = 1L)
  expect_match(result_sentences(calc$spec, calc$result)[["headline"]], "For 80% power with an F test with 2 and 40 degrees of freedom at alpha = .05, the noncentrality parameter needs to be at least", fixed = TRUE)
  # pwrss's search goes wrong for a t test with 3 degrees of freedom; the
  # engine refuses its answer.
  v <- modifyList(form_examples$E50, list(goal = "sensitivity", ncp = "", df = "3"))
  calc <- run_calculation(build_spec(forms, "E50", fields, v), run, seed = 1L)
  expect_identical(calc$status, "error")
  expect_match(calc$message, "couldn't find the noncentrality", fixed = TRUE)
})

# The plain-words version for an ethics application (19 October 2026) --------

test_that("the write-up has a plain-words version for an ethics application, for each goal", {
  fields <- form_fields(form_groups(forms, "E2"))
  values <- modifyList(form_examples[["E2"]], list(just_source = "Smallest difference our clinic would act on.", attrition = "0.1"))
  calc <- run_calculation(build_spec(forms, "E2", fields, values), seed = forms$default_seed)
  e <- writeup_text(forms$forms$E2, calc$spec, calc$result, fields, values)[["ethics"]]
  n <- calc$result$n_required$n
  expect_match(e, sprintf("We plan to include %s participants in the analysis", whole(n)), fixed = TRUE)
  expect_match(e, sprintf("we will recruit %s", whole(calc$result$recruitment$n_recruit)), fixed = TRUE)
  expect_match(e, "This number comes from a power analysis.", fixed = TRUE)
  expect_match(e, "Cohen's d = 0.4, based on the smallest effect that would matter", fixed = TRUE)
  expect_match(e, "is 80%, and the chance that it misses it is 20%", fixed = TRUE)
  expect_match(e, "using a 5% threshold", fixed = TRUE)
  expect_no_match(e, "ethical", fixed = TRUE) # it describes the plan; no verdict
  html <- as.character(result_panel_ui(tree, forms, "E2", fields, values, calc))
  expect_match(html, "Plain-words version (for an ethics application)", fixed = TRUE)
  expect_match(html, "writeup_ethics", fixed = TRUE)

  # A fixed sample size: says so, and gives the chance of missing the effect.
  fixed <- modifyList(values, list(goal = "power", n = "60", situation = "fixed", attrition = ""))
  calc <- run_calculation(build_spec(forms, "E2", fields, fixed), seed = forms$default_seed)
  e <- writeup_text(forms$forms$E2, calc$spec, calc$result, fields, fixed)[["ethics"]]
  expect_match(e, "set by the resources available, not chosen by a power analysis", fixed = TRUE)
  p <- calc$result$curve$power[1]
  expect_match(e, sprintf("is %s, and the chance that it misses it is %s", percent(p), percent(1 - p)), fixed = TRUE)

  # The smallest detectable effect.
  sens <- modifyList(values, list(method = "student_t", goal = "sensitivity", n = "128", power = "0.8", d = "", attrition = ""))
  calc <- run_calculation(build_spec(forms, "E2", fields, sens), seed = forms$default_seed)
  e <- writeup_text(forms$forms$E2, calc$spec, calc$result, fields, sens)[["ethics"]]
  expect_match(e, sprintf("would find 80%% of the time (using a 5%% threshold for statistical significance) is %s, measured as Cohen's d",
    format(round(calc$result$sensitivity$effect, 3), nsmall = 2)), fixed = TRUE)
  expect_match(e, "Our reasoning about the size of the effect:", fixed = TRUE)

  # No reasoning, no write-up and no ethics version.
  expect_null(writeup_text(forms$forms$E2, calc$spec, calc$result, fields, modifyList(sens, list(just_source = ""))))
})

# Sharing the server: a limit on background calculations --------------------

test_that("at most background_limit() background calculations run at once, across all visitors", {
  withr::local_envvar(POWERKIT_BACKGROUND_LIMIT = "")
  expect_identical(background_limit(forms), 2L)
  expect_identical(background_limit(list()), 2L)
  withr::local_envvar(POWERKIT_BACKGROUND_LIMIT = "5")
  expect_identical(background_limit(forms), 5L)
  withr::local_envvar(POWERKIT_BACKGROUND_LIMIT = "none")
  expect_identical(background_limit(forms), 2L)

  old <- background_registry$processes
  on.exit(background_registry$processes <- old, add = TRUE)
  background_registry$processes <- list()
  fake <- function(alive) { state <- alive; list(is_alive = function() state, finish = function() state <<- FALSE) }
  a <- register_background(fake(TRUE)); b <- register_background(fake(TRUE))
  expect_identical(background_running(), 2L)
  # A finished run frees its place, and is dropped from the registry.
  a$finish()
  expect_identical(background_running(), 1L)
  expect_length(background_registry$processes, 1)
})

test_that("the app checks the limit before starting any background run, and says so plainly", {
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, "if (background_running() >= background_limit(forms)) {", fixed = TRUE)
  expect_match(code, "register_background(start_background_calculation(", fixed = TRUE)
  # start_background_calculation() is only called through start_job().
  expect_length(regmatches(code, gregexpr("start_background_calculation(", code, fixed = TRUE))[[1]], 1)
  html <- as.character(busy_ui())
  expect_match(html, "powerkit is busy just now", fixed = TRUE)
  expect_match(html, "in a minute or two", fixed = TRUE)
  expect_false(grepl("Error|error|stack", html))
})

test_that("safeguard power: the form asks for the earlier study's size, and the result and write-up say what was used", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E2"))
  expect_true("sg_use" %in% vapply(fields, `[[`, "", "id"))
  expect_false("sg_use" %in% vapply(form_fields(form_groups(forms, "E5")), `[[`, "", "id"))
  use <- Filter(function(f) identical(f$id, "sg_use"), fields)[[1]]
  expect_false(field_applies(use, modifyList(form_examples$E2, list(just_type = "smallest_effect_of_interest"))))
  values <- modifyList(form_examples$E2, list(just_type = "pilot_study", just_source = "Our pilot", sg_use = "yes",
    sg_n1 = 20, sg_n2 = 20, sg_protection = 0.8, goal = "power", n = 48))
  expect_true(field_applies(use, values))
  spec <- build_spec(forms, "E2", fields, values)
  expect_equal(spec$effect_justification$safeguard$n1, 20)
  calc <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_lt(calc$result$safeguard$lower, calc$result$safeguard$estimate)
  html <- as.character(result_panel_ui(tree, forms, "E2", fields, values, calc))
  expect_match(html, "Safeguard power: the earlier study's estimate", fixed = TRUE)
  expect_match(html, "60% confidence interval", fixed = TRUE)
  text <- writeup_text(forms$forms$E2, spec, calc$result, fields, values)
  expect_match(paste(text, collapse = " "), "safeguard power approach (Perugini, Gallucci & Costantini, 2014)", fixed = TRUE)
  # Without "yes" nothing about the safeguard reaches the spec.
  plain <- build_spec(forms, "E2", fields, modifyList(values, list(sg_use = "no")))
  expect_null(plain$effect_justification$safeguard)
})

test_that("effect-size conversion: the form offers each card's forms, and the engine converts with effectsize", {
  # The app offers the forms the engine converts from.
  for (template in names(conversion_choices)) {
    expect_setequal(conversion_choices[[template]], powerkit:::conversion_templates[[template]]$from)
  }
  fields <- form_fields(form_groups(forms, "E2"))
  ids <- vapply(fields, `[[`, "", "id")
  expect_identical(ids[match("d", ids) + 1], "conv_from")
  expect_false("conv_from" %in% vapply(form_fields(form_groups(forms, "E5")), `[[`, "", "id"))
  by_id <- function(id) Filter(function(f) identical(f$id, id), fields)[[1]]
  values <- modifyList(form_examples$E2, list(goal = "power", n = 64, conv_from = "t", conv_value = 2.5, conv_df = 58,
    just_type = "meta_analysis", just_source = "A published trial"))
  # Cohen's d gives way to the published value and its df.
  expect_false(field_applies(by_id("d"), values))
  expect_true(field_applies(by_id("conv_df"), values))
  expect_false(field_applies(by_id("conv_df"), modifyList(values, list(conv_from = "odds_ratio"))))
  # Not for the smallest detectable effect, nor with the measure's own units.
  expect_false(field_applies(by_id("conv_from"), modifyList(values, list(goal = "sensitivity"))))
  expect_false(field_applies(by_id("conv_from"), modifyList(values, list(effect_units = "raw"))))
  spec <- build_spec(forms, "E2", fields, values)
  expect_null(spec$population$d)
  expect_identical(spec$effect_justification$conversion$from, "t")
  skip_without_run()
  calc <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_equal(calc$result$effect_conversion$converted, effectsize::t_to_d(2.5, 58)[[1]])
  html <- as.character(result_panel_ui(tree, forms, "E2", fields, values, calc))
  expect_match(html, "Effect size converted: the published t statistic of 2.5 (error df 58) gives Cohen's d = 0.657, with the effectsize package's t_to_d()", fixed = TRUE)
  text <- paste(writeup_text(forms$forms$E2, spec, calc$result, fields, values), collapse = " ")
  expect_match(text, "converted from the published t statistic of 2.5 (error df 58) with the effectsize package's t_to_d()", fixed = TRUE)
  # "No" leaves the card as it was.
  plain <- build_spec(forms, "E2", fields, modifyList(values, list(conv_from = "none", d = "0.4")))
  expect_null(plain$effect_justification$conversion)
  expect_equal(plain$population$d, 0.4)
})

test_that("between-participants ANOVA by its effect size: partial eta-squared, or converted from F, goes to pwrss", {
  for (ep in c("E7", "E18", "E21")) {
    fields <- form_fields(form_groups(forms, ep))
    ids <- vapply(fields, `[[`, "", "id")
    expect_identical(ids[match("metric", ids) + 1], "eta_squared", label = ep)
    by_id <- function(id) Filter(function(f) identical(f$id, id), fields)[[1]]
    expect_true("eta_squared" %in% names(by_id("metric")$choices), label = ep)
    # The means give way to the effect size.
    effect_values <- list(metric = "eta_squared", goal = "power")
    for (id in intersect(c("means", "m11", "sd", "sd_mode"), ids)) {
      expect_false(field_applies(by_id(id), effect_values), label = paste(ep, id))
    }
    expect_true(field_applies(by_id("eta_squared"), effect_values), label = ep)
    expect_true(field_applies(by_id("conv_df1"), c(effect_values, list(conv_from = "F"))), label = ep)
  }
  fields <- form_fields(form_groups(forms, "E18"))
  values <- modifyList(form_examples$E18, list(metric = "eta_squared", eta_squared = "0.06", test_version = "anova_f",
    goal = "sample_size", power = "0.8"))
  spec <- build_spec(forms, "E18", fields, values)
  expect_null(spec$population$means)
  expect_equal(spec$population$eta_squared, 0.06)
  skip_without_run()
  calc <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.f.ancova")
  text <- paste(writeup_text(forms$forms$E18, spec, calc$result, fields, values), collapse = " ")
  expect_match(text, "The effect size, partial eta-squared = 0.06", fixed = TRUE)
  expect_match(text, "pwrss::power.f.ancova()", fixed = TRUE)
  # A published F(2, 114) for the factorial card's interaction.
  fields <- form_fields(form_groups(forms, "E21"))
  values <- modifyList(form_examples$E21, list(metric = "eta_squared", effect = "interaction", conv_from = "F",
    conv_value = "4.2", conv_df1 = "2", conv_df = "114", goal = "power", n = "120", just_type = "meta_analysis"))
  calc <- run_calculation(build_spec(forms, "E21", fields, values), run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_equal(calc$result$effect_conversion$converted, effectsize::F_to_eta2(4.2, 2, 114)[[1]])
})

test_that("repeated-measures and mixed ANOVA by effect size: the screen asks which kind of partial eta-squared", {
  for (ep in c("E54", "E8", "E55")) {
    fields <- form_fields(form_groups(forms, ep))
    ids <- vapply(fields, `[[`, "", "id")
    by_id <- function(id) Filter(function(f) identical(f$id, id), fields)[[1]]
    expect_identical(ids[match("metric", ids) + 1:2], c("eta_source", "eta_squared"), label = ep)
    source <- by_id("eta_source")
    expect_true(isTRUE(source$required), label = ep)
    expect_null(source$default, label = ep)
    effect <- list(metric = "eta_squared", goal = "power")
    expect_false(field_applies(by_id("eta_r"), c(effect, list(eta_source = "published"))), label = ep)
    expect_true(field_applies(by_id("eta_r"), c(effect, list(eta_source = "planned"))), label = ep)
    # A published F only for the published kind.
    expect_false(field_applies(by_id("conv_from"), c(effect, list(eta_source = "planned"))), label = ep)
    expect_true(field_applies(by_id("conv_from"), c(effect, list(eta_source = "published"))), label = ep)
  }
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E8"))
  values <- modifyList(form_examples$E8, list(metric = "eta_squared", eta_source = "planned", eta_squared = "0.022", eta_r = "0.5",
    effect = "interaction", goal = "power", n = "90"))
  calc <- run_calculation(build_spec(forms, "E8", fields, values), run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.f.mixed.anova")
})

test_that("moderation by its R-squared change: pwrss's fixed-model test, with its own known difference", {
  fields <- form_fields(form_groups(forms, "E9"))
  by_id <- function(id) Filter(function(f) identical(f$id, id), fields)[[1]]
  r2 <- list(interaction_metric = "r2_change", goal = "power")
  for (id in c("r_X_Y", "r_XW_Y", "rel_X")) expect_false(field_applies(by_id(id), r2), label = id)
  expect_true(field_applies(by_id("r2_change"), r2))
  values <- modifyList(form_examples$E9, list(interaction_metric = "r2_change", r2_change = "0.0225", r2_main = "0.0667",
    rel_X = NULL, rel_W = NULL, goal = "power", n = "200"))
  spec <- build_spec(forms, "E9", fields, values)
  expect_identical(spec$population$metric, "r2_change")
  expect_null(spec$population$r_XW_Y)
  expect_null(spec$variables$X$reliability)
  # Known difference 7 on this route, 1 (the simulation's) on the correlations.
  expect_identical(known_difference_keys(forms, "E9", spec), "7")
  expect_identical(known_difference_keys(forms, "E9", build_spec(forms, "E9", fields, form_examples$E9)), "1")
  skip_without_run()
  calc <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_identical(calc$result$provenance$backend_function, "pwrss::power.f.regression")
})

test_that("three effects side by side: conservative, the plan's and optimistic", {
  spec <- light_spec("E2", goal = list(type = "sample_size", power = 0.8))
  spec$target_test$method <- "student_t"
  spec$options$nrep <- NULL
  calc <- run_calculation(spec, seed = forms$default_seed)
  html <- as.character(scenarios_ui(calc$spec, calc$result))
  expect_match(html, "How much does the answer depend on the effect?", fixed = TRUE)
  expect_match(html, "powerkit won&#39;t suggest them|powerkit won't suggest them")
  # Only the values given are drawn; the plan's effect always is.
  n <- scenario_n(calc$spec, calc$result, conservative = 0.3, seed = forms$default_seed)
  expect_named(n, c("conservative", "expected"))
  expect_equal(n[["expected"]], calc$result$n_required$n)
  expect_equal(n[["conservative"]], 2 * ceiling(pwr::pwr.t.test(d = 0.3, power = 0.8)$n))
  n <- scenario_n(calc$spec, calc$result, 0.3, 0.6, seed = forms$default_seed)
  df <- scenario_curves(calc$spec, calc$result, 0.3, 0.6, n = n, seed = forms$default_seed)
  expect_setequal(unique(df$scenario), c("conservative", "expected", "optimistic"))
  expect_false(anyNA(df$power))
  # Wide enough for the conservative effect to reach the target power.
  expect_gte(max(df$power[df$scenario == "conservative"]), 0.8)
  # The larger effect has more power at every N.
  expect_true(all(df$power[df$scenario == "optimistic"] >= df$power[df$scenario == "conservative"]))
  expect_match(scenario_sentence(calc$spec, n), "For 80% power, conservative needs", fixed = TRUE)
  # Not offered for the smallest detectable effect, or where explore isn't.
  sens <- light_spec("E2", goal = list(type = "sensitivity", n = 100L, power = 0.8))
  sens$target_test$method <- "student_t"
  expect_null(scenarios_ui(sens))
  expect_null(scenarios_ui(light_spec("E7")))
})

test_that("the t-tests take the effect in the measure's own units, and the engine works out d", {
  units <- list(
    E1 = list(effect_units = "raw", raw_mean = "4.5", raw_test_value = "4", raw_sd = "1.25"),
    E2 = list(effect_units = "raw", raw_mean_1 = "3.8", raw_mean_2 = "4.5", raw_sd = "1.2", method = "student_t"),
    E3 = list(effect_units = "raw", raw_mean_1 = "10", raw_mean_2 = "12", raw_sd_kind = "each", raw_sd = "5", raw_r = "0.5")
  )
  expected <- c(E1 = 0.4, E2 = 0.7 / 1.2, E3 = 0.4)
  for (ep in names(units)) {
    values <- modifyList(form_examples[[ep]], units[[ep]])
    fields <- form_fields(form_groups(forms, ep))
    expect_length(form_problems(fields, values), 0)
    spec <- build_spec(forms, ep, fields, values)
    expect_equal(spec$population$metric, "raw", info = ep)
    expect_null(spec$population$d, info = ep)
    spec$goal <- list(type = "power", n = 60L)
    calc <- run_calculation(spec, seed = forms$default_seed)
    expect_equal(calc$status, "ok", info = ep)
    expect_equal(calc$result$effect_from_units$value, expected[[ep]], info = ep)
    expect_match(result_sentences(calc$spec, calc$result)[["detail"]], "From the means and SD you entered, powerkit worked out", fixed = TRUE)
    w <- writeup_text(forms$forms[[ep]], calc$spec, calc$result, fields,
      modifyList(values, list(just_source = "Smallest difference that matters.")))
    expect_match(w[["short"]], sprintf("= %s)", format(round(expected[[ep]], 3), nsmall = 2)), fixed = TRUE, info = ep)
    expect_match(w[["short"]], "SD = ", fixed = TRUE, info = ep)
  }
  # The paired test: the SD of the differences instead of one SD and r.
  values <- modifyList(form_examples$E3, list(effect_units = "raw", raw_mean_1 = "10", raw_mean_2 = "12",
    raw_sd_kind = "difference", raw_sd_difference = "5"))
  spec <- build_spec(forms, "E3", form_fields(form_groups(forms, "E3")), values)
  expect_equal(spec$population$raw, list(mean_1 = 10, mean_2 = 12, sd_difference = 5))
  # The explore panel works in standardised units, starting from that d.
  spec <- light_spec("E2")
  spec$target_test$method <- "student_t"
  spec$population <- list(metric = "raw", raw = list(mean_1 = 3.8, mean_2 = 4.5, sd = 1.2))
  calc <- run_calculation(spec, seed = forms$default_seed)
  expect_match(as.character(explore_ui(calc$spec, calc$result)), "value=\"0.58\"|data-from=\"0.58\"")
  expect_false(anyNA(explore_curve(calc$spec, calc$result, 0.3, seed = forms$default_seed)$power))
})

test_that("the smallest detectable effect is also given in the measure's own units", {
  spec <- light_spec("E2", goal = list(type = "sensitivity", n = 100L, power = 0.8))
  spec$target_test$method <- "student_t"
  spec$options$nrep <- NULL
  spec$population <- list(metric = "raw", raw = list(mean_1 = 0, mean_2 = 0, sd = 1.2))
  calc <- run_calculation(spec, seed = forms$default_seed)
  expect_match(result_sentences(calc$spec, calc$result)[["detail"]], "In your outcome's own units, that is a difference of", fixed = TRUE)
})

test_that("the plain reading of power never rounds a target up to every study", {
  expect_match(plain_reading(0.9), "about 9 in 10 studies", fixed = TRUE)
  expect_match(plain_reading(0.8), "about 8 in 10 studies", fixed = TRUE)
  expect_match(plain_reading(0.95), "about 95 in 100 studies", fixed = TRUE)
  expect_match(plain_reading(0.85), "about 85 in 100 studies", fixed = TRUE)
  expect_match(plain_reading(0.999), "about 99 in 100 studies", fixed = TRUE)
})

test_that("every folded departure exists, and folding never hides one that changes the answer", {
  folded <- unlist(forms$departures_folded)
  expect_true(all(folded %in% names(forms$departures)))
  # Departures 1, 5, 6, 7, 10, 12 and 13 change the number a user would compare.
  expect_false(any(c("1", "5", "6", "7", "10", "12", "13") %in% folded))
})

test_that("a group treatment trial (only condition 2 in groups) runs on powertools' irgtt functions from the same screen", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E34"))
  values <- modifyList(form_examples$E34, list(assignment = "group_treatment", cluster_size_grouped = "8"))
  values$cluster_size <- NULL; values$cluster_size_sd <- NULL
  spec <- build_spec(forms, "E34", fields, values)
  expect_identical(spec$template, "group_treatment")
  expect_identical(spec$target_test$method, "cluster_t")
  expect_null(spec$population$cluster_size_sd)
  calc <- run_calculation(spec, run, seed = 1L)
  expect_identical(calc$status, "ok")
  expect_identical(calc$result$provenance$backend_function, "powertools::irgtt.cont")
  words <- result_sentences(calc$spec, calc$result)
  expect_match(words[["detail"]], "Only the condition delivered in groups is clustered", fixed = TRUE)
  w <- writeup_text(forms$forms$E34, calc$spec, calc$result, fields, modifyList(values, list(just_source = "A pilot study.")))
  expect_match(w[["short"]], "randomised individually", fixed = TRUE)
  # A yes/no outcome: the test of the difference in proportions, with the ICC.
  values_bin <- modifyList(values, list(outcome_type = "proportion", p1 = "0.3", p2 = "0.45", icc_grouped = "0.05"))
  values_bin$d <- NULL; values_bin$icc <- NULL
  spec_bin <- build_spec(forms, "E34", fields, values_bin)
  expect_identical(spec_bin$target_test$effect, "proportion_difference")
  expect_identical(spec_bin$target_test$method, "z_test")
  expect_identical(spec_bin$population$icc, 0.05)
  calc_bin <- run_calculation(spec_bin, run, seed = 1L)
  expect_identical(calc_bin$status, "ok")
  expect_identical(calc_bin$result$provenance$backend_function, "powertools::irgtt.bin")
})

test_that("departure 14 shows only for a group treatment trial's smallest detectable d", {
  base <- list(design = "cluster_trial", template = "group_treatment", population = list(metric = "standardised"),
               target_test = list(method = "cluster_t"), goal = list(type = "sensitivity"))
  expect_true(any(grepl("0.352", departures_for(forms, "E34", base), fixed = TRUE)))
  expect_length(departures_for(forms, "E34", modifyList(base, list(goal = list(type = "sample_size")))), 0)
  expect_length(departures_for(forms, "E34", modifyList(base, list(template = "multisite"))), 0)
  expect_length(departures_for(forms, "E34", modifyList(base, list(population = list(metric = "proportion")))), 0)
})

test_that("a baseline score on the grouped-designs screen reaches powertools, and the between-group value can start as the within", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E34"))
  values <- modifyList(form_examples$E34, list(adjust_baseline = "yes", baseline_within = "0.36"))
  spec <- build_spec(forms, "E34", fields, values)
  expect_identical(spec$population$baseline_r2_within, 0.36)
  expect_identical(spec$population$baseline_r2_between, 0.36)
  spec2 <- build_spec(forms, "E34", fields, modifyList(values, list(baseline_between = "0.6")))
  expect_identical(spec2$population$baseline_r2_between, 0.6)
  calc <- run_calculation(spec2, run, seed = 1L)
  expect_identical(calc$status, "ok")
  words <- result_sentences(calc$spec, calc$result)
  expect_match(words[["detail"]], "adjustment for the baseline score", fixed = TRUE)
  w <- writeup_text(forms$forms$E34, calc$spec, calc$result, fields, modifyList(values, list(just_source = "A pilot study.")))
  expect_match(w[["short"]], "0.6 of the variance between the groups' averages", fixed = TRUE)
  # No baseline: nothing is passed.
  expect_null(build_spec(forms, "E34", fields, modifyList(values, list(adjust_baseline = "no")))$population$baseline_r2_within)
})

test_that("the simulated data set: offered where the engine has a generator, with its n; said to be unavailable elsewhere", {
  skip_if(is.null(engine_function("simulated_data_available")), "powerkit's engine isn't available here")
  spec_at <- function(name) jsonlite::fromJSON(file.path(repo_dir, "engine", "inst", "specs", paste0(name, ".json")), simplifyVector = FALSE)
  spec <- spec_at("independent_t")
  result <- list(goal_type = "sample_size", n_required = list(n = 128))
  html <- as.character(simulated_data_ui(spec, result))
  expect_match(html, "Simulated data set (CSV, n = 128)", fixed = TRUE)
  expect_match(html, "not evidence, not a pilot", fixed = TRUE)
  expect_equal(simulated_data_n_for(spec, list(goal_type = "power")), spec$goal$n %||% NA_real_)
  html <- as.character(simulated_data_ui(spec_at("sem_model_fit"), result))
  expect_match(html, "A simulated data set isn't available for this design yet.", fixed = TRUE)
  expect_no_match(html, "download_simulated_data", fixed = TRUE)
})

test_that("moderated mediation with two mediators (E40) builds a valid spec for either link", {
  skip_without_run()
  validate <- engine_function("validate_spec", file.path(repo_dir, "engine"))
  fields <- form_fields(form_groups(forms, "E40"))
  expect_equal(form_problems(fields, form_examples$E40), character())
  spec <- build_spec(forms, "E40", fields, form_examples$E40)
  expect_identical(spec$template, "process_7")
  expect_identical(spec$target_test$path, "X->M1->Y")
  expect_true(all(c("XW->M1", "XW->M2", "W->M1") %in% names(spec$population$paths)))
  expect_false(any(c("M1W->Y", "W->Y") %in% names(spec$population$paths)))
  expect_identical(spec$variables$W$label, "Autonomy")
  expect_s3_class(validate(spec), "powerkit_spec")

  values <- modifyList(form_examples$E40, list(stage = "process_14", p_W_Y = "-0.1", p_M1W_Y = "0.15", p_M2W_Y = "0.1",
                                               target_path = "X->M2->Y"))
  expect_equal(form_problems(fields, values), character())
  spec <- build_spec(forms, "E40", fields, values)
  expect_identical(spec$template, "process_14")
  expect_true(all(c("M1W->Y", "M2W->Y", "W->Y") %in% names(spec$population$paths)))
  expect_false(any(c("XW->M1", "W->M1") %in% names(spec$population$paths)))
  expect_s3_class(validate(spec), "powerkit_spec")
})
