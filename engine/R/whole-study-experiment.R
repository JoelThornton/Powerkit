# Whole-study simulation of an experiment (experimental; docs/conventions.md,
# Departure 13; next.md item 1, step "experiments").
#
# An experiment with one or two crossed factors, between or within
# participants, analysed with a factorial ANOVA: the study's planned
# analyses are its F tests (a main effect, the other main effect, the
# interaction). Each simulated data set is analysed once by
# Superpower::ANOVA_power(), which returns every F test's p-value for every
# simulated data set (`sim_data`), so each test's power and the joint power
# of the main tests come from the same replications. The statistics are all
# Superpower's (and afex's, which fits the ANOVA); powerkit builds the
# design from the embedded design spec (superpower_inputs()), counts the
# significant tests per replication and searches the sample size.

whole_study_is_experiment <- function(spec) !is.null(spec$experiment)

whole_study_experiment_templates <- c("oneway_between", "oneway_within", "2x2_between", "2x2_mixed",
  "factorial_between", "factorial_within", "mixed")

# The embedded design spec, given the whole study's goal, alpha and (for
# validate_spec()) the first analysis's effect. Its own options are kept
# only for unequal cells: the whole study's n is the number analysed, and
# its replications and seed are the whole study's.
whole_study_experiment_spec <- function(spec) {
  exp <- spec$experiment
  effects <- vapply(spec$analyses, function(a) a$effect %||% "", character(1))
  exp$target_test$effect <- effects[[1]]
  exp$target_test$alpha <- spec$alpha
  exp$target_test$method <- exp$target_test$method %||% "anova_f"
  exp$goal <- spec$goal
  exp$effect_justification <- spec$effect_justification
  exp$options <- if (!is.null(spec$experiment$options$cell_ratio)) list(cell_ratio = spec$experiment$options$cell_ratio)
  exp
}

whole_study_experiment_problems <- function(spec) {
  problems <- character()
  ids <- vapply(spec$analyses, function(a) a$id, character(1))
  tests <- vapply(spec$analyses, function(a) a$test, character(1))
  effects <- vapply(spec$analyses, function(a) a$effect %||% "", character(1))
  exp <- spec$experiment
  if (anyDuplicated(ids)) problems <- c(problems, "Each analysis needs its own 'id'.")
  if (!"main" %in% vapply(spec$analyses, function(a) a$role, character(1))) {
    problems <- c(problems, "Mark at least one analysis as a main analysis ('role': 'main').")
  }
  if (any(tests != "anova_effect")) {
    problems <- c(problems, "In an experiment every analysis is one of its ANOVA's F tests ('test': 'anova_effect').")
  }
  if (anyDuplicated(effects)) problems <- c(problems, "Each analysis needs a different effect: a main effect, the other main effect or the interaction.")
  if (!identical(exp$design, "factorial_anova") || !(exp$template %||% "") %in% whole_study_experiment_templates) {
    problems <- c(problems, sprintf(
      "The experiment is a factorial ANOVA design with one or two factors ('design': 'factorial_anova', 'template' one of %s).",
      paste(whole_study_experiment_templates, collapse = ", ")))
    return(problems)
  }
  oneway <- exp$template %in% c("oneway_between", "oneway_within")
  if (oneway && any(effects != "main_effect_A")) {
    problems <- c(problems, "With one factor the only effect is its main effect ('main_effect_A').")
  }
  if (!identical(exp$target_test$method %||% "anova_f", "anova_f")) {
    problems <- c(problems, "The whole study simulates the ANOVA's F tests ('target_test > method' 'anova_f').")
  }
  if (!is.null(exp$options$group_ratio)) {
    problems <- c(problems, "Unequal groups in a design with a within-participants factor aren't simulated as a whole study yet; use equal groups.")
  }
  if (length(problems)) return(problems)
  checked <- tryCatch({
    validate_spec(whole_study_experiment_spec(spec))
    character()
  }, powerkit_spec_error = function(e) conditionMessage(e))
  if (length(checked)) problems <- c(problems, paste("In the experiment:", checked))
  problems
}

