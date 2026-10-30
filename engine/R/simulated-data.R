# A simulated data set: one sample of n participants drawn from the
# population a spec describes, by the same generator the backend uses
# (Spower's gen_*() functions, Superpower's ANOVA_design(),
# InteractionPoweR's generate_interaction() and power4mome's power4test()),
# or, where the backend has no generator, from the same population by base
# R's draws (one proportion, rank tests, factorial logistic regression,
# ordinal outcomes with Hmisc::pomodm() for the second group's shares,
# one-predictor logistic and Poisson regression, and cluster trials).
# It is for writing and checking analysis code before the real data
# arrive, never evidence or a pilot. The data are built by R code that
# simulated_data_code() writes; simulated_data() runs that code and the R
# script (simulated_data_section()) prints it, so both give the same data
# for the same seed. Every row is marked as simulated, in the first column.

#' A simulated data set for a design
#'
#' Draws one data set of `n` participants from the population in a
#' design specification, with the generator the power analysis uses. It
#' is for writing and checking the analysis code (in R, SPSS, JASP,
#' jamovi or Python) before the real data arrive: it is not evidence, not
#' a pilot, and not a substitute for the analysis plan. The first column,
#' `SIMULATED_NOT_REAL_DATA`, marks every row as simulated, and the
#' columns are named after the variables' labels.
#'
#' Available for the basic tests of means, correlations, proportions,
#' variances, goodness of fit and cross-tabulations (not McNemar's test),
#' the rank tests, equivalence and non-inferiority tests, the ANOVA designs
#' on Superpower and Welch's one-way ANOVA, regression interactions,
#' mediation and moderated mediation, factorial logistic regression,
#' ordinal outcomes in two groups, planned contrasts, logistic and Poisson
#' regression with one predictor (no other predictors) and cluster trials
#' with a score outcome (cluster-randomised and group treatment); `simulated_data_available()` says
#' whether a spec is covered.
#'
#' @param spec A design specification (see [read_spec()]).
#' @param n Total sample size.
#' @param seed Random seed (1 if missing); the same seed gives the same
#'   data, here and in the R script from [export_script()].
#' @param file Optional path; if given, the data are written there as CSV.
#' @return A data frame (invisibly when `file` is given).
#' @export
simulated_data <- function(spec, n, seed = 1, file = NULL) {
  spec <- validate_spec(spec)
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 1) {
    abort_run("'n' should be a single positive number of participants.")
  }
  if (!is.numeric(seed) || length(seed) != 1 || is.na(seed)) {
    seed <- 1
  }
  code <- simulated_data_code(spec, as.integer(ceiling(n)), seed)
  if (is.null(code)) {
    abort_not_available("A simulated data set isn't available for this design yet.")
  }
  env <- new.env(parent = baseenv())
  call_backend("The data generator", with_seed(seed, quietly(
    eval(parse(text = code), envir = env)
  )))
  data <- env$simulated
  if (is.null(file)) {
    return(data)
  }
  utils::write.csv(data, file, row.names = FALSE, fileEncoding = "UTF-8")
  invisible(data)
}

#' @rdname simulated_data
#' @export
simulated_data_available <- function(spec) {
  spec <- validate_spec(spec)
  !is.null(simulated_data_code(spec, 100L, 1L))
}

