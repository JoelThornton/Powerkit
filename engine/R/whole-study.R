# Whole-study simulation (experimental; docs/conventions.md, Departure 13).
#
# One population model for the whole study. Each simulated data set is
# analysed with every planned analysis, each fitted with its own model as
# it would be analysed on its own, so every analysis's power and the joint
# power of the main analyses come from the same replications.
#
# All of the statistics are power4mome's (power4mome 0.2.1):
# power4test() generates the data from the standardised paths, fits
# several models to the same data sets (`fit_model_args` with one entry per
# model: lavaan for the mediation models, lmhelprs::many_lm() for the
# regressions), tests each analysis with its test function, and
# rejection_rates() gives each test's rejection rate and, with
# merge_all_tests = TRUE, the rate at which all main tests (collapse =
# "all_sig") or at least one (collapse = "at_least_one_sig") are
# significant in the same replication. powerkit writes the models, checks
# the population, runs the replications in batches and reports.

#' Check a whole-study specification
#'
#' Experimental. Checks a whole-study simulation specification against
#' `inst/schema/whole-study.schema.json`, then that the analyses, variables
#' and paths fit together and that the population is possible. Problems are
#' reported together, in plain English.
#'
#' @param spec A specification as a named list, a JSON string or a path to a
#'   JSON file.
#' @return The specification, normalised, with class `powerkit_whole_study`.
#' @seealso [run_whole_study()]
#' @export
validate_whole_study <- function(spec) {
  if (is.character(spec)) {
    spec <- parse_spec_json(spec_json_text(spec))
  }
  spec <- unclass(spec)
  if (!is_json_object(spec)) {
    abort_spec("The spec must be a set of named fields ({ ... }), not a list or a single value.")
  }
  problems <- check_duplicate_names(spec)
  if (length(problems) == 0) {
    problems <- check_spec_version(spec)
  }
  if (length(problems) == 0) {
    spec <- normalise_spec(spec)
    problems <- schema_problems(spec, whole_study_validator())
  }
  if (length(problems) == 0) {
    problems <- whole_study_problems(spec)
  }
  if (length(problems) > 0) {
    abort_spec(problems)
  }
  structure(spec, class = "powerkit_whole_study")
}

whole_study_validator <- function() {
  if (is.null(spec_cache$whole_study_validator)) {
    path <- system.file("schema", "whole-study.schema.json", package = "powerkit", mustWork = TRUE)
    spec_cache$whole_study_validator <- jsonvalidate::json_validator(path, engine = "ajv")
  }
  spec_cache$whole_study_validator
}

# The structure of the population model the analyses imply: which variable
# is regressed on which, and which product terms exist. Every analysis's
# own model is nested in it.
#   Mediators: X -> M (and, in a chain, M1 -> M2); W and X x W -> M when
#     moderated mediation has W moderating X -> M (PROCESS model 7).
#   Y: X and every mediator; W and X x W when an analysis tests X x W on
#     Y; W and M x W when W moderates M -> Y (PROCESS model 14).
whole_study_model <- function(spec) {
  tests <- vapply(spec$analyses, function(a) a$test, character(1))
  links <- unlist(lapply(spec$analyses, function(a) a$moderated_link))
  mediators <- sort(intersect(c("M", "M1", "M2"), names(spec$variables)))
  serial <- identical(spec$mediators, "serial")
  products <- list()
  m_eq <- lapply(seq_along(mediators), function(j) {
    c("X", if (serial) mediators[seq_len(j - 1)], if ("x_m" %in% links) c("W", "XW"))
  })
  names(m_eq) <- mediators
  y_eq <- c("X", mediators)
  if ("x_m" %in% links) products$XW <- c("X", "W")
  if ("interaction" %in% tests) {
    y_eq <- c(y_eq, "W", "XW")
    products$XW <- c("X", "W")
  }
  if ("m_y" %in% links) {
    y_eq <- c(y_eq, "W", "MW")
    products$MW <- c("M", "W")
  }
  y_eq <- unique(y_eq)
  list(
    exogenous = intersect(c("X", "W"), names(spec$variables)),
    mediators = mediators,
    serial = serial,
    products = products,
    equations = c(m_eq, list(Y = y_eq))
  )
}

