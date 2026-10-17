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

test_that("only the fast end points calculate; the others keep the 'not wired' panel", {
  expect_setequal(wired, paste0("E", 1:8))
  for (ep in paste0("E", 9:14)) expect_false(form_calculates(forms, ep), label = ep)
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

test_that("the result screen shows the number, inputs, backend, validation status, departures and exports", {
  skip_without_run()
  spec <- light_spec("E5")
  fields <- form_fields(form_groups(forms, "E5"))
  calc <- run_calculation(spec, run, seed = 5L)
  html <- as.character(result_panel_ui(tree, forms, "E5", fields, form_examples$E5, calc))
  expect_match(html, "the study has", fixed = TRUE)
  expect_match(html, "not \"observed power\"|not &quot;observed power&quot;")
  expect_match(html, "Calculated by the R package\\s*<strong>Spower</strong>")
  expect_match(html, "Validated.", fixed = TRUE)
  expect_match(html, "No continuity correction", fixed = TRUE)            # Departure 5
  expect_match(html, "in group 1 (0 to 1): 0.6", fixed = TRUE)            # an input it used
  expect_match(html, "download_script", fixed = TRUE)
  expect_match(html, "download_citations", fixed = TRUE)
  expect_match(html, "Methods paragraph", fixed = TRUE)
  expect_match(html, calc$result$provenance$spec_hash, fixed = TRUE)
  for (key in c("result_wording", "n_rounding", "power_curve", "calculation_seed")) expect_match(html, setting_by_key(tree, key)$question |> htmltools::htmlEscape(), fixed = TRUE, label = key)
  # Citations come from the engine's export.
  expect_match(citations(calc$result, format = "text"), "Spower", fixed = TRUE)
})

test_that("departure 1 shows only for the interaction; the mixed design shows departure 2", {
  e7 <- light_spec("E7")
  expect_true(any(grepl("Sommet", departures_for(forms, "E7", e7))))
  e7$target_test$effect <- "main_effect_A"
  expect_false(any(grepl("Sommet", departures_for(forms, "E7", e7))))
  expect_true(any(grepl("ANOVA_exact2", departures_for(forms, "E8", light_spec("E8")))))
})

test_that("an engine error is shown in plain English, without a stack trace", {
  calc <- run_calculation(list(), run = function(spec) stop(structure(class = c("powerkit_error", "error", "condition"), list(message = "Plain message.", call = NULL))), seed = 1L)
  html <- as.character(result_panel_ui(tree, forms, "E1", list(), list(), calc))
  expect_match(html, "Plain message.", fixed = TRUE)
  calc <- run_calculation(list(), run = function(spec) stop("internal detail"), seed = 1L)
  expect_no_match(calc$message, "internal detail", fixed = TRUE)
  expect_identical(run_calculation(list(), run = NULL)$status, "error")
})
