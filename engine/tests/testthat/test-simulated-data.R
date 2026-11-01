spec_file <- function(name) system.file("specs", paste0(name, ".json"), package = "powerkit")

test_that("every row is marked as simulated, and columns are named after the labels", {
  data <- simulated_data(read_spec(spec_file("independent_t")), 40, seed = 2)
  expect_equal(names(data), c("SIMULATED_NOT_REAL_DATA", "participant", "Condition", "Recall_score"))
  expect_true(all(data$SIMULATED_NOT_REAL_DATA == "simulated by powerkit"))
  expect_equal(nrow(data), 40)
  expect_setequal(unique(data$Condition), c("Control", "Training"))
})

test_that("the same seed gives the same data, and the CSV keeps the marker column first", {
  spec <- read_spec(spec_file("anova_2x2_mixed"))
  expect_identical(simulated_data(spec, 40, seed = 5), simulated_data(spec, 40, seed = 5))
  file <- tempfile(fileext = ".csv")
  simulated_data(spec, 40, seed = 5, file = file)
  csv <- utils::read.csv(file)
  expect_equal(names(csv)[1], "SIMULATED_NOT_REAL_DATA")
  expect_equal(names(csv)[-(1:2)], c("Group", "Depression_score_Pre", "Depression_score_Post"))
  expect_equal(nrow(csv), 40)
})

test_that("a large simulated data set recovers the population, in the spec's orientation", {
  big <- 20000
  spec <- read_spec(spec_file("independent_t"))
  data <- simulated_data(spec, big, seed = 1)
  levels <- unlist(spec$variables$X$levels)
  y <- split(data$Recall_score, data$Condition)
  expect_equal(mean(y[[levels[2]]]) - mean(y[[levels[1]]]), spec$population$d, tolerance = 0.05 / abs(spec$population$d))

  spec <- read_spec(spec_file("paired_t"))
  data <- simulated_data(spec, big, seed = 1)
  diff <- data[[4]] - data[[3]]
  expect_equal(mean(diff) / stats::sd(diff), spec$population$dz, tolerance = 0.05 / abs(spec$population$dz))

  spec <- read_spec(spec_file("two_proportions"))
  data <- simulated_data(spec, big, seed = 1)
  yes <- unlist(spec$variables$Y$levels)[2]
  groups <- unlist(spec$variables$X$levels)
  p <- vapply(groups, function(g) mean(data$Attended[data$Reminder == g] == yes), numeric(1))
  expect_equal(unname(p), c(spec$population$p1, spec$population$p2), tolerance = 0.02)

  spec <- read_spec(spec_file("anova_2x2_mixed"))
  data <- simulated_data(spec, big, seed = 1)
  means <- matrix(as.numeric(unlist(spec$population$means)), nrow = 2, byrow = TRUE)
  waitlist <- data$Group == unlist(spec$variables$A$levels)[1]
  expect_equal(mean(data$Depression_score_Post[waitlist]), means[1, 2], tolerance = 0.02)
  expect_equal(mean(data$Depression_score_Pre[!waitlist]), means[2, 1], tolerance = 0.02)
  expect_equal(stats::cor(data$Depression_score_Pre, data$Depression_score_Post), spec$population$r, tolerance = 0.05)

  spec <- read_spec(spec_file("regression_interaction"))
  data <- simulated_data(spec, big, seed = 1)
  rel <- spec$variables$X$reliability * (spec$variables$Y$reliability %||% 1)
  expect_equal(stats::cor(data$Daily_stress, data$Sleep_quality), spec$population$r_X_Y * sqrt(rel), tolerance = 0.05)
})

