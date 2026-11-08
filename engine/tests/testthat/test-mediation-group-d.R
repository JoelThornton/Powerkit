group_d_spec <- function(group_d = list(M = 0.4, Y = 0.3), x_prob = 0.5) {
  spec <- read_spec(example_path("mediation_simple"), validate = FALSE)
  spec$variables$X <- list(type = "binary", label = "Condition", levels = list("Control", "Intervention"))
  spec$population$x_prob <- x_prob
  for (outcome in names(group_d)) spec$population$paths[[paste0("X->", outcome)]] <- NULL
  spec$population$group_d <- group_d
  spec$options$seed <- 1L
  spec
}

test_that("a two-group X's path given as Cohen's d is found from a large simulated sample", {
  # With M on X alone, M = a X + e with X at SD 1 and var(e) = 1 - a^2, so
  # the groups' d on M is a / (sqrt(p q) sqrt(1 - a^2)): an independent
  # check of the numerical search, a = d sqrt(p q) / sqrt(1 + d^2 p q).
  for (p in c(0.5, 0.3)) {
    spec <- validate_spec(group_d_spec(list(M = 0.4), x_prob = p))
    found <- resolve_group_d(spec, 1L)$population$paths[["X->M"]]
    pq <- p * (1 - p)
    expect_equal(found, 0.4 * sqrt(pq) / sqrt(1 + 0.4^2 * pq), tolerance = 0.02, label = sprintf("x_prob %s", p))
  }
  # The same seed finds the same paths.
  spec <- validate_spec(group_d_spec())
  expect_identical(resolve_group_d(spec, 7L)$population$paths, resolve_group_d(spec, 7L)$population$paths)
})

test_that("Cohen's d of the groups is checked in words", {
  continuous <- group_d_spec()
  continuous$variables$X <- list(type = "continuous", label = "Condition")
  continuous$population$x_prob <- NULL
  expect_error(validate_spec(continuous), "applies only when X is two groups")
  both <- group_d_spec()
  both$population$paths[["X->M"]] <- 0.2
  expect_error(validate_spec(both), "not both")
  impossible <- validate_spec(group_d_spec(list(M = 9)))
  expect_error(resolve_group_d(impossible, 1L), "isn't possible with the other paths")
})

test_that("a run records the d entered and the paths found, and the script uses them", {
  spec <- group_d_spec()
  spec$goal <- list(type = "power", n = 100L)
  spec$options$nrep <- 100L
  spec$options$ci_draws <- 100L
  result <- suppressWarnings(run_spec(spec))
  expect_identical(result$group_d$entered, list(M = 0.4, Y = 0.3))
  expect_named(result$group_d$found_paths, c("X->M", "X->Y"))
  # The hash is the spec's as given, so the export finds it.
  expect_identical(result$provenance$spec_hash, spec_hash(validate_spec(spec)))
  script <- paste(suppressWarnings(export_script(spec, result)), collapse = "\n")
  expect_match(script, format_pop_value(result$group_d$found_paths[["X->M"]]), fixed = TRUE)
})
