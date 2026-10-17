# Helpers for the independent cross-checks of mediation
# (test-validation-mediation-crosscheck*.R): the same design run in tools
# written independently of power4mome. Each returns list(power, mcse).
#
# The design is simple mediation with standardised paths a (X -> M),
# b (M -> Y) and c' (X -> Y), all variables with variance 1. Y's R-squared
# from M and X is b^2 + c'^2 + 2abc' (M and X correlate a); M's is a^2.
#
# The comparisons and their tolerance are explained in
# docs/validation-log.md, "Independent cross-check for mediation".

mediation_r_squared_y <- function(a, b, c_prime) b^2 + c_prime^2 + 2 * a * b * c_prime

# pwrss (Bulus and Jentschke): power.z.mediation(). Its R-squared defaults
# assume M and X uncorrelated in the outcome model, so both R-squared values
# are given explicitly. method = "monte.carlo" simulates estimates of a and b from
# their large-sample normal sampling distributions and applies the Monte
# Carlo interval test (n.simulation replications, n.draws draws each);
# method = "joint" is analytic: power(a) * power(b), with z tests.
pwrss_mediation <- function(a, b, c_prime, n, alpha, method, nrep = NULL, draws = NULL, seed = NULL) {
  args <- list(
    beta.a = a, beta.b = b, beta.cp = c_prime,
    r.squared.mediator = a^2, r.squared.outcome = mediation_r_squared_y(a, b, c_prime),
    n = n, alpha = alpha, method = method, verbose = 0
  )
  if (method == "monte.carlo") {
    args$n.simulation <- nrep
    args$n.draws <- draws
    set.seed(seed)
    return(binomial_estimate(do.call(pwrss::power.z.mediation, args)$power, nrep))
  }
  exact_estimate(do.call(pwrss::power.z.mediation, args)$power)
}

# power4mome's joint-significance test for simple mediation: both a and b
# significant. See power4mome_joint_model().
power4mome_joint <- function(a, b, c_prime, n, alpha, nrep, seed, batch_size = 500) {
  power4mome_joint_model(
    model = "M ~ X\nY ~ M + X",
    pop_es = sprintf("M ~ X: %s\nY ~ M: %s\nY ~ X: %s", a, b, c_prime),
    pars = c("M~X", "Y~M"),
    n = n, alpha = alpha, nrep = nrep, seed = seed, batch_size = batch_size
  )
}

# power4mome's joint-significance test for any path model: every parameter
# in `pars` significant (lavaan ML z tests via test_parameters()),
# collapsed with rejection_rates(collapse = "all_sig"). Run in batches of
# at most `batch_size` replications, with R's generator seeded as in the
# engine.
power4mome_joint_model <- function(model, pop_es, pars, n, alpha, nrep, seed, batch_size = 500) {
  batches <- ceiling(nrep / batch_size)
  sizes <- nrep %/% batches + c(rep(1L, nrep %% batches), rep(0L, batches - nrep %% batches))
  counts <- run_in_parallel(seq_len(batches), function(i) {
    set.seed(seed + i - 1)
    result <- power4mome::power4test(
      nrep = sizes[i],
      model = model,
      pop_es = pop_es,
      n = n,
      test_fun = power4mome::test_parameters,
      test_args = list(pars = pars),
      iseed = seed + i - 1,
      parallel = FALSE,
      progress = FALSE,
      rejection_rates_args = list(collapse = "all_sig", alpha = alpha)
    )
    rates <- power4mome::rejection_rates(result, collapse = "all_sig", alpha = alpha)
    valid <- round(rates$pvalid[1] * sizes[i])
    c(round(rates$reject[1] * valid), valid)
  }, powerkit_cores())
  counts <- matrix(counts, nrow = 2)
  binomial_estimate(sum(counts[1, ]) / sum(counts[2, ]), sum(counts[2, ]))
}

