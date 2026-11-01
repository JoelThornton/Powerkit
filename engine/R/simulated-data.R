# A simulated data set: one sample of n participants drawn from the
# population a spec describes, by the same generator the backend uses
# (Spower's gen_*() functions, Superpower's ANOVA_design(),
# InteractionPoweR's generate_interaction() and power4mome's power4test()),
# or, where the backend has no generator, from the same population by base
# R's draws (one proportion, rank tests, factorial logistic regression,
# ordinal outcomes with Hmisc::pomodm() for the second group's shares,
# one-predictor logistic and Poisson regression, multiple regression's
# R-squared tests, the ANCOVAs, the Cochran-Armitage trend test, cluster
# trials and precision planning).
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
#' regression with one predictor (other predictors carried by one
#' column), multiple regression's R-squared tests, one- and two-way ANCOVA,
#' the trend tests, cluster trials (cluster-randomised, multisite and group
#' treatment, with a score or a yes/no outcome and a baseline score) and
#' precision planning; `simulated_data_available()` says whether a spec is
#' covered. Not available for McNemar's test, the three-way regression
#' interaction, structural equation models, meta-analyses and the generic
#' tests.
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

#' @rdname simulated_data
#' @return `simulated_data_note()`: a sentence on a choice the data set
#'   makes that the spec leaves open (for example one covariate standing
#'   for all of an ANCOVA's covariates), or `NULL`.
#' @export
simulated_data_note <- function(spec) {
  spec <- validate_spec(spec)
  pop <- spec$population
  if (identical(spec$design, "multiple_regression")) {
    return(paste0(
      "The predictors are drawn as independent standard normal scores with equal weights",
      if (identical(spec$template, "r2_increase")) " within each set (Control_ for those already in the model, Predictor_ for those tested)" else "",
      ", since the plan says how much they explain together, not how they relate to each other."))
  }
  if (spec$design %in% c("logistic_regression", "poisson_regression") && (pop$r2_other_predictors %||% 0) > 0) {
    return(sprintf(paste0(
      "The other predictors are carried by one column, Other_predictor, which shares R-squared %s with %s ",
      "and has no effect of its own on the outcome, since the plan says how much they overlap with %s, not what they do."),
      format_number(pop$r2_other_predictors), sim_label(spec, "X"), sim_label(spec, "X")))
  }
  if (identical(spec$design, "cluster_trial") && (pop$cluster_size_sd %||% 0) > 0) {
    return(sprintf("Every group in the data set has %s people; the plan allows for sizes that vary (SD %s), which the data set doesn't.",
      format_number(pop$cluster_size), format_number(pop$cluster_size_sd)))
  }
  if (identical(spec$template, "group_treatment") && identical(spec$variables$Y$type, "binary") && pop$icc > 0) {
    return(sprintf("Each group's proportion is drawn from a beta distribution with mean %s and intraclass correlation %s.",
      format_number(pop$p2), format_number(pop$icc)))
  }
  if (identical(spec$design, "precision") && identical(spec$template, "paired")) {
    return("The two measurements are drawn with SD 1 and correlation 0.5, so that their difference has SD 1 and mean d_z; the plan gives only d_z.")
  }
  if (identical(spec$template, "factorial_ancova")) {
    spec$template <- "oneway_ancova"
  }
  if (identical(spec$template, "oneway_ancova") && (spec$population$covariates %||% 1) > 1) {
    return(sprintf(paste0(
      "The plan has %d covariates; the data set has one, Covariate, carrying all of their R-squared (%s) ",
      "with the outcome, since the plan doesn't say what they are."),
      spec$population$covariates, format_number(spec$population$r2_covariates)))
  }
  if (identical(spec$template, "oneway_ancova")) {
    return(sprintf("The covariate, Covariate, is drawn as a standard normal score with R-squared %s with the outcome within each group.",
      format_number(spec$population$r2_covariates)))
  }
  NULL
}

