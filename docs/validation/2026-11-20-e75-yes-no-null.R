# False-positive rate of the logistic random-intercept model's tests with
# repeated yes/no answers (validation-log.md, 20 November 2026). Each
# simulated study has no difference to find; each is fitted with lme4's
# glmer() (Laplace) and tested by the Wald chi-square and the
# likelihood-ratio test of the condition term (one factor) or the
# group-by-condition interaction (two groups). Run:
#   Rscript docs/validation/2026-11-20-e75-yes-no-null.R 4000
# Each block's seeds are as recorded; four cores take about two hours.
suppressMessages(library(lme4))
reps <- as.integer(commandArgs(TRUE)[1] %||% 4000)

fit_tests <- function(d, full, reduced, term) {
  ctrl <- glmerControl(calc.derivs = FALSE)
  quiet <- function(f) tryCatch(suppressWarnings(suppressMessages(glmer(f, d, binomial, control = ctrl))), error = function(e) NULL)
  f1 <- quiet(full); f0 <- quiet(reduced)
  if (is.null(f1) || is.null(f0)) return(c(failed = 1, singular = NA, wald = NA, lr = NA))
  b <- fixef(f1); V <- as.matrix(vcov(f1)); k <- grep(term, names(b))
  w <- as.numeric(t(b[k]) %*% solve(V[k, k, drop = FALSE]) %*% b[k])
  lr <- 2 * (as.numeric(logLik(f1)) - as.numeric(logLik(f0)))
  c(failed = 0, singular = isSingular(f1), wald = pchisq(w, length(k), lower.tail = FALSE) < .05,
    lr = pchisq(max(lr, 0), length(k), lower.tail = FALSE) < .05)
}

# Two groups (npg people each), `times` conditions, m answers per condition.
groups_study <- function(npg, sd, p0, times, m) {
  n <- 2 * npg
  id <- rep(seq_len(n), each = times * m)
  g <- rep(rep(0:1, each = npg), each = times * m)
  tt <- factor(rep(rep(seq_len(times) - 1, each = m), n))
  eta <- qlogis(p0) + 0.4 * (as.integer(tt) - 1) + 0.3 * g + rnorm(n, 0, sd)[id]
  d <- data.frame(y = rbinom(length(id), 1, plogis(eta)), g = factor(g), tt, id = factor(id))
  fit_tests(d, y ~ g * tt + (1 | id), y ~ g + tt + (1 | id), ":")
}

# One group of n people, `times` conditions, one answer each.
one_factor_study <- function(n, sd, p0, times) {
  id <- rep(seq_len(n), each = times)
  tt <- factor(rep(seq_len(times) - 1, n))
  d <- data.frame(y = rbinom(length(id), 1, plogis(qlogis(p0) + rnorm(n, 0, sd)[id])), tt, id = factor(id))
  fit_tests(d, y ~ tt + (1 | id), y ~ 1 + (1 | id), "^tt")
}

run_grid <- function(grid, study, seed0) {
  res <- parallel::mclapply(seq_len(nrow(grid)), function(i) {
    set.seed(seed0 + i)
    out <- replicate(reps, do.call(study, as.list(grid[i, ])))
    ok <- out["failed", ] == 0
    data.frame(grid[i, ], failed = mean(!ok), singular = mean(out["singular", ok]),
      wald = mean(out["wald", ok]), lr = mean(out["lr", ok]), n_ok = sum(ok))
  }, mc.cores = 4)
  do.call(rbind, res)
}

# 1. Two groups, one answer per condition (seeds 7501 to 7508).
print(run_grid(rbind(
  expand.grid(npg = c(30, 50, 100), sd = c(0.5, 1.5), p0 = 0.3, times = 2, m = 1),
  data.frame(npg = c(50, 50), sd = c(1, 1), p0 = c(0.1, 0.3), times = c(2, 3), m = 1)), groups_study, 7500), digits = 3)
# 2. Two groups, two or three answers per condition (seeds 7501 to 7505).
print(run_grid(rbind(
  expand.grid(npg = c(30, 100), sd = 1.5, p0 = c(0.1, 0.3), times = 2, m = 2),
  data.frame(npg = 50, sd = 1, p0 = 0.1, times = 2, m = 3)), groups_study, 7500), digits = 3)
# 3. One group, one answer per condition (seeds 7601 to 7606).
print(run_grid(rbind(
  expand.grid(n = c(60, 200), sd = c(0.5, 1.5), p0 = 0.3, times = 2),
  data.frame(n = c(100, 100), sd = c(1, 1), p0 = c(0.1, 0.3), times = c(2, 3))), one_factor_study, 7600), digits = 3)