#' The population values a whole study needs
#'
#' Experimental. For a whole-study specification whose population values
#' aren't given yet (`population` is ignored), the paths and correlations
#' its population model needs, so that an input screen can ask for each.
#' The analyses and variables are checked first.
#'
#' @param spec A whole-study specification as a named list.
#' @return A list: `paths`, the 'From->To' keys the population needs, and
#'   `correlations`, the correlation keys ('X<->W', 'M1<->M2').
#' @seealso [run_whole_study()]
#' @export
whole_study_parameters <- function(spec) {
  spec <- unclass(spec)
  spec$population <- list(paths = list(placeholder = 0))
  problems <- schema_problems(normalise_spec(spec), whole_study_validator())
  if (length(problems) == 0) {
    problems <- whole_study_structure_problems(spec)
  }
  if (length(problems) > 0) {
    abort_spec(problems)
  }
  roles <- names(spec$variables)
  list(
    paths = model_paths(whole_study_model(spec)),
    correlations = c(if ("W" %in% roles) "X<->W", if (identical(spec$mediators, "parallel")) "M1<->M2")
  )
}

# The analyses and variables fit together (before the population is read).
whole_study_structure_problems <- function(spec) {
  roles <- names(spec$variables)
  tests <- vapply(spec$analyses, function(a) a$test, character(1))
  ids <- vapply(spec$analyses, function(a) a$id, character(1))
  mediators <- intersect(c("M", "M1", "M2"), roles)
  problems <- character()
  if (anyDuplicated(ids)) {
    problems <- c(problems, "Each analysis needs its own 'id'.")
  }
  if (!"main" %in% vapply(spec$analyses, function(a) a$role, character(1))) {
    problems <- c(problems, "Mark at least one analysis as a main analysis ('role': 'main').")
  }
  needs_w <- any(tests %in% c("interaction", "index_of_mome"))
  if (needs_w && !"W" %in% roles) {
    problems <- c(problems, "An analysis with a moderator needs the moderator W in 'variables'.")
  }
  if (!needs_w && "W" %in% roles) {
    problems <- c(problems, "W is in 'variables' but no analysis uses a moderator; remove it.")
  }
  needs_m <- any(tests %in% c("indirect", "index_of_mome"))
  if (needs_m && length(mediators) == 0) {
    problems <- c(problems, "A mediation analysis needs a mediator (M, or M1 and M2) in 'variables'.")
  }
  if (!needs_m && length(mediators) > 0) {
    problems <- c(problems, "Mediators are in 'variables' but no analysis uses them; remove them.")
  }
  if (length(mediators) > 0 && !(identical(mediators, "M") || identical(sort(mediators), c("M1", "M2")))) {
    problems <- c(problems, "Name one mediator M, or two mediators M1 and M2.")
  }
  two <- identical(sort(mediators), c("M1", "M2"))
  if (two && is.null(spec$mediators)) {
    problems <- c(problems, "With two mediators, say how they connect: 'mediators': 'parallel' or 'serial'.")
  }
  if (!two && !is.null(spec$mediators)) {
    problems <- c(problems, "'mediators' applies only with two mediators (M1 and M2).")
  }
  if ("index_of_mome" %in% tests && !identical(mediators, "M")) {
    problems <- c(problems, "Moderated mediation is available with one mediator, named M.")
  }
  if (sum(tests == "index_of_mome") > 1) {
    problems <- c(problems, "Only one moderated mediation analysis can be simulated at a time.")
  }
  for (a in spec$analyses) {
    if (identical(a$test, "indirect")) {
      nodes <- strsplit(a$path, "->", fixed = TRUE)[[1]]
      inner <- nodes[-c(1, length(nodes))]
      if (!all(inner %in% mediators)) {
        problems <- c(problems, sprintf("The path '%s' names a mediator that isn't in 'variables'.", a$path))
      } else if (length(inner) == 2 && !identical(spec$mediators, "serial")) {
        problems <- c(problems, sprintf("The path '%s' goes through both mediators, which only a chain (serial mediators) has.", a$path))
      } else if (length(inner) == 2 && !identical(inner, c("M1", "M2"))) {
        problems <- c(problems, sprintf("In a chain the path runs X->M1->M2->Y, not '%s'.", a$path))
      }
    }
  }
  problems
}

