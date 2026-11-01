# Precision planning (design "precision"): the sample size for a target
# confidence-interval width, or the width expected at a given sample size,
# rather than power.
#
# Every number comes from a package:
#   Cohen's d, two equal groups      MBESS's ss.aipe.smd() for n (per group),
#                                    with assurance if asked; the width at n
#                                    from MBESS's ci.smd() at d = delta, the
#                                    width ss.aipe.smd() aims at
#   standardised mean (one group)    MBESS's ss.aipe.sm() and ci.sm()
#   d_z (paired)                     the same, on the differences
#   correlation                      presize's prec_cor() (Fisher's z, with
#                                    presize's corrections for Spearman's and
#                                    Kendall's coefficients)
#   one proportion                   presize's prec_prop() (Wilson's interval
#                                    by default, presize's own default)
#   mean difference (raw units)      presize's prec_meandiff(), two equal
#                                    groups, equal variances
#   odds ratio                       presize's prec_or() (the independence-
#                                    smoothed logit interval by default,
#                                    presize's own default), the second
#                                    group's odds over the first's
#   ICC                              (the expected width only: presize gives
#                                    no limits)
#   ICC                              presize's prec_icc() (k ratings of each
#                                    subject)
#   regression coefficient           MBESS's ss.aipe.reg.coef() for the
#                                    standardised coefficient; the width at
#                                    a given n is the narrowest width for
#                                    which ss.aipe.reg.coef() needs no more
#                                    than n (1 November 2026)
# MBESS (Kelley, the package's own citation()) and presize (Haynes et al.,
# 2021, its citation()) are cited from their citation() entries.
#
# MBESS's AIPE functions set options(warn = -10) or (warn = -1) globally
# (their source, MBESS 4.9.x and 5.0.1), so every call restores the warning
# level it found.

precision_goal <- function(spec) identical(spec$goal$type, "precision")

precision_mbess <- function(spec) spec$template %in% c("two_groups", "one_group", "paired")

precision_regression <- function(spec) identical(spec$template, "regression_coefficient")

precision_effect <- function(spec) {
  pop <- spec$population
  switch(spec$template, two_groups = pop$d, one_group = pop$d, paired = pop$dz, correlation = pop$r, proportion = pop$p,
    mean_difference = pop$difference, odds_ratio = (pop$p2 / (1 - pop$p2)) / (pop$p1 / (1 - pop$p1)), icc = pop$icc,
    regression_coefficient = pop$b)
}

precision_effect_name <- function(spec) {
  switch(spec$template, two_groups = "d", one_group = "d", paired = "d_z", correlation = "r", proportion = "p",
    mean_difference = "mean difference", odds_ratio = "odds ratio", icc = "ICC", regression_coefficient = "standardised b")
}

precision_conf_level <- function(spec) 1 - spec$target_test$alpha

precision_presize_method <- function(spec) {
  switch(spec$target_test$method, agresti_coull = "agresti-coull", spec$target_test$method %||% "")
}

# Calls a package function with the warning level restored afterwards.
keep_warn <- function(expr) {
  old <- getOption("warn")
  on.exit(options(warn = old), add = TRUE)
  expr
}

