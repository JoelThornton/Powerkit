# The smallest detectable effect for the tests pwrss computes by formula
# (backend-pwrss.R). pwrss's power functions solve for n or power, not for
# the effect, so the effect is found by searching it with the package's own
# power call at the fixed n: no new formula (CLAUDE.md, "Never write new
# statistical maths"). The search is the one the exported R script repeats
# (pwrss_search_section(), export-script-pwrss.R), so the script reproduces
# the answer to the last digit:
#
#   1. power at each point of a fixed grid of the searched value, from the
#      smallest effect upwards;
#   2. the first grid point whose power reaches the target;
#   3. uniroot() between it and the grid point before it.
#
# Starting from the smallest effect and taking the first crossing means a
# power function that turns down at very large effects (as Wald tests can)
# still gives the smallest effect that reaches the target.
#
# What is searched, for each test (the rest of the population kept as
# entered):
#   R-squared             the R-squared, its increase (as a partial
#                         R-squared) or one predictor's partial R-squared
#   interaction           the R-squared change, the R-squared of X and W kept
#   ANOVA (partial        the partial eta-squared of the effect tested
#   eta-squared)
#   logistic regression   the odds ratio, the proportion of 'yes' kept
#   Poisson regression    the rate ratio, the base rate kept
#   one proportion        the proportion, the fixed value kept
#   McNemar's test        the proportion changing in the second condition
#                         only, the proportion changing in the first kept
#   two correlations      group 2's correlation, group 1's kept (searched
#                         on Fisher's z scale)
#   goodness of fit       Cohen's w, with the number of categories kept
#   dependent             the second correlation (X with Z, or X2 with Y2),
#   correlations          the first and the others kept, within the values
#                         that keep the correlation matrix positive definite
#   contrast and ANCOVA   the pattern of means entered, scaled about its
#                         grand mean, as the ANOVAs' smallest detectable
#                         effect scales it (superpower_sensitivity())

# The pwrss keys that have a smallest detectable effect by search.
pwrss_search_keys <- c(
  "r2_zero", "r2_increase", "single_coefficient", "interaction_r2_change", "anova_eta_squared",
  "single_predictor", "single_predictor_count", "one_proportion", "mcnemar",
  "two_correlations", "chi_square_gof", "oneway_contrast", "oneway_ancova", "factorial_ancova",
  "overlapping_correlations", "nonoverlapping_correlations"
)

pwrss_search_available <- function(spec) pwrss_key(spec) %in% pwrss_search_keys

# The direction of the effect searched: the one-sided test's, or for a
# two-sided test the direction of the effect entered (an increase when none
# was given).
pwrss_search_direction <- function(spec, entered) {
  alternative <- spec$target_test$alternative %||% "two_sided"
  if (identical(alternative, "less")) return(-1)
  if (identical(alternative, "greater")) return(1)
  if (isTRUE(entered < 0)) -1 else 1
}

