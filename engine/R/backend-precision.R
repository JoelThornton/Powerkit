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
# MBESS (Kelley, the package's own citation()) and presize (Haynes et al.,
# 2021, its citation()) are cited from their citation() entries.
#
# MBESS's AIPE functions set options(warn = -10) or (warn = -1) globally
# (their source, MBESS 4.9.x and 5.0.1), so every call restores the warning
# level it found.

precision_goal <- function(spec) identical(spec$goal$type, "precision")

precision_mbess <- function(spec) spec$template %in% c("two_groups", "one_group", "paired")

precision_effect <- function(spec) {
  pop <- spec$population
  switch(spec$template, two_groups = pop$d, one_group = pop$d, paired = pop$dz, correlation = pop$r, proportion = pop$p)
}

precision_effect_name <- function(spec) {
  switch(spec$template, two_groups = "d", one_group = "d", paired = "d_z", correlation = "r", proportion = "p")
}

precision_conf_level <- function(spec) 1 - spec$target_test$alpha

precision_presize_method <- function(spec) {
  switch(spec$target_test$method, agresti_coull = "agresti-coull", spec$target_test$method)
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
  if (identical(spec$template, "proportion") && has_width && goal$width >= 1) {
    problems <- c(problems, "A proportion's interval can't be 1 or more wide: 'goal > width' should be below 1.")
  }
  if (has_n) {
    smallest <- switch(spec$template, two_groups = 4L, correlation = 5L, 3L)
    if (goal$n < smallest) problems <- c(problems, sprintf("'goal > n' should be at least %d for this interval.", smallest))
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
  call <- function(...) {
    call_backend("presize", quietly(if (identical(spec$template, "correlation")) {
      presize::prec_cor(r = effect, conf.level = level, method = method, ...)
    } else {
      presize::prec_prop(p = effect, conf.level = level, method = method, ...)
    }))
  }
  if (!is.null(goal$width)) {
    found <- call(conf.width = goal$width)
    n <- as.integer(ceiling(found$n - 1e-9))
  } else {
    n <- as.integer(goal$n)
  }
  # The width at the whole n (presize's search can return a fraction).
  at_n <- call(n = n)
  list(
    n = n, lower = at_n$lwr, upper = at_n$upr, width = at_n$conf.width,
    function_used = if (identical(spec$template, "correlation")) "presize::prec_cor" else "presize::prec_prop",
    package = "presize"
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
