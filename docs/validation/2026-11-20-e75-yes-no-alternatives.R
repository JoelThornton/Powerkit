# Which tests keep repeated yes/no answers near alpha (validation-log.md,
# 20 November 2026, "Repeated yes/no answers: quadrature"). The eight
# settings where the Laplace fit's tests left the Monte Carlo band, each
# simulated study (no difference to find) tested ten ways: glmer() by the
# Laplace approximation and by adaptive quadrature (nAGQ = 10), each by
# the Wald chi-square, the Wald F (a t reference) and the likelihood ratio;
# survival's clogit() by its Wald, likelihood-ratio and score tests; and,
# for two groups with two conditions and one answer, Fisher's exact test
# of the people whose answers change. Run:
#   Rscript docs/validation/2026-11-20-e75-yes-no-alternatives.R 4000
# One file per setting (cell4_<i>.rds) in the working directory; four
# cores take about three hours.
suppressMessages({library(lme4); library(survival)})
reps <- as.integer(commandArgs(TRUE)[1])
ctrl <- glmerControl(calc.derivs = FALSE)
quiet <- function(expr) tryCatch(suppressWarnings(suppressMessages(expr)), error = function(e) NULL)
wald_p <- function(b, V, k, df = Inf) {
  w <- as.numeric(t(b[k]) %*% solve(V[k, k, drop = FALSE]) %*% b[k]); q <- length(k)
  if (is.finite(df)) pf(w / q, q, df, lower.tail = FALSE) else pchisq(w, q, lower.tail = FALSE)
}
glmm_p <- function(d, full, reduced, term, nagq, df) {
  f1 <- quiet(glmer(full, d, binomial, control = ctrl, nAGQ = nagq)); f0 <- quiet(glmer(reduced, d, binomial, control = ctrl, nAGQ = nagq))
  if (is.null(f1) || is.null(f0)) return(c(NA, NA, NA))
  b <- fixef(f1); V <- as.matrix(vcov(f1)); k <- grep(term, names(b))
  lr <- 2 * (as.numeric(logLik(f1)) - as.numeric(logLik(f0)))
  c(wald = wald_p(b, V, k), wald_t = wald_p(b, V, k, df), lr = pchisq(max(lr, 0), length(k), lower.tail = FALSE))
}
clogit_p <- function(d, full, reduced, term) {
  f1 <- quiet(clogit(full, d)); if (is.null(f1)) return(c(NA, NA, NA))
  b <- coef(f1); k <- grep(term, names(b)); keep <- !is.na(b)
  if (any(!keep[k])) return(c(NA, NA, NA))
  V <- as.matrix(vcov(f1)); bb <- b[keep]; kk <- grep(term, names(bb))
  f0 <- if (is.null(reduced)) NULL else quiet(clogit(reduced, d))
  ll0 <- if (is.null(reduced)) f1$loglik[1] else f0$loglik[2]
  lr <- 2 * (f1$loglik[2] - ll0)
  # Score test of the term at the reduced model's estimates: refit the full model
  # starting from the reduced fit with no iterations.
  sc <- if (is.null(reduced)) f1$score else {
    init <- setNames(rep(0, length(b)), names(b)); init[names(coef(f0))] <- coef(f0)
    s <- quiet(clogit(full, d, init = init, control = coxph.control(iter.max = 0))); if (is.null(s)) NA else s$score
  }
  c(wald = wald_p(bb, V, kk), lr = pchisq(max(lr, 0), length(kk), lower.tail = FALSE),
    score = pchisq(sc, length(kk), lower.tail = FALSE))
}
groups_study <- function(npg, sd, p0, times, m) {
  n <- 2 * npg; id <- rep(seq_len(n), each = times * m); g <- rep(rep(0:1, each = npg), each = times * m)
  tt <- factor(rep(rep(seq_len(times) - 1, each = m), n))
  eta <- qlogis(p0) + 0.4 * (as.integer(tt) - 1) + 0.3 * g + rnorm(n, 0, sd)[id]
  d <- data.frame(y = rbinom(length(id), 1, plogis(eta)), g = factor(g), tt, id = factor(id))
  df <- n - (2 * times)
  c(glmm_p(d, y ~ g * tt + (1 | id), y ~ g + tt + (1 | id), ":", 1, df),
    glmm_p(d, y ~ g * tt + (1 | id), y ~ g + tt + (1 | id), ":", 10, df),
    { for (j in seq_len(times - 1)) d[[paste0("gt", j)]] <- as.numeric(d$g == "1" & d$tt == as.character(j))
      clogit_p(d, as.formula(paste("y ~ tt +", paste0("gt", seq_len(times - 1), collapse = " + "), "+ strata(id)")),
        y ~ tt + strata(id), "^gt") },
    exact = if (times == 2 && m == 1) {
      w <- reshape(d[, c("id", "g", "tt", "y")], idvar = c("id", "g"), timevar = "tt", direction = "wide")
      disc <- w$y.0 != w$y.1
      tab <- table(factor(w$g[disc], levels = c("0", "1")), factor(w$y.1[disc], levels = 0:1))
      if (sum(tab) == 0 || any(rowSums(tab) == 0)) 1 else fisher.test(tab)$p.value
    } else NA)
}
one_factor_study <- function(n, sd, p0, times, m = 1) {
  id <- rep(seq_len(n), each = times * m); tt <- factor(rep(rep(seq_len(times) - 1, each = m), n))
  d <- data.frame(y = rbinom(length(id), 1, plogis(qlogis(p0) + rnorm(n, 0, sd)[id])), tt, id = factor(id))
  df <- n - times
  c(glmm_p(d, y ~ tt + (1 | id), y ~ 1 + (1 | id), "^tt", 1, df),
    glmm_p(d, y ~ tt + (1 | id), y ~ 1 + (1 | id), "^tt", 10, df),
    clogit_p(d, y ~ tt + strata(id), NULL, "^tt"), exact = NA)
}
labs <- c("laplace_wald", "laplace_wald_t", "laplace_lr", "agq_wald", "agq_wald_t", "agq_lr", "clogit_wald", "clogit_lr", "clogit_score", "exact_fisher")
cells <- list(
  list("groups", npg = 30, sd = 0.5, p0 = 0.3, times = 2, m = 1),
  list("groups", npg = 50, sd = 1.5, p0 = 0.3, times = 2, m = 1),
  list("groups", npg = 30, sd = 1.5, p0 = 0.3, times = 2, m = 1),
  list("groups", npg = 50, sd = 1.0, p0 = 0.1, times = 2, m = 1),
  list("groups", npg = 30, sd = 1.5, p0 = 0.3, times = 2, m = 2),
  list("groups", npg = 100, sd = 1.5, p0 = 0.3, times = 2, m = 2),
  list("one", n = 100, sd = 1.0, p0 = 0.1, times = 2),
  list("one", n = 100, sd = 1.0, p0 = 0.3, times = 3))
todo <- Filter(function(i) !file.exists(sprintf("cell4_%d.rds", i)), seq_along(cells))
invisible(parallel::mclapply(todo, function(i) {
  set.seed(7700 + i); cl <- cells[[i]]; f <- if (cl[[1]] == "groups") groups_study else one_factor_study
  pv <- replicate(reps, do.call(f, cl[-1])); rownames(pv) <- labs
  rate <- rowMeans(pv < 0.05, na.rm = TRUE); nok <- rowSums(!is.na(pv))
  saveRDS(data.frame(design = cl[[1]], setting = paste(names(cl)[-1], unlist(cl[-1]), collapse = " "), test = labs,
    rate = rate, n_ok = nok, z = (rate - 0.05) / sqrt(0.05 * 0.95 / nok)), sprintf("cell4_%d.rds", i))
}, mc.cores = 4, mc.preschedule = FALSE))
full <- do.call(rbind, lapply(seq_along(cells), function(i) readRDS(sprintf("cell4_%d.rds", i))))
print(full)
