# Three-way regression interactions, by InteractionPoweR's analytic
# power_interaction_3way_r2().

three_way_spec <- function(goal = list(type = "power", n = 400), ...) {
  spec <- example_spec("regression_three_way")
  spec$goal <- goal
  spec$population <- utils::modifyList(spec$population, list(...))
  spec
}

direct_3way <- function(n, rel.x1 = 0.8) {
  InteractionPoweR::power_interaction_3way_r2(
    N = n, b.x1x2x3 = 0.1, r.x1.y = -0.3, r.x2.y = 0.2, r.x3.y = -0.1,
    r.x1x2.y = 0.1, r.x1x3.y = 0.05, r.x2x3.y = 0, r.x1.x2 = -0.1, r.x1.x3 = 0.1, r.x2.x3 = 0,
    rel.x1 = rel.x1, rel.x2 = 1, rel.x3 = 1, rel.y = 1, alpha = 0.05
  )$pwr
}

test_that("power is InteractionPoweR's, called with the spec's values renamed", {
  result <- run_spec(three_way_spec())
  expect_equal(result$provenance$backend_function, "InteractionPoweR::power_interaction_3way_r2")
  expect_equal(result$provenance$method, "exact")
  expect_equal(result$curve$power, suppressWarnings(direct_3way(400)))
  expect_true(all(result$check_run$ok))
  expect_setequal(result$check_run$parameter, c(
    "b_XWZ", "r_X_Y", "r_W_Y", "r_Z_Y", "r_XW_Y", "r_XZ_Y", "r_WZ_Y", "r_X_W", "r_X_Z", "r_W_Z"
  ))
})

test_that("the required n is the first n whose power reaches the target", {
  result <- run_spec(three_way_spec(list(type = "sample_size", power = 0.8)))
  n <- result$n_required$n
  expect_gte(suppressWarnings(direct_3way(n)), 0.8)
  expect_lt(suppressWarnings(direct_3way(n - 1)), 0.8)
})

test_that("a zero three-way effect and impossible correlations are refused in plain English", {
  expect_spec_problem(three_way_spec(list(type = "sample_size", power = 0.8), b_XWZ = 0), "zero|no effect", fixed = FALSE)
  spec <- three_way_spec(b_XWZ = 0.5, r_X_Y = 0.7, r_W_Y = 0.7, r_Z_Y = 0.7)
  expect_error(run_spec(spec), "impossible together")
})

test_that("a yes/no X, W or Z is refused by the schema", {
  spec <- three_way_spec()
  spec$variables$Z <- list(type = "binary", label = "Group", levels = list("A", "B"))
  expect_error(validate_spec(spec), class = "powerkit_spec_error")
})

test_that("the exported script reproduces the result", {
  skip_on_cran()
  for (goal in list(list(type = "power", n = 400), list(type = "sample_size", power = 0.8))) {
    spec <- three_way_spec(goal)
    result <- run_spec(spec)
    out <- run_exported_script(spec, result)
    expect_equal(out$reproduced, out$powerkit, tolerance = 1e-10, label = goal$type)
  }
})
