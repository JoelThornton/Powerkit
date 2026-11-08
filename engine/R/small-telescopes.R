# Small telescopes (Simonsohn, 2015; refs.bib Simonsohn2015_telescopes):
# planning a replication so that it can show the original study's effect
# was too small for that study to have detected. The yardstick is d33 (r33
# for a correlation), the effect the original study had 33% power to
# detect with its own sample size: pwr's power functions at power = 1/3.
# The replication's test is one-sided, of H0: effect = d33 against H1:
# effect smaller than d33 (towards 0), and it is planned for a true effect
# of 0, so a null replication can reject the original's detectable
# effect. Its power comes from pwrss: power.t.student() with the margin
# d33 for the t-tests ("For non-inferiority or superiority tests, add or
# subtract the margin from the null hypothesis value and use alternative
# = 'one.sided'", pwrss 1.3.3 help) and power.z.onecor() with null.rho =
# r33 for the correlation. Simonsohn's rule of thumb, about 2.5 times the
# original sample for 80% power, is what this gives: 51 per group for an
# original 20 per group (test-small-telescopes.R).
#
# Two significance levels: d33 is worked out at the level the original
# study used (`small_telescopes > alpha`, two-sided, 0.05 unless given),
# and the replication's test uses the card's own alpha. Using the card's
# alpha for both would move the yardstick: a replication at .005 would get
# d33 = 0.79 instead of 0.50 for an original of 20 per group, and so a
# smaller sample than one at .05.

# Which population field holds the original effect, and which of the
# original study's sample sizes are needed, for each template.
telescope_templates <- list(
  one_sample_t = list(effect = "d", sizes = "n", design = "one.sample"),
  paired_t = list(effect = "dz", sizes = "n", design = "paired"),
  independent_t = list(effect = "d", sizes = c("n1", "n2"), design = "independent"),
  correlation = list(effect = "r", sizes = "n")
)

small_telescopes_test <- function(spec) {
  !is.null(spec$effect_justification$small_telescopes)
}

# The significance level the original study used: two-sided, 0.05 unless
# the spec says otherwise.
telescope_original_alpha <- function(st) st$alpha %||% 0.05

#' The effect an original study had 33% power to detect
#'
#' Simonsohn's (2015) d33 (or r33): the effect size that the original
#' study, with its own sample size, had a one-in-three chance of finding
#' significant (two-sided, at `alpha`), from pwr's power functions.
#'
#' @param template `"one_sample_t"`, `"paired_t"`, `"independent_t"` or
#'   `"correlation"`.
#' @param n The original study's number of participants (one-sample,
#'   paired and correlation).
#' @param n1,n2 The original study's group sizes (independent groups).
#' @param alpha The original test's significance level.
#' @return A list: `effect` (d33, d_z33 or r33, positive), `effect_name`,
#'   `function_used` and `package` (name and version).
#' @keywords internal
telescope_effect <- function(template, n = NULL, n1 = NULL, n2 = NULL, alpha = 0.05) {
  third <- 1 / 3
  out <- switch(template,
    independent_t = list(
      effect = pwr::pwr.t2n.test(n1 = n1, n2 = n2, power = third, sig.level = alpha)$d,
      used = sprintf("pwr::pwr.t2n.test(n1 = %s, n2 = %s, power = 1/3, sig.level = %s)", n1, n2, format(alpha))),
    one_sample_t = ,
    paired_t = list(
      effect = pwr::pwr.t.test(n = n, power = third, sig.level = alpha, type = if (template == "paired_t") "paired" else "one.sample")$d,
      used = sprintf("pwr::pwr.t.test(n = %s, power = 1/3, sig.level = %s, type = \"%s\")", n, format(alpha),
        if (template == "paired_t") "paired" else "one.sample")),
    correlation = list(
      effect = pwr::pwr.r.test(n = n, power = third, sig.level = alpha)$r,
      used = sprintf("pwr::pwr.r.test(n = %s, power = 1/3, sig.level = %s)", n, format(alpha)))
  )
  list(
    effect = out$effect,
    effect_name = switch(template, paired_t = "d_z33", correlation = "r33", "d33"),
    function_used = out$used,
    package = list(name = "pwr", version = as.character(utils::packageVersion("pwr")))
  )
}

