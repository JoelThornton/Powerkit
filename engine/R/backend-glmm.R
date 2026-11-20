# Backend adapter: the same people measured more than once with a count or
# a yes/no outcome (mixed_model / repeated_glmm, E75).
#
# Each person gives `measurements` observations in each condition (X a
# within factor: every person in every condition, such as before and after
# a programme) or in their own condition (X a between factor: the people
# split equally between the conditions, each measured several times). The
# analysis is a generalised linear mixed model with a random intercept for
# each person,
#   y ~ cond + (1 | person)
# with cond a factor in treatment coding (each coefficient a condition's
# log rate, or log odds, minus the first condition's):
#
#   count, Poisson     (population > dispersion absent or 0) glmer's
#                      Poisson family, the model built by simr's
#                      makeGlmer() and simulated with powerSim(), as E33
#                      does for yes/no trials (Green & MacLeod, 2016).
#   count, negative    (dispersion k above 0: each count's variance is
#   binomial           mu + k mu^2 given the person, MASS's and lme4's
#                      theta = 1 / k) lme4's glmer.nb(). simr cannot build
#                      or refit a negative binomial model, so Spower runs
#                      the experiment p_repeated_nb(): each person's
#                      intercept drawn from N(0, sd_person^2), each count
#                      from stats::rnbinom(), and the model fitted with
#                      glmer.nb(), theta estimated.
#   yes/no             glmer's binomial family, built by makeGlmer() as for
#                      a count.
#   ordered            (Y categorical, its categories in order) a cumulative
#   categories         link mixed model with the logit link and
#                      proportional odds, the R package ordinal's clmm()
#                      (Christensen; citation("ordinal")), run in a
#                      Spower simulation as for the negative binomial:
#                      logit P(Y <= j) =
#                      theta_j - cond - person. The thresholds theta_j
#                      come from the share of a typical person's answers
#                      in each category in the first condition; each other
#                      condition's coefficient is the log of its odds ratio
#                      of a higher category (above 1: higher categories).
#
# Two or more groups measured more than once (W a between factor, X a
# within factor such as time): every person in every condition of X, the
# people split equally between W's groups, and the model
#   y ~ group * cond + (1 | person)
# whose group-by-condition interaction is tested (does the change over the
# conditions differ between the groups?), by the Wald chi-square test of
# group:cond or the likelihood-ratio test against y ~ group + cond +
# (1 | person). The rates, probabilities or odds ratios are then given one
# row per group, one value per condition; the cells are taken group by
# group (unlist() of the rows).
#
# The rates (or probabilities) are those of a typical person, with random
# intercept 0; sd_person is on the log (or log-odds) scale. The test that
# the conditions differ is the Wald chi-square test of cond (car's Anova(),
# simr's "chisq"; with two conditions the square of glmer's Wald z, the
# same p-value) or the likelihood-ratio test against the model without
# cond (simr's "lr"). A data set whose fit fails counts as not
# significant, as simr counts it.

repeated_glmm_count <- function(spec) identical(spec$variables$Y$type, "count")

repeated_glmm_ordinal <- function(spec) identical(spec$variables$Y$type, "categorical")

repeated_glmm_nb <- function(spec) repeated_glmm_count(spec) && (spec$population$dispersion %||% 0) > 0

# The cells of the design, group by group (each group's conditions in
# order), as factors: the order of the rates, probabilities or odds ratios.
repeated_glmm_cells <- function(levels, groups = NULL) {
  if (is.null(groups)) return(data.frame(cond = factor(levels, levels = levels)))
  cells <- expand.grid(cond = levels, group = groups, stringsAsFactors = FALSE)
  data.frame(group = factor(cells$group, levels = groups), cond = factor(cells$cond, levels = levels))
}

# The model's fixed effects in treatment coding, from each cell's log rate
# (log odds, or log odds ratio of a higher category): the coefficients
# that reproduce the cells exactly (the model is saturated in its fixed
# part), named as glmer() and clmm() name them.
repeated_glmm_fixef <- function(levels, groups, centre) {
  cells <- repeated_glmm_cells(levels, groups)
  x <- stats::model.matrix(if (is.null(groups)) ~cond else ~ group * cond, cells)
  stats::setNames(as.numeric(solve(x, centre)), colnames(x))
}

# Each row's cell, group by group, as repeated_glmm_cells() orders them.
repeated_glmm_cell <- function(data, k) {
  if (is.null(data$group)) as.integer(data$cond) else (as.integer(data$group) - 1L) * k + as.integer(data$cond)
}

repeated_glmm_inputs <- function(spec) {
  pop <- spec$population
  levels <- unlist(spec$variables$X$levels)
  groups <- if (is.null(spec$variables$W)) NULL else unlist(spec$variables$W$levels)
  interaction <- !is.null(groups)
  count <- repeated_glmm_count(spec)
  ordinal <- repeated_glmm_ordinal(spec)
  centre <- if (ordinal) log(as.numeric(unlist(pop$odds_ratios))) else
    if (count) log(as.numeric(unlist(pop$rates))) else stats::qlogis(as.numeric(unlist(pop$probabilities)))
  categories <- if (ordinal) as.numeric(unlist(pop$category_probabilities)) else NULL
  method <- spec$target_test$method %||% "likelihood_ratio"
  nb <- repeated_glmm_nb(spec)
  fixef <- repeated_glmm_fixef(levels, groups, centre)
  list(
    formula = stats::as.formula(if (interaction) "y ~ group * cond + (1 | person)" else "y ~ cond + (1 | person)",
      env = globalenv()),
    groups = groups,
    interaction = interaction,
    term = if (interaction) "group:cond" else "cond",
    df = if (interaction) (length(groups) - 1L) * (length(levels) - 1L) else length(levels) - 1L,
    family = if (count) "poisson" else if (ordinal) "cumulative logit" else "binomial",
    count = count,
    nb = nb,
    ordinal = ordinal,
    binary = !count && !ordinal,
    categories = categories,
    thresholds = if (ordinal) stats::qlogis(cumsum(categories)[-length(categories)]) else NULL,
    dispersion = if (nb) pop$dispersion else 0,
    centre = centre,
    fixef = unname(fixef),
    fixef_names = names(fixef),
    VarCorr = list(person = pop$sd_person^2),
    sd_person = pop$sd_person,
    levels = levels,
    measurements = as.integer(pop$measurements %||% 1L),
    between = identical(spec$variables$X$type, "between_factor"),
    method = method,
    cochran = identical(method, "cochran_q"),
    simr_method = if (identical(method, "likelihood_ratio")) "lr" else "chisq",
    alpha = spec$target_test$alpha,
    design = repeated_glmm_design
  )
}

