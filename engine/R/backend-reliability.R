# Backend adapter: reliability and agreement (design "reliability"), by
# formula.
#
#   icc             reliability/icc: a test that the intraclass correlation
#                   exceeds a null value, k ratings of each subject, in a
#                   one-way random-effects model. ICC.Sample.Size's
#                   calculateIccPower(): Walter, Eliasziw and Donner's
#                   approximation to the F test, power
#                   Phi(sqrt((k - 1)(N - 1) / (2k)) log(F1 / F0) - z), with
#                   F = (1 + (k - 1) rho) / (1 - rho) (its source, version
#                   1.1). One- or two-sided (`tails`). That is the
#                   approximation, kept on request (target_test > method
#                   "icc_walter"). By default (method "icc_test") powerkit
#                   uses the F test's exact power, as Donner and Eliasziw
#                   (1987) give it: under the one-way random-effects model
#                   MSB / MSW is F1 times a central F with n - 1 and
#                   n (k - 1) df, so the test that rejects when
#                   MSB / MSW > F0 x F_crit has power
#                   P(F > (F0 / F1) F_crit) in base R's stats::pf()
#                   (two-sided: both tails). Checked against simulated
#                   one-way ANOVAs (test-validation-reliability.R) and
#                   Departure 29.
#
#   cronbach_alpha  reliability/cronbach_alpha: a test that Cronbach's alpha
#                   exceeds a null value h, over r items. Bonett and
#                   Wright's (2015) test of ln(1 - alpha), whose sample size
#                   statpsych's size.test.cronbach() computes:
#                   n = ceiling(2r / (r - 1) (z_a + z_b)^2 / ln(e)^2 + 2),
#                   e = (1 - rel) / (1 - h), z_a two-sided (its source,
#                   version 2.0.0). statpsych gives no power at a given n,
#                   so power is the same formula solved for z_b:
#                   Phi(D - z_a), D = sqrt((n - 2)(r - 1) / (2r)) |ln e|,
#                   plus, for a two-sided test, the other tail's
#                   Phi(-D - z_a), which the sample-size formula leaves
#                   out (Departure 34: so a test at the null value has
#                   power alpha, not alpha / 2). Its smallest n for a power
#                   equals size.test.cronbach()'s
#                   (test-backend-reliability.R). A one-sided test takes
#                   z_a at 1 - alpha.
#
#   kappa           reliability/kappa: agreement among 2 to 6 raters on 2
#                   to 5 categories, H0: kappa = kappa0 against kappa1, by
#                   kappaSize's PowerBinary(), Power3Cats(), Power4Cats()
#                   or Power5Cats() (Donner and Rotondi's goodness-of-fit
#                   approach, two-sided). These give the sample size for a
#                   power, as a number that is not rounded: the
#                   noncentrality for that power over the noncentrality
#                   per subject. Power at a given n is the power for which
#                   kappaSize gives that n, found by root-finding on its
#                   `power` argument, so every number comes from kappaSize.
#
# No random numbers are drawn. The check runs simulate a large study from
# each model and recover its inputs.

