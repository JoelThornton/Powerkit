# Backend adapter: 2x2 between and 2x2 mixed ANOVA via Superpower.
#
# Power is estimated by simulation with Superpower::ANOVA_power(). Superpower's
# exact method, ANOVA_exact(), is used only to bracket the sample size quickly
# and to run the check run (see docs/decisions.md). ANOVA_exact2() is not
# used: for mixed designs it gives a different answer from G*Power,
# ANOVA_exact() and simulation.

superpower_backend <- function(spec) {
  inputs <- superpower_inputs(spec)
  design_at <- function(n) {
    call_backend("Superpower", Superpower::ANOVA_design(
      design = inputs$design,
      n = n / inputs$groups,
      mu = inputs$mu,
      sd = inputs$sd,
      r = inputs$r,
      plot = FALSE
    ))
  }
  list(
    name = "Superpower",
    simulation_function = "Superpower::ANOVA_power",
    packages = c("Superpower", "afex"),
    n_step = inputs$groups,
    # ANOVA_exact() needs more participants per cell than there are cells.
    approximate_min_n = 5 * inputs$groups,
    simulate = function(n, nrep, seed, cores) {
      superpower_simulate(design_at(n), inputs, nrep, seed, cores)
    },
    approximate_power = function(n) {
      superpower_exact_power(design_at(n), inputs)
    },
    check_run = function() {
      superpower_check_run(spec, design_at(50 * inputs$groups))
    }
  )
}

# Translate a validated 2x2 spec into Superpower's terms. Superpower orders
# cells a1_b1, a1_b2, a2_b1, a2_b2; the spec's 2x2 arrays have rows = levels
# of A and columns = levels of B, so the arrays are read row by row.
superpower_inputs <- function(spec) {
  pop <- spec$population
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

# Rejections out of nrep, splitting the replications into one seeded
# ANOVA_power() call per core. With one core this is exactly
# ANOVA_power(design, nsims = nrep, seed = seed).
superpower_simulate <- function(design, inputs, nrep, seed, cores) {
  chunks <- split_replications(nrep, cores)
  seeds <- offset_seed(seed, seq_along(chunks) - 1)
  run_chunk <- function(i) {
    result <- call_backend("Superpower", Superpower::ANOVA_power(
      design,
      alpha_level = inputs$alpha,
      nsims = chunks[i],
      seed = seeds[i],
      verbose = FALSE
    ))
    power <- result$main_results[paste0("anova_", inputs$effect), "power"]
    round(power / 100 * chunks[i])
  }
  rejections <- run_in_parallel(seq_along(chunks), run_chunk, cores)
  list(rejections = sum(rejections), nrep = nrep)
}

superpower_exact_power <- function(design, inputs) {
  result <- call_backend(
    "Superpower",
    Superpower::ANOVA_exact(design, alpha_level = inputs$alpha, verbose = FALSE)
  )
  result$main_results[inputs$effect, "power"] / 100
}

# Check that Superpower's version of the population has the spec's cell
# means, SDs and (mixed designs) repeated-measures correlation, read back
# from the data set Superpower builds with exactly those properties. Cells
# are matched by Superpower's factor labels, so a cell put in the wrong
# place by the translation shows up as a mismatch.
superpower_check_run <- function(spec, design) {
  data <- call_backend("Superpower", Superpower::ANOVA_exact(design, verbose = FALSE))$dataframe
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
