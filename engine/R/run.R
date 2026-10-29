#' Run a power analysis
#'
#' Validates a design specification, checks that the backend reproduces the
#' specified population (the check run), then computes power at a fixed n,
#' the sample size that reaches the target power, or the smallest
#' detectable effect.
#'
#' **Backends.** Basic tests run on pwr's exact formulas by default (Spower
#' simulation on request, and for Welch's t-test; two proportions on base
#' R's `stats::power.prop.test()` for equal groups and pwrss for unequal
#' groups), regression interactions on
#' InteractionPoweR, mediation and moderated mediation (PROCESS models 4, 6,
#' 7 and 14) on power4mome, and 2x2 ANOVA designs on Superpower.
#' Wave 2 (engine only, not yet in the app): one-way between-participants
#' ANOVA on Superpower's `ANOVA_exact()`; multiple regression R-squared
#' (against 0, or an increase) on `pwrss::power.f.regression()`; one
#' proportion and McNemar's test on pwrss's exact tests
#' (`power.exact.oneprop()`, `power.exact.mcnemar()`); and Welch's t-test
#' by formula on request (`options > method = "exact"`,
#' `pwrss::power.t.welch()`). These have no simulation option. For the two
#' exact tests of counts, whose power goes up and down with n, the required
#' n is the smallest that reaches the target power.
#' More tests by formula (engine only, not yet in the app), each on one
#' pwrss function: Fisher's exact test of two proportions
#' (`target_test > method = "fisher_exact"`, `power.exact.fisher()`), the
#' chi-square goodness-of-fit test (`power.chisq.gof()`, with Cohen's w from
#' `probs.to.w()`), two independent correlations (`power.z.twocors()`) and
#' one-way ANCOVA (`power.f.ancova.shieh()`). None has a simulation option;
#' Fisher's exact test is an exact test of counts too.
#' One-way repeated-measures ANOVA (template `oneway_within`): one
#' within-participants factor with three or more levels, the omnibus F test
#' on Superpower's `ANOVA_exact()` (design `"kw"`), with one SD and one
#' correlation `population > r` for every pair of conditions, so sphericity
#' holds. `goal > n` is the number of participants, each in every condition.
#' Mixed ANOVA beyond 2 x 2 (template `mixed`): one between factor A by one
#' within factor B, at least one with three or more levels (for example
#' group by time with three timepoints), on Superpower's `ANOVA_exact()`
#' (design `"kb*mw"`), with one SD and one correlation, so sphericity holds.
#' `population > means` has one row per level of A, one mean per level of B.
#' Rank tests (`target_test > method` `"wilcoxon_signed_rank"` for
#' `one_sample_t` and `paired_t`, `"mann_whitney"` for `independent_t`,
#' `"kruskal_wallis"` for `oneway_between`): simulated with Spower's
#' `p_wilcox.test()` and `p_kruskal.test()` on scores of the shape in
#' `population > score_shape` (normal, skewed or heavy-tailed; the
#' signed-rank test, which assumes symmetry, normal or heavy-tailed),
#' shifted by the effect. No formula.
#' Two-way ANCOVA (template `factorial_ancova`): two between factors, either
#' main effect or the interaction, by pwrss's `power.f.ancova.shieh()`
#' (Shieh's method) with the effect's rows of `factorial.contrasts()`;
#' adjusted cell means laid out as for `mixed`, equal cells.
#' Two-factor ANOVA with both factors between participants, beyond 2 x 2
#' (template `factorial_between`, design `"kb*mb"`), or both within
#' participants, 2 x 2 or larger (template `factorial_within`, design
#' `"kw*mw"`, one correlation between every pair of cells, so sphericity
#' holds): either main effect or the interaction on Superpower's
#' `ANOVA_exact()`, with means laid out as for `mixed`. `goal > n` is the
#' total number of participants (split equally across the cells for the
#' between design; each in every cell for the within design).
#' Bayes factor t-tests (`target_test > method` `"bayes_factor"` for
#' `one_sample_t`, `paired_t` and `independent_t`, equal groups): power is
#' the probability that the JZS Bayes factor BF10 reaches
#' `target_test > evidence_threshold` (default 10), by bfpwr's
#' `powertbf01()` in closed form, with a Cauchy analysis prior of scale
#' `target_test > prior_scale` (default 1/sqrt(2)) and a normal design
#' prior with SD `population > effect_sd` (default 0). No alpha.
#' Three-factor ANOVA (template `factorial_three`): factors A, B and C, each
#' between or within participants (between factors first), means as a
#' nested A by B by C array, one SD and one correlation between every pair
#' of a participant's cells; any main effect or interaction on
#' Superpower's `ANOVA_exact()`. `goal > n` is the total number of
#' participants, split equally across the between factors' combinations.
#' Two dependent correlations in one group (engine only), by Steiger's z
#' test with pwrss's `power.z.twocors.steiger()` (unpooled, as G*Power):
#' templates `overlapping_correlations` (X with Y against X with Z) and
#' `nonoverlapping_correlations` (X1 with Y1 against X2 with Y2).
#' Logistic regression (design `logistic_regression`, engine only): the Wald z
#' test of one predictor, a score (odds ratio per SD) or a yes/no group,
#' optionally adjusted for other predictors through their R-squared with
#' it, by pwrss's `power.z.logistic()` (Demidenko's method with variance
#' correction).
#' Poisson regression (design `poisson_regression`, engine only): the Wald z
#' test of one predictor of a count outcome, a score (rate ratio per SD) or
#' a yes/no group, over a mean exposure, optionally adjusted for other
#' predictors through their R-squared with it, by pwrss's
#' `power.z.poisson()` (Demidenko's method with variance correction).
#' Planned comparisons (design `factorial_anova`, template
#' `oneway_contrast`, engine only): the t test of a weighted combination of
#' one factor's group means, by pwrss's `power.t.contrasts()`. The weights
#' go in `target_test > weights`, one per level, adding up to 0; a trend
#' test is the contrast with the matching weights. Two-sided only, equal
#' groups, one contrast at a time.
#' Generic tests (design `generic_test`, engine only): power for a t, F,
#' chi-square or z statistic's noncentrality parameter, or the
#' noncentrality needed for a target power, with pwrss's generic functions.
#' They have no sample size; the result's curve has one row with `n` `NA`.
#' Cluster-randomised trials (design `cluster_trial`, template
#' `cluster_randomised`): whole groups are assigned to one of two
#' conditions and a score compared, by powertools' `crt.parallel.cont()`
#' (the design effect with the degrees of freedom from the number of
#' groups). `goal > n` is the total number of participants, a whole number
#' of groups of `population > cluster_size`, the same number of groups in
#' each condition. Multisite trials (template `multisite`): people are
#' randomised to the two conditions within each group, by powertools'
#' `multisite.cont()`; `goal > n` is a whole number of groups. Group
#' treatment trials (template `group_treatment`): people are randomised one
#' by one and the second condition is delivered in groups, by powertools'
#' `irgtt.cont()` or, for a yes/no outcome, `irgtt.bin()`; `goal > n` is
#' split equally between the conditions.
#' Structural equation models (design `sem`, template `model_fit`): the
#' power of the chi-square test of exact fit to reject a model whose misfit
#' in the population is `population > rmsea`, by semPower's
#' `semPower.postHoc()`. The model's degrees of freedom are
#' `population > df`, or are counted by `semPower.getDf()` for a
#' confirmatory factor analysis of `population > indicators` items on
#' `population > factors` correlated factors. Goals: power and sample size.
#' Three more templates test one restriction against the model without
#' it, by the chi-square difference (likelihood ratio) test: measurement
#' invariance of one factor across two groups (template `invariance`,
#' metric or scalar, semPower's `semPower.powerMI()`; `goal > n` is split
#' between the groups by `options > allocation_ratio`), the correlation
#' between two factors against zero (template `factor_correlation`,
#' `semPower.powerCFA()`) and one slope of a latent regression against
#' zero (template `latent_regression`, `semPower.powerRegression()`).
#'
#' **Method.** `options > method` chooses how power is computed. For 2x2
#' ANOVA designs the default is `"exact"` (Superpower's `ANOVA_exact()`,
#' exact for the specified population), and for basic tests other than
#' Welch's t-test it is `"exact"` too (pwr's analytic formulas: noncentral
#' t and chi-square distributions; Fisher's z for a correlation, an
#' approximation). Two proportions use the z test with pooled variance under
#' the null and no continuity correction, as G*Power does
#' (`power.prop.test(strict = TRUE)` for equal groups,
#' `pwrss::power.z.twoprops()` for unequal groups); with
#' `options > proportions_formula = "arcsine"` they use pwr's Cohen's h (the
#' arcsine approximation). `"simulation"` uses Monte Carlo
#' simulation with `options > nrep` replications (default 1,000) and
#' `options > seed` (drawn and recorded if not given). Every other design
#' is simulated. Set
#' `options(powerkit.cores = k)` or the environment variable `POWERKIT_CORES`
#' to spread simulation replications over `k` cores (Unix-alikes only).
#' Mediation and moderated-mediation simulations run in batches of at most
#' 200 replications per power4mome call (fewer above 1,000 draws per
#' confidence interval), keeping only each batch's counts, so memory use
#' doesn't grow with `options > nrep`.
#'
#' **Sensitivity.** For 2x2 designs, the shape of the specified pattern is
#' kept and its size scaled (each cell mean's deviation from the grand mean)
#' until the target effect reaches the target power at n. Sensitivity is not
#' yet available for other designs (the one-way ANOVA included).
#'
#' @param spec A spec as a named list, a JSON string or a path to a JSON file.
#'
#' @return A `powerkit_result`: a list with
#'   * `goal_type`: the spec's goal type;
#'   * `curve`: data frame of `n`, `power` and `mcse` (Monte Carlo standard
#'     error; 0 for exact results); a single row for a fixed-n or
#'     sensitivity goal;
#'   * `n_required`: list of `n`, `lower` and `upper` (95% interval for
#'     simulation; all equal for exact results), or `NA` unless the goal is
#'     `sample_size`;
#'   * `sensitivity`: `NA` unless the goal is `sensitivity`; otherwise a list
#'     with the smallest detectable `effect` (with an `effect_description`)
#'     and the `power` reached there. For 2x2 ANOVAs it also has the `scale`
#'     applied to the specified pattern, the scaled cell `means` and the
#'     `cohen_f`; for the basic tests on pwr, the `effect_name` (`d`, `d_z`,
#'     `r`, `w` or `p2`);
#'   * `effect_from_units`: `NULL` unless the effect was given in the
#'     outcome's own units (`population > metric` "raw", the t-tests);
#'     otherwise a list with the standardised effect's `name` ("Cohen's d"
#'     or "d_z") and `value`, the `difference` in the outcome's units, and
#'     the `sd` it was divided by (with its `sd_name`), and for a
#'     sensitivity goal the `smallest_difference` in the outcome's units;
#'   * `safeguard`: `NULL` unless the effect justification uses safeguard
#'     power; otherwise [safeguard_effect()]'s list for the earlier study's
#'     estimate, with `lower` the effect size the calculation used.
#'   * `clusters`: `NULL` unless the design is clustered (design
#'     `cluster_trial`); otherwise [cluster_summary()]'s list for the n
#'     analysed: the number of groups, the design effect and the effective
#'     sample size;
#'   * `sem`: `NULL` unless the design is a structural equation model
#'     (design `sem`); otherwise [sem_summary()]'s list: for model fit,
#'     the RMSEA, the model's degrees of freedom and, for a CFA, its
#'     items, factors and lavaan model; for the other templates, the
#'     restriction's degrees of freedom;
#'   * `recruitment`: `NA` unless `options > attrition` is above 0;
#'     otherwise a list with the `attrition`, `n_analysed` (the required n,
#'     or the goal's n) and its `groups_analysed`, and `n_recruit` and
#'     `groups_recruit`: each group's analysed n divided by
#'     (1 - attrition) and rounded up. This common heuristic ignores how
#'     missing data will be handled (Rubin, 2025, doi:10.1002/ijop.70017);
#'   * `check_run`: data frame comparing specified and recovered population
#'     values;
#'   * `provenance`: spec hash, method, seed, replications, cores, batch
#'     size (the most replications simulated in one backend call; `NA` if
#'     the backend isn't run in batches), `simulations` (for a simulated
#'     result, a data frame with one row per simulated n: its `seed`,
#'     `rejections`, analysable replications `nrep`, and `fitted`, whether
#'     the curve for the required n was fitted to it; `NA` for an exact
#'     result), backend and backend function, R and package versions, and
#'     run time. A simulated result is reproduced by the same seed,
#'     replications and batch size; for a backend run in batches, the
#'     number of cores doesn't change it. [export_script()] writes an R
#'     script that reproduces a result with the backend package alone.
#' @export
#' @examples
#' \donttest{
#' spec <- read_spec(system.file("specs", "anova_2x2_mixed.json", package = "powerkit"))
#' run_spec(spec)
#' }
run_spec <- function(spec) {
  spec <- validate_spec(spec)
  seed <- spec$options$seed %||% sample.int(2147483646L, 1)
  if (spec$design == "generic_test") {
    return(run_generic(spec, seed))
  }
  backend <- route_spec(spec, seed)
  method <- spec$options$method %||% backend$default_method
  # A backend that simulates may find the smallest detectable effect by a
  # formula of its own (InteractionPoweR's fixed-model power).
  if (identical(spec$goal$type, "sensitivity") && is.null(spec$options$method) && !is.null(backend$sensitivity_method)) {
    method <- backend$sensitivity_method
  } else if (!method %in% backend$methods) {
    abort_run(sprintf(
      "The '%s' method isn't available for this design; use %s.",
      method, quote_list(backend$methods)
    ))
  }
  simulating <- method == "simulation"
  nrep <- if (simulating) spec$options$nrep %||% 1000L else NA_integer_
  cores <- powerkit_cores()
  started <- Sys.time()

  check <- backend$check_run()
  if (!all(check$ok)) {
    abort_run(paste0(
      "powerkit's translation of this design to ", backend$name,
      " did not reproduce the population you specified (",
      paste(check$parameter[!check$ok], collapse = "; "),
      "). This is a bug in powerkit, not in your spec; please report it."
    ))
  }

  goal <- spec$goal
  outcome <- switch(
    goal$type,
    power = c(
      power_at_n(backend, goal$n, simulating, nrep, seed, cores),
      list(n_required = NA, sensitivity = NA)
    ),
    sample_size = c(
      if (simulating) {
        search_n(spec, backend, goal$power, nrep, seed, cores)
      } else {
        search_n_exact(spec, backend, goal$power)
      },
      list(sensitivity = NA)
    ),
    sensitivity = {
      if (is.null(backend$sensitivity)) {
        abort_not_available(
          "Sensitivity analysis (the smallest detectable effect) isn't available yet for this design; use goal type 'power' or 'sample_size'."
        )
      }
      if (simulating) {
        abort_run(
          "Sensitivity analysis uses the exact method; remove 'options > method' or set it to 'exact'."
        )
      }
      found <- backend$sensitivity(goal$n, goal$power)
      list(
        curve = data.frame(n = goal$n, power = found$power, mcse = 0),
        n_required = NA,
        sensitivity = found,
        simulations = NA
      )
    }
  )

  # In the outcome's own units, the smallest detectable effect is also
  # given as a difference: the standardised effect times the SD.
  units <- effect_from_units(spec)
  if (!is.null(units) && is.list(outcome$sensitivity)) {
    units$smallest_difference <- outcome$sensitivity$effect * units$sd
  }

  n_analysed <- if (identical(goal$type, "sample_size")) outcome$n_required$n else goal$n

  structure(
    list(
      goal_type = goal$type,
      curve = outcome$curve,
      n_required = outcome$n_required,
      sensitivity = outcome$sensitivity,
      effect_from_units = units,
      safeguard = safeguard_record(spec),
      recruitment = recruitment_target(spec, n_analysed),
      clusters = cluster_summary(spec, n_analysed),
      sem = sem_summary(spec),
      bayes = bayes_summary(spec, n_analysed),
      check_run = check,
      provenance = list(
        spec_hash = spec_hash(spec),
        method = method,
        seed = seed,
        nrep = nrep,
        cores = if (simulating) cores else NA_integer_,
        batch_size = if (simulating) backend$batch_size %||% NA_integer_ else NA_integer_,
        simulations = outcome$simulations,
        backend = backend$name,
        backend_function = backend$functions[[method]],
        r_version = R.version.string,
        packages = package_versions(c("powerkit", backend$packages,
          if (!is.null(spec$effect_justification$safeguard)) "psych")),
        started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
        run_time_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
      )
    ),
    class = "powerkit_result"
  )
}

