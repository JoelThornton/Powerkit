# Backend adapter: basic tests (one-sample, independent and paired t-tests,
# correlation, two proportions, chi-square test of independence) via Spower.
#
# Used when simulation is requested (options > method = "simulation") and
# for Welch's t-test; otherwise basic tests use pwr's exact formulas
# (backend-pwr.R; docs/decisions.md, 17 October 2026).
#
# Power is simulated with Spower::Spower() and Spower's own experiment
# functions (p_t.test(), p_r(), p_prop.test(), p_chisq.test(),
# p_var.test()), exactly as a
# user would call them. One-sided tests use their `alternative` argument
# (Spower 0.7 and later), translated to Spower's orientation by
# spower_alternative(). Spower 0.6.4's `two.tailed = FALSE` halved the
# two-sided p-value whatever the direction, so powerkit used its own
# directional test until Spower 0.7 fixed this (Departure 4, retired; see
# docs/decisions.md, 17 October 2026).

spower_backend <- function(spec, seed = NULL) {
  inputs <- spower_inputs(spec)
  step <- valid_n_step(spec)
  n_min <- step * ceiling(minimum_n(spec) / step)
  list(
    name = "Spower",
    # EnvStats carries the chi-square test of one variance that
    # p_var.test() calls, so its version belongs in the provenance.
    packages = c(
      "Spower", "SimDesign",
      if (identical(spec$template, "one_variance")) "EnvStats"
    ),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = inputs$description),
    n_step = step,
    exact_min_n = n_min,
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) {
        spower_rejections(inputs, n, k, chunk_seed)
      })
    },
    sensitivity = NULL,
    check_run = function() {
      big_n <- step * ceiling(check_run_n() / step)
      spower_check_run(spec, inputs, big_n, seed)
    }
  )
}

# Translate a validated basic-test spec into Spower's terms.
#
# Orientation: the spec's effects are group 2 minus group 1 (d), second
# condition minus first (dz), and p2 versus p1. Spower's generators put the
# effect d in the first group (two-sample) or first time point (paired), so
# d is passed with its sign reversed. Spower's paired generator draws the two
# time points independently with SD 1, so the differences have SD sqrt(2):
# Spower's d is sqrt(2) * dz.
spower_inputs <- function(spec) {
  pop <- spec$population
  ratio <- spec$options$allocation_ratio %||% 1
  # Group 1's size, from the total n and the allocation ratio n2 / n1.
  first_group <- function(n) round(n / (1 + ratio))
  template <- spec$template
  test <- if (rank_test(spec)) rank_test_inputs(spec, first_group) else switch(
    template,
    one_sample_t = list(
      experiment = "p_t.test", generator = "gen_t.test",
      args = function(n) list(n = n, d = pop$d, type = "one.sample")
    ),
    independent_t = list(
      experiment = "p_t.test", generator = "gen_t.test",
      args = function(n) {
        list(
          n = first_group(n), d = -pop$d, type = "two.sample", n2_n1 = ratio,
          var.equal = spec$target_test$method == "student_t"
        )
      }
    ),
    paired_t = list(
      experiment = "p_t.test", generator = "gen_t.test",
      args = function(n) list(n = n, d = -sqrt(2) * pop$dz, type = "paired")
    ),
    correlation = list(
      experiment = "p_r", generator = "gen_r",
      args = function(n) list(n = n, r = pop$r)
    ),
    two_proportions = list(
      experiment = "p_prop.test", generator = "gen_prop.test",
      args = function(n) {
        list(
          n = first_group(n), prop = c(pop$p1, pop$p2), n.ratios = c(1, ratio),
          correct = FALSE
        )
      }
    ),
    chi_square_independence = list(
      experiment = "p_chisq.test", generator = "gen_chisq.test",
      args = function(n) list(n = n, P = probability_matrix(spec), correct = FALSE)
    ),
    # One variance against a fixed value: p_var.test() with one variance and
    # sigma2 runs EnvStats::varTest(), the chi-square test, which is the
    # test G*Power's "Variance: difference from constant" computes.
    one_variance = list(
      experiment = "p_var.test", generator = "gen_var.test",
      args = function(n) list(n = n, vars = pop$var, sigma2 = pop$var0)
    ),
    # Two variances: p_var.test() with two variances runs stats::var.test(),
    # the F test, whatever its `test` argument says (that argument chooses
    # between Levene, Bartlett and Fligner for three groups or more). The F
    # test is what G*Power computes.
    # The groups are always the same size: an allocation ratio is refused
    # in the spec checks, because Spower's generator can't draw unequal
    # groups for this test (docs/upstream-questions.md).
    two_variances = list(
      experiment = "p_var.test", generator = "gen_var.test",
      args = function(n) list(n = first_group(n), vars = c(pop$var1, pop$var2))
    )
  )
  alternative <- spec$target_test$alternative %||% "two_sided"
  test$template <- template
  test$alpha <- spec$target_test$alpha
  test$alternative <- alternative
  test$description <- if (rank_test(spec)) {
    rank_test_description(test, template, alternative)
  } else if (alternative == "two_sided") {
    sprintf("Spower::Spower(Spower::%s())", test$experiment)
  } else {
    sprintf(
      "Spower::Spower(Spower::%s(alternative = \"%s\"))",
      test$experiment, spower_alternative(template, alternative)
    )
  }
  test
}