# Spec checks for the precision design and goal (validate_spec()).
check_precision <- function(spec) {
  goal <- spec$goal
  if (precision_goal(spec) && !identical(spec$design, "precision")) {
    return("'goal > type' \"precision\" is only for the precision design ('design' \"precision\"): choose 'sample_size', 'power' or 'sensitivity' here.")
  }
  if (!identical(spec$design, "precision")) return(character(0))
  problems <- character(0)
  has_width <- !is.null(goal$width)
  has_n <- !is.null(goal$n)
  if (has_width == has_n) {
    problems <- c(problems, "A precision goal needs either 'goal > width' (the interval width wanted, to find the sample size) or 'goal > n' (to find the width expected), not both and not neither.")
  }
  if (!is.null(goal$assurance) && !has_width) {
    problems <- c(problems, "'goal > assurance' applies when finding the sample size for a width ('goal > width'), not at a given n.")
  }
  if (identical(spec$template, "correlation") && has_width && goal$width >= 2) {
    problems <- c(problems, "A correlation's interval can't be 2 or more wide: 'goal > width' should be below 2.")
  }
  if (identical(spec$template, "icc") && has_width && goal$width >= 2) {
    problems <- c(problems, "An ICC's interval can't be 2 or more wide: 'goal > width' should be below 2.")
  }
  if (identical(spec$template, "regression_coefficient")) {
    pop <- spec$population
    if (!is.null(pop$r2) && !is.null(pop$b) && !is.null(pop$r2_predictor) && pop$b^2 * (1 - pop$r2_predictor) > pop$r2) {
      problems <- c(problems, "The predictor alone explains more of the outcome than all the predictors together: 'population > b' squared, times (1 - 'r2_predictor'), can't be larger than 'r2'.")
    }
  }
  if (identical(spec$template, "proportion") && has_width && goal$width >= 1) {
    problems <- c(problems, "A proportion's interval can't be 1 or more wide: 'goal > width' should be below 1.")
  }
  if (has_n) {
    smallest <- switch(spec$template, two_groups = 4L, mean_difference = 4L, odds_ratio = 4L, correlation = 5L,
      regression_coefficient = as.integer(spec$population$predictors %||% 1) + 3L, 3L)
    if (goal$n < smallest) problems <- c(problems, sprintf("'goal > n' should be at least %d for this interval.", smallest))
    if (spec$template %in% c("mean_difference", "odds_ratio") && goal$n %% 2 != 0) {
      problems <- c(problems, "For two groups, 'goal > n' is the total and should be even: two equal groups.")
    }
    if (identical(spec$template, "two_groups") && goal$n %% 2 != 0) {
      problems <- c(problems, "For two groups, 'goal > n' is the total and should be even: two equal groups.")
    }
  }
  if (identical(spec$template, "proportion") && identical(spec$target_test$method, "wald") && has_n) {
    p <- spec$population$p
    if (goal$n * min(p, 1 - p) < 5) {
      problems <- c(problems, "The Wald interval needs at least 5 expected in each outcome (n times the proportion, and n times one minus it); choose Wilson's interval, or a larger n.")
    }
  }
  problems
}

# The calculation: list(n, width, lower, upper, effect, ...). For a width
# goal, n is the total and width the width expected at it.
precision_calculate <- function(spec) {
  goal <- spec$goal
  level <- precision_conf_level(spec)
  effect <- precision_effect(spec)
  if (precision_mbess(spec)) precision_mbess_calculate(spec, effect, level, goal) else
    if (precision_regression(spec)) precision_regression_calculate(spec, effect, level, goal) else
    precision_presize_calculate(spec, effect, level, goal)
}

precision_mbess_calculate <- function(spec, effect, level, goal) {
  two <- identical(spec$template, "two_groups")
  interval_at <- function(size) {
    lims <- call_backend("MBESS", keep_warn(quietly(if (two) {
      MBESS::ci.smd(smd = effect, n.1 = size / 2, n.2 = size / 2, conf.level = level)
    } else {
      MBESS::ci.sm(sm = effect, N = size, conf.level = level)
    })))
    lower <- if (two) lims$Lower.Conf.Limit.smd else lims$Lower.Conf.Limit.Standardized.Mean
    upper <- if (two) lims$Upper.Conf.Limit.smd else lims$Upper.Conf.Limit.Standardized.Mean
    list(lower = lower, upper = upper, width = upper - lower)
  }
  if (!is.null(goal$width)) {
    found <- call_backend("MBESS", keep_warn(quietly(if (two) {
      MBESS::ss.aipe.smd(delta = effect, conf.level = level, width = goal$width, assurance = goal$assurance)
    } else {
      MBESS::ss.aipe.sm(sm = effect, width = goal$width, conf.level = level, assurance = goal$assurance)
    })))
    n <- as.integer(if (two) 2 * found else found)
  } else {
    n <- as.integer(goal$n)
  }
  c(list(n = n), interval_at(n), list(
    function_used = if (!is.null(goal$width)) {
      if (two) "MBESS::ss.aipe.smd" else "MBESS::ss.aipe.sm"
    } else if (two) "MBESS::ci.smd" else "MBESS::ci.sm",
    package = "MBESS"
  ))
}