whole_study_problems <- function(spec) {
  problems <- whole_study_structure_problems(spec)
  if (length(problems) > 0) {
    return(problems)
  }
  roles <- names(spec$variables)
  two <- identical(sort(intersect(c("M1", "M2"), roles)), c("M1", "M2"))
  model <- whole_study_model(spec)
  expected <- model_paths(model)
  given <- names(spec$population$paths)
  missing <- setdiff(expected, given)
  extra <- setdiff(given, expected)
  if (length(missing) > 0) {
    problems <- c(problems, sprintf(
      "The population model needs a value for every path (0 for no effect). Missing: %s.",
      paste(missing, collapse = ", ")
    ))
  }
  if (length(extra) > 0) {
    problems <- c(problems, sprintf(
      "These paths aren't part of the model the analyses imply: %s. Remove them.",
      paste(extra, collapse = ", ")
    ))
  }
  correlations <- spec$population$correlations %||% list()
  wanted <- c(if ("W" %in% roles) "X<->W", if (two && identical(spec$mediators, "parallel")) "M1<->M2")
  missing_r <- setdiff(wanted, names(correlations))
  extra_r <- setdiff(names(correlations), wanted)
  if (length(missing_r) > 0) {
    problems <- c(problems, sprintf("Give the correlation %s (0 if none).", paste(missing_r, collapse = " and ")))
  }
  if (length(extra_r) > 0) {
    problems <- c(problems, sprintf("The correlation %s doesn't apply to this model. Remove it.", paste(extra_r, collapse = " and ")))
  }
  if (length(problems) > 0) {
    return(problems)
  }
  whole_study_variance_problems(spec, model)
}

# Each outcome's explained variance must be below 1. It is computed with
# the validator the PROCESS templates already use (implied_r_squared()),
# through a spec in their form: that function reads the template's
# structure from path_model(), so the whole-study structure is given to
# it directly.
whole_study_variance_problems <- function(spec, model) {
  r2 <- implied_r_squared(whole_study_paths_spec(spec), model)
  bad <- names(r2$r_squared)[!is.finite(r2$r_squared) | r2$r_squared >= 1]
  if (length(bad) == 0) {
    return(character())
  }
  vapply(bad, function(v) sprintf(
    "These paths are impossible together: they explain %s%% of the variance in %s (R-squared %s), but R-squared must be below 1. Make some paths into %s smaller.",
    format_number(round(100 * r2$r_squared[[v]], 1)), var_label(spec, v), format_number(round(r2$r_squared[[v]], 3)), var_label(spec, v)
  ), character(1), USE.NAMES = FALSE)
}

# The population in the form the PROCESS templates' checks read: the
# correlation of X and W as an exogenous correlation, and parallel
# mediators' correlation as a residual correlation.
whole_study_paths_spec <- function(spec) {
  correlations <- spec$population$correlations %||% list()
  list(
    design = "whole_study",
    variables = spec$variables,
    population = list(
      paths = spec$population$paths,
      correlations = correlations["X<->W"[!is.null(correlations[["X<->W"]])]],
      residual_correlations = correlations["M1<->M2"[!is.null(correlations[["M1<->M2"]])]]
    )
  )
}

# power4mome's inputs: the population model and values, one fitted model
# per analysis, and each analysis's test.
whole_study_inputs <- function(spec) {
  model <- whole_study_model(spec)
  term <- function(v) if (v %in% names(model$products)) paste(model$products[[v]], collapse = ":") else v
  paths <- spec$population$paths
  regressions <- vapply(names(model$equations), function(outcome) {
    paste(outcome, "~", paste(vapply(model$equations[[outcome]], term, character(1)), collapse = " + "))
  }, character(1))
  pop_paths <- unlist(lapply(names(model$equations), function(outcome) {
    vapply(model$equations[[outcome]], function(p) {
      sprintf("%s ~ %s: %s", outcome, term(p), format_pop_value(paths[[paste0(p, "->", outcome)]]))
    }, character(1))
  }), use.names = FALSE)
  correlations <- spec$population$correlations %||% list()
  covariances <- character()
  pop_covariances <- character()
  if (!is.null(correlations[["X<->W"]])) {
    pop_covariances <- sprintf("X ~~ W: %s", format_pop_value(correlations[["X<->W"]]))
  }
  if (!is.null(correlations[["M1<->M2"]])) {
    # power4mome's value for 'M1 ~~ M2' is the residual covariance (all
    # observed variables standardised), so the residual correlation is
    # multiplied by the two residual SDs, as power4mome_inputs() does for
    # parallel mediation.
    r2 <- implied_r_squared(whole_study_paths_spec(spec), model)$r_squared
    covariances <- "M1 ~~ M2"
    pop_covariances <- c(pop_covariances, sprintf(
      "M1 ~~ M2: %s",
      format_pop_value(correlations[["M1<->M2"]] * sqrt((1 - r2[["M1"]]) * (1 - r2[["M2"]])))
    ))
  }

  alpha <- spec$alpha
  mains <- vapply(spec$analyses, function(a) identical(a$role, "main"), logical(1))
  # Under "any", each main test is at alpha / (number of main analyses).
  main_alpha <- if (identical(spec$claim, "any")) alpha / sum(mains) else alpha
  fits <- list()
  analyses <- lapply(seq_along(spec$analyses), function(i) {
    a <- spec$analyses[[i]]
    fit_name <- if (i == 1) "fit" else paste0("fit", i)
    level <- 1 - (if (mains[i]) main_alpha else alpha)
    fitted <- whole_study_fit(a, spec)
    fits[[fit_name]] <<- fitted$args
    test <- switch(
      a$test,
      x_y = list(fun = "test_parameters", args = list(pars = "Y~X", level = level)),
      interaction = list(fun = "test_moderation", args = list(level = level)),
      indirect = {
        nodes <- strsplit(a$path, "->", fixed = TRUE)[[1]]
        list(fun = "test_indirect_effect", args = list(x = "X", m = nodes[-c(1, length(nodes))], y = "Y",
          mc_ci = TRUE, boot_ci = FALSE, level = level, test_method = "ci"))
      },
      index_of_mome = list(fun = "test_index_of_mome", args = list(x = "X", m = "M", y = "Y", w = "W",
        mc_ci = TRUE, boot_ci = FALSE, level = level, test_method = "ci"))
    )
    test$args$fit_name <- fit_name
    list(id = a$id, label = a$label, role = a$role, test = a$test, path = a$path,
      moderated_link = a$moderated_link, alpha = 1 - level,
      fit_name = fit_name, fit_model = fitted$text, fit_function = fitted$fun,
      test_fun = test$fun, test_args = test$args)
  })
  list(
    model = paste(c(regressions, covariances), collapse = "\n"),
    pop_es = paste(c(pop_paths, pop_covariances), collapse = "\n"),
    equations = model$equations,
    term = term,
    structure = model,
    fits = fits,
    analyses = analyses,
    mains = vapply(analyses, function(a) a$id, character(1))[mains],
    needs_draws = any(vapply(analyses, function(a) a$test %in% c("indirect", "index_of_mome"), logical(1))),
    ci_draws = spec$options$ci_draws %||% default_ci_draws()
  )
}

