# The Labs sequential Bayes factor tool: bayes_sequential() simulates a
# Bayes factor t-test checked as the data come in, stopping at a threshold
# or at the maximum sample size, under the design prior and with no effect.

test_that("each look's thresholds give the same decisions as bfpwr's Bayes factor itself", {
  for (alternative in c("two.sided", "greater", "less")) {
    for (type in c("two.sample", "paired")) {
      plan <- bayes_sequential(10, 60, 10, type = type, alternative = alternative, threshold = 6, threshold_null = 3,
        nsim = 100)
      set.seed(11)
      for (j in seq_len(nrow(plan$looks))) {
        n <- plan$looks$n[j]
        t <- c(stats::runif(40, -5, 5), plan$looks$t_effect[j] + c(-1e-4, 1e-4))
        bf10 <- 1 / bfpwr::tbf01(t = t, n = n, pscale = 1 / sqrt(2), type = type, alternative = alternative)
        u <- if (alternative == "two.sided") abs(t) else if (alternative == "less") -t else t
        ok <- abs(u) < 6
        expect_equal((u >= plan$looks$t_effect[j])[ok], (bf10 >= 6)[ok], info = paste(alternative, type, n))
        stops_null <- if (is.na(plan$looks$t_null[j])) rep(FALSE, length(u)) else u <= plan$looks$t_null[j]
        expect_equal(stops_null[ok], (1 / bf10 >= 3)[ok], info = paste(alternative, type, n))
      }
    }
  }
})

test_that("every simulated study ends one way, at a look, and the seed reproduces it", {
  plan <- bayes_sequential(20, 80, 5, effect = 0.4, effect_sd = 0.1, nsim = 400, seed = 3)
  o <- plan$outcomes
  expect_equal(o$for_effect + o$for_null + o$at_max, c(1, 1))
  expect_equal(o$at_max_toward_effect + o$at_max_toward_null + o$at_max_neither, o$at_max)
  expect_equal(sum(plan$stops$count[plan$stops$truth == "belief"]), 400)
  expect_equal(sum(plan$stops$count[plan$stops$truth == "null"]), 400)
  expect_true(all(plan$stops$n %in% seq(20, 80, 5)))
  expect_true(all(o$n_median >= 20 & o$n_median <= 80))
  expect_identical(bayes_sequential(20, 80, 5, effect = 0.4, effect_sd = 0.1, nsim = 400, seed = 3)$outcomes, o)
  expect_identical(plan$package$name, "bfpwr")
  expect_match(plan$function_used, "seed = 3", fixed = TRUE)
})

test_that("a single look at the maximum is bfpwr's fixed-N chance, as the Labs fixed-N tool gives", {
  plan <- bayes_sequential(30, 120, 10, effect = 0.5, effect_sd = 0.15, threshold = 10, nsim = 200)
  fixed <- bayes_planning(120, effect = 0.5, effect_sd = 0.15, threshold = 10)
  expect_equal(plan$fixed$for_effect, fixed$outcomes$for_effect, tolerance = 1e-10)
  expect_equal(plan$fixed$for_null, fixed$outcomes$for_null, tolerance = 1e-10)
})

test_that("a study checked only once at the maximum matches the fixed-N chances", {
  plan <- bayes_sequential(100, 100, 1, effect = 0.4, threshold = 6, nsim = 4000, seed = 5)
  expect_equal(nrow(plan$looks), 1)
  # bfpwr's normal approximation is close at 198 degrees of freedom.
  expect_equal(plan$outcomes$for_effect, plan$fixed$for_effect, tolerance = 0.03)
  expect_equal(plan$outcomes$for_null, plan$fixed$for_null, tolerance = 0.03)
  expect_true(all(plan$outcomes$n_median == 100))
})

test_that("a two-sided test can't stop for no effect while t = 0 doesn't give enough evidence", {
  plan <- bayes_sequential(10, 40, 10, threshold_null = 10, nsim = 200)
  bf01_at_zero <- vapply(plan$looks$n, function(n) bfpwr::tbf01(t = 0, n = n), 0)
  expect_true(all(is.na(plan$looks$t_null[bf01_at_zero < 10])))
  expect_equal(plan$outcomes$for_null, c(0, 0))
})

test_that("the inputs are refused in plain words", {
  expect_error(bayes_sequential(2, 50), "first look")
  expect_error(bayes_sequential(50, 20), "largest sample size")
  expect_error(bayes_sequential(10, 5000, 1), "checks at most 2,000")
  expect_error(bayes_sequential(10, 50, threshold_null = 1), "threshold for no effect")
  expect_error(bayes_sequential(10, 50, nsim = 10), "simulated studies")
  expect_error(bayes_sequential(10, 50, type = "three.sample"), "'type'")
})
