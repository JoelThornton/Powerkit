# Mixed designs with unequal groups (options > group_ratio): simulated with
# Spower, each data set analysed by afex::aov_car(), since Superpower's
# ANOVA_power() takes equal groups only in a mixed design.

mixed_spec <- function(template = "anova_2x2_mixed", ratio = c(1, 2), n = 60) {
  spec <- example_spec(template)
  spec$options$group_ratio <- ratio
  spec$options$method <- NULL
  spec$options$nrep <- 100
  spec$goal <- list(type = "power", n = n)
  spec
}

test_that("unequal groups are refused where they can't be used", {
  spec <- mixed_spec()
  spec$options$method <- "exact"
  expect_spec_problem(spec, "isn't available with unequal groups")
  spec <- mixed_spec()
  spec$goal <- list(type = "sensitivity", n = 60, power = 0.8)
  expect_spec_problem(spec, "smallest detectable effect isn't available")
  expect_spec_problem(mixed_spec(ratio = c(1, 1, 2)), "one number per group")
  expect_spec_problem(mixed_spec(n = 61), "ratio 1 : 2")
})

test_that("the groups are drawn at their own sizes", {
  expect_identical(mixed_group_n(90, c(1, 2)), c(30L, 60L))
  set.seed(1)
  data <- mixed_unequal_scores(c(3L, 6L), mu = c(0, 0, 1, 1), sigma = diag(4), m = 2)
  people <- unique(data[c("subject", "a")])
  expect_equal(as.numeric(table(people$a)), c(3, 6))
  expect_equal(nrow(data), 18)
})

test_that("a 2 x 2 mixed design with unequal groups runs through Spower and afex", {
  skip_if_not_installed("afex")
  spec <- mixed_spec()
  spec$options$attrition <- 0.1
  result <- run_quietly(spec)
  expect_true(result$curve$power > 0 && result$curve$power < 1)
  expect_match(result$provenance$backend_function, "p_mixed_anova", fixed = TRUE)
  expect_match(paste(names(unlist(result$provenance$packages)), unlist(result$provenance$packages), collapse = " "), "Spower")
  expect_equal(result$recruitment$groups_analysed, c(20, 40))
  expect_true(all(result$check_run$ok))
})

test_that("the sample-size search keeps the groups whole in the ratio", {
  skip_if_not_installed("afex")
  spec <- mixed_spec("anova_mixed", ratio = c(1, 2))
  spec$goal <- list(type = "sample_size", power = 0.8)
  result <- run_quietly(spec)
  expect_equal(result$n_required$n %% 3, 0)
})

test_that("the R script and the simulated data keep the unequal groups", {
  skip_if_not_installed("afex")
  spec <- mixed_spec()
  result <- run_quietly(spec)
  script <- paste(export_script(spec, result), collapse = "\n")
  expect_match(script, "group_ratio <- c(1, 2)", fixed = TRUE)
  expect_match(script, "p_mixed_anova <- function", fixed = TRUE)
  expect_match(script, "groups_analysed <- n_analysed * group_ratio / sum(group_ratio)", fixed = TRUE)
  data <- simulated_data(mixed_spec("anova_mixed"), 90)
  expect_equal(as.numeric(table(data$Group)), c(30, 60))
})