test_that("equivalence, rank, proportion, correlation, ordinal and factorial logistic designs recover their populations", {
  big <- 20000
  spec <- validate_spec(read_spec(spec_file("tost_paired")))
  data <- simulated_data(spec, big, seed = 2)
  diff <- data[[4]] - data[[3]]
  expect_lt(abs(mean(diff) / stats::sd(diff) - spec$population$dz), 0.03)

  spec <- read_spec(spec_file("noninf_two_proportions"))
  data <- simulated_data(spec, big, seed = 2)
  yes <- sim_levels(spec, "Y")[2]
  p <- as.numeric(tapply(data[[4]] == yes, data[[3]], mean)[sim_levels(spec, "X")])
  expect_equal(unname(p), c(spec$population$p1, spec$population$p2), tolerance = 0.02)

  spec <- read_spec(spec_file("tost_correlation"))
  data <- simulated_data(spec, big, seed = 2)
  expect_equal(stats::cor(data[[3]], data[[4]]), spec$population$r, tolerance = 0.03)

  spec <- read_spec(spec_file("one_proportion"))
  data <- simulated_data(spec, big, seed = 2)
  expect_equal(mean(data[[3]] == unlist(spec$variables$Y$levels)[2]), spec$population$p, tolerance = 0.02)

  spec <- read_spec(spec_file("chi_square_gof"))
  data <- simulated_data(spec, big, seed = 2)
  shares <- prop.table(table(factor(data[[3]], levels = unlist(spec$variables$Y$levels))))
  expect_equal(as.numeric(shares), as.numeric(unlist(spec$population$probabilities)), tolerance = 0.03)

  spec <- read_spec(spec_file("two_correlations"))
  data <- simulated_data(spec, big, seed = 2)
  r <- vapply(split(data, data[[3]])[unlist(spec$variables$G$levels)], function(d) stats::cor(d[[4]], d[[5]]), numeric(1))
  expect_equal(unname(r), c(spec$population$r1, spec$population$r2), tolerance = 0.05)

  spec <- read_spec(spec_file("nonoverlapping_correlations"))
  data <- simulated_data(spec, big, seed = 2)
  expect_equal(stats::cor(data[[3]], data[[4]]), spec$population$r_X1_Y1, tolerance = 0.1)
  expect_equal(stats::cor(data[[5]], data[[6]]), spec$population$r_X2_Y2, tolerance = 0.1)

  spec <- read_spec(spec_file("logistic_factorial"))
  data <- simulated_data(spec, big, seed = 2)
  yes <- unlist(spec$variables$Y$levels)[2]
  first <- data[[3]] == unlist(spec$variables$A$levels)[1] & data[[4]] == unlist(spec$variables$B$levels)[1]
  expect_equal(mean(data[[5]][first] == yes), spec$population$probabilities[[1]][[1]], tolerance = 0.03)

  # Group 2's shares follow from group 1's and the odds ratio: here (an odds
  # ratio below 1) group 2 is in lower categories.
  spec <- read_spec(spec_file("ordinal_two_groups"))
  data <- simulated_data(spec, big, seed = 2)
  groups <- unlist(spec$variables$X$levels)
  levels <- unlist(spec$variables$Y$levels)
  shares <- prop.table(table(factor(data[[3]], levels = groups), factor(data[[4]], levels = levels)), 1)
  expect_equal(as.numeric(shares[1, ]), as.numeric(unlist(spec$population$probabilities)), tolerance = 0.03)
  cum_odds <- function(p) {
    q <- cumsum(p)[-length(p)]
    (1 - q) / q
  }
  expect_equal(cum_odds(shares[2, ]) / cum_odds(shares[1, ]), rep(spec$population$odds_ratio, length(levels) - 1), tolerance = 0.15, ignore_attr = TRUE)

  # Rank tests: the effect shifts scores of the chosen shape.
  spec <- read_spec(spec_file("independent_t"))
  spec$target_test$method <- "mann_whitney"
  spec$population$score_shape <- "heavy_tailed"
  spec$options$method <- NULL
  data <- simulated_data(spec, big, seed = 2)
  y <- split(data$Recall_score, data$Condition)[unlist(spec$variables$X$levels)]
  expect_equal(median(y[[2]]) - median(y[[1]]), spec$population$d, tolerance = 0.1)
})

test_that("contrasts, one-predictor regressions and cluster trials recover their populations", {
  big <- 40000
  spec <- read_spec(spec_file("anova_oneway_contrast"))
  data <- simulated_data(spec, big, seed = 3)
  means <- tapply(data[[4]], data[[3]], mean)[sim_levels(spec, "A")]
  expect_equal(as.numeric(means), as.numeric(unlist(spec$population$means)), tolerance = 0.03)

  spec <- read_spec(spec_file("logistic_regression"))
  data <- simulated_data(spec, big, seed = 3)
  fit <- stats::glm(data[[4]] == sim_levels(spec, "Y")[2] ~ data[[3]], family = stats::binomial())
  expect_equal(unname(exp(stats::coef(fit)[2])), spec$population$odds_ratio, tolerance = 0.05)
  expect_equal(unname(stats::plogis(stats::coef(fit)[1])), spec$population$base_prob, tolerance = 0.05)

  spec <- read_spec(spec_file("poisson_regression"))
  data <- simulated_data(spec, big, seed = 3)
  fit <- stats::glm(data[[4]] ~ data[[3]], family = stats::poisson())
  expect_equal(unname(exp(stats::coef(fit))), c(spec$population$base_rate * (spec$population$mean_exposure %||% 1), spec$population$rate_ratio), tolerance = 0.03)

  # A cluster-randomised trial: whole groups of cluster_size in each
  # condition, with the ICC between groups and total SD 1.
  spec <- read_spec(spec_file("cluster_randomised"))
  data <- simulated_data(spec, 8000, seed = 3)
  expect_true(all(table(data$cluster) == spec$population$cluster_size))
  expect_true(all(tapply(data[[3]], data$cluster, function(x) length(unique(x))) == 1))
  cluster_means <- tapply(data[[5]], data$cluster, mean)
  between <- stats::var(cluster_means) - mean(tapply(data[[5]], data$cluster, stats::var)) / spec$population$cluster_size
  expect_equal(between, spec$population$icc, tolerance = 0.5)
  y <- split(data[[5]], data[[3]])[sim_levels(spec, "X")]
  expect_equal(mean(y[[2]]) - mean(y[[1]]), spec$population$d, tolerance = 0.3)

  spec <- read_spec(spec_file("group_treatment"))
  data <- simulated_data(spec, 8000, seed = 3)
  individual <- data[[3]] == sim_levels(spec, "X")[1]
  expect_true(all(is.na(data$cluster[individual])))
  expect_equal(mean(data[[5]][!individual]) - mean(data[[5]][individual]), spec$population$d, tolerance = 0.2)
})

