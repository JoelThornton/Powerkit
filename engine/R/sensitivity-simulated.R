# The smallest detectable effect of a simulated test: Welch's F, when
# simulation is asked for (by default it is worked out by Levy's
# approximation, welch_levy_sensitivity()).
#
# As for the F test (superpower_sensitivity()), the pattern of means
# entered keeps its shape and its size (each mean's deviation from the
# grand mean) is scaled until the test reaches the target power at n. No
# package gives Welch's F's power by formula, so power at each scale is
# simulated with Spower, as for its power and sample size, and the scale is
# read from a probit curve fitted to the simulated rejections, as search_n()
# reads the sample size: for roughly normal test statistics power is close
# to pnorm(a + b * scale) near the target.

#' Find the smallest detectable effect by simulation
#'
#' For Welch's one-way ANOVA. The search starts from the F test's exact
#' answer (Superpower's `ANOVA_exact()`, with the root mean square of the
#' groups' SDs), which only places the grid, then simulates power at seven
#' scales of the pattern of means around it, each with `nrep`
#' replications, widening the grid if the target lies outside it. A probit
#' regression of the rejection counts on the scale, fitted to the points
#' within 20% of the estimate, gives the scale at which fitted power reaches
#' the target; its 95% interval runs between the scales at which the upper
#' and lower confidence limits of the curve reach it.
#'
#' @inheritParams search_n
#' @param n Total sample size.
#' @return A list with `sensitivity` (the scale, its interval, the scaled
#'   means, the effect as the largest difference between two means and its
#'   interval, a description, the fitted power and `simulated = TRUE`),
#'   `curve` (the target power at `n`, with the curve's standard error) and
#'   `simulations` (one row per simulated scale, with its `scale`).
#' @keywords internal
welch_f_sensitivity <- function(spec, n, power, nrep, seed, cores = 1L, level = 0.95) {
  means <- as.numeric(unlist(spec$population$means))
  grand_mean <- mean(means)
  mu_at <- function(scale) grand_mean + scale * (means - grand_mean)
  guess <- classical_f_scale(spec, n, power)

  found <- simulated_scale_search(guess, power, seed, level, function(scale, scale_seed) {
    scaled <- spec
    scaled$population$means <- as.list(mu_at(scale))
    spower_backend(scaled)$simulate(n, nrep, scale_seed, cores)
  })
  points <- found$points
  estimate <- found$estimate
  fitted <- found$fitted

  points <- points[order(points$scale), ]
  spread <- max(means) - min(means)
  scaled <- mu_at(estimate$scale)
  record <- simulation_record(rep(n, nrow(points)), points$seed, points$rejections, points$nrep,
    points$scale %in% fitted, points$attempted, points$valid)
  record$scale <- points$scale
  list(
    sensitivity = list(
      scale = estimate$scale,
      scale_lower = estimate$lower,
      scale_upper = estimate$upper,
      means = scaled,
      effect = estimate$scale * spread,
      effect_lower = estimate$lower * spread,
      effect_upper = estimate$upper * spread,
      effect_description = sprintf(
        "the largest difference between two of the means of %s, with the pattern you entered kept and scaled (means %s)",
        spec$variables$Y$label %||% "the outcome", paste(vapply(scaled, function(x) format(signif(x, 3)), character(1)), collapse = ", ")
      ),
      power = power,
      simulated = TRUE
    ),
    curve = data.frame(n = n, power = power, mcse = 0),
    simulations = record
  )
}