# R code that builds `simulated` (a data frame) from the spec's
# population, or NULL when the design has no generator here yet. The code
# names its packages (pkg::fun) so it runs without powerkit.
simulated_data_code <- function(spec, n, seed) {
  superpower <- c(
    "oneway_between", "oneway_within", "2x2_between", "2x2_mixed", "mixed",
    "factorial_between", "factorial_within", "factorial_three"
  )
  body <- if (rank_test(spec)) sim_rank_code(spec, n) else switch(
    spec$design,
    basic_test = sim_basic_code(spec, n) %||% sim_more_basic_code(spec, n),
    equivalence_test = sim_equivalence_code(spec, n),
    logistic_regression = if (identical(spec$template, "factorial")) sim_logistic_factorial_code(spec, n) else sim_glm_code(spec, n),
    ordinal_regression = sim_ordinal_code(spec, n),
    mixed_model = sim_mixed_code(spec, n),
    poisson_regression = sim_glm_code(spec, n),
    cluster_trial = sim_cluster_code(spec, n),
    factorial_anova = if (welch_anova(spec)) {
      sim_basic_code(spec, n)
    } else if (spec$template %in% superpower) {
      sim_superpower_code(spec, n)
    } else if (identical(spec$template, "oneway_contrast")) {
      sim_contrast_code(spec, n)
    },
    regression_interaction = if (identical(spec$template, "two_way")) sim_interaction_code(spec, n),
    mediation = ,
    moderated_mediation = sim_power4mome_code(spec, n, seed),
    NULL
  )
  if (is.null(body)) {
    return(NULL)
  }
  c(
    body,
    "simulated <- data.frame(",
    "  SIMULATED_NOT_REAL_DATA = \"simulated by powerkit\",",
    # Long data (one row per trial) number their participants themselves.
    if (!identical(spec$design, "mixed_model")) "  participant = seq_len(nrow(simulated)),",
    "  simulated, check.names = FALSE, row.names = NULL",
    ")"
  )
}

# A column name that SPSS, JASP, jamovi, Python and R all accept: letters,
# digits and underscores, starting with a letter, at most 60 characters.
csv_name <- function(x) {
  x <- gsub("^_+|_+$", "", gsub("[^A-Za-z0-9]+", "_", as.character(x)))
  x <- ifelse(nzchar(x) & grepl("^[A-Za-z]", x), x, paste0("v_", x))
  substr(x, 1, 60)
}

sim_label <- function(spec, role) csv_name(spec$variables[[role]]$label %||% role)

sim_levels <- function(spec, role) {
  levels <- as.character(unlist(spec$variables[[role]]$levels))
  if (length(levels)) levels else paste0(role, seq_len(2))
}

# One "name = value" argument line per element, for a call in the code.
sim_args <- function(args) {
  values <- vapply(args, r_code, character(1))
  paste0("  ", names(args), " = ", values, c(rep(",", length(values) - 1), ""))
}

# Basic tests and Welch's ANOVA, from Spower's generators with the
# arguments the backend passes (spower_inputs()), reshaped to one row per
# participant. Scores are in SD units, as Spower draws them.
sim_basic_code <- function(spec, n) {
  templates <- c(
    "one_sample_t", "independent_t", "paired_t", "correlation", "two_proportions",
    "chi_square_independence", "one_variance", "two_variances", "paired_variances",
    "oneway_between"
  )
  if (!spec$template %in% templates) {
    return(NULL)
  }
  pop <- spec$population
  if (spec$template == "paired_variances") {
    # The paired scores themselves (pitman_morgan_scores() before it takes
    # their sum and difference).
    levels <- sim_levels(spec, "X")
    return(c(
      sprintf("z1 <- stats::rnorm(%d)", n),
      sprintf("z2 <- %s * z1 + sqrt(1 - %s^2) * stats::rnorm(%d)", r_code(pop$r), r_code(pop$r), n),
      "simulated <- data.frame(",
      sprintf("  %s = sqrt(%s) * z1,", csv_name(paste(sim_label(spec, "Y"), levels[1])), r_code(pop$var1)),
      sprintf("  %s = sqrt(%s) * z2", csv_name(paste(sim_label(spec, "Y"), levels[2])), r_code(pop$var2)),
      ")"
    ))
  }
  inputs <- spower_inputs(spec)
  args <- inputs$args(n)
  args <- args[setdiff(names(args), c("var.equal", "correct", "method"))]
  call <- c(sprintf("sim <- Spower::%s(", inputs$generator), sim_args(args), ")")
  y <- sim_label(spec, "Y")
  tidy <- switch(
    spec$template,
    one_sample_t = sprintf("simulated <- data.frame(%s = sim[[1]])", y),
    one_variance = sprintf("simulated <- data.frame(%s = sim$DV)", y),
    independent_t = c(
      "simulated <- data.frame(",
      sprintf("  %s = rep(%s, lengths(sim)),", sim_label(spec, "X"), r_code(sim_levels(spec, "X"))),
      sprintf("  %s = unlist(sim, use.names = FALSE)", y),
      ")"
    ),
    paired_t = c(
      "simulated <- data.frame(",
      sprintf("  %s = sim[[1]],", csv_name(paste(y, sim_levels(spec, "X")[1]))),
      sprintf("  %s = sim[[2]]", csv_name(paste(y, sim_levels(spec, "X")[2]))),
      ")"
    ),
    correlation = sprintf("simulated <- data.frame(%s = sim[, 1], %s = sim[, 2])", sim_label(spec, "X"), y),
    # gen_prop.test() returns counts: "yes" (the second level of Y) in row
    # 1 and the group sizes in row 2; one row per participant, in random
    # order within each group.
    two_proportions = c(
      "simulated <- data.frame(",
      sprintf("  %s = rep(%s, sim[2, ]),", sim_label(spec, "X"), r_code(sim_levels(spec, "X"))),
      sprintf(
        "  %s = unlist(lapply(1:2, function(g) sample(rep(%s, c(sim[1, g], sim[2, g] - sim[1, g])))))",
        y, r_code(rev(sim_levels(spec, "Y")))
      ),
      ")"
    ),
    # gen_chisq.test() returns the table of counts, X's levels in rows.
    chi_square_independence = c(
      sprintf(
        "cells <- expand.grid(%s = %s, %s = %s, stringsAsFactors = FALSE)",
        sim_label(spec, "X"), r_code(sim_levels(spec, "X")), y, r_code(sim_levels(spec, "Y"))
      ),
      "simulated <- cells[sample(rep(seq_len(nrow(cells)), as.vector(sim))), ]"
    ),
    two_variances = sprintf(
      "simulated <- data.frame(%s = %s[match(sim$group, c(\"G1\", \"G2\"))], %s = sim$DV)",
      sim_label(spec, "G"), r_code(sim_levels(spec, "G")), y
    ),
    oneway_between = sprintf(
      "simulated <- data.frame(%s = %s[as.integer(sim$group)], %s = sim$DV)",
      sim_label(spec, "A"), r_code(sim_levels(spec, "A")), y
    )
  )
  c(call, tidy)
}

