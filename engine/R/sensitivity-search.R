# The smallest detectable effect for the formula tests outside pwrss whose
# power powerkit computes exactly: the variance tests and Hotelling's
# T-squared (stats, by the G*Power manual's distributions,
# backend-variance.R and backend-hotelling.R) and the equivalence tests
# (TOSTER). None of these solves for the effect, so, as for pwrss's tests
# (sensitivity-pwrss.R), the effect is searched with the backend's own power
# at the fixed n: power on a fixed grid from the smallest effect up, the
# first grid point that reaches the target, then uniroot() between it and
# the point before (pwrss_search_root()). No new formula. The exported
# script repeats the search with the script's own power_at()
# (pwrss_search_section(), export-script-pwrss.R).
#
# What is searched, the rest of the population kept as entered:
#   one variance       the ratio of the variance to the fixed value, on the
#                      side the test looks at (as G*Power's sensitivity
#                      analysis reports it)
#   two variances      the ratio of group 1's variance to group 2's
#   Hotelling's T2     the Mahalanobis distance of the means from the fixed
#   (one sample, or    values, or between the two groups' means; the
#   two groups)        pattern entered keeps its shape and is scaled
#   equivalence (TOST) the narrowest equivalence bounds (-bound, +bound) at
#                      which the test shows equivalence with the target
#                      power, the expected difference kept: the equivalence
#                      test's sensitivity analysis (Lakens, 2017, on
#                      TOSTER's power functions)
#   meta-analysis      the average effect (d or r), the typical study's size
#   (z test)           and I-squared kept (metapower's mpower())
#   SEM model fit      the population RMSEA: for exact fit (semPower) the
#                      smallest the test would detect; for close fit
#                      (WebPower) the smallest above the null RMSEA; for
#                      not-close fit the largest below it at which the test
#                      would show close fit
#   SEM factor         the correlation between the two factors, the items
#   correlation        and loadings kept (semPower.powerCFA())
#   SEM latent slope   the slope tested, the other slopes, the predictors'
#                      correlation and the items kept
#                      (semPower.powerRegression()); it stays where the
#                      outcome's explained variance is below 1

formula_search_available <- function(spec) {
  !is.null(formula_search_kind(spec))
}

formula_search_kind <- function(spec) {
  if (variance_formula_test(spec)) return(spec$template)
  if (hotelling_formula_test(spec) && !permanova_test(spec) && !identical(spec$options$method, "simulation")) return("hotelling")
  if (identical(spec$design, "equivalence_test") && identical(spec$target_test$method %||% "tost", "tost")) return("tost")
  if (identical(spec$design, "meta_analysis") && identical(spec$template, "mean_effect") && !hartung_knapp_test(spec)) return("meta")
  if (identical(spec$design, "sem") && isTRUE(spec$template %in% c("model_fit", "factor_correlation", "latent_regression"))) {
    return(paste0("sem_", spec$template))
  }
  if (identical(spec$design, "ordinal_regression") && identical(spec$template, "ordinal_two_groups")) return("ordinal_two_groups")
  if (identical(spec$design, "survival") && isTRUE(spec$template %in% c("log_rank", "cox_predictor"))) return(spec$template)
  if (identical(spec$design, "mixed_model") && identical(spec$template, "growth_curve")) return("growth_curve")
  if (identical(spec$design, "reliability") && isTRUE(spec$template %in% c("icc", "cronbach_alpha", "kappa"))) return(paste0("reliability_", spec$template))
  NULL
}

# Whether the search scales the pattern entered (so a zero pattern can't
# be searched).
formula_search_scales_pattern <- function(spec) identical(formula_search_kind(spec), "hotelling")