test_that("MANOVA, one-sample Hotelling's T-squared and one-way ANCOVA recover their populations", {
  manova <- read_spec(spec_file("manova"))
  data <- simulated_data(manova, 6000, seed = 2)
  outcomes <- as.matrix(data[, 4:6])
  groups <- data[[3]]
  expected <- do.call(rbind, lapply(manova$population$means, as.numeric))
  observed <- do.call(rbind, lapply(unlist(manova$variables$A$levels), function(g) colMeans(outcomes[groups == g, ])))
  expect_equal(unname(observed), expected, tolerance = 0.03)
  centred <- outcomes - apply(outcomes, 2, function(v) ave(v, groups))
  expect_equal(unname(apply(centred, 2, stats::sd)), as.numeric(unlist(manova$population$sds)), tolerance = 0.03)
  expect_lt(abs(stats::cor(centred)[1, 2] - manova$population$r), 0.05)

  hotelling <- read_spec(spec_file("hotelling_one"))
  data <- simulated_data(hotelling, 6000, seed = 2)
  expect_equal(unname(colMeans(data[, 3:5])), as.numeric(unlist(hotelling$population$means)), tolerance = 0.02)

  ancova <- read_spec(spec_file("anova_oneway_ancova"))
  data <- simulated_data(ancova, 6000, seed = 2)
  expect_named(data, c("SIMULATED_NOT_REAL_DATA", "participant", "Intervention", "Covariate", "Anxiety_after"))
  means <- tapply(data$Anxiety_after, data$Intervention, mean)[unlist(ancova$variables$A$levels)]
  expect_equal(as.numeric(means), as.numeric(unlist(ancova$population$means)), tolerance = 0.03)
  within <- data$Anxiety_after - ave(data$Anxiety_after, data$Intervention)
  expect_equal(stats::sd(within), ancova$population$sd, tolerance = 0.03)
  expect_lt(abs(stats::cor(data$Covariate, within)^2 - ancova$population$r2_covariates), 0.04)
  expect_match(simulated_data_note(ancova), "standard normal score with R-squared 0.36", fixed = TRUE)
  ancova$population$covariates <- 3
  expect_match(simulated_data_note(ancova), "The plan has 3 covariates; the data set has one", fixed = TRUE)
  expect_null(simulated_data_note(manova))
})