precision_presize_calculate <- function(spec, effect, level, goal) {
  method <- precision_presize_method(spec)
  pop <- spec$population
  template <- spec$template
  # Two equal groups: presize's n1 is per group, and powerkit's n the total.
  two <- template %in% c("mean_difference", "odds_ratio")
  call <- function(n = NULL, conf.width = NULL) {
    call_backend("presize", quietly(switch(template,
      correlation = presize::prec_cor(r = effect, conf.level = level, method = method, n = n, conf.width = conf.width),
      proportion = presize::prec_prop(p = effect, conf.level = level, method = method, n = n, conf.width = conf.width),
      mean_difference = presize::prec_meandiff(delta = pop$difference, sd1 = pop$sd, n1 = if (!is.null(n)) n / 2,
        conf.width = conf.width, conf.level = level, variance = "equal"),
      # presize's odds ratio is its p1's odds over p2's: the groups are
      # passed in reverse so that it is the second group's over the first's.
      odds_ratio = presize::prec_or(p1 = pop$p2, p2 = pop$p1, n1 = if (!is.null(n)) n / 2, conf.width = conf.width,
        conf.level = level, method = method),
      icc = presize::prec_icc(rho = pop$icc, k = pop$raters, n = n, conf.width = conf.width, conf.level = level)
    )))
  }
  if (!is.null(goal$width)) {
    found <- call(conf.width = goal$width)
    n <- if (two) 2L * as.integer(ceiling(found$n1 - 1e-9)) else as.integer(ceiling(found$n - 1e-9))
  } else {
    n <- as.integer(goal$n)
  }
  # The width at the whole n (presize's search can return a fraction).
  at_n <- call(n = n)
  # prec_icc() gives the expected width only, not the limits.
  list(
    n = n, lower = at_n$lwr %||% NA_real_, upper = at_n$upr %||% NA_real_, width = at_n$conf.width,
    function_used = paste0("presize::", precision_presize_function(spec)),
    package = "presize"
  )
}

precision_presize_function <- function(spec) {
  switch(spec$template, correlation = "prec_cor", proportion = "prec_prop", mean_difference = "prec_meandiff",
    odds_ratio = "prec_or", icc = "prec_icc")
}

# A standardised regression coefficient: MBESS's ss.aipe.reg.coef() (the
# sample size for an expected width, with assurance if asked). Its
# interval is symmetric about b, so the limits are b -/+ width / 2. At a
# given n, the width expected is the narrowest for which the same
# function asks for no more than n.
precision_regression_n <- function(spec, width, level, assurance = NULL) {
  pop <- spec$population
  out <- call_backend("MBESS", keep_warn(quietly(MBESS::ss.aipe.reg.coef(
    Rho2.Y_X = pop$r2, Rho2.j_X.without.j = pop$r2_predictor, p = pop$predictors, b.j = pop$b, width = width,
    sigma.Y = 1, sigma.X = 1, conf.level = level, assurance = assurance, Suppress.Statement = TRUE
  ))))
  as.integer(if (is.list(out)) out[[1]] else out)
}

precision_regression_calculate <- function(spec, effect, level, goal) {
  if (!is.null(goal$width)) {
    n <- precision_regression_n(spec, goal$width, level, goal$assurance)
    width <- goal$width
  } else {
    n <- as.integer(goal$n)
    needs <- function(w) precision_regression_n(spec, w, level) - n
    width <- stats::uniroot(function(w) needs(w) - 0.5, c(1e-3, 4), tol = 1e-8)$root
  }
  list(
    n = n, lower = effect - width / 2, upper = effect + width / 2, width = width,
    function_used = "MBESS::ss.aipe.reg.coef", package = "MBESS"
  )
}

run_precision <- function(spec, seed) {
  started <- Sys.time()
  goal <- spec$goal
  found <- precision_calculate(spec)
  effect <- precision_effect(spec)
  precision <- list(
    effect_name = precision_effect_name(spec),
    effect = effect,
    conf_level = precision_conf_level(spec),
    method = spec$target_test$method,
    target_width = goal$width %||% NA_real_,
    assurance = goal$assurance %||% NA_real_,
    n = found$n,
    width = found$width,
    lower = found$lower,
    upper = found$upper,
    function_used = found$function_used
  )
  check <- data.frame(
    parameter = c(
      sprintf("expected %s passed to %s", precision$effect_name, found$package),
      "confidence level passed (1 - alpha)"
    ),
    specified = c(effect, precision$conf_level),
    recovered = c(effect, precision$conf_level),
    ok = TRUE
  )
  n_required <- if (!is.null(goal$width)) list(n = found$n, lower = found$n, upper = found$n) else NA
  structure(
    list(
      goal_type = goal$type,
      curve = data.frame(n = found$n, power = NA_real_, mcse = 0),
      n_required = n_required,
      sensitivity = NA,
      precision = precision,
      recruitment = recruitment_target(spec, found$n),
      check_run = check,
      provenance = list(
        spec_hash = spec_hash(spec),
        method = "exact",
        seed = seed,
        nrep = NA_integer_,
        cores = NA_integer_,
        batch_size = NA_integer_,
        simulations = NA,
        backend = found$package,
        backend_function = found$function_used,
        r_version = R.version.string,
        packages = package_versions(c("powerkit", found$package)),
        started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
        run_time_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
      )
    ),
    class = "powerkit_result"
  )
}

