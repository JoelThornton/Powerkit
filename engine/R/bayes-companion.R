# What a Bayes factor would add to a plan made for a p-value, and planning
# for both (5 November 2026; docs/decisions.md, "How Bayes factors fit
# powerkit"). Every number comes from the design's own Bayes factor test
# version (bfpwr, BayesFactor), run through run_spec() with its default
# priors; nothing here computes a Bayes factor itself.
#
# The agreement between the two tests (t-tests only) uses that the p-value
# and the JZS Bayes factor both depend on the data only through t: each
# test's decision is a region of t (the Bayes factor's bounds from bfpwr's
# tbf01(), as in bayes_sequential()), so the chance of each pair of
# decisions is a probability of t falling between two values, from the t
# distribution (noncentral with the effect, as for the t-test's power).

companion_methods <- list(
  one_sample_t = c("t_test"), paired_t = c("t_test"), independent_t = c("student_t", "welch_t"),
  correlation = c("pearson"), one_proportion = c("exact_binomial"), two_proportions = c("z_test", "fisher_exact"),
  oneway_between = c("anova_f")
)

#' What a Bayes factor would add to a plan made for a p-value
#'
#' For a plan made with a p-value, the chances a Bayes factor analysis of
#' the same data would give: evidence for the effect if it is as planned,
#' evidence for no effect if there is none, and misleading evidence for an
#' effect if there is none, at each threshold, with the design's Bayes
#' factor test version and its default priors (JASP's). With `target`, the
#' sample size at which the Bayes factor reaches the same chance of evidence
#' for the effect, and the larger of the two (enough for both). For the
#' t-tests, how often the two tests agree.
#'
#' @param spec A design spec planned with a p-value.
#' @param n The planned sample size (total).
#' @param thresholds Bayes factors that count as evidence (BF10 for an
#'   effect, BF01 for no effect).
#' @param target The target power of the p-value plan, or `NULL`.
#' @return `NULL` when the design has no Bayes factor version computed
#'   exactly; otherwise a list: `available` (`FALSE` with a plain-English
#'   `reason` when this plan's settings have no Bayes factor counterpart),
#'   `n`, `outcomes` (one row per threshold), `n_for_both` (with `target`),
#'   `agreement` (t-tests) and `priors`, `package` and `function_used`.
#' @export
bayes_companion <- function(spec, n, thresholds = c(3, 10), target = NULL) {
  methods <- companion_methods[[spec$template %||% ""]]
  method <- spec$target_test$method
  if (is.null(methods) || identical(method, "bayes_factor")) return(NULL)
  if (!is.null(method) && !method %in% methods) return(NULL)
  unavailable <- function(reason) list(available = FALSE, reason = reason)
  b <- companion_spec(spec)
  if (is.character(b)) return(unavailable(b))
  run_at <- function(k, goal) {
    s <- b
    s$target_test$evidence_threshold <- k
    s$goal <- goal
    tryCatch(run_spec(s), error = function(e) e)
  }
  rows <- lapply(thresholds, function(k) {
    r <- run_at(k, list(type = "power", n = as.integer(n)))
    if (inherits(r, "error")) return(conditionMessage(r))
    data.frame(threshold = k, for_effect = r$curve$power[1], for_null = r$bayes$evidence_for_null,
      misleading = r$bayes$misleading_evidence)
  })
  failed <- Filter(is.character, rows)
  if (length(failed)) return(unavailable(failed[[1]]))
  outcomes <- do.call(rbind, rows)
  both <- NULL
  if (!is.null(target)) {
    both <- do.call(rbind, lapply(thresholds, function(k) {
      r <- run_at(k, list(type = "sample_size", power = target))
      n_bayes <- if (inherits(r, "error")) NA_integer_ else as.integer(r$n_required$n)
      data.frame(threshold = k, n_bayes = n_bayes, n_both = if (is.na(n_bayes)) NA_integer_ else max(as.integer(n), n_bayes))
    }))
  }
  agreement <- if (spec$template %in% c("one_sample_t", "paired_t", "independent_t")) {
    do.call(rbind, lapply(thresholds, function(k) companion_agreement_t(spec, b, n, k)))
  }
  list(
    available = TRUE, n = as.integer(n), thresholds = thresholds, outcomes = outcomes,
    n_for_both = both, agreement = agreement,
    priors = companion_priors(b),
    package = companion_package(spec$template),
    function_used = sprintf("powerkit::bayes_companion(spec, n = %s, thresholds = c(%s)%s)", format(n),
      paste(format(thresholds), collapse = ", "), if (is.null(target)) "" else sprintf(", target = %s", format(target)))
  )
}

