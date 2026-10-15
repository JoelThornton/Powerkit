# "How we check this": the published benchmarks the 2x2 engine reproduces.
#
# Transcribed from the published-example tests in
#   engine/tests/testthat/test-validation-anova-2x2-between.R
#   engine/tests/testthat/test-validation-anova-2x2-mixed.R
# (values owned by the maintainer). Keep this list in step with those files.
# Published power values are kept as written so the agreement allowance is
# half a unit in their last decimal place, as in the tests.

benchmarks_2x2 <- list(
  list(
    id = "vignette_between",
    source = "Superpower package vignette, \"More ANOVA designs\": two-way between-participants design",
    template = "2x2_between", mu = c(1, 0, 0, 1), sd = 2, r = NA,
    n = 160, setup = "Means 1, 0, 0, 1; SD 2; 40 per cell (N = 160); interaction; alpha .05",
    published_power = "0.881553371"
  ),
  list(
    id = "lakens_caldwell_2021",
    source = "Lakens & Caldwell (2021), Advances in Methods and Practices in Psychological Science, 4(1): 2x2 between-participants example",
    template = "2x2_between", mu = c(1, 0, 0, 0), sd = 2, r = NA,
    n = 320, setup = "Means 1, 0, 0, 0; SD 2; 80 per cell (N = 320); interaction; alpha .05",
    published_power = "0.6062"
  ),
  list(
    id = "sommet_reversed",
    source = "Sommet, Weissman, Cheutin & Elliot (2023), Advances in Methods and Practices in Psychological Science, 6(3), Table 2: reversed (crossover) interaction",
    template = "2x2_between", mu = c(-0.175, 0.175, 0.175, -0.175), sd = 1, r = NA,
    power = 0.80, setup = "Means -0.175, 0.175, 0.175, -0.175; SD 1; interaction; alpha .05; power .80",
    published_n = 256, exact_n = 260
  ),
  list(
    id = "sommet_attenuated",
    source = "Sommet, Weissman, Cheutin & Elliot (2023), Table 2: fully attenuated (knock-out) interaction",
    template = "2x2_between", mu = c(0, 0, 0, 0.35), sd = 1, r = NA,
    power = 0.80, setup = "Means 0, 0, 0, 0.35; SD 1; interaction; alpha .05; power .80",
    published_n = 1024, exact_n = 1028
  ),
  list(
    id = "vignette_mixed",
    source = "Superpower package vignette, \"More ANOVA designs\": 2x2 within-between design",
    template = "2x2_mixed", mu = c(-0.25, 0.25, 0.25, -0.25), sd = 1, r = 0.5,
    n = 46, setup = "Means -0.25, 0.25, 0.25, -0.25; SD 1; r .5; 23 per group (N = 46); interaction; alpha .05",
    published_power = "0.9125"
  ),
  list(
    id = "superpower_book_5_4",
    source = "Caldwell, Lakens, Parlett-Pelleriti, Prochilo & Aust, Power Analysis with Superpower (book), section 5.1, Table 5.4",
    template = "2x2_mixed", mu = c(-0.25, 0.25, 0.25, -0.25), sd = 1, r = 0.7,
    n = 46, setup = "Means -0.25, 0.25, 0.25, -0.25; SD 1; r .7; 23 per group (N = 46); interaction; alpha .05",
    published_power = "0.9898467"
  )
)

benchmark_spec <- function(b) {
  mixed <- b$template == "2x2_mixed"
  population <- list(metric = "raw", means = list(as.list(b$mu[1:2]), as.list(b$mu[3:4])), sd = b$sd)
  if (mixed) population$r <- b$r
  list(
    spec_version = "0.1",
    design = "factorial_anova",
    template = b$template,
    variables = list(
      A = list(type = "between_factor", label = "Factor A", levels = list("a1", "a2")),
      B = list(type = if (mixed) "within_factor" else "between_factor", label = "Factor B", levels = list("b1", "b2")),
      Y = list(type = "continuous", label = "Outcome")
    ),
    population = population,
    effect_justification = list(
      type = "smallest_effect_of_interest",
      source = "powerkit validation benchmark (not a real study)"
    ),
    target_test = list(effect = "interaction", method = "anova_f", alpha = 0.05),
    goal = if (is.null(b$published_n)) {
      list(type = "power", n = as.integer(b$n))
    } else {
      list(type = "sample_size", power = b$power)
    },
    options = list(method = "exact", seed = 20261013L)
  )
}

# Half a unit in the last decimal place of a value as written.
rounding_allowance <- function(x) {
  decimals <- if (grepl(".", x, fixed = TRUE)) nchar(sub(".*\\.", "", x)) else 0
  0.5 * 10^-decimals
}

benchmark_published_text <- function(b) {
  if (is.null(b$published_n)) {
    sprintf("power %s", b$published_power)
  } else {
    sprintf("N = %s (normal approximation); exact F-test N = %s", b$published_n, b$exact_n)
  }
}

# One row of the checks table. `out` is the engine_call() result for the
# benchmark spec, or NULL if the check hasn't been run.
benchmark_row <- function(b, out = NULL) {
  engine <- "not run yet"
  verdict <- ""
  if (!is.null(out)) {
    if (!out$ok) {
      engine <- "engine error"
      verdict <- "✗ see message"
    } else if (is.null(b$published_n)) {
      power <- out$value$curve$power[1]
      engine <- sprintf("power %.7f", power)
      ok <- abs(power - as.numeric(b$published_power)) <= rounding_allowance(b$published_power)
      verdict <- if (ok) "✓ matches" else "✗ differs"
    } else {
      n <- out$value$n_required$n
      engine <- sprintf("N = %s", n)
      ok <- n == b$exact_n && n >= b$published_n
      verdict <- if (ok) "✓ matches the exact N" else "✗ differs"
    }
  }
  data.frame(
    Design = if (b$template == "2x2_mixed") "2 x 2 mixed" else "2 x 2 between",
    Source = b$source,
    Setup = b$setup,
    Published = benchmark_published_text(b),
    powerkit = engine,
    Agreement = verdict,
    check.names = FALSE
  )
}

checks_ui <- function() {
  tagList(
    h3("How we check this"),
    p(
      "The 2 × 2 engine is tested against published results. Each benchmark below is a test in",
      tags$code("engine/tests/testthat/test-validation-anova-2x2-between.R"), "or",
      tags$code("...-mixed.R"), "and runs in the nightly validation job. For power values, agreement",
      "means powerkit's exact power equals the published value to the precision it was published with.",
      "Sommet et al. give N from a normal (z) approximation, which is slightly below the exact F-test N;",
      "there, powerkit must give the exact F-test N (checked by the maintainer) and at least the published N."
    ),
    p(
      "The same test files also check that powerkit agrees with direct calls to Superpower (exactly and by",
      "simulation) and that the Type I error rate is at alpha when the tested effect is zero."
    ),
    actionButton("run_checks", "Run these checks now with the engine", icon = icon("play"), class = "btn-outline-primary mb-3"),
    tableOutput("checks_table"),
    uiOutput("checks_problems")
  )
}
