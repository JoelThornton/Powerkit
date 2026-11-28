#' The effect size that a design's means and SD give
#'
#' The input screens of the t-tests, the ANOVAs and the ANCOVAs can take the
#' expected means and an SD rather than an effect size. This works out the
#' standardised effect those numbers give, so the screen can show it while
#' the researcher types: Cohen's d (or d_z) for the t-tests, and Cohen's f
#' with partial eta-squared for the effect an ANOVA or ANCOVA tests. An
#' ANOVA given by its partial eta-squared gets its Cohen's f.
#'
#' Nothing here is new statistics: the t-tests' effect is the engine's own
#' conversion from the outcome's units (the schema's definitions); an ANOVA's
#' partial eta-squared and Cohen's f are Superpower's, from `ANOVA_exact()`
#' on its data set with exactly the population's means and covariances, at
#' 1,000 people per group, where they are within 0.1% of the population
#' values (the error sum of squares has n - 1 in place of n); an ANCOVA's
#' are the standardised effect of Shieh's (2020) equations after adjusting
#' for the covariates, the one the engine passes to pwrss for fixed
#' covariates; and an eta-squared becomes f by the effectsize package's
#' `eta2_to_f()`.
#'
#' @param spec A spec as a named list or a JSON string. It need not be
#'   complete: only the template, the variables' levels, the effect tested
#'   and the population values are read.
#'
#' @return `NULL` when the spec has no means and SD to convert (or they are
#'   incomplete), otherwise a list with `name` and `value` of the main
#'   effect size (`"Cohen's d"`, `"d_z"` or `"Cohen's f"`), and for the
#'   ANOVAs `eta_squared` (partial eta-squared), `adjusted` (`TRUE` for an
#'   ANCOVA) and `equal_groups` (`TRUE` when the design has unequal groups
#'   and the value is the one for equal groups). For mediation, two
#'   proportions, a table of proportions, a one-factor MANOVA, a cluster
#'   trial and a 2 x 2 logistic table, a list with `kind = "derived"` and
#'   `items`, each with a `name` and a `value`: the indirect effects, the
#'   odds ratio, difference and Cohen's h, Cohen's w, Pillai's V, the
#'   design effect, or the interaction odds ratio.
#' @export
#' @examples
#' implied_effect_size(list(
#'   design = "factorial_anova", template = "oneway_between",
#'   variables = list(A = list(type = "between_factor", levels = list("a", "b", "c"))),
#'   population = list(metric = "raw", means = list(10, 11, 13), sd = 6)
#' ))
implied_effect_size <- function(spec) {
  if (is.character(spec)) spec <- parse_spec_json(spec_json_text(spec))
  spec <- unclass(spec)
  if (!is.list(spec) || !is.list(spec$population)) return(NULL)
  tryCatch(implied_effect(spec), error = function(e) NULL)
}

