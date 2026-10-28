# Direct calls to the backend packages, for the direct-call agreement tests
# (build guide section 6, test type 3). Each returns list(power, mcse).
#
# These call the packages exactly as a user would, from inputs written out
# by hand in the test, so they check powerkit's spec-to-backend translation
# independently of powerkit's own adapter code.
#
# Status: all calls have been run against Superpower 0.2.4.1, Spower 0.6.4,
# InteractionPoweR 0.2.4 and power4mome 0.2.1 (build phase 3; see
# docs/decisions.md for what was changed and why).
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

# Spower -------------------------------------------------------------------------
#
# Spower::Spower() reads its experiment unevaluated (as in
# `Spower(p_t.test(n = 50, d = 0.5))`), so the experiment is written out as
# a call with its values in place, and evaluated with the random-number
# generator seeded (Spower draws its own seed from it). Spower turns each
# length-one argument into a column of its design table; vectors and
# matrices must be names it can look up, so they are bound in `data`.

spower_power <- function(result) {
  power <- result$power
  if (is.null(power)) {
    stop("Couldn't find the power estimate in Spower's output; update spower_power() in helper-direct-calls.R.", call. = FALSE)
  }
  as.numeric(power)[1]
}

run_spower <- function(experiment, alpha, nrep, seed, data = list()) {
  env <- list2env(data, parent = globalenv())
  sim_call <- bquote(Spower::Spower(
    .(experiment),
    sig.level = .(alpha), replications = .(nrep), verbose = FALSE
  ))
  set.seed(seed)
  result <- eval(sim_call, env)
  binomial_estimate(spower_power(result), nrep)
}

# `n` is per group for two-group designs and the number of pairs or
# participants otherwise, as in Spower::p_t.test(). For type = "paired",
# `d` is Cohen's d_z (as in the spec). Spower's paired generator draws the
# two time points independently with SD 1, so the differences have SD
# sqrt(2) and Spower's own d is sqrt(2) * d_z.
direct_spower_t_test <- function(type, n, d, n2_n1 = 1, alpha, nrep, seed) {
  spower_d <- if (type == "paired") sqrt(2) * d else d
  run_spower(
    bquote(Spower::p_t.test(n = .(n), d = .(spower_d), type = .(type), n2_n1 = .(n2_n1))),
    alpha, nrep, seed
  )
}

direct_spower_correlation <- function(n, r, alpha, nrep, seed) {
  run_spower(bquote(Spower::p_r(n = .(n), r = .(r))), alpha, nrep, seed)
}

# `n` is per group. The spec's z test has no continuity correction, so
# Yates' correction (on by default in Spower) is turned off.
direct_spower_two_proportions <- function(n, p1, p2, alpha, nrep, seed) {
  run_spower(
    bquote(Spower::p_prop.test(n = .(n), prop = prop, correct = FALSE)),
    alpha, nrep, seed, data = list(prop = c(p1, p2))
  )
}

# `probabilities` is a matrix of cell probabilities; `n` is the total.
# Given a matrix, p_chisq.test() runs chisq.test() on the generated table,
# which is the Pearson test of independence (its null pattern P0 is not
# used for a table). Yates' correction is off, as in the spec's Pearson
# chi-square (it only matters for 2x2 tables).
direct_spower_chisq <- function(n, probabilities, alpha, nrep, seed) {
  run_spower(
    bquote(Spower::p_chisq.test(n = .(n), P = probabilities, correct = FALSE)),
    alpha, nrep, seed, data = list(probabilities = probabilities)
  )
}

# One variance against `sigma2` (one value in `vars`), or two independent
# variances of the same size (two values). `n` is the number of
# participants in each group. Given one variance, p_var.test() runs
# EnvStats::varTest() (the chi-square test); given two,
# stats::var.test() (the F test). Its `alternative` is in the spec's own
# order (the variance in `vars[1]` against `sigma2`, or `vars[1]` over
# `vars[2]`), so it is passed through unchanged, and only when it is a
# one-sided test: `alternative = NULL` would make Spower read the
# argument as the quantity to solve for.
direct_spower_var_test <- function(n, vars, sigma2 = 1, alternative = NULL,
                                   alpha, nrep, seed) {
  experiment <- if (is.null(alternative)) {
    bquote(Spower::p_var.test(n = .(n), vars = vars, sigma2 = .(sigma2)))
  } else {
    bquote(Spower::p_var.test(
      n = .(n), vars = vars, sigma2 = .(sigma2), alternative = .(alternative)
    ))
  }
  run_spower(experiment, alpha, nrep, seed, data = list(vars = vars))
}