# The search itself, for any effect whose power rises with a positive
# value x (a scale of the pattern of means, or the effect itself): power
# simulated at seven values around the guess, widened until the target
# lies inside them, then a probit curve of the rejections on x fitted to
# the points within 20% of the estimate (scale_from_curve()). Each value
# has its own seed. `simulate_at_x(x, seed)` returns the backend's
# simulate() result. Returns the points (column `scale` holding x), the
# estimate and the values fitted.
simulated_scale_search <- function(guess, power, seed, level, simulate_at_x, limit = Inf) {
  points <- data.frame(scale = numeric(), seed = numeric(), rejections = numeric(), nrep = numeric(),
    attempted = numeric(), valid = numeric())
  simulate_at <- function(scales) {
    scales <- setdiff(signif(scales, 6), points$scale)
    # Values the population can't take (a proportion beyond 0 or 1) are
    # left out.
    for (scale in scales[scales > 0 & scales <= limit]) {
      scale_seed <- offset_seed(seed, 10007 * nrow(points))
      sim <- simulate_at_x(scale, scale_seed)
      points[nrow(points) + 1, ] <<- c(scale, scale_seed, sim$rejections, sim$nrep,
        sim$attempted %||% sim$nrep, sim$valid %||% sim$nrep)
    }
  }
  simulate_at(guess * (1 + 0.08 * (-3:3)))
  for (attempt in 1:6) {
    estimate <- scale_from_curve(points, power, level)
    if (!is.na(estimate$scale) && !is.na(estimate$lower) && !is.na(estimate$upper)) break
    p <- points$rejections / points$nrep
    # The target is above every simulated point: larger values; below
    # every point: smaller ones.
    if (all(p < power)) simulate_at(max(points$scale) * c(1.15, 1.35, 1.6))
    if (all(p >= power)) simulate_at(min(points$scale) / c(1.15, 1.35, 1.6))
    if (any(p < power) && any(p >= power)) simulate_at(range(points$scale) * c(0.85, 1.15))
  }
  fitted <- points$scale
  if (!is.na(estimate$scale)) {
    near <- function() points[abs(points$scale / estimate$scale - 1) <= 0.2, ]
    if (nrow(near()) < 5) simulate_at(estimate$scale * (1 + 0.05 * (-3:3)))
    fitted <- near()$scale
    estimate <- scale_from_curve(near(), power, level)
  }
  if (is.na(estimate$scale) || is.na(estimate$lower) || is.na(estimate$upper)) {
    abort_run("The search for the smallest detectable effect could not pin it down: the simulated power didn't settle near the target. Try more replications ('options > nrep') or another seed.")
  }
  list(points = points, estimate = estimate, fitted = fitted)
}

# The F test's smallest detectable scale of the pattern of means, exactly
# (Superpower), with every group's SD the root mean square of the groups'
# SDs. A starting point for the simulated search only.
classical_f_scale <- function(spec, n, power) {
  f_test <- spec
  f_test$target_test$method <- "anova_f"
  f_test$population$sd <- sqrt(mean(welch_sds(spec)^2))
  f_test$population$sds <- NULL
  superpower_backend(f_test)$sensitivity(n, power)$scale
}

# The scale at which a probit curve of the rejections on the scale reaches
# the target, and the scales at which its upper and lower 95% confidence
# limits do (NA where they don't within the points simulated).
scale_from_curve <- function(points, target, level = 0.95) {
  if (nrow(points) < 3) {
    return(list(scale = NA_real_, lower = NA_real_, upper = NA_real_))
  }
  fit <- suppressWarnings(stats::glm(
    cbind(rejections, nrep - rejections) ~ scale,
    family = stats::binomial(link = "probit"),
    data = points
  ))
  if (!isTRUE(stats::coef(fit)[["scale"]] > 0)) {
    return(list(scale = NA_real_, lower = NA_real_, upper = NA_real_))
  }
  candidates <- data.frame(scale = seq(min(points$scale), max(points$scale), length.out = 2001))
  link <- stats::predict(fit, candidates, se.fit = TRUE)
  z <- stats::qnorm(1 - (1 - level) / 2)
  first_reaching <- function(p) {
    hit <- which(p >= target)
    if (length(hit) == 0 || hit[1] == 1) NA_real_ else candidates$scale[hit[1]]
  }
  list(
    scale = first_reaching(stats::pnorm(link$fit)),
    lower = first_reaching(stats::pnorm(link$fit + z * link$se.fit)),
    upper = first_reaching(stats::pnorm(link$fit - z * link$se.fit))
  )
}

