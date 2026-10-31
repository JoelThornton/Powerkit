# Backend adapter: 2x2 between, 2x2 mixed, larger mixed (between x within),
# two-factor between (beyond 2x2) and two-factor within, three-factor (any
# mix of between and within), one-way between and one-way within
# (repeated-measures) ANOVA via Superpower.
#
# By default power is computed exactly with Superpower::ANOVA_exact(), which
# is exact for the specified population and matches G*Power and the
# published values. Simulation with Superpower::ANOVA_power() is available
# on request (options > method = "simulation"). ANOVA_exact2() is not used:
# for mixed designs it gives a different answer from G*Power, ANOVA_exact()
# and simulation (see docs/decisions.md).

superpower_backend <- function(spec, seed = NULL) {
  inputs <- superpower_inputs(spec)
  # ANOVA_exact() needs more participants in each between-participants
  # group than there are cells in the design ("n <= the product of the
  # factors" is refused); powerkit asks for at least 5.
  per_group <- max(5, length(inputs$mu) + 1)
  exact_min_n <- per_group * inputs$groups
  # ANOVA_design() draws random numbers; it runs under the run's seed so it
  # leaves the caller's random-number state alone. Its draws don't affect
  # ANOVA_exact(), which is seeded again (see superpower_exact()).
  design_at <- function(n, mu = inputs$mu, cells = superpower_cell_n(inputs, n)) {
    call_backend("Superpower", with_seed(seed, Superpower::ANOVA_design(
      design = inputs$design,
      n = cells,
      mu = mu,
      sd = inputs$sd,
      r = inputs$r,
      plot = FALSE
    )))
  }
  exact_at <- function(n, mu = inputs$mu) {
    if (n < exact_min_n) {
      abort_run(sprintf(
        "Exact power for this design needs at least %d participants%s; for n = %s, set 'options > method' to 'simulation'.",
        exact_min_n,
        if (inputs$groups == 1) "" else sprintf(
          " (%d per %s)", per_group, if (spec$template %in% c("2x2_between", "factorial_between") ||
            (spec$template == "factorial_three" && !any(three_factor_within(spec)))) "cell" else "group"
        ),
        n
      ))
    }
    superpower_exact(design_at(n, mu), inputs, seed)
  }
  # Unequal cells: ANOVA_exact() takes equal cells only, so they are
  # simulated (unequal_cells()).
  # So are pairwise comparisons: ANOVA_exact() doesn't adjust p-values.
  unequal <- !is.null(inputs$cell_ratio)
  simulated_only <- unequal || !is.null(inputs$pairwise_row)
  list(
    name = "Superpower",
    packages = c("Superpower", "afex"),
    methods = if (simulated_only) "simulation" else c("exact", "simulation"),
    default_method = if (simulated_only) "simulation" else "exact",
    functions = c(exact = "Superpower::ANOVA_exact", simulation = if (is.null(inputs$pairwise_row)) {
      "Superpower::ANOVA_power"
    } else {
      sprintf("Superpower::ANOVA_power (pairwise t-tests, p_adjust = \"%s\")", inputs$p_adjust)
    }),
    # Unequal cells: the smallest total that splits into whole cells in the
    # ratio given (6 for 2 : 2 : 1 : 1), so every n searched is valid.
    n_step = if (unequal) cell_ratio_step(inputs$cell_ratio) else inputs$groups,
    exact_min_n = exact_min_n,
    exact_power = if (simulated_only) NULL else function(n) exact_at(n)$power,
    bracket_power = if (simulated_only) NULL else function(n) exact_at(n)$power,
    manova_power = function(n) exact_at(n)$manova_power,
    details = function(n) exact_at(n)$details,
    simulate = function(n, nrep, seed, cores) {
      superpower_simulate(design_at(n), inputs, nrep, seed, cores)
    },
    # Sensitivity for the one-way designs (which effect pattern to scale)
    # is not settled yet; it is available for the 2x2 designs.
    sensitivity = if (spec$template %in% c("oneway_between", "oneway_within", "mixed", "factorial_between", "factorial_within", "factorial_three")) NULL else function(n, power) {
      superpower_sensitivity(spec, inputs, exact_at, n, power)
    },
    # The check reads the cell means and SDs back from ANOVA_exact()'s data
    # set, which needs equal cells; the cell sizes don't change them.
    check_run = function() {
      superpower_check_run(spec, design_at(50 * inputs$groups, cells = 50), seed)
    }
  )
}