# The groups of a two-group design: group 1's size and group 2's, from the
# total n and the allocation ratio n2 / n1.
sim_two_groups <- function(spec, n) {
  ratio <- spec$options$allocation_ratio %||% 1
  n1 <- round(n / (1 + ratio))
  c(n1, n - n1)
}

# Basic tests with no Spower experiment in powerkit: one proportion (base
# R's binomial draws), goodness of fit (Spower's gen_chisq.test() with one
# row of probabilities), two independent correlations (Spower's gen_r() in
# each group) and two dependent correlations (Spower's gen_2r() with the
# correlation matrix the spec gives). McNemar's test isn't covered: the
# spec gives only the two discordant proportions, not how the concordant
# pairs split. Scores are in SD units.
sim_more_basic_code <- function(spec, n) {
  pop <- spec$population
  y <- sim_label(spec, "Y")
  switch(
    spec$template,
    one_proportion = {
      levels <- sim_levels(spec, "Y")
      sprintf(
        "simulated <- data.frame(%s = %s[stats::rbinom(%d, 1, %s) + 1])",
        y, r_code(levels), n, r_code(pop$p)
      )
    },
    chi_square_gof = c(
      sprintf("counts <- Spower::gen_chisq.test(%d, P = %s)", n, r_code(as.numeric(unlist(pop$probabilities)))),
      sprintf("simulated <- data.frame(%s = sample(rep(%s, counts)))", y, r_code(sim_levels(spec, "Y")))
    ),
    two_correlations = {
      groups <- sim_two_groups(spec, n)
      c(
        sprintf("sim1 <- Spower::gen_r(%d, r = %s)", groups[1], r_code(pop$r1)),
        sprintf("sim2 <- Spower::gen_r(%d, r = %s)", groups[2], r_code(pop$r2)),
        "simulated <- data.frame(",
        sprintf("  %s = rep(%s, %s),", sim_label(spec, "G"), r_code(sim_levels(spec, "G")), r_code(groups)),
        sprintf("  %s = c(sim1[, 1], sim2[, 1]),", sim_label(spec, "X")),
        sprintf("  %s = c(sim1[, 2], sim2[, 2])", y),
        ")"
      )
    },
    overlapping_correlations = ,
    nonoverlapping_correlations = {
      roles <- if (spec$template == "overlapping_correlations") c("X", "Y", "Z") else c("X1", "Y1", "X2", "Y2")
      pairs <- utils::combn(roles, 2)
      R <- diag(length(roles))
      for (k in seq_len(ncol(pairs))) {
        i <- match(pairs[1, k], roles)
        j <- match(pairs[2, k], roles)
        value <- pop[[sprintf("r_%s_%s", pairs[1, k], pairs[2, k])]] %||% pop[[sprintf("r_%s_%s", pairs[2, k], pairs[1, k])]]
        R[i, j] <- R[j, i] <- value
      }
      c(
        sprintf("R <- matrix(%s, nrow = %d) # correlations of %s, in that order", r_code(as.vector(R)), length(roles), paste(roles, collapse = ", ")),
        sprintf("sim <- Spower::gen_2r(%d, R)", n),
        "simulated <- data.frame(",
        paste0(
          "  ", vapply(roles, function(v) sim_label(spec, v), character(1)), " = sim[, ", seq_along(roles), "]",
          c(rep(",", length(roles) - 1), "")
        ),
        ")"
      )
    },
    NULL
  )
}

