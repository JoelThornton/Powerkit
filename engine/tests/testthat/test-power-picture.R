# The Labs picture of power: pwr's power for a two-group t-test, base R's
# t densities, the critical t and the smallest significant d.

test_that("the picture's numbers are pwr's and base R's", {
  picture <- power_picture(64, 0.5, alpha = 0.05)
  expect_equal(picture$power, pwr::pwr.t.test(n = 32, d = 0.5, sig.level = 0.05)$power)
  expect_equal(picture$power, stats::power.t.test(n = 32, delta = 0.5, sd = 1, sig.level = 0.05, strict = TRUE)$power, tolerance = 1e-6)
  expect_equal(picture$beta, 1 - picture$power)
  expect_equal(picture$df, 62)
  expect_equal(picture$ncp, 0.5 * sqrt(16))
  expect_equal(picture$t_crit, stats::qt(0.975, 62))
  # The smallest significant d gives an observed t exactly at the critical
  # value (t = d sqrt(n1 n2 / (n1 + n2))).
  expect_equal(picture$d_crit * sqrt(32 * 32 / 64), picture$t_crit)
  expect_identical(picture$package$name, "pwr")
})

test_that("the curves are the central and noncentral t densities over both critical values", {
  picture <- power_picture(40, 0.8, alpha = 0.01)
  curves <- picture$curves
  expect_equal(curves$null, stats::dt(curves$t, 38))
  expect_equal(curves$alternative, stats::dt(curves$t, 38, ncp = picture$ncp))
  expect_lt(min(curves$t), -picture$t_crit)
  expect_gt(max(curves$t), picture$ncp + 3)
  # Each curve holds nearly all of its distribution.
  step <- diff(curves$t)[1]
  expect_gt(sum(curves$null) * step, 0.99)
  expect_gt(sum(curves$alternative) * step, 0.99)
  # No effect: power is alpha.
  expect_equal(power_picture(40, 0, alpha = 0.01)$power, 0.01, tolerance = 1e-8)
})

test_that("impossible inputs are refused in plain words", {
  expect_error(power_picture(31, 0.5), "even number of participants", class = "powerkit_error")
  expect_error(power_picture(64, -0.2), "of 0 or more", class = "powerkit_error")
  expect_error(power_picture(64, 0.5, alpha = 0.7), "between 0 and 0.5", class = "powerkit_error")
})

test_that("the correlation's picture is pwr.r.test()'s calculation, drawn on Fisher's z scale", {
  picture <- power_picture_r(84, 0.3, alpha = 0.05)
  expect_equal(picture$power, pwr::pwr.r.test(n = 84, r = 0.3, sig.level = 0.05)$power)
  expect_equal(picture$beta, 1 - picture$power)
  expect_equal(picture$df, 82)
  expect_equal(picture$se, 1 / sqrt(81))
  expect_equal(picture$t_crit, stats::qt(0.975, 82))
  # The smallest significant r gives an observed t exactly at the critical
  # value (t = r sqrt(n - 2) / sqrt(1 - r^2)).
  expect_equal(picture$r_crit * sqrt(82) / sqrt(1 - picture$r_crit^2), picture$t_crit)
  # The two shaded tails of the blue curve beyond the dashed lines are the power.
  tails <- stats::pnorm(picture$z_crit, picture$z_r, picture$se, lower.tail = FALSE) +
    stats::pnorm(-picture$z_crit, picture$z_r, picture$se)
  expect_equal(tails, picture$power, tolerance = 1e-10)
  expect_identical(picture$package$name, "pwr")
})

test_that("the correlation's curves are normal densities over both critical values", {
  picture <- power_picture_r(30, 0.6, alpha = 0.01)
  curves <- picture$curves
  expect_equal(curves$null, stats::dnorm(curves$z, 0, picture$se))
  expect_equal(curves$alternative, stats::dnorm(curves$z, picture$z_r, picture$se))
  expect_lt(min(curves$z), -picture$z_crit)
  expect_gt(max(curves$z), picture$z_r + 3 * picture$se)
  step <- diff(curves$z)[1]
  expect_gt(sum(curves$null) * step, 0.99)
  expect_gt(sum(curves$alternative) * step, 0.99)
  # No correlation: power is close to alpha, not equal to it, because
  # pwr's formula mixes Fisher's z with a critical value from t (0.0092 at
  # alpha .01 and n = 30).
  expect_equal(power_picture_r(30, 0, alpha = 0.01)$power, pwr::pwr.r.test(n = 30, r = 0, sig.level = 0.01)$power)
  expect_lt(abs(power_picture_r(30, 0, alpha = 0.01)$power - 0.01), 0.001)
  expect_error(power_picture_r(3, 0.3), "at least 4", class = "powerkit_error")
  expect_error(power_picture_r(50, 1), "below 1", class = "powerkit_error")
})