# The smallest detectable effect of other simulated tests, by the same
# search (simulated_scale_search()) over the effect itself: `plan` gives
# a starting guess, how a positive value x sets the spec, and how x is
# reported. What is searched, the rest kept as entered:
#   meta-analysis (Hartung-Knapp)   the average effect, d or r (its size;
#                                   the sign of the effect entered), the
#                                   typical study's size and I-squared
#                                   kept; the guess is metapower's z test
#   two paired variances            the ratio of the first measurement's
#   (Pitman-Morgan)                 variance to the second's, the second's
#                                   and the correlation kept
#   trend in proportions            the pattern of proportions scaled about
#   (Cochran-Armitage)              their mean, reported as the difference
#                                   between the highest and lowest
#   d' in two conditions            the second condition's average d',
#                                   the first's and the rest kept
#   Jonckheere-Terpstra trend       the pattern of group means scaled about
#                                   their mean, reported as the difference
#                                   between the largest and smallest, the
#                                   SD kept
simulated_search_plan <- function(spec, n, power) {
  pop <- spec$population
  guess_from <- function(entered, otherwise) if (isTRUE(abs(entered) > 1e-8)) abs(entered) else otherwise
  # Levene's and the Brown-Forsythe tests of two variances: group 1's
  # variance moved away from group 2's, as for the paired variances.
  if (levene_test(spec)) {
    entered <- log(pop$var1 / pop$var2)
    direction <- pwrss_search_direction(spec, entered)
    return(list(
      guess = guess_from(entered, 0.5),
      set = function(s, x) { s$population$var1 <- pop$var2 * exp(direction * x); s },
      effect = function(x) exp(direction * x),
      effect_name = "variance_ratio",
      what = sprintf("ratio of group 1's variance to group 2's, with group 2's kept at %s", format(pop$var2)),
      script_set = sprintf("  var1 <<- var2 * exp(%s * x)", r_code(direction)),
      effect_script = sprintf("exp(%s * x)", r_code(direction))
    ))
  }
  # McNemar's chi-square tests: the proportion who say yes in the second
  # condition only moved away from those who do in the first only, which is
  # kept, as pwrss's search does for the exact test. Above it, the two can't
  # add up to more than 1.
  if (mcnemar_chisq_test(spec)) {
    entered <- log(pop$p_second_only / pop$p_first_only)
    direction <- pwrss_search_direction(spec, entered)
    return(list(
      guess = guess_from(entered, 0.5),
      limit = if (direction > 0) 0.999 * log((1 - pop$p_first_only) / pop$p_first_only),
      set = function(s, x) { s$population$p_second_only <- pop$p_first_only * exp(direction * x); s },
      effect = function(x) pop$p_first_only * exp(direction * x),
      effect_name = "p_second_only",
      what = sprintf("proportion who change only in the second condition, with %s changing only in the first", format(pop$p_first_only)),
      script_set = sprintf("  p_second_only <<- p_first_only * exp(%s * x)", r_code(direction)),
      effect_script = sprintf("p_first_only * exp(%s * x)", r_code(direction))
    ))
  }
  if (identical(spec$template, "paired_variances")) {
    entered <- log(pop$var1 / pop$var2)
    direction <- pwrss_search_direction(spec, entered)
    return(list(
      guess = guess_from(entered, 0.5),
      set = function(s, x) { s$population$var1 <- pop$var2 * exp(direction * x); s },
      effect = function(x) exp(direction * x),
      effect_name = "variance_ratio",
      what = sprintf("ratio of the first measurement's variance to the second's, with the second's kept at %s and the correlation at %s",
        format(pop$var2), format(pop$r)),
      script_set = sprintf("  var1 <<- var2 * exp(%s * x)", r_code(direction)),
      effect_script = sprintf("exp(%s * x)", r_code(direction))
    ))
  }
  if (identical(spec$template, "proportion_trend")) {
    p <- as.numeric(unlist(pop$proportions))
    centre <- mean(p)
    spread <- max(p) - min(p)
    # The largest scale keeping every proportion between 0.001 and 0.999.
    room <- min(ifelse(p > centre, (0.999 - centre) / (p - centre), ifelse(p < centre, (centre - 0.001) / (centre - p), Inf)))
    return(list(
      guess = 1, limit = room,
      set = function(s, x) { s$population$proportions <- as.list(centre + x * (p - centre)); s },
      effect = function(x) x * spread,
      effect_name = "proportion_range",
      what = sprintf("difference between the highest and lowest groups' proportions, with the pattern you entered kept and scaled about its average (%s)", format(signif(centre, 3))),
      script_set = sprintf("  proportions <<- %s + x * (%s - %s)", r_code(centre), r_code(p), r_code(centre)),
      effect_script = sprintf("x * %s", r_code(spread))
    ))
  }
  if (jonckheere_search(spec)) {
    m <- as.numeric(unlist(pop$means))
    centre <- mean(m)
    spread <- max(m) - min(m)
    return(list(
      guess = 1,
      set = function(s, x) { s$population$means <- as.list(centre + x * (m - centre)); s },
      effect = function(x) x * spread,
      effect_name = "mean_range",
      what = sprintf("difference between the largest and smallest group means, in the outcome's units, with the pattern you entered kept and scaled about its average and the SD kept at %s", format(pop$sd %||% 1)),
      script_set = sprintf("  means <<- (%s + x * (%s - %s)) / %s", r_code(centre), r_code(m), r_code(centre), r_code(pop$sd %||% 1)),
      effect_script = sprintf("x * %s", r_code(spread))
    ))
  }
  if (identical(spec$design, "regression_interaction") && identical(spec$template, "group_moderator")) {
    r <- as.numeric(unlist(pop$r_xy))
    centre <- mean(r)
    spread <- max(r) - min(r)
    # The largest scale keeping every correlation within -0.99 to 0.99.
    room <- min(ifelse(r > centre, (0.99 - centre) / (r - centre), ifelse(r < centre, (centre + 0.99) / (centre - r), Inf)))
    return(list(
      guess = 1, limit = room,
      set = function(s, x) { s$population$r_xy <- as.list(centre + x * (r - centre)); s },
      effect = function(x) x * spread,
      effect_name = "r_range",
      what = sprintf("difference between the largest and smallest group's correlation of %s with %s, with the pattern you entered kept and scaled about its average (%s) and the group means kept",
        spec$variables$X$label %||% "X", spec$variables$Y$label %||% "Y", format(signif(centre, 3))),
      script_set = sprintf("  r <<- %s + x * (%s - %s)", r_code(centre), r_code(r), r_code(centre)),
      effect_script = sprintf("x * %s", r_code(spread))
    ))
  }
  if (identical(spec$design, "mixture") && identical(spec$template, "lpa")) {
    return(list(
      guess = guess_from(pop$separation %||% 0, 1),
      set = function(s, x) { s$population$separation <- x; s },
      effect = function(x) x,
      effect_name = "separation",
      what = sprintf("separation between neighbouring profiles' means, in SDs of each indicator, with %s profiles, %s indicators and the shares kept",
        format(pop$profiles), format(pop$indicators)),
      script_set = "  separation <<- x",
      effect_script = "x"
    ))
  }
  if (identical(spec$design, "factor_analysis") && identical(spec$template, "efa")) {
    return(list(
      guess = guess_from(pop$loading %||% 0, 0.5),
      # Loadings of 1 or more leave no unique variance.
      limit = 0.95,
      set = function(s, x) { s$population$loading <- x; s },
      effect = function(x) x,
      effect_name = "loading",
      what = sprintf("loading of every item on its factor, with %s factors of %s items, a factor correlation of %s and recovery at a congruence of %s kept",
        format(pop$factors), format(pop$items_per_factor), format(pop$factor_correlation %||% 0), format(spec$target_test$congruence %||% 0.95)),
      script_set = "  loading <<- x",
      effect_script = "x"
    ))
  }
  if (binary_interaction_search(spec)) {
    entered <- pop$r_XW_Y %||% 0
    direction <- pwrss_search_direction(spec, entered)
    return(list(
      guess = guess_from(entered, 0.15),
      set = function(s, x) { s$population$r_XW_Y <- direction * x; s },
      effect = function(x) direction * x,
      effect_name = "r_XW_Y",
      what = "correlation of the interaction XW with Y, with the other correlations and the reliabilities kept",
      script_set = sprintf("  r_x1x2_y <<- %s * x", r_code(direction)),
      effect_script = sprintf("%s * x", r_code(direction))
    ))
  }
  if (multinomial_search(spec)) {
    interaction <- identical(spec$template, "multinomial_interaction")
    slopes <- if (interaction) log(as.numeric(unlist(pop$odds_ratios_xw))) else multinomial_coefficients(spec)$slopes
    category <- multinomial_category(spec)
    # The Wald test's category, or else the category whose odds ratio is
    # furthest from 1.
    k <- if (is.null(category)) which.max(abs(slopes)) else category - 1
    levels <- unlist(spec$variables$Y$levels)
    return(list(
      guess = 1,
      set = function(s, x) {
        if (interaction) {
          s$population$odds_ratios_xw <- as.list(exp(x * slopes))
        } else {
          s$population$odds_ratios <- as.list(exp(x * slopes))
          s$population$probabilities_second <- NULL
        }
        s
      },
      effect = function(x) exp(x * slopes[k]),
      effect_name = if (interaction) "odds_ratio_xw" else "odds_ratio",
      what = sprintf("%s for '%s' against '%s'%s, with the pattern of the categories' log odds ratios you entered kept and scaled, and the rest kept",
        if (interaction) "interaction odds ratio" else "odds ratio", levels[k + 1], levels[1],
        if (is.null(category)) " (the category furthest from 1)" else ""),
      script_set = sprintf("  %s <<- x * %s", if (interaction) "bxw" else "slopes", r_code(slopes)),
      effect_script = sprintf("exp(x * %s)", r_code(slopes[k]))
    ))
  }
  if (moderation_ratio_search(spec)) {
    count <- identical(spec$design, "poisson_regression")
    entered <- log(if (count) pop$rate_ratio_xw else pop$odds_ratio_xw)
    direction <- pwrss_search_direction(spec, entered)
    return(list(
      guess = guess_from(entered, 0.3),
      set = function(s, x) {
        if (count) s$population$rate_ratio_xw <- exp(direction * x) else s$population$odds_ratio_xw <- exp(direction * x)
        s
      },
      effect = function(x) exp(direction * x),
      effect_name = if (count) "rate_ratio_xw" else "odds_ratio_xw",
      what = sprintf("interaction, as the factor by which %s's %s is multiplied per SD (or group) of %s, with the rest you entered kept",
        spec$variables$X$label %||% "X", if (count) "rate ratio" else "odds ratio", spec$variables$W$label %||% "W"),
      script_set = sprintf("  %s <<- exp(%s * x)", if (count) "rate_ratio_xw" else "or_xw", r_code(direction)),
      effect_script = sprintf("exp(%s * x)", r_code(direction))
    ))
  }
  if (identical(spec$template, "its")) {
    test <- spec$target_test$effect
    if (identical(test, "both")) {
      level <- pop$level_change %||% 0
      slope <- pop$slope_change %||% 0
      return(list(
        guess = 1,
        set = function(s, x) { s$population$level_change <- x * level; s$population$slope_change <- x * slope; s },
        effect = function(x) x * level,
        effect_name = "level_change",
        what = sprintf("change in level at the intervention, with the change in trend scaled with it (%s per time point for each unit of level) and the rest you entered kept",
          format(signif(slope / level, 3))),
        script_set = c(sprintf("  level <<- x * %s", r_code(level)), sprintf("  slope <<- x * %s", r_code(slope))),
        effect_script = sprintf("x * %s", r_code(level))
      ))
    }
    slope_test <- identical(test, "slope")
    entered <- if (slope_test) pop$slope_change %||% 0 else pop$level_change %||% 0
    direction <- pwrss_search_direction(spec, entered)
    return(list(
      guess = guess_from(entered, pop$sigma * if (slope_test) 0.05 else 0.5),
      set = function(s, x) {
        if (slope_test) s$population$slope_change <- direction * x else s$population$level_change <- direction * x
        s
      },
      effect = function(x) direction * x,
      effect_name = if (slope_test) "slope_change" else "level_change",
      what = sprintf("%s, in the outcome's units, with the rest you entered kept (errors' SD %s, autocorrelation %s)",
        if (slope_test) "change in trend per time point after the intervention" else "change in level at the intervention",
        format(pop$sigma), format(pop$rho %||% 0)),
      script_set = sprintf("  %s <<- %s * x", if (slope_test) "slope" else "level", r_code(direction)),
      effect_script = sprintf("%s * x", r_code(direction))
    ))
  }
  if (logistic_factorial_search(spec)) {
    design <- logistic_factorial_design(spec)
    tested <- names(design$betas) %in% design$tested
    model <- stats::model.matrix(~ A * B, design$cells)
    index <- cbind(as.integer(design$cells$A), as.integer(design$cells$B))
    at_scale <- function(x) {
      logits <- drop(model %*% (design$betas * ifelse(tested, x, 1)))
      p <- matrix(NA_real_, nlevels(design$cells$A), nlevels(design$cells$B))
      p[index] <- stats::plogis(logits)
      p
    }
    size <- logistic_factorial_contrast(spec, stats::qlogis(at_scale(1)))
    effect <- spec$target_test$effect
    return(list(
      guess = 1,
      set = function(s, x) {
        p <- at_scale(x)
        s$population$probabilities <- lapply(seq_len(nrow(p)), function(i) as.list(p[i, ]))
        s
      },
      effect = function(x) exp(x * size),
      effect_name = if (identical(effect, "interaction")) "ratio_of_odds_ratios" else "factorial_odds_ratio",
      what = if (identical(effect, "interaction")) {
        "largest ratio of odds ratios in any two levels of each factor, with the pattern of the interaction you entered kept and scaled, and the main effects kept"
      } else {
        sprintf("odds ratio between the levels of %s with the most and the fewest 'yes' (on the log-odds scale, averaged over %s), with the pattern you entered kept and scaled, and the other effects kept",
          spec$variables[[if (identical(effect, "main_effect_A")) "A" else "B"]]$label %||% "the factor",
          spec$variables[[if (identical(effect, "main_effect_A")) "B" else "A"]]$label %||% "the other factor")
      },
      # The script's coefficients (logistic_factorial_design()): the tested
      # ones multiplied by x.
      script_set = sprintf("  betas <<- %s * ifelse(%s, x, 1)", r_code(unname(design$betas)), r_code(tested)),
      effect_script = sprintf("exp(x * %s)", r_code(size))
    ))
  }
  if (identical(spec$design, "signal_detection") && identical(spec$template, "dprime")) {
    d1 <- pop$dprime[[1]]
    entered <- pop$dprime[[2]] - d1
    direction <- pwrss_search_direction(spec, entered)
    return(list(
      guess = guess_from(entered, 0.3),
      set = function(s, x) { s$population$dprime[[2]] <- d1 + direction * x; s },
      effect = function(x) direction * x,
      effect_name = "dprime_difference",
      what = sprintf("difference in average d' between the conditions (the second minus the first), with the first's kept at %s", format(d1)),
      script_set = sprintf("  d2 <<- d1 + %s * x", r_code(direction)),
      effect_script = sprintf("%s * x", r_code(direction))
    ))
  }
  if (identical(spec$design, "meta_analysis") && identical(spec$template, "mean_effect") && hartung_knapp_test(spec)) {
    direction <- pwrss_search_direction(spec, pop$effect %||% 0)
    r <- identical(pop$metric, "r")
    z_test <- spec
    z_test$target_test$test <- "z"
    guess <- tryCatch(abs(formula_search_sensitivity(z_test, n, power)$effect), error = function(e) if (r) 0.2 else 0.3)
    return(list(
      guess = guess,
      set = function(s, x) { s$population$effect <- direction * x; s },
      effect = function(x) direction * x,
      effect_name = if (r) "meta_r" else "meta_d",
      what = sprintf("average effect, as %s, with studies of %s participants and I-squared %s",
        if (r) "a correlation r" else "Cohen's d", format(pop$study_size), format(pop$i2)),
      # The script's inputs for the average effect (meta_hk_script()).
      script_set = c(
        sprintf("  theta <<- %s", if (r) sprintf("atanh(%s * x)", r_code(direction)) else sprintf("%s * x", r_code(direction))),
        if (r) sprintf("  v <<- 1 / (%s - 3)", r_code(pop$study_size)) else
          sprintf("  v <<- 4 / %s + theta^2 / (2 * %s)", r_code(pop$study_size), r_code(pop$study_size)),
        sprintf("  tau2 <<- %s * v / (1 - %s)", r_code(pop$i2), r_code(pop$i2))
      ),
      effect_script = sprintf("%s * x", r_code(direction))
    ))
  }
  NULL
}