# Equivalence and non-inferiority tests: the data are those of the test
# the bound or margin is put on (the t-test, two proportions or a
# correlation), drawn as for that test. Effects in the outcome's own units
# have already been put in SD units by validate_spec().
sim_equivalence_code <- function(spec, n) {
  pop <- spec$population
  twin <- spec
  twin$design <- "basic_test"
  twin$target_test <- list(alpha = spec$target_test$alpha)
  switch(
    spec$template,
    tost_one_sample = ,
    noninf_one_sample = {
      twin$template <- "one_sample_t"
      twin$population <- list(d = pop$d)
    },
    tost_independent = ,
    noninf_independent = {
      twin$template <- "independent_t"
      twin$population <- list(d = pop$d)
      twin$target_test$method <- "student_t"
    },
    tost_paired = ,
    noninf_paired = {
      twin$template <- "paired_t"
      twin$population <- list(dz = pop$dz)
    },
    tost_two_proportions = ,
    noninf_two_proportions = {
      twin$template <- "two_proportions"
      twin$population <- list(p1 = pop$p1, p2 = pop$p2)
    },
    tost_correlation = {
      twin$template <- "correlation"
      twin$population <- list(r = pop$r)
    },
    return(NULL)
  )
  sim_basic_code(twin, n)
}

# Rank tests: scores of the chosen shape in SD units (as the backend draws
# them, score_shape_sampler()), shifted by the effect. For a paired test
# the backend draws the differences; here the first measurement is a
# normal score and the second adds the drawn difference, so the
# differences have the chosen shape.
sim_rank_code <- function(spec, n) {
  pop <- spec$population
  draw <- sprintf("draw <- function(n) %s # %s, mean 0 and SD 1", switch(
    pop$score_shape %||% "normal",
    normal = "stats::rnorm(n)",
    skewed = "(stats::rchisq(n, df = 10) - 10) / sqrt(20)",
    heavy_tailed = "stats::rt(n, df = 3) / sqrt(3)"
  ), score_shape_words(pop$score_shape))
  y <- sim_label(spec, "Y")
  body <- switch(
    spec$template,
    one_sample_t = sprintf("simulated <- data.frame(%s = %s + draw(%d))", y, r_code(pop$d), n),
    paired_t = {
      levels <- sim_levels(spec, "X")
      c(
        sprintf("first <- stats::rnorm(%d)", n),
        "simulated <- data.frame(",
        sprintf("  %s = first,", csv_name(paste(y, levels[1]))),
        sprintf("  %s = first + %s + draw(%d)", csv_name(paste(y, levels[2])), r_code(pop$dz), n),
        ")"
      )
    },
    independent_t = {
      groups <- sim_two_groups(spec, n)
      c(
        "simulated <- data.frame(",
        sprintf("  %s = rep(%s, %s),", sim_label(spec, "X"), r_code(sim_levels(spec, "X")), r_code(groups)),
        sprintf("  %s = c(draw(%d), %s + draw(%d))", y, groups[1], r_code(pop$d), groups[2]),
        ")"
      )
    },
    oneway_between = {
      levels <- sim_levels(spec, "A")
      k <- length(levels)
      means <- as.numeric(unlist(pop$means)) / pop$sd
      c(
        sprintf("means <- %s # each group's mean, in SD units", r_code(means)),
        "simulated <- data.frame(",
        sprintf("  %s = rep(%s, each = %d),", sim_label(spec, "A"), r_code(levels), n %/% k),
        sprintf("  %s = unlist(lapply(means, function(m) m + draw(%d)))", y, n %/% k),
        ")"
      )
    }
  )
  c(draw, body)
}

