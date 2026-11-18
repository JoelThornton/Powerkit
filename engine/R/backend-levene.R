# Backend adapter: Levene's test and the Brown-Forsythe test of two
# variances (basic_test / two_variances, E53, target_test > method "levene"
# or "brown_forsythe").
#
# The F test of two variances (backend-variance.R) assumes normal scores and
# its false-positive rate is far from alpha when they aren't. Levene's test
# compares the groups' absolute deviations from their means by an ANOVA F
# test, and the Brown-Forsythe version uses deviations from the medians.
# Both are car::leveneTest() (center = mean or median; median is car's
# default), which jamovi and car report; SPSS reports Levene's test.
#
# No package has a formula for their power, so each study is simulated:
# group 1's n1 and group 2's n2 scores (the total split by the allocation
# ratio, as rounded_groups() splits it) are drawn from the chosen shape
# (score_shape_sampler(): normal, skewed or heavy-tailed, mean 0 and SD 1),
# scaled to each group's SD, and car::leveneTest() tests them. Spower runs
# the experiment p_levene(). The tests are two-sided.

levene_inputs <- function(spec) {
  pop <- spec$population
  list(
    var1 = as.numeric(pop$var1),
    var2 = as.numeric(pop$var2),
    ratio = as.numeric(allocation_ratio(spec)),
    shape = pop$score_shape %||% "normal",
    center = if (identical(spec$target_test$method, "levene")) "mean" else "median"
  )
}

# One study's two groups: n split by ratio (group 2 / group 1), each group
# the chosen shape scaled to its SD, group 1 drawn first.
levene_scores <- function(n, var1, var2, ratio, shape) {
  sizes <- rounded_groups(n, ratio)
  draw <- score_shape_sampler(shape)
  list(first = sqrt(var1) * draw(sizes[1]), second = sqrt(var2) * draw(sizes[2]))
}

# The experiment Spower runs: car::leveneTest()'s p-value, with the
# deviations taken from each group's mean (Levene) or median
# (Brown-Forsythe).
p_levene <- function(n, var1, var2, ratio, shape, center) {
  g <- levene_scores(n, var1, var2, ratio, shape)
  y <- c(g$first, g$second)
  group <- factor(rep(c("1", "2"), c(length(g$first), length(g$second))))
  car::leveneTest(y, group, center = center)[["Pr(>F)"]][1]
}

levene_count <- function(inputs, n, nrep, alpha, seed) {
  result <- spower_eval(as.name("p_levene"), c(list(n = n), inputs), nrep, alpha, seed)
  round(result$power * nrep)
}

levene_test_words <- function(spec) {
  if (identical(spec$target_test$method, "levene")) {
    "Levene's test (car::leveneTest(center = mean))"
  } else {
    "the Brown-Forsythe test (car::leveneTest(center = median))"
  }
}

levene_backend <- function(spec, seed = NULL) {
  inputs <- levene_inputs(spec)
  step <- valid_n_step(spec)
  list(
    name = "Spower",
    packages = c("Spower", "SimDesign", "car"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = sprintf("Spower::Spower(p_levene()) (%s, on %s)", levene_test_words(spec),
      score_shape_words(inputs$shape))),
    n_step = step,
    exact_min_n = step * ceiling(minimum_n(spec) / step),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(chunk, chunk_seed) {
        levene_count(inputs, n, chunk, spec$target_test$alpha, chunk_seed)
      })
    },
    sensitivity = NULL,
    simulated_sensitivity = function(n, power, nrep, seed, cores) simulated_effect_sensitivity(spec, n, power, nrep, seed, cores),
    check_run = function() levene_check_run(spec, inputs, seed)
  )
}

