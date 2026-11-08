# Effects that vary between studies (Kenny & Judd, 2019) on the t-test
# cards: an optional field that sets population.tau; the engine works it out.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
skip_without_run <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

test_that("the t-test cards offer how much the effect might vary between studies, and no other card does", {
  for (ep in c("E1", "E2", "E3")) {
    fields <- form_fields(form_groups(forms, ep))
    het <- Filter(function(f) identical(f$id, "het_tau"), fields)
    expect_length(het, 1)
    expect_identical(het[[1]]$path, "population.tau")
    expect_true(isTRUE(het[[1]]$optional))
  }
  expect_false("het_tau" %in% vapply(form_fields(form_groups(forms, "E4")), `[[`, "", "id"))
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
  text <- paste(writeup_text(forms$forms$E2, spec, calc$result, fields, values), collapse = " ")
  expect_match(text, "following Kenny and Judd (2019)", fixed = TRUE)
  plain <- build_spec(forms, "E2", fields, modifyList(values, list(het_tau = NULL)))
  expect_null(plain$population$tau)
  plain_calc <- run_calculation(plain, run, seed = forms$default_seed)
  expect_null(plain_calc$result$heterogeneity)
  expect_no_match(as.character(result_panel_ui(tree, forms, "E2", fields, values, plain_calc)), "result-heterogeneity", fixed = TRUE)
})

test_that("the field is hidden when small telescopes plans for no effect", {
  het <- Filter(function(f) identical(f$id, "het_tau"), form_fields(form_groups(forms, "E2")))[[1]]
  expect_false(field_applies(het, modifyList(form_examples$E2, list(sg_use = "telescopes"))))
  expect_true(field_applies(het, form_examples$E2))
})
