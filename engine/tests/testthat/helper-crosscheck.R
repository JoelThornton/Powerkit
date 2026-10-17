# Helpers for the independent cross-check of simple mediation
# (test-validation-mediation-crosscheck.R): the same design run in tools
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

# power4mome's joint-significance test: both a and b significant (lavaan ML
# z tests via test_parameters()), collapsed with rejection_rates(collapse =
# "all_sig"). Run in batches of at most `batch_size` replications, with R's
# generator seeded as in the engine.
power4mome_joint <- function(a, b, c_prime, n, alpha, nrep, seed, batch_size = 500) {
  batches <- ceiling(nrep / batch_size)
  sizes <- nrep %/% batches + c(rep(1L, nrep %% batches), rep(0L, batches - nrep %% batches))
  counts <- run_in_parallel(seq_len(batches), function(i) {
    set.seed(seed + i - 1)
    result <- power4mome::power4test(
      nrep = sizes[i],
      model = "M ~ X\nY ~ M + X",
      pop_es = sprintf("M ~ X: %s\nY ~ M: %s\nY ~ X: %s", a, b, c_prime),
      n = n,
      test_fun = power4mome::test_parameters,
      test_args = list(pars = c("M~X", "Y~M")),
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

# simsem (Pornprasertmanit, Miller, Schoemann and Jorgensen): data
# generated from the standardised population (residual variances set so
# that every variable has variance 1), fitted with lavaan, joint test from
# the per-replication estimates and standard errors (two-sided z tests).
# simsem switches R's generator to L'Ecuyer-CMRG; the caller's kind is
# restored afterwards.
simsem_joint <- function(a, b, c_prime, n, alpha, nrep, seed) {
  old_kind <- RNGkind()
  on.exit(RNGkind(old_kind[1], old_kind[2], old_kind[3]), add = TRUE)
  # simsem finds lavaan's fitting function by name (lavaanfun = "sem"), so
  # lavaan must be attached while it runs.
  if (!"package:lavaan" %in% search()) {
    suppressPackageStartupMessages(attachNamespace("lavaan"))
    on.exit(detach("package:lavaan", character.only = TRUE), add = TRUE)
  }
  generate <- sprintf(
    "M ~ %s*X\nY ~ %s*M + %s*X\nX ~~ 1*X\nM ~~ %s*M\nY ~~ %s*Y",
    a, b, c_prime, 1 - a^2, 1 - mediation_r_squared_y(a, b, c_prime)
  )
  args <- list(
    nRep = nrep, model = "M ~ X\nY ~ M + X", n = n, generate = generate,
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
  binomial_estimate(mean(p("M~X")[ok] < alpha & p("Y~M")[ok] < alpha), sum(ok))
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
