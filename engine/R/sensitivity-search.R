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

formula_search_available <- function(spec) {
  !is.null(formula_search_kind(spec))
}

formula_search_kind <- function(spec) {
  if (variance_formula_test(spec)) return(spec$template)
  if (hotelling_formula_test(spec) && !permanova_test(spec) && !identical(spec$options$method, "simulation")) return("hotelling")
  if (identical(spec$design, "equivalence_test") && identical(spec$target_test$method %||% "tost", "tost")) return("tost")
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
