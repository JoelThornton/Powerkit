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
  if (mixed_model_search(spec)) return(mixed_model_search_plan(spec))
  if (repeated_glmm_search(spec)) return(repeated_glmm_search_plan(spec))
  if (mediation_search(spec)) {
    tested <- mediation_tested_paths(spec)
    k <- length(tested)
    paths <- spec$population$paths
    entered <- prod(vapply(tested, function(p) as.numeric(paths[[p]]), numeric(1)))
    set <- function(s, x) {
      for (p in tested) s$population$paths[[p]] <- as.numeric(paths[[p]]) * x^(1 / k)
      s
    }
    index <- identical(spec$design, "moderated_mediation")
    return(list(
      guess = 1, limit = mediation_scale_limit(spec, set),
      set = set,
      effect = function(x) x * entered,
      effect_name = if (index) "index_of_moderated_mediation" else "indirect_effect",
      what = sprintf("%s (the product of the standardised paths %s), with each of those paths scaled by the same factor and every other path and correlation you entered kept",
        if (index) sprintf("index of moderated mediation through %s", var_label(spec, modmed_mediator(spec))) else
          sprintf("indirect effect along %s", spec$target_test$path),
        quote_list(gsub("->", " -> ", tested, fixed = TRUE), "and")),
      script_set = mediation_pop_es_script(spec, tested, k),
      effect_script = sprintf("x * %s", r_code(entered))
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
    binary_interaction_search(spec) || mediation_search(spec) || mixed_model_search(spec) || repeated_glmm_search(spec) ||
    (identical(spec$design, "mixture") && identical(spec$template, "lpa")) ||
    (identical(spec$design, "factor_analysis") && identical(spec$template, "efa"))
}

# Mixed models fitted by simr (E33, E41, E62, E63, E67, E68): the effect
# tested, the rest you entered kept. A score's difference between two
# conditions, an item predictor's slope, a three-level design's d and a
# two-level model's one coefficient tested are searched themselves (their
# sign kept; for a yes/no outcome the slope or coefficient is on the log
# odds). Conditions' means, or a yes/no outcome's chances on the log-odds
# scale, are scaled about their average: the answer is the difference
# between the conditions tested (the largest and smallest for the test of
# every condition), or for a yes/no outcome their odds ratio. Several
# coefficients tested together are not searched.
mixed_model_search <- function(spec) {
  if (!identical(spec$design, "mixed_model")) return(FALSE)
  switch(spec$template %||% "",
    crossed_two_condition = , crossed_conditions = , item_predictor = , three_level = TRUE,
    two_level = length(two_level_terms(spec$target_test$effect %||% "cross_level_interaction", !is.null(spec$population$groups_per_site))) == 1,
    FALSE)
}

mixed_model_search_plan <- function(spec) {
  pop <- spec$population
  binary <- identical(spec$variables$Y$type, "binary")
  one_value <- function(name, script_name, effect_name, what, default) {
    entered <- as.numeric(pop[[name]] %||% 0)
    direction <- pwrss_search_direction(spec, entered)
    list(
      guess = if (isTRUE(abs(entered) > 1e-8)) abs(entered) else default,
      set = function(s, x) { s$population[[name]] <- direction * x; s },
      effect = function(x) direction * x,
      effect_name = effect_name,
      what = what,
      script_set = sprintf("  %s <<- %s * x", script_name, r_code(direction)),
      effect_script = sprintf("%s * x", r_code(direction))
    )
  }
  units <- if (binary) "on the log odds" else "in the outcome's units"
  if (spec$template %in% c("crossed_two_condition", "crossed_conditions", "three_level") && binary) {
    # The chances of 'yes', scaled about their average on the log-odds
    # scale; reported as the odds ratio of the conditions tested.
    logits <- stats::qlogis(as.numeric(unlist(pop$probabilities)))
    centre <- mean(logits)
    pair <- if (identical(spec$target_test$effect, "pairwise")) match(unlist(spec$target_test$comparison), unlist(spec$variables$X$levels))
    spread <- if (is.null(pair)) max(logits) - min(logits) else abs(diff(logits[pair]))
    fixed_line <- if (identical(spec$template, "three_level")) "  fixed <<- c(mean(qlogis(probabilities)), diff(qlogis(probabilities)))"
    return(list(
      guess = 1,
      set = function(s, x) { s$population$probabilities <- as.list(stats::plogis(centre + x * (logits - centre))); s },
      effect = function(x) exp(x * spread),
      effect_name = "odds_ratio",
      what = sprintf("odds ratio of 'yes' %s, with the pattern of chances you entered kept and scaled about its average on the log-odds scale and every SD kept",
        if (is.null(pair)) "between the conditions with the highest and lowest chance" else "between the two conditions compared"),
      script_set = c(sprintf("  probabilities <<- plogis(%s + x * (%s - %s))", r_code(centre), r_code(logits), r_code(centre)), fixed_line),
      effect_script = sprintf("exp(x * %s)", r_code(spread))
    ))
  }
  switch(spec$template,
    crossed_two_condition = one_value("difference", "difference", "mean_difference",
      "difference between the conditions' means, in the outcome's units, with every SD you entered kept", 0.2 * (pop$sd_residual %||% 1)),
    item_predictor = one_value("slope", "slope", "slope",
      sprintf("slope of the item predictor, per SD of it, %s, with every SD you entered kept", units), if (binary) 0.3 else 0.2 * (pop$sd_residual %||% 1)),
    three_level = one_value("d", "d", "d",
      "standardised difference between the conditions (d over the outcome's total SD), with the shares of variance you entered kept", 0.3),
    two_level = {
      term <- two_level_terms(spec$target_test$effect %||% "cross_level_interaction", !is.null(pop$groups_per_site))
      name <- switch(term, x = "b_X", w = "b_W", z = "b_Z", "x:w" = "b_XW", "x:z" = "b_XZ")
      words <- switch(term, x = "X's effect within groups", w = "W's effect between groups", z = "Z's effect between sites",
        "x:w" = "the cross-level interaction of X and W", "x:z" = "X's interaction with Z")
      one_value(name, tolower(name), "coefficient", sprintf("coefficient of %s, %s, with the other coefficients and every SD you entered kept", words, units),
        if (binary) 0.3 else 0.2 * (pop$sd_residual %||% 1))
    },
    crossed_conditions = {
      m <- as.numeric(unlist(pop$means))
      centre <- mean(m)
      pair <- if (identical(spec$target_test$effect, "pairwise")) match(unlist(spec$target_test$comparison), unlist(spec$variables$X$levels))
      spread <- if (is.null(pair)) max(m) - min(m) else abs(diff(m[pair]))
      list(
        guess = 1,
        set = function(s, x) { s$population$means <- as.list(centre + x * (m - centre)); s },
        effect = function(x) x * spread,
        effect_name = if (is.null(pair)) "mean_range" else "mean_difference",
        what = sprintf("difference between %s, in the outcome's units, with the pattern of means you entered kept and scaled about its average and every SD kept",
          if (is.null(pair)) "the largest and smallest condition means" else "the two conditions compared"),
        script_set = sprintf("  means <<- %s + x * (%s - %s)", r_code(centre), r_code(m), r_code(centre)),
        effect_script = sprintf("x * %s", r_code(spread))
      )
    })
}

# The same people measured more than once with a count, a yes/no answer
# or ordered categories (E75), and Cochran's Q (E78): the differences
# between the conditions you entered, on the model's scale (log rates, log
# odds, or log odds ratios of a higher category), times x, the first
# condition kept as entered. With groups, the group-by-condition
# interaction is scaled and the groups' and conditions' own differences
# are kept: each interaction coefficient in treatment coding is
# multiplied by x, so every ratio of ratios between two groups and two
# conditions is raised to the power x and the first group's first
# condition is kept. The answer is the rate or odds ratio between the
# conditions furthest apart, or with groups the largest ratio of those
# ratios between two groups and two conditions. The person SD, the
# category shares and any overdispersion are kept.
repeated_glmm_search <- function(spec) {
  identical(spec$design, "mixed_model") && identical(spec$template, "repeated_glmm")
}

repeated_glmm_search_plan <- function(spec) {
  inputs <- repeated_glmm_inputs(spec)
  centre <- inputs$centre
  int <- inputs$interaction
  levels <- inputs$levels
  if (int) {
    cells <- repeated_glmm_cells(levels, inputs$groups)
    design <- stats::model.matrix(~ group * cond, cells)
    coefs <- as.numeric(solve(design, centre))
    tested <- grepl(":", colnames(design), fixed = TRUE)
    scaled_centre <- function(x) as.numeric(design %*% (ifelse(tested, x, 1) * coefs))
    table <- matrix(centre, nrow = length(inputs$groups), byrow = TRUE)
    pairs <- function(m) utils::combn(m, 2, simplify = FALSE)
    spread <- max(vapply(pairs(nrow(table)), function(g) max(vapply(pairs(ncol(table)), function(k)
      abs(table[g[1], k[1]] - table[g[1], k[2]] - table[g[2], k[1]] + table[g[2], k[2]]), numeric(1))), numeric(1)))
  } else {
    delta <- centre - centre[1]
    scaled_centre <- function(x) centre[1] + x * delta
    spread <- max(centre) - min(centre)
  }
  to_values <- function(eta) if (inputs$ordinal || inputs$count) exp(eta) else stats::plogis(eta)
  field <- if (inputs$ordinal) "odds_ratios" else if (inputs$count) "rates" else "probabilities"
  rows <- length(inputs$groups)
  as_field <- function(values) {
    if (!int) return(as.list(values))
    lapply(seq_len(rows), function(g) as.list(values[(g - 1L) * length(levels) + seq_along(levels)]))
  }
  ratio <- if (inputs$count) "rate ratio" else "odds ratio"
  kept <- paste(c(if (int) c("the groups' and conditions' own differences", "the first group's first condition") else "the first condition",
    if (inputs$ordinal) "the category shares", if (inputs$nb) "the overdispersion", "the person SD"), collapse = ", ")
  kept <- sub(", ([^,]*)$", " and \\1", kept)
  measure <- if (inputs$ordinal) "log odds ratios of a higher category" else if (inputs$count) "log expected counts" else "log odds of 'yes'"
  # Rates or odds ratios beyond about 1,000 times apart are left out: such
  # a study needs no planning, and its counts would be slow to simulate.
  limit <- if (spread > 0) log(1000) / spread else Inf
  # The script's values, then (with groups, for simr) the fixed effects
  # it derives from them once.
  eta_code <- if (int) {
    sprintf("as.numeric(matrix(%s, nrow = %d) %%*%% (ifelse(%s, x, 1) * %s))", r_code(as.numeric(design)), nrow(design), r_code(tested), r_code(coefs))
  } else {
    sprintf("%s + x * %s", r_code(centre[1]), r_code(delta))
  }
  values_code <- sprintf(if (inputs$ordinal || inputs$count) "exp(%s)" else "plogis(%s)", eta_code)
  set_line <- if (int) {
    sprintf("  %s <<- matrix(%s, nrow = %d, byrow = TRUE, dimnames = list(groups, conditions))", field, values_code, rows)
  } else {
    sprintf("  %s <<- %s", field, values_code)
  }
  simr_route <- !(inputs$nb || inputs$ordinal || inputs$cochran)
  fixed_line <- if (int && simr_route) {
    sprintf("  fixed_effects <<- as.numeric(solve(model.matrix(~ group * cond, cells), %s(as.vector(t(%s)))))",
      if (inputs$count) "log" else "qlogis", field)
  }
  list(
    guess = 1,
    limit = limit,
    set = function(s, x) { s$population[[field]] <- as_field(to_values(scaled_centre(x))); s },
    effect = function(x) exp(x * spread),
    effect_name = if (int) paste0("ratio_of_", gsub(" ", "_", ratio), "s") else gsub(" ", "_", ratio),
    what = sprintf(if (int) {
      "largest ratio of %ss between two groups and two conditions, with %s you entered kept and the group-by-condition interaction (on the %s) scaled"
    } else {
      "%s between the conditions furthest apart, with %s you entered kept and the differences between the conditions (on the %s) scaled"
    }, ratio, kept, measure),
    script_set = c(set_line, fixed_line),
    effect_script = sprintf("exp(x * %s)", r_code(spread))
  )
}

# Mediation and moderated mediation fitted by power4mome (E10 to E14, E16,
# E17, E40): the paths making up the effect tested (the indirect effect
# along the path tested, or the index of moderated mediation, the moderated
# link times the other) are each multiplied by x^(1/k) for k paths, so the
# effect is x times the one entered and keeps its sign; every other path,
# correlation and residual correlation is kept. The conditional indirect
# effects' difference with W on both links (E38) is not searched: its
# residual variances are given explicitly and change with every path.
mediation_search <- function(spec) {
  methods <- c("monte_carlo_ci", "percentile_bootstrap", "ols_percentile_bootstrap")
  isTRUE(spec$target_test$method %in% methods) && (
    (identical(spec$design, "mediation") && isTRUE(spec$template %in% c("process_4", "process_6"))) ||
      (identical(spec$design, "moderated_mediation") && isTRUE(spec$template %in% c("process_7", "process_8", "process_14")) &&
        !cond_indirect_difference(spec)))
}

# The paths whose product is the effect tested, as "from->to".
mediation_tested_paths <- function(spec) {
  if (identical(spec$design, "mediation")) {
    nodes <- trimws(strsplit(spec$target_test$path, "->", fixed = TRUE)[[1]])
    return(paste0(nodes[-length(nodes)], "->", nodes[-1]))
  }
  model <- path_model(spec)
  m <- modmed_mediator(spec)
  first <- if ("XW" %in% model$equations[[m]]) paste0("XW->", m) else paste0("X->", m)
  mw <- names(Filter(function(p) identical(p, c(m, "W")), model$products))
  second <- if (length(mw) == 1 && mw %in% model$equations$Y) paste0(mw, "->Y") else paste0(m, "->Y")
  c(first, second)
}

# The largest scale at which every equation's R-squared stays below 0.99,
# so the population can be standardised.
mediation_scale_limit <- function(spec, set) {
  model <- path_model(spec)
  feasible <- function(x) {
    r2 <- implied_r_squared(set(spec, x), model)$r_squared
    length(r2) == length(setdiff(names(model$equations), names(model$products))) && all(r2 < 0.99)
  }
  if (feasible(1e4)) return(Inf)
  lo <- 0
  hi <- 1e4
  for (i in 1:60) {
    mid <- (lo + hi) / 2
    if (feasible(mid)) lo <- mid else hi <- mid
  }
  lo
}

# The exported script's set_effect(): power4mome's population values
# (power4mome_inputs()) rebuilt at x, with the same arithmetic, so the
# simulated studies are the ones powerkit ran.
mediation_pop_es_script <- function(spec, tested, k) {
  model <- path_model(spec)
  inputs <- power4mome_inputs(spec)
  paths <- spec$population$paths
  value_code <- function(p) {
    if (p %in% tested) sprintf("%s * x^(1 / %s)", r_code(as.numeric(paths[[p]])), r_code(k)) else r_code(as.numeric(paths[[p]]))
  }
  pop_value <- function(code) sprintf("format(as.numeric(%s), digits = 15, scientific = FALSE)", code)
  lines <- unlist(lapply(names(model$equations), function(outcome) {
    vapply(model$equations[[outcome]], function(p) {
      sprintf("paste0(%s, %s)", r_code(sprintf("%s ~ %s: ", outcome, inputs$term(p))), pop_value(value_code(paste0(p, "->", outcome))))
    }, character(1))
  }), use.names = FALSE)
  existing <- strsplit(inputs$pop_es, "\n")[[1]]
  rest <- existing[!grepl("^[^~]+ ~ [^~]", existing)]
  if (!isTRUE(model$serial) && length(model$mediators) > 1 && length(model$products) == 0) {
    # Parallel mediators' residual covariances: each residual correlation
    # times the two residual SDs, which change with a tested X -> M path.
    lookup <- correlation_lookup(spec)
    pairs <- utils::combn(model$mediators, 2, simplify = FALSE)
    residual <- function(m) sprintf("(1 - (%s)^2)", value_code(paste0("X->", m)))
    rest <- vapply(pairs, function(pr) {
      sprintf("paste0(%s, %s)", r_code(sprintf("%s ~~ %s: ", pr[1], pr[2])),
        pop_value(sprintf("%s * sqrt(%s * %s)", r_code(lookup(pr[1], pr[2], residual = TRUE)), residual(pr[1]), residual(pr[2]))))
    }, character(1))
  } else {
    rest <- vapply(rest, r_code, character(1), USE.NAMES = FALSE)
  }
  c("  pop_es <<- paste(c(", paste0("    ", c(lines, rest), c(rep(",", length(lines) + length(rest) - 1), "")), "  ), collapse = \"\\n\")")
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
  isTRUE(spec$template %in% c("proportion_trend", "group_moderator")) || multinomial_search(spec) || mediation_search(spec) ||
    repeated_glmm_search(spec) ||
    (mixed_model_search(spec) && (identical(spec$template, "crossed_conditions") || identical(spec$variables$Y$type, "binary") && spec$template %in% c("crossed_two_condition", "three_level"))) || jonckheere_search(spec) || logistic_factorial_search(spec) ||
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