formula_search_plan <- function(spec) {
  pop <- spec$population
  log_grid <- function(lower, upper, k = 200) exp(seq(log(lower), log(upper), length.out = k))
  kind <- formula_search_kind(spec)
  switch(kind,
    one_variance = ,
    two_variances = {
      one <- kind == "one_variance"
      entered <- if (one) pop$var / pop$var0 else pop$var1 / pop$var2
      direction <- pwrss_search_direction(spec, log(entered))
      list(
        grid = log_grid(1e-4, log(1e3)),
        direction = direction,
        power = function(s, n) variance_power(variance_inputs(s), n),
        set = if (one) {
          function(s, x) { s$population$var <- pop$var0 * exp(direction * x); s }
        } else {
          function(s, x) { s$population$var1 <- pop$var2 * exp(direction * x); s }
        },
        script = "ratio <<- exp(direction * x)",
        effect = function(x) exp(direction * x), effect_script = "exp(direction * found)",
        effect_name = "variance_ratio",
        what = if (one) {
          sprintf("ratio of the variance to the fixed value %s", format(pop$var0))
        } else {
          sprintf("ratio of group 1's variance to group 2's, with group 2's kept at %s", format(pop$var2))
        },
        extra = function(x) {
          ratio <- exp(direction * x)
          if (one) list(variance = pop$var0 * ratio) else list(variance = pop$var2 * ratio)
        }
      )
    },
    hotelling = {
      two <- identical(spec$template, "manova")
      entered <- sqrt(hotelling_inputs(spec)$distance2)
      # The pattern entered, scaled so its distance is x.
      scaled_means <- function(x) {
        k <- x / entered
        if (two) {
          means <- manova_means(spec)
          centre <- colMeans(means)
          rows <- sweep(sweep(means, 2, centre) * k, 2, centre, "+")
          lapply(seq_len(nrow(rows)), function(i) as.list(rows[i, ]))
        } else {
          mu0 <- as.numeric(unlist(pop$mu0))
          as.list(mu0 + k * (as.numeric(unlist(pop$means)) - mu0))
        }
      }
      list(
        grid = log_grid(1e-4, 50),
        power = function(s, n) hotelling_power(hotelling_inputs(s), n),
        set = function(s, x) { s$population$means <- scaled_means(x); s },
        script = "distance2 <<- x^2",
        effect = function(x) x, effect_script = "found",
        effect_name = "mahalanobis",
        what = if (two) {
          "Mahalanobis distance between the two groups' means (the difference in SDs, allowing for the outcomes' correlations), with the pattern of means you entered kept and scaled"
        } else {
          "Mahalanobis distance of the means from the fixed values (the difference in SDs, allowing for the outcomes' correlations), with the pattern of means you entered kept and scaled"
        },
        extra = function(x) list(means = scaled_means(x), scale = x / entered)
      )
    },
    meta = {
      direction <- pwrss_search_direction(spec, pop$effect %||% 0)
      r <- identical(pop$metric, "r")
      list(
        # metapower is slow, so a coarser grid (uniroot() does the rest).
        grid = log_grid(1e-3, if (r) 0.99 else 5, 50),
        direction = direction,
        power = function(s, n) metapower_backend(s)$exact_power(n),
        set = function(s, x) { s$population$effect <- direction * x; s },
        script = "effect_size <<- x",
        effect = function(x) direction * x, effect_script = "direction * found",
        effect_name = if (r) "meta_r" else "meta_d",
        what = sprintf("average effect, as %s, with studies of %s participants and I-squared %s",
          if (r) "a correlation r" else "Cohen's d", format(pop$study_size), format(pop$i2))
      )
    },
    sem_model_fit = {
      method <- spec$target_test$method %||% "chi_square_exact_fit"
      null <- sem_rmsea_null(spec)
      not_close <- identical(method, "chi_square_not_close_fit")
      start <- if (identical(method, "chi_square_close_fit")) null else 0
      # Close fit: power rises from alpha as the RMSEA moves above the
      # null value; not-close fit: as it moves below it.
      direction <- if (not_close) -1 else 1
      if (not_close) start <- null
      list(
        grid = log_grid(1e-4, if (not_close) null - 1e-4 else 0.5),
        # The model's df, counted once (semPower counts it with lavaan).
        power = local({
          df <- sem_df(spec)
          if (sem_close_fit_test(spec)) function(s, n) webpower_rmsea_power(s, n, df) else function(s, n) sempower_power(s, n, df)
        }),
        set = function(s, x) { s$population$rmsea <- start + direction * x; s },
        script = sprintf("rmsea <<- %s", if (start == 0) "x" else sprintf("rmsea_null %s x", if (not_close) "-" else "+")),
        effect = function(x) start + direction * x,
        effect_script = if (start == 0) "found" else sprintf("rmsea_null %s found", if (not_close) "-" else "+"),
        effect_name = "rmsea",
        description = switch(method,
          chi_square_not_close_fit = sprintf("the largest RMSEA, below the null value %s, at which the test of not-close fit would show close fit", format(null)),
          chi_square_close_fit = sprintf("the smallest RMSEA, above the null value %s, that the test of close fit would detect", format(null)),
          "the smallest misfit (RMSEA) the test of exact fit would detect")
      )
    },
    sem_factor_correlation = {
      direction <- pwrss_search_direction(spec, pop$r)
      list(
        grid = log_grid(1e-3, 0.99, 40),
        direction = direction,
        power = function(s, n) sempower_restriction_backend(s)$exact_power(n),
        set = function(s, x) { s$population$r <- direction * x; s },
        script_before = sem_fit_with_lines(spec, "Phi", "value"),
        script = "fit <<- fit_with(direction * x)",
        effect = function(x) direction * x, effect_script = "direction * found",
        effect_name = "factor_r",
        description = "the correlation between the two factors, with the items and loadings kept as entered"
      )
    },
    sem_latent_regression = {
      tested <- pop$tested %||% 1L
      slopes <- as.numeric(unlist(pop$slopes))
      direction <- pwrss_search_direction(spec, slopes[tested])
      upper <- sem_slope_limit(spec, direction)
      list(
        grid = log_grid(1e-3, upper, 40),
        direction = direction,
        power = function(s, n) sempower_restriction_backend(s)$exact_power(n),
        set = function(s, x) { s$population$slopes <- as.list(replace(slopes, tested, direction * x)); s },
        script_before = sem_fit_with_lines(spec, "slopes", sprintf("replace(%s, %s, value)", r_code(slopes), tested)),
        script = "fit <<- fit_with(direction * x)",
        effect = function(x) direction * x, effect_script = "direction * found",
        effect_name = "latent_slope",
        description = if (length(slopes) > 1) {
          sprintf("standardised slope of predictor %s, with the other slopes, the predictors' correlation and the items kept as entered", tested)
        } else {
          "standardised slope of the latent predictor, with the items kept as entered"
        }
      )
    },
    ordinal_two_groups = {
      direction <- pwrss_search_direction(spec, log(pop$odds_ratio))
      list(
        grid = log_grid(1e-4, log(100)),
        direction = direction,
        power = function(s, n) propodds_backend(s)$exact_power(n),
        set = function(s, x) { s$population$odds_ratio <- exp(direction * x); s },
        # The script gives powertools the odds ratio above 1, with the shares
        # ordered for the direction searched (propodds_inputs()).
        script = "OR <<- exp(x)",
        effect = function(x) exp(direction * x), effect_script = "exp(direction * found)",
        effect_name = "odds_ratio",
        what = "odds ratio between the groups, with group 1's shares in the categories kept"
      )
    },
    log_rank = {
      p1 <- pop$p_event[[1]]
      direction <- pwrss_search_direction(spec, pop$p_event[[2]] - p1)
      list(
        grid = log_grid(1e-4, (if (direction < 0) p1 else 1 - p1) - 1e-4),
        direction = direction,
        power = function(s, n) survival_backend(s)$exact_power(n),
        set = function(s, x) { s$population$p_event[[2]] <- p1 + direction * x; s },
        script = sprintf("p_event[2] <<- %s + direction * x", r_code(p1)),
        effect = function(x) p1 + direction * x, effect_script = sprintf("%s + direction * found", r_code(p1)),
        effect_name = "p_event2",
        description = sprintf("the proportion of group 2 with the event by time %s, with group 1's kept at %s", format(pop$time), format(p1))
      )
    },
    cox_predictor = {
      direction <- pwrss_search_direction(spec, log(pop$hazard_ratio))
      list(
        grid = log_grid(1e-4, log(100)),
        direction = direction,
        power = function(s, n) survival_backend(s)$exact_power(n),
        set = function(s, x) { s$population$hazard_ratio <- exp(direction * x); s },
        script = "hazard_ratio <<- exp(direction * x)",
        effect = function(x) exp(direction * x), effect_script = "exp(direction * found)",
        effect_name = "hazard_ratio",
        what = "hazard ratio for a person 1 SD higher on X, with the share with the event and the other predictors kept"
      )
    },
    growth_curve = {
      direction <- pwrss_search_direction(spec, pop$slope_difference)
      spread <- max(pop$sd_slope, pop$sd_residual, pop$sd_intercept %||% 0, 1)
      list(
        grid = log_grid(1e-4 * spread, 100 * spread),
        direction = direction,
        power = function(s, n) route_backend(s)$exact_power(n),
        set = function(s, x) { s$population$slope_difference <- direction * x; s },
        script = "slope_difference <<- direction * x",
        effect = function(x) direction * x, effect_script = "direction * found",
        effect_name = "slope_difference",
        what = "difference between the groups' average rates of change, per unit of time, in the outcome's units, with the SDs and correlation kept"
      )
    },
    reliability_icc = ,
    reliability_cronbach_alpha = ,
    reliability_kappa = {
      field <- switch(kind, reliability_icc = "icc", reliability_cronbach_alpha = "reliability", reliability_kappa = "kappa")
      null_field <- switch(kind, reliability_icc = "icc_null", reliability_cronbach_alpha = "reliability_null", reliability_kappa = "kappa_null")
      null <- pop[[null_field]]
      direction <- pwrss_search_direction(spec, pop[[field]] - null)
      # Below the null value an ICC, alpha or kappa can go down to -1 in
      # principle; the search keeps to the side the test looks at.
      room <- if (direction > 0) 1 - null else null + 1
      script_name <- switch(kind, reliability_icc = "icc", reliability_cronbach_alpha = "reliability", reliability_kappa = "kappa1")
      script_null <- switch(kind, reliability_icc = "icc_null", reliability_cronbach_alpha = "reliability_null", reliability_kappa = "kappa0")
      name <- switch(kind, reliability_icc = "ICC", reliability_cronbach_alpha = "Cronbach's alpha", reliability_kappa = "kappa")
      list(
        grid = log_grid(1e-4, room - 1e-3),
        direction = direction,
        power = function(s, n) route_backend(s)$exact_power(n),
        set = function(s, x) { s$population[[field]] <- null + direction * x; s },
        script = sprintf("%s <<- %s + direction * x", script_name, script_null),
        effect = function(x) null + direction * x, effect_script = sprintf("%s + direction * found", script_null),
        effect_name = field,
        description = sprintf("the %s the study could show %s the null value %s", name, if (direction > 0) "exceeds" else "is below", format(null))
      )
    },
    tost = {
      template <- spec$template
      field <- switch(template, tost_correlation = "r", tost_two_proportions = NULL, tost_paired = "dz", "d")
      expected <- switch(template,
        tost_two_proportions = pop$p2 - pop$p1,
        pop[[field]] %||% 0)
      # The bounds must lie beyond the expected difference, and within
      # what the measure allows.
      upper <- switch(template,
        tost_correlation = 0.999 - abs(expected),
        tost_two_proportions = 1 - abs(expected),
        10)
      units <- switch(template,
        tost_correlation = "on the correlation",
        tost_two_proportions = "on the difference between the proportions",
        tost_paired = "in SDs of the differences (d_z)",
        "in SDs (d)")
      list(
        grid = log_grid(1e-5, upper, 300),
        power = function(s, n) toster_backend(s)$exact_power(n),
        set = function(s, x) { s$population$bound <- abs(expected) + x; s },
        script = sprintf("bound <<- %s + x", r_code(abs(expected))),
        effect = function(x) abs(expected) + x, effect_script = sprintf("%s + found", r_code(abs(expected))),
        effect_name = "bound",
        description = sprintf("%s, with the expected %s kept at %s",
          units, if (template == "tost_correlation") "correlation" else "difference", format(signif(expected, 3)))
      )
    }
  )
}

