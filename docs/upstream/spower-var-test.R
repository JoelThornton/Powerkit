# Spower: p_var.test() can't do unequal groups, and two.tailed = FALSE
# tests the wrong direction for a smaller variance
#
# Minimal reproducible example, prepared for Phil Chalmers (Spower's
# author). Found with Spower 0.7, SimDesign 2.28, R 4.5.3.
#
# Both show up when reproducing the two variance examples in the G*Power
# 3.1 manual (version of 1 June 2023): section 26.3 (chi-square test of one
# variance, one tail, V0 = 1.5, V1 = 1, alpha = .05, 80% power, N = 81) and
# section 15.3 (F test of two variances, two tails, ratio 1.5, alpha = .05,
# 80% power, 193 per group; and N = 443, 148 and 295, at an allocation
# ratio of 2).

library(Spower)

alpha <- 0.05
replications <- 10000

# 1. two.tailed = FALSE is "greater" whichever way the variances point.
#
# p_var.test() sets `alternative <- ifelse(two.tailed, "two.sided",
# "greater")`. The manual's example 26.3 tests whether a variance is
# *lower* than 1.5, so "greater" has no power, and the example in Spower's
# own vignette ("Example 26.3; Difference from constant (one sample case)",
# vignettes/gpower_examples.Rmd) cannot reach the manual's N = 81:
#
#   p_var.test(n = interval(10, 200), vars = 1, sigma2 = 1.5,
#              two.tailed = FALSE) |> Spower(power = .80)
#
# At the manual's N = 81 the two calls give 0 and about .80.
set.seed(1)
greater <- Spower(
  p_var.test(n = 81, vars = 1, sigma2 = 1.5, two.tailed = FALSE),
  sig.level = alpha, replications = replications, verbose = FALSE
)
greater$power

set.seed(1)
less <- Spower(
  p_var.test(n = 81, vars = 1, sigma2 = 1.5, alternative = "less"),
  sig.level = alpha, replications = replications, verbose = FALSE
)
less$power

# What I'd expect: for a one-sided test, the direction that the variances
# imply, as `var.test()` and `EnvStats::varTest()` do when given
# `alternative`; or, if "greater" is meant to be the default, a note in
# ?p_var.test and a correction to the vignette.

# 2. gen_var.test() fails whenever the groups are unequal.
#
# In gen_var.test(), `sapply()` over groups of different sizes returns a
# list, so `data.frame(DV = as.vector(dv), group = group)` is built from
# columns of different lengths:
#
#   dv <- sapply(1:length(sds), function(i) rnorm(n * n.ratios[i], sd = sds[i]))
#   group <- rep(paste0("G", 1:length(sds)), times = n * n.ratios)
#
# Error in data.frame(DV = as.vector(dv), group = group):
#   arguments imply differing number of rows: 80, 120
try(gen_var.test(n = 40, vars = c(1.5, 1), n.ratios = c(1, 2)))

# Equal groups are fine, so only the unequal case is affected.
str(gen_var.test(n = 40, vars = c(1.5, 1)))

# What I'd expect: `unlist(Map(...))` (or `do.call(c, ...)`) in place of
# `as.vector(sapply(...))`, so that the allocation-ratio case in the
# manual's example 15.3 can be run:
#
#   p_var.test(n = interval(50, 300), vars = c(1.5, 1), n.ratios = c(1, 2)) |>
#     Spower(power = .80)

# 3. Passing alternative = NULL explicitly (its own default) stops Spower.
#
# Error: Exactly *one* argument must be set to 'NA' in
#        Spower(..., power, sig.level)
# A caller that always supplies `alternative` therefore has to drop the
# argument when it is NULL.
try(Spower(
  p_var.test(n = 100, vars = c(1.5, 1), alternative = NULL),
  sig.level = alpha, replications = 200, verbose = FALSE
))
