# Generic tests (design generic_test): power from a test statistic's
# noncentrality parameter and degrees of freedom, as in G*Power's
# "Generic" tests. There is no sample size: the user supplies the
# noncentrality, which already reflects it. Each is one pwrss call:
#   t           pwrss::power.t.test(ncp, df)
#   f           pwrss::power.f.test(ncp, df1, df2)
#   chi_square  pwrss::power.chisq.test(ncp, df)
#   z           pwrss::power.z.test(mean = ncp), SD 1 under both hypotheses
# Goal "power" gives the power for the noncentrality given; goal
# "sensitivity" gives the noncentrality needed for the target power
# (pwrss solves for it when ncp is left NULL). A generic binomial test is
# the exact test of one proportion (basic_test/one_proportion), which
# takes a sample size. Functions and arguments checked in pwrss 1.3.3's
# help pages.

generic_inputs <- function(spec) {
  pop <- spec$population
  alpha <- spec$target_test$alpha
  alternative <- if (identical(spec$target_test$alternative %||% "two_sided", "two_sided")) "two.sided" else "one.sided"
  # For the noncentrality needed, the direction it is solved in.
  req_sign <- if (identical(spec$target_test$alternative, "less")) "-" else "+"
  switch(
    spec$template,
    t = list(fun = "power.t.test", ncp_arg = "ncp", args = list(
      df = pop$df, alpha = alpha, alternative = alternative, plot = FALSE, verbose = 0
    ), sign = req_sign),
    f = list(fun = "power.f.test", ncp_arg = "ncp", args = list(
      df1 = pop$df1, df2 = pop$df2, alpha = alpha, plot = FALSE, verbose = 0
    )),
    chi_square = list(fun = "power.chisq.test", ncp_arg = "ncp", args = list(
      df = pop$df, alpha = alpha, plot = FALSE, verbose = 0
    )),
    z = list(fun = "power.z.test", ncp_arg = "mean", args = list(
      alpha = alpha, alternative = alternative, plot = FALSE, verbose = 0
    ), sign = req_sign)
  )
}

generic_call <- function(inputs, extra) {
  fun <- getExportedValue("pwrss", inputs$fun)
  call_backend("pwrss", quietly(do.call(fun, c(extra, inputs$args))))
}

generic_description <- function(spec) {
  switch(
    spec$template,
    t = "the noncentrality parameter of the t statistic",
    f = "the noncentrality parameter (lambda) of the F statistic",
    chi_square = "the noncentrality parameter (lambda) of the chi-square statistic",
    z = "the mean of the z statistic under the alternative"
  )
}

# The result for a generic test, in run_spec()'s shape: the curve has one
# row with no n.
run_generic <- function(spec, seed) {
  started <- Sys.time()
  inputs <- generic_inputs(spec)
  goal <- spec$goal
  if (goal$type == "power") {
    extra <- stats::setNames(list(spec$population$ncp), inputs$ncp_arg)
    power <- generic_call(inputs, extra)$power
    sensitivity <- NA
  } else {
    extra <- list(power = goal$power)
    if (!is.null(inputs$sign)) extra$req.sign <- inputs$sign
    out <- generic_call(inputs, extra)
    found <- out[[inputs$ncp_arg]]
    # pwrss 1.3.3's search can stop at a wrong value for a t test with few
    # degrees of freedom (df 3: about 8331 where the answer is about 4.26),
    # though its power for a given noncentrality is right. So the
    # noncentrality found is checked with pwrss's own power for it.
    check_power <- generic_call(inputs, stats::setNames(list(found), inputs$ncp_arg))$power
    if (!is.finite(check_power) || abs(check_power - goal$power) > 0.001) {
      abort_run(sprintf(
        "pwrss couldn't find the noncentrality needed for %s power with these degrees of freedom (its answer gives %s power). Try the power for a noncentrality you choose instead.",
        format_number(goal$power), format_number(round(check_power, 3))
      ))
    }
    power <- goal$power
    sensitivity <- list(
      effect = found, effect_name = "ncp", power = power,
      effect_description = sprintf("%s needed for %s power", generic_description(spec), format_number(goal$power))
    )
  }
  check <- data.frame(
    parameter = "noncentrality passed to pwrss",
    specified = spec$population$ncp, recovered = spec$population$ncp, ok = TRUE
  )
  structure(
    list(
      goal_type = goal$type,
      curve = data.frame(n = NA_integer_, power = power, mcse = 0),
      n_required = NA,
      sensitivity = sensitivity,
      recruitment = NA,
      check_run = check,
      provenance = list(
        spec_hash = spec_hash(spec),
        method = "exact",
        seed = seed,
        nrep = NA_integer_,
        cores = NA_integer_,
        batch_size = NA_integer_,
        simulations = NA,
        backend = "pwrss",
        backend_function = sprintf("pwrss::%s", inputs$fun),
        r_version = R.version.string,
        packages = package_versions(c("powerkit", "pwrss")),
        started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
        run_time_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
      )
    ),
    class = "powerkit_result"
  )
}

# The R script for a generic test: the same pwrss call, with the values
# written out.
generic_script <- function(spec, result) {
  inputs <- generic_inputs(spec)
  pop <- spec$population
  goal <- spec$goal
  arg_lines <- function(extra) {
    args <- c(extra, inputs$args)
    paste0("  ", ensure_commas(sprintf("%s = %s", names(args), vapply(args, r_code, character(1)))))
  }
  call <- if (goal$type == "power") {
    c(sprintf("out <- %s(", inputs$fun), arg_lines(stats::setNames(list(pop$ncp), inputs$ncp_arg)), ")",
      "reproduced <- list(power = out$power)",
      "cat(sprintf(\"Power: %.4f\\n\", out$power))",
      sprintf("powerkit_result <- list(power = %s)", r_code(result$curve$power)))
  } else {
    extra <- list(power = goal$power)
    if (!is.null(inputs$sign)) extra$req.sign <- inputs$sign
    c(sprintf("out <- %s( # leaving the noncentrality out, so pwrss solves for it", inputs$fun), arg_lines(extra), ")",
      sprintf("reproduced <- list(ncp = out$%s)", inputs$ncp_arg),
      sprintf("cat(sprintf(\"Noncentrality needed: %%.4f\\n\", out$%s))", inputs$ncp_arg),
      sprintf("powerkit_result <- list(ncp = %s)", r_code(result$sensitivity$effect)))
  }
  c(
    script_header(spec, result, "pwrss", sprintf("pwrss::%s", inputs$fun)),
    "library(pwrss)",
    "",
    sprintf("# %s.", if (goal$type == "power") "Power for the noncentrality given" else "The noncentrality needed for the target power"),
    call,
    "",
    comparison_section()
  )
}