# The model each analysis is fitted with, as it would be analysed on its
# own: the regressions by OLS (lmhelprs::many_lm(), power4mome's "lm"), so
# the test of X is the t test of the correlation and the test of X x W is
# the t test InteractionPoweR simulates; the mediation models with lavaan,
# as power4mome fits them for powerkit's mediation designs (residuals of
# parallel mediators free to correlate, Departure 7).
whole_study_fit <- function(a, spec) {
  regression <- function(formula) list(fun = "lm", text = formula, args = list(fit_function = "lm", model = list(formula)))
  sem <- function(lines) {
    text <- paste(lines, collapse = "\n")
    list(fun = "lavaan", text = text, args = list(model = text))
  }
  mediators <- sort(intersect(c("M", "M1", "M2"), names(spec$variables)))
  switch(
    a$test,
    x_y = regression("Y ~ X"),
    interaction = regression("Y ~ X + W + X:W"),
    indirect = if (identical(mediators, "M")) {
      sem(c("M ~ X", "Y ~ M + X"))
    } else if (identical(spec$mediators, "serial")) {
      sem(c("M1 ~ X", "M2 ~ M1 + X", "Y ~ M1 + M2 + X"))
    } else {
      sem(c("M1 ~ X", "M2 ~ X", "Y ~ M1 + M2 + X", "M1 ~~ M2"))
    },
    index_of_mome = if (identical(a$moderated_link, "x_m")) {
      sem(c("M ~ X + W + X:W", "Y ~ M + X"))
    } else {
      sem(c("M ~ X", "Y ~ M + X + W + M:W"))
    }
  )
}