cell_ratio_step <- function(ratio) {
  whole <- function(x) all(abs(x - round(x)) < 1e-9)
  for (n in seq_len(10000)) if (whole(n * ratio / sum(ratio))) return(n)
  length(ratio)
}

# Superpower's n: the number in each between-participants group, one
# number for equal groups or one per cell (options > cell_ratio).
superpower_cell_n <- function(inputs, n) {
  if (is.null(inputs$cell_ratio)) {
    return(n / inputs$groups)
  }
  n * inputs$cell_ratio / sum(inputs$cell_ratio)
}

# Translate a validated 2x2 spec into Superpower's terms. Superpower orders
# cells a1_b1, a1_b2, a2_b1, a2_b2; the spec's 2x2 arrays have rows = levels
# of A and columns = levels of B, so the arrays are read row by row.
superpower_inputs <- function(spec) {
  pop <- spec$population
  if (spec$template == "oneway_between") {
    # One between-participants factor with k levels: Superpower's design
    # "kb" (for example "3b"), one mean per group, equal SDs.
    k <- length(spec$variables$A$levels)
    return(c(list(
      design = paste0(k, "b"),
      groups = k,
      mu = as.numeric(unlist(pop$means)),
      sd = pop$sd,
      r = 0,
      alpha = spec$target_test$alpha,
      effect = "a"
    ), superpower_pairwise(spec)))
  }
  if (spec$template == "oneway_within") {
    # One within-participants factor with k levels: Superpower's design
    # "kw" (for example "3w"). Everyone is in every condition, so there is
    # one group. One SD and one correlation for every pair of conditions
    # (compound symmetry) keep sphericity; an SD per condition and a
    # correlation per pair (the upper triangle, row by row, as
    # ANOVA_design() takes it) need not, and the F test can then be
    # corrected (target_test > correction, Superpower's `correction`).
    k <- length(spec$variables$A$levels)
    return(c(list(
      design = paste0(k, "w"),
      groups = 1,
      mu = as.numeric(unlist(pop$means)),
      sd = as.numeric(unlist(pop$sd)),
      r = as.numeric(unlist(pop$r)),
      alpha = spec$target_test$alpha,
      effect = "a",
      correction = spec$target_test$correction %||% "none"
    ), superpower_pairwise(spec)))
  }
  by_row <- function(x) as.numeric(unlist(x))
  if (spec$template == "mixed") {
    # One between factor with k levels by one within factor with m levels:
    # Superpower's design "kb*mw" (for example "2b*3w"). Cells are read row
    # by row (a1_b1, a1_b2, ..., a2_b1, ...), Superpower's order. One SD and
    # one correlation between every pair of B's levels, so sphericity holds.
    k <- length(spec$variables$A$levels)
    m <- length(spec$variables$B$levels)
    return(list(
      design = sprintf("%db*%dw", k, m),
      groups = k,
      mu = by_row(pop$means),
      sd = pop$sd,
      r = pop$r,
      alpha = spec$target_test$alpha,
      effect = c(main_effect_A = "a", main_effect_B = "b", interaction = "a:b")[[spec$target_test$effect]]
    ))
  }
  if (spec$template %in% c("factorial_between", "factorial_within")) {
    # Two crossed factors, both between participants (design "kb*mb", one
    # group of different people per cell) or both within (design "kw*mw",
    # everyone in every cell). Cells are read row by row (a1_b1, a1_b2,
    # ..., a2_b1, ...), Superpower's order. One SD; for the within design
    # one correlation between every pair of cells, so sphericity holds.
    k <- length(spec$variables$A$levels)
    m <- length(spec$variables$B$levels)
    between <- spec$template == "factorial_between"
    return(list(
      design = sprintf(if (between) "%db*%db" else "%dw*%dw", k, m),
      groups = if (between) k * m else 1,
      mu = by_row(pop$means),
      sd = pop$sd,
      r = if (between) 0 else pop$r,
      alpha = spec$target_test$alpha,
      effect = c(main_effect_A = "a", main_effect_B = "b", interaction = "a:b")[[spec$target_test$effect]]
    ))
  }
  if (spec$template == "factorial_three") {
    return(three_factor_inputs(spec))
  }
  between <- spec$template == "2x2_between"
  list(
    # Relative cell sizes (options > cell_ratio), in Superpower's order;
    # NULL for equal cells.
    cell_ratio = if (unequal_cells(spec)) cell_ratio_vector(spec),
    design = if (between) "2b*2b" else "2b*2w",
    # Superpower's n is per between-participants cell: four cells in a 2x2
    # between design, two groups in a 2x2 mixed design.
    groups = if (between) 4 else 2,
    mu = by_row(pop$means),
    sd = by_row(pop$sd),
    r = if (between) 0 else pop$r,
    alpha = spec$target_test$alpha,
    effect = c(main_effect_A = "a", main_effect_B = "b", interaction = "a:b")[[spec$target_test$effect]]
  )
}