# The R script: the same package call, and a check that it reproduces
# powerkit's answer (export_script()).
precision_script <- function(spec, result) {
  if (spec$template %in% c("mean_difference", "odds_ratio", "icc", "regression_coefficient")) {
    return(precision_script_more(spec, result))
  }
  pr <- result$precision
  goal <- spec$goal
  two <- identical(spec$template, "two_groups")
  mbess <- precision_mbess(spec)
  package <- if (mbess) "MBESS" else "presize"
  effect_arg <- switch(spec$template, two_groups = "delta", correlation = "r", proportion = "p", "sm")
  find <- if (is.null(goal$width)) {
    sprintf("n <- %s # total sample size", r_code(pr$n))
  } else if (mbess) {
    assurance <- if (is.na(pr$assurance)) "" else ", assurance = assurance"
    if (two) {
      c(sprintf("n_per_group <- ss.aipe.smd(delta = effect, conf.level = conf_level, width = width%s)", assurance),
        "n <- 2 * n_per_group # total, in two equal groups")
    } else {
      sprintf("n <- ss.aipe.sm(sm = effect, width = width, conf.level = conf_level%s)", assurance)
    }
  } else {
    sprintf("n <- ceiling(%s(%s = effect, conf.width = width, conf.level = conf_level, method = method)$n - 1e-9)",
      if (identical(spec$template, "correlation")) "prec_cor" else "prec_prop", effect_arg)
  }
  interval <- if (mbess) {
    if (two) {
      c("limits <- ci.smd(smd = effect, n.1 = n / 2, n.2 = n / 2, conf.level = conf_level)",
        "lower <- limits$Lower.Conf.Limit.smd",
        "upper <- limits$Upper.Conf.Limit.smd")
    } else {
      c("limits <- ci.sm(sm = effect, N = n, conf.level = conf_level)",
        "lower <- limits$Lower.Conf.Limit.Standardized.Mean",
        "upper <- limits$Upper.Conf.Limit.Standardized.Mean")
    }
  } else {
    c(sprintf("limits <- %s(%s = effect, n = n, conf.level = conf_level, method = method)",
        if (identical(spec$template, "correlation")) "prec_cor" else "prec_prop", effect_arg),
      "lower <- limits$lwr",
      "upper <- limits$upr")
  }
  c(
    script_header(spec, result, package, sprintf("%s (the confidence interval's width, not power)", pr$function_used)),
    sprintf("library(%s)", package),
    "",
    "# Inputs ----",
    sprintf("effect <- %s # the expected %s", r_code(pr$effect), pr$effect_name),
    sprintf("conf_level <- %s # the confidence level", r_code(pr$conf_level)),
    if (!is.null(goal$width)) sprintf("width <- %s # the full width wanted (upper limit minus lower)", r_code(goal$width)),
    if (!is.na(pr$assurance)) sprintf("assurance <- %s # the chance the width is no more than that", r_code(pr$assurance)),
    if (!mbess) sprintf("method <- %s", r_code(precision_presize_method(spec))),
    "",
    "# Sample size and interval ----",
    find,
    interval,
    "cat(sprintf(\"n = %d: expected interval %.4f to %.4f (width %.4f)\\n\", n, lower, upper, upper - lower))",
    "",
    "reproduced <- list(n = n, width = upper - lower)",
    sprintf("powerkit_result <- list(n = %s, width = %s)", r_code(pr$n), r_code(pr$width)),
    "",
    comparison_section()
  )
}