#' Simulate a whole study (experimental)
#'
#' Experimental, and not yet checked by a statistician
#' (`docs/conventions.md`, Departure 13). One population model for the
#' whole study, given as standardised paths. Each simulated data set is
#' analysed with every planned analysis, each fitted with its own model as
#' it would be analysed on its own, so all the analyses' power comes from
#' the same replications. Under the claim "all", the joint power is the
#' proportion of replications in which every main analysis is significant;
#' under "any", in which at least one is (each main test at alpha divided
#' by the number of main analyses). All of the simulation, model fitting
#' and testing is power4mome's [power4mome::power4test()].
#'
#' With the goal `sample_size`, it first searches for the smallest n whose
#' power reaches the goal's `power`, by the same simulation search as
#' [run_spec()] (short runs to bracket it, then `nrep` replications at
#' several n smoothed by a probit curve), and then reports a full run at
#' that n. What reaches the target depends on the claim: with one main
#' analysis, its power; under "all", the chance that every main analysis is
#' significant; under "any", that at least one is; under "each", the power
#' of every main analysis. A search simulates every analysis at many n, so
#' it is slow (hours, for mediation): run it on your own computer, with the
#' script from [export_whole_study_script()].
#'
#' @param spec A whole-study specification (see [validate_whole_study()]).
#' @return A `powerkit_whole_study_result`: a list with `n` (the n found,
#'   for a sample size search), `goal`, `claim`,
#'   `alpha`, `analyses` (a data frame: each analysis's `id`, `label`,
#'   `role`, `test`, the `alpha` it was tested at, `power`, `mcse`, a 95%
#'   Clopper-Pearson interval `lower` and `upper`, and `nrep`, the
#'   replications it could be analysed in), `joint` (`NULL` with one main
#'   analysis; otherwise its `rule`, `power`, `mcse`, `lower`, `upper` and
#'   `nrep`), `sample_size` (`NULL` unless the goal is a sample size:
#'   the `target`, the `rule` and `criterion` it was reached by,
#'   `n_required` with its 95% interval `lower` and `upper`, the power
#'   `curve` and the `simulations` behind it), `implied` (what the population implies for each analysis,
#'   from one large simulated data set: the values its own card asks for),
#'   `check_run` and `provenance`.
#' @export
run_whole_study <- function(spec) {
  spec <- validate_whole_study(spec)
  seed <- spec$options$seed %||% sample.int(2147483646L, 1)
  nrep <- spec$options$nrep %||% 1000L
  inputs <- whole_study_inputs(spec)
  started <- Sys.time()
  cores <- powerkit_cores()

  big <- whole_study_big_sample(inputs, seed)
  check <- whole_study_check_run(spec, inputs, big)
  if (!all(check$ok)) {
    abort_run(paste0(
      "powerkit's translation of this study to power4mome did not reproduce the population you specified (",
      paste(check$parameter[!check$ok], collapse = "; "),
      "). This is a bug in powerkit, not in your spec; please report it."
    ))
  }

  search <- NULL
  n <- spec$goal$n
  if (identical(spec$goal$type, "sample_size")) {
    search <- whole_study_search_n(spec, inputs, nrep, seed, cores)
    n <- search$n_required$n
  }
  # The reported powers come from a full run at n (at the n found, for a
  # sample size search), with the spec's own seed.
  totals <- whole_study_counts(inputs, n, nrep, seed, cores)

  rate <- function(rejections, valid) {
    if (valid == 0) {
      return(c(power = NA, mcse = NA, lower = NA, upper = NA, nrep = 0))
    }
    p <- rejections / valid
    ci <- stats::binom.test(rejections, valid)$conf.int
    c(power = p, mcse = sqrt(p * (1 - p) / valid), lower = ci[1], upper = ci[2], nrep = valid)
  }
  per_analysis <- do.call(rbind, lapply(inputs$analyses, function(a) {
    r <- rate(totals[[paste0(a$id, ":sig")]], totals[[paste0(a$id, ":valid")]])
    data.frame(id = a$id, label = a$label, role = a$role, test = a$test, alpha = a$alpha,
      power = r[["power"]], mcse = r[["mcse"]], lower = r[["lower"]], upper = r[["upper"]], nrep = r[["nrep"]])
  }))
  if (any(per_analysis$nrep == 0)) {
    abort_run("None of the simulated data sets could be analysed for at least one analysis. Check the population values, or try a larger n.")
  }
  joint <- NULL
  if (length(inputs$mains) > 1) {
    rule <- if (identical(spec$claim, "any")) "any" else "all"
    r <- rate(totals[[paste0("joint_", rule, ":sig")]], totals[[paste0("joint_", rule, ":valid")]])
    joint <- c(list(rule = rule), as.list(r))
  }

  structure(
    list(
      kind = "whole_study",
      n = n,
      goal = spec$goal,
      claim = spec$claim,
      alpha = spec$alpha,
      analyses = per_analysis,
      joint = joint,
      sample_size = search,
      implied = whole_study_implied(spec, inputs, big),
      check_run = check,
      models = list(population = inputs$model, population_values = inputs$pop_es,
        analyses = vapply(inputs$analyses, function(a) a$fit_model, character(1))),
      provenance = list(
        spec_hash = spec_hash(spec),
        method = "simulation",
        seed = seed,
        nrep = nrep,
        ci_draws = if (inputs$needs_draws) inputs$ci_draws else NA_integer_,
        cores = cores,
        batch_size = power4mome_batch_size(inputs$ci_draws),
        backend = "power4mome",
        backend_function = "power4mome::power4test (several analysis models fitted to the same simulated data sets)",
        r_version = R.version.string,
        packages = package_versions(c("powerkit", "power4mome", "manymome", "lavaan", "lmhelprs")),
        started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
        run_time_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
      )
    ),
    class = "powerkit_whole_study_result"
  )
}