# simsem (Pornprasertmanit, Miller, Schoemann and Jorgensen) for simple
# mediation: data generated from the standardised population (residual
# variances set so that every variable has variance 1), fitted with lavaan,
# joint test of a and b. See simsem_joint_model().
simsem_joint <- function(a, b, c_prime, n, alpha, nrep, seed) {
  generate <- sprintf(
    "M ~ %s*X\nY ~ %s*M + %s*X\nX ~~ 1*X\nM ~~ %s*M\nY ~~ %s*Y",
    a, b, c_prime, 1 - a^2, 1 - mediation_r_squared_y(a, b, c_prime)
  )
  simsem_joint_model(
    model = "M ~ X\nY ~ M + X", generate = generate, pars = c("M~X", "Y~M"),
    n = n, alpha = alpha, nrep = nrep, seed = seed
  )
}

# simsem's joint-significance test for any path model: data generated from
# `generate` (lavaan syntax with fixed values), `model` fitted with lavaan,
# and every parameter in `pars` significant (two-sided z tests from the
# per-replication estimates and standard errors). simsem switches R's
# generator to L'Ecuyer-CMRG; the caller's kind is restored afterwards.
simsem_joint_model <- function(model, generate, pars, n, alpha, nrep, seed) {
  old_kind <- RNGkind()
  on.exit(RNGkind(old_kind[1], old_kind[2], old_kind[3]), add = TRUE)
  # simsem finds lavaan's fitting function by name (lavaanfun = "sem"), so
  # lavaan must be attached while it runs.
  if (!"package:lavaan" %in% search()) {
    suppressPackageStartupMessages(attachNamespace("lavaan"))
    on.exit(detach("package:lavaan", character.only = TRUE), add = TRUE)
  }
  args <- list(
    nRep = nrep, model = model, n = n, generate = generate,
    lavaanfun = "sem", seed = seed, silent = TRUE
  )
  # multicore is always given: its default is an option simsem sets only
  # when attached. numProc only with several cores: sim(numProc = 1)
  # failed every fit (simsem 0.5-17, Windows).
  args$multicore <- powerkit_cores() > 1
  if (args$multicore) {
    args$numProc <- powerkit_cores()
  }
  out <- suppressMessages(do.call(simsem::sim, args))
  if (!any(out@converged == 0)) {
    stop("simsem could not fit any replication.", call. = FALSE)
  }
  ok <- out@converged == 0
  p <- function(par) 2 * stats::pnorm(-abs(out@coef[[par]] / out@se[[par]]))
  significant <- Reduce(`&`, lapply(pars, function(par) p(par)[ok] < alpha))
  binomial_estimate(mean(significant), sum(ok))
}

# Residual variances (and the residual covariance of two parallel
# mediators) that give every variable variance 1, for simsem's data
# generation. Written separately from the engine's implied_r_squared(): the
# implied covariance matrix Sigma = A Psi A' (A = (I - B)^-1) is computed
# from the path matrix B, and each residual variance in Psi is raised by
# 1 - Sigma[v, v] until every variance is 1. `paths` are "From->To" =
# value; `residual_r` is the mediators' residual correlation (parallel
# mediation only).
standardised_residuals <- function(variables, paths, residual_r = 0, mediators = character()) {
  k <- length(variables)
  B <- matrix(0, k, k, dimnames = list(variables, variables))
  for (key in names(paths)) {
    ends <- strsplit(key, "->", fixed = TRUE)[[1]]
    B[ends[2], ends[1]] <- as.numeric(paths[[key]])
  }
  A <- solve(diag(k) - B)
  psi <- diag(1, k)
  dimnames(psi) <- list(variables, variables)
  for (iteration in 1:200) {
    if (length(mediators) == 2) {
      psi[mediators[1], mediators[2]] <- psi[mediators[2], mediators[1]] <-
        residual_r * sqrt(psi[mediators[1], mediators[1]] * psi[mediators[2], mediators[2]])
    }
    sigma <- A %*% psi %*% t(A)
    gap <- 1 - diag(sigma)
    if (max(abs(gap)) < 1e-12) break
    diag(psi) <- diag(psi) + gap
  }
  if (max(abs(gap)) >= 1e-12 || any(diag(psi) <= 0)) {
    stop("No standardised population with these paths.", call. = FALSE)
  }
  psi
}

