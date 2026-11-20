# Does adaptive quadrature keep repeated yes/no answers near alpha?
# (validation-log.md, 20 November 2026, "Repeated yes/no answers:
# quadrature"). Two groups, two conditions, no group-by-condition
# interaction (log odds ratios 0.4 for the condition and 0.3 for the
# group); each simulated study fitted by lme4's glmer() with the Laplace
# approximation and with adaptive quadrature (nAGQ = 10), and tested by
# the likelihood ratio of the interaction. Run:
#   Rscript docs/validation/2026-11-20-e75-yes-no-quadrature.R
# 2,000 studies a setting on four cores; about an hour.
suppressMessages(library(lme4))
ctrl <- glmerControl(calc.derivs = FALSE)
quiet <- function(expr) tryCatch(suppressWarnings(suppressMessages(expr)), error = function(e) NULL)
lr_p <- function(d, nagq) {
  f1 <- quiet(glmer(y ~ g * tt + (1 | id), d, binomial, control = ctrl, nAGQ = nagq))
  f0 <- quiet(glmer(y ~ g + tt + (1 | id), d, binomial, control = ctrl, nAGQ = nagq))
  if (is.null(f1) || is.null(f0)) return(NA)
  pchisq(max(2 * (as.numeric(logLik(f1)) - as.numeric(logLik(f0))), 0), 1, lower.tail = FALSE)
}
one <- function(npg, sd, p0, m) {
  n <- 2 * npg; id <- rep(seq_len(n), each = 2 * m); g <- rep(rep(0:1, each = npg), each = 2 * m)
  tt <- factor(rep(rep(0:1, each = m), n))
  eta <- qlogis(p0) + 0.4 * (as.integer(tt) - 1) + 0.3 * g + rnorm(n, 0, sd)[id]
  d <- data.frame(y = rbinom(length(id), 1, plogis(eta)), g = factor(g), tt, id = factor(id))
  c(laplace = lr_p(d, 1), quadrature = lr_p(d, 10))
}
RNGkind("L'Ecuyer-CMRG")
settings <- list(c(50, 1, 0.05, 1), c(50, 1, 0.05, 2), c(20, 1.5, 0.05, 2), c(30, 1, 0.1, 2), c(50, 1, 0.05, 3))
for (i in seq_along(settings)) {
  s <- settings[[i]]
  set.seed(7810 + i)
  pv <- do.call(cbind, parallel::mclapply(1:4, function(k) replicate(500, one(s[1], s[2], s[3], s[4])), mc.cores = 4))
  cat(sprintf("%d a group, SD %.1f, p0 %.2f, %d answer(s) per condition: Laplace %.4f, quadrature %.4f\n",
    s[1], s[2], s[3], s[4], mean(pv[1, ] < 0.05, na.rm = TRUE), mean(pv[2, ] < 0.05, na.rm = TRUE)))
}
