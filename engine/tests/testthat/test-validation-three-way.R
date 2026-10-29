# Validation: three-way regression interactions (Y ~ X + W + Z + their
# products + XWZ).
# Backend: InteractionPoweR's analytic power_interaction_3way_r2() (the
# change in R-squared when XWZ is added). Build guide section 6:
#   1. analytic agreement: the unit tests (test-backend-three-way.R) and
#      the direct call below check powerkit against InteractionPoweR
#   2. published examples: placeholders below, for the maintainer to choose
#      a source and transcribe
#   3. direct-call agreement with a simulation: not yet (InteractionPoweR
#      has no simulation for three-way models)
#   4. Type I error: a zero three-way coefficient gives alpha (below)
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

three_way_validation_spec <- function(population, alpha = 0.05, seed = 1,
                                      n = NULL, target_power = NULL,
                                      reliability = list()) {
  v <- validation_variable
  variable <- function(label, role) {
    out <- v("continuous", label)
    if (!is.null(reliability[[role]])) out$reliability <- reliability[[role]]
    out
  }
  validation_spec(
    design = "regression_interaction",
    template = "three_way",
    variables = list(
      X = variable("Predictor", "X"), W = variable("First moderator", "W"),
      Z = variable("Second moderator", "Z"), Y = variable("Outcome", "Y")
    ),
    population = c(list(metric = "correlation"), population),
    target_test = list(effect = "three_way_interaction", method = "ols_t", alpha = alpha),
    seed = seed,
    n = n,
    target_power = target_power
  )
}

example_population <- list(
  r_X_Y = 0.2, r_W_Y = 0.1, r_Z_Y = 0.1, r_XW_Y = 0.05, r_XZ_Y = 0.05, r_WZ_Y = 0.05,
  r_X_W = 0.2, r_X_Z = 0.1, r_W_Z = 0.1, b_XWZ = 0.1
)

# 1. Published example -----------------------------------------------------------

test_that("three-way interaction: matches a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO_PUBLISHED_VALUE (the maintainer chooses a published
  #   three-way power example, for instance from InteractionPoweR's own
  #   documentation or its authors' tutorial papers, and records its
  #   section and page here).
  b_xwz <- TODO_PUBLISHED_VALUE # coefficient of the three-way product
  r_x_y <- TODO_PUBLISHED_VALUE # X with Y
  r_w_y <- TODO_PUBLISHED_VALUE # W with Y
  r_z_y <- TODO_PUBLISHED_VALUE # Z with Y
  r_xw_y <- TODO_PUBLISHED_VALUE # XW with Y
  r_xz_y <- TODO_PUBLISHED_VALUE # XZ with Y
  r_wz_y <- TODO_PUBLISHED_VALUE # WZ with Y
  r_x_w <- TODO_PUBLISHED_VALUE # X with W
  r_x_z <- TODO_PUBLISHED_VALUE # X with Z
  r_w_z <- TODO_PUBLISHED_VALUE # W with Z
  n <- TODO_PUBLISHED_VALUE # the sample size
  published_power <- TODO_PUBLISHED_VALUE # the published power at n
  skip_if_todo(
    b_xwz, r_x_y, r_w_y, r_z_y, r_xw_y, r_xz_y, r_wz_y, r_x_w, r_x_z, r_w_z, n, published_power
  )
  spec <- three_way_validation_spec(
    list(
      r_X_Y = r_x_y, r_W_Y = r_w_y, r_Z_Y = r_z_y, r_XW_Y = r_xw_y, r_XZ_Y = r_xz_y,
      r_WZ_Y = r_wz_y, r_X_W = r_x_w, r_X_Z = r_x_z, r_W_Z = r_w_z, b_XWZ = b_xwz
    ),
    n = n
  )
  expect_equal(run_spec(spec)$curve$power, published_power, tolerance = 0.005)
})

# 2. Direct call -------------------------------------------------------------------

test_that("three-way interaction: equals InteractionPoweR called directly, with reliabilities", {
  skip_unless_full_validation()
  spec <- three_way_validation_spec(example_population, n = 500, reliability = list(X = 0.8, Y = 0.9))
  direct <- suppressWarnings(InteractionPoweR::power_interaction_3way_r2(
    N = 500, b.x1x2x3 = 0.1, r.x1.y = 0.2, r.x2.y = 0.1, r.x3.y = 0.1,
    r.x1x2.y = 0.05, r.x1x3.y = 0.05, r.x2x3.y = 0.05,
    r.x1.x2 = 0.2, r.x1.x3 = 0.1, r.x2.x3 = 0.1,
    rel.x1 = 0.8, rel.x2 = 1, rel.x3 = 1, rel.y = 0.9, alpha = 0.05
  )$pwr)
  expect_equal(run_spec(spec)$curve$power, direct, tolerance = 1e-12)
})

# 3. Type I error ------------------------------------------------------------------

test_that("three-way interaction: no three-way effect gives power equal to alpha", {
  skip_unless_full_validation()
  population <- utils::modifyList(example_population, list(b_XWZ = 0))
  spec <- three_way_validation_spec(population, n = 500)
  expect_equal(run_spec(spec)$curve$power, 0.05, tolerance = 1e-6)
})