# Check run: one large study drawn as each simulated one is. Each group's
# SD and their ratio are compared on the log scale with standard errors
# that allow for the scores' kurtosis (sd_ratio_row(): the variance of a
# log SD is about (kurtosis - 1) / (4 n)), since a heavy-tailed shape makes
# an SD vary far more than a normal one does; and the groups' sizes with
# the allocation ratio.
levene_check_run <- function(spec, inputs, seed) {
  step <- valid_n_step(spec)
  n <- step * ceiling(check_run_n() / step)
  g <- call_backend("Spower", with_seed(seed %||% 1L, levene_scores(n, inputs$var1, inputs$var2, inputs$ratio, inputs$shape)))
  kurtosis <- function(x) mean((x - mean(x))^4) / stats::var(x)^2
  sd_row <- function(x, specified, label) {
    se_log <- sqrt((kurtosis(x) - 1) / (4 * length(x)))
    data.frame(parameter = label, specified = specified, recovered = stats::sd(x),
      ok = abs(log(stats::sd(x)) - log(specified)) <= 5 * se_log)
  }
  sizes <- rounded_groups(n, inputs$ratio)
  rbind(
    sd_row(g$first, sqrt(inputs$var1), "SD in group 1"),
    sd_row(g$second, sqrt(inputs$var2), "SD in group 2"),
    sd_ratio_row(g$first, g$second, sqrt(inputs$var2 / inputs$var1)),
    data.frame(parameter = "group size ratio (group 2 / group 1)", specified = inputs$ratio,
      recovered = length(g$second) / length(g$first),
      ok = length(g$first) == sizes[1] && length(g$second) == sizes[2])
  )
}

# The score generator in R code, as score_shape_sampler() draws it.
levene_draw_line <- function(shape) {
  sprintf("draw <- function(n) %s # %s, mean 0 and SD 1", switch(
    shape,
    normal = "rnorm(n)",
    skewed = "(rchisq(n, df = 10) - 10) / sqrt(20)",
    heavy_tailed = "rt(n, df = 3) / sqrt(3)"
  ), score_shape_words(shape))
}

# The standalone script (export_script()).
levene_script <- function(spec, result) {
  inputs <- levene_inputs(spec)
  v <- spec$variables
  levels <- comment_text(unlist(v$G$levels))
  header <- script_header(spec, result, "Spower", "Spower::Spower, car::leveneTest")
  c(
    header,
    "library(Spower)",
    "",
    "# Inputs ----",
    sprintf("var1 <- %s # variance of %s in group 1 (%s)", r_code(inputs$var1), comment_text(v$Y$label), levels[1]),
    sprintf("var2 <- %s # variance in group 2 (%s)", r_code(inputs$var2), levels[2]),
    sprintf("allocation_ratio <- %s # size of group 2 relative to group 1", r_code(inputs$ratio)),
    sprintf("center <- %s # %s", r_code(inputs$center),
      if (identical(inputs$center, "mean")) "Levene's test: deviations from each group's mean" else
        "the Brown-Forsythe test: deviations from each group's median"),
    goal_inputs(spec, result),
    "",
    "# Scores in the chosen shape.",
    levene_draw_line(inputs$shape),
    "",
    "# One simulated study: the total split into the two groups (group 1",
    "# rounded to the nearest whole person), each group's scores drawn in the",
    "# chosen shape and scaled to its SD, group 1 first; then car's",
    "# leveneTest(), which is two-sided.",
    "p_levene <- function(n) {",
    "  n1 <- floor(n / (1 + allocation_ratio) + 0.5)",
    "  first <- sqrt(var1) * draw(n1)",
    "  second <- sqrt(var2) * draw(n - n1)",
    "  group <- factor(rep(c(\"1\", \"2\"), c(n1, n - n1)))",
    "  car::leveneTest(c(first, second), group, center = center)[[\"Pr(>F)\"]][1]",
    "}",
    "",
    "# One batch: significant results, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  result <- Spower(p_levene(n = batch_n), sig.level = alpha, replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, valid_n_step(spec)),
    comparison_section()
  )
}

# Simulated-data code (simulated_data()): the two groups drawn as the
# simulation draws them.
sim_levene_code <- function(spec, n) {
  inputs <- levene_inputs(spec)
  sizes <- rounded_groups(n, inputs$ratio)
  draw <- switch(inputs$shape,
    normal = "stats::rnorm(%d)",
    skewed = "(stats::rchisq(%d, df = 10) - 10) / sqrt(20)",
    heavy_tailed = "stats::rt(%d, df = 3) / sqrt(3)")
  c(
    sprintf("first <- sqrt(%s) * %s # %s", r_code(inputs$var1), sprintf(draw, sizes[1]), score_shape_words(inputs$shape)),
    sprintf("second <- sqrt(%s) * %s", r_code(inputs$var2), sprintf(draw, sizes[2])),
    sprintf("simulated <- data.frame(%s = rep(%s, c(%d, %d)), %s = c(first, second))",
      sim_label(spec, "G"), r_code(sim_levels(spec, "G")), sizes[1], sizes[2], sim_label(spec, "Y"))
  )
}