# Rank tests: the Wilcoxon signed-rank test (one sample, paired) and the
# Mann-Whitney test (two groups) with Spower's p_wilcox.test(); the
# Kruskal-Wallis test with p_kruskal.test(). Scores are drawn from the
# chosen shape in SD units (score_shape_sampler()), and the effect shifts
# it: d for one sample, dz for the within-person differences, d for two
# groups, and the group means in SD units for Kruskal-Wallis. So the
# effect sizes mean what they mean for the t-test and ANOVA.
#
# Orientation as for the t-tests: p_wilcox.test() compares the first
# sample with the second, so the spec's d (group 2 minus group 1) and dz
# (second minus first) are passed with their sign reversed. For a paired
# test the differences themselves are drawn (the second sample is 0), so
# that their shape is the one chosen: the signed-rank test ranks the
# differences, and assumes they are symmetric.
rank_test_inputs <- function(spec, first_group) {
  pop <- spec$population
  ratio <- spec$options$allocation_ratio %||% 1
  draw <- score_shape_sampler(pop$score_shape)
  shifted <- function(n, d) d + draw(n)
  if (identical(spec$template, "oneway_between")) {
    k <- length(spec$variables$A$levels)
    means <- as.numeric(unlist(pop$means)) / pop$sd
    gen <- function(n, k, n.ratios, means, ...) {
      lapply(seq_len(k), function(g) means[g] + draw(n * n.ratios[g]))
    }
    return(list(
      experiment = "p_kruskal.test", rank = "kruskal", draw = draw,
      args = function(n) list(n = n / k, k = k, means = means, gen_fun = gen)
    ))
  }
  wilcox <- function(args) {
    c(args, list(parent1 = shifted, parent2 = if (identical(args$type, "paired")) {
      function(n, d) rep(0, n)
    } else {
      function(n, d) draw(n)
    }))
  }
  args <- switch(
    spec$template,
    one_sample_t = function(n) wilcox(list(n = n, d = pop$d, type = "one.sample")),
    paired_t = function(n) wilcox(list(n = n, d = -pop$dz, type = "paired")),
    independent_t = function(n) {
      wilcox(list(n = first_group(n), d = -pop$d, type = "two.sample", n2_n1 = ratio))
    }
  )
  list(experiment = "p_wilcox.test", rank = "wilcox", draw = draw, args = args)
}

# Draws of n scores with mean 0 and SD 1 in the chosen shape. The skewed
# shape is the standardised chi-square distribution with 10 df that
# Spower's p_wilcox.test() examples use; the heavy-tailed shape is a t
# distribution with 3 df, whose SD is sqrt(3).
score_shape_sampler <- function(shape) {
  switch(
    shape %||% "normal",
    normal = function(n) stats::rnorm(n),
    skewed = function(n) (stats::rchisq(n, df = 10) - 10) / sqrt(20),
    heavy_tailed = function(n) stats::rt(n, df = 3) / sqrt(3)
  )
}

score_shape_words <- function(shape) {
  switch(
    shape %||% "normal",
    normal = "normal scores",
    skewed = "skewed scores (standardised chi-square, 10 df)",
    heavy_tailed = "heavy-tailed scores (t, 3 df, rescaled to SD 1)"
  )
}