implied_effect <- function(spec) {
  pop <- spec$population
  derived <- implied_derived(spec)
  if (!is.null(derived)) return(derived)
  if (identical(spec$design, "factorial_anova") && identical(pop$metric, "eta_squared")) {
    eta <- pop$eta_squared
    if (!is_proportion_open(eta)) return(NULL)
    return(list(name = "Cohen's f", value = effectsize::eta2_to_f(eta), eta_squared = eta, given = "eta_squared"))
  }
  if (!pop$metric %in% c("raw", "standardised")) return(NULL)
  if (spec$template %in% raw_effect_templates && identical(pop$metric, "raw")) {
    standard <- standardise_raw_effect(spec)
    paired <- spec$template %in% c("paired_t", "tost_paired")
    value <- if (paired) standard$population$dz else standard$population$d
    if (!is_finite_number(value)) return(NULL)
    return(list(name = if (paired) "d_z" else "Cohen's d", value = value))
  }
  if (!identical(spec$design, "factorial_anova")) return(NULL)
  if (spec$template %in% c("oneway_ancova", "factorial_ancova")) return(implied_ancova_effect(spec))
  if (!spec$template %in% c("oneway_between", "oneway_within", "2x2_between", "2x2_mixed", "mixed",
                            "factorial_between", "factorial_within", "factorial_three")) {
    return(NULL)
  }
  # Separate SDs per group for Welch's F: no single Cohen's f.
  if (!is.null(pop$sds)) return(NULL)
  inputs <- superpower_inputs(spec)
  if (!all(is_finite_number(inputs$mu)) || !all(is_finite_number(inputs$sd)) || any(inputs$sd <= 0) ||
      !all(is_finite_number(inputs$r))) {
    return(NULL)
  }
  design <- call_backend("Superpower", with_seed(1, quietly(Superpower::ANOVA_design(
    design = inputs$design, n = 1000, mu = inputs$mu, sd = inputs$sd, r = inputs$r, plot = FALSE
  ))))
  result <- call_backend("Superpower", with_seed(1, quietly(
    Superpower::ANOVA_exact(design, alpha_level = 0.05, verbose = FALSE)
  )))
  row <- result$main_results[inputs$effect, ]
  list(name = "Cohen's f", value = row$cohen_f, eta_squared = row$partial_eta_squared,
       equal_groups = !is.null(inputs$cell_ratio) || !is.null(inputs$group_ratio))
}

# Shieh's (2020) standardised effect after adjusting for the covariates:
# gamma^2 is Cohen's f^2 of the adjusted means, so f = gamma and partial
# eta-squared = gamma^2 / (1 + gamma^2).
implied_ancova_effect <- function(spec) {
  pop <- spec$population
  if (!all(is_finite_number(unlist(pop$means))) || !is_finite_number(pop$sd) || pop$sd <= 0) return(NULL)
  if (is.null(pop$r2_covariates)) pop$r2_covariates <- 0
  if (!is_finite_number(pop$r2_covariates) || pop$r2_covariates < 0 || pop$r2_covariates >= 1) return(NULL)
  spec$population <- pop
  gamma2 <- ancova_fixed_gamma2(spec)
  list(name = "Cohen's f", value = sqrt(gamma2), eta_squared = gamma2 / (1 + gamma2), adjusted = TRUE)
}

is_finite_number <- function(x) is.numeric(x) && length(x) > 0 && all(is.finite(x))

is_proportion_open <- function(x) is_finite_number(x) && length(x) == 1 && x > 0 && x < 1

