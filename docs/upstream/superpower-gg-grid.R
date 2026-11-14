# Superpower's exact dataset with a Greenhouse-Geisser correction, against
# the corrected test's power, across thirteen two-group by three-occasion
# designs and two one-way designs (docs/validation-log.md, 14 November 2026; docs/conventions.md,
# Departure 27). Base R only; it doesn't call Superpower.
#
# approx: ANOVA_exact()'s calculation, written out. The noncentral F with
#   noncentrality epsilon * q * F and degrees of freedom epsilon * q and
#   epsilon * df2, at the population epsilon of the pooled within-group
#   covariance of orthonormal contrasts.
# true: the corrected test itself, in 400,000 studies drawn from their
#   sufficient statistics. These are the group-mean difference of the
#   contrasts (normal) and the pooled within-group covariance (Wishart).
#   Each study's F and Greenhouse-Geisser epsilon are estimated from them.
#   superpower-gg.R checks these p-values against afex::aov_car() on
#   identical data.
# diff: approx - true. The MCSE of `true` is at most .0008.
#
# Run: Rscript docs/upstream/superpower-gg-grid.R (about 8 seconds).

q <- 2L; Q <- qr.Q(qr(contr.helmert(3)))
eps <- function(s) sum(diag(s))^2 / (q * sum(s * s))
case <- function(ng, means, sds, r, reps = 4e5, seed = 1) {
  sigma <- lapply(sds, function(s) diag(s) %*% r %*% diag(s))
  n <- c(ng, ng); N <- sum(n); df2 <- (N - 2) * q
  Sz <- lapply(sigma, function(s) t(Q) %*% s %*% Q); Sp <- (Sz[[1]] + Sz[[2]]) / 2
  e_pop <- eps(Sp); delta <- drop(t(Q) %*% (means[[1]] - means[[2]]))
  F_exact <- (prod(n) / N * sum(delta^2) / q) / (sum(diag(Sp)) / q)
  A <- pf(qf(.95, q * e_pop, df2 * e_pop), q * e_pop, df2 * e_pop, ncp = e_pop * q * F_exact, lower.tail = FALSE)
  set.seed(seed)
  d <- sweep(matrix(rnorm(reps * q), reps) %*% chol(Sz[[1]] / n[1] + Sz[[2]] / n[2]), 2, delta, "+")
  S <- (rWishart(reps, n[1] - 1, Sz[[1]]) + rWishart(reps, n[2] - 1, Sz[[2]])) / (N - 2)
  trS <- S[1,1,] + S[2,2,]; trS2 <- S[1,1,]^2 + S[2,2,]^2 + 2 * S[1,2,]^2
  Fs <- (prod(n) / N * rowSums(d^2) / q) / (trS / q); e_hat <- trS^2 / (q * trS2)
  B <- mean(pf(Fs, q * e_hat, df2 * e_hat, lower.tail = FALSE) < .05)
  c(n_per_group = ng, epsilon = round(e_pop, 3), approx = round(A, 4), true = round(B, 4), diff = round(A - B, 4))
}
r1 <- matrix(c(1,.7,.3,.7,1,.6,.3,.6,1),3)
base_means <- list(c(20,16,15), c(20,19,18.5)); base_sds <- list(c(6,7,8), c(6,8,10))
out <- rbind(
  t(sapply(c(10, 20, 40, 80, 160), function(ng) case(ng, base_means, base_sds, r1))),
  # same pattern, a larger effect
  t(sapply(c(20, 40), function(ng) case(ng, list(c(20,14,12), c(20,19,18.5)), base_sds, r1))),
  # effect aligned the other way (a linear trend difference)
  t(sapply(c(20, 40), function(ng) case(ng, list(c(20,18,16), c(20,20,20)), base_sds, r1))),
  # milder departure from sphericity
  t(sapply(c(20, 40), function(ng) case(ng, base_means, list(c(7,7,8), c(7,7,8)), matrix(c(1,.6,.45,.6,1,.6,.45,.6,1),3)))),
  # strong departure
  t(sapply(c(20, 40), function(ng) case(ng, base_means, list(c(4,7,12), c(4,7,12)), matrix(c(1,.8,.1,.8,1,.5,.1,.5,1),3)))))
