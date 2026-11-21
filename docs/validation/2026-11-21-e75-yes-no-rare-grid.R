# Where does E75's likelihood-ratio test of a group-by-condition
# interaction on repeated yes/no answers start finding too many
# differences? (validation-log.md, 21 November 2026, "Repeated yes/no
# answers: where the excess starts"). Two groups, two conditions, no
# interaction (log odds ratios 0.4 for the condition and 0.3 for the
# group, as in 2026-11-20-e75-yes-no-quadrature.R); each simulated study
# fitted by lme4's glmer() with the Laplace approximation, the card's fit,
# and tested by the likelihood ratio of the interaction. The settings vary
# the expected number of yes answers in the rarest cell for a typical
# person: people a group x answers per condition x the smallest of p and
# 1 - p over the four cells. Run:
#   Rscript docs/validation/2026-11-21-e75-yes-no-rare-grid.R
# 2,000 studies a setting on four cores; about 45 minutes.
suppressMessages(library(lme4))
ctrl <- glmerControl(calc.derivs = FALSE)
quiet <- function(expr) tryCatch(suppressWarnings(suppressMessages(expr)), error = function(e) NULL)
lr_p <- function(d) {
  f1 <- quiet(glmer(y ~ g * tt + (1 | id), d, binomial, control = ctrl))
  f0 <- quiet(glmer(y ~ g + tt + (1 | id), d, binomial, control = ctrl))
  if (is.null(f1) || is.null(f0)) return(NA)
  pchisq(max(2 * (as.numeric(logLik(f1)) - as.numeric(logLik(f0))), 0), 1, lower.tail = FALSE)
}
one <- function(npg, sd, p0, m) {
  n <- 2 * npg; id <- rep(seq_len(n), each = 2 * m); g <- rep(rep(0:1, each = npg), each = 2 * m)
  tt <- factor(rep(rep(0:1, each = m), n))
  eta <- qlogis(p0) + 0.4 * (as.integer(tt) - 1) + 0.3 * g + rnorm(n, 0, sd)[id]
  d <- data.frame(y = rbinom(length(id), 1, plogis(eta)), g = factor(g), tt, id = factor(id))
  lr_p(d)
}
rarest <- function(npg, p0, m) {
  p <- plogis(qlogis(p0) + c(0, 0.4, 0.3, 0.7))
  npg * m * min(p, 1 - p)
}
RNGkind("L'Ecuyer-CMRG")
# people a group, SD, p0, answers per condition
settings <- list(
  c(10, 1, 0.10, 2), c(20, 1, 0.05, 2), c(20, 1.5, 0.05, 2), c(50, 1, 0.02, 2),
  c(20, 1, 0.025, 4), c(30, 1, 0.05, 2), c(10, 1, 0.20, 2), c(20, 1, 0.10, 2),
  c(40, 1, 0.05, 2), c(20, 1, 0.05, 4), c(100, 1, 0.02, 2), c(40, 2, 0.05, 2),
  c(10, 1, 0.30, 2), c(60, 1, 0.05, 2), c(30, 1, 0.10, 2), c(20, 1, 0.20, 2),
  c(40, 1, 0.10, 2), c(80, 1, 0.05, 2), c(20, 1.5, 0.10, 4)
)
for (i in seq_along(settings)) {
  s <- settings[[i]]
  set.seed(7910 + i)
  pv <- unlist(parallel::mclapply(1:4, function(k) replicate(500, one(s[1], s[2], s[3], s[4])), mc.cores = 4))
  cat(sprintf("%3d a group, SD %.1f, p0 %.3f, %d answers per condition (rarest cell %.1f): %.4f (%d fits failed)\n",
    s[1], s[2], s[3], s[4], rarest(s[1], s[3], s[4]), mean(pv < 0.05, na.rm = TRUE), sum(is.na(pv))))
}
