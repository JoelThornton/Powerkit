# Shared by test-sensitivity-simulated-*.R: for each simulated search, how
# to put the effect found back into the spec, and the check that a fresh
# simulation at it has the target power and the script reproduces it.

sensitivity_simulated_check <- function(names) {
  set_found <- list(
    paired_variances = function(spec, s) { spec$population$var1 <- spec$population$var2 * s$effect; spec },
    proportion_trend = function(spec, s) {
      p <- unlist(spec$population$proportions)
      spec$population$proportions <- as.list(mean(p) + s$scale * (p - mean(p)))
      spec
    },
    dprime = function(spec, s) { spec$population$dprime[[2]] <- spec$population$dprime[[1]] + s$effect; spec },
    jonckheere = function(spec, s) {
      m <- unlist(spec$population$means)
      spec$population$means <- as.list(mean(m) + s$scale * (m - mean(m)))
      spec
    },
    its = function(spec, s) { spec$population$level_change <- s$effect; spec },
    regression_interaction_binary = function(spec, s) { spec$population$r_XW_Y <- s$effect; spec },
    logistic_interaction = function(spec, s) { spec$population$odds_ratio_xw <- s$effect; spec },
    poisson_interaction = function(spec, s) { spec$population$rate_ratio_xw <- s$effect; spec },
    # The log odds ratios of the categories against the first, scaled: from
    # the shares entered (the second point's less the first's).
    multinomial_regression = function(spec, s) {
      p1 <- unlist(spec$population$probabilities)
      p2 <- unlist(spec$population$probabilities_second)
      spec$population$odds_ratios <- as.list(exp(s$scale * (log(p2[-1] / p2[1]) - log(p1[-1] / p1[1]))))
      spec$population$probabilities_second <- NULL
      spec
    },
    multinomial_interaction = function(spec, s) {
      spec$population$odds_ratios_xw <- as.list(unlist(spec$population$odds_ratios_xw)^s$scale)
      spec
    },
    group_moderator = function(spec, s) {
      r <- unlist(spec$population$r_xy)
      spec$population$r_xy <- as.list(mean(r) + s$scale * (r - mean(r)))
      spec
    },
    # The interaction's part of each cell's log-odds (the cell less its
    # row and column means, plus the grand mean) multiplied by the scale.
    logistic_factorial = function(spec, s) {
      l <- stats::qlogis(do.call(rbind, lapply(spec$population$probabilities, unlist)))
      ab <- l - outer(rowMeans(l), colMeans(l), "+") + mean(l)
      p <- stats::plogis(l + (s$scale - 1) * ab)
      spec$population$probabilities <- lapply(seq_len(nrow(p)), function(i) as.list(p[i, ]))
      spec
    }
  )
  jonckheere <- function() {
    spec <- example_spec("anova_oneway_between")
    spec$target_test$method <- "jonckheere_terpstra"
    spec$target_test$alternative <- "greater"
    spec$population$score_shape <- "normal"
    spec
  }
  for (name in names) {
    spec <- if (name == "jonckheere") jonckheere() else example_spec(name)
    if (name == "logistic_factorial") spec$target_test$effect <- "interaction"
    n <- switch(name, jonckheere = 99L, logistic_factorial = 600L, group_moderator = 300L, its = 24L, logistic_interaction = 400L, poisson_interaction = 400L,
      multinomial_regression = 400L, multinomial_interaction = 400L, regression_interaction_binary = 300L, 100L)
    spec$goal <- list(type = "sensitivity", n = n, power = 0.8)
    spec$options$nrep <- 500L
    result <- suppressWarnings(run_quietly(spec))
    s <- result$sensitivity
    expect_true(isTRUE(s$simulated) && s$effect_lower < s$effect && s$effect < s$effect_upper, label = name)
    # Power simulated afresh at the effect found, with more replications
    # and another seed.
    at <- set_found[[name]](spec, s)
    at$goal <- list(type = "power", n = n)
    at$options$nrep <- 4000L
    at$options$seed <- 99L
    expect_equal(suppressWarnings(run_quietly(at))$curve$power, 0.8, tolerance = 0.04, label = name)
    file <- withr::local_tempfile(fileext = ".R")
    writeLines(export_script(spec, result), file)
    out <- system2(file.path(R.home("bin"), "Rscript"), file, stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("^Reproduced powerkit's result", out)), label = name)
  }
}
