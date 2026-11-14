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

repeated_glmm_inputs <- function(spec) {
  pop <- spec$population
  levels <- unlist(spec$variables$X$levels)
  count <- repeated_glmm_count(spec)
  ordinal <- repeated_glmm_ordinal(spec)
  centre <- if (ordinal) log(as.numeric(unlist(pop$odds_ratios))) else
    if (count) log(as.numeric(unlist(pop$rates))) else stats::qlogis(as.numeric(unlist(pop$probabilities)))
  categories <- if (ordinal) as.numeric(unlist(pop$category_probabilities)) else NULL
  method <- spec$target_test$method %||% "likelihood_ratio"
  nb <- repeated_glmm_nb(spec)
  list(
    formula = stats::as.formula("y ~ cond + (1 | person)", env = globalenv()),
    family = if (count) "poisson" else if (ordinal) "cumulative logit" else "binomial",
    count = count,
    nb = nb,
    ordinal = ordinal,
    binary = !count && !ordinal,
    categories = categories,
    thresholds = if (ordinal) stats::qlogis(cumsum(categories)[-length(categories)]) else NULL,
    dispersion = if (nb) pop$dispersion else 0,
    centre = centre,
    fixef = c(centre[1], centre[-1] - centre[1]),
    VarCorr = list(person = pop$sd_person^2),
    sd_person = pop$sd_person,
    levels = levels,
    measurements = as.integer(pop$measurements %||% 1L),
    between = identical(spec$variables$X$type, "between_factor"),
    method = method,
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
repeated_ordinal_data <- function(n, levels, centre, thresholds, sd_person, measurements, between) {
  data <- repeated_glmm_design(list(levels = levels, measurements = measurements, between = between), n)
  intercepts <- stats::rnorm(n, 0, sd_person)
  eta <- centre[as.integer(data$cond)] + intercepts[as.integer(data$person)]
  below <- stats::plogis(outer(-eta, thresholds, "+"))
  data$y <- factor(1L + rowSums(stats::runif(nrow(data)) > below), levels = seq_len(length(thresholds) + 1L), ordered = TRUE)
  data
}

repeated_ordinal_fit <- function(formula, data) {
  tryCatch(suppressMessages(suppressWarnings(ordinal::clmm(formula, data = data, link = "logit"))),
    error = function(e) NULL)
}

# The Wald chi-square test of cond's coefficients in a clmm() fit: with
# two conditions, the square of clmm()'s Wald z.
repeated_ordinal_wald <- function(fit, k) {
  terms <- utils::tail(names(stats::coef(fit)), k - 1)
  b <- stats::coef(fit)[terms]
  v <- stats::vcov(fit)[terms, terms, drop = FALSE]
  stats::pchisq(as.numeric(t(b) %*% solve(v, b)), df = k - 1, lower.tail = FALSE)
}

# Spower experiment for ordered categories: one study, analysed with
# clmm(); the p-value of the Wald chi-square test of cond or of the
# likelihood-ratio test against the model without it. A data set whose fit
# fails, or with answers in one category only, counts as not significant
# (p = 1).
p_repeated_ordinal <- function(n, levels, centre, thresholds, sd_person, measurements, between, method = "wald") {
  data <- repeated_ordinal_data(n, levels, centre, thresholds, sd_person, measurements, between)
  if (length(unique(data$y)) < 2) return(1)
  data$y <- droplevels(data$y)
  fit <- repeated_ordinal_fit(y ~ cond + (1 | person), data)
  if (is.null(fit)) return(1)
  p <- if (identical(method, "likelihood_ratio")) {
    reduced <- repeated_ordinal_fit(y ~ 1 + (1 | person), data)
    if (is.null(reduced)) return(1)
    stats::pchisq(2 * (as.numeric(stats::logLik(fit)) - as.numeric(stats::logLik(reduced))),
      df = length(levels) - 1, lower.tail = FALSE)
  } else {
    tryCatch(repeated_ordinal_wald(fit, length(levels)), error = function(e) NA_real_)
  }
  if (is.finite(p)) p else 1
}

repeated_ordinal_rejections <- function(inputs, n, nrep, seed) {
  args <- list(n = n, levels = inputs$levels, centre = inputs$centre, thresholds = inputs$thresholds,
    sd_person = inputs$sd_person, measurements = inputs$measurements, between = inputs$between,
    method = inputs$method)
  result <- spower_eval(as.name("p_repeated_ordinal"), args, nrep, inputs$alpha, seed)
  round(result$power * nrep)
}

# A negative binomial data set: each person's intercept, then each count.
repeated_nb_data <- function(n, levels, centre, sd_person, dispersion, measurements, between) {
  data <- repeated_glmm_design(list(levels = levels, measurements = measurements, between = between), n)
  intercepts <- stats::rnorm(n, 0, sd_person)
  mu <- exp(centre[as.integer(data$cond)] + intercepts[as.integer(data$person)])
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
p_repeated_nb <- function(n, levels, centre, sd_person, dispersion, measurements, between, method = "wald") {
  data <- repeated_nb_data(n, levels, centre, sd_person, dispersion, measurements, between)
  if (all(data$y == 0)) return(1)
  fit <- repeated_nb_fit(y ~ cond + (1 | person), data)
  if (is.null(fit)) return(1)
  p <- if (identical(method, "likelihood_ratio")) {
    reduced <- repeated_nb_fit(y ~ 1 + (1 | person), data)
    if (is.null(reduced)) return(1)
    stats::pchisq(2 * (as.numeric(stats::logLik(fit)) - as.numeric(stats::logLik(reduced))),
      df = length(levels) - 1, lower.tail = FALSE)
  } else {
    tryCatch(car::Anova(fit, type = 2)["cond", "Pr(>Chisq)"], error = function(e) NA_real_)
  }
  if (is.finite(p)) p else 1
}

repeated_nb_rejections <- function(inputs, n, nrep, seed) {
  args <- list(n = n, levels = inputs$levels, centre = inputs$centre, sd_person = inputs$sd_person,
    dispersion = inputs$dispersion, measurements = inputs$measurements, between = inputs$between,
    method = inputs$method)
  result <- spower_eval(as.name("p_repeated_nb"), args, nrep, inputs$alpha, seed)
  round(result$power * nrep)
}

repeated_glmm_test_label <- function(inputs) {
  if (inputs$ordinal) {
    return(sprintf("Spower::Spower(p_repeated_ordinal()) (ordinal::clmm(), %s)",
      if (identical(inputs$method, "likelihood_ratio")) "the likelihood-ratio test of cond" else
        "the Wald chi-square test of cond"))
  }
  if (inputs$nb) {
    return(sprintf("Spower::Spower(p_repeated_nb()) (lme4::glmer.nb(), %s)",
      if (identical(inputs$method, "likelihood_ratio")) "the likelihood-ratio test of cond" else
        "car::Anova()'s Wald chi-square test of cond"))
  }
  sprintf("simr::powerSim() with simr::fixed(\"cond\", \"%s\") (glmer, %s family)", inputs$simr_method, inputs$family)
}

repeated_glmm_backend <- function(spec, seed = NULL) {
  inputs <- repeated_glmm_inputs(spec)
  inputs$test <- simr::fixed("cond", inputs$simr_method)
  k <- length(inputs$levels)
  list(
    name = if (inputs$nb || inputs$ordinal) "Spower" else "simr",
    packages = if (inputs$ordinal) c("Spower", "SimDesign", "ordinal") else
      if (inputs$nb) c("Spower", "SimDesign", "lme4", "car") else c("simr", "lme4", "car"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = repeated_glmm_test_label(inputs)),
    n_step = if (inputs$between) k else 1,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(chunk, chunk_seed) {
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
  if (inputs$ordinal) return(repeated_ordinal_check_run(inputs, seed))
  n <- 2000L
  k <- length(inputs$levels)
  if (inputs$between) n <- k * ceiling(n / k)
  if (inputs$nb) {
    data <- with_seed(seed %||% 1L, repeated_nb_data(n, inputs$levels, inputs$centre, inputs$sd_person,
      inputs$dispersion, inputs$measurements, inputs$between))
    fit <- call_backend("lme4", repeated_nb_fit(inputs$formula, data))
    if (is.null(fit)) abort_run("The check run's negative binomial mixed model could not be fitted.")
  } else {
    model <- simr_model(inputs, n)
    data <- repeated_glmm_design(inputs, n)
    data$y <- with_seed(seed %||% 1L, stats::simulate(model)[[1]])
    fit <- call_backend("lme4", quietly(lme4::glmer(inputs$formula, data = data, family = inputs$family)))
  }
  coefs <- summary(fit)$coefficients
  names <- paste0("cond", inputs$levels[-1])
  scale <- if (inputs$count) "log rate ratio" else "log odds ratio"
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
    check_run_rows(sprintf("%s minus %s (%s)", inputs$levels[-1], inputs$levels[1], scale), inputs$fixef[-1],
      coefs[names, "Estimate"], coefs[names, "Std. Error"]),
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
  data <- with_seed(seed %||% 1L, repeated_ordinal_data(n, inputs$levels, inputs$centre, inputs$thresholds,
    inputs$sd_person, inputs$measurements, inputs$between))
  fit <- call_backend("ordinal", repeated_ordinal_fit(inputs$formula, data))
  if (is.null(fit)) abort_run("The check run's cumulative link mixed model could not be fitted.")
  coefs <- summary(fit)$coefficients
  names <- paste0("cond", inputs$levels[-1])
  below <- cumsum(inputs$categories)[-length(inputs$categories)]
  noise <- 1 / max(below * (1 - below)) / (nrow(data) / n)
  sd_person <- as.numeric(attr(ordinal::VarCorr(fit)$person, "stddev"))
  se_var <- (inputs$sd_person^2 + noise) * sqrt(2 / (n - 1))
  cuts <- rownames(coefs)[seq_along(inputs$thresholds)]
  check <- rbind(
    check_run_rows(sprintf("%s minus %s (log odds ratio of a higher category)", inputs$levels[-1], inputs$levels[1]),
      inputs$centre[-1], coefs[names, "Estimate"], coefs[names, "Std. Error"]),
    check_run_rows(sprintf("threshold %s (log odds of category %s or below, first condition)", cuts, seq_along(cuts)),
      inputs$thresholds, coefs[cuts, "Estimate"], coefs[cuts, "Std. Error"]),
    check_run_rows("SD of person intercepts", inputs$sd_person, sd_person, se_var / (2 * max(inputs$sd_person, 0.05)))
  )
  rownames(check) <- NULL
  check
}

check_repeated_glmm <- function(spec) {
  if (repeated_glmm_ordinal(spec)) return(check_repeated_ordinal(spec))
  pop <- spec$population
  levels <- unlist(spec$variables$X$levels)
  k <- length(levels)
  count <- repeated_glmm_count(spec)
  problems <- character()
  values <- if (count) pop$rates else pop$probabilities
  field <- if (count) "rates" else "probabilities"
  other <- if (count) "probabilities" else "rates"
  if (is.null(values)) {
    problems <- c(problems, sprintf("Give 'population > %s', one per condition of X, in the order of its levels (%s).",
      field, paste(levels, collapse = ", ")))
  } else if (length(unlist(values)) != k) {
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
  if (!identical(spec$variables$X$type, "between_factor") && !count && measurements < 2) {
    problems <- c(problems, paste0(
      "A yes/no outcome measured once in each condition is McNemar's test (two conditions) or Cochran's Q (three or more), ",
      "not a mixed model, whose person SD can't be estimated from one yes/no answer per condition. ",
      "Set 'population > measurements' to 2 or more if each person answers several times in each condition."))
  }
  problems
}

check_repeated_ordinal <- function(spec) {
  pop <- spec$population
  levels <- unlist(spec$variables$X$levels)
  k <- length(levels)
  categories <- unlist(spec$variables$Y$levels)
  problems <- character()
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
  } else if (length(ratios) != k) {
    problems <- c(problems, sprintf("'population > odds_ratios' has %d values, but X has %d conditions: give one per condition, the first 1.",
      length(ratios), k))
  } else if (abs(ratios[1] - 1) > 1e-8) {
    problems <- c(problems, sprintf("'population > odds_ratios' starts with %s; the first condition is the one the others are compared with, so its odds ratio is 1.",
      format_number(ratios[1])))
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
  pop <- spec$population
  v <- spec$variables
  lr <- identical(inputs$method, "likelihood_ratio")
  header <- if (inputs$ordinal) script_header(spec, result, "Spower", "Spower::Spower, ordinal::clmm") else
    if (inputs$nb) script_header(spec, result, "Spower", "Spower::Spower, lme4::glmer.nb") else
    script_header(spec, result, "simr", repeated_glmm_test_label(inputs))
  values <- if (inputs$ordinal) {
    c(sprintf("category_probabilities <- %s # a typical person's share of answers in each category, first condition, lowest first",
        r_code(inputs$categories)),
      sprintf("odds_ratios <- %s # each condition's odds of a higher category compared with the first", r_code(exp(inputs$centre))))
  } else if (inputs$count) {
    sprintf("rates <- %s # each condition's expected count per measurement, for a typical person", r_code(as.numeric(unlist(pop$rates))))
  } else {
    sprintf("probabilities <- %s # each condition's chance of 'yes', for a typical person", r_code(as.numeric(unlist(pop$probabilities))))
  }
  centre <- if (inputs$ordinal) "log(odds_ratios)" else if (inputs$count) "log(rates)" else "qlogis(probabilities)"
  inputs_lines <- c(
    "# Inputs ----",
    sprintf("# The outcome, %s; cond is %s, a factor whose coefficients are each", comment_text(v$Y$label), comment_text(v$X$label)),
    sprintf("# condition's %s minus the first condition's.", if (inputs$ordinal) "log odds of a higher category" else
      if (inputs$count) "log rate" else "log odds"),
    sprintf("conditions <- %s", r_code(inputs$levels)),
    values,
    sprintf("sd_person <- %s # SD of the person intercepts, on the %s scale", r_code(inputs$sd_person),
      if (inputs$count) "log" else "log-odds"),
    if (inputs$ordinal) "thresholds <- qlogis(cumsum(category_probabilities))[-length(category_probabilities)]",
    if (inputs$nb) sprintf("dispersion <- %s # overdispersion k: a count's variance is mu + k mu^2", r_code(inputs$dispersion)),
    sprintf("measurements <- %s # measurements of each person in each condition", r_code(inputs$measurements)),
    sprintf("person_design <- %s # %s", r_code(if (inputs$between) "between" else "within"),
      if (inputs$between) "each person in one condition, the people split equally" else "every person in every condition"),
    goal_inputs(spec, result),
    "",
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
    "}",
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
      sprintf("# %s. A data set whose fit fails,", if (lr) "the likelihood-ratio test of cond" else "the Wald chi-square test of cond"),
      "# or with every answer in one category, counts as not significant.",
      "fit_clmm <- function(formula, data) {",
      "  tryCatch(suppressMessages(suppressWarnings(clmm(formula, data = data, link = \"logit\"))), error = function(e) NULL)",
      "}",
      "p_repeated_ordinal <- function(n, method) {",
      "  data <- design_for(n)",
      "  intercepts <- rnorm(n, 0, sd_person)",
      sprintf("  eta <- %s[as.integer(data$cond)] + intercepts[as.integer(data$person)]", centre),
      "  below <- plogis(outer(-eta, thresholds, \"+\"))",
      "  data$y <- factor(1L + rowSums(runif(nrow(data)) > below), levels = seq_along(category_probabilities), ordered = TRUE)",
      "  if (length(unique(data$y)) < 2) return(1)",
      "  data$y <- droplevels(data$y)",
      "  fit <- fit_clmm(y ~ cond + (1 | person), data)",
      "  if (is.null(fit)) return(1)",
      if (lr) c(
        "  reduced <- fit_clmm(y ~ 1 + (1 | person), data)",
        "  if (is.null(reduced)) return(1)",
        "  p <- pchisq(2 * (as.numeric(logLik(fit)) - as.numeric(logLik(reduced))),",
        "    df = length(conditions) - 1, lower.tail = FALSE)"
      ) else c(
        "  # The Wald chi-square test of cond's coefficients.",
        "  terms <- tail(names(coef(fit)), length(conditions) - 1)",
        "  b <- coef(fit)[terms]",
        "  p <- tryCatch(pchisq(as.numeric(t(b) %*% solve(vcov(fit)[terms, terms, drop = FALSE], b)),",
        "    df = length(conditions) - 1, lower.tail = FALSE), error = function(e) NA_real_)"
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
      simulation_goal_section(spec, result, if (inputs$between) length(inputs$levels) else 1),
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
      sprintf("# glmer.nb(); %s. A data set of zeros only, or", if (lr) "the likelihood-ratio test of cond" else "car's Wald chi-square test of cond"),
      "# whose fit fails, counts as not significant.",
      "fit_nb <- function(formula, data) {",
      "  tryCatch(suppressMessages(suppressWarnings(glmer.nb(formula, data = data))), error = function(e) NULL)",
      "}",
      "p_repeated_nb <- function(n, method) {",
      "  data <- design_for(n)",
      "  intercepts <- rnorm(n, 0, sd_person)",
      sprintf("  mu <- exp(%s[as.integer(data$cond)] + intercepts[as.integer(data$person)])", centre),
      "  data$y <- rnbinom(nrow(data), size = 1 / dispersion, mu = mu)",
      "  if (all(data$y == 0)) return(1)",
      "  fit <- fit_nb(y ~ cond + (1 | person), data)",
      "  if (is.null(fit)) return(1)",
      if (lr) c(
        "  reduced <- fit_nb(y ~ 1 + (1 | person), data)",
        "  if (is.null(reduced)) return(1)",
        "  p <- pchisq(2 * (as.numeric(logLik(fit)) - as.numeric(logLik(reduced))),",
        "    df = length(conditions) - 1, lower.tail = FALSE)"
      ) else
        "  p <- tryCatch(car::Anova(fit, type = 2)[\"cond\", \"Pr(>Chisq)\"], error = function(e) NA_real_)",
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
      simulation_goal_section(spec, result, if (inputs$between) length(inputs$levels) else 1),
      comparison_section()
    ))
  }
  c(
    header,
    "library(simr)",
    "",
    inputs_lines,
    "model_for <- function(n_people) {",
    sprintf("  makeGlmer(y ~ cond + (1 | person), family = \"%s\",", inputs$family),
    sprintf("    fixef = c(%s[1], %s[-1] - %s[1]),", centre, centre, centre),
    "    VarCorr = list(person = sd_person^2), data = design_for(n_people))",
    "}",
    "",
    sprintf("# The test that the conditions differ: simr's fixed(\"cond\", \"%s\").", inputs$simr_method),
    "# simr counts a data set whose fit or test fails as not significant.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    sprintf("  result <- powerSim(model_for(batch_n), test = fixed(\"cond\", \"%s\"),", inputs$simr_method),
    "    nsim = batch_replications, alpha = alpha, seed = batch_seed, progress = FALSE)",
    "  c(result$x, result$n)",
    "}",
    "",
    batch_section(result, "powerSim()"),
    simulation_goal_section(spec, result, if (inputs$between) length(inputs$levels) else 1),
    comparison_section()
  )
}