# A yes/no outcome with two crossed factors: each cell's 'yes' drawn with
# its proportion, which is the logistic model with both factors and their
# interaction that the backend simulates (it reproduces every cell's
# proportion exactly).
sim_logistic_factorial_code <- function(spec, n) {
  p <- logistic_factorial_probabilities(spec)
  a <- sim_levels(spec, "A")
  b <- sim_levels(spec, "B")
  per_cell <- n %/% (length(a) * length(b))
  c(
    sprintf("cells <- expand.grid(A = %s, B = %s, stringsAsFactors = FALSE)", r_code(a), r_code(b)),
    sprintf("cells$p <- %s # proportion of 'yes' in each cell", r_code(as.vector(p))),
    sprintf("rows <- cells[rep(seq_len(nrow(cells)), each = %d), ]", per_cell),
    "simulated <- data.frame(",
    sprintf("  %s = rows$A,", sim_label(spec, "A")),
    sprintf("  %s = rows$B,", sim_label(spec, "B")),
    sprintf("  %s = %s[stats::rbinom(nrow(rows), 1, rows$p) + 1]", sim_label(spec, "Y"), r_code(sim_levels(spec, "Y"))),
    ")"
  )
}

# An ordinal outcome in two groups: group 1's shares, and group 2's from
# them and the odds ratio under proportional odds (Hmisc::pomodm(), the
# function powertools' propodds() uses).
sim_ordinal_code <- function(spec, n) {
  pop <- spec$population
  groups <- sim_two_groups(spec, n)
  levels <- sim_levels(spec, "Y")
  c(
    sprintf("p1 <- %s # group 1's share in each category", r_code(as.numeric(unlist(pop$probabilities)))),
    sprintf("p2 <- Hmisc::pomodm(p = p1, odds.ratio = %s) # group 2's, under proportional odds", r_code(pop$odds_ratio)),
    "simulated <- data.frame(",
    sprintf("  %s = rep(%s, %s),", sim_label(spec, "X"), r_code(sim_levels(spec, "X")), r_code(groups)),
    sprintf(
      "  %s = c(sample(%s, %d, replace = TRUE, prob = p1), sample(%s, %d, replace = TRUE, prob = p2))",
      sim_label(spec, "Y"), r_code(levels), groups[1], r_code(levels), groups[2]
    ),
    ")"
  )
}

# A planned contrast: equal groups drawn with each group's mean and the
# one SD (Spower's gen_anova.test(), as for Welch's ANOVA but with equal
# SDs), in the outcome's units when the means are.
sim_contrast_code <- function(spec, n) {
  pop <- spec$population
  levels <- sim_levels(spec, "A")
  k <- length(levels)
  c(
    sprintf(
      "sim <- Spower::gen_anova.test(n = %d, k = %d, means = %s, sds = %s)",
      n %/% k, k, r_code(as.numeric(unlist(pop$means))), r_code(rep(pop$sd, k))
    ),
    sprintf(
      "simulated <- data.frame(%s = %s[as.integer(sim$group)], %s = sim$DV)",
      sim_label(spec, "A"), r_code(levels), sim_label(spec, "Y")
    )
  )
}