# Everything a run needs: the Superpower inputs, the analyses with the
# column of ANOVA_power()'s sim_data that holds each one's p-value, and
# each one's alpha (under the claim "any", each main test at alpha divided
# by the number of main analyses, as for the other whole studies).
whole_study_experiment_inputs <- function(spec) {
  exp <- whole_study_experiment_spec(spec)
  inputs <- superpower_inputs(exp)
  mains <- vapply(spec$analyses, function(a) identical(a$role, "main"), logical(1))
  main_alpha <- if (identical(spec$claim, "any")) spec$alpha / sum(mains) else spec$alpha
  factor_of <- c(main_effect_A = "a", main_effect_B = "b", interaction = "a:b")
  analyses <- lapply(seq_along(spec$analyses), function(i) {
    a <- spec$analyses[[i]]
    c(a, list(term = factor_of[[a$effect]], alpha = if (mains[i]) main_alpha else spec$alpha))
  })
  list(spec = exp, superpower = inputs, analyses = analyses,
    mains = vapply(spec$analyses[mains], function(a) a$id, character(1)),
    model = inputs$design)
}

# The sim_data column of an F test's p-values: "anova_a", "anova_b", and
# the interaction as "anova_a:b" or, in some designs, "anova_b:a".
experiment_p_column <- function(columns, term) {
  candidates <- paste0("anova_", c(term, paste(rev(strsplit(term, ":", fixed = TRUE)[[1]]), collapse = ":")))
  hit <- intersect(candidates, columns)
  if (!length(hit)) abort_run(sprintf("Superpower didn't return the F test for '%s'. This is a bug in powerkit; please report it.", term))
  hit[[1]]
}

whole_study_experiment_design <- function(inputs, n, seed) {
  sp <- inputs$superpower
  call_backend("Superpower", with_seed(seed, Superpower::ANOVA_design(
    design = sp$design, n = superpower_cell_n(sp, n), mu = sp$mu, sd = sp$sd, r = sp$r, plot = FALSE
  )))
}

# One batch: ANOVA_power() on k simulated data sets, then for each analysis
# its significant and analysable replications, and the same for the joint
# rules over the main analyses (whole_study_batch_template()'s order).
whole_study_experiment_batch <- function(inputs, n, k, seed) {
  design <- whole_study_experiment_design(inputs, n, seed)
  sp <- inputs$superpower
  result <- call_backend("Superpower", Superpower::ANOVA_power(
    design, alpha_level = sp$alpha, correction = sp$correction %||% "none",
    nsims = k, seed = seed, verbose = FALSE
  ))
  sims <- result$sim_data
  sig <- vapply(inputs$analyses, function(a) {
    p <- sims[[experiment_p_column(names(sims), a$term)]]
    !is.na(p) & p < a$alpha
  }, logical(k))
  sig <- matrix(sig, nrow = k)
  colnames(sig) <- vapply(inputs$analyses, function(a) a$id, character(1))
  mains <- sig[, inputs$mains, drop = FALSE]
  counts <- unlist(lapply(colnames(sig), function(id) c(sum(sig[, id]), k)))
  if (length(inputs$mains) > 1) {
    counts <- c(counts, sum(apply(mains, 1, all)), k, sum(apply(mains, 1, any)), k)
  }
  counts
}

whole_study_experiment_template <- function(inputs) {
  ids <- vapply(inputs$analyses, function(a) a$id, character(1))
  rows <- as.vector(rbind(paste0(ids, ":sig"), paste0(ids, ":valid")))
  if (length(inputs$mains) > 1) rows <- c(rows, "joint_all:sig", "joint_all:valid", "joint_any:sig", "joint_any:valid")
  rows
}

# Every count, summed over nrep replications at n, in batches of at most
# 250 spread over the cores. The batches and their seeds depend only on
# nrep, not on the cores.
whole_study_experiment_counts <- function(inputs, n, nrep, seed, cores) {
  chunks <- split_replications(nrep, number_of_chunks(nrep, cores, 250))
  seeds <- offset_seed(seed, seq_along(chunks) - 1)
  counts <- run_in_parallel(seq_along(chunks), function(i) {
    whole_study_experiment_batch(inputs, n, chunks[i], seeds[i])
  }, cores)
  totals <- rowSums(matrix(unlist(counts), ncol = length(chunks)))
  names(totals) <- whole_study_experiment_template(inputs)
  totals
}

# The smallest total n allowed: at least 3 people per between-participants
# group (cell), and Superpower's equal cells.
whole_study_experiment_min_n <- function(inputs) inputs$superpower$groups * 3