# The spec's Bayes factor test version, with its default priors, or a
# plain-English reason it has none.
companion_spec <- function(spec) {
  b <- spec
  b$target_test$method <- "bayes_factor"
  b$target_test$alpha <- NULL
  b$options$method <- NULL
  if (!length(b$options)) b$options <- NULL
  b$effect_justification$safeguard <- NULL
  b$population$score_shape <- NULL
  pop <- b$population
  if (!is.null(pop$sd_ratio)) {
    if (!isTRUE(all.equal(pop$sd_ratio, 1))) {
      return("The Bayes factor t-test assumes the two groups' SDs are equal, and this plan has them differ.")
    }
    b$population$sd_ratio <- NULL
  }
  if (!is.null(pop$sds) && length(unique(unlist(pop$sds))) > 1) {
    return("The Bayes factor test assumes the groups' SDs are equal, and this plan has them differ.")
  }
  b
}

companion_priors <- function(b) {
  tt <- b$target_test
  switch(b$template,
    one_sample_t = , paired_t = , independent_t = list(prior_scale = tt$prior_scale %||% bayes_defaults$prior_scale),
    oneway_between = list(prior_scale = tt$prior_scale %||% 0.5),
    list())
}

companion_package <- function(template) {
  name <- if (template %in% c("one_sample_t", "paired_t", "independent_t", "one_proportion")) "bfpwr" else "BayesFactor"
  list(name = name, version = as.character(utils::packageVersion(name)))
}

# How often the p-value test and the Bayes factor agree, for a t-test at a
# total of n: a row per truth (the planned effect, and none) and pair of
# decisions (p below alpha or not; BF10 at least k, BF01 at least k, or
# neither).
companion_agreement_t <- function(spec, b, n, k) {
  inputs <- bfpwr_inputs(b)
  two <- identical(inputs$type, "two.sample")
  ratio <- spec$options$allocation_ratio %||% 1
  if (two && !isTRUE(all.equal(ratio, 1))) return(NULL)
  size <- inputs$size(n)
  df <- if (two) n - 2 else n - 1
  ncp_of <- function(d) if (two) d * sqrt(size / 2) else d * sqrt(size)
  alpha <- spec$target_test$alpha %||% 0.05
  alt <- inputs$alternative
  sided <- identical(alt, "two.sided")
  crit <- stats::qt(1 - if (sided) alpha / 2 else alpha, df)
  bounds <- call_backend("bfpwr", sequential_bounds(size, inputs$type, alt, inputs$prior_scale,
    c(effect = log(k), null = -log(k))))
  t_effect <- bounds$effect[1]
  t_null <- bounds$null[1]
  # The statistic in the hypothesis's direction (|t| when two-sided).
  lower_end <- if (sided) 0 else -Inf
  cuts <- sort(unique(c(lower_end, Inf, crit, t_effect, t_null)))
  cuts <- cuts[!is.na(cuts)]
  sgn <- if (identical(alt, "less")) -1 else 1
  prob_between <- function(a, z, ncp) {
    if (sided) {
      (stats::pt(z, df, ncp) - stats::pt(a, df, ncp)) + (stats::pt(-a, df, ncp) - stats::pt(-z, df, ncp))
    } else {
      stats::pt(z, df, sgn * ncp) - stats::pt(a, df, sgn * ncp)
    }
  }
  # For "less", the statistic in the hypothesis's direction is -t, a
  # noncentral t with the noncentrality's sign flipped (prob_between()).
  cells <- function(d, truth) {
    out <- list()
    for (i in seq_len(length(cuts) - 1)) {
      a <- cuts[i]; z <- cuts[i + 1]
      mid <- if (is.infinite(z)) a + 1 else if (is.infinite(a)) z - 1 else (a + z) / 2
      p_sig <- mid > crit
      bf <- if (!is.na(t_effect) && mid >= t_effect) "effect" else if (!is.na(t_null) && mid <= t_null) "null" else "neither"
      pr <- prob_between(a, z, ncp_of(d))
      out[[i]] <- data.frame(truth = truth, p_significant = p_sig, bayes = bf, probability = pr)
    }
    x <- do.call(rbind, out)
    # Every pair of decisions, with 0 for those this design can't give.
    grid <- expand.grid(p_significant = c(TRUE, FALSE), bayes = c("effect", "neither", "null"), stringsAsFactors = FALSE)
    grid$truth <- truth
    grid$probability <- vapply(seq_len(nrow(grid)), function(i) {
      sum(x$probability[x$p_significant == grid$p_significant[i] & x$bayes == grid$bayes[i]])
    }, numeric(1))
    grid[, c("truth", "p_significant", "bayes", "probability")]
  }
  rbind(
    cbind(threshold = k, cells(inputs$effect, "effect")),
    cbind(threshold = k, cells(0, "none"))
  )
}