# Pairwise comparisons (pairwise_comparison()): the row of ANOVA_power()'s
# pc_results for the chosen pair, and the adjustment. Superpower names the
# levels of a design built without labels a1, a2, ..., so the pair of
# levels i < j is row "p_a_ai_a_aj". NULL otherwise.
superpower_pairwise <- function(spec) {
  if (!pairwise_comparison(spec)) {
    return(NULL)
  }
  pair <- pairwise_levels(spec)
  list(pairwise_row = sprintf("p_a_a%d_a_a%d", pair[1], pair[2]), p_adjust = spec$target_test$p_adjust %||% "holm")
}

# Rejections out of nrep, one seeded ANOVA_power() call per core. With one
# core this is exactly ANOVA_power(design, nsims = nrep, seed = seed).
# For a pairwise comparison, the chosen pair's power, with the p-values of
# all the pairwise t-tests adjusted (p_adjust).
superpower_simulate <- function(design, inputs, nrep, seed, cores) {
  simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) {
    result <- call_backend("Superpower", Superpower::ANOVA_power(
      design,
      alpha_level = inputs$alpha,
      correction = inputs$correction %||% "none",
      p_adjust = inputs$p_adjust %||% "none",
      nsims = k,
      seed = chunk_seed,
      verbose = FALSE
    ))
    power <- if (is.null(inputs$pairwise_row)) {
      result$main_results[paste0("anova_", inputs$effect), "power"]
    } else {
      result$pc_results[inputs$pairwise_row, "power"]
    }
    round(power / 100 * k)
  })
}

# Exact power for the target effect, and Superpower's Cohen's f for it.
# ANOVA_exact() builds its data set with the random-number generator, so
# repeated calls differ around the 15th decimal place; running it under the
# run's seed makes exact results reproducible bit for bit.
superpower_exact <- function(design, inputs, seed = NULL) {
  # Build the design before seeding: ANOVA_design() draws random numbers
  # too, so building it lazily inside with_seed() would start
  # ANOVA_exact() from a different RNG state than a direct call
  # (design first, then set.seed(), then ANOVA_exact()).
  force(design)
  result <- call_backend("Superpower", with_seed(
    seed,
    Superpower::ANOVA_exact(design, alpha_level = inputs$alpha, correction = inputs$correction %||% "none", verbose = FALSE)
  ))
  row <- result$main_results[inputs$effect, ]
  # The MANOVA approach (Pillai's trace), which doesn't assume sphericity:
  # ANOVA_exact() reports it for designs with a within factor.
  manova <- result$manova_results
  manova_power <- if (!is.null(manova) && inputs$effect %in% rownames(manova)) manova[inputs$effect, "power"] / 100 else NA_real_
  list(
    power = row$power / 100, cohen_f = row$cohen_f, manova_power = manova_power,
    details = superpower_details(result, inputs, row)
  )
}