# Every count of whole_study_batch_template(), summed over `nrep`
# replications at n, run in batches spread over the cores. The batches and
# their seeds depend only on nrep and the batch size, not on the cores.
whole_study_counts <- function(inputs, n, nrep, seed, cores) {
  batch <- power4mome_batch_size(inputs$ci_draws)
  chunks <- split_replications(nrep, number_of_chunks(nrep, cores, batch))
  seeds <- offset_seed(seed, seq_along(chunks) - 1)
  counts <- run_in_parallel(seq_along(chunks), function(i) {
    whole_study_batch(inputs, n, chunks[i], seeds[i])
  }, cores)
  counts <- matrix(counts, ncol = length(chunks))
  totals <- rowSums(counts)
  names(totals) <- rownames(whole_study_batch_template(inputs))
  totals
}

# What the sample size search aims for, from the claim: with one main
# analysis, its power; with several, the joint power under "all" (every
# main result significant) or "any" (at least one), and under "each" (every
# main result a separate claim) the power of the weakest main analysis, so
# that each reaches the target.
whole_study_criterion <- function(spec, inputs) {
  mains <- inputs$mains
  if (length(mains) == 1) {
    label <- inputs$analyses[[match(mains, vapply(inputs$analyses, function(a) a$id, character(1)))]]$label
    return(list(rule = "single", description = sprintf("the power of the main analysis (%s)", label),
      counts = function(totals) totals[paste0(mains, c(":sig", ":valid"))]))
  }
  switch(
    spec$claim,
    all = list(rule = "all", description = "the chance that every main analysis is significant",
      counts = function(totals) totals[c("joint_all:sig", "joint_all:valid")]),
    any = list(rule = "any", description = "the chance that at least one main analysis is significant",
      counts = function(totals) totals[c("joint_any:sig", "joint_any:valid")]),
    each = list(rule = "each", description = "the power of each main analysis (the weakest one at each n)",
      counts = function(totals) {
        rates <- vapply(mains, function(id) totals[[paste0(id, ":sig")]] / max(1, totals[[paste0(id, ":valid")]]), numeric(1))
        weakest <- mains[which.min(rates)]
        totals[paste0(weakest, c(":sig", ":valid"))]
      })
  )
}

# The smallest n whose power (by the claim's criterion) reaches the target,
# by powerkit's simulation search (search_n()): short runs bracket it, then
# runs of `nrep` replications at several n around it are smoothed by a
# probit curve. Each simulated n analyses every planned analysis.
whole_study_search_n <- function(spec, inputs, nrep, seed, cores) {
  criterion <- whole_study_criterion(spec, inputs)
  backend <- list(
    n_step = 1,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      counts <- criterion$counts(whole_study_counts(inputs, n, nrep, seed, cores))
      list(rejections = unname(counts[[1]]), nrep = unname(counts[[2]]))
    }
  )
  search <- search_n(spec, backend, spec$goal$power, nrep, seed, cores)
  c(list(target = spec$goal$power, rule = criterion$rule, criterion = criterion$description), search)
}

# The counts one batch returns, in a fixed order: for each analysis its
# significant and analysable replications, then the same for the joint
# rules over the main analyses.
whole_study_batch_template <- function(inputs) {
  rows <- c(
    unlist(lapply(inputs$analyses, function(a) paste0(a$id, c(":sig", ":valid")))),
    "joint_all:sig", "joint_all:valid", "joint_any:sig", "joint_any:valid"
  )
  matrix(0, nrow = length(rows), ncol = 1, dimnames = list(rows, NULL))
}