# The search for one spec: the grid, how a grid value sets the spec, and
# how the found value is reported. `script` is the same setting written in
# the exported script's variables (power_at() reads them).
pwrss_search_plan <- function(spec) {
  pop <- spec$population
  log_grid <- function(lower, upper, k = 80) exp(seq(log(lower), log(upper), length.out = k))
  key <- pwrss_key(spec)
  switch(key,
    r2_zero = list(
      grid = log_grid(1e-6, 0.99),
      set = function(s, x) { s$population$r2 <- x; s },
      script = "r2 <<- x",
      effect = function(x) x, effect_script = "found",
      effect_name = "r2", what = "R-squared of the predictors together"
    ),
    single_coefficient = list(
      grid = log_grid(1e-6, 0.99),
      set = function(s, x) { s$population$partial_r2 <- x; s },
      script = "partial_r2 <<- x",
      effect = function(x) x, effect_script = "found",
      effect_name = "partial_r2",
      what = sprintf("partial R-squared of %s, controlling for the other predictors", spec$variables$X$label %||% "the predictor")
    ),
    r2_increase = {
      reduced <- pop$r2_reduced %||% 0
      list(
        grid = log_grid(1e-6, 0.99),
        set = function(s, x) { s$population$r2_full <- reduced + x * (1 - reduced); s },
        script = "partial_r2 <<- x",
        effect = function(x) x, effect_script = "found",
        effect_name = "partial_r2",
        what = "partial R-squared of the predictors you are testing (their R-squared increase over 1 minus the R-squared without them)",
        extra = function(x) list(r2_change = x * (1 - reduced))
      )
    },
    interaction_r2_change = {
      main <- pop$r2_main %||% 0
      list(
        grid = log_grid(1e-6, 0.99 * (1 - main)),
        set = function(s, x) { s$population$r2_change <- x; s },
        script = c("r2_change <<- x", "partial <<- r2_change / (1 - r2_main)"),
        effect = function(x) x, effect_script = "found",
        effect_name = "r2_change",
        what = sprintf("R-squared the interaction adds, with X and W explaining %s without it", format(signif(main, 3)))
      )
    },
    anova_eta_squared = list(
      grid = log_grid(1e-6, 0.95),
      set = function(s, x) { s$population$eta_squared <- x; s },
      script = "eta_squared <<- x",
      effect = function(x) x, effect_script = "found",
      effect_name = "eta_squared",
      what = sprintf("partial eta-squared of %s%s", anova_effect_name(spec),
        if (identical(pop$eta_source, "published")) ", as a repeated-measures ANOVA reports it" else "")
    ),
    single_predictor = ,
    single_predictor_count = {
      field <- if (key == "single_predictor") "odds_ratio" else "rate_ratio"
      direction <- pwrss_search_direction(spec, log(pop[[field]] %||% 1))
      list(
        grid = log_grid(1e-4, log(100)),
        direction = direction,
        set = function(s, x) { s$population[[field]] <- exp(direction * x); s },
        script = sprintf("%s <<- exp(direction * x)", field),
        effect = function(x) exp(direction * x), effect_script = "exp(direction * found)",
        effect_name = field,
        what = if (key == "single_predictor") {
          sprintf("odds ratio of %s, with the proportion of 'yes' kept at %s", pwrss_x_text(spec), format(pop$base_prob))
        } else {
          sprintf("rate ratio of %s, with the base rate kept at %s", pwrss_x_text(spec), format(pop$base_rate))
        }
      )
    },
    one_proportion = {
      direction <- pwrss_search_direction(spec, (pop$p %||% pop$p0) - pop$p0)
      room <- if (direction > 0) 1 - pop$p0 else pop$p0
      list(
        grid = seq(room / 400, room * (1 - 1e-6), length.out = 400),
        direction = direction,
        set = function(s, x) { s$population$p <- pop$p0 + direction * x; s },
        script = "p <<- p0 + direction * x",
        effect = function(x) pop$p0 + direction * x, effect_script = "p0 + direction * found",
        effect_name = "p",
        what = sprintf("proportion, against the fixed value %s", format(pop$p0))
      )
    },
    mcnemar = {
      first <- pop$p_first_only
      direction <- pwrss_search_direction(spec, (pop$p_second_only %||% first) - first)
      # Both changes together can't pass 1, and neither can go below 0.
      room <- if (direction > 0) 1 - 2 * first else first
      list(
        grid = seq(room / 400, room * (1 - 1e-6), length.out = 400),
        direction = direction,
        set = function(s, x) { s$population$p_second_only <- first + direction * x; s },
        script = "p_second_only <<- p_first_only + direction * x",
        effect = function(x) first + direction * x, effect_script = "p_first_only + direction * found",
        effect_name = "p_second_only",
        what = sprintf("proportion who change only in the second condition, with %s changing only in the first", format(first))
      )
    },
    two_correlations = {
      z1 <- atanh(pop$r1)
      direction <- pwrss_search_direction(spec, (pop$r2 %||% pop$r1) - pop$r1)
      room <- if (direction > 0) atanh(0.999) - z1 else z1 - atanh(-0.999)
      list(
        grid = seq(room / 400, room, length.out = 400),
        direction = direction,
        set = function(s, x) { s$population$r2 <- tanh(z1 + direction * x); s },
        script = "r2 <<- tanh(atanh(r1) + direction * x)",
        effect = function(x) tanh(z1 + direction * x), effect_script = "tanh(atanh(r1) + direction * found)",
        effect_name = "r_group2",
        what = sprintf("correlation in group 2, with group 1's kept at %s", format(pop$r1))
      )
    },
    overlapping_correlations = ,
    nonoverlapping_correlations = {
      overlapping <- key == "overlapping_correlations"
      first <- if (overlapping) "r_X_Y" else "r_X1_Y1"
      second <- if (overlapping) "r_X_Z" else "r_X2_Y2"
      r1 <- pop[[first]]
      range <- dependent_correlation_range(spec, second)
      start <- min(max(r1, range[1]), range[2])
      direction <- pwrss_search_direction(spec, (pop[[second]] %||% r1) - r1)
      room <- if (direction > 0) range[2] - start else start - range[1]
      list(
        grid = seq(room / 400, room, length.out = 400),
        direction = direction,
        set = function(s, x) { s$population[[second]] <- start + direction * x; s },
        script = sprintf("%s <<- %s + direction * x", second, r_code(start)),
        effect = function(x) start + direction * x, effect_script = sprintf("%s + direction * found", r_code(start)),
        effect_name = "r_second",
        what = sprintf("second correlation (%s), with the first kept at %s and the other correlations as entered",
          if (overlapping) "X with Z" else "X2 with Y2", format(r1))
      )
    },
    chi_square_gof = list(
      grid = log_grid(1e-4, 3),
      set = function(s, x) {
        s$population$metric <- "w"
        s$population$w <- x
        s$population$probabilities <- NULL
        s$population$null_probabilities <- NULL
        s
      },
      script = "effect$w <<- x",
      effect = function(x) x, effect_script = "found",
      effect_name = "w",
      what = sprintf("Cohen's w for %d categories", length(spec$variables$Y$levels))
    ),
    oneway_contrast = ,
    oneway_ancova = ,
    factorial_ancova = {
      entered <- as.numeric(unlist(pop$means))
      grand <- mean(entered)
      scaled <- function(x) grand + x * (entered - grand)
      contrast <- key == "oneway_contrast"
      weights <- as.numeric(unlist(spec$target_test$weights))
      list(
        grid = log_grid(1e-4, 1e3, 200),
        set = function(s, x) { s$population$means <- relist_means(pop$means, scaled(x)); s },
        script = "means <<- mean(entered_means) + x * (entered_means - mean(entered_means))",
        script_before = "entered_means <- means # the pattern entered, kept and scaled",
        effect = if (contrast) function(x) sum(weights * scaled(x)) else function(x) diff(range(scaled(x))),
        effect_script = if (contrast) {
          "sum(weights * (mean(entered_means) + found * (entered_means - mean(entered_means))))"
        } else {
          "diff(range(mean(entered_means) + found * (entered_means - mean(entered_means))))"
        },
        effect_name = if (contrast) "contrast" else "mean_range",
        what = if (contrast) {
          sprintf("value of the contrast (the weighted sum of the group means, in the outcome's units; SD %s), with the pattern of means you entered kept and scaled", format(pop$sd))
        } else {
          sprintf("difference between the largest and smallest adjusted mean (in the outcome's units; SD %s), with the pattern of means you entered kept and scaled", format(pop$sd))
        },
        extra = function(x) list(means = scaled(x), scale = x, standardised = (if (contrast) sum(weights * scaled(x)) else diff(range(scaled(x)))) / pop$sd)
      )
    },
    NULL
  )
}