# One data set's design: each person measured `measurements` times in each
# condition (within), or in their own condition, the people split into
# equal groups in the order of X's levels (between).
repeated_glmm_design <- function(inputs, n) {
  k <- length(inputs$levels)
  if (!is.null(inputs$groups)) {
    # Every person in every condition, the people split equally between
    # the groups in the order of W's levels.
    data <- expand.grid(measurement = seq_len(inputs$measurements), cond = inputs$levels, person = seq_len(n),
      stringsAsFactors = FALSE)
    data$group <- factor(inputs$groups[ceiling(data$person / (n / length(inputs$groups)))], levels = inputs$groups)
    data$person <- factor(data$person)
    data$cond <- factor(data$cond, levels = inputs$levels)
    return(data[, c("person", "group", "cond", "measurement")])
  }
  if (isTRUE(inputs$between)) {
    data <- expand.grid(measurement = seq_len(inputs$measurements), person = seq_len(n))
    data$cond <- inputs$levels[ceiling(data$person / (n / k))]
  } else {
    data <- expand.grid(measurement = seq_len(inputs$measurements), cond = inputs$levels, person = seq_len(n),
      stringsAsFactors = FALSE)
  }
  data$person <- factor(data$person)
  data$cond <- factor(data$cond, levels = inputs$levels)
  data[, c("person", "cond", "measurement")]
}

# An ordered-categories data set: each person's intercept, then each
# answer, its category drawn from the cumulative logits
# P(Y <= j) = plogis(theta_j - centre[cond] - intercept).
repeated_ordinal_data <- function(n, levels, centre, thresholds, sd_person, measurements, between, groups = NULL) {
  data <- repeated_glmm_design(list(levels = levels, measurements = measurements, between = between, groups = groups), n)
  intercepts <- stats::rnorm(n, 0, sd_person)
  eta <- centre[repeated_glmm_cell(data, length(levels))] + intercepts[as.integer(data$person)]
  below <- stats::plogis(outer(-eta, thresholds, "+"))
  data$y <- factor(1L + rowSums(stats::runif(nrow(data)) > below), levels = seq_len(length(thresholds) + 1L), ordered = TRUE)
  data
}

repeated_ordinal_fit <- function(formula, data) {
  tryCatch(suppressMessages(suppressWarnings(ordinal::clmm(formula, data = data, link = "logit"))),
    error = function(e) NULL)
}

# The Wald chi-square test of cond's coefficients in a clmm() fit (with
# two conditions, the square of clmm()'s Wald z), or of the group-by-
# condition interaction's.
repeated_ordinal_wald <- function(fit, k, interaction = FALSE) {
  terms <- if (interaction) grep(":", names(stats::coef(fit)), fixed = TRUE, value = TRUE) else
    utils::tail(names(stats::coef(fit)), k - 1)
  b <- stats::coef(fit)[terms]
  v <- stats::vcov(fit)[terms, terms, drop = FALSE]
  stats::pchisq(as.numeric(t(b) %*% solve(v, b)), df = length(terms), lower.tail = FALSE)
}

# Spower experiment for ordered categories: one study, analysed with
# clmm(); the p-value of the Wald chi-square test of cond or of the
# likelihood-ratio test against the model without it. A data set whose fit
# fails, or with answers in one category only, counts as not significant
# (p = 1).
p_repeated_ordinal <- function(n, levels, centre, thresholds, sd_person, measurements, between, method = "wald",
                               groups = NULL) {
  data <- repeated_ordinal_data(n, levels, centre, thresholds, sd_person, measurements, between, groups)
  if (length(unique(data$y)) < 2) return(1)
  data$y <- droplevels(data$y)
  interaction <- !is.null(groups)
  fit <- repeated_ordinal_fit(if (interaction) y ~ group * cond + (1 | person) else y ~ cond + (1 | person), data)
  if (is.null(fit)) return(1)
  df <- if (interaction) (length(groups) - 1) * (length(levels) - 1) else length(levels) - 1
  p <- if (identical(method, "likelihood_ratio")) {
    reduced <- repeated_ordinal_fit(if (interaction) y ~ group + cond + (1 | person) else y ~ 1 + (1 | person), data)
    if (is.null(reduced)) return(1)
    stats::pchisq(2 * (as.numeric(stats::logLik(fit)) - as.numeric(stats::logLik(reduced))), df = df, lower.tail = FALSE)
  } else {
    tryCatch(repeated_ordinal_wald(fit, length(levels), interaction), error = function(e) NA_real_)
  }
  if (is.finite(p)) p else 1
}

repeated_ordinal_rejections <- function(inputs, n, nrep, seed) {
  args <- list(n = n, levels = inputs$levels, centre = inputs$centre, thresholds = inputs$thresholds,
    sd_person = inputs$sd_person, measurements = inputs$measurements, between = inputs$between,
    method = inputs$method, groups = inputs$groups)
  result <- spower_eval(as.name("p_repeated_ordinal"), args, nrep, inputs$alpha, seed)
  round(result$power * nrep)
}

# A negative binomial data set: each person's intercept, then each count.
repeated_nb_data <- function(n, levels, centre, sd_person, dispersion, measurements, between, groups = NULL) {
  data <- repeated_glmm_design(list(levels = levels, measurements = measurements, between = between, groups = groups), n)
  intercepts <- stats::rnorm(n, 0, sd_person)
  mu <- exp(centre[repeated_glmm_cell(data, length(levels))] + intercepts[as.integer(data$person)])
  data$y <- stats::rnbinom(nrow(data), size = 1 / dispersion, mu = mu)
  data
}

repeated_nb_fit <- function(formula, data) {
  tryCatch(suppressMessages(suppressWarnings(lme4::glmer.nb(formula, data = data))), error = function(e) NULL)
}

