# Validation: differential item functioning (DIF) in a 2PL model.
# Backend: irtpwr's analytical power (Zimmer and Debelak, 2023, the
# package's citation())
# with its DIF preset.
#   1. agreement with an independent simulation: responses drawn from the
#      two groups' 2PL models (abilities standard normal in both), mirt's
#      multipleGroup() fitted with every item equal and with the DIF item's
#      parameters free (both, or the one that differs; both groups' ability
#      distributions fixed, as irtpwr assumes), and the likelihood-ratio
#      test of the two, for a change in difficulty and in discrimination;
#      the analytical power is a large-sample result, so an allowance of
#      0.04 besides the simulation's own error
#   2. published example: the method paper irtpwr's DESCRIPTION names;
#      placeholder for the maintainer
# Expected values below are owned by the maintainer: do not edit them.
# Skipped unless POWERKIT_FULL_VALIDATION=true.

dif_validation_spec <- function(a, b, item, shift, n, change = 0, free = "both") {
  validation_spec(
    design = "irt",
    template = "dif",
    variables = list(G = validation_variable("binary", "Group", levels = list("Reference", "Focal")), Y = validation_variable("continuous", "Test")),
    population = list(metric = "irt_2pl", a = as.list(a), b = as.list(b), dif_items = list(item), b_shift = list(shift), a_change = list(change)),
    target_test = list(effect = "dif", method = "likelihood_ratio", alpha = 0.05, free_parameters = free),
    seed = 7201,
    n = n
  )
}

# free = "both": the DIF item's slope and intercept free (2 df), the usual
# test; free = "differing" with only a difficulty shift: the intercept
# alone free and the slope equal (1 df), as a change in difficulty alone
# changes only the intercept (d = -a b).
dif_by_hand <- function(a, b, item, shift, n, nrep, seed, change = 0, free = "both") {
  focal_a <- a
  focal_b <- b
  focal_a[item] <- a[item] + change
  focal_b[item] <- b[item] + shift
  k <- length(a)
  draw <- function(m, a, b) {
    th <- stats::rnorm(m)
    p <- stats::plogis(outer(th, a) - matrix(a * b, m, k, byrow = TRUE))
    matrix(as.integer(stats::runif(m * k) < p), m)
  }
  names <- paste0("i", seq_len(k))
  if (free == "both") {
    free_model <- 1
    df <- 2
  } else {
    free_model <- mirt::mirt.model(sprintf("F = 1-%d\nCONSTRAINB = (%d, a1)", k, item))
    df <- 1
  }
  hits <- with_seed(seed, vapply(seq_len(nrep), function(i) {
    data <- rbind(draw(n / 2, a, b), draw(n / 2, focal_a, focal_b))
    colnames(data) <- names
    group <- rep(c("R", "F"), each = n / 2)
    equal <- mirt::multipleGroup(data, 1, group, invariance = names, verbose = FALSE)
    free_fit <- mirt::multipleGroup(data, free_model, group, invariance = names[-item], verbose = FALSE)
    lr <- 2 * (mirt::extract.mirt(free_fit, "logLik") - mirt::extract.mirt(equal, "logLik"))
    stats::pchisq(lr, df = df, lower.tail = FALSE) < 0.05
  }, logical(1)))
  list(power = mean(hits), mcse = sqrt(mean(hits) * (1 - mean(hits)) / nrep))
}

dif_a <- c(1.2, 0.9, 1.5, 1.0, 1.3, 0.8, 1.1, 1.4)
dif_b <- c(-1.0, -0.5, 0.0, 0.3, 0.6, 1.0, -0.2, 0.4)

test_that("DIF: irtpwr's analytical power agrees with multigroup models fitted to simulated studies (simulation)", {
  skip_unless_full_validation()
  cases <- list(
    list(shift = 0.4, change = 0, n = 800, free = "both"),
    list(shift = 0, change = 0.6, n = 1000, free = "both"),
    list(shift = 0.4, change = 0, n = 600, free = "differing"),
    list(shift = -0.3, change = 0, n = 1000, free = "differing")
  )
  for (case in cases) {
    spec <- dif_validation_spec(dif_a, dif_b, 1, case$shift, case$n, case$change, case$free)
    reference <- dif_by_hand(dif_a, dif_b, 1, case$shift, case$n, 500L, 72, case$change, case$free)
    expect_power_agrees_within(engine_power(spec), reference, allowance = 0.04)
  }
})

test_that("DIF: the test keeps its size when no item differs (Type I error)", {
  skip_unless_full_validation()
  null <- dif_by_hand(dif_a, dif_b, 1, 0, 600, 1000L, 73)
  expect_type1_near(null, 0.05)
})

test_that("DIF: compared with a published example (published)", {
  skip_unless_full_validation()
  # Source: TODO (maintainer: the paper irtpwr's DESCRIPTION names,
  # Zimmer et al., 2022, doi:10.1007/s11336-022-09883-5,
  # Psychometrika, the DIF example; section, page).
  n <- TODO_PUBLISHED_VALUE
  published_power <- TODO_PUBLISHED_VALUE
  skip_if_todo(n, published_power)
  spec <- dif_validation_spec(c(1, 1, 1, 1, 1), c(-1, -0.5, 0, 0.5, 1), 1, 0.5, n)
  expect_power_near(engine_power(spec), exact_estimate(published_power))
})