reliability_backend <- function(spec, seed = NULL) {
  inputs <- reliability_inputs(spec)
  step <- valid_n_step(spec)
  package <- reliability_package(inputs$template, inputs$method)
  power_at <- function(n) call_backend(package, reliability_power(inputs, n))
  list(
    name = package,
    packages = package,
    methods = "exact",
    default_method = "exact",
    functions = c(exact = reliability_function(inputs)),
    n_step = step,
    exact_min_n = step * ceiling(minimum_n(spec) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = function(n, power) formula_search_sensitivity(spec, n, power),
    check_run = function() reliability_check_run(spec, inputs, seed)
  )
}

reliability_package <- function(template, method = NULL) {
  if (identical(template, "icc") && !identical(method, "icc_walter")) return("stats")
  switch(template, icc = "ICC.Sample.Size", cronbach_alpha = "statpsych", kappa = "kappaSize")
}

# The ICC by the F test's exact power (the default; see the header).
icc_exact_test <- function(spec) {
  identical(spec$design, "reliability") && identical(spec$template, "icc") &&
    !identical(spec$target_test$method, "icc_walter")
}

reliability_function <- function(inputs) {
  switch(inputs$template,
    icc = if (identical(inputs$method, "icc_walter")) "ICC.Sample.Size::calculateIccPower" else
      "stats::pf() (the F test's exact power, Donner & Eliasziw, 1987)",
    cronbach_alpha = "statpsych::size.test.cronbach",
    kappa = paste0("kappaSize::", kappa_function_name(length(inputs$proportions)))
  )
}

kappa_function_name <- function(categories) {
  c("PowerBinary", "Power3Cats", "Power4Cats", "Power5Cats")[categories - 1]
}

reliability_inputs <- function(spec) {
  pop <- spec$population
  tt <- spec$target_test
  one_sided <- identical(tt$alternative, "greater")
  base <- list(template = spec$template, alpha = tt$alpha, one_sided = one_sided, method = tt$method)
  switch(spec$template,
    icc = c(base, list(value = pop$icc, null = pop$icc_null, raters = pop$raters)),
    cronbach_alpha = c(base, list(value = pop$reliability, null = pop$reliability_null, items = pop$items)),
    kappa = c(base, list(value = pop$kappa, null = pop$kappa_null, raters = pop$raters,
      proportions = as.numeric(unlist(pop$proportions))))
  )
}

reliability_power <- function(inputs, n) {
  switch(inputs$template,
    icc = if (identical(inputs$method, "icc_walter")) {
      ICC.Sample.Size::calculateIccPower(
        p = inputs$value, p0 = inputs$null, k = inputs$raters, alpha = inputs$alpha,
        tails = if (inputs$one_sided) 1 else 2, N = n
      )[[1]]$power
    } else {
      icc_exact_power(inputs, n)
    },
    cronbach_alpha = cronbach_power(inputs, n),
    kappa = kappa_power(inputs, n)
  )
}

# The F test of the ICC's exact power (Donner and Eliasziw, 1987): MSB /
# MSW is F1 times a central F(n - 1, n (k - 1)); the test rejects when it
# exceeds F0 times the central F's critical value (two-sided: or is below
# F0 times its lower critical value).
icc_exact_power <- function(inputs, n) {
  ratio <- function(rho) (1 + (inputs$raters - 1) * rho) / (1 - rho)
  scale <- ratio(inputs$null) / ratio(inputs$value)
  df1 <- n - 1
  df2 <- n * (inputs$raters - 1)
  if (inputs$one_sided) {
    return(stats::pf(scale * stats::qf(1 - inputs$alpha, df1, df2), df1, df2, lower.tail = FALSE))
  }
  stats::pf(scale * stats::qf(1 - inputs$alpha / 2, df1, df2), df1, df2, lower.tail = FALSE) +
    stats::pf(scale * stats::qf(inputs$alpha / 2, df1, df2), df1, df2)
}

# Bonett and Wright's test, solved for power (see the header).
cronbach_power <- function(inputs, n) {
  z_a <- stats::qnorm(1 - if (inputs$one_sided) inputs$alpha else inputs$alpha / 2)
  e <- (1 - inputs$value) / (1 - inputs$null)
  r <- inputs$items
  d <- sqrt(max(n - 2, 0) * (r - 1) / (2 * r)) * abs(log(e))
  # A two-sided test rejects in either tail (Departure 34).
  stats::pnorm(d - z_a) + if (inputs$one_sided) 0 else stats::pnorm(-d - z_a)
}

# kappaSize's sample size (not rounded) for a power.
kappa_size <- function(inputs, power) {
  fun <- getExportedValue("kappaSize", kappa_function_name(length(inputs$proportions)))
  props <- if (length(inputs$proportions) == 2) inputs$proportions[2] else inputs$proportions
  fun(kappa0 = inputs$null, kappa1 = inputs$value, props = props, raters = inputs$raters,
    alpha = inputs$alpha, power = power)$N
}

# The power at which kappaSize asks for n subjects. Its sample size rises
# with the power asked for, from 0 at power alpha.
kappa_power <- function(inputs, n) {
  low <- inputs$alpha + 1e-6
  high <- 1 - 1e-9
  if (n <= kappa_size(inputs, low)) return(inputs$alpha)
  if (n >= kappa_size(inputs, high)) return(1)
  stats::uniroot(function(p) kappa_size(inputs, p) - n, c(low, high), tol = 1e-10)$root
}

# Check runs: one large study drawn from the model, recovering its inputs.
reliability_check_run <- function(spec, inputs, seed) {
  n <- check_run_n()
  with_seed(seed %||% 1L, switch(inputs$template,
    icc = reliability_check_icc(inputs, n),
    cronbach_alpha = reliability_check_alpha(inputs, n),
    kappa = reliability_check_kappa(inputs, n)
  ))
}

# Subjects' true scores with variance icc and rating error with variance
# 1 - icc; the one-way ANOVA estimate of the ICC.
reliability_check_icc <- function(inputs, n) {
  k <- inputs$raters
  ratings <- matrix(stats::rnorm(n, sd = sqrt(inputs$value)), n, k) +
    matrix(stats::rnorm(n * k, sd = sqrt(1 - inputs$value)), n, k)
  icc_hat <- one_way_icc(ratings)
  # Large-sample SE of the ICC (Fisher, as in Donner and Eliasziw).
  rho <- inputs$value
  se <- sqrt(2 * (1 - rho)^2 * (1 + (k - 1) * rho)^2 / (k * (k - 1) * (n - 1)))
  data.frame(
    parameter = sprintf("ICC with %d ratings of each subject (one-way ANOVA estimate)", k),
    specified = rho, recovered = icc_hat, ok = abs(icc_hat - rho) < 4 * se
  )
}

one_way_icc <- function(ratings) {
  k <- ncol(ratings)
  n <- nrow(ratings)
  means <- rowMeans(ratings)
  msb <- k * sum((means - mean(ratings))^2) / (n - 1)
  msw <- sum((ratings - means)^2) / (n * (k - 1))
  (msb - msw) / (msb + (k - 1) * msw)
}

# Parallel items: a common true score and independent errors, with the
# item reliability that gives the specified alpha (Spearman-Brown).
reliability_check_alpha <- function(inputs, n) {
  r <- inputs$items
  a <- inputs$value
  item_rel <- a / (r - a * (r - 1))
  items <- matrix(stats::rnorm(n, sd = sqrt(item_rel)), n, r) +
    matrix(stats::rnorm(n * r, sd = sqrt(1 - item_rel)), n, r)
  alpha_hat <- r / (r - 1) * (1 - sum(apply(items, 2, stats::var)) / stats::var(rowSums(items)))
  se_log <- sqrt(2 * r / ((r - 1) * (n - 2)))
  data.frame(
    parameter = sprintf("Cronbach's alpha over %d items", r),
    specified = a, recovered = alpha_hat,
    ok = abs(log(1 - alpha_hat) - log(1 - a)) < 4 * se_log
  )
}

# Ratings from the models kappaSize assumes, so the check run tests the
# population kappaSize plans for: any two raters' kappa is kappa, and the
# chance that all raters agree is kappaSize's too. Two categories
# (PowerBinary()): with probability kappa every rater gives the subject
# the same category, drawn from the proportions, and otherwise each draws
# one independently. Three to five (Power3Cats() to Power5Cats()): a
# Dirichlet-multinomial, each subject's category probabilities drawn from
# a Dirichlet with means the proportions and intraclass correlation kappa,
# and each rater draws from them. For 3 raters, a share p and kappa 0.3,
# all three give that category with probability 0.0656 under the first
# and 0.0501 under the second (upstream-questions.md, kappaSize question
# 1); test-backend-reliability.R checks both against kappaSize's cell
# probabilities. Fleiss' kappa recovers kappa, and the shares of ratings
# the proportions.
reliability_check_kappa <- function(inputs, n) {
  p <- inputs$proportions
  m <- inputs$raters
  cats <- length(p)
  ratings <- reliability_kappa_ratings(n, m, p, inputs$value)
  counts <- vapply(seq_len(cats), function(c) rowSums(ratings == c), numeric(n))
  shares <- colSums(counts) / (n * m)
  observed <- mean((rowSums(counts^2) - m) / (m * (m - 1)))
  expected <- sum(shares^2)
  kappa_hat <- (observed - expected) / (1 - expected)
  se_kappa <- 2 / sqrt(n)
  data.frame(
    parameter = c(sprintf("kappa among %d raters (Fleiss)", m), sprintf("share of ratings in category %d", seq_len(cats))),
    specified = c(inputs$value, p),
    recovered = c(kappa_hat, shares),
    ok = c(abs(kappa_hat - inputs$value) < 4 * se_kappa, abs(shares - p) < 4 * sqrt(p * (1 - p) / n))
  )
}

# n subjects rated by m raters into categories with proportions p, under
# kappaSize's common correlation model (reliability_check_kappa()).
reliability_kappa_ratings <- function(n, m, p, kappa) {
  cats <- length(p)
  if (cats == 2) {
    common <- stats::runif(n) < kappa
    truth <- sample.int(cats, n, replace = TRUE, prob = p)
    return(vapply(seq_len(m), function(j) ifelse(common, truth, sample.int(cats, n, replace = TRUE, prob = p)), integer(n)))
  }
  # Dirichlet draws from gammas: shape p_j (1 - kappa) / kappa.
  shape <- p * (1 - kappa) / kappa
  g <- matrix(stats::rgamma(n * cats, shape = rep(shape, each = n)), n, cats)
  probs <- g / rowSums(g)
  cum <- t(apply(probs, 1, cumsum))
  vapply(seq_len(m), function(j) 1L + as.integer(rowSums(stats::runif(n) > cum[, -cats, drop = FALSE])), integer(n))
}

check_reliability <- function(spec) {
  if (bland_altman_test(spec)) {
    return(check_bland_altman(spec))
  }
  pop <- spec$population
  tt <- spec$target_test
  problems <- character()
  pair <- switch(spec$template,
    icc = list(value = pop$icc, null = pop$icc_null, name = "ICC", paths = c("icc", "icc_null")),
    cronbach_alpha = list(value = pop$reliability, null = pop$reliability_null, name = "Cronbach's alpha",
      paths = c("reliability", "reliability_null")),
    kappa = list(value = pop$kappa, null = pop$kappa_null, name = "kappa", paths = c("kappa", "kappa_null"))
  )
  if (identical(tt$alternative, "greater") && !is.null(pair$value) && !is.null(pair$null) && pair$value < pair$null) {
    problems <- c(problems, sprintf(
      "A one-sided test shows the %s is above 'population > %s', so the %s expected ('population > %s') can't be below it.",
      pair$name, pair$paths[2], pair$name, pair$paths[1]))
  }
  if (identical(spec$template, "kappa")) {
    p <- as.numeric(unlist(pop$proportions))
    levels <- spec$variables$Y$levels
    if (length(p) && abs(sum(p) - 1) > 0.001) {
      problems <- c(problems, "The proportions in each category ('population > proportions') must add up to 1.")
    }
    if (!is.null(levels) && length(p) && length(levels) != length(p)) {
      problems <- c(problems, sprintf(
        "Give one proportion for each of the rating's %d categories ('population > proportions').", length(levels)))
    }
  }
  problems
}

reliability_design_description <- function(spec, label) {
  inputs <- reliability_inputs(spec)
  side <- if (inputs$one_sided) "one-sided" else "two-sided"
  switch(inputs$template,
    icc = sprintf(
      "%s test that the ICC of %s, with %d ratings of each subject, exceeds %s (one-way random-effects model; expected ICC %s)",
      side, label("Y"), inputs$raters, format_number(inputs$null), format_number(inputs$value)),
    cronbach_alpha = sprintf(
      "%s test (Bonett and Wright's) that Cronbach's alpha of %s, over %d items, exceeds %s (expected alpha %s)",
      side, label("Y"), inputs$items, format_number(inputs$null), format_number(inputs$value)),
    kappa = sprintf(
      "two-sided test of agreement on %s among %d raters (%d categories, proportions %s): kappa %s against %s",
      label("Y"), inputs$raters, length(inputs$proportions), paste(format_number(inputs$proportions), collapse = ", "),
      format_number(inputs$value), format_number(inputs$null))
  )
}

# The R script: the same package call at each size powerkit computed.
reliability_script <- function(spec, result) {
  inputs <- reliability_inputs(spec)
  package <- reliability_package(inputs$template, inputs$method)
  body <- switch(inputs$template,
    icc = if (identical(package, "stats")) c(
      sprintf("icc <- %s # the ICC expected", r_code(inputs$value)),
      sprintf("icc_null <- %s # the ICC the study aims to show it exceeds", r_code(inputs$null)),
      sprintf("raters <- %s # ratings of each subject", r_code(inputs$raters)),
      sprintf("one_sided <- %s", r_code(inputs$one_sided)),
      "",
      "# The F test's exact power (Donner and Eliasziw, 1987): in the one-way",
      "# random-effects model MSB / MSW is F1 times a central F with n - 1 and",
      "# n (raters - 1) df, where F = (1 + (raters - 1) ICC) / (1 - ICC); the",
      "# test rejects when MSB / MSW exceeds F0 times the critical value.",
      "power_at <- function(n_total) {",
      "  ratio <- function(rho) (1 + (raters - 1) * rho) / (1 - rho)",
      "  scale <- ratio(icc_null) / ratio(icc)",
      "  df1 <- n_total - 1",
      "  df2 <- n_total * (raters - 1)",
      "  if (one_sided) return(pf(scale * qf(1 - alpha, df1, df2), df1, df2, lower.tail = FALSE))",
      "  pf(scale * qf(1 - alpha / 2, df1, df2), df1, df2, lower.tail = FALSE) + pf(scale * qf(alpha / 2, df1, df2), df1, df2)",
      "}"
    ) else c(
      sprintf("icc <- %s # the ICC expected", r_code(inputs$value)),
      sprintf("icc_null <- %s # the ICC the study aims to show it exceeds", r_code(inputs$null)),
      sprintf("raters <- %s # ratings of each subject", r_code(inputs$raters)),
      sprintf("tails <- %s", r_code(if (inputs$one_sided) 1 else 2)),
      "",
      "power_at <- function(n_total) {",
      "  calculateIccPower(p = icc, p0 = icc_null, k = raters, alpha = alpha, tails = tails, N = n_total)[[1]]$power",
      "}"
    ),
    cronbach_alpha = c(
      sprintf("reliability <- %s # Cronbach's alpha expected", r_code(inputs$value)),
      sprintf("reliability_null <- %s # the alpha the study aims to show it exceeds", r_code(inputs$null)),
      sprintf("items <- %s", r_code(inputs$items)),
      sprintf("one_sided <- %s", r_code(inputs$one_sided)),
      "",
      "# Bonett and Wright's (2015) test of ln(1 - alpha). size.test.cronbach()",
      "# gives the sample size; the same formula solved for power gives the",
      "# power at a given n. A two-sided test also counts the other tail,",
      "# which the sample-size formula leaves out (powerkit's Departure 34).",
      "power_at <- function(n_total) {",
      "  z_a <- qnorm(1 - if (one_sided) alpha else alpha / 2)",
      "  e <- (1 - reliability) / (1 - reliability_null)",
      "  d <- sqrt(max(n_total - 2, 0) * (items - 1) / (2 * items)) * abs(log(e))",
      "  pnorm(d - z_a) + if (one_sided) 0 else pnorm(-d - z_a)",
      "}",
      "# For comparison: statpsych's sample size for 80% power.",
      "size.test.cronbach(if (one_sided) 2 * alpha else alpha, 0.8, reliability, items, reliability_null)"
    ),
    kappa = c(
      sprintf("kappa1 <- %s # the kappa expected", r_code(inputs$value)),
      sprintf("kappa0 <- %s # kappa under the null hypothesis", r_code(inputs$null)),
      sprintf("props <- %s # share of subjects in each category", r_code(if (length(inputs$proportions) == 2) inputs$proportions[2] else inputs$proportions)),
      sprintf("raters <- %s", r_code(inputs$raters)),
      "",
      sprintf("# %s() gives the sample size for a power; the power at n is the", kappa_function_name(length(inputs$proportions))),
      "# power for which it gives n.",
      sprintf("size_at <- function(power) %s(kappa0, kappa1, props, raters = raters, alpha = alpha, power = power)$N",
        kappa_function_name(length(inputs$proportions))),
      "power_at <- function(n_total) {",
      "  if (n_total <= size_at(alpha + 1e-6)) return(alpha)",
      "  if (n_total >= size_at(1 - 1e-9)) return(1)",
      "  uniroot(function(p) size_at(p) - n_total, c(alpha + 1e-6, 1 - 1e-9), tol = 1e-10)$root",
      "}"
    )
  )
  c(
    script_header(spec, result, package, reliability_function(inputs)),
    if (!identical(package, "stats")) c(sprintf("library(%s)", package), ""),
    "# Inputs ----",
    goal_inputs(spec, result),
    body,
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
