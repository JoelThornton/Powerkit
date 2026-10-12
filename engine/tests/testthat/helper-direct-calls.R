# Direct calls to the backend packages, for the direct-call agreement tests
# (build guide section 6, test type 3). Each returns list(power, mcse).
#
# These call the packages exactly as a user would, from inputs written out
# by hand in the test, so they check powerkit's spec-to-backend translation
# independently of powerkit's own adapter code.
#
# Status when written (build phase 1): the Superpower calls were run against
# Superpower 0.2.4.1. Spower, power4mome and InteractionPoweR could not be
# installed in the environment where this file was written, so those calls
# follow the packages' documented interfaces but have NOT been run yet.
# If one fails in the nightly job because an argument or output name is
# wrong, fix it here (not in test-validation-*.R).

# Superpower -----------------------------------------------------------------

superpower_effect_row <- function(effect) {
  switch(effect, main_effect_A = "a", main_effect_B = "b", interaction = "a:b")
}

# `design` is a Superpower design string ("2b*2b" or "2b*2w"); `n` is the
# number of participants per between-participants cell; `means` is a 2x2
# matrix with rows = levels of A and columns = levels of B.
superpower_design <- function(design, n, means, sd, r = 0) {
  Superpower::ANOVA_design(
    design = design,
    n = n,
    # Superpower orders cells a1_b1, a1_b2, a2_b1, a2_b2.
    mu = as.vector(t(means)),
    sd = sd,
    r = r,
    plot = FALSE
  )
}

direct_superpower_simulation <- function(design, n, means, sd, r = 0,
                                         effect, alpha, nrep, seed) {
  result <- Superpower::ANOVA_power(
    superpower_design(design, n, means, sd, r),
    alpha_level = alpha,
    nsims = nrep,
    seed = seed,
    verbose = FALSE
  )
  row <- paste0("anova_", superpower_effect_row(effect))
  binomial_estimate(result$main_results[row, "power"] / 100, nrep)
}

# ANOVA_exact() builds its data with the random-number generator, so its
# results vary around the 15th decimal place between calls. powerkit runs it
# under the run's seed; pass the same seed here for a like-for-like call.
direct_superpower_exact <- function(design, n, means, sd, r = 0, effect, alpha, seed) {
  design <- superpower_design(design, n, means, sd, r)
  set.seed(seed)
  result <- Superpower::ANOVA_exact(design, alpha_level = alpha, verbose = FALSE)
  exact_estimate(result$main_results[superpower_effect_row(effect), "power"] / 100)
}

# Spower (not yet run) ----------------------------------------------------------

spower_power <- function(result) {
  power <- result$power
  if (is.null(power)) {
    stop("Couldn't find the power estimate in Spower's output; update spower_power() in helper-direct-calls.R.", call. = FALSE)
  }
  as.numeric(power)[1]
}

run_spower <- function(sim_call, alpha, nrep, seed) {
  set.seed(seed)
  result <- Spower::Spower(sim_call, sig.level = alpha, replications = nrep, verbose = FALSE)
  binomial_estimate(spower_power(result), nrep)
}

# `n` is per group for two-group designs and the number of pairs or
# participants otherwise, as in Spower::p_t.test().
direct_spower_t_test <- function(type, n, d, n2_n1 = 1, alpha, nrep, seed) {
  run_spower(Spower::p_t.test(n = n, d = d, type = type, n2_n1 = n2_n1), alpha, nrep, seed)
}

direct_spower_correlation <- function(n, r, alpha, nrep, seed) {
  run_spower(Spower::p_r(n = n, r = r), alpha, nrep, seed)
}

# `n` is per group.
direct_spower_two_proportions <- function(n, p1, p2, alpha, nrep, seed) {
  run_spower(Spower::p_prop.test(n = n, prop = c(p1, p2)), alpha, nrep, seed)
}

# `probabilities` is a matrix of cell probabilities; `n` is the total.
direct_spower_chisq <- function(n, probabilities, alpha, nrep, seed) {
  independent <- outer(rowSums(probabilities), colSums(probabilities))
  run_spower(
    Spower::p_chisq.test(n = n, P0 = independent, P = probabilities),
    alpha, nrep, seed
  )
}

# InteractionPoweR (not yet run) -------------------------------------------------

direct_interactionpower_analytic <- function(n, r_x_y, r_w_y, r_xw_y, r_x_w,
                                             rel_x = 1, rel_w = 1, rel_y = 1,
                                             alpha) {
  result <- InteractionPoweR::power_interaction_r2(
    alpha = alpha, N = n,
    r.x1.y = r_x_y, r.x2.y = r_w_y, r.x1x2.y = r_xw_y, r.x1.x2 = r_x_w,
    rel.x1 = rel_x, rel.x2 = rel_w, rel.y = rel_y
  )
  exact_estimate(result$pwr[1])
}

direct_interactionpower_simulation <- function(n, r_x_y, r_w_y, r_xw_y, r_x_w,
                                               rel_x = 1, rel_w = 1, rel_y = 1,
                                               alpha, nrep, seed) {
  result <- InteractionPoweR::power_interaction(
    n.iter = nrep, alpha = alpha, N = n,
    r.x1.y = r_x_y, r.x2.y = r_w_y, r.x1x2.y = r_xw_y, r.x1.x2 = r_x_w,
    rel.x1 = rel_x, rel.x2 = rel_w, rel.y = rel_y,
    seed = seed
  )
  binomial_estimate(result$pwr[1], nrep)
}

# power4mome (not yet run) -------------------------------------------------------
#
# `model` is lavaan model syntax; `pop_es` gives the population values in
# power4mome's "lhs ~ rhs: value" format. `test` is "indirect" (an indirect
# effect along x -> m -> y, where m may name several mediators in order) or
# "index" (the index of moderated mediation, with moderator w).

direct_power4mome <- function(model, pop_es, n, test, x, m, y, w = NULL,
                              method = "monte_carlo_ci", ci_draws, nrep, seed) {
  test_fun <- switch(
    test,
    indirect = power4mome::test_indirect_effect,
    index = power4mome::test_index_of_mome
  )
  test_args <- list(x = x, m = m, y = y)
  if (!is.null(w)) {
    test_args$w <- w
  }
  if (method == "monte_carlo_ci") {
    test_args$mc_ci <- TRUE
    ci_type <- "mc"
  } else {
    test_args$boot_ci <- TRUE
    ci_type <- "boot"
  }
  result <- power4mome::power4test(
    nrep = nrep,
    model = model,
    pop_es = pop_es,
    n = n,
    R = ci_draws,
    ci_type = ci_type,
    test_fun = test_fun,
    test_args = test_args,
    iseed = seed,
    parallel = FALSE,
    progress = FALSE
  )
  rates <- power4mome::rejection_rates(result)
  binomial_estimate(rates$reject[1], nrep)
}