print(out)
cat("MCSE at power .5 with 4e5 reps:", sqrt(.25/4e5), "\n")

# One-way repeated measures (one group of n), the same two quantities.
one <- function(mu, sds, r, n, reps = 4e5, seed = 1) {
  R <- diag(3); R[lower.tri(R)] <- r; R <- R + t(R) - diag(3)
  sig <- diag(sds) %*% R %*% diag(sds); Sz <- t(Q) %*% sig %*% Q
  delta <- drop(t(Q) %*% mu); e_pop <- eps(Sz); df2 <- (n - 1) * q
  Fx <- n * sum(delta^2) / sum(diag(Sz))
  A <- pf(qf(.95, q * e_pop, df2 * e_pop), q * e_pop, df2 * e_pop, ncp = e_pop * q * Fx, lower.tail = FALSE)
  set.seed(seed)
  d <- sweep(matrix(rnorm(reps * q), reps) %*% chol(Sz / n), 2, delta, "+")
  S <- rWishart(reps, n - 1, Sz) / (n - 1)
  trS <- S[1,1,] + S[2,2,]; trS2 <- S[1,1,]^2 + S[2,2,]^2 + 2 * S[1,2,]^2
  Fs <- n * rowSums(d^2) / trS; eh <- trS^2 / (q * trS2)
  B <- mean(pf(Fs, q * eh, df2 * eh, lower.tail = FALSE) < .05)
  c(n = n, epsilon = round(e_pop, 3), approx = round(A, 4), true = round(B, 4), diff = round(A - B, 4))
}
print(rbind(
  # test-validation-anova-within-covariance.R's one-way case
  one(c(600, 630, 650), c(100, 120, 150), c(.8, .5, .6), 30),
  # Departure 26's example
  one(c(600, 620, 650), c(100, 100, 100), c(.8, .5, .2), 40)))

# Two-factor within design (2 x 3, interaction), Huynh-Feldt: the reference
# for test-validation-anova-within-covariance.R. The cells are ordered a1b1,
# a1b2, a1b3, a2b1, ...; the interaction contrasts are A's contrast times B's
# orthonormal contrasts. car's Huynh-Feldt epsilon (with Lecoutre's
# correction), capped at 1, which afex reports. On 30 identical data sets
# these p-values agree with afex::aov_car(correction = "HF") to 1e-14.
hf_case <- function(reps = 4e5, seed = 1) {
  mu <- c(400, 410, 420, 430, 450, 470); sds <- rep(c(70, 85, 100), 2); n <- 20L
  R <- 0.7 - 0.08 * abs(outer(1:6, 1:6, "-")); diag(R) <- 1
  sig <- diag(sds) %*% R %*% diag(sds)
  C <- kronecker(c(1, -1) / sqrt(2), Q)
  Sz <- t(C) %*% sig %*% C; delta <- drop(t(C) %*% mu); df2 <- (n - 1) * q
  hf <- function(e) pmin(1, (n * q * e - 2) / (q * (n - 1 - q * e)))
  e_pop <- eps(Sz); Fx <- n * sum(delta^2) / sum(diag(Sz)); e_hf <- hf(e_pop)
  A <- pf(qf(.95, q * e_hf, df2 * e_hf), q * e_hf, df2 * e_hf, ncp = e_hf * q * Fx, lower.tail = FALSE)
  set.seed(seed)
  d <- sweep(matrix(rnorm(reps * q), reps) %*% chol(Sz / n), 2, delta, "+")
  S <- rWishart(reps, n - 1, Sz) / (n - 1)
  trS <- S[1,1,] + S[2,2,]; trS2 <- S[1,1,]^2 + S[2,2,]^2 + 2 * S[1,2,]^2
  Fs <- n * rowSums(d^2) / trS; e <- hf(trS^2 / (q * trS2))
  B <- mean(pf(Fs, q * e, df2 * e, lower.tail = FALSE) < .05)
  c(n = n, epsilon_gg = round(e_pop, 3), approx_hf = round(A, 4), true = round(B, 4), diff = round(A - B, 4))
}
print(hf_case())