# Logistic and Poisson regression with one predictor: X standardised
# (normal) or a yes/no group (X's second level with probability x_prob),
# then Y from the model pwrss's formulas assume. Logistic: the odds of
# 'yes' are base_prob's odds times odds_ratio per unit of X. Poisson: the
# count over the mean exposure, with rate base_rate times rate_ratio per
# unit of X. Only when no other predictors are entered (r2_other_predictors
# 0 or absent): the spec doesn't say what they are.
sim_glm_code <- function(spec, n) {
  pop <- spec$population
  if (!identical(spec$template %in% c("single_predictor", "single_predictor_count"), TRUE) ||
      (pop$r2_other_predictors %||% 0) > 0) {
    return(NULL)
  }
  binary_x <- identical(spec$variables$X$type, "binary")
  x_line <- if (binary_x) {
    sprintf("x <- stats::rbinom(%d, 1, %s) # 1 = %s", n, r_code(pop$x_prob %||% 0.5), sim_levels(spec, "X")[2])
  } else {
    sprintf("x <- stats::rnorm(%d) # standardised", n)
  }
  y_line <- if (identical(spec$design, "logistic_regression")) {
    sprintf(
      "y <- %s[stats::rbinom(%d, 1, stats::plogis(stats::qlogis(%s) + log(%s) * x)) + 1]",
      r_code(sim_levels(spec, "Y")), n, r_code(pop$base_prob), r_code(pop$odds_ratio)
    )
  } else {
    sprintf(
      "y <- stats::rpois(%d, %s * %s * %s^x) # events over the mean exposure",
      n, r_code(pop$mean_exposure %||% 1), r_code(pop$base_rate), r_code(pop$rate_ratio)
    )
  }
  x_column <- if (binary_x) sprintf("%s[x + 1]", r_code(sim_levels(spec, "X"))) else "x"
  c(x_line, y_line, sprintf("simulated <- data.frame(%s = %s, %s = y)", sim_label(spec, "X"), x_column, sim_label(spec, "Y")))
}

# Cluster trials with a score outcome, in SD units: each group's
# participants share a random intercept with variance icc, and the rest of
# the variance (1 - icc) is each person's own, so the total SD is 1 and d
# is the difference between conditions. Cluster-randomised: whole groups
# in each condition. Group treatment: only the second condition in groups;
# the first takes part individually. Not yet for multisite trials, yes/no
# outcomes or a baseline covariate.
sim_cluster_code <- function(spec, n) {
  pop <- spec$population
  if (!spec$template %in% c("cluster_randomised", "group_treatment") ||
      !identical(spec$variables$Y$type, "continuous") || !is.null(pop$baseline_r2_within)) {
    return(NULL)
  }
  m <- pop$cluster_size
  levels <- sim_levels(spec, "X")
  x <- sim_label(spec, "X")
  y <- sim_label(spec, "Y")
  grouped <- function(groups, offset, condition, effect) {
    sprintf(
      "  data.frame(%s = %s, cluster = rep(%d + seq_len(%d), each = %s), %s = %s + rep(stats::rnorm(%d, sd = sqrt(icc)), each = %s) + stats::rnorm(%d, sd = sqrt(1 - icc)))",
      x, r_code(condition), offset, groups, r_code(m), y, r_code(effect), groups, r_code(m), groups * m
    )
  }
  head <- sprintf("icc <- %s # share of the variance between groups", r_code(pop$icc))
  if (spec$template == "cluster_randomised") {
    per_condition <- (n / 2) %/% m
    return(c(
      head,
      "simulated <- rbind(",
      paste0(grouped(per_condition, 0, levels[1], 0), ","),
      grouped(per_condition, per_condition, levels[2], pop$d),
      ")"
    ))
  }
  groups <- (n / 2) %/% m
  c(
    head,
    "simulated <- rbind(",
    sprintf(
      "  data.frame(%s = %s, cluster = NA, %s = stats::rnorm(%d)),",
      x, r_code(levels[1]), y, n %/% 2
    ),
    grouped(groups, 0, levels[2], pop$d),
    ")"
  )
}

