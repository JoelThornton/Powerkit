# One-way MANOVA (Pillai's trace; Hotelling's T-squared with two groups),
# simulated with Spower and powerkit's p_manova() experiment. Few
# replications.

manova_spec <- function(n = 90, nrep = 200, ...) {
  spec <- example_spec("manova")
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(seed = 7, nrep = nrep)
  # Replaced whole: modifyList() would merge new rows of means into the old.
  for (name in names(list(...))) spec$population[[name]] <- list(...)[[name]]
  spec
}

two_group_spec <- function(n = 100, nrep = 2000) {
  spec <- manova_spec(n = n, nrep = nrep, means = list(c(0, 0, 0), c(0.4, 0.3, 0.2)), sds = c(1, 1, 1), r = 0.4)
  spec$variables$A$levels <- c("Control", "Treatment")
  spec
}

test_that("MANOVA is simulated with Spower, equal to a direct call, and recovers its population", {
  old <- options(powerkit.cores = 1)
  on.exit(options(old))
  result <- run_quietly(manova_spec())
  expect_equal(result$provenance$backend, "Spower")
  expect_match(result$provenance$backend_function, "Pillai", fixed = TRUE)
  expect_true(all(result$check_run$ok))
  expect_equal(nrow(result$check_run), 9 + 3 + 1)
  set.seed(7)
  spec <- example_spec("manova")
  means <- do.call(rbind, lapply(spec$population$means, as.numeric))
  sds <- c(6, 5, 7)
  direct <- Spower::Spower(p_manova(n = 30, means = means, sds = sds, r = 0.5), replications = 200, verbose = FALSE)
  expect_equal(result$curve$power, direct$power)
})

test_that("with two groups, power matches Hotelling's T-squared computed exactly (pwrss's F test of R-squared)", {
  result <- run_quietly(two_group_spec())
  # Two-group Hotelling's T-squared is the F test of the regression of the
  # group on the outcomes, with Cohen's f-squared = D^2 * n1 * n2 / N^2,
  # where D^2 is the Mahalanobis distance between the groups' means.
  p <- 3
  correlation <- matrix(0.4, p, p)
  diag(correlation) <- 1
  d <- c(0.4, 0.3, 0.2)
  d2 <- drop(t(d) %*% solve(correlation) %*% d)
  f2 <- d2 * 50 * 50 / 100^2
  exact <- pwrss::power.f.regression(r.squared = f2 / (1 + f2), k.total = p, n = 100, alpha = 0.05, verbose = FALSE)$power
  expect_equal(result$curve$power, exact, tolerance = 0.03)
})

test_that("MANOVA holds alpha when every group has the same means", {
  null_power <- run_quietly(manova_spec(n = 60, nrep = 2000, means = list(c(1, 2, 3), c(1, 2, 3), c(1, 2, 3))))$curve$power
  expect_lt(abs(null_power - 0.05), 0.02)
})

test_that("MANOVA specs are refused in plain English when they can't be run", {
  bad_rows <- manova_spec()
  bad_rows$population$means <- bad_rows$population$means[1:2]
  expect_error(validate_spec(bad_rows), "one row per group", class = "powerkit_spec_error")
  bad_sds <- manova_spec(sds = c(6, 5))
  expect_error(validate_spec(bad_sds), "one SD per outcome", class = "powerkit_spec_error")
  bad_r <- manova_spec(r = -0.6)
  expect_error(validate_spec(bad_r), "must be above -0.5", class = "powerkit_spec_error")
  odd_n <- manova_spec(n = 91)
  expect_error(validate_spec(odd_n), "split into 3 equal groups", class = "powerkit_spec_error")
  exact <- manova_spec()
  exact$options$method <- "exact"
  expect_error(validate_spec(exact), class = "powerkit_spec_error")
})

test_that("the exported script reproduces MANOVA", {
  skip_unless_scripts_can_run()
  spec <- manova_spec(n = 60, nrep = 100)
  expect_script_reproduces_power(spec, run_for_export(spec))
})