# The F test's details from ANOVA_exact()'s output: its degrees of freedom
# (the ANOVA table) and noncentrality (main_results). Superpower doesn't
# return the critical F, so it is stats::qf() at those df; the details are
# given only if they reproduce Superpower's power.
superpower_details <- function(result, inputs, row) {
  table <- result$aov_result$anova_table
  if (is.null(table) || !inputs$effect %in% rownames(table)) {
    return(NULL)
  }
  df <- as.numeric(table[inputs$effect, c("num Df", "den Df")])
  critical <- stats::qf(1 - inputs$alpha, df[1], df[2])
  power <- stats::pf(critical, df[1], df[2], ncp = row$non_centrality, lower.tail = FALSE)
  if (!isTRUE(abs(power - row$power / 100) < 1e-4)) {
    return(NULL)
  }
  list(
    statistic = "F", df = df, critical = critical, ncp = row$non_centrality,
    actual_alpha = NA_real_, source = "Superpower::ANOVA_exact (critical F: stats::qf)"
  )
}

# Whether the MANOVA approach differs from the univariate F for the target
# effect: it involves a within factor with three or more levels (with two,
# sphericity can't fail and the two tests agree).
manova_applies <- function(spec) {
  if (!identical(spec$design, "factorial_anova")) {
    return(FALSE)
  }
  effect <- spec$target_test$effect %||% ""
  factors <- if (identical(effect, "interaction")) {
    c("A", "B")
  } else if (startsWith(effect, "main_effect_")) {
    sub("^main_effect_", "", effect)
  } else if (startsWith(effect, "interaction_")) {
    strsplit(sub("^interaction_", "", effect), "")[[1]]
  } else {
    character()
  }
  any(vapply(factors, function(f) {
    v <- spec$variables[[f]]
    identical(v$type, "within_factor") && length(v$levels) >= 3
  }, logical(1)))
}

#' The MANOVA approach to a repeated-measures effect
#'
#' For a factorial ANOVA whose target effect involves a within-participants
#' factor with three or more levels, computed exactly: the power of the
#' MANOVA approach (Pillai's trace), which doesn't assume sphericity, from
#' the same `Superpower::ANOVA_exact()` run as the univariate F.
#'
#' @param spec A validated spec.
#' @param backend The backend [run_spec()] used.
#' @param method The method used ("exact" or "simulation").
#' @param n The total number of participants analysed.
#'
#' @return `NULL` when it doesn't apply; otherwise a list with `power` (the
#'   MANOVA approach's power at `n`) and `n`.
#' @keywords internal
manova_summary <- function(spec, backend, method, n) {
  if (!identical(method, "exact") || is.null(backend$manova_power) || !manova_applies(spec) || is.null(n) || is.na(n)) {
    return(NULL)
  }
  power <- backend$manova_power(n)
  if (is.na(power)) {
    return(NULL)
  }
  list(power = power, n = n)
}

# Sensitivity: keep the shape of the specified pattern of cell means and
# scale its size (each cell mean's deviation from the grand mean) until the
# target effect reaches the target power at n. Scale 1 is the pattern as
# specified; scale 0 has all means equal, where power equals alpha.
superpower_sensitivity <- function(spec, inputs, exact_at, n, target) {
  grand_mean <- mean(inputs$mu)
  mu_at <- function(scale) grand_mean + scale * (inputs$mu - grand_mean)
  power_at <- function(scale) exact_at(n, mu_at(scale))$power
  upper <- 1
  while (power_at(upper) < target) {
    upper <- upper * 2
    if (upper > 1e4) {
      abort_run("No effect of this shape reaches the target power at this n. Check the population values.")
    }
  }
  scale <- stats::uniroot(
    function(k) power_at(k) - target,
    lower = 0, upper = upper, tol = 1e-10
  )$root
  at_scale <- exact_at(n, mu_at(scale))
  means <- matrix(mu_at(scale), nrow = 2, byrow = TRUE)
  contrast <- anova_effect_in_units(spec, means)
  list(
    scale = scale,
    means = means,
    effect = contrast$value,
    effect_description = contrast$description,
    cohen_f = at_scale$cohen_f,
    power = at_scale$power
  )
}

