# Backend adapter: non-inferiority tests by formula, via pwrss.
#
# A non-inferiority test asks whether a new condition is no worse than a
# comparison by more than a margin: a one-sided test of the difference
# against -margin (when higher scores are better) or +margin (when lower
# are better). pwrss's power.t.student() (two groups, paired data, one
# sample) and power.z.twoprops() (two proportions) take the margin
# directly ("For non-inferiority or superiority tests, add or subtract the
# margin from the null hypothesis value and use alternative = 'one.sided'",
# pwrss 0.3.1 help), testing H1: effect > margin.
#
# pwrss chooses the side of a one-sided test from the sign of the effect
# minus the margin, so powerkit passes the effect oriented so that better
# is positive and the margin as -margin, and the spec checks refuse an
# expected effect that isn't better than -margin (check_equivalence_test()):
# at or beyond the margin, the test would be run in the wrong direction.
#
# Orientation: the spec's d is group 2 minus group 1 (d_z: second minus
# first; one sample: mean minus the reference value), and p2 versus p1;
# group 2 (the second condition) is the new one. When lower is better, the
# effect's sign is reversed. pwrss's proportions are prob1 - prob2, so the
# new group is passed as prob1.

noninf_backend <- function(spec, seed = NULL) {
  inputs <- noninf_inputs(spec)
  step <- valid_n_step(spec)
  power_at <- function(n) {
    out <- call_backend("pwrss", quietly(do.call(getExportedValue("pwrss", inputs$fun), inputs$args(n))))
    out$power
  }
  list(
    name = "pwrss",
    packages = "pwrss",
    methods = "exact",
    default_method = "exact",
    functions = c(exact = paste0("pwrss::", inputs$fun)),
    n_step = step,
    exact_min_n = step * ceiling(minimum_n(spec) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() noninf_check_run(spec, inputs)
  )
}

# +1 when higher values are better, -1 when lower are.
noninf_sign <- function(spec) if (identical(spec$population$better, "lower")) -1 else 1

# The expected effect, better positive, in the spec's units.
noninf_effect <- function(spec) {
  pop <- spec$population
  raw <- switch(
    spec$template,
    noninf_paired = pop$dz,
    noninf_two_proportions = pop$p2 - pop$p1,
    pop$d
  )
  noninf_sign(spec) * raw
}

noninf_inputs <- function(spec) {
  pop <- spec$population
  alpha <- spec$target_test$alpha
  ratio <- spec$options$allocation_ratio %||% 1
  sizes <- function(n) {
    n1 <- round(n / (1 + ratio))
    c(n1, n - n1)
  }
  margin <- -pop$margin
  if (identical(spec$template, "noninf_two_proportions")) {
    better_higher <- noninf_sign(spec) > 0
    return(list(fun = "power.z.twoprops", effect = noninf_effect(spec), margin = margin, args = function(n) {
      s <- sizes(n)
      # prob1 - prob2 is tested against the margin: the better-is-positive
      # difference puts the new group (2) first when higher is better.
      list(
        prob1 = if (better_higher) pop$p2 else pop$p1, prob2 = if (better_higher) pop$p1 else pop$p2,
        margin = margin, n2 = if (better_higher) s[1] else s[2], n.ratio = if (better_higher) s[2] / s[1] else s[1] / s[2],
        alpha = alpha, alternative = "one.sided", verbose = 0
      )
    }))
  }
  design <- switch(spec$template, noninf_independent = "independent", noninf_paired = "paired", noninf_one_sample = "one.sample")
  list(fun = "power.t.student", effect = noninf_effect(spec), margin = margin, design = design, args = function(n) {
    common <- list(d = noninf_effect(spec), margin = margin, alpha = alpha, alternative = "one.sided", design = design, verbose = 0)
    if (identical(design, "independent")) {
      s <- sizes(n)
      c(common, list(n2 = s[2], n.ratio = s[1] / s[2]))
    } else {
      c(common, list(n2 = n))
    }
  })
}

# Check run: no simulated data; the check confirms what pwrss receives.
noninf_check_run <- function(spec, inputs) {
  args <- inputs$args(100)
  rows <- data.frame(
    parameter = c("margin passed to pwrss (minus the margin, better is positive)", "expected effect, better is positive"),
    specified = c(-spec$population$margin, noninf_effect(spec)),
    recovered = c(args$margin, if (is.null(args$d)) args$prob1 - args$prob2 else args$d)
  )
  rows$ok <- mapply(function(a, b) isTRUE(all.equal(a, b)), rows$specified, rows$recovered)
  rows
}

# The R script: the same pwrss call at each size powerkit computed.
noninf_script <- function(spec, result) {
  inputs <- noninf_inputs(spec)
  args <- inputs$args(100)
  fixed <- args[setdiff(names(args), c("n2", "n.ratio"))]
  arg_lines <- vapply(names(fixed), function(a) sprintf("    %s = %s,", a, r_code(fixed[[a]])), character(1))
  sizes <- if (identical(inputs$design, "independent") || identical(inputs$fun, "power.z.twoprops")) {
    ratio <- spec$options$allocation_ratio %||% 1
    first <- identical(inputs$fun, "power.t.student") || noninf_sign(spec) < 0
    c(
      sprintf("  n1 <- round(n_total / (1 + %s)) # group 1 (allocation 1 : %s)", r_code(ratio), format_number(ratio)),
      "  n2 <- n_total - n1",
      if (first) "  sizes <- list(n2 = n2, n.ratio = n1 / n2) # pwrss's n2 is its second group" else
        "  sizes <- list(n2 = n1, n.ratio = n2 / n1) # the new group is pwrss's first, group 1 its second"
    )
  } else {
    "  sizes <- list(n2 = n_total)"
  }
  c(
    script_header(spec, result, "pwrss", paste0("pwrss::", inputs$fun, "(alternative = \"one.sided\", margin)")),
    "library(pwrss)",
    "",
    "# Inputs ----",
    goal_inputs(spec, result),
    "",
    "# Power of the one-sided non-inferiority test at a total sample size.",
    "# The effect is oriented so that better is positive, and the margin is",
    "# minus the largest difference in the wrong direction that is acceptable.",
    "power_at <- function(n_total) {",
    sizes,
    sprintf("  do.call(%s, c(list(", inputs$fun),
    sub(",$", "", paste(arg_lines, collapse = "\n")),
    "  ), sizes))$power",
    "}",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
