# Backend adapter: time-to-event (survival) outcomes, by formula.
#
#   log_rank       survival/log_rank: two groups compared on the time until
#                  an event, by the log-rank test (the Cox model's test of
#                  the group). Hmisc::cpower(): exponential times in each
#                  group (a constant hazard, so a constant hazard ratio),
#                  recruitment at an even rate over `accrual` and at least
#                  `follow_up` of follow-up, the expected number of events
#                  in each group from these (Schoenfeld's formulas, its
#                  help), and the two-sided test of the log hazard ratio
#                  with George and Desu's variance 1/m1 + 1/m2 (m the
#                  expected events in each group). cpower() takes the
#                  first group's proportion with the event by `time` (mc)
#                  and the percentage reduction in it in the second group
#                  (r), so r = 100 (1 - p2 / p1).
#
#   cox_predictor  survival/cox_predictor: a measured score's hazard ratio
#                  in a Cox model, possibly beside other predictors.
#                  powerSurvEpi::powerEpiCont.default(), Hsieh and
#                  Lavori's (2000) formula (its help): the two-sided test,
#                  power Phi(sqrt(n log(HR)^2 var(X) psi (1 - R^2)) -
#                  z), with psi the proportion of people with the event.
#                  powerkit takes the hazard ratio per SD of X, so var(X)
#                  is 1.
#
# Both are large-sample formulas for the number of events; no random
# numbers are drawn. The check runs simulate a large study from the model
# the formula assumes and recover its inputs with the survival package's
# Kaplan-Meier and Cox fits.