simulated_search_available <- function(spec) {
  (identical(spec$design, "meta_analysis") && identical(spec$template, "mean_effect") && hartung_knapp_test(spec)) ||
    (identical(spec$design, "basic_test") && isTRUE(spec$template %in% c("paired_variances", "proportion_trend"))) ||
    levene_test(spec) || mcnemar_chisq_test(spec) ||
    (identical(spec$design, "signal_detection") && identical(spec$template, "dprime")) ||
    jonckheere_search(spec) || logistic_factorial_search(spec) ||
    (identical(spec$design, "regression_interaction") && identical(spec$template, "group_moderator")) ||
    identical(spec$template, "its") || moderation_ratio_search(spec) || multinomial_search(spec) ||
    binary_interaction_search(spec) ||
    (identical(spec$design, "mixture") && identical(spec$template, "lpa")) ||
    (identical(spec$design, "factor_analysis") && identical(spec$template, "efa"))
}

# Moderated regression with a yes/no X or W (E15), which InteractionPoweR
# simulates (its fixed-model formula assumes continuous variables).
binary_interaction_search <- function(spec) {
  identical(spec$design, "regression_interaction") && identical(spec$template %||% "two_way", "two_way") &&
    any(interaction_binary(spec))
}

# An outcome in unordered categories (E70), and its moderation (E32): the
# pattern of log odds ratios against the first category, scaled.
multinomial_search <- function(spec) {
  identical(spec$design, "logistic_regression") && isTRUE(spec$template %in% c("multinomial", "multinomial_interaction"))
}