# The script for the estimates added on 1 November 2026: the same package
# call, and a check that it reproduces powerkit's answer.
precision_script_more <- function(spec, result) {
  pr <- result$precision
  goal <- spec$goal
  pop <- spec$population
  template <- spec$template
  regression <- identical(template, "regression_coefficient")
  package <- if (regression) "MBESS" else "presize"
  inputs <- switch(template,
    mean_difference = c(sprintf("difference <- %s # the expected difference between the group means, in the outcome's units", r_code(pop$difference)),
      sprintf("sd <- %s # the outcome's SD within each group", r_code(pop$sd))),
    odds_ratio = c(sprintf("p1 <- %s # the chance of 'yes' in the first group", r_code(pop$p1)),
      sprintf("p2 <- %s # the chance of 'yes' in the second group", r_code(pop$p2)),
      sprintf("method <- %s", r_code(precision_presize_method(spec))),
      "# presize's odds ratio is its p1's odds over p2's, so the groups go in reversed: group 2's odds over group 1's."),
    icc = c(sprintf("icc <- %s # the expected ICC", r_code(pop$icc)),
      sprintf("raters <- %s # ratings of each subject", r_code(pop$raters))),
    regression_coefficient = c(sprintf("b <- %s # the expected standardised coefficient", r_code(pop$b)),
      sprintf("r2 <- %s # R-squared of the full model", r_code(pop$r2)),
      sprintf("r2_predictor <- %s # R-squared of this predictor on the others", r_code(pop$r2_predictor)),
      sprintf("predictors <- %s # predictors in the model", r_code(pop$predictors)))
  )
  presize_call <- function(size_arg) switch(template,
    mean_difference = sprintf("prec_meandiff(delta = difference, sd1 = sd, %s, conf.level = conf_level, variance = \"equal\")", size_arg),
    odds_ratio = sprintf("prec_or(p1 = p2, p2 = p1, %s, conf.level = conf_level, method = method)", size_arg),
    icc = sprintf("prec_icc(rho = icc, k = raters, %s, conf.level = conf_level)", size_arg))
  two <- template %in% c("mean_difference", "odds_ratio")
  reg_call <- function(width_arg, assurance_arg = "") sprintf(
    "ss.aipe.reg.coef(Rho2.Y_X = r2, Rho2.j_X.without.j = r2_predictor, p = predictors, b.j = b, width = %s, sigma.Y = 1, sigma.X = 1, conf.level = conf_level%s, Suppress.Statement = TRUE)",
    width_arg, assurance_arg)
  find <- if (is.null(goal$width)) {
    sprintf("n <- %s # total sample size", r_code(pr$n))
  } else if (regression) {
    sprintf("n <- as.integer(unlist(%s)[1])", reg_call("width", if (is.na(pr$assurance)) "" else ", assurance = assurance"))
  } else if (two) {
    c(sprintf("n_per_group <- ceiling(%s$n1 - 1e-9)", presize_call("conf.width = width")), "n <- 2 * n_per_group # total, in two equal groups")
  } else {
    sprintf("n <- ceiling(%s$n - 1e-9)", presize_call("conf.width = width"))
  }
  interval <- if (regression) {
    c(if (is.null(goal$width)) {
      c("# The narrowest width for which ss.aipe.reg.coef() needs no more than n.",
        sprintf("needs <- function(w) as.integer(unlist(%s)[1]) - n", reg_call("w")),
        "width <- uniroot(function(w) needs(w) - 0.5, c(1e-3, 4), tol = 1e-8)$root")
    },
      "lower <- b - width / 2",
      "upper <- b + width / 2")
  } else {
    c(sprintf("limits <- %s", presize_call(if (two) "n1 = n / 2" else "n = n")),
      if (identical(template, "icc")) {
        c("width <- limits$conf.width # prec_icc() gives the expected width, not the limits",
          "lower <- NA", "upper <- NA")
      } else c("lower <- limits$lwr", "upper <- limits$upr"))
  }
  c(
    script_header(spec, result, package, sprintf("%s (the confidence interval's width, not power)", pr$function_used)),
    sprintf("library(%s)", package),
    "",
    "# Inputs ----",
    inputs,
    sprintf("conf_level <- %s # the confidence level", r_code(pr$conf_level)),
    if (!is.null(goal$width)) sprintf("width <- %s # the full width wanted (upper limit minus lower)", r_code(goal$width)),
    if (!is.na(pr$assurance)) sprintf("assurance <- %s # the chance the width is no more than that", r_code(pr$assurance)),
    "",
    "# Sample size and interval ----",
    find,
    interval,
    if (identical(template, "icc")) "cat(sprintf(\"n = %d: expected width %.4f\\n\", n, width))" else
      "cat(sprintf(\"n = %d: expected interval %.4f to %.4f (width %.4f)\\n\", n, lower, upper, upper - lower))",
    "",
    if (identical(template, "icc")) "reproduced <- list(n = n, width = width)" else "reproduced <- list(n = n, width = upper - lower)",
    sprintf("powerkit_result <- list(n = %s, width = %s)", r_code(pr$n), r_code(pr$width)),
    "",
    comparison_section()
  )
}