# Spower experiment for a negative binomial outcome: one study, analysed
# with glmer.nb(); the p-value of the Wald chi-square test of cond (car's
# Anova()) or of the likelihood-ratio test against the model without it.
# A data set of zeros only, or whose fit fails, counts as not significant
# (p = 1).
p_repeated_nb <- function(n, levels, centre, sd_person, dispersion, measurements, between, method = "wald",
                          groups = NULL) {
  data <- repeated_nb_data(n, levels, centre, sd_person, dispersion, measurements, between, groups)
  if (all(data$y == 0)) return(1)
  interaction <- !is.null(groups)
  fit <- repeated_nb_fit(if (interaction) y ~ group * cond + (1 | person) else y ~ cond + (1 | person), data)
  if (is.null(fit)) return(1)
  df <- if (interaction) (length(groups) - 1) * (length(levels) - 1) else length(levels) - 1
  p <- if (identical(method, "likelihood_ratio")) {
    reduced <- repeated_nb_fit(if (interaction) y ~ group + cond + (1 | person) else y ~ 1 + (1 | person), data)
    if (is.null(reduced)) return(1)
    stats::pchisq(2 * (as.numeric(stats::logLik(fit)) - as.numeric(stats::logLik(reduced))), df = df, lower.tail = FALSE)
  } else {
    tryCatch(car::Anova(fit, type = 2)[if (interaction) "group:cond" else "cond", "Pr(>Chisq)"], error = function(e) NA_real_)
  }
  if (is.finite(p)) p else 1
}

repeated_nb_rejections <- function(inputs, n, nrep, seed) {
  args <- list(n = n, levels = inputs$levels, centre = inputs$centre, sd_person = inputs$sd_person,
    dispersion = inputs$dispersion, measurements = inputs$measurements, between = inputs$between,
    method = inputs$method, groups = inputs$groups)
  result <- spower_eval(as.name("p_repeated_nb"), args, nrep, inputs$alpha, seed)
  round(result$power * nrep)
}

# Cochran's Q (target_test > method "cochran_q"): a yes/no answer given
# once in each of three or more conditions by every person (X within
# people, measurements 1, no groups). The answers are drawn from the same
# model as the logistic mixed model's (each person's intercept from
# N(0, sd_person^2), then each answer with chance plogis(log odds of the
# condition + intercept)), so the chances are a typical person's as on the
# rest of this card, and each simulated study is tested with Cochran's Q.
# On 0/1 data the Friedman test with its correction for ties is
# algebraically Cochran's Q (test-backend-glmm.R checks it against Q's own
# formula), so stats::friedman.test() computes it (its p-value from the chi-square distribution on k - 1 degrees of
# freedom); a study in which nobody's answers vary has no test and counts
# as not significant (p = 1).
repeated_glmm_cochran <- function(spec) identical(spec$target_test$method, "cochran_q")

repeated_cochran_data <- function(n, centre, sd_person) {
  intercepts <- stats::rnorm(n, 0, sd_person)
  chance <- stats::plogis(outer(intercepts, centre, "+"))
  matrix(stats::rbinom(length(chance), 1L, chance), nrow = n)
}

p_repeated_cochran <- function(n, centre, sd_person) {
  answers <- repeated_cochran_data(n, centre, sd_person)
  if (all(apply(answers, 1, stats::var) == 0)) return(1)
  p <- stats::friedman.test(answers)$p.value
  if (is.finite(p)) p else 1
}

repeated_cochran_rejections <- function(inputs, n, nrep, seed) {
  args <- list(n = n, centre = inputs$centre, sd_person = inputs$sd_person)
  result <- spower_eval(as.name("p_repeated_cochran"), args, nrep, inputs$alpha, seed)
  round(result$power * nrep)
}

# The share answering 'yes' in each condition across everyone (over the
# people's intercepts), which the check run compares with the simulated
# shares: a typical person's chance is further from 1/2 than this when
# people differ (sd_person above 0).
repeated_cochran_shares <- function(centre, sd_person) {
  if (sd_person == 0) return(stats::plogis(centre))
  vapply(centre, function(eta) {
    stats::integrate(function(u) stats::plogis(eta + u) * stats::dnorm(u, 0, sd_person), -Inf, Inf)$value
  }, numeric(1))
}

# Check run for Cochran's Q: one large data set (2,000 people) drawn as the
# simulation draws it; each condition's share of 'yes' within 5 of its
# standard errors of the share the model implies.
repeated_cochran_check_run <- function(inputs, seed) {
  n <- 2000L
  answers <- with_seed(seed %||% 1L, repeated_cochran_data(n, inputs$centre, inputs$sd_person))
  expected <- repeated_cochran_shares(inputs$centre, inputs$sd_person)
  check <- check_run_rows(sprintf("share answering 'yes' across everyone, %s", inputs$levels), expected,
    colMeans(answers), sqrt(expected * (1 - expected) / n))
  rownames(check) <- NULL
  check
}

repeated_glmm_test_label <- function(inputs) {
  term <- inputs$term %||% "cond"
  if (isTRUE(inputs$cochran)) {
    return("Spower::Spower(p_repeated_cochran()) (Cochran's Q, by stats::friedman.test() on the 0/1 answers)")
  }
  if (inputs$ordinal) {
    return(sprintf("Spower::Spower(p_repeated_ordinal()) (ordinal::clmm(), %s)",
      if (identical(inputs$method, "likelihood_ratio")) sprintf("the likelihood-ratio test of %s", term) else
        sprintf("the Wald chi-square test of %s", term)))
  }
  if (inputs$nb) {
    return(sprintf("Spower::Spower(p_repeated_nb()) (lme4::glmer.nb(), %s)",
      if (identical(inputs$method, "likelihood_ratio")) sprintf("the likelihood-ratio test of %s", term) else
        sprintf("car::Anova()'s Wald chi-square test of %s", term)))
  }
  sprintf("simr::powerSim() with simr::fixed(\"%s\", \"%s\") (glmer, %s family)", term, inputs$simr_method, inputs$family)
}

repeated_glmm_backend <- function(spec, seed = NULL) {
  inputs <- repeated_glmm_inputs(spec)
  inputs$test <- simr::fixed(inputs$term, inputs$simr_method)
  k <- length(inputs$levels)
  list(
    name = if (inputs$nb || inputs$ordinal || inputs$cochran) "Spower" else "simr",
    packages = if (inputs$cochran) c("Spower", "SimDesign") else if (inputs$ordinal) c("Spower", "SimDesign", "ordinal") else
      if (inputs$nb) c("Spower", "SimDesign", "lme4", "car") else c("simr", "lme4", "car"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = repeated_glmm_test_label(inputs)),
    n_step = if (inputs$interaction) length(inputs$groups) else if (inputs$between) k else 1,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(chunk, chunk_seed) {
        if (inputs$cochran) repeated_cochran_rejections(inputs, n, chunk, chunk_seed) else
          if (inputs$ordinal) repeated_ordinal_rejections(inputs, n, chunk, chunk_seed) else
          if (inputs$nb) repeated_nb_rejections(inputs, n, chunk, chunk_seed) else simr_rejections(inputs, n, chunk, chunk_seed)
      })
    },
    sensitivity = NULL,
    check_run = function() repeated_glmm_check_run(spec, inputs, seed)
  )
}

