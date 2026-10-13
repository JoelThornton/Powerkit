# Spower: one-sided tests reject about twice alpha when there is no effect
#
# Minimal reproducible example, prepared for Phil Chalmers (Spower's
# author). Found with Spower 0.6.4, SimDesign 2.28, R 4.5.3, Windows 11.
#
# What happens: with two.tailed = FALSE, p_t.test() returns half the
# two-sided p-value whatever the direction of the observed effect
# (`p <- ifelse(two.tailed, p, p/2)` in its source; p_r() and
# p_prop.test() do the same). A result in the opposite direction to the
# one being tested therefore counts as significant too, so with d = 0 the
# rejection rate is about 2 * alpha instead of alpha.
#
# What I'd expect: the one-sided p-value, e.g. p/2 when the effect is in the
# tested direction and 1 - p/2 when it isn't (as t.test(..., alternative =
# "greater") gives), so that the rejection rate with d = 0 is about alpha.

library(Spower)

alpha <- 0.05
replications <- 10000

# 1. Spower's one-sided test, no true effect: about 0.10.
set.seed(1)
halved <- Spower(
  p_t.test(n = 50, d = 0, two.tailed = FALSE),
  sig.level = alpha, replications = replications, verbose = FALSE
)
halved$power

# 2. The same data generator, analysed with t.test()'s one-sided test:
#    about 0.05.
one_sided_p <- function(n, d) {
  dat <- gen_t.test(n = n, d = d)
  # gen_t.test() puts d in the first group, so "greater" tests group 1 > 2.
  t.test(dat[[1]], dat[[2]], var.equal = TRUE, alternative = "greater")$p.value
}
set.seed(1)
directional <- Spower(
  one_sided_p(n = 50, d = 0),
  sig.level = alpha, replications = replications, verbose = FALSE
)
directional$power

# 3. With a real effect in the tested direction the two agree closely
#    (results in the wrong direction are then very rare), which is why the
#    problem is easy to miss in power analyses.
set.seed(2)
Spower(p_t.test(n = 50, d = 0.5, two.tailed = FALSE),
       sig.level = alpha, replications = replications, verbose = FALSE)$power
set.seed(2)
Spower(one_sided_p(n = 50, d = 0.5),
       sig.level = alpha, replications = replications, verbose = FALSE)$power

# Results on the machine above (seeded, 10,000 replications each):
#   1. 0.1009 (Type I error with two.tailed = FALSE)
#   2. 0.0495 (Type I error with a directional one-sided test)
#   3. 0.7931 and 0.7931 (power for d = 0.5)

sessionInfo()