# Quantities the screen's other numbers give, computed by the functions
# the engine already uses (input-screen review of 28 November 2026,
# I-17 to I-23): a list with `kind = "derived"` and `items`, each a `name`
# and `value`, or NULL. Mediation's indirect effects are the products of
# the standardised paths along each route; two proportions give their odds
# ratio (effectsize's probs_to_odds()), difference and Cohen's h (pwr's
# ES.h()); a table of proportions gives Cohen's w (pwr's ES.w2() for a
# test of independence, the goodness-of-fit w the engine passes to pwrss);
# a MANOVA's means give Pillai's V (pillai_v_from_means(), Faul et al.,
# 2007); a cluster trial gives its design effect (cluster_summary()).
implied_derived <- function(spec) {
  pop <- spec$population
  item <- function(name, value) if (is_finite_number(value)) list(name = name, value = unname(value))
  out <- function(...) {
    items <- Filter(Negate(is.null), list(...))
    if (length(items)) list(kind = "derived", items = items)
  }
  if (identical(spec$design, "mediation") && identical(pop$metric, "standardised") && is.list(pop$paths)) {
    return(mediation_indirect_items(pop$paths, item, out))
  }
  if (identical(spec$design, "basic_test") && identical(spec$template, "two_proportions") && identical(pop$metric, "proportion")) {
    if (!is_proportion_open(pop$p1) || !is_proportion_open(pop$p2)) return(NULL)
    odds <- effectsize::probs_to_odds(c(pop$p1, pop$p2))
    return(out(item("odds ratio (group 2 against group 1)", odds[2] / odds[1]),
      item("difference in proportions (group 2 minus group 1)", pop$p2 - pop$p1),
      item("Cohen's h", pwr::ES.h(pop$p2, pop$p1))))
  }
  if (identical(spec$design, "basic_test") && identical(pop$metric, "proportion") &&
      spec$template %in% c("chi_square_independence", "chi_square_gof")) {
    p <- suppressWarnings(as.numeric(unlist(pop$probabilities)))
    if (!length(p) || !all(is.finite(p)) || any(p < 0) || abs(sum(p) - 1) > 1e-6) return(NULL)
    w <- if (identical(spec$template, "chi_square_gof")) gof_w(spec)$w else pwr_w(probability_matrix(spec))
    return(out(item("Cohen's w", w)))
  }
  if (identical(spec$template, "manova") && identical(pop$metric, "raw") && is.null(spec$variables$B)) {
    means <- manova_means(spec)
    sds <- suppressWarnings(as.numeric(unlist(pop$sds)))
    if (!all(is.finite(means)) || length(sds) != ncol(means) || !all(is.finite(sds)) || any(sds <= 0) ||
        !is_finite_number(pop$r) || abs(pop$r) >= 1) return(NULL)
    return(out(item("Pillai's V", pillai_v_from_means(means, hotelling_sigma(sds, pop$r)))))
  }
  if (identical(spec$design, "cluster_trial") && is_finite_number(pop$cluster_size) && is_finite_number(pop$icc)) {
    summary <- cluster_summary(spec, n = 2 * pop$cluster_size * 10)
    effect <- summary$grouped_design_effect
    if (!is_finite_number(effect)) effect <- summary$design_effect
    return(out(item("design effect (how many times the grouping multiplies the variance)", effect)))
  }
  # A 2 x 2 table of the chance of yes: the interaction as a ratio of odds
  # ratios, the second level of B's odds ratio for A over the first's.
  if (identical(spec$design, "logistic_regression") && identical(spec$template, "factorial") && identical(pop$metric, "proportion")) {
    p <- tryCatch(probability_matrix(spec), error = function(e) NULL)
    if (is.null(p) || !identical(dim(p), c(2L, 2L)) || !all(is.finite(p)) || any(p <= 0 | p >= 1)) return(NULL)
    odds <- effectsize::probs_to_odds(p)
    return(out(item("interaction odds ratio (ratio of the two odds ratios)", (odds[2, 2] / odds[1, 2]) / (odds[2, 1] / odds[1, 1]))))
  }
  NULL
}

# The indirect effect along each route from X to Y through the mediators:
# the product of the standardised paths on it ("X->M1", "M1->M2", ...).
mediation_indirect_items <- function(paths, item, out) {
  path <- function(from, to) {
    v <- paths[[paste0(from, "->", to)]]
    if (is.null(v)) NULL else suppressWarnings(as.numeric(v))
  }
  mediators <- unique(sub("^X->", "", grep("^X->M", names(paths), value = TRUE)))
  if (!length(mediators)) return(NULL)
  routes <- list()
  walk <- function(at, route) {
    to_y <- path(at, "Y")
    if (!is.null(to_y)) routes[[length(routes) + 1L]] <<- c(route, "Y")
    for (m in setdiff(mediators, route)) if (!is.null(path(at, m)) && match(m, mediators) > match(at, mediators)) walk(m, c(route, m))
  }
  for (m in mediators) if (!is.null(path("X", m))) walk(m, c("X", m))
  values <- vapply(routes, function(r) prod(vapply(seq_len(length(r) - 1L), function(i) path(r[i], r[i + 1L]), numeric(1))), numeric(1))
  if (!length(values) || !all(is.finite(values))) return(NULL)
  if (length(values) == 1L) return(out(item("indirect effect (X -> M -> Y, the product of the paths)", values)))
  items <- lapply(seq_along(routes), function(i) item(sprintf("indirect effect through %s", paste(routes[[i]][-c(1, length(routes[[i]]))], collapse = " then ")), values[i]))
  do.call(out, c(items, list(item("total indirect effect", sum(values)))))
}