# The target effect in the user's units, from a 2x2 matrix of cell means
# (rows = levels of A, columns = levels of B).
anova_effect_in_units <- function(spec, means) {
  a <- spec$variables$A
  b <- spec$variables$B
  switch(
    spec$target_test$effect,
    main_effect_A = list(
      value = mean(means[1, ]) - mean(means[2, ]),
      description = sprintf(
        "difference in mean %s between %s and %s (%s), averaged over %s",
        spec$variables$Y$label, a$levels[[1]], a$levels[[2]], a$label, b$label
      )
    ),
    main_effect_B = list(
      value = mean(means[, 1]) - mean(means[, 2]),
      description = sprintf(
        "difference in mean %s between %s and %s (%s), averaged over %s",
        spec$variables$Y$label, b$levels[[1]], b$levels[[2]], b$label, a$label
      )
    ),
    interaction = list(
      value = (means[1, 1] - means[1, 2]) - (means[2, 1] - means[2, 2]),
      description = sprintf(
        "difference in the %s effect (%s minus %s) between %s and %s (%s)",
        b$label, b$levels[[1]], b$levels[[2]], a$levels[[1]], a$levels[[2]], a$label
      )
    )
  )
}

# Check that Superpower's version of the population has the spec's cell
# means, SDs and (mixed designs) repeated-measures correlation, read back
# from the data set Superpower builds with exactly those properties. Cells
# are matched by Superpower's factor labels, so a cell put in the wrong
# place by the translation shows up as a mismatch.
superpower_check_run <- function(spec, design, seed = NULL) {
  force(design)
  data <- call_backend(
    "Superpower",
    with_seed(seed, Superpower::ANOVA_exact(design, verbose = FALSE))
  )$dataframe
  if (spec$template %in% c("oneway_between", "oneway_within")) {
    return(superpower_check_oneway(spec, data))
  }
  if (spec$template %in% c("mixed", "factorial_between", "factorial_within")) {
    return(superpower_check_mixed(spec, data))
  }
  if (spec$template == "factorial_three") {
    return(superpower_check_three(spec, data))
  }
  level <- function(x) as.integer(sub(".*(\\d)$", "\\1", as.character(x)))
  data$i <- level(data$a)
  data$j <- level(data$b)
  means <- matrix(as.numeric(unlist(spec$population$means)), nrow = 2, byrow = TRUE)
  sds <- matrix(as.numeric(unlist(spec$population$sd)), nrow = 2, ncol = 2, byrow = TRUE)
  cells <- expand.grid(i = 1:2, j = 1:2)
  rows <- lapply(seq_len(nrow(cells)), function(k) {
    i <- cells$i[k]
    j <- cells$j[k]
    y <- data$y[data$i == i & data$j == j]
    data.frame(
      parameter = c(sprintf("mean, A%d B%d", i, j), sprintf("SD, A%d B%d", i, j)),
      specified = c(means[i, j], sds[i, j]),
      recovered = c(mean(y), stats::sd(y))
    )
  })
  if (spec$template == "2x2_mixed") {
    rows <- c(rows, lapply(1:2, function(i) {
      group <- data[data$i == i, ]
      group <- group[order(group$subject), ]
      data.frame(
        parameter = sprintf("r between B1 and B2, A%d", i),
        specified = spec$population$r,
        recovered = stats::cor(group$y[group$j == 1], group$y[group$j == 2])
      )
    }))
  }
  check <- do.call(rbind, rows)
  check$ok <- abs(check$recovered - check$specified) <= 1e-6 * pmax(1, abs(check$specified))
  check
}

