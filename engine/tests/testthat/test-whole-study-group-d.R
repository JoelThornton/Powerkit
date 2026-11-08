# Cohen's d for a two-group X (population > group_d), found as a path from
# the large simulated data set.

group_d_spec <- function() {
  spec <- jsonlite::read_json(system.file("whole-study", "example.json", package = "powerkit"), simplifyVector = FALSE)
  spec$variables$X$type <- "binary"
  spec$variables$W <- NULL
  spec$population$correlations <- NULL
  spec$population$paths <- list(`X->M` = 0.3, `M->Y` = 0.3)
  spec$population$group_d <- list(Y = 0.4)
  spec$analyses <- list(list(id = "compare", label = "Groups on the outcome", test = "x_y", role = "main"),
    list(id = "check", label = "Groups on the mediator", test = "x_m", role = "extra"))
  spec$options <- list(nrep = 100L, seed = 20261108L)
  spec
}

test_that("a d of the groups is checked plainly", {
  spec <- group_d_spec()
  expect_s3_class(validate_whole_study(spec), "powerkit_whole_study")
  both <- spec
  both$population$paths$`X->Y` <- 0.1
  expect_error(validate_whole_study(both), "not both")
  continuous <- spec
  continuous$variables$X$type <- "continuous"
  expect_error(validate_whole_study(continuous), "two groups")
})

test_that("the path found gives the d entered, and a full run reports it", {
  skip_on_cran()
  spec <- group_d_spec()
  found <- whole_study_resolve_group_d(validate_whole_study(spec), spec$options$seed)
  b <- found$population$paths$`X->Y`
  expect_true(is.numeric(b) && abs(b) < 1)
  r <- run_whole_study(spec)
  expect_equal(unname(r$implied$compare$values[["d"]]), 0.4, tolerance = 1e-3)
  expect_equal(r$found_paths$`X->Y`, b)
  # A d for the mediator as well: found first, then the outcome's.
  spec$population$paths$`X->M` <- NULL
  spec$population$group_d$M <- 0.5
  r <- run_whole_study(spec)
  expect_equal(unname(r$implied$check$values[["d"]]), 0.5, tolerance = 1e-3)
  expect_equal(unname(r$implied$compare$values[["d"]]), 0.4, tolerance = 1e-3)
  # Beside a moderator, near the edge of the paths the others allow.
  moderated <- list(spec_version = "0.1", kind = "whole_study",
    variables = list(X = list(type = "binary", label = "X"), W = list(type = "continuous", label = "W"), Y = list(type = "continuous", label = "Y")),
    population = list(paths = list(`W->Y` = 0.1, `XW->Y` = 0.15), correlations = list(`X<->W` = 0), group_d = list(Y = 0.4)),
    analyses = list(list(id = "compare", label = "c", test = "x_y", role = "main"),
      list(id = "moderation", label = "m", test = "interaction", role = "main")),
    claim = "each", alpha = 0.05, effect_justification = list(type = "none"),
    goal = list(type = "power", n = 300L), options = list(nrep = 100L, seed = 1L))
  found <- whole_study_resolve_group_d(validate_whole_study(moderated), 1L)
  expect_true(abs(found$population$paths$`X->Y`) < 0.5)
  # An impossible d is refused with the range the other paths allow.
  spec <- group_d_spec()
  spec$population$paths$`M->Y` <- 0.95
  spec$population$group_d$Y <- 5
  expect_error(run_whole_study(spec), "isn't possible")
})
