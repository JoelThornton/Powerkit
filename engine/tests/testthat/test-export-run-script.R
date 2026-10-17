# export_run_script(): the script the app offers for calculations too long
# to run there. It holds the spec and its seed and runs run_spec(), so it
# gives the same result as run_spec() on the same spec and seed.

test_that("the run script needs a seed, and says what it needs and how long it takes", {
  spec <- continuous_and_reliable(sim_spec("mediation_simple"))
  spec$options$seed <- NULL
  expect_error(export_run_script(spec), "needs a seed", class = "powerkit_export_error")

  spec$options$seed <- 5L
  text <- export_run_script(spec, run_time = "about 2 hours on one core")
  expect_no_error(parse(text = text))
  expect_match(text, "Expected run time: about 2 hours on one core.", fixed = TRUE)
  expect_match(text, "remotes::install_github(\"JoelThornton/Powerkit\", subdir = \"engine\")", fixed = TRUE)
  expect_match(text, sprintf("power4mome %s", utils::packageVersion("power4mome")), fixed = TRUE)
  expect_match(text, spec_hash(spec), fixed = TRUE)
  expect_match(text, "with its seed (5)", fixed = TRUE)
  expect_match(text, "number of cores doesn't change the result", fixed = TRUE)
  expect_match(text, "result <- run_spec(spec)", fixed = TRUE)
  expect_no_match(export_run_script(spec), "Expected run time", fixed = TRUE)
  file <- tempfile(fileext = ".R")
  on.exit(unlink(file))
  expect_invisible(export_run_script(spec, file))
  expect_equal(paste(c(readLines(file), ""), collapse = "\n"), export_run_script(spec))
})

test_that("the run script's spec is the same spec (same hash)", {
  spec <- continuous_and_reliable(sim_spec("mediation_simple"))
  text <- export_run_script(spec)
  # Evaluate only the line that builds spec_json.
  exprs <- parse(text = text)
  is_json <- vapply(exprs, function(e) is.call(e) && identical(e[[1]], as.name("<-")) && identical(e[[2]], as.name("spec_json")), logical(1))
  expect_equal(sum(is_json), 1)
  spec_json <- eval(exprs[[which(is_json)]][[3]])
  expect_equal(spec_hash(read_spec(spec_json)), spec_hash(spec))
})

test_that("running the script gives the same result as run_spec() with the same spec and seed", {
  skip_on_cran()
  spec <- continuous_and_reliable(sim_spec("mediation_simple", goal = list(type = "power", n = 60)))
  expected <- run_quietly(spec)
  out <- run_exported_run_script(spec)
  expect_equal(out$result$curve, expected$curve)
  expect_identical(out$result$provenance$spec_hash, expected$provenance$spec_hash)
  expect_identical(out$result$provenance$seed, expected$provenance$seed)
  expect_true(out$files[["powerkit-reproduce.R"]])
  expect_true(out$files[["powerkit-citations.txt"]])
})

test_that("power_interval() gives an exact binomial range for simulated power", {
  spec <- continuous_and_reliable(sim_spec("mediation_simple", goal = list(type = "power", n = 60)))
  result <- run_quietly(spec)
  sims <- result$provenance$simulations
  range <- power_interval(result)
  expect_equal(unname(range), stats::binom.test(sims$rejections, sims$nrep)$conf.int[1:2])
  expect_lte(range[["lower"]], result$curve$power)
  expect_gte(range[["upper"]], result$curve$power)
  expect_error(power_interval(list()), "needs the result", class = "powerkit_error")
})