run_whole_study_experiment <- function(spec) {
  seed <- spec$options$seed %||% sample.int(2147483646L, 1)
  nrep <- spec$options$nrep %||% 1000L
  inputs <- whole_study_experiment_inputs(spec)
  sp <- inputs$superpower
  started <- Sys.time()
  cores <- powerkit_cores()
  step <- if (!is.null(sp$cell_ratio)) cell_ratio_step(sp$cell_ratio) else sp$groups

  # The data Superpower builds reproduce the means, SDs and correlations
  # entered (ANOVA_exact()'s data set, as for the card).
  check <- superpower_check_run(inputs$spec, whole_study_experiment_design(inputs, sp$groups * 50, seed), seed)
  if (!all(check$ok)) {
    abort_run(paste0(
      "powerkit's translation of this experiment to Superpower did not reproduce the population you specified (",
      paste(check$parameter[!check$ok], collapse = "; "),
      "). This is a bug in powerkit, not in your spec; please report it."
    ))
  }
  n <- spec$goal$n
  if (!is.null(n) && n %% step != 0) {
    abort_spec(sprintf("The total n (%s) has to split into equal groups: use a multiple of %s.", n, step))
  }
  if (!is.null(n) && n < whole_study_experiment_min_n(inputs)) {
    abort_spec(sprintf("The total n has to give at least 3 people per group: %s or more.", whole_study_experiment_min_n(inputs)))
  }
  search <- NULL
  if (identical(spec$goal$type, "sample_size")) {
    criterion <- whole_study_criterion(spec, inputs)
    backend <- list(
      n_step = step,
      exact_min_n = whole_study_experiment_min_n(inputs),
      simulate = function(n, nrep, seed, cores) {
        counts <- criterion$counts(whole_study_experiment_counts(inputs, n, nrep, seed, cores))
        list(rejections = unname(counts[[1]]), nrep = unname(counts[[2]]), attempted = nrep, valid = unname(counts[[2]]))
      }
    )
    search <- c(list(target = spec$goal$power, rule = criterion$rule, criterion = criterion$description),
      search_n(spec, backend, spec$goal$power, nrep, seed, cores))
    n <- search$n_required$n
  }
  totals <- whole_study_experiment_counts(inputs, n, nrep, seed, cores)
  rate <- function(rejections, valid) whole_study_rate(rejections, valid, nrep)
  per_analysis <- do.call(rbind, lapply(inputs$analyses, function(a) {
    r <- rate(totals[[paste0(a$id, ":sig")]], totals[[paste0(a$id, ":valid")]])
    data.frame(id = a$id, label = a$label, role = a$role, test = a$test, alpha = a$alpha, as.list(r))
  }))
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
      implied = whole_study_experiment_implied(inputs, n),
      check_run = check,
      models = list(population = sp$design,
        population_values = sprintf("Cell means (Superpower's order, a1_b1, a1_b2, ...): %s; SD: %s%s",
          paste(format(sp$mu), collapse = ", "), paste(format(sp$sd), collapse = ", "),
          if (grepl("w", sp$design)) sprintf("; correlation: %s", paste(format(sp$r), collapse = ", ")) else ""),
        analyses = vapply(inputs$analyses, function(a) sprintf("ANOVA F test of %s", a$term), character(1))),
      provenance = list(
        spec_hash = spec_hash(spec),
        method = "simulation",
        seed = seed,
        nrep = nrep,
        ci_draws = NA_integer_,
        cores = cores,
        batch_size = 250L,
        backend = "Superpower",
        backend_function = "Superpower::ANOVA_power (every F test read from the same simulated data sets, sim_data)",
        r_version = R.version.string,
        packages = package_versions(c("powerkit", "Superpower", "afex")),
        started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
        run_time_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
      )
    ),
    class = "powerkit_whole_study_result"
  )
}

# What the population implies for each analysis, as its card would report
# it: Superpower's Cohen's f for each F test, and its exact power at n
# at the whole study's alpha (ANOVA_exact(), equal cells only), the
# power its own card gives. The shape matches whole_study_implied().
whole_study_experiment_implied <- function(inputs, n) {
  sp <- inputs$superpower
  if (!is.null(sp$cell_ratio)) return(NULL)
  exact <- tryCatch(call_backend("Superpower", with_seed(1L, Superpower::ANOVA_exact(
    whole_study_experiment_design(inputs, n, 1L), alpha_level = sp$alpha, correction = sp$correction %||% "none", verbose = FALSE
  )))$main_results, error = function(e) NULL)
  if (is.null(exact)) return(NULL)
  lapply(inputs$analyses, function(a) {
    row <- sub("^anova_", "", experiment_p_column(paste0("anova_", rownames(exact)), a$term))
    list(id = a$id, values = list(cohen_f = exact[row, "cohen_f"], power_alone = exact[row, "power"] / 100))
  })
}