# Power at a fixed n: list(curve, simulations), with `simulations` NA for
# exact power.
power_at_n <- function(backend, n, simulating, nrep, seed, cores) {
  if (!simulating) {
    return(list(curve = data.frame(n = n, power = backend$exact_power(n), mcse = 0), simulations = NA))
  }
  sim <- backend$simulate(n, nrep, seed, cores)
  p <- sim$rejections / sim$nrep
  list(
    curve = data.frame(n = n, power = p, mcse = sqrt(p * (1 - p) / sim$nrep)),
    simulations = simulation_record(n, seed, sim$rejections, sim$nrep)
  )
}

package_versions <- function(packages) {
  vapply(packages, function(p) as.character(utils::packageVersion(p)), character(1))
}

#' @export
print.powerkit_result <- function(x, ...) {
  cat("<powerkit result>\n")
  if (identical(x$goal_type, "sample_size")) {
    est <- x$n_required
    if (identical(x$provenance$method, "exact")) {
      cat(sprintf("Required n: %s (exact)\n", est$n))
    } else {
      cat(sprintf("Required n: %s (95%% interval %s to %s)\n", est$n, est$lower, est$upper))
    }
  }
  curve <- x$curve
  cat("Power by n:\n")
  for (i in seq_len(nrow(curve))) {
    if (is.na(curve$n[i])) {
      # Generic tests have no n.
      cat(sprintf("  power = %.3f\n", curve$power[i]))
    } else {
      cat(sprintf("  n = %-6s power = %.3f (MC SE %.3f)\n", curve$n[i], curve$power[i], curve$mcse[i]))
    }
  }
  if (identical(x$goal_type, "sensitivity")) {
    s <- x$sensitivity
    extra <- if (!is.null(s$cohen_f)) sprintf(" (Cohen's f = %.3f)", s$cohen_f) else ""
    cat(sprintf(
      "Smallest detectable effect: %s = %s%s, power %.3f\n",
      s$effect_description, format(signif(s$effect, 4)), extra, s$power
    ))
  }
  r <- x$recruitment
  if (is.list(r)) {
    cat(sprintf(
      "To recruit: %s (analysed n %s / (1 - %s attrition), rounded up per group)\n",
      r$n_recruit, r$n_analysed, format(r$attrition)
    ))
  }
  p <- x$provenance
  method <- if (p$method == "simulation") {
    sprintf("simulation, %s replications, seed %s", p$nrep, p$seed)
  } else {
    "exact"
  }
  cat(sprintf(
    "Check run: %s\nBackend: %s %s (%s)\nSpec hash: %s\n",
    if (all(x$check_run$ok)) "passed" else "FAILED",
    p$backend, p$packages[[p$backend]], method, p$spec_hash
  ))
  invisible(x)
}

abort_run <- function(message, class = NULL) {
  stop(structure(
    class = c(class, "powerkit_run_error", "powerkit_error", "error", "condition"),
    list(message = message, call = NULL)
  ))
}

#' A range for simulated power
#'
#' For a simulated power result, an exact (Clopper-Pearson) confidence
#' interval for power from the rejections and replications the run
#' recorded, by base R's [stats::binom.test()]. The app uses it to show a
#' quick preview as a range rather than a single number. For an exact
#' result both ends are the power itself.
#'
#' @param result A `powerkit_result` for a `power` goal.
#' @param level Confidence level.
#'
#' @return A named numeric vector: `lower` and `upper`.
#' @export
power_interval <- function(result, level = 0.95) {
  if (!inherits(result, "powerkit_result") || !identical(result$goal_type, "power")) {
    abort_run("power_interval() needs the result of run_spec() for a 'power' goal.")
  }
  sims <- result$provenance$simulations
  if (!is.data.frame(sims)) {
    return(c(lower = result$curve$power[1], upper = result$curve$power[1]))
  }
  ci <- stats::binom.test(sims$rejections[1], sims$nrep[1], conf.level = level)$conf.int
  c(lower = ci[1], upper = ci[2])
}
