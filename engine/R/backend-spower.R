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
    # Interrupted time series: n is the number of points after the
    # intervention, and gls()'s time grows with the cube of the series'
    # length, so the search stops at 240 (20 years of monthly data). With
    # the points before fixed, a level change's power can level off below
    # the target however many points come after.
    n_max = if (identical(spec$template, "its")) 240L,
    n_max_message = if (identical(spec$template, "its")) paste(
      "The target power of %s isn't reached with up to %s time points after the intervention.",
      "A change in level or slope is measured against the trend before the intervention, so with the points before it fixed,",
      "power levels off however long the series runs after it. More points before the intervention, a larger change or less noise",
      "would raise it; check the power at a given number of points to see where it levels off."),
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
      # p_art() calls ARTool's art() and artlm(), then car's Anova();
      # p_art_within() calls aov() through artlm(), or with unequal groups
      # car's Anova() with pbkrtest's Kenward-Roger F tests.
      if (aligned_rank_test(spec)) c("ARTool", if (!art_within(spec) || mixed_unequal_groups(spec)) "car", if (art_within(spec) && mixed_unequal_groups(spec)) c("lme4", "pbkrtest")),
      # p_negative_binomial() fits MASS's glm.nb().
      if (negative_binomial_test(spec)) "MASS",
      # p_zero_inflated() fits pscl's zeroinfl().
      if (zero_inflated_test(spec)) "pscl",
      # p_coefficient() tests with car's linearHypothesis() and hccm(), or
      # fits quantreg's rq().
      if (robust_regression(spec)) {
        if (identical(spec$target_test$method, "quantile_regression")) "quantreg" else "car"
      },
      # p_permanova() calls vegan's adonis2().
      if (permanova_test(spec)) "vegan",
      # p_efa() fits psych's fa(), whose oblimin rotation is GPArotation's.
      if (identical(spec$template, "efa")) c("psych", "GPArotation"),
      # p_riclpm() simulates and fits each study with powRICLPM, which
      # fits the model with lavaan.
      if (identical(spec$template, "riclpm")) c("powRICLPM", "lavaan"),
      # p_its() simulates each series with PITS and fits nlme's gls().
      if (identical(spec$template, "its")) c("PITS", "nlme"),
      # p_lpa() fits mclust's models.
      if (identical(spec$template, "lpa")) "mclust",
      # p_multinomial() fits nnet's multinom().
      if (identical(spec$template, "multinomial")) "nnet"
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
        c(list(
          n = first_group(n), d = -pop$d, type = "two.sample", n2_n1 = ratio,
          var.equal = spec$target_test$method == "student_t"
        ), if (unequal_welch(spec)) list(sds = welch_population_sds(spec)))
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
    # PERMANOVA: powerkit's own experiment, p_permanova(), draws the
    # groups' scores (permanova_scores(): multivariate normal, or of the
    # chosen shape) and returns vegan's adonis2() permutation test of the
    # effect, on Euclidean distances between the standardised outcomes.
    manova = if (permanova_test(spec)) list(
      experiment = "p_permanova", own = TRUE, generator = "permanova_scores", generate = permanova_scores,
      args = function(n) {
        c(list(n = n / length(pop$means), means = manova_means(spec), sds = as.numeric(unlist(pop$sds)), r = pop$r,
          shape = pop$score_shape %||% "normal"),
          if (!is.null(spec$variables$B)) list(b = length(spec$variables$B$levels), term = manova_term(spec)))
      }
    ) else list(
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
    # Zero-inflated Poisson or negative binomial regression: powerkit's own
    # experiment, p_zero_inflated(), draws the predictor, any other
    # predictor, the counts and the extra zeros (zero_inflated_data()) and
    # returns the test of the predictor in pscl's zeroinfl(): the Wald z
    # test of its count coefficient or its zero coefficient, or the
    # likelihood-ratio test of both.
    single_predictor_count = if (zero_inflated_test(spec)) list(
      experiment = "p_zero_inflated", own = TRUE,
      args = function(n) {
        list(
          n = n, rate_ratio = pop$rate_ratio, base_rate = pop$base_rate, zero_prob = pop$zero_prob,
          zero_odds_ratio = pop$zero_odds_ratio %||% 1, dispersion = pop$dispersion %||% 0,
          exposure = pop$mean_exposure %||% 1, binary = identical(spec$variables$X$type, "binary"),
          x_prob = pop$x_prob %||% 0.5, r2_other = pop$r2_other_predictors %||% 0,
          part = spec$target_test$effect
        )
      }
    ) else list(
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
    # Multinomial logistic regression: powerkit's own experiment,
    # p_multinomial(), draws the predictor, any other predictor and the
    # outcome's category (multinomial_data()) and returns the likelihood-
    # ratio test of the predictor (all its coefficients) or the Wald z test
    # of one category against the first, from nnet's multinom().
    # Moderation with a yes/no outcome: powerkit's own experiment,
    # p_logistic_interaction(), draws X, W and the outcome
    # (logistic_interaction_data()) and returns the Wald z test of the
    # X x W coefficient in glm().
    # Moderation by groups: powerkit's own experiment, p_group_moderator(),
    # draws each group's X and Y (group_moderator_data()) and returns the F
    # test of the X x A terms in lm().
    # d' in two conditions or groups: powerkit's own experiment, p_dprime(),
    # draws each person's hits and false alarms (dprime_data()) and returns
    # the t-test of the estimated d' values.
    # Latent profiles: powerkit's own experiment, p_lpa(), draws people
    # from the profiles (lpa_data()), fits mclust's models with 1 to
    # profiles + 1 profiles and returns 0 when the BIC chooses the right
    # number, 1 when it doesn't, so Spower's share of "p-values" below its
    # level is the chance of finding it.
    # Exploratory factor analysis: powerkit's own experiment, p_efa(),
    # draws people from the factor model (efa_data()), fits psych's fa()
    # and returns 0 when every factor's loadings are recovered (Tucker's
    # congruence at least the level asked), 1 when not.
    # Random-intercept cross-lagged panel model: powerkit's experiment,
    # p_riclpm(), has powRICLPM simulate one study and fit the model, and
    # returns the Wald test's p-value for the lagged effect asked about.
    riclpm = list(
      experiment = "p_riclpm", own = TRUE,
      args = function(n) {
        list(n = n, waves = pop$waves, icc = pop$icc, ri_cor = pop$ri_correlation %||% 0,
          ar_x = pop$autoregressive_x, ar_y = pop$autoregressive_y,
          cl_xy = pop$cross_lagged_xy, cl_yx = pop$cross_lagged_yx,
          within_cor = pop$within_correlation %||% 0, reliability = pop$reliability %||% 1,
          constraints = pop$constraints %||% "none", effect = spec$target_test$effect)
      }
    ),
    # Interrupted time series: powerkit's experiment, p_its(), has PITS
    # simulate the series and fits the segmented regression with AR(1)
    # errors by nlme's gls() (REML by default; PITS's own maximum-likelihood
    # test on request). n is the number of time points after the
    # intervention.
    its = list(
      experiment = "p_its", own = TRUE,
      args = function(n) {
        list(n = n, n_pre = pop$n_pre, baseline = pop$baseline %||% 0, pre_trend = pop$pre_trend %||% 0,
          level = pop$level_change %||% 0, slope = pop$slope_change %||% 0, sigma = pop$sigma, rho = pop$rho %||% 0,
          test = spec$target_test$effect, method = spec$target_test$method)
      }
    ),
    efa = list(
      experiment = "p_efa", own = TRUE,
      args = function(n) {
        list(n = n, factors = pop$factors, items = pop$items_per_factor, loading = pop$loading,
          phi = pop$factor_correlation %||% 0, congruence = spec$target_test$congruence %||% 0.95)
      }
    ),
    lpa = list(
      experiment = "p_lpa", own = TRUE,
      args = function(n) {
        k <- pop$profiles
        list(n = n, profiles = k, indicators = pop$indicators, separation = pop$separation,
          shares = as.numeric(unlist(pop$shares %||% rep(1 / k, k))))
      }
    ),
    dprime = list(
      experiment = "p_dprime", own = TRUE,
      args = function(n) {
        list(
          n = n, d1 = as.numeric(pop$dprime[[1]]), d2 = as.numeric(pop$dprime[[2]]),
          trials_signal = pop$trials_signal, trials_noise = pop$trials_noise,
          sd_d = pop$sd_dprime %||% 0, r_d = pop$r_dprime %||% 0.5,
          criterion = pop$criterion %||% 0, sd_c = pop$sd_criterion %||% 0,
          within = identical(spec$variables$G$type, "within_factor")
        )
      }
    ),
    group_moderator = list(
      experiment = "p_group_moderator", own = TRUE,
      args = function(n) {
        w <- trend_group_shares(spec)
        k <- length(spec$variables$A$levels)
        list(n = n, r = as.numeric(unlist(pop$r_xy)), means = as.numeric(unlist(pop$means %||% rep(0, k))), group_ratio = w)
      }
    ),
    interaction = list(
      experiment = "p_logistic_interaction", own = TRUE,
      args = function(n) {
        list(
          n = n, base_prob = pop$base_prob, or_x = pop$odds_ratio_x, or_w = pop$odds_ratio_w, or_xw = pop$odds_ratio_xw,
          x_binary = identical(spec$variables$X$type, "binary"), w_binary = identical(spec$variables$W$type, "binary"),
          x_prob = pop$x_prob %||% 0.5, w_prob = pop$w_prob %||% 0.5, r = pop$r_xw %||% 0
        )
      }
    ),
    multinomial = {
      coefficients <- multinomial_coefficients(spec)
      list(
        experiment = "p_multinomial", own = TRUE,
        args = function(n) {
          c(
            list(
              n = n, intercepts = coefficients$intercepts, slopes = coefficients$slopes,
              binary = identical(spec$variables$X$type, "binary"), x_prob = pop$x_prob %||% 0.5,
              r2_other = pop$r2_other_predictors %||% 0, test = spec$target_test$method
            ),
            if (identical(spec$target_test$method, "wald_z")) list(category = multinomial_category(spec))
          )
        }
      )
    },
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
  # The latent profile experiment returns 0 for success and 1 for failure,
  # so any level between them counts the successes.
  test$alpha <- spec$target_test$alpha %||% 0.5
  test$alternative <- alternative
  test$description <- if (rank_test(spec)) {
    rank_test_description(test, template, alternative)
  } else if (identical(template, "factorial")) {
    "Spower::Spower(Spower::p_glm(family = binomial()), Wald test of the effect's coefficients)"
  } else if (identical(template, "riclpm")) {
    sprintf("Spower::Spower(p_riclpm()) (powRICLPM simulates each study and fits the random-intercept cross-lagged panel model with lavaan; the Wald z test of the lagged effect%s)",
      if (alternative == "two_sided") "" else sprintf(", one-sided (%s)", alternative))
  } else if (identical(template, "its")) {
    sprintf("Spower::Spower(p_its()) (PITS's simulate_its_data(); nlme's gls() with AR(1) errors, %s; the %s)",
      if (identical(spec$target_test$method, "gls_ml")) "maximum likelihood, PITS's fit_its_model()" else "REML",
      switch(spec$target_test$effect, level = "t test of the level change", slope = "t test of the slope change",
        both = if (identical(spec$target_test$method, "gls_ml")) "likelihood-ratio test of both" else "F test of both"))
  } else if (identical(template, "efa")) {
    "Spower::Spower(p_efa()) (psych's fa() with its defaults, minimum residual and oblimin rotation; every factor's loadings recovered with Tucker's congruence at the level asked)"
  } else if (identical(template, "lpa")) {
    "Spower::Spower(p_lpa()) (mclust's latent profile models with 1 to k + 1 profiles, equal variances and local independence, the BIC choosing among them)"
  } else if (identical(template, "dprime")) {
    sprintf("Spower::Spower(p_dprime()) (each person's d' from hits and false alarms with the log-linear correction, then %s)",
      if (identical(spec$variables$G$type, "within_factor")) "the paired t-test" else "Student's t-test")
  } else if (identical(template, "group_moderator")) {
    "Spower::Spower(p_group_moderator()) (stats::lm() of Y on X * A, the F test of the X x A terms)"
  } else if (identical(template, "interaction") && identical(spec$design, "logistic_regression")) {
    sprintf("Spower::Spower(p_logistic_interaction(%s)) (stats::glm(family = binomial()), the Wald z test of the X x W coefficient)",
      if (alternative == "two_sided") "" else sprintf("alternative = \"%s\"", alternative))
  } else if (identical(template, "multinomial")) {
    if (identical(spec$target_test$method, "wald_z")) {
      sprintf("Spower::Spower(p_multinomial()) (nnet::multinom(), the Wald z test of X's coefficient for %s against %s)",
        multinomial_level(spec, multinomial_category(spec)), multinomial_level(spec, 1))
    } else {
      "Spower::Spower(p_multinomial()) (nnet::multinom(), the likelihood-ratio test of X, all categories together)"
    }
  } else if (identical(template, "single_predictor_count") && zero_inflated_test(spec)) {
    sprintf("Spower::Spower(p_zero_inflated(%s)) (pscl::zeroinfl(dist = \"%s\"), %s)",
      if (alternative == "two_sided") "" else sprintf("alternative = \"%s\"", alternative),
      if (negative_binomial_counts(spec)) "negbin" else "poisson",
      switch(spec$target_test$effect,
        zero_odds_ratio = "the Wald z test of the predictor in the zero part",
        rate_and_zero = "the likelihood-ratio test of the predictor in both parts",
        "the Wald z test of the predictor in the count part"
      ))
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
  } else if (identical(template, "manova") && permanova_test(spec)) {
    sprintf("Spower::Spower(p_permanova()) (vegan::adonis2(method = \"euclidean\", permutations = 999) on the standardised outcomes%s)",
      if (is.null(spec$variables$B)) "" else sprintf(", the sequential test of %s", manova_term(spec)))
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
  # The aligned rank transform with a within-participants factor:
  # powerkit's own experiment, p_art_within(), on correlated scores of the
  # chosen shape (art_within_scores()), the participants an error term.
  if (art_within(spec)) {
    cells <- art_cells(spec)
    shape <- pop$score_shape %||% "normal"
    term <- art_term(spec$target_test$effect)
    within_both <- identical(spec$template, "factorial_within")
    groups <- if (within_both) 1 else nrow(cells$means)
    r <- art_within_r(spec)
    ratio <- if (mixed_unequal_groups(spec)) group_ratio_vector(spec) else rep(1, groups)
    type3 <- mixed_unequal_groups(spec)
    return(list(
      experiment = "p_art_within", own = TRUE, rank = "art_within", draw = draw,
      args = function(n) {
        list(n = n, means = cells$means, sds = cells$sds, r = r, group_ratio = ratio, shape = shape, term = term,
          within_both = within_both, type3 = type3)
      }
    ))
  }
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
  if (identical(test$experiment, "p_art_within")) {
    return(if (isTRUE(test$args(100)$type3)) {
      "Spower::Spower(p_art_within()) (ARTool::art() with a random intercept for each person, ARTool::artlm(), car::Anova(type = 3) with Kenward-Roger F tests)"
    } else {
      "Spower::Spower(p_art_within()) (ARTool::art() with the participants as an error term, ARTool::artlm(), aov())"
    })
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

# The aligned rank transform with a within-participants factor ----------------
#
# The correlation between any two of a person's scores: one per group (a
# 2 x 2 mixed design may give one per level of A), or one for everyone
# (spec checks require every pair's to be the same).
art_within_r <- function(spec) {
  r <- as.numeric(unlist(spec$population$r))
  if (identical(spec$template, "2x2_mixed")) rep_len(r, length(spec$variables$A$levels)) else r[1]
}

# Scores for the aligned rank transform with a within-participants factor,
# drawn as Friedman's test draws them (friedman_scores()): each score is
# the cell's mean plus its SD times (sqrt(r) times the person's own level,
# standard normal, plus sqrt(1 - r) times a deviation of the chosen shape),
# so that every cell has its SD and any two of a person's scores correlate
# r. A mixed design (A between, B within): the groups have n split in the
# ratio given (mixed_group_n()), and in each group in turn the people's
# levels are drawn, then the deviations in each level of B in turn. Both
# factors within (within_both): n people, their levels first, then the
# deviations in each cell, row by row (A's first level with each level of
# B, then A's second level, ...). Long format: id, A, B, Y.
art_within_scores <- function(n, means, sds, r, group_ratio, shape, within_both = FALSE) {
  draw <- score_shape_sampler(shape)
  k <- nrow(means)
  m <- ncol(means)
  person_scores <- function(size, first_id, r, cells) {
    level <- stats::rnorm(size)
    do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
      a <- cells$a[i]
      b <- cells$b[i]
      data.frame(id = first_id + seq_len(size), A = a, B = b,
        Y = means[a, b] + sds[a, b] * (sqrt(r) * level + sqrt(1 - r) * draw(size)))
    }))
  }
  data <- if (within_both) {
    person_scores(n, 0, r[1], expand.grid(b = seq_len(m), a = seq_len(k)))
  } else {
    sizes <- mixed_group_n(n, group_ratio)
    first <- c(0, cumsum(sizes))
    do.call(rbind, lapply(seq_len(k), function(a) {
      person_scores(sizes[a], first[a], r[min(a, length(r))], data.frame(a = a, b = seq_len(m)))
    }))
  }
  data$id <- factor(data$id)
  data$A <- factor(data$A, levels = seq_len(k))
  data$B <- factor(data$B, levels = seq_len(m))
  data
}

# The p-value of `term` in the analysis of variance aov() fits with an
# error term (an "aovlist"): the stratum that holds the term.
art_aov_p <- function(fit, term) {
  for (stratum in summary(fit)) {
    table <- stratum[[1]]
    at <- match(term, trimws(rownames(table)))
    if (!is.na(at)) {
      return(table[at, "Pr(>F)"])
    }
  }
  NA_real_
}

# Spower experiment for the aligned rank transform with a within-
# participants factor. ARTool's art() aligns and ranks the scores for every
# effect, with the participants as an error term (Error(id)), and artlm()
# gives aov()'s repeated measures ANOVA of the ranks for the effect tested.
# With equal groups its F test is the one ARTool's documented model, a
# random intercept for each person ((1 | id)) analysed by its anova() with
# Kenward-Roger F tests, gives (checked in test-backend-art-within.R), and
# much faster. With unequal groups (type3), aov()'s sequential sums of
# squares would differ from Type III for B's main effect, so that model is
# used: art() with (1 | id), artlm() and car's Anova(type = 3) with
# Kenward-Roger F tests.
p_art_within <- function(n, means, sds, r, group_ratio, shape, term, within_both = FALSE, type3 = FALSE) {
  data <- art_within_scores(n, means, sds, r, group_ratio, shape, within_both)
  if (type3) {
    model <- ARTool::art(Y ~ A * B + (1 | id), data = data)
    return(car::Anova(ARTool::artlm(model, term), type = 3, test.statistic = "F")[term, "Pr(>F)"])
  }
  model <- ARTool::art(Y ~ A * B + Error(id), data = data)
  art_aov_p(ARTool::artlm(model, term), term)
}

# Check run: one large data set drawn as the simulation draws it; each
# cell's mean and, per group, the correlation between a person's first two
# scores.
art_within_check_run <- function(spec, args, seed) {
  data <- call_backend("Spower", with_seed(seed, art_within_scores(args$n, args$means, args$sds, args$r, args$group_ratio, args$shape, args$within_both)))
  a_levels <- unlist(spec$variables$A$levels)
  b_levels <- unlist(spec$variables$B$levels)
  cells <- expand.grid(b = seq_along(b_levels), a = seq_along(a_levels))
  by_cell <- split(data$Y, list(data$A, data$B))
  cell <- function(i) by_cell[[paste(cells$a[i], cells$b[i], sep = ".")]]
  index <- cbind(cells$a, cells$b)
  rows <- check_run_rows(sprintf("mean of %s, %s", a_levels[cells$a], b_levels[cells$b]), args$means[index],
    vapply(seq_len(nrow(cells)), function(i) mean(cell(i)), numeric(1)),
    args$sds[index] / sqrt(vapply(seq_len(nrow(cells)), function(i) length(cell(i)), numeric(1))))
  groups <- if (args$within_both) list(all = data) else split(data, data$A)
  for (g in seq_along(groups)) {
    d <- groups[[g]]
    first <- d$Y[d$B == 1 & (args$within_both | TRUE) & d$A == d$A[1]]
    second <- d$Y[d$B == 2 & d$A == d$A[1]]
    r_hat <- stats::cor(first, second)
    r_spec <- args$r[min(g, length(args$r))]
    rows <- rbind(rows, check_run_rows(
      sprintf("correlation between a person's scores%s", if (args$within_both) "" else sprintf(" in %s", a_levels[g])),
      r_spec, r_hat, (1 - r_spec^2) / sqrt(length(first))
    ))
  }
  rows
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

# Zero-inflated count regression ---------------------------------------------
#
# Data for zero-inflated Poisson or negative binomial regression: n people,
# the predictor x and any other predictor z drawn as for negative binomial
# regression (negative_binomial_data()); then each person's count, Poisson
# (dispersion 0) or negative binomial with mean exposure * base_rate *
# rate_ratio^x; then whether they are an extra zero, with probability
# plogis(qlogis(zero_prob) + log(zero_odds_ratio) * x), whose count is set
# to 0. Drawn in this order: x, z, the counts, the extra zeros.
zero_inflated_data <- function(n, rate_ratio, base_rate, zero_prob, zero_odds_ratio, dispersion, exposure, binary, x_prob, r2_other) {
  x <- if (binary) sample(rep(c(0, 1), c(n - round(n * x_prob), round(n * x_prob)))) else stats::rnorm(n)
  data <- data.frame(x = x)
  if (r2_other > 0) {
    standard <- if (binary) (x - mean(x)) / stats::sd(x) else x
    data$z <- sqrt(r2_other) * standard + sqrt(1 - r2_other) * stats::rnorm(n)
  }
  mu <- exposure * base_rate * rate_ratio^x
  counts <- if (dispersion > 0) stats::rnbinom(n, size = 1 / dispersion, mu = mu) else stats::rpois(n, mu)
  extra <- stats::runif(n) < stats::plogis(stats::qlogis(zero_prob) + log(zero_odds_ratio) * x)
  data$y <- ifelse(extra, 0, counts)
  data$exposure <- exposure
  data
}

# The model pscl's zeroinfl() fits: the count part on x (and z) with
# log(exposure) as offset, and the zero part on the same predictors
# (zeroinfl()'s default when one formula is given), or on none (the
# reduced model for the joint test).
zero_inflated_formula <- function(r2_other, with_x = TRUE) {
  predictors <- paste(c(if (with_x) "x", if (r2_other > 0) "z"), collapse = " + ")
  if (!nzchar(predictors)) predictors <- "1"
  stats::as.formula(sprintf("y ~ %s + offset(log(exposure)) | %s", predictors, predictors))
}

# Spower experiment for zero-inflated count regression: pscl's zeroinfl()
# of the counts, and the test of x. "rate_ratio": the Wald z test of x's
# coefficient in the count part; "zero_odds_ratio": in the zero part
# (one-sided in the direction asked: "greater", the rate or the odds of
# an extra zero rising with x); "rate_and_zero": the likelihood-ratio test
# of both against the model without x (2 df). A data set with no zeros or
# no counts above 0, or whose fit fails, counts as not significant
# (p = 1), as it would for the study.
p_zero_inflated <- function(n, rate_ratio, base_rate, zero_prob, zero_odds_ratio, dispersion, exposure, binary, x_prob, r2_other,
                            part = "rate_ratio", alternative = "two.sided") {
  data <- zero_inflated_data(n, rate_ratio, base_rate, zero_prob, zero_odds_ratio, dispersion, exposure, binary, x_prob, r2_other)
  if (all(data$y == 0) || all(data$y > 0)) {
    return(1)
  }
  dist <- if (dispersion > 0) "negbin" else "poisson"
  fit <- tryCatch(suppressWarnings(pscl::zeroinfl(zero_inflated_formula(r2_other), data = data, dist = dist)), error = function(e) NULL)
  if (is.null(fit)) {
    return(1)
  }
  if (identical(part, "rate_and_zero")) {
    reduced <- tryCatch(suppressWarnings(pscl::zeroinfl(zero_inflated_formula(r2_other, with_x = FALSE), data = data, dist = dist)), error = function(e) NULL)
    if (is.null(reduced)) {
      return(1)
    }
    p <- stats::pchisq(2 * (as.numeric(stats::logLik(fit)) - as.numeric(stats::logLik(reduced))), df = 2, lower.tail = FALSE)
    return(if (is.finite(p)) p else 1)
  }
  coefficients <- summary(fit)$coefficients[[if (identical(part, "zero_odds_ratio")) "zero" else "count"]]
  z <- coefficients["x", "z value"]
  if (!is.finite(z)) {
    return(1)
  }
  switch(alternative,
    two.sided = 2 * stats::pnorm(-abs(z)),
    greater = stats::pnorm(z, lower.tail = FALSE),
    less = stats::pnorm(z)
  )
}

# Check run: one large data set, fitted as each simulated one is; the
# rate ratio, base rate, share of extra zeros, their odds ratio and (for
# negative binomial counts) the dispersion recovered.
zero_inflated_check_run <- function(args, seed) {
  data <- call_backend("Spower", with_seed(seed, do.call(zero_inflated_data, args[setdiff(names(args), c("alternative", "part"))])))
  dist <- if (args$dispersion > 0) "negbin" else "poisson"
  fit <- call_backend("pscl", suppressWarnings(pscl::zeroinfl(zero_inflated_formula(args$r2_other), data = data, dist = dist)))
  s <- summary(fit)$coefficients
  rows <- rbind(
    check_run_rows("rate ratio for X (checked on the log scale)", log(args$rate_ratio), s$count["x", 1], s$count["x", 2]),
    check_run_rows("base rate (checked on the log scale)", log(args$base_rate), s$count["(Intercept)", 1], s$count["(Intercept)", 2]),
    check_run_rows("share of extra zeros at the starting point (checked on the log-odds scale)", stats::qlogis(args$zero_prob), s$zero["(Intercept)", 1], s$zero["(Intercept)", 2]),
    check_run_rows("odds ratio for X of being an extra zero (checked on the log scale)", log(args$zero_odds_ratio), s$zero["x", 1], s$zero["x", 2])
  )
  rows$specified <- c(args$rate_ratio, args$base_rate, args$zero_prob, args$zero_odds_ratio)
  rows$recovered <- c(exp(s$count["x", 1]), exp(s$count["(Intercept)", 1]), stats::plogis(s$zero["(Intercept)", 1]), exp(s$zero["x", 1]))
  if (args$dispersion > 0) {
    theta <- s$count["Log(theta)", ]
    k <- check_run_rows("dispersion k (1 / theta, checked on the log scale)", log(args$dispersion), -theta[[1]], theta[[2]])
    k$specified <- args$dispersion
    k$recovered <- exp(-theta[[1]])
    rows <- rbind(rows, k)
  }
  if (args$r2_other > 0) {
    r2 <- stats::cor(data$x, data$z)^2
    rows <- rbind(rows, data.frame(parameter = "R-squared of X on the other predictor", specified = args$r2_other, recovered = r2,
      ok = abs(r2 - args$r2_other) <= 5 * 2 * sqrt(args$r2_other) * (1 - args$r2_other) / sqrt(nrow(data))))
  }
  rows
}

# Moderation by a factor with three or more groups ---------------------------
#
# Data: the groups have n split in the ratio given (mixed_group_n()); in
# each group in turn, X is standard normal and Y = mean_g + r_g X +
# sqrt(1 - r_g^2) e, so that within the group Y has SD 1 and correlates r_g
# with X. Drawn in this order, group by group: X, then the errors.
group_moderator_data <- function(n, r, means, group_ratio) {
  sizes <- mixed_group_n(n, group_ratio)
  rows <- lapply(seq_along(sizes), function(g) {
    x <- stats::rnorm(sizes[g])
    data.frame(a = g, x = x, y = means[g] + r[g] * x + sqrt(1 - r[g]^2) * stats::rnorm(sizes[g]))
  })
  data <- do.call(rbind, rows)
  data$a <- factor(data$a, levels = seq_along(sizes))
  data
}

# Spower experiment: the F test comparing lm(y ~ x * a) with lm(y ~ x + a),
# the test of the X x A terms (k - 1 df).
p_group_moderator <- function(n, r, means, group_ratio) {
  data <- group_moderator_data(n, r, means, group_ratio)
  stats::anova(stats::lm(y ~ x + a, data = data), stats::lm(y ~ x * a, data = data))[2, "Pr(>F)"]
}

# Check run: one large data set; each group's correlation and mean, and
# its share of the sample.
group_moderator_check_run <- function(spec, args, seed) {
  data <- call_backend("Spower", with_seed(seed, group_moderator_data(args$n, args$r, args$means, args$group_ratio)))
  levels <- unlist(spec$variables$A$levels)
  by_group <- split(data, data$a)
  r_hat <- vapply(by_group, function(d) stats::cor(d$x, d$y), numeric(1))
  sizes <- vapply(by_group, nrow, numeric(1))
  m_hat <- vapply(by_group, function(d) mean(d$y), numeric(1))
  rbind(
    check_run_rows(sprintf("correlation of X and Y in %s", levels), args$r, r_hat, (1 - args$r^2) / sqrt(sizes)),
    check_run_rows(sprintf("mean of Y in %s (SD units)", levels), args$means, m_hat, 1 / sqrt(sizes)),
    data.frame(parameter = "share of people in each group (largest difference)", specified = 0,
      recovered = max(abs(sizes / sum(sizes) - args$group_ratio / sum(args$group_ratio))),
      ok = max(abs(sizes / sum(sizes) - args$group_ratio / sum(args$group_ratio))) < 1e-3)
  )
}

# Random-intercept cross-lagged panel model ------------------------------------
#
# powRICLPM (Mulder, 2023) generates each study and fits the model: X is
# its variable A and Y its variable B. Its Phi has the outcomes in rows and
# the predictors in columns, so the effect of X on Y is Phi[2, 1]. With no
# constraints (powRICLPM's default) each wave's lagged effects are
# estimated freely, and the effect tested is the one from the first wave
# to the second, as in powRICLPM's documentation; with constraints =
# "lagged" they are held equal over time, and all waves' estimates are one.
riclpm_phi <- function(ar_x, ar_y, cl_xy, cl_yx) matrix(c(ar_x, cl_yx, cl_xy, ar_y), 2, byrow = TRUE)

riclpm_parameter <- function(effect) {
  switch(effect, cross_lagged_xy = "wB2~wA1", cross_lagged_yx = "wA2~wB1",
    autoregressive_x = "wA2~wA1", autoregressive_y = "wB2~wB1")
}

# One powRICLPM study: its estimate and standard error of each parameter
# (with one replication, its "average" is the estimate and "SEAvg" the
# standard error), or NULL when the model did not converge or gave an
# inadmissible solution, which powRICLPM discards.
riclpm_fit <- function(n, waves, icc, ri_cor, ar_x, ar_y, cl_xy, cl_yx, within_cor, reliability, constraints) {
  # powRICLPM refuses an integer where it expects a double (a 0 read from
  # JSON is an integer), so every value is passed as a double.
  num <- as.numeric
  out <- tryCatch(suppressMessages(suppressWarnings(powRICLPM::powRICLPM(
    sample_size = as.integer(n), time_points = as.integer(waves), ICC = num(icc), RI_cor = num(ri_cor),
    Phi = riclpm_phi(num(ar_x), num(ar_y), num(cl_xy), num(cl_yx)), within_cor = num(within_cor),
    reliability = num(reliability), reps = 1, constraints = constraints))),
    error = function(e) NULL)
  if (is.null(out)) return(NULL)
  est <- out$conditions[[1]]$estimates
  if (is.null(est) || !nrow(est) || all(is.na(est$SEAvg))) NULL else est
}

# Spower experiment: the Wald z test of the lagged effect (lavaan's test),
# from its estimate and standard error; NA when the fit failed.
p_riclpm <- function(n, waves, icc, ri_cor, ar_x, ar_y, cl_xy, cl_yx, within_cor, reliability, constraints,
                     effect, alternative = "two.sided") {
  est <- riclpm_fit(n, waves, icc, ri_cor, ar_x, ar_y, cl_xy, cl_yx, within_cor, reliability, constraints)
  if (is.null(est)) return(NA_real_)
  row <- est[est$parameter == riclpm_parameter(effect), ]
  if (!nrow(row) || !is.finite(row$SEAvg[1]) || row$SEAvg[1] <= 0) return(NA_real_)
  z <- row$average[1] / row$SEAvg[1]
  switch(alternative, two.sided = 2 * stats::pnorm(-abs(z)), greater = stats::pnorm(z, lower.tail = FALSE),
    less = stats::pnorm(z))
}

# Check run: one very large study; the four lagged effects' estimates
# against the population values.
riclpm_check_run <- function(args, seed) {
  n <- 20000
  est <- call_backend("powRICLPM", with_seed(seed, do.call(riclpm_fit,
    c(args[setdiff(names(args), c("n", "effect", "alternative"))], list(n = n)))))
  if (is.null(est)) stop("The check run's model did not converge.", call. = FALSE)
  labels <- c(ar_x = "autoregressive effect of X", ar_y = "autoregressive effect of Y",
    cl_xy = "cross-lagged effect of X on Y", cl_yx = "cross-lagged effect of Y on X")
  effects <- c(ar_x = "autoregressive_x", ar_y = "autoregressive_y", cl_xy = "cross_lagged_xy", cl_yx = "cross_lagged_yx")
  do.call(rbind, lapply(names(labels), function(a) {
    row <- est[est$parameter == riclpm_parameter(effects[[a]]), ]
    check_run_rows(labels[[a]], args[[a]], row$average[1], row$SEAvg[1])
  }))
}

# Interrupted time series -------------------------------------------------------
#
# PITS (de Lorenzo, 2026) generates each series: the segmented regression
# y_t = baseline + pre_trend t + level_change D_t + slope_change T*_t + e_t,
# D_t = 1 after the intervention, T*_t the time since it, and AR(1) errors
# whose SD is sigma. PITS's own test, fit_its_model(), fits nlme's gls() by
# maximum likelihood; in short series it rejects too often when there is no
# effect (upstream-questions.md, PITS question 1), so powerkit fits the
# same model by REML by default (the maintainer's decision of 6 November
# 2026, judgement-calls E8) and reports the Type I error at the planned
# length beside the power (its_type1()).
its_data <- function(n, n_pre, baseline, pre_trend, level, slope, sigma, rho) {
  PITS::simulate_its_data(n_pre = as.integer(n_pre), n_post = as.integer(n), baseline = baseline,
    level_change = level, slope_change = slope, sigma = sigma, rho = rho, pre_trend = pre_trend)
}

its_p_value <- function(data, test, method) {
  if (identical(method, "gls_ml")) return(PITS::fit_its_model(data, test))
  fit <- tryCatch(nlme::gls(y ~ time + D + time_after, data = data, correlation = nlme::corAR1(form = ~time),
    method = "REML"), error = function(e) NULL)
  if (is.null(fit)) return(NA_real_)
  switch(test,
    level = summary(fit)$tTable["D", "p-value"],
    slope = summary(fit)$tTable["time_after", "p-value"],
    both = stats::anova(fit, Terms = c("D", "time_after"))[["p-value"]]
  )
}

# Spower experiment: the test's p-value for one simulated series.
p_its <- function(n, n_pre, baseline, pre_trend, level, slope, sigma, rho, test, method, alternative = "two.sided") {
  its_p_value(its_data(n, n_pre, baseline, pre_trend, level, slope, sigma, rho), test, method)
}

# The Type I error at the planned length: the same series with no level or
# slope change, as many as the power used, under the run's seed.
its_type1 <- function(spec, n, nrep, seed) {
  if (!identical(spec$template, "its") || is.null(n) || is.na(n)) return(NULL)
  args <- spower_inputs(spec)$args(n)
  args$level <- 0
  args$slope <- 0
  p <- call_backend("PITS", with_seed(seed, vapply(seq_len(nrep), function(i) do.call(p_its, args), numeric(1))))
  ok <- p[!is.na(p)]
  rate <- mean(ok < spec$target_test$alpha)
  list(n = n, alpha = spec$target_test$alpha, rate = rate, mcse = sqrt(rate * (1 - rate) / length(ok)),
    nrep = length(ok), method = spec$target_test$method)
}

# Check run: one long series (400 points on each side: gls()'s time grows
# with the cube of the length); the level change, slope change and
# autocorrelation estimated by gls against the values given.
its_check_run <- function(args, seed) {
  n <- 400
  d <- call_backend("PITS", with_seed(seed, its_data(n, n, args$baseline, args$pre_trend, args$level, args$slope, args$sigma, args$rho)))
  fit <- nlme::gls(y ~ time + D + time_after, data = d, correlation = nlme::corAR1(form = ~time), method = "REML")
  est <- summary(fit)$tTable
  phi <- unname(stats::coef(fit$modelStruct$corStruct, unconstrained = FALSE))
  rbind(
    check_run_rows("level change", args$level, est["D", "Value"], est["D", "Std.Error"]),
    check_run_rows("slope change", args$slope, est["time_after", "Value"], est["time_after", "Std.Error"]),
    check_run_rows("autocorrelation", args$rho, phi, sqrt((1 - args$rho^2) / (2 * n)))
  )
}

# Exploratory factor analysis ---------------------------------------------------
#
# Data: the common factor model with simple structure: items_per_factor
# items load `loading` on each factor and 0 on the others, the factors
# correlate phi, and each item's unique variance makes its variance 1.
# Scores are multivariate normal with that covariance.
efa_loadings <- function(factors, items, loading) kronecker(diag(factors), matrix(loading, items, 1))

efa_data <- function(n, factors, items, loading, phi) {
  lambda <- efa_loadings(factors, items, loading)
  correlation <- matrix(phi, factors, factors)
  diag(correlation) <- 1
  sigma <- lambda %*% correlation %*% t(lambda)
  diag(sigma) <- 1
  matrix(stats::rnorm(n * nrow(sigma)), n) %*% chol(sigma)
}

# Tucker's congruence of each true factor with the estimated factor matched
# to it: the one-to-one matching that makes the congruences (in absolute
# value, as a factor's sign is arbitrary) largest in total.
efa_matched_congruence <- function(estimated, true) {
  tucker <- abs(crossprod(estimated, true) / sqrt(outer(colSums(estimated^2), colSums(true^2))))
  k <- ncol(true)
  orders <- if (k == 1) matrix(1, 1, 1) else efa_permutations(k)
  totals <- apply(orders, 1, function(o) sum(tucker[cbind(o, seq_len(k))]))
  best <- orders[which.max(totals), ]
  tucker[cbind(best, seq_len(k))]
}

efa_permutations <- function(k) {
  if (k == 1) return(matrix(1, 1, 1))
  smaller <- efa_permutations(k - 1)
  do.call(rbind, lapply(seq_len(k), function(i) {
    cbind(i, matrix(setdiff(seq_len(k), i)[smaller], nrow(smaller)))
  }))
}

# Spower experiment: 0 when every factor's loadings are recovered with
# congruence of at least `congruence`, 1 otherwise (including a fit that
# fails).
p_efa <- function(n, factors, items, loading, phi, congruence) {
  x <- efa_data(n, factors, items, loading, phi)
  fit <- tryCatch(suppressWarnings(psych::fa(x, nfactors = factors, rotate = if (factors > 1) "oblimin" else "none",
    fm = "minres", warnings = FALSE)), error = function(e) NULL)
  if (is.null(fit)) return(1)
  matched <- efa_matched_congruence(unclass(fit$loadings), efa_loadings(factors, items, loading))
  if (all(matched >= congruence)) 0 else 1
}

# Check run: one large data set; the correlation between two items of the
# same factor, and between items of two factors, against the model's.
efa_check_run <- function(args, seed) {
  n <- 20000
  x <- call_backend("Spower", with_seed(seed, efa_data(n, args$factors, args$items, args$loading, args$phi)))
  same <- stats::cor(x[, 1], x[, 2])
  rows <- check_run_rows("correlation of two items of the same factor", args$loading^2, same, (1 - args$loading^4) / sqrt(n))
  if (args$factors > 1) {
    across <- stats::cor(x[, 1], x[, args$items + 1])
    expected <- args$loading^2 * args$phi
    rows <- rbind(rows, check_run_rows("correlation of items of two factors", expected, across, (1 - expected^2) / sqrt(n)))
  }
  rbind(rows, check_run_rows("variance of an item", 1, stats::var(x[, 1]), sqrt(2 / n)))
}

# Latent profile analysis -----------------------------------------------------
#
# Data: each person belongs to profile k with probability shares[k] (drawn
# independently, so the profiles' sizes vary from study to study, as in the
# published simulations); within a profile their indicators are independent
# normal scores with SD 1 and mean (k - 1) * separation on every indicator
# (Tein, Coxe and Cham, 2013). Drawn in this order: the profiles, then the
# scores.
lpa_data <- function(n, profiles, indicators, separation, shares) {
  g <- sample.int(profiles, n, replace = TRUE, prob = shares)
  x <- matrix(stats::rnorm(n * indicators), n) + (g - 1) * separation
  list(profile = g, x = x)
}

# Spower experiment: 0 when the BIC of mclust's EEI models (equal
# variances, local independence) with 1 to profiles + 1 profiles is best at
# the true number, 1 otherwise (Spower counts the 0s as successes).
p_lpa <- function(n, profiles, indicators, separation, shares) {
  data <- lpa_data(n, profiles, indicators, separation, shares)
  bic <- mclust::mclustBIC(data$x, G = seq_len(profiles + 1), modelNames = "EEI", verbose = FALSE)
  chosen <- which.max(bic[, "EEI"])
  if (length(chosen) == 1 && chosen == profiles) 0 else 1
}

# Check run: one large data set; each profile's share and its mean on the
# first indicator.
lpa_check_run <- function(args, seed) {
  data <- call_backend("Spower", with_seed(seed, do.call(lpa_data, args[setdiff(names(args), "alternative")])))
  k <- args$profiles
  n <- length(data$profile)
  shares <- tabulate(data$profile, k) / n
  means <- vapply(seq_len(k), function(j) mean(data$x[data$profile == j, 1]), numeric(1))
  rbind(
    check_run_rows(sprintf("share of people in profile %d", seq_len(k)), args$shares, shares, sqrt(args$shares * (1 - args$shares) / n)),
    check_run_rows(sprintf("mean of the first indicator in profile %d (SD units)", seq_len(k)), (seq_len(k) - 1) * args$separation, means,
      1 / sqrt(pmax(1, tabulate(data$profile, k))))
  )
}

# d' in two conditions or groups (signal detection) ---------------------------
#
# Data: the equal-variance Gaussian signal detection model (Macmillan and
# Creelman's standard model): a person with sensitivity d and criterion c
# says yes on a signal trial with probability pnorm(d / 2 - c) and on a
# noise trial with probability pnorm(-d / 2 - c). Each person's true d is
# drawn around the condition's average with SD sd_d (with the same people
# in both conditions, the two are bivariate normal with correlation r_d),
# and their criterion around the average with SD sd_c (the same in both
# conditions). Hits and false alarms are binomial counts of the trials.
# Each person's d' is then estimated as researchers do, with the log-linear
# correction (Hautus, 1995: 0.5 added to each count and 1 to each number of
# trials), which keeps perfect scores finite. Drawn in this order: the
# true d values, the criteria, then the counts.
dprime_estimate <- function(hits, fas, trials_signal, trials_noise) {
  stats::qnorm((hits + 0.5) / (trials_signal + 1)) - stats::qnorm((fas + 0.5) / (trials_noise + 1))
}

dprime_data <- function(n, d1, d2, trials_signal, trials_noise, sd_d, r_d, criterion, sd_c, within) {
  if (within) {
    z1 <- stats::rnorm(n)
    z2 <- r_d * z1 + sqrt(1 - r_d^2) * stats::rnorm(n)
    true <- cbind(d1 + sd_d * z1, d2 + sd_d * z2)
    cond <- NULL
  } else {
    cond <- rep(1:2, each = n / 2)
    true <- matrix(c(d1, d2)[cond] + sd_d * stats::rnorm(n), ncol = 1)
  }
  crit <- criterion + sd_c * stats::rnorm(n)
  draw <- function(d) {
    hits <- stats::rbinom(length(d), trials_signal, stats::pnorm(d / 2 - crit))
    fas <- stats::rbinom(length(d), trials_noise, stats::pnorm(-d / 2 - crit))
    list(hits = hits, fas = fas, estimate = dprime_estimate(hits, fas, trials_signal, trials_noise))
  }
  if (within) {
    a <- draw(true[, 1])
    b <- draw(true[, 2])
    list(true = true, crit = crit, first = a, second = b)
  } else {
    a <- draw(true[, 1])
    list(true = true, crit = crit, cond = cond, first = a)
  }
}

# Spower experiment: the t-test of the second condition's d' against the
# first's (paired for the same people; Student's for two groups).
p_dprime <- function(n, d1, d2, trials_signal, trials_noise, sd_d, r_d, criterion, sd_c, within, alternative = "two.sided") {
  data <- dprime_data(n, d1, d2, trials_signal, trials_noise, sd_d, r_d, criterion, sd_c, within)
  if (within) {
    stats::t.test(data$second$estimate, data$first$estimate, paired = TRUE, alternative = alternative)$p.value
  } else {
    e <- data$first$estimate
    stats::t.test(e[data$cond == 2], e[data$cond == 1], var.equal = TRUE, alternative = alternative)$p.value
  }
}

# Check run: one large data set; the people's true d' in each condition,
# its SD and correlation, and the share of hits and false alarms against
# their expected values (averaged over people's true d' and criteria by
# numerical integration).
dprime_check_run <- function(args, seed) {
  n <- if (args$within) args$n else 2 * (args$n %/% 2)
  data <- call_backend("Spower", with_seed(seed, do.call(dprime_data, c(args[setdiff(names(args), c("n", "alternative"))], list(n = n)))))
  t1 <- if (args$within) data$true[, 1] else data$true[data$cond == 1, 1]
  t2 <- if (args$within) data$true[, 2] else data$true[data$cond == 2, 1]
  spread <- sqrt(args$sd_d^2 / 4 + args$sd_c^2)
  expected_hit <- stats::pnorm((args$d1 / 2 - args$criterion) / sqrt(1 + spread^2))
  hits <- if (args$within) data$first$hits else data$first$hits[data$cond == 1]
  observed_hit <- mean(hits) / args$trials_signal
  m <- length(t1)
  rows <- rbind(
    check_run_rows(c("average true d' in the first condition", "average true d' in the second condition"),
      c(args$d1, args$d2), c(mean(t1), mean(t2)), rep(max(args$sd_d, 1e-9) / sqrt(m), 2)),
    check_run_rows("share of hits in the first condition", expected_hit, observed_hit, stats::sd(hits / args$trials_signal) / sqrt(m))
  )
  if (args$within && args$sd_d > 0) {
    rows <- rbind(rows, check_run_rows("correlation of a person's true d' in the two conditions", args$r_d, stats::cor(t1, t2), (1 - args$r_d^2) / sqrt(m)))
  }
  rows
}

# Moderation with a yes/no outcome --------------------------------------------
#
# Data: n people. Two scores X and W are standard normal with correlation
# r; a yes/no X has round(n * x_prob) people in its second group (coded 1),
# placed at random, and a yes/no W is 1 with probability w_prob, each drawn
# on its own (a score partner is standard normal). The outcome is yes with
# probability plogis(qlogis(base_prob) + log(or_x) x + log(or_w) w +
# log(or_xw) x w). Drawn in this order: X, W, the outcomes.
logistic_interaction_data <- function(n, base_prob, or_x, or_w, or_xw, x_binary, w_binary, x_prob, w_prob, r) {
  if (!x_binary && !w_binary) {
    x <- stats::rnorm(n)
    w <- r * x + sqrt(1 - r^2) * stats::rnorm(n)
  } else {
    x <- if (x_binary) sample(rep(c(0, 1), c(n - round(n * x_prob), round(n * x_prob)))) else stats::rnorm(n)
    w <- if (w_binary) as.numeric(stats::runif(n) < w_prob) else stats::rnorm(n)
  }
  eta <- stats::qlogis(base_prob) + log(or_x) * x + log(or_w) * w + log(or_xw) * x * w
  data.frame(x = x, w = w, y = stats::rbinom(n, 1, stats::plogis(eta)))
}

# Spower experiment: glm() of the outcome on x * w, and the Wald z test of
# the x:w coefficient (one-sided in the direction asked: "greater", X's
# odds ratio rising with W).
p_logistic_interaction <- function(n, base_prob, or_x, or_w, or_xw, x_binary, w_binary, x_prob, w_prob, r, alternative = "two.sided") {
  data <- logistic_interaction_data(n, base_prob, or_x, or_w, or_xw, x_binary, w_binary, x_prob, w_prob, r)
  fit <- suppressWarnings(stats::glm(y ~ x * w, family = stats::binomial(), data = data))
  z <- stats::coef(summary(fit))["x:w", "z value"]
  switch(alternative,
    two.sided = 2 * stats::pnorm(-abs(z)),
    greater = stats::pnorm(z, lower.tail = FALSE),
    less = stats::pnorm(z)
  )
}

# Check run: one large data set, fitted as each simulated one is; the four
# coefficients recovered (the starting proportion and the three odds
# ratios, on the logit scale).
logistic_interaction_check_run <- function(args, seed) {
  data <- call_backend("Spower", with_seed(seed, do.call(logistic_interaction_data, args[setdiff(names(args), "alternative")])))
  est <- stats::coef(summary(stats::glm(y ~ x * w, family = stats::binomial(), data = data)))
  specified <- c(stats::qlogis(args$base_prob), log(c(args$or_x, args$or_w, args$or_xw)))
  rows <- check_run_rows(
    c("proportion of yes at the starting point (checked on the log-odds scale)", "odds ratio for X (checked on the log scale)",
      "odds ratio for W (checked on the log scale)", "ratio of odds ratios for X x W (checked on the log scale)"),
    specified, est[, "Estimate"], est[, "Std. Error"]
  )
  rows$specified <- c(args$base_prob, args$or_x, args$or_w, args$or_xw)
  rows$recovered <- c(stats::plogis(est[1, 1]), exp(est[-1, 1]))
  rownames(rows) <- NULL
  rows
}

# Multinomial logistic regression ---------------------------------------------
#
# The model: the log odds of category k against the first (the reference)
# are intercept_k + slope_k x, for k = 2, ..., K. The spec gives the share
# of people in each category at X's mean (a score) or in X's first group,
# and either the shares one SD above X's mean or in X's second group, or
# each category's odds ratio against the first. Both fix the model
# exactly: intercept_k = log(p_k / p_1) at the starting point, and slope_k
# = log(odds ratio_k).
multinomial_coefficients <- function(spec) {
  pop <- spec$population
  start <- as.numeric(unlist(pop$probabilities))
  intercepts <- log(start[-1] / start[1])
  slopes <- if (!is.null(pop$odds_ratios)) {
    log(as.numeric(unlist(pop$odds_ratios)))
  } else {
    second <- as.numeric(unlist(pop$probabilities_second))
    log(second[-1] / second[1]) - intercepts
  }
  list(intercepts = intercepts, slopes = slopes)
}

# The category tested against the first by the Wald z test, as its
# position among Y's levels (target_test > category names it); NULL for
# the likelihood-ratio test of every category together.
multinomial_category <- function(spec) {
  if (!identical(spec$target_test$method, "wald_z")) {
    return(NULL)
  }
  match(spec$target_test$category, unlist(spec$variables$Y$levels))
}

multinomial_level <- function(spec, k) {
  sprintf("'%s'", unlist(spec$variables$Y$levels)[[k]])
}

# Each category's share of people at a value of X (one row per person),
# from the model's coefficients.
multinomial_probabilities <- function(x, intercepts, slopes) {
  eta <- cbind(0, outer(x, slopes) + rep(intercepts, each = length(x)))
  p <- exp(eta - apply(eta, 1, max))
  p / rowSums(p)
}

# Data for multinomial logistic regression: n people; the predictor x is a
# standard normal score, or a yes/no group (0, 1) with round(n * x_prob) in
# the second group, placed at random. With another predictor (r2_other
# above 0), z is drawn so that x's R-squared on z is r2_other, with no
# effect of its own on the outcome, as for logistic and Poisson
# regression. Each person's category is then drawn from the model's shares
# at their x (one uniform draw per person). Drawn in this order: x, z, the
# categories. y is a factor of the category numbers 1 to K.
multinomial_data <- function(n, intercepts, slopes, binary, x_prob, r2_other) {
  x <- if (binary) sample(rep(c(0, 1), c(n - round(n * x_prob), round(n * x_prob)))) else stats::rnorm(n)
  data <- data.frame(x = x)
  if (r2_other > 0) {
    standard <- if (binary) (x - mean(x)) / stats::sd(x) else x
    data$z <- sqrt(r2_other) * standard + sqrt(1 - r2_other) * stats::rnorm(n)
  }
  p <- multinomial_probabilities(x, intercepts, slopes)
  k <- ncol(p)
  below <- t(apply(p, 1, cumsum))[, -k, drop = FALSE]
  data$y <- factor(1L + rowSums(stats::runif(n) > below), levels = seq_len(k))
  data
}

# Spower experiment for multinomial logistic regression: nnet's
# multinom() of the category on x (and z). The likelihood-ratio test of x
# compares it with the model without x (K - 1 df: x's coefficients for
# every category at once); the Wald z test is x's coefficient for one
# category against the first. A data set in which some category has
# nobody can't be fitted, and counts as not significant (p = 1), as it
# would for the study.
p_multinomial <- function(n, intercepts, slopes, binary, x_prob, r2_other, test = "likelihood_ratio", category = NULL) {
  data <- multinomial_data(n, intercepts, slopes, binary, x_prob, r2_other)
  if (any(tabulate(data$y, nlevels(data$y)) == 0)) {
    return(1)
  }
  others <- if (r2_other > 0) " + z" else ""
  wald <- identical(test, "wald_z")
  full <- nnet::multinom(stats::as.formula(paste0("y ~ x", others)), data = data, trace = FALSE, Hess = wald)
  if (wald) {
    fit <- summary(full)
    z <- fit$coefficients[category - 1, "x"] / fit$standard.errors[category - 1, "x"]
    return(2 * stats::pnorm(-abs(z)))
  }
  reduced <- nnet::multinom(stats::as.formula(paste0("y ~ 1", others)), data = data, trace = FALSE)
  stats::pchisq(stats::deviance(reduced) - stats::deviance(full), df = length(slopes), lower.tail = FALSE)
}

# Check run: one large data set, fitted as each simulated one is; every
# category's intercept and slope recovered (the share at the starting
# point and the odds ratio, on the log scale).
multinomial_check_run <- function(spec, args, seed) {
  data <- call_backend("Spower", with_seed(seed, multinomial_data(args$n, args$intercepts, args$slopes, args$binary, args$x_prob, args$r2_other)))
  others <- if (args$r2_other > 0) " + z" else ""
  fit <- call_backend("nnet", summary(nnet::multinom(stats::as.formula(paste0("y ~ x", others)), data = data, trace = FALSE, Hess = TRUE)))
  est <- fit$coefficients
  se <- fit$standard.errors
  levels <- unlist(spec$variables$Y$levels)
  start <- if (args$binary) "the first group" else "X's mean"
  rows <- do.call(rbind, lapply(seq_along(args$slopes), function(j) {
    rbind(
      check_run_rows(sprintf("log odds of '%s' against '%s' at %s", levels[j + 1], levels[1], start), args$intercepts[j], est[j, "(Intercept)"], se[j, "(Intercept)"]),
      check_run_rows(sprintf("odds ratio for X, '%s' against '%s' (checked on the log scale)", levels[j + 1], levels[1]), args$slopes[j], est[j, "x"], se[j, "x"])
    )
  }))
  slopes <- seq(2, nrow(rows), by = 2)
  rows$specified[slopes] <- exp(args$slopes)
  rows$recovered[slopes] <- exp(est[, "x"])
  if (args$r2_other > 0) {
    r2 <- stats::cor(data$x, data$z)^2
    rows <- rbind(rows, data.frame(parameter = "R-squared of X on the other predictor", specified = args$r2_other, recovered = r2,
      ok = abs(r2 - args$r2_other) <= 5 * 2 * sqrt(args$r2_other) * (1 - args$r2_other) / sqrt(nrow(data))))
  }
  rows
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
  if (identical(spec$template, "multinomial")) {
    return(multinomial_check_run(spec, args, seed))
  }
  if (identical(spec$template, "interaction") && identical(spec$design, "logistic_regression")) {
    return(logistic_interaction_check_run(args, seed))
  }
  if (identical(spec$template, "group_moderator")) {
    return(group_moderator_check_run(spec, args, seed))
  }
  if (identical(spec$template, "dprime")) {
    return(dprime_check_run(args, seed))
  }
  if (identical(spec$template, "lpa")) {
    return(lpa_check_run(args, seed))
  }
  if (identical(spec$template, "efa")) {
    return(efa_check_run(args, seed))
  }
  if (identical(spec$template, "its")) {
    return(its_check_run(args, seed))
  }
  if (identical(spec$template, "riclpm")) {
    return(riclpm_check_run(args, seed))
  }
  if (permanova_test(spec) && !identical(args$shape, "normal")) {
    return(permanova_check_run(spec, args, seed))
  }
  if (identical(spec$template, "single_predictor_count") && zero_inflated_test(spec)) {
    return(zero_inflated_check_run(args, seed))
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
      if (unequal_welch(spec)) {
        sds <- welch_population_sds(spec)
        return(rbind(
          check_run_rows("mean difference / root mean square SD", pop$d,
            (mean(g2) - mean(g1)) / sqrt((stats::var(g1) + stats::var(g2)) / 2),
            sqrt(sds[1]^2 / length(g1) + sds[2]^2 / length(g2))),
          check_run_rows(c("SD group 1 (RMS units)", "SD group 2 (RMS units)"), sds,
            c(stats::sd(g1), stats::sd(g2)), sds / sqrt(2 * (c(length(g1), length(g2)) - 1))),
          group_sizes(length(g1), length(g2))))
      }
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
  if (art_within(spec)) {
    return(art_within_check_run(spec, args, seed))
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

# PERMANOVA ----------------------------------------------------------------------
#
# Scores for PERMANOVA: n people in each group (or combination of A and
# B). Normal scores are multivariate normal, as for MANOVA
# (manova_scores()). Scores of another shape are drawn as each person's
# common level (standard normal, a share r of the variance) plus a
# deviation of the chosen shape for each outcome (score_shape_sampler(),
# the rest), so any two outcomes correlate r (at least 0), each outcome
# has its SD, and groups differ by their means; in each group in turn, the
# common levels first, then each outcome's deviations in turn.
permanova_scores <- function(n, means, sds, r, shape = "normal", ...) {
  if (identical(shape %||% "normal", "normal")) {
    return(manova_scores(n, means, sds, r))
  }
  draw <- score_shape_sampler(shape)
  p <- ncol(means)
  y <- do.call(rbind, lapply(seq_len(nrow(means)), function(g) {
    common <- stats::rnorm(n)
    vapply(seq_len(p), function(j) means[g, j] + sds[j] * (sqrt(r) * common + sqrt(1 - r) * draw(n)), numeric(n))
  }))
  y <- matrix(y, ncol = p)
  colnames(y) <- paste0("Y", seq_len(p))
  data.frame(group = factor(rep(seq_len(nrow(means)), each = n)), y)
}

# Spower experiment for PERMANOVA (permutational MANOVA; vegan's
# adonis2(), Anderson, 2001, cited by its help): the outcomes standardised
# in each data set (scale()), so that an outcome measured on a larger scale
# doesn't dominate the distances, then Euclidean distances (vegan's default
# is Bray-Curtis, for ecological abundance data, which needs scores of 0 or
# more) and vegan's default 999 permutations. One factor: the test of the
# groups; two factors: the effect's sequential test (by = "terms"), which
# equals its marginal test with equal groups.
p_permanova <- function(n, means, sds, r, shape = "normal", b = 1, term = "A") {
  data <- permanova_scores(n, means, sds, r, shape)
  y <- scale(as.matrix(data[, -1]))
  if (b == 1) {
    fit <- vegan::adonis2(y ~ group, data = data, method = "euclidean", permutations = 999, by = "terms")
    return(fit["group", "Pr(>F)"])
  }
  group <- as.integer(data$group)
  design <- data.frame(A = factor((group - 1) %/% b + 1), B = factor((group - 1) %% b + 1))
  fit <- vegan::adonis2(y ~ A * B, data = design, method = "euclidean", permutations = 999, by = "terms")
  fit[term, "Pr(>F)"]
}

# Check run for PERMANOVA's scores of a shape other than normal: each
# group's means, and the average correlation between two outcomes (its
# allowance three times the normal-theory standard error, since
# heavy-tailed scores estimate it less precisely).
permanova_check_run <- function(spec, args, seed) {
  data <- call_backend("Spower", with_seed(seed, permanova_scores(args$n, args$means, args$sds, args$r, args$shape)))
  y <- as.matrix(data[, -1])
  groups <- split(seq_len(nrow(data)), data$group)
  centred <- do.call(rbind, lapply(groups, function(i) scale(y[i, , drop = FALSE], scale = FALSE)))
  within_r <- mean(stats::cor(centred)[upper.tri(diag(ncol(y)))])
  cells <- expand.grid(g = seq_len(nrow(args$means)), j = seq_len(ncol(args$means)))
  rbind(
    check_run_rows(sprintf("mean of Y%d in group %d", cells$j, cells$g), args$means[cbind(cells$g, cells$j)],
      vapply(seq_len(nrow(cells)), function(i) mean(y[groups[[cells$g[i]]], cells$j[i]]), numeric(1)),
      args$sds[cells$j] / sqrt(args$n)),
    check_run_rows("correlation between two outcomes (average)", args$r, within_r, 3 * (1 - args$r^2) / sqrt(nrow(y)))
  )
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