# Participants and items in two conditions (E33): one data set simulated
# from simr's model, one row per trial (participant, item, condition), the
# long format a mixed model is fitted to. The outcome is centred: the
# model's intercept is 0, as the difference is all the power depends on.
sim_mixed_code <- function(spec, n) {
  inputs <- simr_inputs(spec)
  levels <- sim_levels(spec, "X")
  item_var <- if (length(inputs$VarCorr$item) > 1) {
    sprintf("diag(%s)", r_code(diag(inputs$VarCorr$item)))
  } else {
    r_code(inputs$VarCorr$item)
  }
  c(
    if (inputs$within) {
      sprintf("design <- expand.grid(participant = seq_len(%d), item = seq_len(%d), cond = c(-0.5, 0.5))", n, inputs$items)
    } else {
      c(
        sprintf("design <- expand.grid(participant = seq_len(%d), item = seq_len(%d))", n, inputs$items),
        sprintf("design$cond <- ifelse(design$item <= %d, -0.5, 0.5) # the first half of the items in the first condition", inputs$items %/% 2)
      )
    },
    "design$participant <- factor(design$participant)",
    "design$item <- factor(design$item)",
    sprintf("participant_var <- matrix(%s, nrow = 2)", r_code(as.vector(inputs$VarCorr$participant))),
    sprintf(
      "model <- simr::makeLmer(%s, fixef = %s, VarCorr = list(participant = participant_var, item = %s), sigma = %s, data = design)",
      deparse1(inputs$formula), r_code(inputs$fixef), item_var, r_code(inputs$sigma)
    ),
    "simulated <- data.frame(",
    "  participant = design$participant,",
    "  item = design$item,",
    sprintf("  %s = %s[(design$cond > 0) + 1],", sim_label(spec, "X"), r_code(levels)),
    sprintf("  %s = stats::simulate(model)[[1]]", sim_label(spec, "Y")),
    ")"
  )
}

# ANOVA designs, from Superpower's ANOVA_design(), which draws one sample
# of the requested size (n per between-participants group). Its long data
# (one row per participant per condition) are turned wide when there is a
# within-participants factor: one row per participant, one column per
# condition, as SPSS, JASP and jamovi expect for repeated measures.
sim_superpower_code <- function(spec, n) {
  inputs <- superpower_inputs(spec)
  per_group <- if (is.null(inputs$cell_ratio)) ceiling(n / inputs$groups) else round(superpower_cell_n(inputs, n))
  roles <- intersect(c("A", "B", "C"), names(spec$variables))
  factor_of <- c(A = "a", B = "b", C = "c")
  within <- vapply(roles, function(v) identical(spec$variables[[v]]$type, "within_factor"), logical(1))
  y <- sim_label(spec, "Y")
  level_of <- function(v, safe = FALSE) {
    levels <- sim_levels(spec, v)
    sprintf("%s[level(long$%s)]", r_code(if (safe) csv_name(levels) else levels), factor_of[[v]])
  }
  call <- c(
    "design <- Superpower::ANOVA_design(",
    sim_args(list(design = inputs$design, n = per_group, mu = inputs$mu, sd = inputs$sd, r = inputs$r, plot = FALSE)),
    ")",
    "long <- design$dataframe",
    if (!is.null(inputs$cell_ratio)) c(
      "# ANOVA_design() builds every cell at the largest size; keep each cell's own n.",
      "cell_n <- stats::setNames(design$n, unique(long$cond))",
      "long <- long[stats::ave(seq_along(long$cond), long$cond, FUN = seq_along) <= cell_n[long$cond], ]"
    ),
    "level <- function(x) as.integer(sub(\"^.*[a-z]\", \"\", as.character(x)))"
  )
  between <- roles[!within]
  if (!any(within)) {
    columns <- c(
      vapply(between, function(v) sprintf("  %s = %s,", sim_label(spec, v), level_of(v)), character(1)),
      sprintf("  %s = long$y", y)
    )
    return(c(call, "simulated <- data.frame(", columns, ")"))
  }
  cell <- paste(c(r_code(y), vapply(roles[within], level_of, character(1), safe = TRUE)), collapse = ", ")
  c(
    call,
    sprintf("long$cell <- paste(%s, sep = \"_\")", cell),
    "people <- unique(long$subject)",
    "simulated <- data.frame(row.names = seq_along(people))",
    vapply(between, function(v) {
      sprintf("simulated$%s <- %s[match(people, long$subject)]", sim_label(spec, v), level_of(v))
    }, character(1)),
    "for (cell in unique(long$cell)) {",
    "  rows <- long$cell == cell",
    "  simulated[[cell]] <- long$y[rows][match(people, long$subject[rows])]",
    "}"
  )
}