# lavaan syntax for simsem's data generation: every path and residual
# (co)variance fixed at its population value.
generating_model <- function(variables, paths, psi) {
  regressions <- vapply(names(paths), function(key) {
    ends <- strsplit(key, "->", fixed = TRUE)[[1]]
    sprintf("%s ~ %s*%s", ends[2], format(paths[[key]], digits = 15), ends[1])
  }, character(1))
  variances <- sprintf("%s ~~ %s*%s", variables, format(diag(psi), digits = 15), variables)
  covariances <- character()
  for (i in seq_along(variables)) for (j in seq_along(variables)) {
    if (i < j && psi[i, j] != 0) {
      covariances <- c(covariances, sprintf("%s ~~ %s*%s", variables[i], format(psi[i, j], digits = 15), variables[j]))
    }
  }
  paste(c(regressions, variances, covariances), collapse = "\n")
}

# The joint test's parameters for a mediation spec's target path, in
# lavaan's "outcome~predictor" names: X->M1->M2->Y gives M1~X, M2~M1, Y~M2.
joint_test_pars <- function(path) {
  nodes <- trimws(strsplit(path, "->", fixed = TRUE)[[1]])
  sprintf("%s~%s", nodes[-1], nodes[-length(nodes)])
}

# The joint test for a mediation spec, in power4mome (with powerkit's own
# translation of the spec: power4mome_inputs()) and in simsem (data
# generated from standardised_residuals(), written separately). Returns
# list(power4mome = , simsem = ), each list(power, mcse).
mediation_joint_crosscheck <- function(spec, nrep, seed) {
  spec <- validate_spec(spec)
  inputs <- power4mome_inputs(spec)
  pars <- joint_test_pars(spec$target_test$path)
  mediators <- setdiff(names(spec$variables), c("X", "Y"))
  variables <- c("X", mediators, "Y")
  paths <- spec$population$paths
  residual_r <- 0
  parallel_mediators <- character()
  if (!is.null(spec$population$residual_correlations)) {
    residual_r <- as.numeric(spec$population$residual_correlations[[1]])
    parallel_mediators <- mediators
  }
  psi <- standardised_residuals(variables, paths, residual_r, parallel_mediators)
  list(
    power4mome = power4mome_joint_model(
      inputs$model, inputs$pop_es, pars, spec$goal$n,
      alpha = spec$target_test$alpha, nrep = nrep, seed = seed
    ),
    simsem = simsem_joint_model(
      inputs$model, generating_model(variables, paths, psi), pars, spec$goal$n,
      alpha = spec$target_test$alpha, nrep = nrep, seed = seed + 1
    )
  )
}

# Two estimates of the same quantity from different tools: their
# difference must lie within the combined 99.9% Monte Carlo interval plus
# `allowance`, the largest difference attributed to the tools' different
# approximations (for example normal-theory standard errors with known
# variances against standard errors estimated from simulated data). With
# allowance = 0 this is expect_power_agrees().
expect_power_agrees_within <- function(estimate, reference, allowance, level = 0.999) {
  difference <- estimate$power - reference$power
  half_width <- z_for(level) * sqrt(estimate$mcse^2 + reference$mcse^2) + allowance
  expect(
    abs(difference) <= half_width,
    sprintf(
      "Estimates %.4f and %.4f differ by %.4f; the tolerance is %.4f (%g%% Monte Carlo interval plus an allowance of %.3f).",
      estimate$power, reference$power, difference, half_width, 100 * level, allowance
    )
  )
  invisible(estimate)
}

# Allowance for comparing a full simulation with pwrss's normal-theory
# calculations: 0.02, for comparisons with pwrss only, at n >= 100 (the
# maintainer's decision, 17 October 2026; docs/validation-log.md). pwrss
# treats the standard errors as known, so its power is slightly higher than
# simulated power; simsem shows the same gap. Comparisons between two
# simulations (power4mome vs simsem) get no allowance. Below n = 100 the
# gap is likely larger and no allowance has been decided, so it stops.
crosscheck_allowance <- function(n) {
  if (n < 100) {
    stop("No cross-check allowance is decided for n < 100 (docs/validation-log.md).", call. = FALSE)
  }
  0.02
}