survival_backend <- function(spec, seed = NULL) {
  inputs <- survival_inputs(spec)
  step <- valid_n_step(spec)
  log_rank <- identical(spec$template, "log_rank")
  power_at <- function(n) call_backend(if (log_rank) "Hmisc" else "powerSurvEpi", survival_power(inputs, n))
  list(
    name = if (log_rank) "Hmisc" else "powerSurvEpi",
    packages = if (log_rank) c("Hmisc", "survival") else c("powerSurvEpi", "survival"),
    methods = "exact",
    default_method = "exact",
    functions = c(exact = if (log_rank) "Hmisc::cpower" else "powerSurvEpi::powerEpiCont.default"),
    n_step = step,
    exact_min_n = step * ceiling(minimum_n(spec) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() survival_check_run(spec, inputs, seed)
  )
}

survival_inputs <- function(spec) {
  pop <- spec$population
  tt <- spec$target_test
  if (identical(spec$template, "log_rank")) {
    p <- as.numeric(unlist(pop$p_event))
    ratio <- spec$options$allocation_ratio %||% 1
    list(
      template = "log_rank", alpha = tt$alpha, time = pop$time, p = p,
      reduction = 100 * (1 - p[2] / p[1]),
      accrual = pop$accrual %||% 0, follow_up = pop$follow_up,
      share = c(1, ratio) / (1 + ratio),
      # The hazard ratio the two proportions imply (exponential times).
      hazard_ratio = log(1 - p[2]) / log(1 - p[1])
    )
  } else {
    list(
      template = "cox_predictor", alpha = tt$alpha, hazard_ratio = pop$hazard_ratio,
      event_proportion = pop$event_proportion, r2_other = pop$r2_other %||% 0
    )
  }
}

survival_power <- function(inputs, n) {
  if (identical(inputs$template, "log_rank")) {
    groups <- n * inputs$share
    unname(Hmisc::cpower(
      tref = inputs$time, mc = inputs$p[1], r = inputs$reduction, accrual = inputs$accrual,
      tmin = inputs$follow_up, alpha = inputs$alpha, nc = groups[1], ni = groups[2], pr = FALSE
    ))
  } else {
    powerSurvEpi::powerEpiCont.default(
      n = n, theta = inputs$hazard_ratio, sigma2 = 1, psi = inputs$event_proportion,
      rho2 = inputs$r2_other, alpha = inputs$alpha
    )
  }
}

# The expected proportion of each group with an event during the study
# (log-rank), as cpower() computes it: exponential times, recruitment
# spread evenly over the accrual period.
survival_event_share <- function(inputs) {
  rate <- -log(1 - inputs$p) / inputs$time
  a <- inputs$accrual
  t_min <- inputs$follow_up
  if (a == 0) {
    1 - exp(-rate * t_min)
  } else {
    1 - (exp(-rate * t_min) - exp(-rate * (t_min + a))) / (a * rate)
  }
}

# Check run: one large study drawn from the model the formula assumes.
# Log-rank: exponential times in each group, recruitment times uniform over
# the accrual period, follow-up to the end of the study; the Kaplan-Meier
# estimate at `time` recovers each group's proportion with the event (in
# a study whose follow-up reaches it), and the Cox fit the hazard ratio.
# Cox predictor: X standard normal, exponential times with hazard
# exp(log(HR) X), censored at the time that gives the event proportion;
# the Cox fit recovers the hazard ratio per SD and the share of events.
survival_check_run <- function(spec, inputs, seed) {
  n <- check_run_n()
  with_seed(seed %||% 1L, {
    if (identical(inputs$template, "log_rank")) {
      survival_check_log_rank(inputs, n)
    } else {
      survival_check_cox(inputs, n)
    }
  })
}

survival_check_log_rank <- function(inputs, n) {
  sizes <- round(n * inputs$share)
  group <- rep(c(0, 1), sizes)
  rate <- (-log(1 - inputs$p) / inputs$time)[group + 1]
  event_time <- stats::rexp(length(group), rate)
  # Follow-up long enough to see `time` for everyone, for the Kaplan-Meier
  # check; the design's own follow-up decides the events counted.
  long <- max(inputs$time, inputs$follow_up) * 2
  km <- survival::survfit(survival::Surv(pmin(event_time, long), event_time <= long) ~ group)
  at <- summary(km, times = inputs$time)
  recovered_p <- 1 - at$surv
  fit <- survival::coxph(survival::Surv(pmin(event_time, long), event_time <= long) ~ group)
  recovered_hr <- exp(unname(stats::coef(fit)))
  # The design's events: recruited at an even rate, followed to the end.
  entry <- stats::runif(length(group), 0, inputs$accrual)
  follow <- inputs$accrual + inputs$follow_up - entry
  observed_share <- tapply(event_time <= follow, group, mean)
  expected_share <- survival_event_share(inputs)
  se_p <- sqrt(inputs$p * (1 - inputs$p) / sizes)
  se_share <- sqrt(expected_share * (1 - expected_share) / sizes)
  se_log_hr <- sqrt(1 / sum(sizes[1] * expected_share[1]) + 1 / sum(sizes[2] * expected_share[2]))
  data.frame(
    parameter = c(
      sprintf("proportion with the event by time %s, group %d (Kaplan-Meier)", format_number(inputs$time), 1:2),
      "hazard ratio, group 2 against group 1 (Cox model)",
      sprintf("proportion with an event during the study, group %d (what cpower() expects)", 1:2)
    ),
    specified = c(inputs$p, inputs$hazard_ratio, expected_share),
    recovered = c(recovered_p, recovered_hr, observed_share),
    ok = c(
      abs(recovered_p - inputs$p) < 4 * se_p,
      abs(log(recovered_hr) - log(inputs$hazard_ratio)) < 4 * se_log_hr,
      abs(observed_share - expected_share) < 4 * se_share
    )
  )
}

survival_check_cox <- function(inputs, n) {
  x <- stats::rnorm(n)
  beta <- log(inputs$hazard_ratio)
  event_time <- stats::rexp(n, exp(beta * x))
  # Censor everyone at the time that makes the expected share of events
  # the one specified (all events seen when it is 1).
  share_at <- function(c) mean(1 - exp(-exp(beta * stats::qnorm(seq(0.5, 999.5) / 1000)) * c))
  censor <- if (inputs$event_proportion >= 1) Inf else {
    stats::uniroot(function(c) share_at(c) - inputs$event_proportion, c(1e-8, 1e8), tol = 1e-10)$root
  }
  status <- event_time <= censor
  fit <- survival::coxph(survival::Surv(pmin(event_time, censor), status) ~ x)
  recovered_hr <- exp(unname(stats::coef(fit)))
  events <- sum(status)
  se_log_hr <- 1 / sqrt(max(events, 1))
  se_share <- sqrt(inputs$event_proportion * (1 - inputs$event_proportion) / n)
  data.frame(
    parameter = c("hazard ratio for 1 SD higher on X (Cox model)", "proportion of people with the event"),
    specified = c(inputs$hazard_ratio, inputs$event_proportion),
    recovered = c(recovered_hr, events / n),
    ok = c(
      abs(log(recovered_hr) - beta) < 4 * se_log_hr,
      abs(events / n - inputs$event_proportion) < 4 * se_share + 1e-9
    )
  )
}

# The schema already takes two-sided tests by formula only, and a zero
# effect is refused for a sample size with every design's
# (target_effect_is_zero()).
check_survival <- function(spec) character()

survival_design_description <- function(spec, label) {
  inputs <- survival_inputs(spec)
  if (identical(inputs$template, "log_rank")) {
    sprintf(
      "log-rank test of %s between the two groups of %s: %s and %s with the event by time %s (hazard ratio %s, exponential times), recruitment over %s and at least %s of follow-up",
      label("Y"), label("X"), format_number(inputs$p[1]), format_number(inputs$p[2]), format_number(inputs$time),
      format_number(round(inputs$hazard_ratio, 3)), format_number(inputs$accrual), format_number(inputs$follow_up)
    )
  } else {
    sprintf(
      "Cox regression of %s on %s: hazard ratio %s per SD of %s, %s of people with the event, R-squared %s with the other predictors",
      label("Y"), label("X"), format_number(inputs$hazard_ratio), label("X"),
      format_number(inputs$event_proportion), format_number(inputs$r2_other)
    )
  }
}

# The R script: the same package call at each size powerkit computed.
survival_script <- function(spec, result) {
  inputs <- survival_inputs(spec)
  log_rank <- identical(inputs$template, "log_rank")
  c(
    script_header(spec, result, if (log_rank) "Hmisc" else "powerSurvEpi",
      if (log_rank) "Hmisc::cpower" else "powerSurvEpi::powerEpiCont.default"),
    if (log_rank) "library(Hmisc)" else "library(powerSurvEpi)",
    "",
    "# Inputs ----",
    goal_inputs(spec, result),
    if (log_rank) {
      c(
        sprintf("time <- %s # the time at which the proportions with the event are given", r_code(inputs$time)),
        sprintf("p_event <- %s # proportion with the event by then: group 1, group 2", r_code(inputs$p)),
        sprintf("accrual <- %s # how long recruitment takes", r_code(inputs$accrual)),
        sprintf("follow_up <- %s # the shortest follow-up", r_code(inputs$follow_up)),
        sprintf("share <- %s # each group's share of the total", r_code(inputs$share)),
        "",
        "# cpower() takes group 1's proportion and the percentage reduction in",
        "# it in group 2; it assumes exponential times and a two-sided test.",
        "power_at <- function(n_total) {",
        "  groups <- n_total * share",
        "  unname(cpower(tref = time, mc = p_event[1], r = 100 * (1 - p_event[2] / p_event[1]),",
        "    accrual = accrual, tmin = follow_up, alpha = alpha, nc = groups[1], ni = groups[2], pr = FALSE))",
        "}"
      )
    } else {
      c(
        sprintf("hazard_ratio <- %s # for a person 1 SD higher on X", r_code(inputs$hazard_ratio)),
        sprintf("event_proportion <- %s # share of people with the event during the study", r_code(inputs$event_proportion)),
        sprintf("r2_other <- %s # R-squared of X on the other predictors", r_code(inputs$r2_other)),
        "",
        "# Hsieh and Lavori's (2000) formula, two-sided; X's variance is 1 because",
        "# the hazard ratio is per SD.",
        "power_at <- function(n_total) {",
        "  powerEpiCont.default(n = n_total, theta = hazard_ratio, sigma2 = 1,",
        "    psi = event_proportion, rho2 = r2_other, alpha = alpha)",
        "}"
      )
    },
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
