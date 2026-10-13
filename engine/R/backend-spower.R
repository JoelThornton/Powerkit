# Backend adapter: basic tests (one-sample, independent and paired t-tests,
# correlation, two proportions, chi-square test of independence) via Spower.
#
# Power is simulated with Spower::Spower(). Two-sided tests use Spower's own
# experiment functions (p_t.test(), p_r(), p_prop.test(), p_chisq.test())
# exactly as a user would call them. One-sided tests use Spower's data
# generators (gen_t.test(), ...) with the stats test and its `alternative`,
# because Spower's `two.tailed = FALSE` halves the two-sided p-value without
# checking the direction of the effect, which doubles the Type I error rate
# (see docs/decisions.md).

spower_backend <- function(spec, seed = NULL) {
  inputs <- spower_inputs(spec)
  step <- valid_n_step(spec)
  n_min <- step * ceiling(minimum_n(spec) / step)
  list(
    name = "Spower",
    packages = c("Spower", "SimDesign"),
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
  test <- switch(
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
    )
  )
  alternative <- spec$target_test$alternative %||% "two_sided"
  test$template <- template
  test$alpha <- spec$target_test$alpha
  test$alternative <- alternative
  test$description <- if (alternative == "two_sided") {
    sprintf("Spower::Spower(Spower::%s())", test$experiment)
  } else {
    sprintf(
      "Spower::Spower() with Spower::%s() data and stats::%s(alternative = \"%s\")",
      test$generator, spower_stats_test(template), stats_alternative(template, alternative)
    )
  }
  test
}

probability_matrix <- function(spec) {
  rows <- spec$population$probabilities
  matrix(as.numeric(unlist(rows)), nrow = length(rows), byrow = TRUE)
}

spower_stats_test <- function(template) {
  switch(template, correlation = "cor.test", two_proportions = "prop.test", "t.test")
}

# The spec's "greater" means the spec's effect (d, dz, r, p2 - p1) is
# positive. spower_one_sided_p() puts group 2 (or the second condition)
# first in each test, so "greater" carries over unchanged.
stats_alternative <- function(template, alternative) {
  if (alternative == "two_sided") "two.sided" else alternative
}

# Rejections in `nrep` Spower replications at total sample size n.
spower_rejections <- function(inputs, n, nrep, seed) {
  args <- inputs$args(n)
  if (inputs$alternative == "two_sided") {
    head <- call("::", as.name("Spower"), as.name(inputs$experiment))
  } else {
    head <- as.name("spower_one_sided_p")
    args <- c(
      list(
        template = inputs$template,
        alternative = stats_alternative(inputs$template, inputs$alternative),
        generator = inputs$generator
      ),
      args
    )
  }
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

# One replication of a one-sided test: data from Spower's generator for the
# template, analysed with the stats test and `alternative`. Returns the
# p-value. Group 2 (or the second condition) comes first in each test, so
# "greater" means the spec's effect is positive.
spower_one_sided_p <- function(template, alternative, generator, ...) {
  data <- do.call(getExportedValue("Spower", generator), list(...))
  test <- switch(
    template,
    one_sample_t = stats::t.test(data[[1]], alternative = alternative),
    independent_t = stats::t.test(
      data[[2]], data[[1]],
      var.equal = list(...)$var.equal, alternative = alternative
    ),
    paired_t = stats::t.test(data[[2]], data[[1]], paired = TRUE, alternative = alternative),
    correlation = stats::cor.test(data[, 1], data[, 2], alternative = alternative),
    two_proportions = stats::prop.test(
      data[1, 2:1], data[2, 2:1],
      alternative = alternative, correct = FALSE
    )
  )
  test$p.value
}

# Check run: one large data set from Spower's generator with the translated
# arguments; the spec's effect is recovered from it in the spec's own
# orientation, with its standard error.
spower_check_run <- function(spec, inputs, n, seed) {
  args <- inputs$args(n)
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
