# metapower: homogen_power()'s random-effects power for the test of
# heterogeneity disagrees with simulation, and mpower() rounds Fisher's z
#
# Minimal reproducible example, prepared for Jason W. Griffin (metapower's
# author). Found with metapower 0.2.2, R 4.5.3, while adding a meta-analysis
# card to powerkit (31 October 2026).
#
# 1. homogen_power(): k studies of the same size, true effects drawn from
#    N(d, tau^2) with tau^2 = i2 * v / (1 - i2), Cochran's Q with fixed
#    weights, rejected at the chi-square(k - 1) critical value. The share
#    of simulated Q tests that reject should match random_power. It
#    doesn't, in either direction.
#
#    In compute_homogen_power() the variance of Q,
#      sd <- 2 * df + 4 * (weight - (weight^2 / weight)) * tau2 +
#            2 * (weight^2 - 2 * ((weight^3) / (weight)) + (weight^2)^2 / ((weight^2))) * tau2^2,
#    uses one study's weight where the line before it (for c) sums over
#    the k studies, and its second term is 0 for any weight
#    (weight - weight^2 / weight). The weight is also taken from the
#    variance rounded to two decimals.

library(metapower)

simulated_q_power <- function(k, n, d, i2, nrep = 40000, seed = 1) {
  set.seed(seed)
  v <- 4 / n + d^2 / (2 * n)            # metapower's compute_variance() for d
  tau2 <- i2 * v / (1 - i2)
  w <- rep(1 / v, k)
  mean(replicate(nrep, {
    y <- rnorm(k, rnorm(k, d, sqrt(tau2)), sqrt(v))
    q <- sum(w * (y - sum(w * y) / sum(w))^2)
    q > qchisq(0.95, k - 1)
  }))
}

for (case in list(c(k = 10, n = 40, d = 0.3, i2 = 0.5),
                  c(k = 20, n = 60, d = 0.2, i2 = 0.25),
                  c(k = 5, n = 40, d = 0.3, i2 = 0.5))) {
  mp <- homogen_power(effect_size = case[["d"]], study_size = case[["n"]], k = case[["k"]],
                      i2 = case[["i2"]], es_type = "d")$homogen_power$random_power
  cat(sprintf("k = %d, n = %d, d = %.2f, I2 = %.2f: homogen_power %.3f, simulated %.3f\n",
              case[["k"]], case[["n"]], case[["d"]], case[["i2"]], mp,
              simulated_q_power(case[["k"]], case[["n"]], case[["d"]], case[["i2"]])))
}
# metapower 0.2.2: 0.582 against 0.485; 0.196 against 0.258; 0.275 against 0.313.
#
# The mean-effect power (mpower()) agrees with the same kind of simulation
# (fixed-effect and DerSimonian-Laird random-effects z tests) within Monte
# Carlo error; powerkit uses it (engine/tests/testthat/
# test-validation-meta-analysis.R).
#
# 2. mpower() with es_type = "r" rounds Fisher's z to two decimals
#    (round(0.5 * log((1 + r) / (1 - r)), 2)) before computing power. For
#    r = 0.25 in five studies of 30 with i2 = 0, fixed-effect power is
#    0.856 with z = 0.26 and 0.843 with z = atanh(0.25) = 0.2554:
z <- atanh(0.25)
ncp <- z / sqrt(1 / (27 * 5))
exact <- pnorm(ncp - qnorm(0.975)) + pnorm(-qnorm(0.975) - ncp)
rounded <- mpower(effect_size = 0.25, study_size = 30, k = 5, i2 = 0, es_type = "r")$power$fixed_power
cat(sprintf("r = 0.25: mpower %.3f, exact z %.3f\n", rounded, exact))
