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
#'   and the value is the one for equal groups).
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
