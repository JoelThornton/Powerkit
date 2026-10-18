# Backend adapter: 2x2 between, 2x2 mixed and one-way between ANOVA via
# Superpower.
#
# By default power is computed exactly with Superpower::ANOVA_exact(), which
# is exact for the specified population and matches G*Power and the
# published values. Simulation with Superpower::ANOVA_power() is available
# on request (options > method = "simulation"). ANOVA_exact2() is not used:
# for mixed designs it gives a different answer from G*Power, ANOVA_exact()
# and simulation (see docs/decisions.md).

superpower_backend <- function(spec, seed = NULL) {
  inputs <- superpower_inputs(spec)
  # ANOVA_exact() needs more participants per cell than there are cells.
  exact_min_n <- 5 * inputs$groups
  # ANOVA_design() draws random numbers; it runs under the run's seed so it
  # leaves the caller's random-number state alone. Its draws don't affect
  # ANOVA_exact(), which is seeded again (see superpower_exact()).
  design_at <- function(n, mu = inputs$mu) {
    call_backend("Superpower", with_seed(seed, Superpower::ANOVA_design(
      design = inputs$design,
      n = n / inputs$groups,
      mu = mu,
      sd = inputs$sd,
      r = inputs$r,
      plot = FALSE
    )))
  }
  exact_at <- function(n, mu = inputs$mu) {
    if (n < exact_min_n) {
      abort_run(sprintf(
        "Exact power for this design needs at least %d participants (5 per %s); for n = %s, set 'options > method' to 'simulation'.",
        exact_min_n, if (spec$template == "2x2_between") "cell" else "group", n
      ))
    }
    superpower_exact(design_at(n, mu), inputs, seed)
  }
  list(
    name = "Superpower",
    packages = c("Superpower", "afex"),
    methods = c("exact", "simulation"),
    default_method = "exact",
    functions = c(exact = "Superpower::ANOVA_exact", simulation = "Superpower::ANOVA_power"),
    n_step = inputs$groups,
    exact_min_n = exact_min_n,
    exact_power = function(n) exact_at(n)$power,
    bracket_power = function(n) exact_at(n)$power,
    simulate = function(n, nrep, seed, cores) {
      superpower_simulate(design_at(n), inputs, nrep, seed, cores)
    },
    # Sensitivity for the one-way design (which effect pattern to scale)
    # is not settled yet; it is available for the 2x2 designs.
    sensitivity = if (spec$template == "oneway_between") NULL else function(n, power) {
      superpower_sensitivity(spec, inputs, exact_at, n, power)
    },
    check_run = function() {
      superpower_check_run(spec, design_at(50 * inputs$groups), seed)
    }
  )
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
    return(list(
      design = paste0(k, "b"),
      groups = k,
      mu = as.numeric(unlist(pop$means)),
      sd = pop$sd,
      r = 0,
      alpha = spec$target_test$alpha,
      effect = "a"
    ))
  }
  by_row <- function(x) as.numeric(unlist(x))
  between <- spec$template == "2x2_between"
  list(
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

# Rejections out of nrep, one seeded ANOVA_power() call per core. With one
# core this is exactly ANOVA_power(design, nsims = nrep, seed = seed).
superpower_simulate <- function(design, inputs, nrep, seed, cores) {
  simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) {
    result <- call_backend("Superpower", Superpower::ANOVA_power(
      design,
      alpha_level = inputs$alpha,
      nsims = k,
      seed = chunk_seed,
      verbose = FALSE
    ))
    power <- result$main_results[paste0("anova_", inputs$effect), "power"]
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
    Superpower::ANOVA_exact(design, alpha_level = inputs$alpha, verbose = FALSE)
  ))
  row <- result$main_results[inputs$effect, ]
  list(power = row$power / 100, cohen_f = row$cohen_f)
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
  if (spec$template == "oneway_between") {
    return(superpower_check_oneway(spec, data))
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

# Check run for the one-way design: each group's mean and SD in the data
# set Superpower builds, matched by its level labels (a1, a2, ...).
superpower_check_oneway <- function(spec, data) {
  means <- as.numeric(unlist(spec$population$means))
  group <- as.integer(sub("^.*a", "", as.character(data$a)))
  rows <- lapply(seq_along(means), function(i) {
    y <- data$y[group == i]
    data.frame(
      parameter = c(sprintf("mean, group %d", i), sprintf("SD, group %d", i)),
      specified = c(means[i], spec$population$sd),
      recovered = c(mean(y), stats::sd(y))
    )
  })
  check <- do.call(rbind, rows)
  check$ok <- abs(check$recovered - check$specified) <= 1e-6 * pmax(1, abs(check$specified))
  check
}