# Moderation of a yes/no or count outcome (E32): the X x W odds or rate
# ratio.
moderation_ratio_search <- function(spec) {
  identical(spec$template, "interaction") && isTRUE(spec$design %in% c("logistic_regression", "poisson_regression"))
}

logistic_factorial_search <- function(spec) {
  identical(spec$design, "logistic_regression") && identical(spec$template, "factorial") && !is.null(spec$population$probabilities)
}

# The size of the factorial logistic effect tested, on the log-odds scale,
# from the cells' log-odds (rows are A's levels): for a main effect the
# largest difference between the factor's levels averaged over the other
# factor; for the interaction the largest interaction contrast of any two
# levels of each factor (the log of a ratio of odds ratios).
logistic_factorial_contrast <- function(spec, logits) {
  effect <- spec$target_test$effect
  if (identical(effect, "main_effect_A")) return(diff(range(rowMeans(logits))))
  if (identical(effect, "main_effect_B")) return(diff(range(colMeans(logits))))
  pairs <- function(k) utils::combn(k, 2)
  rows <- pairs(nrow(logits))
  cols <- pairs(ncol(logits))
  max(vapply(seq_len(ncol(rows)), function(i) max(vapply(seq_len(ncol(cols)), function(j) {
    r <- rows[, i]
    k <- cols[, j]
    abs(logits[r[1], k[1]] - logits[r[2], k[1]] - logits[r[1], k[2]] + logits[r[2], k[2]])
  }, numeric(1))), numeric(1)))
}