# Check run for the one-way designs: each group's (or condition's) mean
# and SD in the data set Superpower builds, matched by its level labels (a1,
# a2, ...), and for repeated measures the correlation between every pair of
# conditions, with participants matched by Superpower's subject label.
superpower_check_oneway <- function(spec, data) {
  means <- as.numeric(unlist(spec$population$means))
  sds <- rep_len(as.numeric(unlist(spec$population$sd)), length(means))
  group <- as.integer(sub("^.*a", "", as.character(data$a)))
  unit <- if (spec$template == "oneway_within") "condition" else "group"
  rows <- lapply(seq_along(means), function(i) {
    y <- data$y[group == i]
    data.frame(
      parameter = c(sprintf("mean, %s %d", unit, i), sprintf("SD, %s %d", unit, i)),
      specified = c(means[i], sds[i]),
      recovered = c(mean(y), stats::sd(y))
    )
  })
  if (spec$template == "oneway_within") {
    by_level <- lapply(seq_along(means), function(i) {
      level <- data[group == i, ]
      level$y[order(level$subject)]
    })
    pairs <- utils::combn(seq_along(means), 2)
    rs <- rep_len(as.numeric(unlist(spec$population$r)), ncol(pairs))
    rows <- c(rows, lapply(seq_len(ncol(pairs)), function(k) {
      i <- pairs[1, k]
      j <- pairs[2, k]
      data.frame(
        parameter = sprintf("r between conditions %d and %d", i, j),
        specified = rs[k],
        recovered = stats::cor(by_level[[i]], by_level[[j]])
      )
    }))
  }
  check <- do.call(rbind, rows)
  check$ok <- abs(check$recovered - check$specified) <= 1e-6 * pmax(1, abs(check$specified))
  check
}

# Check run for the larger two-factor designs: every cell's mean and SD,
# and the correlations between repeated measurements, with participants
# matched by Superpower's subject label: in the mixed design, within each
# between-participants group, between every pair of the within factor's
# levels; in the within design, between every pair of cells. Levels are
# matched by Superpower's labels (a1, b2, ...).
superpower_check_mixed <- function(spec, data) {
  means <- lapply(spec$population$means, function(row) as.numeric(unlist(row)))
  k <- length(means)
  m <- length(means[[1]])
  level <- function(x) as.integer(sub("^.*[a-z]", "", as.character(x)))
  data$i <- level(data$a)
  data$j <- level(data$b)
  cells <- expand.grid(j = seq_len(m), i = seq_len(k))
  rows <- lapply(seq_len(nrow(cells)), function(c) {
    i <- cells$i[c]
    j <- cells$j[c]
    y <- data$y[data$i == i & data$j == j]
    data.frame(
      parameter = c(sprintf("mean, A%d B%d", i, j), sprintf("SD, A%d B%d", i, j)),
      specified = c(means[[i]][j], spec$population$sd),
      recovered = c(mean(y), stats::sd(y))
    )
  })
  if (spec$template == "factorial_within") {
    by_cell <- lapply(seq_len(nrow(cells)), function(c) {
      cell <- data[data$i == cells$i[c] & data$j == cells$j[c], ]
      cell$y[order(cell$subject)]
    })
    cell_pairs <- utils::combn(seq_len(nrow(cells)), 2)
    rows <- c(rows, lapply(seq_len(ncol(cell_pairs)), function(p) {
      a <- cell_pairs[1, p]
      b <- cell_pairs[2, p]
      data.frame(
        parameter = sprintf("r between A%d B%d and A%d B%d", cells$i[a], cells$j[a], cells$i[b], cells$j[b]),
        specified = spec$population$r,
        recovered = stats::cor(by_cell[[a]], by_cell[[b]])
      )
    }))
  }
  pairs <- if (spec$template == "mixed") utils::combn(seq_len(m), 2) else matrix(integer(), 2, 0)
  for (i in seq_len(k)) {
    group <- data[data$i == i, ]
    by_level <- lapply(seq_len(m), function(j) {
      cell <- group[group$j == j, ]
      cell$y[order(cell$subject)]
    })
    rows <- c(rows, lapply(seq_len(ncol(pairs)), function(p) {
      data.frame(
        parameter = sprintf("r between B%d and B%d, A%d", pairs[1, p], pairs[2, p], i),
        specified = spec$population$r,
        recovered = stats::cor(by_level[[pairs[1, p]]], by_level[[pairs[2, p]]])
      )
    }))
  }
  check <- do.call(rbind, rows)
  check$ok <- abs(check$recovered - check$specified) <= 1e-6 * pmax(1, abs(check$specified))
  check
}