# Rank tests. Scores are written out here by hand, not with powerkit's
# score_shape_sampler(): mean 0 and SD 1, the skewed shape being the
# standardised chi-square (10 df) of Spower's p_wilcox.test() examples and
# the heavy-tailed one t (3 df) over sqrt(3).
direct_scores <- list(
  normal = function(n) stats::rnorm(n),
  skewed = function(n) (stats::rchisq(n, df = 10) - 10) / sqrt(20),
  heavy_tailed = function(n) stats::rt(n, df = 3) / sqrt(3)
)

# `n` is per group (two.sample) or the number of scores or pairs. `d` is in
# Spower's orientation: the first sample minus the second. For a paired
# test the differences are drawn directly and the second sample is 0.
direct_spower_wilcox <- function(type, n, d, shape = "normal", n2_n1 = 1,
                                 alternative = NULL, alpha, nrep, seed) {
  draw <- direct_scores[[shape]]
  parent1 <- function(n, d) d + draw(n)
  parent2 <- if (type == "paired") function(n, d) rep(0, n) else function(n, d) draw(n)
  experiment <- bquote(Spower::p_wilcox.test(
    n = .(n), d = .(d), type = .(type), n2_n1 = .(n2_n1),
    parent1 = parent1, parent2 = parent2
  ))
  if (!is.null(alternative)) experiment$alternative <- alternative
  run_spower(experiment, alpha, nrep, seed, data = list(parent1 = parent1, parent2 = parent2))
}

# `n` per group; `means` in SD units.
direct_spower_kruskal <- function(n, means, shape = "normal", alpha, nrep, seed) {
  draw <- direct_scores[[shape]]
  gen <- function(n, k, n.ratios, means, ...) lapply(seq_len(k), function(g) means[g] + draw(n))
  run_spower(
    bquote(Spower::p_kruskal.test(n = .(n), k = .(length(means)), means = means, gen_fun = gen)),
    alpha, nrep, seed, data = list(means = means, gen = gen)
  )
}

# InteractionPoweR ----------------------------------------------------------------

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
  # power_interaction() has no seed argument; run on one core, it uses R's
  # random-number generator.
  set.seed(seed)
  result <- InteractionPoweR::power_interaction(
    n.iter = nrep, alpha = alpha, N = n,
    r.x1.y = r_x_y, r.x2.y = r_w_y, r.x1x2.y = r_xw_y, r.x1.x2 = r_x_w,
    rel.x1 = rel_x, rel.x2 = rel_w, rel.y = rel_y
  )
  binomial_estimate(result$pwr[1], nrep)
}

# power4mome ----------------------------------------------------------------------
#
# `model` is lavaan model syntax; `pop_es` gives the population values in
# power4mome's "lhs ~ rhs: value" format. `test` is "indirect" (an indirect
# effect along x -> m -> y, where m may name several mediators in order) or
# "index" (the index of moderated mediation, with moderator w).
#
# power4test() keeps every replication's data, fit and draws, so memory
# grows with nrep. Large runs are split into batches of at most
# `batch_size` replications (as equal as possible), each an ordinary
# power4test() call with seed seed, seed + 1, ... (both iseed and
# set.seed()); only each batch's
# rejections and valid replications are kept. This is the engine's
# approach (simulate_in_chunks(), with its batch size), so both sides
# simulate the same data sets, on any number of cores. Batches are spread
# over POWERKIT_CORES cores, as in the engine (Unix-alikes only).

direct_power4mome <- function(model, pop_es, n, test, x, m, y, w = NULL,
                              method = "monte_carlo_ci", ci_draws, nrep, seed,
                              batch_size = power4mome_batch_size(ci_draws)) {
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
  batches <- ceiling(nrep / batch_size)
  sizes <- nrep %/% batches + c(rep(1L, nrep %% batches), rep(0L, batches - nrep %% batches))
  counts <- run_in_parallel(seq_len(batches), function(i) {
    # As in the engine: R's generator is seeded too, because for a model with
    # a product term power4test() standardises the population by Monte Carlo
    # before iseed takes effect.
    set.seed(seed + i - 1)
    result <- power4mome::power4test(
      nrep = sizes[i],
      model = model,
      pop_es = pop_es,
      n = n,
      R = ci_draws,
      ci_type = ci_type,
      test_fun = test_fun,
      test_args = test_args,
      iseed = seed + i - 1,
      parallel = FALSE,
      progress = FALSE
    )
    rates <- power4mome::rejection_rates(result)
    valid <- round(rates$pvalid[1] * sizes[i])
    c(round(rates$reject[1] * valid), valid)
  }, powerkit_cores())
  counts <- matrix(counts, nrow = 2)
  binomial_estimate(sum(counts[1, ]) / sum(counts[2, ]), nrep)
}