# Regression interactions, from InteractionPoweR's generate_interaction()
# with the backend's correlations and reliabilities: observed scores, with
# measurement error when a reliability is below 1, and a yes/no X or W as
# its two levels, split 50/50. The product term is
# left out; the analysis makes it.
sim_interaction_code <- function(spec, n) {
  inputs <- interactionpower_inputs(spec)
  c(
    "sim <- InteractionPoweR::generate_interaction(",
    sim_args(c(list(N = n), inputs[c("r.x1.y", "r.x2.y", "r.x1x2.y", "r.x1.x2", "rel.x1", "rel.x2", "rel.y", if (inputs$k.x1 > 0) "k.x1", if (inputs$k.x2 > 0) "k.x2")])),
    ")",
    sprintf(
      "simulated <- data.frame(%s = %s, %s = %s, %s = sim$y)",
      sim_label(spec, "X"), sim_column("x1", spec, "X"), sim_label(spec, "W"), sim_column("x2", spec, "W"), sim_label(spec, "Y")
    )
  )
}

# A generated predictor as a column: a score as it is, or a yes/no variable
# (InteractionPoweR's -1 and 1) as its level names, the second level for 1.
sim_column <- function(name, spec, role) {
  if (!identical(spec$variables[[role]]$type, "binary")) {
    return(sprintf("sim$%s", name))
  }
  sprintf("%s[(sim$%s > 0) + 1]", r_code(sim_levels(spec, role)), name)
}

# Mediation and moderated mediation, from power4mome's generator (the
# backend's model and population values, no test run). Product terms are
# left out; the analysis makes them.
sim_power4mome_code <- function(spec, n, seed) {
  inputs <- power4mome_inputs(spec)
  roles <- names(spec$variables)
  c(
    "sim <- power4mome::power4test(",
    sim_args(list(
      nrep = 1L, model = inputs$model, pop_es = inputs$pop_es, n = n,
      do_the_test = FALSE, iseed = seed, parallel = FALSE, progress = FALSE
    )),
    if (!is.null(inputs$x_prob)) sprintf(
      "  , x_fun = list(X = list(power4mome::rbinary_rs, p1 = %s))", r_code(inputs$x_prob)
    ),
    ")",
    "pooled <- as.data.frame(power4mome::pool_sim_data(sim))",
    "simulated <- data.frame(",
    paste0(
      "  ", vapply(roles, function(v) sim_label(spec, v), character(1)), " = ",
      vapply(roles, function(v) {
        # A yes/no X as its level names (rbinary_rs() puts the second
        # level above X's mean).
        if (identical(spec$variables[[v]]$type, "binary")) {
          sprintf("%s[(pooled[[%s]] > 0) + 1]", r_code(sim_levels(spec, v)), r_code(v))
        } else {
          sprintf("pooled[[%s]]", r_code(v))
        }
      }, character(1)),
      c(rep(",", length(roles) - 1), "")
    ),
    ")"
  )
}

r_code_each <- function(x) vapply(x, r_code, character(1), USE.NAMES = FALSE)

# The R script's section that builds the same data set and writes it as
# CSV, for designs with a generator.
simulated_data_section <- function(spec, n, seed) {
  if (is.null(n)) {
    return(NULL)
  }
  if (!is.numeric(seed) || length(seed) != 1 || is.na(seed)) {
    seed <- 1
  }
  code <- simulated_data_code(spec, as.integer(ceiling(n)), seed)
  if (is.null(code)) {
    return(NULL)
  }
  c(
    "",
    "# ---- A simulated data set (NOT real data) ----------------------------------",
    "# One data set of the planned size, drawn from the population above. It is",
    "# for writing and checking your analysis code before the real data arrive:",
    "# not evidence, not a pilot, and not a substitute for your analysis plan.",
    "# Every row is marked as simulated in the column SIMULATED_NOT_REAL_DATA.",
    "# To write it as a CSV file, remove the # before write.csv().",
    sprintf("set.seed(%s)", r_code(seed)),
    code,
    sprintf("# write.csv(simulated, %s, row.names = FALSE)", r_code(simulated_data_file_name(spec)))
  )
}

simulated_data_file_name <- function(spec) {
  sprintf("SIMULATED-not-real-data-%s.csv", gsub("_", "-", spec$template))
}

# The planned n: the required n for a sample-size goal (when one was
# found), otherwise the n the spec gives.
simulated_data_n <- function(spec, result) {
  n <- if (identical(spec$goal$type, "sample_size")) result$n_required$n else spec$goal$n
  if (is.numeric(n) && length(n) == 1 && !is.na(n)) n
}