# "the predictor (per SD)" or "group 2 against group 1", for the
# descriptions of a regression's odds or rate ratio.
pwrss_x_text <- function(spec) {
  x <- spec$variables$X
  if (identical(x$type, "binary")) {
    lv <- unlist(x$levels)
    sprintf("%s against %s", lv[2] %||% "group 2", lv[1] %||% "group 1")
  } else {
    sprintf("%s (per SD)", x$label %||% "the predictor")
  }
}

# A flat vector of means put back in the shape the spec gave them (a list,
# or a list of rows).
relist_means <- function(means, values) {
  if (!is.list(means) || !any(vapply(means, is.list, logical(1)))) return(as.list(values))
  sizes <- vapply(means, function(row) length(unlist(row)), integer(1))
  ends <- cumsum(sizes)
  lapply(seq_along(sizes), function(i) as.list(values[(ends[i] - sizes[i] + 1):ends[i]]))
}

# The values of one correlation that keep the matrix of all the
# correlations positive definite, the others as entered: the determinant
# is a quadratic in any one off-diagonal entry, so it is fitted through
# three values and its roots are the ends (pulled in by 0.001).
dependent_correlation_range <- function(spec, field) {
  pop <- spec$population
  overlapping <- identical(spec$template, "overlapping_correlations")
  vars <- if (overlapping) c("X", "Y", "Z") else c("X1", "Y1", "X2", "Y2")
  matrix_at <- function(x) {
    p <- pop
    p[[field]] <- x
    m <- diag(length(vars))
    for (i in seq_along(vars)) for (j in seq_along(vars)) if (i < j) {
      value <- p[[paste0("r_", vars[i], "_", vars[j])]] %||% p[[paste0("r_", vars[j], "_", vars[i])]]
      m[i, j] <- m[j, i] <- value
    }
    m
  }
  d <- vapply(c(-1, 0, 1), function(x) det(matrix_at(x)), numeric(1))
  a <- (d[3] + d[1]) / 2 - d[2]
  b <- (d[3] - d[1]) / 2
  roots <- sort(Re(polyroot(c(d[2], b, a))))
  ends <- c(max(-0.999, roots[1]), min(0.999, roots[2]))
  ends + c(0.001, -0.001)
}

