test_that("handoff requirements follow the routed backend without calculating power", {
  for (case in list(c("mediation_simple", "power4mome"), c("crossed_two_condition", "simr"))) {
    spec <- example_spec(case[[1]])
    req <- analysis_requirements(spec)
    expect_identical(req$backend, case[[2]])
    expect_true(all(c("powerkit", case[[2]]) %in% req$packages))
    expect_setequal(names(req$versions), req$packages)
    expect_type(req$r_requirement, "character")
    expect_length(req$r_requirement, 1)
    expect_no_match(req$r_requirement, "NA")
    if (case[[2]] == "simr") {
      expect_true(all(c("lme4", "lmerTest") %in% req$packages))
      expect_false("power4mome" %in% req$packages)
    }
  }
})

test_that("the downloaded script and handoff use the same software requirement", {
  spec <- example_spec("crossed_two_condition")
  spec$options$seed <- 3L
  req <- analysis_requirements(spec)
  expect_match(export_run_script(spec), paste0("# * R ", req$r_requirement), fixed = TRUE)
  expect_match(export_run_script(spec), "with simr alone", fixed = TRUE)
})