# The smallest detectable effect at n with the target power.
formula_search_sensitivity <- function(spec, n, target) {
  plan <- formula_search_plan(spec)
  at <- function(x) plan$power(plan$set(spec, x), n)
  found <- pwrss_search_root(at, plan$grid, target)
  if (is.na(found)) {
    abort_run("No effect in the range Powerkit searches reaches the target power at this sample size: try a larger sample or a lower target power.")
  }
  description <- plan$description %||% sprintf("the %s", plan$what)
  extra <- if (is.null(plan$extra)) list() else plan$extra(found)
  c(list(effect = plan$effect(found), effect_name = plan$effect_name, effect_description = description,
    power = at(found), searched = TRUE), extra)
}

# The exported script's function that refits semPower's models with the
# searched argument set to `value` (the same call as the script's `fit`).
sem_fit_with_lines <- function(spec, argument, value) {
  args <- sem_restriction_args(spec)
  fun <- sub("^semPower::", "", sem_function(spec))
  code <- vapply(names(args), function(a) {
    sprintf("    %s = %s", a, if (a == argument) value else sem_code(args[[a]]))
  }, character(1))
  c(
    "fit_with <- function(value) {",
    sprintf("  %s(", fun),
    "    type = \"post-hoc\", alpha = alpha, N = 1000,",
    paste0(code, c(rep(",", length(code) - 1), "")),
    "  )",
    "}"
  )
}

# How far the tested latent slope can go in the direction searched before
# the outcome's explained variance reaches 1 (R-squared = b' Rxx b is a
# quadratic in the tested slope), pulled in a little.
sem_slope_limit <- function(spec, direction) {
  pop <- spec$population
  slopes <- as.numeric(unlist(pop$slopes))
  tested <- pop$tested %||% 1L
  k <- length(slopes)
  rxx <- if (k > 1) sem_predictor_correlations(k, pop$predictor_correlation %||% 0) else matrix(1)
  r2 <- function(b) {
    v <- replace(slopes, tested, b)
    as.numeric(t(v) %*% rxx %*% v)
  }
  # r2(b) = a b^2 + c1 b + c0, exactly, from three values.
  y <- vapply(c(-1, 0, 1), r2, numeric(1))
  a <- (y[3] + y[1]) / 2 - y[2]
  c1 <- (y[3] - y[1]) / 2
  roots <- Re(polyroot(c(y[2] - 0.98, c1, a)))
  end <- if (direction > 0) max(roots) else -min(roots)
  max(min(end, 0.99), 2e-3)
}
