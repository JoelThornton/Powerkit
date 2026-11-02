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
      if (identical(spec$template, "one_variance")) "EnvStats",
      # p_glm() tests the coefficients with car::lht().
      if (identical(spec$template, "factorial")) "car",
      # p_jonckheere() calls PMCMRplus's jonckheereTest().
      if (jonckheere_test(spec)) "PMCMRplus",
      # p_brunner_munzel() calls brunnermunzel's brunnermunzel.test().
      if (brunner_munzel_test(spec)) "brunnermunzel",
      # p_art() calls ARTool's art() and artlm(), then car's Anova().
      if (aligned_rank_test(spec)) c("ARTool", "car"),
      # p_negative_binomial() fits MASS's glm.nb().
      if (negative_binomial_test(spec)) "MASS",
      # p_coefficient() tests with car's linearHypothesis() and hccm(), or
      # fits quantreg's rq().
      if (robust_regression(spec)) {
        if (identical(spec$target_test$method, "quantile_regression")) "quantreg" else "car"
      }
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
    # Pearson's r by simulation, or Spearman's rho or Kendall's tau
    # (p_r(method =)), on bivariate normal scores with Pearson correlation r.
    # Spearman's rho and Kendall's tau on scores of a chosen shape other
    # than normal: both scores drawn by shaped_pair_scores(), passed to
    # p_r() as its generator.
    correlation = list(
      experiment = "p_r", generator = "gen_r", generate = if (shaped_rank_correlation(spec)) shaped_pair_scores,
      args = function(n) {
        method <- spec$target_test$method %||% "pearson"
        c(list(n = n, r = pop$r), if (!identical(method, "pearson")) list(method = method),
          if (shaped_rank_correlation(spec)) list(gen_fun = shaped_pair_scores, shape = pop$score_shape))
      }
    ),
    # The Pitman-Morgan test: the variances of two paired measurements are
    # equal exactly when their sum and difference (first minus second) are
    # uncorrelated, and cov(sum, difference) = var1 - var2. p_r() tests that
    # correlation (cor.test()) on the sum and difference of bivariate normal
    # scores with the two variances and the correlation r.
    paired_variances = list(
      experiment = "p_r", generator = "pitman_morgan_scores", generate = pitman_morgan_scores,
      args = function(n) {
        list(n = n, r = 0, gen_fun = pitman_morgan_scores, var1 = pop$var1, var2 = pop$var2, rho12 = pop$r)
      }
    ),
    # One-way MANOVA: powerkit's own experiment for Spower, p_manova(),
    # draws multivariate normal scores for each group (manova_scores()) and
    # returns the p-value of Pillai's trace from stats::manova().
    manova = list(
      experiment = "p_manova", own = TRUE, generator = "manova_scores", generate = manova_scores,
      args = function(n) {
        c(list(n = n / length(pop$means), means = manova_means(spec), sds = as.numeric(unlist(pop$sds)), r = pop$r),
          # Two factors: B's number of levels and the effect tested.
          if (!is.null(spec$variables$B)) list(b = length(spec$variables$B$levels), term = manova_term(spec)))
      }
    ),
    # One-sample Hotelling's T-squared: powerkit's own experiment,
    # p_hotelling_one(), draws one group's multivariate normal scores
    # (hotelling_one_scores()) and tests their means against the fixed
    # values.
    hotelling_one = list(
      experiment = "p_hotelling_one", own = TRUE, generator = "hotelling_one_scores", generate = hotelling_one_scores,
      args = function(n) {
        list(n = n, means = as.numeric(unlist(pop$means)), mu0 = as.numeric(unlist(pop$mu0)),
             sds = as.numeric(unlist(pop$sds)), r = pop$r)
      }
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
    # Welch's one-way ANOVA: p_anova.test() runs stats::oneway.test() with
    # var.equal = FALSE, on groups of equal size drawn with each group's
    # mean and SD.
    oneway_between = list(
      experiment = "p_anova.test", generator = "gen_anova.test",
      args = function(n) {
        k <- length(spec$variables$A$levels)
        list(n = n / k, k = k, means = as.numeric(unlist(pop$means)), sds = welch_sds(spec), var.equal = FALSE)
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
    ),
    # A trend in proportions across groups in order: powerkit's own
    # experiment, p_cochran_armitage(), draws each group's count of "yes"
    # from its proportion and returns stats::prop.trend.test()'s p-value
    # with the groups' scores. The experiment's n is one share of the total:
    # each group has n times its share (options > group_ratio; 1 each for
    # equal groups).
    proportion_trend = list(
      experiment = "p_cochran_armitage", own = TRUE,
      args = function(n) {
        w <- trend_group_shares(spec)
        list(n = n / sum(w), proportions = as.numeric(unlist(pop$proportions)), scores = trend_scores(spec), n.ratios = w)
      }
    ),
    # A yes/no outcome with two crossed factors: p_glm() draws Y from the
    # logistic model with both factors and their interaction (effect
    # coding), whose coefficients reproduce the cell proportions exactly,
    # and tests the effect's coefficients jointly (car::lht(), the Wald
    # chi-square test, as car::Anova(type = 3) would).
    # Negative binomial regression of a count: powerkit's own experiment,
    # p_negative_binomial(), draws the predictor, any other predictor and
    # the counts (negative_binomial_data()) and returns the Wald z test of
    # the predictor's coefficient in MASS's glm.nb().
    single_predictor_count = list(
      experiment = "p_negative_binomial", own = TRUE,
      args = function(n) {
        list(
          n = n, rate_ratio = pop$rate_ratio, base_rate = pop$base_rate, dispersion = pop$dispersion,
          exposure = pop$mean_exposure %||% 1, binary = identical(spec$variables$X$type, "binary"),
          x_prob = pop$x_prob %||% 0.5, r2_other = pop$r2_other_predictors %||% 0
        )
      }
    ),
    # One regression coefficient with robust standard errors or by quantile
    # regression: powerkit's own experiment, p_coefficient(), draws the
    # predictors and the outcome (coefficient_data()) and tests the
    # coefficient of x.
    single_coefficient = list(
      experiment = "p_coefficient", own = TRUE,
      args = function(n) {
        c(
          list(
            n = n, partial_r2 = pop$partial_r2, predictors = pop$predictors_total,
            variance_ratio = pop$variance_ratio %||% 1, shape = pop$error_shape %||% "normal",
            method = spec$target_test$method
          ),
          if (identical(spec$target_test$method, "quantile_regression")) list(quantile = pop$quantile %||% 0.5)
        )
      }
    ),
    factorial = {
      design <- logistic_factorial_design(spec)
      list(
        experiment = "p_glm", generator = "gen_glm",
        args = function(n) {
          list(formula = y ~ A * B, X = design$X(n), betas = design$betas, test = design$test, family = stats::binomial())
        }
      )
    }
  )
  alternative <- spec$target_test$alternative %||% "two_sided"
  test$template <- template
  test$alpha <- spec$target_test$alpha
  test$alternative <- alternative
  test$description <- if (rank_test(spec)) {
    rank_test_description(test, template, alternative)
  } else if (identical(template, "factorial")) {
    "Spower::Spower(Spower::p_glm(family = binomial()), Wald test of the effect's coefficients)"
  } else if (identical(template, "single_predictor_count")) {
    sprintf("Spower::Spower(p_negative_binomial(%s)) (MASS::glm.nb(), the Wald z test of the predictor)",
      if (alternative == "two_sided") "" else sprintf("alternative = \"%s\"", alternative))
  } else if (identical(template, "single_coefficient")) {
    switch(spec$target_test$method,
      quantile_regression = sprintf(
        "Spower::Spower(p_coefficient()) (quantreg::rq(tau = %s), the test of the predictor's coefficient by summary.rq(se = \"nid\"))",
        format(spec$population$quantile %||% 0.5)
      ),
      sprintf(
        "Spower::Spower(p_coefficient()) (stats::lm(), the test of the predictor's coefficient by car::linearHypothesis(white.adjust = \"%s\"))",
        sub("ols_", "", spec$target_test$method)
      )
    )
  } else if (identical(template, "proportion_trend")) {
    sprintf("Spower::Spower(p_cochran_armitage(%s)) (stats::prop.trend.test(), the Cochran-Armitage test)",
      if (alternative == "two_sided") "" else sprintf("alternative = \"%s\"", alternative))
  } else if (welch_anova(spec)) {
    "Spower::Spower(Spower::p_anova.test(var.equal = FALSE))"
  } else if (identical(template, "manova")) {
    if (is.null(spec$variables$B)) "Spower::Spower(p_manova()) (stats::manova(), Pillai's trace)" else
      sprintf("Spower::Spower(p_manova()) (stats::manova() of A * B, Pillai's trace of %s)", manova_term(spec))
  } else if (identical(template, "hotelling_one")) {
    "Spower::Spower(p_hotelling_one()) (one-sample Hotelling's T-squared: stats::anova() of lm(), Pillai's trace)"
  } else if (identical(template, "paired_variances")) {
    sprintf("Spower::Spower(Spower::p_r(gen_fun = <sum and difference of paired scores>%s)) (the Pitman-Morgan test)",
      if (alternative == "two_sided") "" else sprintf(", alternative = \"%s\"", spower_alternative(template, alternative)))
  } else if (rank_correlation(spec)) {
    sprintf("Spower::Spower(Spower::p_r(method = \"%s\"%s%s))", spec$target_test$method,
      if (shaped_rank_correlation(spec)) sprintf(", gen_fun = <%s>", score_shape_words(spec$population$score_shape)) else "",
      if (alternative == "two_sided") "" else sprintf(", alternative = \"%s\"", spower_alternative(template, alternative)))
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
  if (identical(spec$template, "oneway_within")) {
    # Friedman's test: powerkit's own experiment, p_friedman() (see
    # friedman_scores()), with the condition means in SD units.
    means <- as.numeric(unlist(pop$means)) / pop$sd
    shape <- pop$score_shape %||% "normal"
    return(list(
      experiment = "p_friedman", own = TRUE, rank = "friedman", draw = draw,
      args = function(n) list(n = n, means = means, r = pop$r, shape = shape)
    ))
  }
  # The aligned rank transform ANOVA: powerkit's own experiment, p_art(),
  # on the cells of a two-factor between-participants design
  # (art_scores()). The experiment's n is one share of the total: each
  # cell has n times its share (options > cell_ratio; 1 each for equal
  # cells).
  if (aligned_rank_test(spec)) {
    cells <- art_cells(spec)
    shape <- pop$score_shape %||% "normal"
    term <- art_term(spec$target_test$effect)
    return(list(
      experiment = "p_art", own = TRUE, rank = "art", draw = draw,
      args = function(n) list(n = n / sum(cells$n.ratios), means = cells$means, sds = cells$sds, n.ratios = cells$n.ratios, shape = shape, term = term)
    ))
  }
  if (identical(spec$template, "oneway_between")) {
    k <- length(spec$variables$A$levels)
    means <- as.numeric(unlist(pop$means)) / pop$sd
    gen <- function(n, k, n.ratios, means, ...) {
      lapply(seq_len(k), function(g) means[g] + draw(n * n.ratios[g]))
    }
    # The Jonckheere-Terpstra test: powerkit's own experiment,
    # p_jonckheere(), on the same groups as the Kruskal-Wallis test.
    # The experiment's n is one share of the total: each group has n times
    # its share (options > group_ratio; 1 each for equal groups).
    if (jonckheere_test(spec)) {
      w <- trend_group_shares(spec)
      return(list(
        experiment = "p_jonckheere", own = TRUE, rank = "jonckheere", draw = draw,
        args = function(n) list(n = n / sum(w), k = k, means = means, gen_fun = gen, n.ratios = w)
      ))
    }
    return(list(
      experiment = "p_kruskal.test", rank = "kruskal", draw = draw,
      args = function(n) list(n = n / k, k = k, means = means, gen_fun = gen)
    ))
  }
  # The Brunner-Munzel test: powerkit's own experiment, p_brunner_munzel(),
  # on two groups of the chosen shape that may differ in spread
  # (brunner_munzel_scores()).
  if (brunner_munzel_test(spec)) {
    shape <- pop$score_shape %||% "normal"
    sd_ratio <- pop$sd_ratio %||% 1
    return(list(
      experiment = "p_brunner_munzel", own = TRUE, rank = "brunner_munzel", draw = draw,
      args = function(n) list(n = first_group(n), n2_n1 = ratio, d = pop$d, sd_ratio = sd_ratio, shape = shape)
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
  if (identical(test$experiment, "p_art")) {
    return("Spower::Spower(p_art()) (ARTool::art(), ARTool::artlm(), car::Anova(type = 3))")
  }
  if (identical(template, "oneway_within")) {
    return("Spower::Spower(p_friedman()) (stats::friedman.test())")
  }
  if (identical(test$experiment, "p_brunner_munzel")) {
    return(sprintf("Spower::Spower(p_brunner_munzel(%s)) (brunnermunzel::brunnermunzel.test())",
      if (alternative == "two_sided") "" else sprintf("alternative = \"%s\"", spower_alternative(template, alternative))))
  }
  if (identical(test$experiment, "p_jonckheere")) {
    return(sprintf("Spower::Spower(p_jonckheere(%s)) (PMCMRplus::jonckheereTest())",
      if (alternative == "two_sided") "" else sprintf("alternative = \"%s\"", alternative)))
  }
  type <- switch(template, one_sample_t = "one.sample", paired_t = "paired", independent_t = "two.sample", NULL)
  arguments <- c(
    if (!is.null(type)) sprintf("type = \"%s\"", type),
    if (alternative != "two_sided") sprintf("alternative = \"%s\"", spower_alternative(template, alternative))
  )
  sprintf("Spower::Spower(Spower::%s(%s))", test$experiment, paste(arguments, collapse = ", "))
}

# A rank correlation on scores of a shape other than normal.
shaped_rank_correlation <- function(spec) {
  rank_correlation(spec) && !identical(spec$population$score_shape %||% "normal", "normal")
}

# Two scores in the chosen shape (SD 1) with Pearson's correlation r: the
# second is r times the first plus sqrt(1 - r^2) times another draw of the
# same shape. The first is drawn first. Its shape is exactly the one
# chosen; the second's is close to it (a mixture of the two draws).
shaped_pair_scores <- function(n, r, shape, ...) {
  draw <- score_shape_sampler(shape)
  x <- draw(n)
  data.frame(x = x, y = r * x + sqrt(1 - r^2) * draw(n))
}

# Scores for Friedman's test: n people in k conditions, each score the
# condition's mean (in SD units), the person's own level (normal, variance
# r) and a deviation in the chosen shape (variance 1 - r). Every score then
# has SD 1, any two conditions correlate r, and conditions differ only by
# a shift. The person's levels are drawn first, then each condition's
# deviations in turn (the exported script draws in the same order).
friedman_scores <- function(n, means, r, shape) {
  draw <- score_shape_sampler(shape)
  person <- sqrt(r) * stats::rnorm(n)
  y <- vapply(seq_along(means), function(j) means[j] + person + sqrt(1 - r) * draw(n), numeric(n))
  matrix(y, nrow = n)
}

# Spower experiment for Friedman's test: its p-value on friedman_scores().
p_friedman <- function(n, means, r, shape) {
  stats::friedman.test(friedman_scores(n, means, r, shape))$p.value
}

# Spower experiment for the Jonckheere-Terpstra test: k groups of
# n * n.ratios drawn as for the Kruskal-Wallis test (gen_fun), in the order
# of the factor's levels, and PMCMRplus's p-value for a trend across them
# (its default: the normal approximation, no continuity correction).
# "greater" is a rise across the groups in order. The scores and their
# groups are passed as x and g: jonckheereTest() given a list of groups
# ignores its `alternative` argument and is always two-sided
# (docs/upstream-questions.md).
# The two groups of the Brunner-Munzel test: n in group 1 and n * n2_n1 in
# group 2, in the chosen shape; group 2's SD is sd_ratio times group 1's,
# with the two SDs scaled so that sqrt((SD1^2 + SD2^2) / 2) is 1, and its
# mean d higher (d is in those pooled SD units).
brunner_munzel_scores <- function(n, n2_n1, d, sd_ratio, shape) {
  draw <- score_shape_sampler(shape)
  sd1 <- sqrt(2 / (1 + sd_ratio^2))
  list(first = sd1 * draw(n), second = d + sd_ratio * sd1 * draw(round(n * n2_n1)))
}

# The check run's row for the SD ratio, compared on the log scale with a
# standard error that allows for the scores' kurtosis (the variance of a
# log SD is about (kurtosis - 1) / (4 n)), since heavy-tailed scores make
# an SD vary far more than normal ones do.
sd_ratio_row <- function(first, second, specified) {
  kurtosis <- function(x) mean((x - mean(x))^4) / stats::var(x)^2
  se_log <- sqrt((kurtosis(first) - 1) / (4 * length(first)) + (kurtosis(second) - 1) / (4 * length(second)))
  ratio <- stats::sd(second) / stats::sd(first)
  data.frame(
    parameter = "SD of group 2 over SD of group 1", specified = specified, recovered = ratio,
    ok = abs(log(ratio) - log(specified)) <= 5 * se_log
  )
}

# Spower experiment for the Brunner-Munzel test: its p-value on
# brunner_munzel_scores(). brunnermunzel.test(x, y) estimates
# P(X < Y) + P(X = Y) / 2, and "less" is the alternative in which group 2
# (y) tends to be higher (its help; checked in test-backend-rank.R).
p_brunner_munzel <- function(n, n2_n1, d, sd_ratio, shape, alternative = "two.sided") {
  g <- brunner_munzel_scores(n, n2_n1, d, sd_ratio, shape)
  brunnermunzel::brunnermunzel.test(g$first, g$second, alternative = alternative)$p.value
}

# The cells of a two-factor between-participants design for the aligned
# rank transform, as a x b matrices (rows: A's levels): the means and SDs
# in the outcome's units (one SD is used in every cell) and each cell's
# share of the sample (options > cell_ratio, or 1 each).
art_cells <- function(spec) {
  pop <- spec$population
  to_matrix <- function(x) do.call(rbind, lapply(x, function(row) as.numeric(unlist(row))))
  means <- to_matrix(pop$means)
  sds <- if (is.list(pop$sd) || length(pop$sd) > 1) to_matrix(pop$sd) else matrix(pop$sd, nrow(means), ncol(means))
  ratios <- if (is.null(spec$options$cell_ratio)) matrix(1, nrow(means), ncol(means)) else to_matrix(spec$options$cell_ratio)
  list(means = means, sds = sds, n.ratios = ratios)
}

# The term of ARTool's model for the effect tested.
art_term <- function(effect) {
  switch(effect, main_effect_A = "A", main_effect_B = "B", interaction = "A:B")
}

# Scores for the aligned rank transform: n times its share in each cell,
# each the cell's mean plus its SD times a draw of the chosen shape (SD 1).
# Cells are drawn row by row (A's first level with each of B's levels in
# turn, then A's second level, ...); the exported script draws in the same
# order.
art_scores <- function(n, means, sds, n.ratios, shape) {
  draw <- score_shape_sampler(shape)
  cells <- expand.grid(b = seq_len(ncol(means)), a = seq_len(nrow(means)))
  rows <- lapply(seq_len(nrow(cells)), function(i) {
    a <- cells$a[i]
    b <- cells$b[i]
    size <- round(n * n.ratios[a, b])
    data.frame(A = a, B = b, Y = means[a, b] + sds[a, b] * draw(size))
  })
  data <- do.call(rbind, rows)
  data$A <- factor(data$A, levels = seq_len(nrow(means)))
  data$B <- factor(data$B, levels = seq_len(ncol(means)))
  data
}

# Spower experiment for the aligned rank transform ANOVA: ARTool's art()
# aligns and ranks the scores for every effect, artlm() gives the linear
# model for the effect tested (sum-to-zero contrasts, its default), and
# car's Anova() its Type III F test, the row anova() on art()'s model
# reports (checked in test-backend-art.R).
p_art <- function(n, means, sds, n.ratios, shape, term) {
  data <- art_scores(n, means, sds, n.ratios, shape)
  model <- ARTool::art(Y ~ A * B, data = data)
  car::Anova(ARTool::artlm(model, term), type = 3)[term, "Pr(>F)"]
}

# Data for negative binomial regression: n people; the predictor x is a
# standard normal score, or a yes/no group (0, 1) with round(n * x_prob) in
# the second group, placed at random. With another predictor (r2_other
# above 0), z is drawn so that x's R-squared on z is r2_other, and has no
# effect of its own on the count, as the Poisson formula assumes. Each
# count is negative binomial with mean exposure * base_rate *
# rate_ratio^x and variance mu + dispersion * mu^2 (stats::rnbinom() with
# size = 1 / dispersion). Drawn in this order: x, z, the counts.
negative_binomial_data <- function(n, rate_ratio, base_rate, dispersion, exposure, binary, x_prob, r2_other) {
  x <- if (binary) sample(rep(c(0, 1), c(n - round(n * x_prob), round(n * x_prob)))) else stats::rnorm(n)
  data <- data.frame(x = x)
  if (r2_other > 0) {
    standard <- if (binary) (x - mean(x)) / stats::sd(x) else x
    data$z <- sqrt(r2_other) * standard + sqrt(1 - r2_other) * stats::rnorm(n)
  }
  mu <- exposure * base_rate * rate_ratio^x
  data$y <- stats::rnbinom(n, size = 1 / dispersion, mu = mu)
  data$exposure <- exposure
  data
}

# Spower experiment for negative binomial regression: MASS's glm.nb() of
# the counts on x (and z), with log(exposure) as offset, and the Wald z
# test of x's coefficient; one-sided in the direction asked ("greater":
# the rate rises with x).
p_negative_binomial <- function(n, rate_ratio, base_rate, dispersion, exposure, binary, x_prob, r2_other, alternative = "two.sided") {
  data <- negative_binomial_data(n, rate_ratio, base_rate, dispersion, exposure, binary, x_prob, r2_other)
  formula <- if (r2_other > 0) y ~ x + z + offset(log(exposure)) else y ~ x + offset(log(exposure))
  fit <- MASS::glm.nb(formula, data = data)
  z <- stats::coef(summary(fit))["x", "z value"]
  switch(alternative,
    two.sided = 2 * stats::pnorm(-abs(z)),
    greater = stats::pnorm(z, lower.tail = FALSE),
    less = stats::pnorm(z)
  )
}

# Data for the test of one regression coefficient: n people, the tested
# predictor x and the model's other predictors (z1, z2, ...) independent
# standard normal scores. Only the part of x the other predictors don't
# share affects the test of its coefficient, which partial_r2 describes, so
# they are drawn unrelated to x and with no effect. The outcome is
# slope * x + error, with slope = sqrt(partial_r2 / (1 - partial_r2)) in
# units of the error's SD (Cohen's f). The error has the chosen shape
# (score_shape_sampler()) and variance exp(g x - g^2 / 2), which averages
# 1, with g = log(variance_ratio) / 2: variance_ratio is the error variance
# one SD above x's mean over the variance one SD below. For quantile
# regression the error is moved so that its quantile is 0, so the
# outcome's quantile rises by the slope per SD of x; otherwise its mean is
# 0. Drawn in this order: x, the other predictors, the error.
coefficient_data <- function(n, partial_r2, predictors, variance_ratio = 1, shape = "normal", quantile = NULL) {
  x <- stats::rnorm(n)
  data <- data.frame(x = x)
  for (j in seq_len(predictors - 1)) data[[paste0("z", j)]] <- stats::rnorm(n)
  error <- score_shape_sampler(shape)(n)
  if (!is.null(quantile)) error <- error - score_shape_quantile(shape, quantile)
  g <- log(variance_ratio) / 2
  data$y <- sqrt(partial_r2 / (1 - partial_r2)) * x + exp((g * x - g^2 / 2) / 2) * error
  data
}

# The quantile of score_shape_sampler()'s distributions.
score_shape_quantile <- function(shape, quantile) {
  switch(
    shape %||% "normal",
    normal = stats::qnorm(quantile),
    skewed = (stats::qchisq(quantile, df = 10) - 10) / sqrt(20),
    heavy_tailed = stats::qt(quantile, df = 3) / sqrt(3)
  )
}

# Spower experiment for one regression coefficient: the outcome regressed
# on x and the other predictors, and the p-value of x's coefficient (two-
# sided). Least squares with heteroscedasticity-consistent standard errors
# (car's linearHypothesis() with white.adjust "hc3" or "hc4", car's
# hccm()), or quantile regression (quantreg's rq() at the quantile, tested
# by summary.rq(se = "nid"), which allows the spread to change with x).
p_coefficient <- function(n, partial_r2, predictors, variance_ratio = 1, shape = "normal", method = "ols_hc3", quantile = 0.5) {
  quantile_fit <- identical(method, "quantile_regression")
  data <- coefficient_data(n, partial_r2, predictors, variance_ratio, shape, if (quantile_fit) quantile)
  if (quantile_fit) {
    fit <- quantreg::rq(y ~ ., tau = quantile, data = data)
    return(stats::coef(summary(fit, se = "nid"))["x", "Pr(>|t|)"])
  }
  fit <- stats::lm(y ~ ., data = data)
  car::linearHypothesis(fit, "x = 0", white.adjust = sub("ols_", "", method))[2, "Pr(>F)"]
}

p_jonckheere <- function(n, k, means, gen_fun, n.ratios = rep(1, k), alternative = "two.sided") {
  groups <- gen_fun(n, k, n.ratios, means)
  g <- factor(rep(seq_len(k), lengths(groups)))
  unname(PMCMRplus::jonckheereTest(unlist(groups), g, alternative = alternative)$p.value)
}

# Spower experiment for the Cochran-Armitage test: each group's count of
# "yes" out of its size (n * n.ratios), drawn from its proportion, and
# stats::prop.trend.test()'s p-value for a linear trend along the groups'
# scores. prop.trend.test() is two-sided (its statistic is the square of
# the Cochran-Armitage z statistic); a one-sided test halves its p-value
# when the observed trend goes the way predicted ("greater": the
# proportion rises with the scores) and otherwise gives 1 minus half of it,
# the one-sided p-value of z.
cochran_armitage_counts <- function(n, proportions, n.ratios = rep(1, length(proportions))) {
  stats::rbinom(length(proportions), n * n.ratios, proportions)
}

p_cochran_armitage <- function(n, proportions, scores, n.ratios = rep(1, length(proportions)), alternative = "two.sided") {
  sizes <- n * n.ratios
  yes <- cochran_armitage_counts(n, proportions, n.ratios)
  p <- stats::prop.trend.test(yes, sizes, score = scores)$p.value
  if (identical(alternative, "two.sided")) {
    return(p)
  }
  rising <- sum(yes * (scores - sum(sizes * scores) / sum(sizes))) > 0
  if (rising == identical(alternative, "greater")) p / 2 else 1 - p / 2
}

# Relative group sizes in a trend test: options > group_ratio, or 1 per
# group.
trend_group_shares <- function(spec) {
  if (unequal_groups(spec)) {
    return(group_ratio_vector(spec))
  }
  rep(1, length(if (proportion_trend(spec)) spec$variables$X$levels else spec$variables$A$levels))
}

# Paired scores for the Pitman-Morgan test, returned as their sum and
# their difference (first minus second); `r` is p_r()'s own argument and
# unused here.
pitman_morgan_scores <- function(n, r, var1, var2, rho12, ...) {
  z1 <- stats::rnorm(n)
  z2 <- rho12 * z1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  x <- sqrt(var1) * z1
  y <- sqrt(var2) * z2
  data.frame(x = x + y, y = x - y)
}

# Each group's SD for Welch's F: population > sds, or sd in every group.
welch_sds <- function(spec) {
  pop <- spec$population
  if (is.null(pop$sds)) rep(pop$sd, length(spec$variables$A$levels)) else as.numeric(unlist(pop$sds))
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
  head <- if (isTRUE(inputs$own)) as.name(inputs$experiment) else call("::", as.name("Spower"), as.name(inputs$experiment))
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
  if (identical(spec$template, "factorial")) {
    return(logistic_factorial_check_run(spec, args, seed))
  }
  # Negative binomial regression: one large data set, fitted as each
  # simulated one is; the rate ratio, base rate and dispersion recovered.
  if (identical(spec$template, "single_predictor_count")) {
    data <- call_backend("Spower", with_seed(seed, do.call(negative_binomial_data, args[setdiff(names(args), "alternative")])))
    formula <- if (args$r2_other > 0) y ~ x + z + offset(log(exposure)) else y ~ x + offset(log(exposure))
    # glm.nb() warns when theta grows without bound (almost no
    # overdispersion); the rows below still show it.
    fit <- call_backend("MASS", suppressWarnings(MASS::glm.nb(formula, data = data)))
    est <- stats::coef(summary(fit))
    rows <- rbind(
      check_run_rows("rate ratio for X (checked on the log scale)", log(args$rate_ratio), est["x", "Estimate"], est["x", "Std. Error"]),
      check_run_rows("base rate (checked on the log scale)", log(args$base_rate), est["(Intercept)", "Estimate"], est["(Intercept)", "Std. Error"]),
      check_run_rows("dispersion k (1 / theta, checked on the log scale)", log(args$dispersion), -log(fit$theta), fit$SE.theta / fit$theta)
    )
    rows$specified[1:3] <- c(args$rate_ratio, args$base_rate, args$dispersion)
    rows$recovered[1:3] <- exp(c(est["x", "Estimate"], est["(Intercept)", "Estimate"], -log(fit$theta)))
    if (args$r2_other > 0) {
      r2 <- stats::cor(data$x, data$z)^2
      rows <- rbind(rows, data.frame(parameter = "R-squared of X on the other predictor", specified = args$r2_other, recovered = r2,
        ok = abs(r2 - args$r2_other) <= 5 * 2 * sqrt(args$r2_other) * (1 - args$r2_other) / sqrt(nrow(data))))
    }
    return(rows)
  }
  # One regression coefficient: one large data set, fitted as each
  # simulated one is; the slope and the change in spread recovered.
  if (identical(spec$template, "single_coefficient")) {
    return(coefficient_check_run(args, seed))
  }
  # A trend in proportions: each group's proportion from one large draw.
  if (identical(spec$template, "proportion_trend")) {
    yes <- call_backend("Spower", with_seed(seed, cochran_armitage_counts(args$n, args$proportions, args$n.ratios)))
    sizes <- args$n * args$n.ratios
    p_hat <- yes / sizes
    return(check_run_rows(
      sprintf("proportion of %s in %s", spec$variables$Y$label %||% "yes", unlist(spec$variables$X$levels)),
      args$proportions, p_hat, sqrt(p_hat * (1 - p_hat) / sizes)
    ))
  }
  generator <- inputs$generate %||% getExportedValue("Spower", inputs$generator)
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
    # Pitman-Morgan: the paired scores back from their sum and difference.
    paired_variances = {
      x <- (data[[1]] + data[[2]]) / 2
      y <- (data[[1]] - data[[2]]) / 2
      size <- nrow(data)
      r <- stats::cor(x, y)
      rows <- check_run_rows(
        c("variance of the first measurement", "variance of the second measurement"),
        c(pop$var1, pop$var2), c(stats::var(x), stats::var(y)),
        c(pop$var1, pop$var2) * sqrt(2 / (size - 1))
      )
      cor_row <- check_run_rows("correlation between the measurements", pop$r, r, NA)
      cor_row$ok <- abs(atanh(r) - atanh(pop$r)) <= 5 / sqrt(size - 3)
      rbind(rows, cor_row)
    },
    # MANOVA: each group's mean on each outcome, each outcome's SD within
    # the groups, and the correlation between each pair of outcomes.
    manova = {
      means <- manova_means(spec)
      sds <- as.numeric(unlist(pop$sds))
      size <- args$n
      y <- as.matrix(data[, -1])
      groups <- split(seq_len(nrow(data)), data$group)
      centred <- do.call(rbind, lapply(groups, function(i) scale(y[i, , drop = FALSE], scale = FALSE)))
      within_sd <- sqrt(colSums(centred^2) / (nrow(y) - length(groups)))
      within_r <- stats::cor(centred)[upper.tri(diag(ncol(y)))]
      cells <- expand.grid(g = seq_len(nrow(means)), j = seq_len(ncol(means)))
      r_rows <- check_run_rows("correlation between two outcomes (average)", pop$r, mean(within_r), NA)
      r_rows$ok <- abs(atanh(mean(within_r)) - atanh(pop$r)) <= 5 / sqrt(nrow(y) - 3)
      rbind(
        check_run_rows(sprintf("mean of Y%d in group %d", cells$j, cells$g), means[cbind(cells$g, cells$j)],
          vapply(seq_len(nrow(cells)), function(i) mean(y[groups[[cells$g[i]]], cells$j[i]]), numeric(1)),
          sds[cells$j] / sqrt(size)),
        check_run_rows(sprintf("SD of Y%d within groups", seq_along(sds)), sds, within_sd, sds / sqrt(2 * (nrow(y) - length(groups)))),
        r_rows
      )
    },
    # Hotelling's T-squared, one group: each outcome's mean and SD, and
    # the correlation between each pair of outcomes.
    hotelling_one = {
      y <- as.matrix(data)
      means <- as.numeric(unlist(pop$means))
      sds <- as.numeric(unlist(pop$sds))
      within_r <- stats::cor(y)[upper.tri(diag(ncol(y)))]
      r_rows <- check_run_rows("correlation between two outcomes (average)", pop$r, mean(within_r), NA)
      r_rows$ok <- abs(atanh(mean(within_r)) - atanh(pop$r)) <= 5 / sqrt(nrow(y) - 3)
      rbind(
        check_run_rows(sprintf("mean of Y%d", seq_along(means)), means, colMeans(y), sds / sqrt(nrow(y))),
        check_run_rows(sprintf("SD of Y%d", seq_along(sds)), sds, apply(y, 2, stats::sd), sds / sqrt(2 * (nrow(y) - 1))),
        r_rows
      )
    },
    # Welch's F: each group's mean and SD, in the means' units.
    oneway_between = {
      by_group <- split(data$DV, data$group)
      means <- as.numeric(unlist(pop$means))
      sds <- welch_sds(spec)
      sizes <- unname(lengths(by_group))
      k <- length(means)
      rbind(
        check_run_rows(paste("mean of group", seq_len(k)), means,
          vapply(by_group, mean, numeric(1), USE.NAMES = FALSE), sds / sqrt(sizes)),
        check_run_rows(paste("SD of group", seq_len(k)), sds,
          vapply(by_group, stats::sd, numeric(1), USE.NAMES = FALSE), sds / sqrt(2 * (sizes - 1)))
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
  if (identical(spec$template, "oneway_within")) {
    y <- call_backend("Spower", with_seed(seed, friedman_scores(args$n, args$means, args$r, args$shape)))
    within_r <- stats::cor(y)[upper.tri(diag(ncol(y)))]
    r_row <- check_run_rows("correlation between two conditions (average)", args$r, mean(within_r), NA)
    r_row$ok <- abs(atanh(mean(within_r)) - atanh(args$r)) <= 5 / sqrt(nrow(y) - 3)
    return(rbind(
      check_run_rows(sprintf("mean of %s (SD units)", unlist(spec$variables$A$levels)), args$means, colMeans(y), 1 / sqrt(nrow(y))),
      check_run_rows(sprintf("SD in %s (SD units)", unlist(spec$variables$A$levels)), rep(1, ncol(y)), apply(y, 2, stats::sd),
        rep(1 / sqrt(2 * (nrow(y) - 1)), ncol(y))),
      r_row
    ))
  }
  if (aligned_rank_test(spec)) {
    data <- call_backend("Spower", with_seed(seed, art_scores(args$n, args$means, args$sds, args$n.ratios, args$shape)))
    a_levels <- unlist(spec$variables$A$levels)
    b_levels <- unlist(spec$variables$B$levels)
    cells <- expand.grid(b = seq_along(b_levels), a = seq_along(a_levels))
    labels <- sprintf("mean of %s, %s", a_levels[cells$a], b_levels[cells$b])
    index <- cbind(cells$a, cells$b)
    by_cell <- split(data$Y, list(data$A, data$B))
    recovered <- vapply(seq_len(nrow(cells)), function(i) mean(by_cell[[paste(cells$a[i], cells$b[i], sep = ".")]]), numeric(1))
    sizes <- vapply(seq_len(nrow(cells)), function(i) length(by_cell[[paste(cells$a[i], cells$b[i], sep = ".")]]), numeric(1))
    return(check_run_rows(labels, args$means[index], recovered, args$sds[index] / sqrt(sizes)))
  }
  if (brunner_munzel_test(spec)) {
    g <- call_backend("Spower", with_seed(seed, brunner_munzel_scores(args$n, args$n2_n1, args$d, args$sd_ratio, args$shape)))
    # The scores are drawn with a pooled SD of exactly 1, so the difference
    # in means is d itself; its SE uses each group's own SD.
    sd1 <- sqrt(2 / (1 + args$sd_ratio^2))
    se_d <- sqrt(sd1^2 / length(g$first) + (args$sd_ratio * sd1)^2 / length(g$second))
    return(rbind(
      check_run_rows("d (group 2 minus group 1, in the pooled SD the scores are drawn with)", pop$d, mean(g$second) - mean(g$first), se_d),
      sd_ratio_row(g$first, g$second, args$sd_ratio)
    ))
  }
  if (identical(spec$template, "oneway_between")) {
    groups <- call_backend("Spower", with_seed(seed, args$gen_fun(args$n, args$k, args$n.ratios %||% rep(1, args$k), args$means)))
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

# A two-factor design with a yes/no outcome: the cells (one row per
# combination of A's and B's levels, A varying fastest, both factors with
# sum-to-zero contrasts), the logistic model's coefficients that give each
# cell's proportion exactly (the saturated model, solved on the log-odds
# scale), the Wald test's hypotheses for the effect tested, and the design
# for n participants, the same number in every cell.
logistic_factorial_design <- function(spec) {
  a <- length(spec$variables$A$levels)
  b <- length(spec$variables$B$levels)
  cells <- expand.grid(A = factor(seq_len(a)), B = factor(seq_len(b)))
  stats::contrasts(cells$A) <- stats::contr.sum(a)
  stats::contrasts(cells$B) <- stats::contr.sum(b)
  p <- logistic_factorial_probabilities(spec)
  model <- stats::model.matrix(~ A * B, cells)
  betas <- drop(solve(model, stats::qlogis(p[cbind(as.integer(cells$A), as.integer(cells$B))])))
  pattern <- switch(spec$target_test$effect, main_effect_A = "^A[0-9]+$", main_effect_B = "^B[0-9]+$", interaction = ":")
  tested <- grep(pattern, names(betas), value = TRUE)
  list(
    cells = cells,
    betas = betas,
    tested = tested,
    test = paste(tested, "= 0"),
    X = function(n) {
      X <- cells[rep(seq_len(nrow(cells)), each = n / nrow(cells)), , drop = FALSE]
      rownames(X) <- NULL
      X
    }
  )
}

# The cell proportions as a matrix: rows are A's levels, columns B's.
logistic_factorial_probabilities <- function(spec) {
  rows <- spec$population$probabilities
  matrix(as.numeric(unlist(rows)), nrow = length(rows), byrow = TRUE)
}

# Check run: one large data set drawn and fitted by p_glm(); each cell's
# proportion of 'yes' must match the spec within 5 standard errors.
logistic_factorial_check_run <- function(spec, args, seed) {
  fit <- call_backend("Spower", with_seed(seed, quietly(do.call(
    Spower::p_glm, c(args, list(return_analysis = TRUE))
  ))))
  data <- fit$model
  p <- logistic_factorial_probabilities(spec)
  a_levels <- unlist(spec$variables$A$levels)
  b_levels <- unlist(spec$variables$B$levels)
  cells <- expand.grid(i = seq_len(nrow(p)), j = seq_len(ncol(p)))
  recovered <- vapply(seq_len(nrow(cells)), function(k) {
    mean(data$y[as.integer(data$A) == cells$i[k] & as.integer(data$B) == cells$j[k]])
  }, numeric(1))
  per_cell <- nrow(data) / nrow(cells)
  specified <- p[cbind(cells$i, cells$j)]
  check_run_rows(
    sprintf("P(yes), %s %s, %s %s", spec$variables$A$label, a_levels[cells$i], spec$variables$B$label, b_levels[cells$j]),
    specified, recovered, sqrt(specified * (1 - specified) / per_cell)
  )
}

# MANOVA: the means as a matrix, one row per group and one column per
# outcome.
manova_means <- function(spec) {
  do.call(rbind, lapply(spec$population$means, function(row) as.numeric(unlist(row))))
}

# Multivariate normal scores for a one-way MANOVA: n people in each group,
# with that group's means, the outcomes' SDs and one correlation r between
# every pair of outcomes (SimDesign::rmvnorm(), as Spower's own generators
# use). Returns a data frame with the group and one column per outcome.
# Arguments for the test (a two-factor MANOVA's `b` and `term`) are ignored.
manova_scores <- function(n, means, sds, r, ...) {
  p <- ncol(means)
  correlation <- matrix(r, p, p)
  diag(correlation) <- 1
  sigma <- diag(sds, p) %*% correlation %*% diag(sds, p)
  y <- do.call(rbind, lapply(seq_len(nrow(means)), function(g) SimDesign::rmvnorm(n, means[g, ], sigma)))
  colnames(y) <- paste0("Y", seq_len(p))
  data.frame(group = factor(rep(seq_len(nrow(means)), each = n)), y)
}

# Multivariate normal scores for one group: n people with the expected
# means, the outcomes' SDs and one correlation r between every pair
# (SimDesign::rmvnorm(), as manova_scores()). `mu0` is the experiment's,
# not the data's. Returns a data frame with one column per outcome.
hotelling_one_scores <- function(n, means, mu0, sds, r) {
  y <- manova_scores(n, matrix(means, nrow = 1), sds, r)[, -1, drop = FALSE]
  rownames(y) <- NULL
  y
}

# Spower experiment for one-sample Hotelling's T-squared: the p-value of
# the test that the scores' mean vector equals mu0, by the multivariate
# test of the intercept of lm(scores - mu0 ~ 1) (stats::anova(), Pillai's
# trace). With one group every multivariate statistic gives the same
# exact F test, Hotelling's T-squared with p and n - p df.
p_hotelling_one <- function(n, means, mu0, sds, r) {
  differences <- sweep(as.matrix(hotelling_one_scores(n, means, mu0, sds, r)), 2, mu0)
  stats::anova(stats::lm(differences ~ 1), test = "Pillai")[1, "Pr(>F)"]
}

# Spower experiment for a MANOVA: the p-value of Pillai's trace from
# stats::manova() on scores drawn by manova_scores(). With two groups every
# MANOVA statistic gives the same, exact test (Hotelling's T-squared). With
# two factors (`b` levels of B, the groups being A's levels by B's, B
# fastest), the model is A * B and `term` ("A", "B" or "A:B") is tested;
# the groups are equal in size, so the sequential and the adjusted tests
# are the same.
p_manova <- function(n, means, sds, r, b = 1, term = "A") {
  data <- manova_scores(n, means, sds, r)
  y <- as.matrix(data[, -1])
  if (b == 1) {
    fit <- stats::manova(y ~ data$group)
    return(summary(fit, test = "Pillai")$stats[1, "Pr(>F)"])
  }
  group <- as.integer(data$group)
  A <- factor((group - 1) %/% b + 1)
  B <- factor((group - 1) %% b + 1)
  fit <- stats::manova(y ~ A * B)
  summary(fit, test = "Pillai")$stats[term, "Pr(>F)"]
}

# The term of A * B a two-factor MANOVA tests.
manova_term <- function(spec) {
  switch(spec$target_test$effect, main_effect_A = "A", main_effect_B = "B", interaction = "A:B")
}

# Check run for one regression coefficient: the slope of x in error-SD
# units (by least squares, or quantile regression at the quantile, with
# its "nid" standard error; quantreg's Frisch-Newton method, method = "fn",
# which its help advises for large data sets), and the change in the error's spread,
# log(variance_ratio), as twice the slope of the log squared residuals on
# x (its standard error from that regression).
coefficient_check_run <- function(args, seed) {
  quantile_fit <- identical(args$method, "quantile_regression")
  data <- call_backend("Spower", with_seed(seed, coefficient_data(
    args$n, args$partial_r2, args$predictors, args$variance_ratio, args$shape, if (quantile_fit) args$quantile
  )))
  slope <- sqrt(args$partial_r2 / (1 - args$partial_r2))
  ls_fit <- stats::lm(y ~ ., data = data)
  est <- if (quantile_fit) {
    stats::coef(call_backend("quantreg", summary(quantreg::rq(y ~ ., tau = args$quantile, data = data, method = "fn"), se = "nid")))["x", 1:2]
  } else {
    stats::coef(summary(ls_fit))["x", 1:2]
  }
  spread <- stats::coef(summary(stats::lm(log(stats::residuals(ls_fit)^2) ~ data$x)))[2, 1:2]
  rows <- rbind(
    check_run_rows(
      if (quantile_fit) sprintf("slope of the outcome's %s quantile per SD of X, in error SDs", format(args$quantile)) else "slope per SD of X, in error SDs (Cohen's f)",
      slope, est[[1]], est[[2]]
    ),
    check_run_rows("error variance ratio, 1 SD above X's mean over 1 SD below (checked on the log scale)", log(args$variance_ratio), 2 * spread[[1]], 2 * spread[[2]])
  )
  rows$specified[2] <- args$variance_ratio
  rows$recovered[2] <- exp(2 * spread[[1]])
  rows
}
