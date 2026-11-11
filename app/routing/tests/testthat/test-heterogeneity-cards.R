# Effects that vary between studies on the t-test cards (Kenny & Judd,
# 2019) and the correlation card (McShane & Bockenholt, 2014): an optional
# field that sets population.tau; the engine works it out.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
skip_without_run <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

test_that("the t-test and correlation cards offer how much the effect might vary between studies, and no other card does", {
  for (ep in c("E1", "E2", "E3")) {
    fields <- form_fields(form_groups(forms, ep))
    het <- Filter(function(f) identical(f$id, "het_tau"), fields)
    expect_length(het, 1)
    expect_identical(het[[1]]$path, "population.tau")
    expect_true(isTRUE(het[[1]]$optional))
    # New plans do not silently average across differing study effects.
    expect_null(het[[1]][["default"]])
  }
  het <- Filter(function(f) identical(f$id, "het_tau"), form_fields(form_groups(forms, "E4")))
  expect_length(het, 1)
  expect_null(het[[1]][["default"]])
  expect_false("het_tau" %in% vapply(form_fields(form_groups(forms, "E5")), `[[`, "", "id"))
})

test_that("a variation reaches the spec, the result and the write-up; empty leaves the usual analysis", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E2"))
  values <- modifyList(form_examples$E2, list(het_tau = 0.2, goal = "power", n = 100))
  spec <- build_spec(forms, "E2", fields, values)
  expect_equal(spec$population$tau, 0.2)
  calc <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_equal(calc$result$heterogeneity$tau, 0.2)
  html <- as.character(result_panel_ui(tree, forms, "E2", fields, values, calc))
  expect_match(html, "result-heterogeneity", fixed = TRUE)
  expect_match(html, "Variation between studies", fixed = TRUE)
  # The range: none, small, medium and large (0.2, the value entered).
  expect_match(html, "result-heterogeneity-table", fixed = TRUE)
  expect_match(html, "Large (your value)", fixed = TRUE)
  expect_match(html, "None (the same in every study)", fixed = TRUE)
  text <- paste(writeup_text(forms$forms$E2, spec, calc$result, fields, values), collapse = " ")
  expect_match(text, "following Kenny and Judd (2019)", fixed = TRUE)
  expect_match(text, "average chance of significance", fixed = TRUE)
  # The starting variation is a departure, shown on the result and in the
  # methods paragraph, only when variation is planned for.
  expect_true("23" %in% names(departures_for(forms, "E2", spec)))
  expect_match(html, "376 people in total against 352 without", fixed = TRUE)
  with_departures <- paste(writeup_text(forms$forms$E2, spec, calc$result, fields, values, departures_for(forms, "E2", spec)), collapse = " ")
  expect_match(with_departures, "not power at the average effect", fixed = TRUE)
  plain <- build_spec(forms, "E2", fields, modifyList(values, list(het_tau = NULL)))
  expect_null(plain$population$tau)
  plain_calc <- run_calculation(plain, run, seed = forms$default_seed)
  expect_null(plain_calc$result$heterogeneity)
  expect_no_match(as.character(result_panel_ui(tree, forms, "E2", fields, values, plain_calc)), "result-heterogeneity", fixed = TRUE)
  expect_false("23" %in% names(departures_for(forms, "E2", plain)))
  # Raw means and one SD work too: the engine plans for their d.
  raw <- build_spec(forms, "E2", fields, modifyList(values, list(effect_units = "raw", raw_mean_1 = 10, raw_mean_2 = 13, raw_sd = 10, d = NULL)))
  raw_calc <- run_calculation(raw, run, seed = forms$default_seed)
  expect_identical(raw_calc$status, "ok")
  expect_equal(raw_calc$result$heterogeneity$tau, 0.2)
  # Unequal SDs for Welch's test are refused in plain words.
  unequal <- build_spec(forms, "E2", fields, modifyList(values, list(method = "welch_t", welch_sd_ratio = 1.5)))
  expect_match(run_calculation(unequal, run, seed = forms$default_seed)$message %||% "", "equal SDs", fixed = TRUE)
})

test_that("the field is hidden where Kenny and Judd's formula doesn't apply", {
  het <- Filter(function(f) identical(f$id, "het_tau"), form_fields(form_groups(forms, "E2")))[[1]]
  expect_true(field_applies(het, form_examples$E2))
  for (change in list(list(sg_use = "telescopes"), list(method = "mann_whitney"), list(method = "bayes_factor"),
    list(method = "minimum_effect"), list(welch_method = "simulation"), list(goal = "justified_alpha"),
    list(goal = "sensitivity_curve"))) {
    expect_false(field_applies(het, modifyList(form_examples$E2, change)), label = names(change))
  }
})

test_that("the correlation card plans a varying correlation on Fisher's z, with its range and write-up", {
  skip_without_run()
  fields <- form_fields(form_groups(forms, "E4"))
  values <- modifyList(form_examples$E4, list(goal = "sample_size", power = 0.8, r = 0.1, method = "pearson"))
  values$het_tau <- NULL
  values <- modifyList(values, list(het_tau = 0.025))
  spec <- build_spec(forms, "E4", fields, values)
  expect_equal(spec$population$tau, 0.025)
  calc <- run_calculation(spec, run, seed = forms$default_seed)
  expect_identical(calc$status, "ok")
  expect_equal(calc$result$heterogeneity$scale, "Fisher's z")
  html <- as.character(result_panel_ui(tree, forms, "E4", fields, values, calc))
  expect_match(html, "on Fisher&#39;s z scale|on Fisher's z scale")
  expect_match(html, "Small (your value)", fixed = TRUE)
  expect_match(html, "People needed", fixed = TRUE)
  expect_true("24" %in% names(departures_for(forms, "E4", spec)))
  expect_false("23" %in% names(departures_for(forms, "E4", spec)))
  text <- paste(writeup_text(forms$forms$E4, spec, calc$result, fields, values), collapse = " ")
  expect_match(text, "following McShane and B\u00f6ckenholt (2014)", fixed = TRUE)
  het <- Filter(function(f) identical(f$id, "het_tau"), fields)[[1]]
  for (change in list(list(method = "spearman"), list(method = "kendall"), list(method = "bayes_factor"),
    list(goal = "justified_alpha"))) {
    expect_false(field_applies(het, modifyList(values, change)), label = names(change))
  }
})

test_that("new ordinary plans stay fixed-effect while stored variation remains explicit", {
  for (ep in c("E1", "E2", "E3", "E4")) {
    fields <- form_fields(form_groups(forms, ep))
    values <- form_examples[[ep]]
    values$het_tau <- NULL
    fresh <- build_spec(forms, ep, fields, values)
    expect_null(fresh$population$tau, label = ep)
    field <- Filter(function(f) identical(f$id, "het_tau"), fields)[[1]]
    html <- as.character(field_ui(field, NULL))
    expect_match(html, "not an automatic safety margin", fixed = TRUE)
    for (tau in c(0, 0.05, 0.2)) {
      saved <- modifyList(values, list(het_tau = tau))
      route <- project_route(list(endpoint = ep), saved)
      restored <- restore_from_project(route, tree, forms)
      expect_equal(restored$form_values$het_tau, tau)
      spec <- build_spec(forms, ep, fields, restored$form_values)
      expect_equal(spec$population$tau, tau)
    }
  }
})