rank_test_description <- function(test, template, alternative) {
  type <- switch(template, one_sample_t = "one.sample", paired_t = "paired", independent_t = "two.sample", NULL)
  arguments <- c(
    if (!is.null(type)) sprintf("type = \"%s\"", type),
    if (alternative != "two_sided") sprintf("alternative = \"%s\"", spower_alternative(template, alternative))
  )
  sprintf("Spower::Spower(Spower::%s(%s))", test$experiment, paste(arguments, collapse = ", "))
}

probability_matrix <- function(spec) {
  rows <- spec$population$probabilities
  matrix(as.numeric(unlist(rows)), nrow = length(rows), byrow = TRUE)
}

# The spec's "greater" means the spec's effect (d, dz, r, p2 - p1) is
# positive. Spower's two-sample, paired and two-proportion tests compare the
# first group (or time point) with the second, and powerkit passes the
# effect to Spower with its sign reversed (-d, -sqrt(2) * dz; proportions
# in the order p1, p2), so for those templates the spec's "greater" is
# Spower's "less". One-sample t-tests and correlations keep the direction.
spower_alternative <- function(template, alternative) {
  if (alternative == "two_sided") {
    return("two.sided")
  }
  # The variances go to Spower in the spec's own order, so their direction
  # is not reversed either.
  reversed <- template %in% c("independent_t", "paired_t", "two_proportions")
  if (!reversed) {
    return(alternative)
  }
  if (alternative == "greater") "less" else "greater"
}

# Rejections in `nrep` Spower replications at total sample size n.
spower_rejections <- function(inputs, n, nrep, seed) {
  args <- inputs$args(n)
  if (inputs$alternative != "two_sided") {
    args$alternative <- spower_alternative(inputs$template, inputs$alternative)
  }
  head <- call("::", as.name("Spower"), as.name(inputs$experiment))
  result <- spower_eval(head, args, nrep, inputs$alpha, seed)
  round(result$power * nrep)
}

# Evaluate Spower::Spower(<head>(<args>)) with the random-number generator
# seeded. Spower reads the experiment unevaluated and turns each length-one
# argument into a column of its design table; longer arguments (vectors,
# matrices) must be names it can look up, so they are bound in the
# environment Spower is called from.
spower_eval <- function(head, args, nrep, alpha, seed) {
  env <- new.env(parent = asNamespace("powerkit"))
  long <- !vapply(args, function(a) is.atomic(a) && length(a) == 1, logical(1))
  for (name in names(args)[long]) {
    assign(paste0(".", name), args[[name]], envir = env)
    args[[name]] <- as.name(paste0(".", name))
  }
  experiment <- as.call(c(list(head), args))
  spower_call <- bquote(Spower::Spower(
    .(experiment),
    sig.level = .(alpha),
    replications = .(as.integer(nrep)),
    parallel = FALSE,
    verbose = FALSE
  ))
  call_backend("Spower", with_seed(seed, quietly(eval(spower_call, env))))
}