# Three crossed factors A, B and C, each between or within participants:
# Superpower's design "kb*mw*lb" and the like (for example "2b*2w*3w").
# Cells are read with A slowest and C fastest (a1_b1_c1, a1_b1_c2, ...),
# Superpower's order. Superpower's n is per between-participants group: the
# number of combinations of the between factors' levels (1 with no between
# factor). One SD; with a within factor, one correlation between every pair
# of a participant's cells, so sphericity holds.
three_factor_inputs <- function(spec) {
  roles <- c("A", "B", "C")
  levels <- vapply(roles, function(v) length(spec$variables[[v]]$levels), integer(1))
  within <- three_factor_within(spec)
  effect <- c(
    main_effect_A = "a", main_effect_B = "b", main_effect_C = "c",
    interaction_AB = "a:b", interaction_AC = "a:c", interaction_BC = "b:c",
    interaction_ABC = "a:b:c"
  )[[spec$target_test$effect]]
  list(
    design = paste0(levels, ifelse(within, "w", "b"), collapse = "*"),
    groups = as.integer(prod(levels[!within])),
    mu = as.numeric(unlist(spec$population$means)),
    sd = spec$population$sd,
    r = if (any(within)) spec$population$r else 0,
    alpha = spec$target_test$alpha,
    effect = effect
  )
}

# Which of A, B and C are within participants.
three_factor_within <- function(spec) {
  vapply(c("A", "B", "C"), function(v) identical(spec$variables[[v]]$type, "within_factor"), logical(1))
}

# Check run for three factors: every cell's mean and SD, and, with a within
# factor, the correlation between every pair of cells a participant is
# measured in (within each combination of the between factors' levels),
# with participants matched by Superpower's subject label and levels by
# its labels (a1, b2, c3, ...).
superpower_check_three <- function(spec, data) {
  roles <- c("A", "B", "C")
  levels <- vapply(roles, function(v) length(spec$variables[[v]]$levels), integer(1))
  within <- three_factor_within(spec)
  means <- array(as.numeric(unlist(spec$population$means)), dim = rev(levels))
  level <- function(x) as.integer(sub("^.*[a-z]", "", as.character(x)))
  data$i <- level(data$a)
  data$j <- level(data$b)
  data$l <- level(data$c)
  cells <- expand.grid(l = seq_len(levels[3]), j = seq_len(levels[2]), i = seq_len(levels[1]))
  label <- function(c) sprintf("A%d B%d C%d", cells$i[c], cells$j[c], cells$l[c])
  in_cell <- function(c) data$i == cells$i[c] & data$j == cells$j[c] & data$l == cells$l[c]
  rows <- lapply(seq_len(nrow(cells)), function(c) {
    y <- data$y[in_cell(c)]
    data.frame(
      parameter = c(paste("mean,", label(c)), paste("SD,", label(c))),
      specified = c(means[cells$l[c], cells$j[c], cells$i[c]], spec$population$sd),
      recovered = c(mean(y), stats::sd(y))
    )
  })
  if (any(within)) {
    # Cells share participants when they agree on every between factor.
    between_key <- do.call(paste, c(list(sep = "_"), cells[c("i", "j", "l")[!within]]))
    if (all(within)) between_key <- rep("all", nrow(cells))
    for (key in unique(between_key)) {
      group <- which(between_key == key)
      by_cell <- lapply(group, function(c) {
        cell <- data[in_cell(c), ]
        cell$y[order(cell$subject)]
      })
      pairs <- utils::combn(seq_along(group), 2)
      rows <- c(rows, lapply(seq_len(ncol(pairs)), function(p) {
        a <- pairs[1, p]
        b <- pairs[2, p]
        data.frame(
          parameter = sprintf("r between %s and %s", label(group[a]), label(group[b])),
          specified = spec$population$r,
          recovered = stats::cor(by_cell[[a]], by_cell[[b]])
        )
      }))
    }
  }
  check <- do.call(rbind, rows)
  check$ok <- abs(check$recovered - check$specified) <= 1e-6 * pmax(1, abs(check$specified))
  check
}