# One batch: `nrep` data sets at n, every analysis fitted and tested on each.
whole_study_batch <- function(inputs, n, nrep, seed) {
  old <- options(power4mome.bz = FALSE)
  on.exit(options(old))
  obj <- power4mome_call(
    inputs, n, nrep, seed,
    R = if (inputs$needs_draws) inputs$ci_draws,
    ci_type = "mc",
    fit_model_args = inputs$fits,
    do_the_test = FALSE
  )
  for (a in inputs$analyses) {
    obj <- call_backend("power4mome", quietly(power4mome::power4test(
      object = obj,
      test_fun = getExportedValue("power4mome", a$test_fun),
      test_args = a$test_args,
      # Which fitted model (and its Monte Carlo draws) the test reads, as
      # the test function itself names them for that model.
      map_names = getExportedValue("power4mome", a$test_fun)(get_map_names = TRUE, fit_name = a$fit_name),
      test_name = a$id,
      progress = FALSE
    )))
  }
  counts <- function(object, ...) {
    rates <- power4mome::rejection_rates(object, ...)
    valid <- round(rates$pvalid[1] * nrep)
    c(round(rates$reject[1] * valid), valid)
  }
  only <- function(ids) {
    out <- obj
    out$test_all <- obj$test_all[ids]
    out
  }
  per_test <- unlist(lapply(inputs$analyses, function(a) counts(only(a$id))))
  mains <- only(inputs$mains)
  joint <- if (length(inputs$mains) > 1) {
    c(counts(mains, merge_all_tests = TRUE, collapse = "all_sig"),
      counts(mains, merge_all_tests = TRUE, collapse = "at_least_one_sig"))
  } else {
    rep(0, 4)
  }
  c(per_test, joint)
}

# One large data set from the population (as in every simulation
# backend's check run), used for the check run and for what the
# population implies for each analysis.
whole_study_big_sample <- function(inputs, seed) {
  sim <- power4mome_call(inputs, check_run_n(), 1, seed, do_the_test = FALSE)
  as.data.frame(power4mome::pool_sim_data(sim))
}

# Check run: each population equation refitted by OLS on the large data
# set must give the specified paths, each observed variable must have
# variance 1, and the specified correlations must be recovered, as in
# power4mome_check_run().
whole_study_check_run <- function(spec, inputs, data) {
  n <- nrow(data)
  backtick <- function(v) paste0("`", v, "`")
  paths <- spec$population$paths
  coefficient_rows <- lapply(names(inputs$equations), function(outcome) {
    preds <- inputs$equations[[outcome]]
    terms <- vapply(preds, inputs$term, character(1))
    fit <- stats::lm(stats::reformulate(backtick(terms), response = backtick(outcome)), data = data)
    est <- summary(fit)$coefficients[-1, , drop = FALSE]
    check_run_rows(
      paste0(preds, "->", outcome),
      vapply(preds, function(p) as.numeric(paths[[paste0(p, "->", outcome)]]), numeric(1)),
      est[, "Estimate"],
      est[, "Std. Error"]
    )
  })
  observed <- c(inputs$structure$exogenous, names(inputs$equations))
  variance_rows <- lapply(observed, function(v) {
    squares <- (data[[v]] - mean(data[[v]]))^2
    check_run_rows(sprintf("variance of %s", v), 1, mean(squares), stats::sd(squares) / sqrt(n))
  })
  correlation_row <- function(label, specified, recovered) {
    data.frame(parameter = label, specified = specified, recovered = recovered,
      ok = abs(atanh(recovered) - atanh(specified)) <= 5 / sqrt(n - 3))
  }
  correlations <- spec$population$correlations %||% list()
  correlation_rows <- list()
  if (!is.null(correlations[["X<->W"]])) {
    correlation_rows <- c(correlation_rows, list(correlation_row("X<->W", correlations[["X<->W"]], stats::cor(data$X, data$W))))
  }
  if (!is.null(correlations[["M1<->M2"]])) {
    residuals <- lapply(c("M1", "M2"), function(m) {
      stats::residuals(stats::lm(stats::reformulate(inputs$equations[[m]], response = m), data = data))
    })
    correlation_rows <- c(correlation_rows, list(correlation_row(
      "residual M1<->M2", correlations[["M1<->M2"]], stats::cor(residuals[[1]], residuals[[2]])
    )))
  }
  check <- do.call(rbind, c(coefficient_rows, variance_rows, correlation_rows))
  rownames(check) <- NULL
  check
}

# What the population implies for each analysis, from the large data set:
# the values that analysis's own input screen asks for, estimated by
# fitting that screen's model by OLS (all variables have variance 1, so the
# coefficients are standardised paths). The indirect effect and the index
# of moderated mediation are manymome's, on the same fits.
whole_study_implied <- function(spec, inputs, data) {
  coefs <- function(formula) stats::coef(stats::lm(stats::as.formula(formula), data = data))
  lapply(stats::setNames(inputs$analyses, vapply(inputs$analyses, function(a) a$id, character(1))), function(a) {
    values <- switch(
      a$test,
      x_y = c(r = stats::cor(data$X, data$Y)),
      interaction = c(
        r_X_Y = stats::cor(data$X, data$Y), r_W_Y = stats::cor(data$W, data$Y),
        r_XW_Y = stats::cor(data$X * data$W, data$Y), r_X_W = stats::cor(data$X, data$W)
      ),
      indirect = whole_study_implied_mediation(spec, a, data, coefs),
      index_of_mome = whole_study_implied_mome(a, data, coefs)
    )
    list(id = a$id, test = a$test, values = values)
  })
}