# Check run: one large data set (2,000 people) drawn as the simulation
# draws them and refitted: each condition's log rate ratio (or log odds
# ratio) with the first within 5 of its standard errors; the SD of the
# person intercepts within 5 of its approximate standard error (as for
# E62: the variance's standard error is the total variance of a person's
# estimated intercept times sqrt(2 / (n - 1))); and for a negative
# binomial outcome the overdispersion k, within 5 of its approximate
# standard error.
repeated_glmm_check_run <- function(spec, inputs, seed) {
  if (inputs$cochran) return(repeated_cochran_check_run(inputs, seed))
  if (inputs$ordinal) return(repeated_ordinal_check_run(inputs, seed))
  n <- 2000L
  k <- length(inputs$levels)
  if (inputs$between) n <- k * ceiling(n / k)
  if (inputs$interaction) n <- length(inputs$groups) * ceiling(n / length(inputs$groups))
  if (inputs$nb) {
    data <- with_seed(seed %||% 1L, repeated_nb_data(n, inputs$levels, inputs$centre, inputs$sd_person,
      inputs$dispersion, inputs$measurements, inputs$between, inputs$groups))
    fit <- call_backend("lme4", repeated_nb_fit(inputs$formula, data))
    if (is.null(fit)) abort_run("The check run's negative binomial mixed model could not be fitted.")
  } else {
    model <- simr_model(inputs, n)
    data <- repeated_glmm_design(inputs, n)
    data$y <- with_seed(seed %||% 1L, stats::simulate(model)[[1]])
    fit <- call_backend("lme4", quietly(lme4::glmer(inputs$formula, data = data, family = inputs$family)))
  }
  coefs <- summary(fit)$coefficients
  names <- inputs$fixef_names[-1]
  scale <- if (inputs$count) "log rate ratio" else "log odds ratio"
  labels <- if (inputs$interaction) repeated_glmm_coef_labels(inputs, scale) else
    sprintf("%s minus %s (%s)", inputs$levels[-1], inputs$levels[1], scale)
  # The noise in one person's estimated intercept, on the model's scale:
  # 1 / mu (+ k for a negative binomial count), or 1 / (p (1 - p)) for
  # yes/no, averaged over the conditions, over the person's observations.
  per_person <- nrow(data) / n
  p <- if (inputs$count) exp(inputs$centre) else stats::plogis(inputs$centre)
  unit <- if (inputs$count) mean(1 / p) + inputs$dispersion else mean(1 / (p * (1 - p)))
  noise <- unit / per_person
  sd_person <- as.data.frame(lme4::VarCorr(fit))$sdcor[1]
  se_var <- (inputs$sd_person^2 + noise) * sqrt(2 / (n - 1))
  rows <- list(
    check_run_rows(labels, inputs$fixef[-1], coefs[names, "Estimate"], coefs[names, "Std. Error"]),
    check_run_rows("SD of person intercepts", inputs$sd_person, sd_person, se_var / (2 * max(inputs$sd_person, 0.05)))
  )
  if (inputs$nb) {
    # k's standard error, from the negative binomial's information for
    # theta at the mean count, delta method to k = 1 / theta; generous (it
    # ignores that the intercepts absorb some of the spread), so a wrong
    # translation (theta given as k, say) is still many SEs out.
    theta <- 1 / inputs$dispersion
    mu <- mean(exp(inputs$centre + inputs$sd_person^2 / 2))
    info_theta <- nrow(data) * (1 / theta^2) * (mu / (mu + theta)) / (2 * theta)
    se_k <- 2 * inputs$dispersion^2 / sqrt(max(info_theta, 1e-12)) + 0.01
    rows <- c(rows, list(check_run_rows("overdispersion k (variance mu + k mu^2)", inputs$dispersion,
      1 / lme4::getME(fit, "glmer.nb.theta"), se_k)))
  }
  check <- do.call(rbind, rows)
  rownames(check) <- NULL
  check
}

# Check run for ordered categories: one large data set (1,000 people;
# clmm() is slower to fit than glmer()) drawn as the simulation draws it
# and refitted with clmm(): each condition's log odds ratio and each
# threshold within 5 of its standard errors, and the SD of the person
# intercepts within 5 of its approximate standard error, as for a count,
# with the noise in a person's estimated intercept bounded by that of the
# most informative split of the categories into two (an ordered outcome
# carries at least the information of any of its yes/no splits).
repeated_ordinal_check_run <- function(inputs, seed) {
  k <- length(inputs$levels)
  n <- if (inputs$between) k * ceiling(1000 / k) else 1000L
  if (inputs$interaction) n <- length(inputs$groups) * ceiling(1000 / length(inputs$groups))
  data <- with_seed(seed %||% 1L, repeated_ordinal_data(n, inputs$levels, inputs$centre, inputs$thresholds,
    inputs$sd_person, inputs$measurements, inputs$between, inputs$groups))
  fit <- call_backend("ordinal", repeated_ordinal_fit(inputs$formula, data))
  if (is.null(fit)) abort_run("The check run's cumulative link mixed model could not be fitted.")
  coefs <- summary(fit)$coefficients
  names <- inputs$fixef_names[-1]
  below <- cumsum(inputs$categories)[-length(inputs$categories)]
  noise <- 1 / max(below * (1 - below)) / (nrow(data) / n)
  sd_person <- as.numeric(attr(ordinal::VarCorr(fit)$person, "stddev"))
  se_var <- (inputs$sd_person^2 + noise) * sqrt(2 / (n - 1))
  cuts <- rownames(coefs)[seq_along(inputs$thresholds)]
  check <- rbind(
    check_run_rows(if (inputs$interaction) repeated_glmm_coef_labels(inputs, "log odds ratio of a higher category") else
      sprintf("%s minus %s (log odds ratio of a higher category)", inputs$levels[-1], inputs$levels[1]),
      inputs$fixef[-1], coefs[names, "Estimate"], coefs[names, "Std. Error"]),
    check_run_rows(sprintf("threshold %s (log odds of category %s or below, first condition)", cuts, seq_along(cuts)),
      inputs$thresholds, coefs[cuts, "Estimate"], coefs[cuts, "Std. Error"]),
    check_run_rows("SD of person intercepts", inputs$sd_person, sd_person, se_var / (2 * max(inputs$sd_person, 0.05)))
  )
  rownames(check) <- NULL
  check
}

