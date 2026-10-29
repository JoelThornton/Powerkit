# The test's technical details at the n reported: its statistic, degrees of
# freedom, critical value(s) and noncentrality, for users checking a result
# against G*Power or R. They are read from the backend package's own output,
# never computed by powerkit. pwrss returns them for every test it runs
# (df, df1 and df2; ncp, or the mean of the test statistic for z tests;
# the critical value as t.alpha, f.alpha, z.alpha, chisq.alpha, or the
# critical counts binom.alpha with the test's actual alpha). pwr returns
# none of them, so for the pwr tests pwrss's own version of the same test
# supplies them, and only when its power equals pwr's at that n (the same
# test, not an approximation of it).

# Read the details from a pwrss result, or NULL when it has none.
pwrss_details <- function(out, fun) {
  found <- grep("\\.alpha$", names(out), value = TRUE)
  found <- found[!vapply(out[found], function(x) all(is.na(x)), logical(1))]
  if (length(found) != 1) {
    return(NULL)
  }
  statistic <- switch(
    sub("\\.alpha$", "", found),
    t = "t", f = "F", z = "z", chisq = "chi-square", binom = "count",
    return(NULL)
  )
  # Critical counts are given only when they are out of the whole sample
  # (one proportion); McNemar's are out of the expected number of
  # discordant pairs, which would mislead.
  if (statistic == "count" && !identical(as.numeric(out$size), as.numeric(out$n))) {
    return(NULL)
  }
  df <- if (!is.null(out$df1)) c(out$df1, out$df2) else out$df
  # A z test's noncentrality is the mean of z under the alternative.
  ncp <- if (statistic == "z") out$mean else out$ncp
  list(
    statistic = statistic,
    df = if (is.null(df)) NA_real_ else as.numeric(df),
    critical = unname(as.numeric(out[[found]])),
    ncp = if (is.null(ncp) || statistic == "count") NA_real_ else as.numeric(ncp),
    actual_alpha = if (statistic == "count" && !is.null(out$alpha)) as.numeric(out$alpha) else NA_real_,
    source = sprintf("pwrss::%s", fun)
  )
}

# The full output of a pwrss call.
pwrss_output <- function(fun, args) {
  call_backend("pwrss", quietly(do.call(getExportedValue("pwrss", fun), args)))
}

# Details for a pwr test from pwrss's version of it, at total n; NULL when
# pwrss has no version of the test or its power differs from `power`.
pwr_details <- function(spec, inputs, n, power) {
  if (identical(inputs$package, "pwrss")) {
    args <- inputs$args(n)
    args[[inputs$alpha_arg]] <- inputs$alpha
    if (isTRUE(inputs$against_effect)) {
      return(NULL)
    }
    return(pwrss_details(pwrss_output(inputs$fun, args), inputs$fun))
  }
  twin <- pwrss_twin(spec, inputs, n)
  if (is.null(twin)) {
    return(NULL)
  }
  out <- tryCatch(pwrss_output(twin$fun, twin$args), error = function(e) NULL)
  if (is.null(out) || !isTRUE(abs(out$power - power) < 1e-6)) {
    return(NULL)
  }
  pwrss_details(out, twin$fun)
}

# pwrss's version of a pwr test (Student's t-tests, the two-proportions z
# test and the chi-square test of independence), with the same arguments.
pwrss_twin <- function(spec, inputs, n) {
  args <- inputs$args(n)
  alpha <- inputs$alpha
  side <- function(alternative) if (alternative == "two.sided") "two.sided" else "one.sided"
  switch(
    inputs$fun,
    pwr.t.test = list(fun = "power.t.student", args = list(
      d = args$d, n2 = args$n, n.ratio = 1, alpha = alpha,
      alternative = side(args$alternative),
      design = switch(args$type, two.sample = "independent", paired = "paired", one.sample = "one.sample"),
      ceil.n = FALSE, verbose = 0
    )),
    pwr.t2n.test = list(fun = "power.t.student", args = list(
      d = args$d, n2 = args$n2, n.ratio = args$n1 / args$n2, alpha = alpha,
      alternative = side(args$alternative), design = "independent",
      ceil.n = FALSE, verbose = 0
    )),
    power.prop.test = list(fun = "power.z.twoprops", args = list(
      prob1 = args$p1, prob2 = args$p2, n2 = args$n, n.ratio = 1, alpha = alpha,
      alternative = args$alternative, std.error = "pooled", verbose = FALSE
    )),
    pwr.chisq.test = list(fun = "power.chisq.gof", args = list(
      w = args$w, df = args$df, n = args$N, alpha = alpha, ceil.n = FALSE, verbose = 0
    )),
    NULL
  )
}