whole_study_implied_mediation <- function(spec, a, data, coefs) {
  nodes <- strsplit(a$path, "->", fixed = TRUE)[[1]]
  mediators <- sort(intersect(c("M", "M1", "M2"), names(spec$variables)))
  serial <- identical(spec$mediators, "serial")
  fits <- lapply(mediators, function(m) {
    rhs <- c("X", if (serial && m == "M2") "M1")
    stats::lm(stats::reformulate(rhs, response = m), data = data)
  })
  y_fit <- stats::lm(stats::reformulate(c(mediators, "X"), response = "Y"), data = data)
  out <- c()
  for (i in seq_along(mediators)) {
    b <- stats::coef(fits[[i]])
    for (p in names(b)[-1]) out[[sprintf("p_%s_%s", p, mediators[i])]] <- b[[p]]
  }
  by <- stats::coef(y_fit)
  for (p in names(by)[-1]) out[[sprintf("p_%s_Y", p)]] <- by[[p]]
  if (identical(mediators, c("M1", "M2")) && !serial) {
    out[["rc_M1_M2"]] <- stats::cor(stats::residuals(fits[[1]]), stats::residuals(fits[[2]]))
  }
  ind <- manymome::indirect_effect(x = "X", y = "Y", m = nodes[-c(1, length(nodes))],
    fit = do.call(manymome::lm2list, c(fits, list(y_fit))))
  out[["indirect"]] <- stats::coef(ind)[[1]]
  unlist(out)
}

whole_study_implied_mome <- function(a, data, coefs) {
  if (identical(a$moderated_link, "x_m")) {
    m_fit <- stats::lm(M ~ X + W + X:W, data = data)
    y_fit <- stats::lm(Y ~ M + X, data = data)
    values <- c(p_X_M = stats::coef(m_fit)[["X"]], p_W_M = stats::coef(m_fit)[["W"]], p_XW_M = stats::coef(m_fit)[["X:W"]],
      p_M_Y = stats::coef(y_fit)[["M"]], p_X_Y = stats::coef(y_fit)[["X"]])
  } else {
    m_fit <- stats::lm(M ~ X, data = data)
    y_fit <- stats::lm(Y ~ M + X + W + M:W, data = data)
    values <- c(p_X_M = stats::coef(m_fit)[["X"]], p_M_Y = stats::coef(y_fit)[["M"]], p_W_Y = stats::coef(y_fit)[["W"]],
      p_MW_Y = stats::coef(y_fit)[["M:W"]], p_X_Y = stats::coef(y_fit)[["X"]])
  }
  index <- manymome::index_of_mome(x = "X", y = "Y", m = "M", w = "W", fit = manymome::lm2list(m_fit, y_fit))
  c(values, c_X_W = stats::cor(data$X, data$W), index = stats::coef(index)[[1]])
}

#' @export
print.powerkit_whole_study_result <- function(x, ...) {
  cat("<powerkit whole-study simulation (experimental)>\n")
  cat(sprintf("n = %s, claim: %s, alpha = %s\n", x$n, x$claim, format(x$alpha)))
  for (i in seq_len(nrow(x$analyses))) {
    a <- x$analyses[i, ]
    cat(sprintf("  %-12s %-5s power = %.3f (MC SE %.3f; %s replications)\n", a$id, a$role, a$power, a$mcse, a$nrep))
  }
  if (!is.null(x$joint)) {
    cat(sprintf("Joint power (%s main analyses significant): %.3f (MC SE %.3f)\n",
      if (x$joint$rule == "all") "all" else "at least one of the", x$joint$power, x$joint$mcse))
  }
  if (!is.null(x$sample_size)) {
    s <- x$sample_size
    cat(sprintf("Sample size for %s%% power (%s): n = %s (95%% interval %s to %s)\n",
      format(100 * s$target), s$criterion, s$n_required$n, s$n_required$lower, s$n_required$upper))
  }
  p <- x$provenance
  cat(sprintf("Check run: %s\nBackend: power4mome %s (simulation, %s replications, seed %s)\nSpec hash: %s\n",
    if (all(x$check_run$ok)) "passed" else "FAILED", p$packages[["power4mome"]], p$nrep, p$seed, p$spec_hash))
  invisible(x)
}