# Plain labels for the coefficients of y ~ group * cond in a check run: a
# group's difference from the first group in the first condition, a
# condition's change from the first in the first group, and how much more
# a group changes than the first group (the interaction).
repeated_glmm_coef_labels <- function(inputs, scale) {
  g <- inputs$groups
  x <- inputs$levels
  vapply(inputs$fixef_names[-1], function(name) {
    parts <- strsplit(name, ":", fixed = TRUE)[[1]]
    group <- g[match(sub("^group", "", parts[1]), g)]
    if (length(parts) == 2) {
      cond <- x[match(sub("^cond", "", parts[2]), x)]
      sprintf("change from %s to %s, %s minus %s (%s, interaction)", x[1], cond, group, g[1], scale)
    } else if (startsWith(name, "group")) {
      sprintf("%s minus %s at %s (%s)", group, g[1], x[1], scale)
    } else {
      cond <- x[match(sub("^cond", "", name), x)]
      sprintf("%s minus %s in %s (%s)", cond, x[1], g[1], scale)
    }
  }, character(1), USE.NAMES = FALSE)
}

# For the group-by-condition interaction: W a between factor of two or
# more groups, X within people, and the rows of rates, probabilities or
# odds ratios one per group of the right length.
check_repeated_interaction <- function(spec, field) {
  groups <- unlist(spec$variables$W$levels)
  levels <- unlist(spec$variables$X$levels)
  problems <- character()
  if (!identical(spec$variables$W$type, "between_factor")) {
    problems <- c(problems, "W is the groups the people are in (each person in one group), so its type is 'between_factor'.")
  }
  if (!identical(spec$variables$X$type, "within_factor")) {
    problems <- c(problems, "With groups (W), X is what each person is measured under in turn, such as the occasions, so its type is 'within_factor'.")
  }
  if (!identical(spec$target_test$effect, "interaction")) {
    problems <- c(problems, "With groups (W), the test is the group-by-condition interaction: set 'target_test > effect' to \"interaction\".")
  }
  rows <- spec$population[[field]]
  if (!is.null(rows)) {
    sizes <- vapply(rows, function(r) length(unlist(r)), integer(1))
    if (length(rows) != length(groups) || any(sizes != length(levels))) {
      problems <- c(problems, sprintf("'population > %s' needs one row per group of W (%s), each with one value per condition of X (%s).",
        field, paste(groups, collapse = ", "), paste(levels, collapse = ", ")))
    }
  }
  problems
}

check_repeated_glmm <- function(spec) {
  if (repeated_glmm_cochran(spec)) return(c(check_repeated_cochran(spec), check_repeated_glmm_values(spec)))
  if (repeated_glmm_ordinal(spec)) return(check_repeated_ordinal(spec))
  pop <- spec$population
  levels <- unlist(spec$variables$X$levels)
  k <- length(levels)
  count <- repeated_glmm_count(spec)
  problems <- character()
  values <- if (count) pop$rates else pop$probabilities
  field <- if (count) "rates" else "probabilities"
  other <- if (count) "probabilities" else "rates"
  interaction <- !is.null(spec$variables$W)
  if (interaction) problems <- c(problems, check_repeated_interaction(spec, field))
  if (!interaction && identical(spec$target_test$effect, "interaction")) {
    problems <- c(problems, "The group-by-condition interaction needs the groups: give them as W, a between factor.")
  }
  if (is.null(values)) {
    problems <- c(problems, sprintf("Give 'population > %s', one per condition of X, in the order of its levels (%s).",
      field, paste(levels, collapse = ", ")))
  } else if (!interaction && length(unlist(values)) != k) {
    problems <- c(problems, sprintf("'population > %s' has %d values, but X has %d conditions: give one per condition, in the order of its levels.",
      field, length(unlist(values)), k))
  }
  if (!is.null(pop[[other]])) {
    problems <- c(problems, sprintf("'population > %s' is for a %s outcome; this outcome is %s, so give '%s' and remove '%s'.",
      other, if (count) "yes/no" else "count", if (count) "a count" else "yes/no", field, other))
  }
  if (!count && !is.null(pop$dispersion)) {
    problems <- c(problems, "'population > dispersion' is the overdispersion of a count; a yes/no outcome has none, so remove it.")
  }
  measurements <- pop$measurements %||% 1
  if (identical(spec$variables$X$type, "between_factor") && measurements < 2) {
    problems <- c(problems, paste0(
      "With each person in one condition and measured once, there is nothing to tell people apart from their measurements: ",
      "the random intercept can't be estimated. Set 'population > measurements' to the number of times each person is measured ",
      "(2 or more), or, for one measurement per person, use Poisson or negative binomial regression (or logistic regression for yes/no)."))
  }
  # One yes/no answer per condition: the logistic random-intercept model
  # is identified, but in 4,000 simulated studies a cell its tests gave
  # too many false positives at alpha .05 for a rare answer (10% yes): the
  # likelihood-ratio test 7.6% for the group-by-condition interaction and
  # 8.5% for the conditions alone, and the Wald test up to 6.4% when people
  # differ a lot (validation-log.md, 20 November 2026). So it is refused.
  if (!identical(spec$variables$X$type, "between_factor") && !count && measurements < 2) {
    problems <- c(problems, if (interaction) {
      paste0(
        "With one yes/no answer from each person in each condition, powerkit can't plan a test of whether the groups change ",
        "differently: in simulations the mixed model's tests of that difference found one too often when there was none ",
        "(up to 7.6% of studies at a 5% significance level), and McNemar's test and Cochran's Q compare conditions within one group only. ",
        "Set 'population > measurements' to 2 or more if each person answers several times in each condition.")
    } else {
      paste0(
        "A yes/no outcome answered once in each condition is McNemar's test (two conditions) or Cochran's Q (three or more: ",
        "set 'target_test > method' to \"cochran_q\"), not a mixed model: with one answer per condition the mixed model's tests ",
        "found a difference too often when there was none (up to 8.5% of simulated studies at a 5% significance level). ",
        "Set 'population > measurements' to 2 or more if each person answers several times in each condition.")
    })
  }
  problems
}

