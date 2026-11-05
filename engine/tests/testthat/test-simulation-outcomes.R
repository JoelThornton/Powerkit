test_that("failure counts retain both conditional and attempted-study denominators", {
  conditional <- simulate_in_chunks(1000, 1, 1, function(k, seed)
    power4mome_counts(data.frame(pvalid = 0.9, reject = 0.8), k))
  attempted <- simulate_in_chunks(1000, 1, 1, function(k, seed)
    simr_counts(list(x = 720, n = k, pval = c(rep(0.01, 720), rep(0.5, 180), rep(NA, 100)))))
  expect_equal(conditional$rejections / conditional$nrep, 0.8)
  expect_equal(attempted$rejections / attempted$nrep, 0.72)
  for (sim in list(conditional, attempted)) {
    record <- simulation_record(200, 1, sim$rejections, sim$nrep, attempted = sim$attempted, valid = sim$valid)
    expect_equal(record$attempted, record$valid + record$failed)
    expect_equal(record$conditional_power, 0.8)
    expect_equal(record$successful_study_probability, 0.72)
    expect_equal(record$successful, 720)
  }
  expect_equal(simulate_in_chunks(1000, 1, 1, function(k, s) k / 2)$failed, 0)
  expect_equal(power4mome_counts(data.frame(pvalid = 0, reject = NA_real_), 20), c(0, 0, 20, 0))
  expect_error(simr_counts(list(x = 0, n = 20, pval = numeric())), "one decision")
})

test_that("whole-study decisions keep the same two denominators", {
  r <- whole_study_rate(720, 900, 1000)
  expect_equal(unname(r[c("attempted", "valid", "failed", "successful")]), c(1000, 900, 100, 720))
  expect_equal(r[["power"]], 0.8)
  expect_equal(r[["successful_study_probability"]], 0.72)
  expect_equal(r[["mcse"]], sqrt(0.8 * 0.2 / 900))
  failed <- whole_study_rate(0, 0, 1000)
  expect_true(is.na(failed[["power"]]))
  expect_equal(failed[["failed"]], 1000)
  expect_equal(failed[["successful_study_probability"]], 0)
})

test_that("project files retain simulation denominators and counts", {
  spec <- example_spec("correlation")
  spec$goal <- list(type = "power", n = 80)
  spec$options <- list(seed = 11, method = "simulation", nrep = 100)
  expect_warning(result <- run_spec(spec), "fewer than 1,000 replications")
  path <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(path))
  write_project(spec, result, file = path)
  saved <- read_project(path)$result$provenance$simulations
  for (field in c("attempted", "valid", "failed", "successful", "conditional_power", "successful_study_probability", "denominator")) {
    expect_equal(unlist(saved[[field]], use.names = FALSE), result$provenance$simulations[[field]], info = field)
  }
})