# Check run: one large data set from Spower's generator with the translated
# arguments; the spec's effect is recovered from it in the spec's own
# orientation, with its standard error.
spower_check_run <- function(spec, inputs, n, seed) {
  args <- inputs$args(n)
  if (!is.null(inputs$rank)) {
    return(rank_check_run(spec, args, seed))
  }
  generator <- getExportedValue("Spower", inputs$generator)
  data <- call_backend("Spower", with_seed(seed, do.call(generator, args)))
  pop <- spec$population
  ratio <- spec$options$allocation_ratio %||% 1
  # The standardised mean of x, with the SE of the mean in SD units.
  standardised <- function(x, label, specified) {
    check_run_rows(label, specified, mean(x) / stats::sd(x), 1 / sqrt(length(x)))
  }
  group_sizes <- function(n1, n2) {
    data.frame(
      parameter = "group size ratio (group 2 / group 1)",
      specified = ratio, recovered = n2 / n1, ok = isTRUE(all.equal(n2 / n1, ratio))
    )
  }
  switch(
    spec$template,
    one_sample_t = standardised(data[[1]], "d (mean / SD)", pop$d),
    independent_t = {
      g1 <- data[[1]]
      g2 <- data[[2]]
      pooled <- sqrt(((length(g1) - 1) * stats::var(g1) + (length(g2) - 1) * stats::var(g2)) /
        (length(g1) + length(g2) - 2))
      rbind(
        check_run_rows(
          "d (group 2 minus group 1, pooled SD)", pop$d,
          (mean(g2) - mean(g1)) / pooled, sqrt(1 / length(g1) + 1 / length(g2))
        ),
        group_sizes(length(g1), length(g2))
      )
    },
    paired_t = standardised(data[[2]] - data[[1]], "dz (second minus first condition)", pop$dz),
    correlation = {
      r <- stats::cor(data[, 1], data[, 2])
      rows <- check_run_rows("r", pop$r, r, NA)
      # Compared on Fisher's z scale, where the SE is 1 / sqrt(n - 3).
      rows$ok <- abs(atanh(r) - atanh(pop$r)) <= 5 / sqrt(nrow(data) - 3)
      rows
    },
    two_proportions = {
      p_hat <- data[1, ] / data[2, ]
      rbind(
        check_run_rows(
          c("p1 (group 1)", "p2 (group 2)"), c(pop$p1, pop$p2), p_hat,
          sqrt(p_hat * (1 - p_hat) / data[2, ])
        ),
        group_sizes(data[2, 1], data[2, 2])
      )
    },
    # gen_var.test() returns the outcome in DV, with a group column when
    # there are two variances. The SE of a sample variance from normal
    # data is var * sqrt(2 / (n - 1)).
    one_variance = {
      v <- stats::var(data$DV)
      check_run_rows(
        "variance of Y", pop$var, v, pop$var * sqrt(2 / (nrow(data) - 1))
      )
    },
    two_variances = {
      by_group <- split(data$DV, data$group)
      specified <- c(pop$var1, pop$var2)
      rbind(
        check_run_rows(
          c("variance in group 1", "variance in group 2"),
          specified,
          vapply(by_group, stats::var, numeric(1), USE.NAMES = FALSE),
          specified * sqrt(2 / (unname(lengths(by_group)) - 1))
        ),
        group_sizes(length(by_group[[1]]), length(by_group[[2]]))
      )
    },
    chi_square_independence = {
      p <- probability_matrix(spec)
      p_hat <- data / sum(data)
      cells <- expand.grid(i = seq_len(nrow(p)), j = seq_len(ncol(p)))
      check_run_rows(
        sprintf(
          "P(%s = %s, %s = %s)",
          spec$variables$X$label, unlist(spec$variables$X$levels)[cells$i],
          spec$variables$Y$label, unlist(spec$variables$Y$levels)[cells$j]
        ),
        p[cbind(cells$i, cells$j)],
        p_hat[cbind(cells$i, cells$j)],
        sqrt(p_hat[cbind(cells$i, cells$j)] * (1 - p_hat[cbind(cells$i, cells$j)]) / sum(data))
      )
    }
  )
}

# Check run for the rank tests: one large sample drawn as each simulated
# sample is, with the effect recovered in the spec's own orientation.
rank_check_run <- function(spec, args, seed) {
  pop <- spec$population
  if (identical(spec$template, "oneway_between")) {
    groups <- call_backend("Spower", with_seed(seed, args$gen_fun(args$n, args$k, rep(1, args$k), args$means)))
    return(check_run_rows(
      sprintf("mean of %s (SD units)", unlist(spec$variables$A$levels)),
      args$means,
      vapply(groups, mean, numeric(1)),
      1 / sqrt(lengths(groups))
    ))
  }
  data <- call_backend("Spower", with_seed(seed, list(
    first = args$parent1(args$n, args$d),
    second = args$parent2(args$n * (args$n2_n1 %||% 1), args$d)
  )))
  standardised <- function(x, label, specified) {
    check_run_rows(label, specified, mean(x) / stats::sd(x), 1 / sqrt(length(x)))
  }
  switch(
    spec$template,
    one_sample_t = standardised(data$first, "d (mean / SD)", pop$d),
    # The second sample is 0: the first holds the differences, first minus
    # second condition, so their sign is reversed here.
    paired_t = standardised(-data$first, "dz (second minus first condition)", pop$dz),
    independent_t = {
      g1 <- data$first
      g2 <- data$second
      pooled <- sqrt(((length(g1) - 1) * stats::var(g1) + (length(g2) - 1) * stats::var(g2)) /
        (length(g1) + length(g2) - 2))
      check_run_rows(
        "d (group 2 minus group 1, pooled SD)", pop$d,
        (mean(g2) - mean(g1)) / pooled, sqrt(1 / length(g1) + 1 / length(g2))
      )
    }
  )
}
