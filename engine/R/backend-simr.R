# Backend adapter: participants responding to many items in two conditions
# (mixed_model / crossed_two_condition, E33), via simr.
#
# simr builds the population model with makeLmer() from the fixed effects,
# the random-effect variances and the residual SD, simulates data sets from
# it and refits each with lme4, testing the condition with powerSim()
# (Green & MacLeod, 2016: citation("simr")). The model is
#   y ~ cond + (1 + cond | participant) + (1 | item)
# with cond coded -0.5 and 0.5, so its coefficient is the difference between
# conditions; with every item in both conditions (item_design "within"), a
# by-item condition slope is added when its SD is above 0. The condition is
# tested with lmerTest's Satterthwaite t test (simr's method "sa"), not
# simr's default "z", which its help calls an asymptotic approximation for
# models fitted with lmer (the maintainer's decision, 30 October 2026;
# docs/conventions.md, Departure 16).

simr_backend <- function(spec, seed = NULL) {
  inputs <- simr_inputs(spec)
  list(
    name = "simr",
    packages = c("simr", "lme4", "lmerTest"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = "simr::powerSim with simr::fixed(\"cond\", \"sa\")"),
    n_step = 1,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) {
        simr_rejections(inputs, n, k, chunk_seed)
      })
    },
    sensitivity = NULL,
    check_run = function() simr_check_run(spec, inputs, seed)
  )
}

# The spec in simr's terms: the model formula, fixed effects, random-effect
# variances (VarCorr) and residual SD, and the design of one data set.
simr_inputs <- function(spec) {
  pop <- spec$population
  within <- identical(pop$item_design %||% "between", "within")
  item_slope <- within && (pop$sd_item_slope %||% 0) > 0
  r <- pop$r_participant %||% 0
  participant <- matrix(
    c(
      pop$sd_participant^2, r * pop$sd_participant * pop$sd_participant_slope,
      r * pop$sd_participant * pop$sd_participant_slope, pop$sd_participant_slope^2
    ),
    nrow = 2
  )
  item <- if (item_slope) diag(c(pop$sd_item^2, pop$sd_item_slope^2)) else pop$sd_item^2
  list(
    formula = if (item_slope) {
      y ~ cond + (1 + cond | participant) + (1 + cond | item)
    } else {
      y ~ cond + (1 + cond | participant) + (1 | item)
    },
    fixef = c(0, pop$difference),
    VarCorr = list(participant = participant, item = item),
    sigma = pop$sd_residual,
    items = pop$items,
    within = within,
    alpha = spec$target_test$alpha
  )
}

# One data set's design: every participant responds to every item, in one
# condition (items between conditions: the first half of the items in the
# first condition) or in both (items within).
simr_design <- function(inputs, n) {
  if (inputs$within) {
    data <- expand.grid(participant = seq_len(n), item = seq_len(inputs$items), cond = c(-0.5, 0.5))
  } else {
    data <- expand.grid(participant = seq_len(n), item = seq_len(inputs$items))
    data$cond <- ifelse(data$item <= inputs$items / 2, -0.5, 0.5)
  }
  data$participant <- factor(data$participant)
  data$item <- factor(data$item)
  data
}

simr_model <- function(inputs, n) {
  call_backend("simr", quietly(simr::makeLmer(
    inputs$formula, fixef = inputs$fixef, VarCorr = inputs$VarCorr,
    sigma = inputs$sigma, data = simr_design(inputs, n)
  )))
}

# Significant results in `nrep` data sets at n, as simr counts them: a
# data set whose fit or test fails counts as not significant (powerSim()'s
# x out of its n).
simr_rejections <- function(inputs, n, nrep, seed) {
  result <- call_backend("simr", quietly(simr::powerSim(
    simr_model(inputs, n),
    test = simr::fixed("cond", "sa"),
    nsim = as.integer(nrep),
    alpha = inputs$alpha,
    seed = seed,
    progress = FALSE
  )))
  c(result$x, result$n)
}

# Check run: one large data set simulated from simr's model (300
# participants, and at least 200 items so that the item variance is
# estimated well), refitted with lme4. The condition's difference, each
# random-effect SD, the participants' intercept-slope correlation and the
# residual SD must match the spec: the difference
# within 5 of its standard errors, an SD within 5 of its approximate
# standard errors (SD / sqrt(2 (groups - 1)); residual: SD / sqrt(2 N)).
simr_check_run <- function(spec, inputs, seed) {
  n <- 300L
  big <- inputs
  big$items <- max(inputs$items, 200L)
  if (!big$within && big$items %% 2 == 1) big$items <- big$items + 1L
  model <- simr_model(big, n)
  data <- simr_design(big, n)
  data$y <- with_seed(seed, stats::simulate(model)[[1]])
  fit <- call_backend("lme4", quietly(lme4::lmer(inputs$formula, data = data)))
  coefs <- summary(fit)$coefficients
  vc <- as.data.frame(lme4::VarCorr(fit))
  sd_of <- function(group, var1) vc$sdcor[vc$grp == group & vc$var1 %in% var1 & is.na(vc$var2)]
  pop <- spec$population
  sd_row <- function(label, specified, recovered, groups) {
    check_run_rows(label, specified, recovered, max(specified, 0.05) / sqrt(2 * (groups - 1)))
  }
  rows <- list(
    check_run_rows("difference between conditions", pop$difference, coefs["cond", "Estimate"], coefs["cond", "Std. Error"]),
    sd_row("SD of participant intercepts", pop$sd_participant, sd_of("participant", "(Intercept)"), n),
    sd_row("SD of participant condition slopes", pop$sd_participant_slope, sd_of("participant", "cond"), n),
    sd_row("SD of item intercepts", pop$sd_item, sd_of("item", "(Intercept)"), big$items),
    check_run_rows("residual SD", pop$sd_residual, sd_of("Residual", NA), pop$sd_residual / sqrt(2 * nrow(data)))
  )
  r <- pop$r_participant %||% 0
  recovered_r <- vc$sdcor[vc$grp == "participant" & vc$var1 == "(Intercept)" & vc$var2 %in% "cond"]
  if (length(recovered_r) && pop$sd_participant > 0 && pop$sd_participant_slope > 0) {
    rows <- c(rows, list(check_run_rows("correlation of participant intercepts and slopes", r, recovered_r, max(1 - r^2, 0.1) / sqrt(n - 3))))
  }
  if (length(sd_of("item", "cond"))) {
    rows <- c(rows, list(sd_row("SD of item condition slopes", pop$sd_item_slope, sd_of("item", "cond"), big$items)))
  }
  check <- do.call(rbind, rows)
  rownames(check) <- NULL
  check
}
