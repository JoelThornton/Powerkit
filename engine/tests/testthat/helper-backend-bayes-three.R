# The spec the three-factor Bayesian ANOVA tests (test-backend-bayes-three*.R)
# start from: E56.

bfthree_spec <- function(within = c("B", "C"), n = 40, nrep = 100, ...) {
  spec <- read_spec(system.file("specs", "anova_factorial_three.json", package = "powerkit"))
  for (v in c("A", "B", "C")) spec$variables[[v]]$type <- if (v %in% within) "within_factor" else "between_factor"
  if (!length(within)) spec$population$r <- NULL
  spec$target_test <- utils::modifyList(list(effect = "interaction_ABC", method = "bayes_factor", evidence_threshold = 3), list(...))
  spec$goal <- list(type = "power", n = n)
  spec$options <- list(nrep = nrep, seed = 20261115)
  spec
}
