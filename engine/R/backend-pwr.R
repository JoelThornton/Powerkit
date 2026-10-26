# Backend adapter: basic tests by exact analytic formula, via pwr.
#
# The default for basic tests (one-sample, Student's independent and paired
# t-tests, correlation, two proportions, chi-square test of independence;
# two proportions use base R's power.prop.test() for equal groups and
# pwrss for unequal groups),
# because an exact answer exists for them and a formula has no Monte Carlo
# noise (docs/decisions.md, 17 October 2026; docs/conventions.md, Departure
# 9). Spower simulation stays available with options > method =
# "simulation", and is used for Welch's t-test, which pwr doesn't cover.
#
# Each template is one pwr call, as a user would make it:
#   one-sample, paired t   pwr.t.test(type = "one.sample" / "paired");
#                          the paired test's d is d_z
#   independent t          pwr.t.test(type = "two.sample") for equal
#                          groups, pwr.t2n.test() otherwise
#   correlation            pwr.r.test() (Fisher's z approximation)
#   two proportions        the z test with pooled variance under the null
#                          and no continuity correction, which equals
#                          G*Power's z test (docs/gpower-parity.md, E5;
#                          Departure 11): stats::power.prop.test(strict =
#                          TRUE) for equal groups, and
#                          pwrss::power.z.twoprops(std.error = "pooled")
#                          for unequal groups (power.prop.test() takes one
#                          n). options > proportions_formula = "arcsine":
#                          pwr.2p2n.test() with Cohen's h = ES.h(p2, p1)
#                          (the arcsine approximation)
#   chi-square             pwr.chisq.test() with Cohen's w = ES.w2(P),
#                          df = (rows - 1) x (columns - 1)
# The spec's effects are group 2 minus group 1 (d, h) and second minus first
# condition (dz), so the spec's "greater" is pwr's "greater".

# Basic-test templates pwr covers (Welch's t-test isn't covered).
pwr_covers <- function(spec) {
  spec$design == "basic_test" &&
    !pwrss_only(spec) &&
    !spower_only(spec) &&
    !identical(spec$target_test$method, "welch_t")
}

pwr_backend <- function(spec, seed = NULL) {
  inputs <- pwr_inputs(spec)
  step <- valid_n_step(spec)
  # pwr.r.test() needs n > 3; every other call accepts the design's minimum.
  n_min <- step * ceiling(max(minimum_n(spec), 4) / step)
  power_at <- function(n) pwr_power(inputs, n)
  list(
    name = inputs$package,
    packages = inputs$package,
    methods = "exact",
    default_method = "exact",
    functions = c(exact = inputs$description),
    n_step = step,
    exact_min_n = n_min,
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = function(n, power) pwr_sensitivity(spec, n, power),
    check_run = function() pwr_check_run(spec, inputs)
  )
}

# Translate a validated basic-test spec into pwr's terms: the function and
# its arguments at total sample size n.
pwr_inputs <- function(spec) {
  pop <- spec$population
  ratio <- spec$options$allocation_ratio %||% 1
  alternative <- pwr_alternative(spec$target_test$alternative %||% "two_sided")
  groups <- function(n) {
    n1 <- round(n / (1 + ratio))
    c(n1, n - n1)
  }
  equal <- isTRUE(all.equal(ratio, 1))
  call <- switch(
    spec$template,
    one_sample_t = list(
      fun = "pwr.t.test",
      args = function(n) list(n = n, d = pop$d, type = "one.sample", alternative = alternative)
    ),
    independent_t = if (equal) {
      list(
        fun = "pwr.t.test",
        args = function(n) list(n = n / 2, d = pop$d, type = "two.sample", alternative = alternative)
      )
    } else {
      list(
        fun = "pwr.t2n.test",
        args = function(n) {
          g <- groups(n)
          list(n1 = g[1], n2 = g[2], d = pop$d, alternative = alternative)
        }
      )
    },
    paired_t = list(
      fun = "pwr.t.test",
      args = function(n) list(n = n, d = pop$dz, type = "paired", alternative = alternative)
    ),
    correlation = list(
      fun = "pwr.r.test",
      args = function(n) list(n = n, r = pop$r, alternative = alternative)
    ),
    two_proportions = if (proportions_z_test(spec) && !equal) {
      list(
        package = "pwrss",
        fun = "power.z.twoprops",
        alpha_arg = "alpha",
        args = function(n) {
          g <- groups(n)
          # pwrss's n.ratio is n1 / n2 (the spec's allocation ratio is
          # n2 / n1).
          list(
            prob1 = pop$p1, prob2 = pop$p2, n2 = g[2], n.ratio = g[1] / g[2],
            alternative = if (alternative == "two.sided") "two.sided" else "one.sided",
            std.error = "pooled", verbose = FALSE
          )
        }
      )
    } else if (proportions_z_test(spec)) {
      list(
        package = "stats",
        fun = "power.prop.test",
        args = function(n) {
          list(
            n = n / 2, p1 = pop$p1, p2 = pop$p2,
            alternative = if (alternative == "two.sided") "two.sided" else "one.sided",
            strict = TRUE
          )
        }
      )
    } else {
      list(
        fun = "pwr.2p2n.test",
        args = function(n) {
          g <- groups(n)
          list(h = pwr_h(pop), n1 = g[1], n2 = g[2], alternative = alternative)
        }
      )
    },
    chi_square_independence = {
      p <- probability_matrix(spec)
      list(
        fun = "pwr.chisq.test",
        args = function(n) list(w = pwr_w(p), N = n, df = (nrow(p) - 1) * (ncol(p) - 1))
      )
    }
  )
  call$package <- call$package %||% "pwr"
  call$alpha_arg <- call$alpha_arg %||% "sig.level"
  call$alpha <- spec$target_test$alpha
  call$description <- sprintf("%s::%s", call$package, call$fun)
  call$against_effect <- against_effect(spec)
  call
}