jonckheere_search <- function(spec) {
  identical(spec$design, "factorial_anova") && identical(spec$template, "oneway_between") &&
    identical(spec$target_test$method, "jonckheere_terpstra") && !is.null(spec$population$means)
}

# Whether the search scales the pattern entered (so a flat pattern can't
# be searched).
simulated_search_scales_pattern <- function(spec) {
  isTRUE(spec$template %in% c("proportion_trend", "group_moderator")) || multinomial_search(spec) || jonckheere_search(spec) || logistic_factorial_search(spec) ||
    (identical(spec$template, "its") && identical(spec$target_test$effect, "both"))
}

simulated_effect_sensitivity <- function(spec, n, power, nrep, seed, cores = 1L, level = 0.95) {
  plan <- simulated_search_plan(spec, n, power)
  found <- simulated_scale_search(plan$guess, power, seed, level, function(x, x_seed) {
    route_backend(plan$set(spec, x), x_seed)$simulate(n, nrep, x_seed, cores)
  }, limit = plan$limit %||% Inf)
  points <- found$points[order(found$points$scale), ]
  estimate <- found$estimate
  record <- simulation_record(rep(n, nrow(points)), points$seed, points$rejections, points$nrep,
    points$scale %in% found$fitted, points$attempted, points$valid)
  record$scale <- points$scale
  ends <- sort(plan$effect(c(estimate$lower, estimate$upper)))
  list(
    sensitivity = list(
      scale = estimate$scale, scale_lower = estimate$lower, scale_upper = estimate$upper,
      effect = plan$effect(estimate$scale), effect_lower = ends[1], effect_upper = ends[2],
      effect_name = plan$effect_name,
      effect_description = sprintf("the %s", plan$what),
      power = power,
      simulated = TRUE,
      searched = TRUE
    ),
    curve = data.frame(n = n, power = power, mcse = 0),
    simulations = record
  )
}