test_that("ANCOVA with two factors, R-squared tests, other predictors and the trend test recover their populations", {
  big <- 30000
  spec <- read_spec(spec_file("anova_factorial_ancova"))
  data <- simulated_data(spec, big, seed = 4)
  means <- tapply(data$Anxiety_after, list(data$Intervention, data$Delivery), mean)
  means <- means[unlist(spec$variables$A$levels), unlist(spec$variables$B$levels)]
  expect_equal(unname(means), do.call(rbind, lapply(spec$population$means, as.numeric)), tolerance = 0.02)
  within <- data$Anxiety_after - ave(data$Anxiety_after, data$Intervention, data$Delivery)
  expect_lt(abs(stats::cor(data$Covariate, within)^2 - spec$population$r2_covariates), 0.03)

  spec <- read_spec(spec_file("regression_r2_increase"))
  data <- simulated_data(spec, big, seed = 4)
  full <- summary(stats::lm(Wellbeing_score ~ ., data = data[, -(1:2)]))$r.squared
  reduced <- summary(stats::lm(Wellbeing_score ~ Control_1 + Control_2 + Control_3, data = data))$r.squared
  expect_equal(c(full, reduced), c(spec$population$r2_full, spec$population$r2_reduced), tolerance = 0.06)
  expect_equal(stats::sd(data$Wellbeing_score), 1, tolerance = 0.02)
  spec <- read_spec(spec_file("regression_r2_zero"))
  data <- simulated_data(spec, big, seed = 4)
  expect_equal(summary(stats::lm(Wellbeing_score ~ ., data = data[, -(1:2)]))$r.squared, spec$population$r2, tolerance = 0.06)

  spec <- read_spec(spec_file("logistic_regression"))
  spec$population$r2_other_predictors <- 0.25
  data <- simulated_data(spec, big, seed = 4)
  expect_equal(stats::cor(data[[3]], data$Other_predictor)^2, 0.25, tolerance = 0.06)
  fit <- stats::glm(data[[5]] == sim_levels(spec, "Y")[2] ~ data[[3]] + data$Other_predictor, family = stats::binomial())
  expect_equal(unname(exp(stats::coef(fit)[2])), spec$population$odds_ratio, tolerance = 0.05)
  expect_lt(abs(stats::coef(fit)[3]), 0.05)
  expect_match(simulated_data_note(spec), "Other_predictor, which shares R-squared 0.25", fixed = TRUE)

  spec <- read_spec(spec_file("proportion_trend"))
  spec$options$group_ratio <- list(1, 1, 2, 2)
  spec$goal <- list(type = "power", n = 600)
  data <- simulated_data(spec, 6000, seed = 4)
  expect_equal(as.numeric(table(factor(data[[3]], levels = unlist(spec$variables$X$levels)))), c(1000, 1000, 2000, 2000))
  shares <- tapply(data[[4]] == "Yes", data[[3]], mean)[unlist(spec$variables$X$levels)]
  expect_equal(as.numeric(shares), as.numeric(unlist(spec$population$proportions)), tolerance = 0.1)
})

test_that("multisite trials, yes/no cluster outcomes and a baseline score recover their models", {
  spec <- read_spec(spec_file("multisite"))
  data <- simulated_data(spec, 40000, seed = 5)
  m <- spec$population$cluster_size
  expect_true(all(table(data$cluster) == m))
  expect_true(all(tapply(data[[3]], data$cluster, function(x) length(unique(x))) == 2))
  treated <- data[[3]] == sim_levels(spec, "X")[2]
  expect_equal(mean(data[[5]][treated]) - mean(data[[5]][!treated]), spec$population$d, tolerance = 0.15)
  effects <- tapply(seq_len(nrow(data)), data$cluster, function(i) mean(data[[5]][i][treated[i]]) - mean(data[[5]][i][!treated[i]]))
  # The effect varies between sites with variance 4 icc_effect, plus each
  # site's sampling variance of a difference of two means of m / 2.
  expect_equal(stats::var(effects) - 4 * (1 - spec$population$icc - spec$population$icc_effect) / m, 4 * spec$population$icc_effect, tolerance = 0.3)
  # Within a condition, the sites' means, effects and people's own scores
  # add up to the total variance, 1.
  expect_equal(stats::var(data[[5]][!treated]), 1, tolerance = 0.05)

  spec <- read_spec(spec_file("cluster_randomised_binary"))
  data <- simulated_data(spec, 40000, seed = 5)
  frame <- data.frame(yes = data[[5]] == "Yes", treated = data[[3]] == sim_levels(spec, "X")[2], cluster = data$cluster)
  fit <- lme4::glmer(yes ~ treated + (1 | cluster), data = frame, family = stats::binomial())
  expect_equal(unname(lme4::fixef(fit)), c(stats::qlogis(spec$population$p1), stats::qlogis(spec$population$p2) - stats::qlogis(spec$population$p1)), tolerance = 0.1)
  expect_equal(as.numeric(attr(lme4::VarCorr(fit)$cluster, "stddev")), spec$population$sigma_u, tolerance = 0.2)

  spec <- read_spec(spec_file("multisite_binary"))
  data <- simulated_data(spec, 40000, seed = 5)
  shares <- tapply(data[[5]] == "Yes", data[[3]], mean)[sim_levels(spec, "X")]
  # Averaged over sites the proportions move a little towards 0.5.
  expect_equal(as.numeric(shares), c(spec$population$p1, spec$population$p2), tolerance = 0.1)

  spec <- read_spec(spec_file("group_treatment_binary"))
  data <- simulated_data(spec, 40000, seed = 5)
  grouped <- !is.na(data$cluster)
  expect_equal(c(mean(data[[5]][!grouped] == "Yes"), mean(data[[5]][grouped] == "Yes")), c(spec$population$p1, spec$population$p2), tolerance = 0.05)
  group_p <- tapply(data[[5]][grouped] == "Yes", data$cluster[grouped], mean)
  m <- spec$population$cluster_size
  p2 <- spec$population$p2
  icc <- (stats::var(group_p) - p2 * (1 - p2) / m) / (p2 * (1 - p2) * (1 - 1 / m))
  expect_equal(icc, spec$population$icc, tolerance = 0.5)

  spec <- read_spec(spec_file("cluster_randomised"))
  spec$population$baseline_r2_within <- 0.4
  spec$population$baseline_r2_between <- 0.6
  data <- simulated_data(spec, 40000, seed = 5)
  expect_named(data, c("SIMULATED_NOT_REAL_DATA", "participant", sim_label(spec, "X"), "cluster", "Baseline", sim_label(spec, "Y")))
  y <- data[[6]] - ave(data[[6]], data[[3]])
  own_y <- y - ave(y, data$cluster)
  own_b <- data$Baseline - ave(data$Baseline, data$cluster)
  expect_equal(stats::cor(own_y, own_b)^2, 0.4, tolerance = 0.05)
  expect_equal(stats::cor(tapply(y, data$cluster, mean), tapply(data$Baseline, data$cluster, mean))^2, 0.6, tolerance = 0.2)
  expect_equal(stats::sd(y), 1, tolerance = 0.05)
})