# The search itself (the steps at the top of this file).
pwrss_search_root <- function(at, grid, target) {
  for (i in seq_along(grid)) {
    if (at(grid[i]) >= target) {
      if (i == 1) return(grid[1])
      return(stats::uniroot(function(x) at(x) - target, lower = grid[i - 1], upper = grid[i], tol = 1e-10)$root)
    }
  }
  NA_real_
}

# The smallest detectable effect at n with the target power.
pwrss_sensitivity <- function(spec, n, target) {
  plan <- pwrss_search_plan(spec)
  at <- function(x) pwrss_power(pwrss_inputs(plan$set(spec, x)), n)
  found <- pwrss_search_root(at, plan$grid, target)
  if (is.na(found)) {
    abort_run("No effect in the range Powerkit searches reaches the target power at this sample size: try a larger sample or a lower target power.")
  }
  effect <- plan$effect(found)
  description <- if (startsWith(plan$what, "Cohen's")) plan$what else sprintf("the %s", plan$what)
  if (plan$effect_name %in% c("r2", "partial_r2", "r2_change")) {
    f2 <- if (plan$effect_name == "r2_change") effect / (1 - (spec$population$r2_main %||% 0) - effect) else effect / (1 - effect)
    description <- sprintf("%s; Cohen's f-squared = %s", description, format(signif(f2, 3)))
  }
  if (identical(plan$effect_name, "eta_squared")) {
    description <- sprintf("%s; Cohen's f = %s", description, format(signif(sqrt(effect / (1 - effect)), 3)))
  }
  extra <- if (is.null(plan$extra)) list() else plan$extra(found)
  if (!is.null(extra$standardised)) {
    description <- sprintf("%s; %s SDs", description, format(signif(extra$standardised, 3)))
  }
  c(list(effect = effect, effect_name = plan$effect_name, effect_description = description, power = at(found), searched = TRUE),
    extra)
}