# R code that builds `simulated` (a data frame) from the spec's
# population, or NULL when the design has no generator here yet. The code
# names its packages (pkg::fun) so it runs without powerkit.
simulated_data_code <- function(spec, n, seed) {
  # An ANOVA given by its partial eta-squared, an interaction by its
  # R-squared change or a chi-square test by Cohen's w has no means,
  # correlations or proportions to draw data from.
  if (eta_squared_anova(spec) || interaction_r2_change(spec) || chisq_by_w(spec)) return(NULL)
  superpower <- c(
    "oneway_between", "oneway_within", "2x2_between", "2x2_mixed", "mixed",
    "factorial_between", "factorial_within", "factorial_three"
  )
  body <- if (rank_test(spec)) sim_rank_code(spec, n) else switch(
    spec$design,
    basic_test = sim_basic_code(spec, n) %||% sim_more_basic_code(spec, n) %||% sim_multivariate_code(spec, n),
    multiple_regression = sim_regression_code(spec, n),
    precision = sim_precision_code(spec, n),
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
    } else if (spec$template %in% c("oneway_ancova", "factorial_ancova")) {
      sim_ancova_code(spec, n)
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
  if (shaped_rank_correlation(spec)) {
    # Both scores in the chosen shape (shaped_pair_scores()).
    draw <- switch(pop$score_shape,
      skewed = "(stats::rchisq(%d, df = 10) - 10) / sqrt(20)",
      heavy_tailed = "stats::rt(%d, df = 3) / sqrt(3)")
    return(c(
      sprintf("x <- %s # %s, mean 0 and SD 1", sprintf(draw, n), score_shape_words(pop$score_shape)),
      sprintf("simulated <- data.frame(%s = x, %s = %s * x + sqrt(1 - %s^2) * %s)", sim_label(spec, "X"), sim_label(spec, "Y"),
        r_code(pop$r), r_code(pop$r), sprintf(draw, n))
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

# Group sizes for a total n split by relative shares (a trend test's
# options > group_ratio): each group's rounded share, the last taking the
# remainder so that they add up to n.
sim_shares <- function(n, shares) {
  sizes <- round(n * shares / sum(shares))
  sizes[length(sizes)] <- n - sum(sizes[-length(sizes)])
  as.integer(sizes)
}

# Basic tests with no Spower experiment in powerkit: one proportion (base
# R's binomial draws), goodness of fit (Spower's gen_chisq.test() with one
# row of probabilities), two independent correlations (Spower's gen_r() in
# each group), two dependent correlations (Spower's gen_2r() with the
# correlation matrix the spec gives), and the Cochran-Armitage trend test
# (base R's binomial draws in each group). McNemar's test isn't covered: the
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
    proportion_trend = {
      sizes <- sim_shares(n, trend_group_shares(spec))
      c(
        sprintf("sizes <- %s # people in each group, in order", r_code(sizes)),
        sprintf("proportions <- %s # each group's proportion of %s", r_code(as.numeric(unlist(pop$proportions))), r_code(sim_levels(spec, "Y")[2])),
        "group <- rep(seq_along(sizes), sizes)",
        sprintf("simulated <- data.frame(%s = %s[group], %s = %s[stats::rbinom(%d, 1, proportions[group]) + 1])",
          sim_label(spec, "X"), r_code(sim_levels(spec, "X")), y, r_code(sim_levels(spec, "Y")), n)
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
    },
    # Friedman's test: one row per participant, one column per condition;
    # each score the condition's mean, the person's level and a deviation in
    # the chosen shape (friedman_scores()).
    oneway_within = {
      levels <- sim_levels(spec, "A")
      means <- as.numeric(unlist(pop$means)) / pop$sd
      c(
        sprintf("means <- %s # each condition's mean, in SD units", r_code(means)),
        sprintf("person <- sqrt(%s) * stats::rnorm(%d) # each person's own level", r_code(pop$r), n),
        "simulated <- data.frame(",
        paste0(sprintf("  %s = means[%d] + person + sqrt(1 - %s) * draw(%d)", vapply(paste(y, levels), csv_name, character(1)),
          seq_along(levels), r_code(pop$r), n), c(rep(",", length(levels) - 1), "")),
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

# MANOVA and one-sample Hotelling's T-squared: multivariate normal scores
# with each group's means (or the one group's), the outcomes' SDs and one
# correlation between every pair, as manova_scores() draws them; one row
# per person, one column per outcome.
sim_multivariate_code <- function(spec, n) {
  if (!spec$template %in% c("manova", "hotelling_one")) {
    return(NULL)
  }
  pop <- spec$population
  outcomes <- vapply(manova_outcomes(spec), function(y) sim_label(spec, y), character(1))
  p <- length(outcomes)
  manova <- identical(spec$template, "manova")
  means <- if (manova) manova_means(spec) else matrix(as.numeric(unlist(pop$means)), nrow = 1)
  k <- nrow(means)
  per_group <- n %/% k
  c(
    sprintf("means <- matrix(%s, nrow = %d, byrow = TRUE) # one row per %s, one column per outcome",
      r_code(as.numeric(t(means))), k, if (manova) "group" else "group (here one)"),
    sprintf("correlation <- matrix(%s, %d, %d)", r_code(pop$r), p, p),
    "diag(correlation) <- 1",
    sprintf("sds <- %s", r_code(as.numeric(unlist(pop$sds)))),
    "sigma <- diag(sds) %*% correlation %*% diag(sds)",
    sprintf("y <- do.call(rbind, lapply(seq_len(%d), function(g) SimDesign::rmvnorm(%d, means[g, ], sigma)))", k, per_group),
    "simulated <- data.frame(",
    if (manova && is.null(spec$variables$B)) sprintf("  %s = rep(%s, each = %d),", sim_label(spec, "A"), r_code(sim_levels(spec, "A")), per_group),
    # Two factors: the groups are A's levels by B's, B's fastest.
    if (manova && !is.null(spec$variables$B)) c(
      sprintf("  %s = rep(%s, each = %d),", sim_label(spec, "A"), r_code(sim_levels(spec, "A")), per_group * length(sim_levels(spec, "B"))),
      sprintf("  %s = rep(rep(%s, each = %d), times = %d),", sim_label(spec, "B"), r_code(sim_levels(spec, "B")), per_group, length(sim_levels(spec, "A")))
    ),
    paste0(sprintf("  %s = y[, %d]", outcomes, seq_len(p)), c(rep(",", p - 1), "")),
    ")"
  )
}

# One-way and two-way ANCOVA: one covariate carrying all of the
# covariates' R-squared with the outcome (the spec says how much they
# explain, not what they are). The covariate is standard normal in every
# group, as randomisation makes it, so the adjusted means are the group (or
# cell) means; within a group the outcome has the unadjusted SD the spec
# gives (pwrss's sd.vector) and R-squared r2_covariates with the covariate.
# Two factors: equal cells, A's levels in rows of population > means.
sim_ancova_code <- function(spec, n) {
  pop <- spec$population
  levels <- sim_levels(spec, "A")
  if (identical(spec$template, "factorial_ancova")) {
    b_levels <- sim_levels(spec, "B")
    cells <- length(levels) * length(b_levels)
    per_cell <- n %/% cells
    total <- per_cell * cells
    means <- as.numeric(t(do.call(rbind, lapply(pop$means, as.numeric))))
    return(c(
      sprintf("means <- %s # each cell's (adjusted) mean: %s by %s, %s's levels changing fastest",
        r_code(means), sim_label(spec, "A"), sim_label(spec, "B"), sim_label(spec, "B")),
      sprintf("covariate <- stats::rnorm(%d) # one covariate standing for all of them (R-squared %s)", total, format_number(pop$r2_covariates)),
      sprintf("cell <- rep(seq_len(%d), each = %d)", cells, per_cell),
      sprintf("outcome <- means[cell] + %s * (sqrt(%s) * covariate + sqrt(1 - %s) * stats::rnorm(%d))",
        r_code(pop$sd), r_code(pop$r2_covariates), r_code(pop$r2_covariates), total),
      "simulated <- data.frame(",
      sprintf("  %s = %s[(cell - 1) %%/%% %d + 1],", sim_label(spec, "A"), r_code(levels), length(b_levels)),
      sprintf("  %s = %s[(cell - 1) %%%% %d + 1],", sim_label(spec, "B"), r_code(b_levels), length(b_levels)),
      sprintf("  Covariate = covariate, %s = outcome", sim_label(spec, "Y")),
      ")"
    ))
  }
  k <- length(levels)
  per_group <- n %/% k
  c(
    sprintf("means <- %s # each group's (adjusted) mean", r_code(as.numeric(unlist(pop$means)))),
    sprintf("covariate <- stats::rnorm(%d) # one covariate standing for all of them (R-squared %s)", per_group * k, format_number(pop$r2_covariates)),
    sprintf("group <- rep(seq_len(%d), each = %d)", k, per_group),
    sprintf("outcome <- means[group] + %s * (sqrt(%s) * covariate + sqrt(1 - %s) * stats::rnorm(%d))",
      r_code(pop$sd), r_code(pop$r2_covariates), r_code(pop$r2_covariates), per_group * k),
    sprintf("simulated <- data.frame(%s = %s[group], Covariate = covariate, %s = outcome)",
      sim_label(spec, "A"), r_code(levels), sim_label(spec, "Y"))
  )
}

# Logistic and Poisson regression with one predictor: X standardised
# (normal) or a yes/no group (X's second level with probability x_prob),
# then Y from the model pwrss's formulas assume. Logistic: the odds of
# 'yes' are base_prob's odds times odds_ratio per unit of X. Poisson: the
# count over the mean exposure, with rate base_rate times rate_ratio per
# unit of X. Other predictors (r2_other_predictors, the share of X's
# variance they explain, pwrss's r.squared.predictor) are carried by one
# normal column, Other_predictor, correlated with X so that it explains
# that share, and with no effect of its own on Y: the spec says how much
# they overlap with X, not what they do (simulated_data_note()).
sim_glm_code <- function(spec, n) {
  pop <- spec$population
  if (!identical(spec$template %in% c("single_predictor", "single_predictor_count"), TRUE)) {
    return(NULL)
  }
  r2_other <- pop$r2_other_predictors %||% 0
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
  if (r2_other <= 0) {
    return(c(x_line, y_line, sprintf("simulated <- data.frame(%s = %s, %s = y)", sim_label(spec, "X"), x_column, sim_label(spec, "Y"))))
  }
  x_standard <- if (binary_x) {
    q <- pop$x_prob %||% 0.5
    sprintf("(x - %s) / %s", r_code(q), r_code(sqrt(q * (1 - q))))
  } else {
    "x"
  }
  c(
    x_line,
    sprintf("other <- sqrt(%s) * %s + sqrt(1 - %s) * stats::rnorm(%d) # shares R-squared %s with X; no effect of its own on Y",
      r_code(r2_other), x_standard, r_code(r2_other), n, format_number(r2_other)),
    y_line,
    sprintf("simulated <- data.frame(%s = %s, Other_predictor = other, %s = y)", sim_label(spec, "X"), x_column, sim_label(spec, "Y"))
  )
}

# Cluster trials with a score outcome, in SD units: each group's
# participants share a random intercept with variance icc, and the rest of
# the variance (1 - icc) is each person's own, so the total SD is 1 and d
# is the difference between conditions. Cluster-randomised: whole groups
# in each condition. Group treatment: only the second condition in groups;
# the first takes part individually. Multisite trials, yes/no outcomes and
# a baseline score: sim_cluster_model_code().
sim_cluster_code <- function(spec, n) {
  pop <- spec$population
  if (!spec$template %in% c("cluster_randomised", "multisite", "group_treatment")) {
    return(NULL)
  }
  if (identical(spec$template, "multisite") || !identical(spec$variables$Y$type, "continuous") ||
      !is.null(pop$baseline_r2_within)) {
    return(sim_cluster_model_code(spec, n))
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

# Cluster trials drawn from the model powertools' formula assumes, one row
# per person, with the group in `cluster`:
#   multisite, score     each group (site) has its own mean (variance icc)
#                        and its own effect (variance 4 icc_effect, so that
#                        with the conditions coded -1/2 and +1/2 it gives
#                        icc_effect of the total variance, as
#                        multisite.cont()'s icc1 is defined); the rest,
#                        1 - icc - icc_effect, is each person's own. Half of
#                        each group in each condition.
#   cluster-randomised,  logistic model with a random intercept: each
#   yes/no               group's log odds are its condition's, qlogis(p1) or
#                        qlogis(p2), plus a normal deviation with SD sigma_u
#                        (crt.parallel.bin()'s model).
#   multisite, yes/no    the effect (log odds ratio) varies between groups
#                        with SD sigma_u (multisite.bin()'s sigma.u), with
#                        the conditions coded -1/2 and +1/2 around the
#                        average of the two log odds.
#   group treatment,     the grouped condition's groups each have their own
#   yes/no               proportion, drawn from a beta distribution with
#                        mean p2 and intraclass correlation icc (the model
#                        under which irgtt.bin()'s design effect
#                        1 + (m - 1) icc holds); the other condition, p1,
#                        is individual.
#   baseline score       a standard normal Baseline column with the same
#                        ICC as the outcome, whose group part explains
#                        baseline_r2_between of the outcome's variance
#                        between groups and whose individual part explains
#                        baseline_r2_within within them (cluster-randomised;
#                        a multisite trial's Rsq is within groups only).
# Groups are all of cluster_size people (the data set doesn't vary their
# size: simulated_data_note()).
sim_cluster_model_code <- function(spec, n) {
  pop <- spec$population
  m <- pop$cluster_size
  levels <- sim_levels(spec, "X")
  x <- sim_label(spec, "X")
  y <- sim_label(spec, "Y")
  binary <- identical(spec$variables$Y$type, "binary")
  y_levels <- sim_yes_no_levels(spec)
  yes_no <- function(prob) sprintf("%s[stats::rbinom(length(%s), 1, %s) + 1]", r_code(y_levels), prob, prob)
  baseline <- !is.null(pop$baseline_r2_within)
  if (identical(spec$template, "group_treatment")) {
    groups <- (n / 2) %/% m
    individual <- n %/% 2
    p2 <- if (pop$icc > 0) {
      sprintf("stats::rbeta(%d, %s, %s)", groups, r_code(pop$p2 * (1 - pop$icc) / pop$icc), r_code((1 - pop$p2) * (1 - pop$icc) / pop$icc))
    } else {
      sprintf("rep(%s, %d)", r_code(pop$p2), groups)
    }
    return(c(
      sprintf("group_p <- %s # each group's proportion of %s (mean %s, ICC %s)", p2, r_code(y_levels[2]), format_number(pop$p2), format_number(pop$icc)),
      sprintf("p_individual <- rep(%s, %d)", r_code(pop$p1), individual),
      sprintf("p_grouped <- rep(group_p, each = %s)", r_code(m)),
      "simulated <- rbind(",
      sprintf("  data.frame(%s = %s, cluster = NA, %s = %s),", x, r_code(levels[1]), y, yes_no("p_individual")),
      sprintf("  data.frame(%s = %s, cluster = rep(seq_len(%d), each = %s), %s = %s)", x, r_code(levels[2]), groups, r_code(m), y, yes_no("p_grouped")),
      ")"
    ))
  }
  multisite <- identical(spec$template, "multisite")
  clusters <- if (multisite) n %/% m else 2 * ((n / 2) %/% m)
  total <- clusters * m
  condition <- if (multisite) {
    sprintf("condition <- rep(rep(0:1, c(%d, %d)), %d) # 0 = %s, 1 = %s; half of each group in each", m - m %/% 2, m %/% 2, clusters, levels[1], levels[2])
  } else {
    sprintf("condition <- rep(0:1, each = %d) # each whole group in one condition: 0 = %s, 1 = %s", total / 2, levels[1], levels[2])
  }
  head <- c(
    sprintf("cluster <- rep(seq_len(%d), each = %s)", clusters, r_code(m)),
    condition
  )
  frame <- function(outcome, extra = NULL) {
    c("simulated <- data.frame(",
      sprintf("  %s = %s[condition + 1], cluster = cluster,%s", x, r_code(levels), if (is.null(extra)) "" else paste0(" ", extra, ",")),
      sprintf("  %s = %s", y, outcome),
      ")")
  }
  if (binary) {
    logit <- if (multisite) {
      c(sprintf("effect <- log(%s) + stats::rnorm(%d, sd = %s) # each group's log odds ratio",
          r_code((pop$p2 / (1 - pop$p2)) / (pop$p1 / (1 - pop$p1))), clusters, r_code(pop$sigma_u)),
        sprintf("log_odds <- (stats::qlogis(%s) + stats::qlogis(%s)) / 2 + effect[cluster] * (condition - 0.5)", r_code(pop$p1), r_code(pop$p2)))
    } else {
      sprintf("log_odds <- stats::qlogis(%s)[condition + 1] + stats::rnorm(%d, sd = %s)[cluster] # each group's own deviation",
        r_code(c(pop$p1, pop$p2)), clusters, r_code(pop$sigma_u))
    }
    return(c(head, logit, frame(yes_no("stats::plogis(log_odds)"))))
  }
  icc <- pop$icc
  own <- if (multisite) 1 - icc - pop$icc_effect else 1 - icc
  r2w <- pop$baseline_r2_within %||% 0
  r2b <- if (multisite) 0 else pop$baseline_r2_between %||% 0
  lines <- c(head, sprintf("icc <- %s # share of the variance between groups' averages", r_code(icc)))
  if (baseline) {
    lines <- c(lines,
      sprintf("baseline_group <- stats::rnorm(%d, sd = sqrt(icc))", clusters),
      sprintf("baseline_own <- stats::rnorm(%d, sd = sqrt(1 - icc))", total),
      sprintf("group_part <- sqrt(%s) * baseline_group + sqrt(1 - %s) * stats::rnorm(%d, sd = sqrt(icc)) # baseline explains R-squared %s between groups",
        r_code(r2b), r_code(r2b), clusters, format_number(r2b)),
      sprintf("own_part <- sqrt(%s) * baseline_own / sqrt(1 - icc) * sqrt(%s) + sqrt(1 - %s) * stats::rnorm(%d, sd = sqrt(%s)) # and %s within them",
        r_code(r2w), r_code(own), r_code(r2w), total, r_code(own), format_number(r2w))
    )
  } else {
    lines <- c(lines,
      sprintf("group_part <- stats::rnorm(%d, sd = sqrt(icc))", clusters),
      sprintf("own_part <- stats::rnorm(%d, sd = sqrt(%s))", total, r_code(own)))
  }
  outcome <- if (multisite) {
    lines <- c(lines, sprintf("effect <- %s + stats::rnorm(%d, sd = 2 * sqrt(%s)) # each group's own effect (ICC of the effect %s)",
      r_code(pop$d), clusters, r_code(pop$icc_effect), format_number(pop$icc_effect)))
    "group_part[cluster] + effect[cluster] * (condition - 0.5) + own_part"
  } else {
    sprintf("%s * condition + group_part[cluster] + own_part", r_code(pop$d))
  }
  c(lines, frame(outcome, if (baseline) "Baseline = baseline_group[cluster] + baseline_own"))
}

# A yes/no outcome's two answers: its levels, or "No" and "Yes".
sim_yes_no_levels <- function(spec) {
  if (length(unlist(spec$variables$Y$levels))) sim_levels(spec, "Y") else c("No", "Yes")
}

# Multiple regression's R-squared tests: independent standard normal
# predictors with equal weights within each set, and a normal error, so
# that the outcome (SD 1) has the spec's R-squared. For the test of an
# increase, the predictors already in the model (Control_1, ...) carry
# r2_reduced and the tested ones (Predictor_1, ...) the increase; for the
# test that R-squared is zero, every predictor is tested. The spec gives
# how much the predictors explain, not how they relate to each other
# (simulated_data_note()).
sim_regression_code <- function(spec, n) {
  pop <- spec$population
  if (identical(spec$template, "r2_zero")) {
    k_base <- 0
    k_test <- pop$predictors
    r2_base <- 0
    r2_full <- pop$r2
  } else if (identical(spec$template, "r2_increase")) {
    k_test <- pop$predictors_tested
    k_base <- pop$predictors_total - k_test
    r2_base <- pop$r2_reduced
    r2_full <- pop$r2_full
  } else {
    return(NULL)
  }
  k <- k_base + k_test
  weights <- c(rep(if (k_base > 0) sqrt(r2_base / k_base) else 0, k_base), rep(sqrt((r2_full - r2_base) / k_test), k_test))
  names <- c(if (k_base > 0) paste0("Control_", seq_len(k_base)), paste0("Predictor_", seq_len(k_test)))
  c(
    sprintf("x <- matrix(stats::rnorm(%d), nrow = %d) # independent standard normal predictors", n * k, n),
    sprintf("weights <- %s # equal within each set: R-squared %s in all", r_code(weights), format_number(r2_full)),
    sprintf("y <- drop(x %%*%% weights) + sqrt(1 - %s) * stats::rnorm(%d)", r_code(r2_full), n),
    sprintf("colnames(x) <- %s", r_code(names)),
    sprintf("simulated <- data.frame(x, %s = y)", sim_label(spec, "Y"))
  )
}

# Precision planning (E46): data in the form the interval is computed
# from, in SD units. Two groups: half in each, the second group d higher.
# A standardised mean: one sample with mean d and SD 1. Paired scores: the
# two measurements with SD 1 each and correlation 0.5, so that the SD of
# their difference is also 1 and the difference has mean d_z (the spec
# gives only d_z: simulated_data_note()). A correlation: bivariate normal
# scores with correlation r. A proportion: yes/no answers with chance p.
sim_precision_code <- function(spec, n) {
  pop <- spec$population
  y <- sim_label(spec, "Y")
  switch(
    spec$template,
    two_groups = {
      groups <- c(n %/% 2, n - n %/% 2)
      c(
        sprintf("group <- rep(0:1, %s)", r_code(groups)),
        sprintf("simulated <- data.frame(%s = %s[group + 1], %s = %s * group + stats::rnorm(%d))",
          sim_label(spec, "X"), r_code(sim_levels(spec, "X")), y, r_code(pop$d), n)
      )
    },
    one_group = sprintf("simulated <- data.frame(%s = stats::rnorm(%d, mean = %s))", y, n, r_code(pop$d)),
    paired = {
      levels <- sim_levels(spec, "X")
      c(
        sprintf("first <- stats::rnorm(%d)", n),
        sprintf("second <- %s + 0.5 * first + sqrt(0.75) * stats::rnorm(%d) # correlation 0.5 with the first", r_code(pop$dz), n),
        "simulated <- data.frame(",
        sprintf("  %s = first,", csv_name(paste(y, levels[1]))),
        sprintf("  %s = second", csv_name(paste(y, levels[2]))),
        ")"
      )
    },
    correlation = c(
      sprintf("x <- stats::rnorm(%d)", n),
      sprintf("simulated <- data.frame(%s = x, %s = %s * x + sqrt(1 - %s^2) * stats::rnorm(%d))",
        sim_label(spec, "X"), y, r_code(pop$r), r_code(pop$r), n)
    ),
    proportion = sprintf("simulated <- data.frame(%s = %s[stats::rbinom(%d, 1, %s) + 1])", y, r_code(sim_yes_no_levels(spec)), n, r_code(pop$p)),
    NULL
  )
}

# Participants and items in two conditions (E33): one data set simulated
# from simr's model, one row per trial (participant, item, condition), the
# long format a mixed model is fitted to. The outcome is centred: the
# model's intercept is 0, as the difference is all the power depends on.
sim_mixed_code <- function(spec, n) {
  if (identical(spec$template, "two_level")) return(sim_two_level_code(spec, n))
  if (identical(spec$template, "crossed_conditions")) return(sim_crossed_conditions_code(spec, n))
  inputs <- simr_inputs(spec)
  levels <- sim_levels(spec, "X")
  item_var <- if (length(inputs$VarCorr$item) > 1) {
    sprintf("diag(%s)", r_code(diag(inputs$VarCorr$item)))
  } else {
    r_code(inputs$VarCorr$item)
  }
  c(
    if (inputs$participants_between) {
      c(
        sprintf("design <- expand.grid(participant = seq_len(%d), item = seq_len(%d))", n, inputs$items),
        sprintf("design$cond <- ifelse(design$participant <= %d, -0.5, 0.5) # the first half of the participants in the first condition", n %/% 2),
        if (!inputs$within) sprintf("design <- design[(design$item <= %d) == (design$cond < 0), ] # each condition's own half of the items", inputs$items %/% 2)
      )
    } else if (inputs$within) {
      sprintf("design <- expand.grid(participant = seq_len(%d), item = seq_len(%d), cond = c(-0.5, 0.5))", n, inputs$items)
    } else {
      c(
        sprintf("design <- expand.grid(participant = seq_len(%d), item = seq_len(%d))", n, inputs$items),
        sprintf("design$cond <- ifelse(design$item <= %d, -0.5, 0.5) # the first half of the items in the first condition", inputs$items %/% 2)
      )
    },
    "design$participant <- factor(design$participant)",
    "design$item <- factor(design$item)",
    if (inputs$participants_between) {
      sprintf("participant_var <- %s", r_code(inputs$VarCorr$participant))
    } else {
      sprintf("participant_var <- matrix(%s, nrow = 2)", r_code(as.vector(inputs$VarCorr$participant)))
    },
    if (inputs$binary) {
      sprintf(
        "model <- simr::makeGlmer(%s, family = \"binomial\", fixef = %s, VarCorr = list(participant = participant_var, item = %s), data = design)",
        deparse1(inputs$formula), r_code(inputs$fixef), item_var
      )
    } else {
      sprintf(
        "model <- simr::makeLmer(%s, fixef = %s, VarCorr = list(participant = participant_var, item = %s), sigma = %s, data = design)",
        deparse1(inputs$formula), r_code(inputs$fixef), item_var, r_code(inputs$sigma)
      )
    },
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
# found), the n of a precision plan, otherwise the n the spec gives.
simulated_data_n <- function(spec, result) {
  n <- if (identical(spec$goal$type, "sample_size")) {
    result$n_required$n
  } else if (identical(spec$goal$type, "precision")) {
    result$precision$n
  } else {
    spec$goal$n
  }
  if (is.numeric(n) && length(n) == 1 && !is.na(n)) n
}

# People in groups (E41): the design and model the simulation uses
# (two_level_design(), two_level_inputs()), one row per person.
sim_two_level_code <- function(spec, n) {
  inputs <- two_level_inputs(spec)
  n <- (n %/% inputs$cluster_size) * inputs$cluster_size
  c(
    sprintf("cluster_size <- %d", as.integer(inputs$cluster_size)),
    sprintf("groups <- %d", as.integer(n / inputs$cluster_size)),
    "x <- qnorm(seq_len(cluster_size) / (cluster_size + 1))",
    "w <- qnorm((seq_len(groups) - 0.5) / groups)",
    "design <- data.frame(group = factor(rep(seq_len(groups), each = cluster_size)),",
    "  x = rep((x - mean(x)) / sqrt(mean((x - mean(x))^2)), groups),",
    "  w = rep((w - mean(w)) / sqrt(mean((w - mean(w))^2)), each = cluster_size))",
    sprintf("group_var <- matrix(%s, nrow = 2)", r_code(as.vector(inputs$VarCorr$group))),
    sprintf("model <- simr::makeLmer(%s, fixef = %s, VarCorr = list(group = group_var), sigma = %s, data = design)",
      deparse1(inputs$formula), r_code(inputs$fixef), r_code(inputs$sigma)),
    "simulated <- data.frame(",
    "  group = design$group,",
    sprintf("  %s = design$x,", sim_label(spec, "X")),
    sprintf("  %s = design$w,", sim_label(spec, "W")),
    sprintf("  %s = stats::simulate(model)[[1]]", sim_label(spec, "Y")),
    ")"
  )
}

# Participants and items in three or more conditions (E63): the same design
# and model as the simulation (crossed_conditions_design(),
# crossed_conditions_inputs()), one row per participant per item.
sim_crossed_conditions_code <- function(spec, n) {
  inputs <- crossed_conditions_inputs(spec)
  var_corr <- paste(sprintf("`%s` = %s", names(inputs$VarCorr), vapply(inputs$VarCorr, r_code, "")), collapse = ", ")
  c(
    sprintf("conditions <- %s", r_code(inputs$levels)),
    if (inputs$participants_between) {
      c(
        sprintf("design <- expand.grid(participant = seq_len(%d), item = seq_len(%d))", n, inputs$items),
        sprintf("design$cond <- conditions[ceiling(design$participant / %s)] # the participants split equally, one group per condition",
          r_code(n / length(inputs$levels))),
        if (!inputs$within) sprintf("design <- design[ceiling(design$item / %d) == match(design$cond, conditions), ] # each condition's own block of items",
          inputs$items %/% length(inputs$levels))
      )
    } else if (inputs$within) {
      sprintf("design <- expand.grid(participant = seq_len(%d), item = seq_len(%d), cond = conditions, stringsAsFactors = FALSE)",
        n, inputs$items)
    } else {
      c(
        sprintf("design <- expand.grid(participant = seq_len(%d), item = seq_len(%d))", n, inputs$items),
        sprintf("design$cond <- conditions[ceiling(design$item / %d)] # the items split equally, one block per condition",
          inputs$items %/% length(inputs$levels))
      )
    },
    "design$participant <- factor(design$participant)",
    "design$item <- factor(design$item)",
    "design$cond <- factor(design$cond, levels = conditions)",
    if (inputs$binary) {
      sprintf("model <- simr::makeGlmer(%s, family = \"binomial\", fixef = %s, VarCorr = list(%s), data = design)",
        deparse1(inputs$formula), r_code(inputs$fixef), var_corr)
    } else {
      sprintf("model <- simr::makeLmer(%s, fixef = %s, VarCorr = list(%s), sigma = %s, data = design)",
        deparse1(inputs$formula), r_code(inputs$fixef), var_corr, r_code(inputs$sigma))
    },
    "simulated <- data.frame(",
    "  participant = design$participant,",
    "  item = design$item,",
    sprintf("  %s = design$cond,", sim_label(spec, "X")),
    sprintf("  %s = stats::simulate(model)[[1]]", sim_label(spec, "Y")),
    ")"
  )
}