# Two proportions by the z test (power.prop.test() for equal groups,
# pwrss for unequal groups): the default. Cohen's h only on request.
proportions_z_test <- function(spec) {
  !identical(spec$options$proportions_formula, "arcsine")
}

# TRUE for a one-sided two-proportions z test whose alternative points away
# from the specified difference ("greater" with p2 < p1, or "less" with
# p2 > p1). power.prop.test() and pwrss's power.z.twoprops() use |p1 - p2|
# for a one-sided test, so they can't tell the directions apart;
# pwr_power() handles this case.
against_effect <- function(spec) {
  if (!identical(spec$template, "two_proportions") || !proportions_z_test(spec)) {
    return(FALSE)
  }
  diff <- spec$population$p2 - spec$population$p1
  switch(
    spec$target_test$alternative %||% "two_sided",
    two_sided = FALSE,
    greater = diff < 0,
    less = diff > 0
  )
}

pwr_alternative <- function(alternative) {
  switch(alternative, two_sided = "two.sided", greater = "greater", less = "less")
}

# Cohen's h for p2 versus p1 (positive when p2 > p1).
pwr_h <- function(pop) pwr::ES.h(pop$p2, pop$p1)

# Cohen's w for a table of cell probabilities (independence as the null).
pwr_w <- function(p) pwr::ES.w2(p)

# Power at total sample size n, from the pwr (or stats, or pwrss) call.
#
# A one-sided z test against the specified direction rejects only in the
# tail away from the effect. The z test's two-sided power at 2 x alpha
# (power.prop.test() with strict = TRUE, or pwrss) is the sum of both tails
# at alpha each, and its one-sided power at alpha is the tail toward the
# effect, so the difference is the power of the test against the effect
# (it is below alpha).
pwr_power <- function(inputs, n) {
  power_of <- function(args) {
    fun <- getExportedValue(inputs$package, inputs$fun)
    call_backend(inputs$package, quietly(do.call(fun, args)))$power
  }
  args <- inputs$args(n)
  args[[inputs$alpha_arg]] <- inputs$alpha
  if (!isTRUE(inputs$against_effect)) {
    return(power_of(args))
  }
  both <- args
  both$alternative <- "two.sided"
  both[[inputs$alpha_arg]] <- 2 * inputs$alpha
  power_of(both) - power_of(args)
}

# Check run: there is no simulated data to recover the population from, so
# the check confirms the effect size pwr receives is the one the spec gives
# (for proportions and tables, Cohen's h and w computed from them).
pwr_check_run <- function(spec, inputs) {
  args <- inputs$args(1000)
  pop <- spec$population
  row <- function(parameter, specified, passed) {
    data.frame(
      parameter = parameter, specified = specified, recovered = passed,
      ok = isTRUE(all.equal(specified, passed))
    )
  }
  switch(
    spec$template,
    one_sample_t = row("d passed to pwr", pop$d, args$d),
    independent_t = row("d passed to pwr (group 2 minus group 1)", pop$d, args$d),
    paired_t = row("d_z passed to pwr", pop$dz, args$d),
    correlation = row("r passed to pwr", pop$r, args$r),
    two_proportions = if (identical(inputs$package, "pwrss")) {
      rbind(
        row("p1 passed to pwrss (prob1)", pop$p1, args$prob1),
        row("p2 passed to pwrss (prob2)", pop$p2, args$prob2)
      )
    } else if (proportions_z_test(spec)) {
      rbind(
        row("p1 passed to power.prop.test", pop$p1, args$p1),
        row("p2 passed to power.prop.test", pop$p2, args$p2)
      )
    } else {
      row(
        "Cohen's h passed to pwr (2 asin(sqrt(p2)) - 2 asin(sqrt(p1)))",
        2 * asin(sqrt(pop$p2)) - 2 * asin(sqrt(pop$p1)), args$h
      )
    },
    chi_square_independence = {
      p <- probability_matrix(spec)
      expected <- outer(rowSums(p), colSums(p))
      row("Cohen's w passed to pwr", sqrt(sum((p - expected)^2 / expected)), args$w)
    }
  )
}

