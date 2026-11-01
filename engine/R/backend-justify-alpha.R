# Justified alpha (goal > type "justified_alpha"): the significance level
# that minimises, or balances, the weighted error rates at a fixed sample
# size, with JustifyAlpha's optimal_alpha() (citation("JustifyAlpha"):
# Maier & Lakens, 2021). G*Power calls the balanced version a compromise
# power analysis. The weights are how many times worse a false positive is
# than a missed effect (goal > cost_ratio, JustifyAlpha's costT1T2,
# default 1) and how likely an effect is compared with none (goal >
# prior_odds, its priorH1H0, default 1):
#   "minimize" (the default): alpha minimising
#     (cost alpha + prior beta) / (cost + prior);
#   "balance": alpha at which cost alpha = prior beta.
# The power at each alpha is pwr's, the same call the card uses for power
# (pwr.t.test(), pwr.t2n.test() or pwr.r.test()), with sig.level = x as
# optimal_alpha() needs. optimal_alpha() searches alpha with
# stats::optimize(tol = 0.001), so alpha is found to about three decimals.

justified_alpha_goal <- function(spec) identical(spec$goal$type, "justified_alpha")

justified_alpha_templates <- c("one_sample_t", "independent_t", "paired_t", "correlation")

# The power function optimal_alpha() evaluates, as text with alpha as x:
# the pwr call for the spec at n.
justified_alpha_power_function <- function(spec, n) {
  inputs <- pwr_inputs(spec)
  args <- inputs$args(n)
  args[[inputs$alpha_arg %||% "sig.level"]] <- NULL
  text <- paste(sprintf("%s = %s", names(args), vapply(args, r_code, character(1))), collapse = ", ")
  sprintf("%s::%s(%s, sig.level = x)$power", inputs$package, inputs$fun, text)
}

justify_alpha <- function(spec) {
  goal <- spec$goal
  power_function <- justified_alpha_power_function(spec, goal$n)
  cost <- goal$cost_ratio %||% 1
  prior <- goal$prior_odds %||% 1
  rule <- goal$error_rule %||% "minimize"
  found <- tryCatch(
    call_backend("JustifyAlpha", quietly(JustifyAlpha::optimal_alpha(
      power_function = power_function, costT1T2 = cost, priorH1H0 = prior, error = rule
    ))),
    error = function(e) NULL
  )
  if (is.null(found) || !is.finite(found$alpha)) {
    abort_run("JustifyAlpha couldn't find a justified alpha for this design. Check the effect size and the sample size.")
  }
  inputs <- pwr_inputs(spec)
  list(
    alpha = found$alpha, beta = found$beta, power = 1 - found$beta, error_rate = found$errorrate,
    cost_ratio = cost, prior_odds = prior, error_rule = rule,
    # For comparison: power at the conventional alpha the spec gives.
    conventional_alpha = spec$target_test$alpha,
    conventional_power = pwr_power(inputs, goal$n),
    power_function = power_function,
    function_used = sprintf("JustifyAlpha::optimal_alpha(power_function = \"%s\", costT1T2 = %s, priorH1H0 = %s, error = \"%s\")",
      power_function, format_number(cost), format_number(prior), rule)
  )
}

# A justified alpha needs a pwr formula (the t-tests and the correlation,
# by formula), a fixed n and positive weights.
check_justified_alpha <- function(spec) {
  goal <- spec$goal
  if (!justified_alpha_goal(spec)) {
    extra <- intersect(names(goal), c("cost_ratio", "prior_odds", "error_rule"))
    if (length(extra)) {
      return(sprintf("'goal > %s' is only used for a justified alpha ('goal > type' \"justified_alpha\"): remove it.", extra[1]))
    }
    return(character())
  }
  if (!identical(spec$design, "basic_test") || !spec$template %in% justified_alpha_templates || !pwr_covers(spec) ||
      identical(spec$options$method, "simulation")) {
    return(paste0(
      "A justified alpha is available for the one-sample, paired and two-group t-tests and the correlation, ",
      "with the t-test or Pearson's correlation worked out by formula; choose one of those, or another goal."
    ))
  }
  character()
}

# The R script: the same optimal_alpha() call on the same pwr function.
justified_alpha_script <- function(spec, result) {
  j <- result$justified_alpha
  c(
    script_header(spec, result, "JustifyAlpha", "JustifyAlpha::optimal_alpha() on pwr's power"),
    "library(JustifyAlpha)",
    "library(pwr)",
    "",
    "# Inputs ----",
    sprintf("n_total <- %s # total sample size (every participant analysed)", r_code(spec$goal$n)),
    sprintf("cost_ratio <- %s # how many times worse a false positive is than a missed effect", r_code(j$cost_ratio)),
    sprintf("prior_odds <- %s # how likely an effect is, compared with no effect", r_code(j$prior_odds)),
    sprintf("error_rule <- %s # \"minimize\" the weighted error rate, or \"balance\" the two errors", r_code(j$error_rule)),
    "",
    "# Power at alpha = x, the same pwr call powerkit uses (optimal_alpha()",
    "# needs the alpha written as x).",
    sprintf("power_function <- %s", r_code(j$power_function)),
    "",
    "# Justified alpha ----",
    "found <- optimal_alpha(power_function = power_function, costT1T2 = cost_ratio,",
    "  priorH1H0 = prior_odds, error = error_rule)",
    "cat(sprintf(\"Justified alpha: %.4f, beta: %.4f (power %.4f)\\n\", found$alpha, found$beta, 1 - found$beta))",
    "",
    "reproduced <- list(alpha = found$alpha, beta = found$beta)",
    sprintf("powerkit_result <- list(alpha = %s, beta = %s)", r_code(j$alpha), r_code(j$beta)),
    "",
    comparison_section()
  )
}