# In validate_spec(): the original study's sizes are there, the design is
# one small telescopes covers, and it isn't combined with what it
# replaces. The original effect stays in the population, for the record;
# the replication is planned for a true effect of 0.
small_telescopes_problems <- function(spec) {
  st <- spec$effect_justification$small_telescopes
  if (is.null(st)) return(character())
  rule <- telescope_templates[[spec$template %||% ""]]
  if (!identical(spec$design, "basic_test") || is.null(rule)) {
    return(paste0("Small telescopes ('effect_justification > small_telescopes') is available for the one-sample, paired and ",
      "independent t-tests and the correlation, not for this design."))
  }
  problems <- character()
  missing <- setdiff(rule$sizes, names(st))
  if (length(missing)) {
    problems <- c(problems, sprintf("Small telescopes needs the original study's %s ('effect_justification > small_telescopes > %s').",
      if (identical(rule$sizes, "n")) "number of participants" else "group sizes", missing[1]))
  }
  if (!is.null(spec$effect_justification$safeguard)) {
    problems <- c(problems, "Choose small telescopes or safeguard power, not both: small telescopes plans for a true effect of 0, so there is no effect to safeguard.")
  }
  method <- spec$target_test$method %||% ""
  if (!method %in% c("", "t_test", "student_t", "welch_t", "pearson")) {
    problems <- c(problems, "Small telescopes plans the replication's t-test or correlation test against the original's d33 (or r33); it doesn't combine with a rank, Bayes factor or minimum-effect test.")
  }
  if (!spec$goal$type %in% c("power", "sample_size")) {
    problems <- c(problems, "Small telescopes gives the replication's sample size, or its power at a given sample size.")
  }
  effect <- spec$population[[rule$effect]]
  if (is.null(effect) || !is.numeric(effect) || effect == 0) {
    problems <- c(problems, "Small telescopes needs the original study's effect size, as reported, so the replication tests in its direction; it can't be zero.")
  }
  if (!is.null(spec$options$method) && !identical(spec$options$method, "exact")) {
    problems <- c(problems, "Small telescopes is worked out by formula (pwr and pwrss); remove 'options > method'.")
  }
  original_alpha <- st$alpha
  if (!is.null(original_alpha) && (!is.numeric(original_alpha) || length(original_alpha) != 1 || original_alpha <= 0 || original_alpha >= 0.5)) {
    problems <- c(problems, "The original study's significance level ('effect_justification > small_telescopes > alpha') must be between 0 and 0.5, for example 0.05.")
  }
  problems
}