# Sensitivity: the smallest effect with the target power at total sample
# size n, in the direction of the specified effect.
#
# For the t-tests, the correlation and the chi-square test, pwr solves for
# the effect itself when it is left NULL (each function's help: "Exactly
# one of the parameters ... must be passed as NULL, and that parameter is
# determined from the others"), so powerkit makes that call. For a
# two-sided test pwr returns a positive effect; powerkit gives it the sign
# of the specified effect. For two proportions, powerkit keeps p1 and
# searches p2 with the same power calls it uses for power (pwr_power()),
# as search_n() does for n.
pwr_sensitivity <- function(spec, n, target) {
  pop <- spec$population
  alpha <- spec$target_test$alpha
  alternative <- pwr_alternative(spec$target_test$alternative %||% "two_sided")
  ratio <- spec$options$allocation_ratio %||% 1
  equal <- isTRUE(all.equal(ratio, 1))
  signed <- function(value, specified) {
    # A zero specified effect (none given) gives a positive result.
    if (alternative == "two.sided" && isTRUE(specified < 0)) -abs(value) else value
  }
  solve <- function(fun, args, field) {
    args$sig.level <- alpha
    args$power <- target
    found <- tryCatch(
      call_backend("pwr", quietly(do.call(getExportedValue("pwr", fun), args))),
      error = function(e) NULL
    )
    if (is.null(found) || !is.finite(found[[field]])) {
      abort_run(paste0(
        "No effect in the direction you specified reaches the target power at this n. ",
        "Check the direction of the test and the population values."
      ))
    }
    found[[field]]
  }
  found <- switch(
    spec$template,
    one_sample_t = {
      d <- signed(solve("pwr.t.test", list(n = n, d = NULL, type = "one.sample", alternative = alternative), "d"), pop$d)
      list(effect = d, effect_name = "d", effect_description = "Cohen's d (mean minus the comparison value, in SDs)")
    },
    independent_t = {
      d <- if (equal) {
        solve("pwr.t.test", list(n = n / 2, d = NULL, type = "two.sample", alternative = alternative), "d")
      } else {
        n1 <- round(n / (1 + ratio))
        solve("pwr.t2n.test", list(n1 = n1, n2 = n - n1, d = NULL, alternative = alternative), "d")
      }
      list(effect = signed(d, pop$d), effect_name = "d", effect_description = "Cohen's d (group 2 minus group 1, in SDs)")
    },
    paired_t = {
      dz <- signed(solve("pwr.t.test", list(n = n, d = NULL, type = "paired", alternative = alternative), "d"), pop$dz)
      list(effect = dz, effect_name = "d_z", effect_description = "Cohen's d_z (mean of the differences, in SDs of the differences)")
    },
    correlation = {
      r <- signed(solve("pwr.r.test", list(n = n, r = NULL, alternative = alternative), "r"), pop$r)
      list(effect = r, effect_name = "r", effect_description = "correlation r")
    },
    chi_square_independence = {
      p <- probability_matrix(spec)
      df <- (nrow(p) - 1) * (ncol(p) - 1)
      w <- solve("pwr.chisq.test", list(N = n, w = NULL, df = df), "w")
      # The power at w, from the same pwr call as for power: a table with
      # no departure from independence (none given) has nothing to scale.
      power <- call_backend("pwr", quietly(pwr::pwr.chisq.test(w = w, N = n, df = df, sig.level = alpha)))$power
      list(effect = w, effect_name = "w", effect_description = "Cohen's w (departure from independence)", power = power)
    },
    two_proportions = pwr_sensitivity_p2(spec, n, target)
  )
  found$power <- found$power %||% pwr_power(pwr_inputs(pwr_spec_with_effect(spec, found)), n)
  found
}

# The spec with the population effect replaced by a sensitivity result, so
# the power at that effect can be checked with the usual power call.
pwr_spec_with_effect <- function(spec, found) {
  field <- switch(found$effect_name, d = "d", d_z = "dz", r = "r", p2 = "p2")
  spec$population[[field]] <- found$effect
  spec
}

# Two proportions: keep p1 and move p2 away from it, in the direction of
# the specified difference, until power reaches the target. With no
# difference given (p2 equal to p1), group 2's proportion goes up.
pwr_sensitivity_p2 <- function(spec, n, target) {
  p1 <- spec$population$p1
  direction <- if (spec$population$p2 >= p1) 1 else -1
  limit <- if (direction > 0) 1 - 1e-9 else 1e-9
  power_at <- function(p2) {
    trial <- spec
    trial$population$p2 <- p2
    pwr_power(pwr_inputs(trial), n)
  }
  if (power_at(limit) < target) {
    abort_run(paste0(
      "No proportion in group 2 reaches the target power at this n with group 1's ",
      "proportion as given. Check the direction of the test and the population values."
    ))
  }
  p2 <- stats::uniroot(
    function(p) power_at(p) - target,
    lower = min(p1, limit), upper = max(p1, limit), tol = 1e-10
  )$root
  list(
    effect = p2, effect_name = "p2",
    effect_description = sprintf("proportion in group 2 (group 1's proportion kept at %s)", format(p1)),
    p1 = p1
  )
}