# Cochran's Q: yes/no, every person in every one of three or more
# conditions, once each, one group.
check_repeated_cochran <- function(spec) {
  problems <- character()
  if (!identical(spec$variables$Y$type, "binary")) {
    problems <- c(problems, "Cochran's Q is for a yes/no outcome: set Y's type to binary, or choose the likelihood-ratio or Wald test.")
  }
  if (!identical(spec$variables$X$type, "within_factor")) {
    problems <- c(problems, "Cochran's Q compares the same people's answers across the conditions, so X is within people (type 'within_factor').")
  }
  if (!is.null(spec$variables$W)) {
    problems <- c(problems, "Cochran's Q compares one group's answers across the conditions; for groups that change differently, use the likelihood-ratio or Wald test of the mixed model.")
  }
  if (!identical(spec$target_test$effect %||% "condition", "condition")) {
    problems <- c(problems, "Cochran's Q tests whether the conditions differ: set 'target_test > effect' to \"condition\".")
  }
  if ((spec$population$measurements %||% 1) != 1) {
    problems <- c(problems, "Cochran's Q takes one yes/no answer from each person in each condition: set 'population > measurements' to 1, or choose the likelihood-ratio or Wald test for several answers.")
  }
  if (length(unlist(spec$variables$X$levels)) < 3) {
    problems <- c(problems, "With two conditions, Cochran's Q is McNemar's test: use the card for the same people with a yes/no outcome in two conditions (McNemar's test), which computes it exactly.")
  }
  problems
}

# The probabilities for Cochran's Q, checked as for the mixed model.
check_repeated_glmm_values <- function(spec) {
  pop <- spec$population
  levels <- unlist(spec$variables$X$levels)
  problems <- character()
  if (is.null(pop$probabilities)) {
    problems <- c(problems, sprintf("Give 'population > probabilities', one per condition of X, in the order of its levels (%s).",
      paste(levels, collapse = ", ")))
  } else if (length(unlist(pop$probabilities)) != length(levels)) {
    problems <- c(problems, sprintf("'population > probabilities' has %d values, but X has %d conditions: give one per condition, in the order of its levels.",
      length(unlist(pop$probabilities)), length(levels)))
  }
  for (other in intersect(c("rates", "dispersion", "odds_ratios", "category_probabilities"), names(pop))) {
    problems <- c(problems, sprintf("'population > %s' is not used by Cochran's Q, which takes each condition's chance of 'yes'; remove it.", other))
  }
  problems
}

check_repeated_ordinal <- function(spec) {
  pop <- spec$population
  levels <- unlist(spec$variables$X$levels)
  k <- length(levels)
  categories <- unlist(spec$variables$Y$levels)
  problems <- character()
  interaction <- !is.null(spec$variables$W)
  if (interaction) {
    problems <- c(problems, check_repeated_interaction(spec, "odds_ratios"))
    k <- k * length(unlist(spec$variables$W$levels))
  } else if (identical(spec$target_test$effect, "interaction")) {
    problems <- c(problems, "The group-by-condition interaction needs the groups: give them as W, a between factor.")
  }
  for (other in intersect(c("rates", "probabilities", "dispersion"), names(pop))) {
    problems <- c(problems, sprintf("'population > %s' is for a count or yes/no outcome; for ordered categories give 'category_probabilities' and 'odds_ratios', and remove '%s'.",
      other, other))
  }
  shares <- as.numeric(unlist(pop$category_probabilities))
  if (!length(shares)) {
    problems <- c(problems, "Give 'population > category_probabilities': the share of a typical person's answers in each category of Y in the first condition, lowest category first.")
  } else {
    if (length(categories) && length(shares) != length(categories)) {
      problems <- c(problems, sprintf("'population > category_probabilities' has %d values, but Y has %d categories: give one per category, lowest first.",
        length(shares), length(categories)))
    }
    if (abs(sum(shares) - 1) > 1e-6) {
      problems <- c(problems, sprintf("'population > category_probabilities' adds up to %s; the shares of the categories must add up to 1.",
        format_number(signif(sum(shares), 4))))
    }
  }
  if (length(categories) && length(categories) < 3) {
    problems <- c(problems, "Y has two categories: that is a yes/no outcome, so set Y's type to binary and give each condition's chance of 'yes'.")
  }
  ratios <- as.numeric(unlist(pop$odds_ratios))
  if (!length(ratios)) {
    problems <- c(problems, sprintf("Give 'population > odds_ratios': one per condition of X (%s), each condition's odds of a higher category compared with the first, so the first is 1.",
      paste(levels, collapse = ", ")))
  } else if (!interaction && length(ratios) != k) {
    problems <- c(problems, sprintf("'population > odds_ratios' has %d values, but X has %d conditions: give one per condition, the first 1.",
      length(ratios), k))
  } else if (length(ratios) == k && abs(ratios[1] - 1) > 1e-8) {
    problems <- c(problems, sprintf("'population > odds_ratios' starts with %s; the first %s is the one the others are compared with, so its odds ratio is 1.",
      format_number(ratios[1]), if (interaction) "group's first condition" else "condition"))
  }
  if (identical(spec$variables$X$type, "between_factor") && (pop$measurements %||% 1) < 2) {
    problems <- c(problems, paste0(
      "With each person in one condition and answering once, there is nothing to tell people apart from their answers: ",
      "the random intercept can't be estimated. Set 'population > measurements' to the number of times each person answers ",
      "(2 or more), or, for one answer per person, use the card for two groups compared on ordered categories (proportional odds)."))
  }
  problems
}