telescope_backend <- function(spec, seed = NULL) {
  rule <- telescope_templates[[spec$template]]
  st <- spec$effect_justification$small_telescopes
  alpha <- spec$target_test$alpha
  yardstick <- telescope_effect(spec$template, n = st$n, n1 = st$n1, n2 = st$n2, alpha = telescope_original_alpha(st))
  # The original effect's sign: the replication asks whether the effect is
  # smaller than d33 in that direction.
  margin <- sign(spec$population[[rule$effect]]) * yardstick$effect
  ratio <- spec$options$allocation_ratio %||% 1
  correlation <- identical(spec$template, "correlation")
  fun <- if (correlation) "power.z.onecor" else "power.t.student"
  # `truth` is the true effect, as a share of the margin: 0 for the plan,
  # more for the table of what happens if the effect is small but real.
  args <- function(n, truth = 0) {
    if (correlation) {
      return(list(rho = truth * margin, null.rho = margin, n = n, alpha = alpha, alternative = "one.sided", verbose = 0))
    }
    sizes <- if (identical(rule$design, "independent")) {
      n1 <- round(n / (1 + ratio))
      list(n2 = n - n1, n.ratio = n1 / (n - n1))
    } else {
      list(n2 = n)
    }
    c(list(d = truth * margin, margin = margin), sizes, list(alpha = alpha, alternative = "one.sided", design = rule$design, verbose = 0))
  }
  power_at <- function(n, truth = 0) {
    call_backend("pwrss", quietly(do.call(getExportedValue("pwrss", fun), args(n, truth))))$power
  }
  step <- valid_n_step(spec)
  list(
    name = "pwrss",
    packages = c("pwrss", "pwr"),
    methods = "exact",
    default_method = "exact",
    functions = c(exact = sprintf("pwrss::%s (H0: the effect is %s = %s; the original's from %s)",
      fun, yardstick$effect_name, format(signif(margin, 4)), yardstick$function_used)),
    n_step = step,
    # pwrss needs at least 3 degrees of freedom.
    exact_min_n = step * ceiling(max(minimum_n(spec), if (identical(rule$design, "independent")) 6 else 5) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    telescope = c(yardstick, list(margin = margin, fun = fun, args = args, power_at = power_at)),
    check_run = function() data.frame(parameter = character(), specified = numeric(), recovered = numeric(), ok = logical())
  )
}

# The share of d33 the true effect could be, for the table of what the
# replication's power is if the effect is small but real.
telescope_truths <- c(0, 0.25, 0.5, 0.75)

# For the result: the original study's sizes, effect and significance
# level, its d33, and, at the replication's sample size `n`, the power to
# show the effect is smaller than d33 if the true effect is 0 or a share
# of d33 (`telescope_truths`).
small_telescopes_record <- function(spec, n = NULL, backend = NULL) {
  st <- spec$effect_justification$small_telescopes
  if (is.null(st)) return(NULL)
  rule <- telescope_templates[[spec$template]]
  original <- spec$population[[rule$effect]]
  original_alpha <- telescope_original_alpha(st)
  yardstick <- telescope_effect(spec$template, n = st$n, n1 = st$n1, n2 = st$n2, alpha = original_alpha)
  yardstick$effect <- sign(original) * yardstick$effect
  if_small <- if (!is.null(n) && is.function(backend$telescope$power_at)) {
    data.frame(true_effect = telescope_truths * yardstick$effect,
      power = vapply(telescope_truths, function(t) backend$telescope$power_at(n, t), numeric(1)))
  }
  c(yardstick, list(
    original_effect = original,
    original_alpha = original_alpha,
    n = st$n, n1 = st$n1, n2 = st$n2,
    original_n = if (is.null(st$n)) st$n1 + st$n2 else st$n,
    if_small = if_small
  ))
}

# The R script: d33 from pwr, then the replication's one-sided test
# against it from pwrss, as telescope_backend() computes them.
telescope_script <- function(spec, result) {
  rule <- telescope_templates[[spec$template]]
  st <- spec$effect_justification$small_telescopes
  record <- result$small_telescopes
  correlation <- identical(spec$template, "correlation")
  yardstick_call <- switch(spec$template,
    independent_t = sprintf("pwr.t2n.test(n1 = %s, n2 = %s, power = 1/3, sig.level = original_alpha)$d", st$n1, st$n2),
    correlation = sprintf("pwr.r.test(n = %s, power = 1/3, sig.level = original_alpha)$r", st$n),
    sprintf("pwr.t.test(n = %s, power = 1/3, sig.level = original_alpha, type = \"%s\")$d", st$n,
      if (spec$template == "paired_t") "paired" else "one.sample"))
  sizes <- if (identical(rule$design, "independent")) {
    ratio <- spec$options$allocation_ratio %||% 1
    c(
      sprintf("  n1 <- round(n_total / (1 + %s)) # group 1 (allocation 1 : %s)", r_code(ratio), format_number(ratio)),
      "  n2 <- n_total - n1"
    )
  }
  test <- if (correlation) {
    "  pwrss::power.z.onecor(rho = 0, null.rho = margin, n = n_total, alpha = alpha, alternative = \"one.sided\", verbose = 0)$power"
  } else if (identical(rule$design, "independent")) {
    "  pwrss::power.t.student(d = 0, margin = margin, n2 = n2, n.ratio = n1 / n2, alpha = alpha, alternative = \"one.sided\", design = \"independent\", verbose = 0)$power"
  } else {
    sprintf("  pwrss::power.t.student(d = 0, margin = margin, n2 = n_total, alpha = alpha, alternative = \"one.sided\", design = \"%s\", verbose = 0)$power", rule$design)
  }
  c(
    script_header(spec, result, "pwrss", result$provenance$backend_function),
    "library(pwr)",
    "library(pwrss)",
    "",
    "# Inputs ----",
    goal_inputs(spec, result),
    sprintf("original_effect <- %s # the original study's estimate, which sets the direction", r_code(record$original_effect)),
    "",
    sprintf("original_alpha <- %s # the significance level the original study used (two-sided)", r_code(record$original_alpha)),
    "",
    sprintf("# Small telescopes (Simonsohn, 2015): %s is the effect the original study,", record$effect_name),
    "# with its own sample size, had 33% power to detect (two-sided, at the",
    "# original's significance level). The replication's test uses alpha.",
    sprintf("yardstick <- %s", yardstick_call),
    "margin <- sign(original_effect) * yardstick",
    "",
    "# The replication's one-sided test of whether the effect is smaller than",
    sprintf("# %s (towards 0), when the true effect is 0.", record$effect_name),
    "power_at <- function(n_total) {",
    sizes,
    test,
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
