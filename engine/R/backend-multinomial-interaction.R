# Moderation with an outcome in three or more unordered categories
# (logistic_regression / multinomial_interaction, E32).
#
# The model is a multinomial logistic regression with the product of X and
# W: the log odds of category k against the first (the reference) are
#   intercept_k + bx_k x + bw_k w + bxw_k x w,   k = 2, ..., K,
# as nnet's multinom() fits y ~ x * w. X and W are each a score (standard
# normal; two scores correlated r) or a yes/no group (0, 1), drawn as for
# moderation of a yes/no outcome (logistic_interaction_data()). The spec
# gives the share of people in each category with X and W at their means
# (or in their first groups), and for each category but the first its
# odds ratio for X, for W and the ratio of odds ratios for X x W: these fix
# the coefficients exactly (intercept_k = log(p_k / p_1), the others the
# logs of the ratios).
#
# The test that X's effect depends on W: the likelihood-ratio test of the
# K - 1 product coefficients together, comparing y ~ x * w with
# y ~ x + w (K - 1 df), or the Wald z test of the product's coefficient
# for one category against the first. A data set with nobody in some
# category can't be fitted and counts as not significant (p = 1), as for
# multinomial logistic regression of one predictor (p_multinomial()).

multinomial_interaction_coefficients <- function(spec) {
  pop <- spec$population
  start <- as.numeric(unlist(pop$probabilities))
  list(
    intercepts = log(start[-1] / start[1]),
    bx = log(as.numeric(unlist(pop$odds_ratios_x))),
    bw = log(as.numeric(unlist(pop$odds_ratios_w))),
    bxw = log(as.numeric(unlist(pop$odds_ratios_xw)))
  )
}

multinomial_interaction_data <- function(n, intercepts, bx, bw, bxw, x_binary, w_binary, x_prob, w_prob, r) {
  if (!x_binary && !w_binary) {
    x <- stats::rnorm(n)
    w <- r * x + sqrt(1 - r^2) * stats::rnorm(n)
  } else {
    x <- if (x_binary) sample(rep(c(0, 1), c(n - round(n * x_prob), round(n * x_prob)))) else stats::rnorm(n)
    w <- if (w_binary) as.numeric(stats::runif(n) < w_prob) else stats::rnorm(n)
  }
  eta <- cbind(0, rep(intercepts, each = n) + outer(x, bx) + outer(w, bw) + outer(x * w, bxw))
  p <- exp(eta - apply(eta, 1, max))
  p <- p / rowSums(p)
  k <- ncol(p)
  below <- t(apply(p, 1, cumsum))[, -k, drop = FALSE]
  data.frame(x = x, w = w, y = factor(1L + rowSums(stats::runif(n) > below), levels = seq_len(k)))
}

p_multinomial_interaction <- function(n, intercepts, bx, bw, bxw, x_binary, w_binary, x_prob, w_prob, r,
                                      test = "likelihood_ratio", category = NULL) {
  data <- multinomial_interaction_data(n, intercepts, bx, bw, bxw, x_binary, w_binary, x_prob, w_prob, r)
  if (any(tabulate(data$y, nlevels(data$y)) == 0)) return(1)
  wald <- identical(test, "wald_z")
  full <- nnet::multinom(y ~ x * w, data = data, trace = FALSE, Hess = wald)
  if (wald) {
    fit <- summary(full)
    z <- fit$coefficients[category - 1, "x:w"] / fit$standard.errors[category - 1, "x:w"]
    p <- 2 * stats::pnorm(-abs(z))
  } else {
    reduced <- nnet::multinom(y ~ x + w, data = data, trace = FALSE)
    p <- stats::pchisq(stats::deviance(reduced) - stats::deviance(full), df = length(bxw), lower.tail = FALSE)
  }
  if (is.finite(p)) p else 1
}

# Check run: one large data set, fitted as each simulated one is; every
# category's four coefficients recovered (the share at the starting point
# and the three odds ratios, on the log scale).
multinomial_interaction_check_run <- function(spec, args, seed) {
  data <- call_backend("Spower", with_seed(seed, do.call(multinomial_interaction_data,
    args[setdiff(names(args), c("test", "category"))])))
  fit <- call_backend("nnet", summary(nnet::multinom(y ~ x * w, data = data, trace = FALSE, Hess = TRUE)))
  est <- fit$coefficients
  se <- fit$standard.errors
  levels <- unlist(spec$variables$Y$levels)
  rows <- do.call(rbind, lapply(seq_along(args$intercepts), function(j) {
    against <- sprintf("'%s' against '%s'", levels[j + 1], levels[1])
    check_run_rows(
      c(sprintf("log odds of %s at the starting point", against),
        sprintf("odds ratio for X, %s (checked on the log scale)", against),
        sprintf("odds ratio for W, %s (checked on the log scale)", against),
        sprintf("ratio of odds ratios for X x W, %s (checked on the log scale)", against)),
      c(args$intercepts[j], args$bx[j], args$bw[j], args$bxw[j]),
      est[j, c("(Intercept)", "x", "w", "x:w")], se[j, c("(Intercept)", "x", "w", "x:w")])
  }))
  ratios <- !grepl("^log odds", rows$parameter)
  rows$specified[ratios] <- exp(rows$specified[ratios])
  rows$recovered[ratios] <- exp(rows$recovered[ratios])
  rownames(rows) <- NULL
  rows
}

multinomial_interaction_label <- function(spec) {
  if (identical(spec$target_test$method, "wald_z")) {
    sprintf("Spower::Spower(p_multinomial_interaction()) (nnet::multinom(y ~ x * w), the Wald z test of the X x W coefficient for %s against %s)",
      multinomial_level(spec, multinomial_category(spec)), multinomial_level(spec, 1))
  } else {
    "Spower::Spower(p_multinomial_interaction()) (nnet::multinom(), the likelihood-ratio test of the X x W terms, all categories together)"
  }
}

check_multinomial_interaction <- function(spec) {
  pop <- spec$population
  levels <- unlist(spec$variables$Y$levels)
  k <- length(levels)
  label <- var_label(spec, "Y")
  problems <- character()
  p <- as.numeric(unlist(pop$probabilities))
  if (length(p) != k) {
    problems <- c(problems, sprintf("'population > probabilities' needs one share for each of %s's %d categories (%s); it has %d.",
      label, k, paste(levels, collapse = ", "), length(p)))
  } else if (abs(sum(p) - 1) > 1e-6) {
    problems <- c(problems, sprintf("The shares in 'population > probabilities' add up to %s; they must add up to 1.", format_number(sum(p))))
  }
  for (field in c("odds_ratios_x", "odds_ratios_w", "odds_ratios_xw")) {
    if (length(unlist(pop[[field]])) != k - 1) {
      problems <- c(problems, sprintf(
        "'population > %s' needs one value for each category but the first ('%s', the reference): %d for %s's %d categories; it has %d.",
        field, levels[1], k - 1, label, k, length(unlist(pop[[field]]))))
    }
  }
  wald <- identical(spec$target_test$method, "wald_z")
  category <- spec$target_test$category
  if (wald && !isTRUE(category %in% levels[-1])) {
    problems <- c(problems, sprintf(
      "The Wald z test compares one category with the first ('%s'): name it in 'target_test > category' (one of %s).",
      levels[1], paste(levels[-1], collapse = ", ")))
  } else if (!wald && !is.null(category)) {
    problems <- c(problems, "'target_test > category' is only used by the Wald z test of one category ('target_test > method' \"wald_z\"); the likelihood-ratio test covers every category together. Remove it.")
  }
  problems
}