# The standalone script: simr (Poisson, yes/no) or Spower with glmer.nb()
# (negative binomial), with the same design and test (export_script()).
repeated_glmm_script <- function(spec, result) {
  inputs <- repeated_glmm_inputs(spec)
  if (inputs$cochran) return(repeated_cochran_script(spec, result, inputs))
  pop <- spec$population
  v <- spec$variables
  lr <- identical(inputs$method, "likelihood_ratio")
  int <- inputs$interaction
  full_f <- if (int) "y ~ group * cond + (1 | person)" else "y ~ cond + (1 | person)"
  reduced_f <- if (int) "y ~ group + cond + (1 | person)" else "y ~ 1 + (1 | person)"
  df_code <- if (int) "(length(groups) - 1) * (length(conditions) - 1)" else "length(conditions) - 1"
  cell_code <- if (int) "(as.integer(data$group) - 1) * length(conditions) + as.integer(data$cond)" else "as.integer(data$cond)"
  term <- inputs$term
  n_step <- if (int) length(inputs$groups) else if (inputs$between) length(inputs$levels) else 1
  # With groups, the cells are given one row per group.
  cells_code <- function(name, values, note) {
    if (!int) return(sprintf("%s <- %s # %s", name, r_code(values), note))
    c(sprintf("%s <- matrix(%s, nrow = %d, byrow = TRUE, dimnames = list(groups, conditions))", name, r_code(values), length(inputs$groups)),
      sprintf("# (%s: one row per group)", note))
  }
  header <- if (inputs$ordinal) script_header(spec, result, "Spower", "Spower::Spower, ordinal::clmm") else
    if (inputs$nb) script_header(spec, result, "Spower", "Spower::Spower, lme4::glmer.nb") else
    script_header(spec, result, "simr", repeated_glmm_test_label(inputs))
  values <- if (inputs$ordinal) {
    c(sprintf("category_probabilities <- %s # a typical person's share of answers in each category, first %s, lowest first",
        r_code(inputs$categories), if (int) "group's first condition" else "condition"),
      cells_code("odds_ratios", exp(inputs$centre), if (int) "each cell's odds of a higher category compared with the first group's first condition" else
        "each condition's odds of a higher category compared with the first"))
  } else if (inputs$count) {
    cells_code("rates", as.numeric(unlist(pop$rates)), "each condition's expected count per measurement, for a typical person")
  } else {
    cells_code("probabilities", as.numeric(unlist(pop$probabilities)), "each condition's chance of 'yes', for a typical person")
  }
  wrap <- function(x) if (int) sprintf("as.vector(t(%s))", x) else x
  centre <- if (inputs$ordinal) sprintf("log(%s)", wrap("odds_ratios")) else if (inputs$count) sprintf("log(%s)", wrap("rates")) else
    sprintf("qlogis(%s)", wrap("probabilities"))
  inputs_lines <- c(
    "# Inputs ----",
    sprintf("# The outcome, %s; cond is %s, a factor whose coefficients are each", comment_text(v$Y$label), comment_text(v$X$label)),
    sprintf("# condition's %s minus the first condition's.", if (inputs$ordinal) "log odds of a higher category" else
      if (inputs$count) "log rate" else "log odds"),
    sprintf("conditions <- %s", r_code(inputs$levels)),
    if (int) sprintf("groups <- %s # %s, each person in one group (the people split equally)", r_code(inputs$groups), comment_text(v$W$label)),
    values,
    sprintf("sd_person <- %s # SD of the person intercepts, on the %s scale", r_code(inputs$sd_person),
      if (inputs$count) "log" else "log-odds"),
    if (inputs$ordinal) "thresholds <- qlogis(cumsum(category_probabilities))[-length(category_probabilities)]",
    if (inputs$nb) sprintf("dispersion <- %s # overdispersion k: a count's variance is mu + k mu^2", r_code(inputs$dispersion)),
    sprintf("measurements <- %s # measurements of each person in each condition", r_code(inputs$measurements)),
    if (!int) sprintf("person_design <- %s # %s", r_code(if (inputs$between) "between" else "within"),
      if (inputs$between) "each person in one condition, the people split equally" else "every person in every condition"),
    goal_inputs(spec, result),
    "",
    if (int) c(
      "# Every person in every condition, the people split equally between the groups.",
      "design_for <- function(n_people) {",
      "  data <- expand.grid(measurement = seq_len(measurements), cond = conditions, person = seq_len(n_people),",
      "    stringsAsFactors = FALSE)",
      "  data$group <- factor(groups[ceiling(data$person / (n_people / length(groups)))], levels = groups)",
      "  data$person <- factor(data$person)",
      "  data$cond <- factor(data$cond, levels = conditions)",
      "  data[, c(\"person\", \"group\", \"cond\", \"measurement\")]",
      "}"
    ) else c(
    "design_for <- function(n_people) {",
    "  k <- length(conditions)",
    "  if (person_design == \"between\") {",
    "    data <- expand.grid(measurement = seq_len(measurements), person = seq_len(n_people))",
    "    data$cond <- conditions[ceiling(data$person / (n_people / k))]",
    "  } else {",
    "    data <- expand.grid(measurement = seq_len(measurements), cond = conditions, person = seq_len(n_people),",
    "      stringsAsFactors = FALSE)",
    "  }",
    "  data$person <- factor(data$person)",
    "  data$cond <- factor(data$cond, levels = conditions)",
    "  data[, c(\"person\", \"cond\", \"measurement\")]",
    "}"),
    ""
  )
  if (inputs$ordinal) {
    return(c(
      header,
      "library(Spower)",
      "library(ordinal)",
      "",
      inputs_lines,
      "# One simulated study: each person's intercept, then each answer, its",
      "# category drawn from the cumulative logits P(Y <= j) = plogis(thresholds[j]",
      "# - log odds ratio of the condition - intercept), fitted with clmm();",
      sprintf("# %s. A data set whose fit fails,", if (lr) sprintf("the likelihood-ratio test of %s", term) else sprintf("the Wald chi-square test of %s", term)),
      "# or with every answer in one category, counts as not significant.",
      "fit_clmm <- function(formula, data) {",
      "  tryCatch(suppressMessages(suppressWarnings(clmm(formula, data = data, link = \"logit\"))), error = function(e) NULL)",
      "}",
      "p_repeated_ordinal <- function(n, method) {",
      "  data <- design_for(n)",
      "  intercepts <- rnorm(n, 0, sd_person)",
      sprintf("  eta <- %s[%s] + intercepts[as.integer(data$person)]", centre, cell_code),
      "  below <- plogis(outer(-eta, thresholds, \"+\"))",
      "  data$y <- factor(1L + rowSums(runif(nrow(data)) > below), levels = seq_along(category_probabilities), ordered = TRUE)",
      "  if (length(unique(data$y)) < 2) return(1)",
      "  data$y <- droplevels(data$y)",
      sprintf("  fit <- fit_clmm(%s, data)", full_f),
      "  if (is.null(fit)) return(1)",
      if (lr) c(
        sprintf("  reduced <- fit_clmm(%s, data)", reduced_f),
        "  if (is.null(reduced)) return(1)",
        "  p <- pchisq(2 * (as.numeric(logLik(fit)) - as.numeric(logLik(reduced))),",
        sprintf("    df = %s, lower.tail = FALSE)", df_code)
      ) else c(
        sprintf("  # The Wald chi-square test of %s's coefficients.", term),
        if (int) "  terms <- grep(\":\", names(coef(fit)), fixed = TRUE, value = TRUE)" else
          "  terms <- tail(names(coef(fit)), length(conditions) - 1)",
        "  b <- coef(fit)[terms]",
        "  p <- tryCatch(pchisq(as.numeric(t(b) %*% solve(vcov(fit)[terms, terms, drop = FALSE], b)),",
        sprintf("    df = %s, lower.tail = FALSE), error = function(e) NA_real_)", df_code)
      ),
      "  if (is.finite(p)) p else 1",
      "}",
      "",
      "# One batch: significant results, and studies run.",
      "run_batch <- function(batch_n, batch_replications, batch_seed) {",
      "  set.seed(batch_seed)",
      sprintf("  result <- Spower(p_repeated_ordinal(n = batch_n, method = %s), sig.level = alpha,", r_code(inputs$method)),
      "    replications = batch_replications, parallel = FALSE, verbose = FALSE)",
      "  c(round(result$power * batch_replications), batch_replications)",
      "}",
      "",
      batch_section(result, "Spower()"),
      simulation_goal_section(spec, result, n_step),
      comparison_section()
    ))
  }
  if (inputs$nb) {
    return(c(
      header,
      "library(Spower)",
      "library(lme4)",
      "",
      inputs_lines,
      "# One simulated study: each person's intercept, then each count",
      "# (negative binomial, variance mu + dispersion mu^2), fitted with",
      sprintf("# glmer.nb(); %s. A data set of zeros only, or", if (lr) sprintf("the likelihood-ratio test of %s", term) else sprintf("car's Wald chi-square test of %s", term)),
      "# whose fit fails, counts as not significant.",
      "fit_nb <- function(formula, data) {",
      "  tryCatch(suppressMessages(suppressWarnings(glmer.nb(formula, data = data))), error = function(e) NULL)",
      "}",
      "p_repeated_nb <- function(n, method) {",
      "  data <- design_for(n)",
      "  intercepts <- rnorm(n, 0, sd_person)",
      sprintf("  mu <- exp(%s[%s] + intercepts[as.integer(data$person)])", centre, cell_code),
      "  data$y <- rnbinom(nrow(data), size = 1 / dispersion, mu = mu)",
      "  if (all(data$y == 0)) return(1)",
      sprintf("  fit <- fit_nb(%s, data)", full_f),
      "  if (is.null(fit)) return(1)",
      if (lr) c(
        sprintf("  reduced <- fit_nb(%s, data)", reduced_f),
        "  if (is.null(reduced)) return(1)",
        "  p <- pchisq(2 * (as.numeric(logLik(fit)) - as.numeric(logLik(reduced))),",
        sprintf("    df = %s, lower.tail = FALSE)", df_code)
      ) else
        sprintf("  p <- tryCatch(car::Anova(fit, type = 2)[\"%s\", \"Pr(>Chisq)\"], error = function(e) NA_real_)", term),
      "  if (is.finite(p)) p else 1",
      "}",
      "",
      "# One batch: significant results, and studies run.",
      "run_batch <- function(batch_n, batch_replications, batch_seed) {",
      "  set.seed(batch_seed)",
      sprintf("  result <- Spower(p_repeated_nb(n = batch_n, method = %s), sig.level = alpha,", r_code(inputs$method)),
      "    replications = batch_replications, parallel = FALSE, verbose = FALSE)",
      "  c(round(result$power * batch_replications), batch_replications)",
      "}",
      "",
      batch_section(result, "Spower()"),
      simulation_goal_section(spec, result, n_step),
      comparison_section()
    ))
  }
  c(
    header,
    "library(simr)",
    "",
    inputs_lines,
    if (int) c(
      "# The fixed effects in treatment coding that reproduce every cell.",
      "cells <- expand.grid(cond = conditions, group = groups)",
      "cells$cond <- factor(cells$cond, levels = conditions)",
      "cells$group <- factor(cells$group, levels = groups)",
      sprintf("fixed_effects <- as.numeric(solve(model.matrix(~ group * cond, cells), %s))", centre),
      ""
    ),
    "model_for <- function(n_people) {",
    sprintf("  makeGlmer(%s, family = \"%s\",", full_f, inputs$family),
    if (int) "    fixef = fixed_effects," else sprintf("    fixef = c(%s[1], %s[-1] - %s[1]),", centre, centre, centre),
    "    VarCorr = list(person = sd_person^2), data = design_for(n_people))",
    "}",
    "",
    sprintf("# The test %s: simr's fixed(\"%s\", \"%s\").",
      if (int) "that the groups change differently over the conditions" else "that the conditions differ", term, inputs$simr_method),
    "# simr counts a data set whose fit or test fails as not significant.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    sprintf("  result <- powerSim(model_for(batch_n), test = fixed(\"%s\", \"%s\"),", term, inputs$simr_method),
    "    nsim = batch_replications, alpha = alpha, seed = batch_seed, progress = FALSE)",
    "  c(result$x, result$n)",
    "}",
    "",
    batch_section(result, "powerSim()"),
    simulation_goal_section(spec, result, n_step),
    comparison_section()
  )
}

# The standalone script for Cochran's Q: Spower with the same experiment
# (each person's intercept, then each yes/no answer; Cochran's Q by
# friedman.test() on the person-by-condition table of 0/1 answers).
repeated_cochran_script <- function(spec, result, inputs) {
  v <- spec$variables
  c(
    script_header(spec, result, "Spower", "Spower::Spower, stats::friedman.test"),
    "library(Spower)",
    "",
    "# Inputs ----",
    sprintf("# The outcome, %s, a yes/no answer from every person once in each", comment_text(v$Y$label)),
    sprintf("# condition of %s.", comment_text(v$X$label)),
    sprintf("conditions <- %s", r_code(inputs$levels)),
    sprintf("probabilities <- %s # each condition's chance of 'yes', for a typical person", r_code(as.numeric(unlist(spec$population$probabilities)))),
    sprintf("sd_person <- %s # SD of the person intercepts, on the log-odds scale", r_code(inputs$sd_person)),
    goal_inputs(spec, result),
    "",
    "# One simulated study: each person's intercept, then each answer with",
    "# chance plogis(log odds of the condition + intercept), one row per",
    "# person and one column per condition. On 0/1 answers, friedman.test()",
    "# (with its correction for ties) is Cochran's Q. A study in which",
    "# nobody's answers vary has no test and counts as not significant.",
    "p_repeated_cochran <- function(n) {",
    "  intercepts <- rnorm(n, 0, sd_person)",
    "  chance <- plogis(outer(intercepts, qlogis(probabilities), \"+\"))",
    "  answers <- matrix(rbinom(length(chance), 1, chance), nrow = n, dimnames = list(NULL, conditions))",
    "  if (all(apply(answers, 1, var) == 0)) return(1)",
    "  p <- friedman.test(answers)$p.value",
    "  if (is.finite(p)) p else 1",
    "}",
    "",
    "# One batch: significant results, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  result <- Spower(p_repeated_cochran(n = batch_n), sig.level = alpha,",
    "    replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, 1),
    comparison_section()
  )
}