test_that("the paired t-test's picture is pwr.t.test(type = 'paired')'s calculation", {
  picture <- power_picture_paired(34, 0.5, alpha = 0.05)
  expect_equal(picture$power, pwr::pwr.t.test(n = 34, d = 0.5, sig.level = 0.05, type = "paired")$power)
  expect_equal(picture$df, 33)
  expect_equal(picture$ncp, 0.5 * sqrt(34))
  # The blue curve's tails beyond the critical values are the power.
  tails <- stats::pt(picture$t_crit, 33, picture$ncp, lower.tail = FALSE) + stats::pt(-picture$t_crit, 33, picture$ncp)
  expect_equal(tails, picture$power, tolerance = 1e-8)
  # An observed d_z at the smallest significant value gives t at the critical value.
  expect_equal(picture$dz_crit * sqrt(34), picture$t_crit)
  expect_equal(picture$curves$alternative, stats::dt(picture$curves$t, 33, ncp = picture$ncp))
  expect_equal(power_picture_paired(20, 0, alpha = 0.05)$power, 0.05, tolerance = 1e-8)
  expect_error(power_picture_paired(2.5, 0.5), "whole number", class = "powerkit_error")
})

test_that("the one-way ANOVA's picture is pwr.anova.test()'s calculation, with the F densities", {
  picture <- power_picture_anova(156, 0.25, k = 3, alpha = 0.05)
  expect_equal(picture$power, pwr::pwr.anova.test(k = 3, n = 52, f = 0.25, sig.level = 0.05)$power)
  expect_equal(c(picture$df1, picture$df2), c(2, 153))
  expect_equal(picture$ncp, 0.25^2 * 156)
  # The upper tail of the noncentral F beyond the critical value is the power.
  expect_equal(stats::pf(picture$f_crit, 2, 153, ncp = picture$ncp, lower.tail = FALSE), picture$power, tolerance = 1e-8)
  # The smallest significant f, as an F: f^2 df2 / df1 is the critical F.
  expect_equal(picture$effect_crit^2 * 153 / 2, picture$f_crit)
  curves <- picture$curves
  expect_equal(curves$alternative, stats::df(curves$F, 2, 153, ncp = picture$ncp))
  expect_gt(max(curves$F), picture$f_crit)
  expect_gt(sum(curves$alternative) * diff(curves$F)[2], 0.98)
  expect_equal(power_picture_anova(60, 0, k = 4, alpha = 0.05)$power, 0.05, tolerance = 1e-8)
  expect_error(power_picture_anova(100, 0.25, k = 3), "3 equal groups", class = "powerkit_error")
  expect_error(power_picture_anova(100, 0.25, k = 12), "from 2 to 10", class = "powerkit_error")
})

test_that("the two-proportion picture is pwr.2p.test()'s calculation, on the z scale", {
  picture <- power_picture_2p(194, 0.4, 0.6, alpha = 0.05)
  h <- pwr::ES.h(0.6, 0.4)
  expect_equal(picture$h, h)
  expect_equal(picture$power, pwr::pwr.2p.test(h = h, n = 97, sig.level = 0.05)$power)
  expect_equal(picture$centre, h * sqrt(97 / 2))
  tails <- stats::pnorm(picture$z_crit, picture$centre, lower.tail = FALSE) + stats::pnorm(-picture$z_crit, picture$centre)
  expect_equal(tails, picture$power, tolerance = 1e-10)
  expect_equal(picture$h_crit * sqrt(97 / 2), picture$z_crit)
  # A decrease has the same power as the same-sized increase.
  expect_equal(power_picture_2p(194, 0.6, 0.4)$power, picture$power)
  expect_error(power_picture_2p(194, 0, 0.6), "between 0 and 1", class = "powerkit_error")
})