test_that("precision plans give data for their interval", {
  spec <- read_spec(spec_file("precision_two_groups"))
  data <- simulated_data(spec, 20000, seed = 6)
  y <- split(data[[4]], data[[3]])[sim_levels(spec, "X")]
  expect_equal(mean(y[[2]]) - mean(y[[1]]), spec$population$d, tolerance = 0.1)
  spec <- read_spec(spec_file("precision_correlation"))
  data <- simulated_data(spec, 20000, seed = 6)
  expect_equal(stats::cor(data[[3]], data[[4]]), spec$population$r, tolerance = 0.05)
  spec <- read_spec(spec_file("precision_proportion"))
  data <- simulated_data(spec, 20000, seed = 6)
  expect_equal(mean(data[[3]] == sim_yes_no_levels(spec)[2]), spec$population$p, tolerance = 0.05)
  spec$goal <- list(type = "precision", width = 0.1)
  result <- run_spec(spec)
  expect_equal(simulated_data_n(spec, result), result$precision$n)
  expect_match(export_script(spec, result), "A simulated data set (NOT real data)", fixed = TRUE)
  paired <- spec
  paired$template <- "paired"
  paired$population <- list(metric = "standardised", dz = 0.4)
  paired$target_test$method <- "noncentral_t"
  paired$variables <- list(X = list(type = "within_factor", label = "Time", levels = list("Before", "After")), Y = list(type = "continuous", label = "Mood"))
  data <- simulated_data(paired, 20000, seed = 6)
  expect_equal(mean(data$Mood_After - data$Mood_Before), 0.4, tolerance = 0.05)
  expect_equal(stats::sd(data$Mood_After - data$Mood_Before), 1, tolerance = 0.03)
  expect_match(simulated_data_note(paired), "correlation 0.5", fixed = TRUE)
})

test_that("designs without a generator say so", {
  spec <- read_spec(spec_file("sem_model_fit"))
  expect_false(simulated_data_available(spec))
  expect_false(simulated_data_available(read_spec(spec_file("mcnemar"))))
  expect_false(simulated_data_available(read_spec(spec_file("regression_three_way"))))
  expect_false(simulated_data_available(read_spec(spec_file("meta_mean_effect"))))
  expect_error(simulated_data(spec, 100), class = "powerkit_not_available")
  expect_true(simulated_data_available(read_spec(spec_file("mediation_simple"))))
})

test_that("the R script builds the same data set as simulated_data()", {
  spec <- read_spec(spec_file("correlation"))
  spec$goal <- list(type = "power", n = 30)
  result <- run_spec(spec)
  script <- export_script(spec, result)
  expect_match(script, "A simulated data set (NOT real data)", fixed = TRUE)
  expect_match(script, "SIMULATED-not-real-data-correlation.csv", fixed = TRUE)
  lines <- strsplit(script, "\n")[[1]]
  start <- grep("^set\\.seed\\(", lines)
  start <- start[length(start)]
  env <- new.env(parent = baseenv())
  eval(parse(text = lines[start:length(lines)]), envir = env)
  expect_identical(env$simulated, simulated_data(spec, 30, seed = result$provenance$seed))
})
