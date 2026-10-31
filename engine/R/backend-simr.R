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
# by-item condition slope is added when its SD is above 0. With the
# condition between participants (X a between factor), half the
# participants are in each condition, each with a random intercept only:
#   y ~ cond + (1 | participant) + (1 | item)  (or (1 + cond | item)).
# The condition is
# tested with lmerTest's Satterthwaite t test (simr's method "sa"), not
# simr's default "z", which its help calls an asymptotic approximation for
# models fitted with lmer (the maintainer's decision, 30 October 2026;
# docs/conventions.md, Departure 16).

simr_backend <- function(spec, seed = NULL) {
  two_level <- identical(spec$template, "two_level")
  inputs <- if (two_level) two_level_inputs(spec) else simr_inputs(spec)
  list(
    name = "simr",
    packages = c("simr", "lme4", "lmerTest"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = sprintf("simr::powerSim with simr::fixed(\"%s\", \"sa\")", inputs$term %||% "cond")),
    n_step = if (two_level) inputs$cluster_size else 1,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) {
        simr_rejections(inputs, n, k, chunk_seed)
      })
    },
    sensitivity = NULL,
    check_run = function() if (two_level) two_level_check_run(spec, inputs, seed) else simr_check_run(spec, inputs, seed)
  )
}

# The spec in simr's terms: the model formula, fixed effects, random-effect
# variances (VarCorr) and residual SD, and the design of one data set.
simr_inputs <- function(spec) {
  pop <- spec$population
  within <- identical(pop$item_design %||% "between", "within")
  participants_between <- identical(spec$variables$X$type, "between_factor")
  item_slope <- within && (pop$sd_item_slope %||% 0) > 0
  r <- pop$r_participant %||% 0
  participant <- if (participants_between) {
    pop$sd_participant^2
  } else {
    matrix(
      c(
        pop$sd_participant^2, r * pop$sd_participant * pop$sd_participant_slope,
        r * pop$sd_participant * pop$sd_participant_slope, pop$sd_participant_slope^2
      ),
      nrow = 2
    )
  }
  item <- if (item_slope) diag(c(pop$sd_item^2, pop$sd_item_slope^2)) else pop$sd_item^2
  participant_term <- if (participants_between) "(1 | participant)" else "(1 + cond | participant)"
  item_term <- if (item_slope) "(1 + cond | item)" else "(1 | item)"
  list(
    formula = stats::as.formula(paste("y ~ cond +", participant_term, "+", item_term), env = globalenv()),
    participants_between = participants_between,
    fixef = c(0, pop$difference),
    VarCorr = list(participant = participant, item = item),
    sigma = pop$sd_residual,
    items = pop$items,
    within = within,
    alpha = spec$target_test$alpha
  )
}

# One data set's design. Conditions within participants: every
# participant responds to every item, in one condition (items between
# conditions: the first half of the items in the first condition) or in
# both (items within). Conditions between participants: the first half of
# the participants in the first condition; each responds to every item
# (items within), or to the half of the items in their own condition
# (items between).
simr_design <- function(inputs, n) {
  if (isTRUE(inputs$participants_between)) {
    data <- expand.grid(participant = seq_len(n), item = seq_len(inputs$items))
    data$cond <- ifelse(data$participant <= n / 2, -0.5, 0.5)
    if (!inputs$within) data <- data[(data$item <= inputs$items / 2) == (data$cond < 0), ]
  } else if (inputs$within) {
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
    sigma = inputs$sigma, data = (inputs$design %||% simr_design)(inputs, n)
  )))
}

# Significant results in `nrep` data sets at n, as simr counts them: a
# data set whose fit or test fails counts as not significant (powerSim()'s
# x out of its n).
simr_rejections <- function(inputs, n, nrep, seed) {
  result <- call_backend("simr", quietly(simr::powerSim(
    simr_model(inputs, n),
    test = simr::fixed(inputs$term %||% "cond", "sa"),
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
    if (!isTRUE(inputs$participants_between)) {
      sd_row("SD of participant condition slopes", pop$sd_participant_slope, sd_of("participant", "cond"), n)
    },
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

# People nested in groups (mixed_model / two_level, E41): a predictor X
# measured on each person, centred within its group, and W measured on
# each group, in y ~ x + w + x:w + (1 + x | group), with the effect chosen
# tested by Satterthwaite's t test as for E33. X takes the same evenly
# spread standard normal values (normal quantiles) in every group, so it
# is centred within groups with SD 1 and uncorrelated with W; W takes
# evenly spread standard normal values across the groups. The design is
# fixed, as simr's are; only the outcome is simulated.
two_level_inputs <- function(spec) {
  pop <- spec$population
  r <- pop$r_group %||% 0
  group <- matrix(c(pop$sd_group^2, r * pop$sd_group * pop$sd_group_slope,
                    r * pop$sd_group * pop$sd_group_slope, pop$sd_group_slope^2), nrow = 2)
  list(
    formula = y ~ x + w + x:w + (1 + x | group),
    fixef = c(0, pop$b_X, pop$b_W, pop$b_XW),
    VarCorr = list(group = group),
    sigma = pop$sd_residual,
    cluster_size = pop$cluster_size,
    term = switch(spec$target_test$effect, within_effect = "x", between_effect = "w", cross_level_interaction = "x:w"),
    design = two_level_design,
    alpha = spec$target_test$alpha
  )
}

# One data set's design: n people in n / cluster_size groups.
two_level_design <- function(inputs, n) {
  m <- inputs$cluster_size
  groups <- n %/% m
  x <- stats::qnorm(seq_len(m) / (m + 1))
  w <- stats::qnorm((seq_len(groups) - 0.5) / groups)
  data.frame(
    group = factor(rep(seq_len(groups), each = m)),
    x = rep((x - mean(x)) / sqrt(mean((x - mean(x))^2)), groups),
    w = rep((w - mean(w)) / sqrt(mean((w - mean(w))^2)), each = m)
  )
}

# Check run: one large data set (2,000 groups) simulated from simr's
# model and refitted with lme4: each fixed effect within 5 of its standard
# errors, each SD within 5 of its approximate standard errors, as for E33.
two_level_check_run <- function(spec, inputs, seed) {
  n <- 2000L * inputs$cluster_size
  model <- simr_model(inputs, n)
  data <- two_level_design(inputs, n)
  data$y <- with_seed(seed, stats::simulate(model)[[1]])
  fit <- call_backend("lme4", quietly(lme4::lmer(inputs$formula, data = data)))
  coefs <- summary(fit)$coefficients
  vc <- as.data.frame(lme4::VarCorr(fit))
  sd_of <- function(var1) vc$sdcor[vc$grp == "group" & vc$var1 %in% var1 & is.na(vc$var2)]
  pop <- spec$population
  groups <- n / inputs$cluster_size
  # A group SD is estimated from the groups' own estimates, which also
  # carry each group's sampling error (the residual variance over the
  # group's size, for the intercept, or over its sum of squared X, for the
  # slope): the variance's standard error is that total times
  # sqrt(2 / (groups - 1)), and the SD's is half of it over the SD.
  m <- inputs$cluster_size
  sd_row <- function(label, specified, recovered, noise) {
    se_var <- (specified^2 + noise) * sqrt(2 / (groups - 1))
    check_run_rows(label, specified, recovered, se_var / (2 * max(specified, 0.05)))
  }
  check <- rbind(
    check_run_rows(c("X's effect within groups", "W's effect between groups", "cross-level interaction"),
      c(pop$b_X, pop$b_W, pop$b_XW), coefs[c("x", "w", "x:w"), "Estimate"], coefs[c("x", "w", "x:w"), "Std. Error"]),
    sd_row("SD of group intercepts", pop$sd_group, sd_of("(Intercept)"), pop$sd_residual^2 / m),
    sd_row("SD of group X slopes", pop$sd_group_slope, sd_of("x"), pop$sd_residual^2 / m),
    check_run_rows("residual SD", pop$sd_residual, vc$sdcor[vc$grp == "Residual"], pop$sd_residual / sqrt(2 * n))
  )
  rownames(check) <- NULL
  check
}

# The standalone script for the two-level design: simr alone, with the same
# design and test (export_script()).
two_level_script <- function(spec, result) {
  inputs <- two_level_inputs(spec)
  pop <- spec$population
  v <- spec$variables
  c(
    script_header(spec, result, "simr", sprintf("simr::powerSim() with fixed(\"%s\", \"sa\")", inputs$term)),
    "library(simr)",
    "library(lmerTest) # the Satterthwaite t test (simr's method \"sa\")",
    "",
    "# Inputs ----",
    sprintf("# The outcome, %s, in its own units; x is %s (per SD, centred within each group),",
      comment_text(v$Y$label), comment_text(v$X$label)),
    sprintf("# w is %s (per SD, measured on each group).", comment_text(v$W$label)),
    sprintf("b_x <- %s # X's effect within groups", r_code(pop$b_X)),
    sprintf("b_w <- %s # W's effect between groups", r_code(pop$b_W)),
    sprintf("b_xw <- %s # the cross-level interaction", r_code(pop$b_XW)),
    sprintf("sd_group <- %s # SD of the groups' intercepts", r_code(pop$sd_group)),
    sprintf("sd_group_slope <- %s # SD of the groups' X slopes", r_code(pop$sd_group_slope)),
    sprintf("r_group <- %s # correlation of the groups' intercepts and slopes", r_code(pop$r_group %||% 0)),
    sprintf("sd_residual <- %s # residual SD", r_code(pop$sd_residual)),
    sprintf("cluster_size <- %s # people in each group", r_code(pop$cluster_size)),
    sprintf("term <- %s # the effect tested", r_code(inputs$term)),
    goal_inputs(spec, result),
    "",
    "# One data set's design: n people in n / cluster_size groups; x takes the",
    "# same evenly spread standard normal values in every group, w evenly spread",
    "# values across the groups (both standardised).",
    "design_for <- function(n_people) {",
    "  groups <- n_people %/% cluster_size",
    "  x <- qnorm(seq_len(cluster_size) / (cluster_size + 1))",
    "  w <- qnorm((seq_len(groups) - 0.5) / groups)",
    "  data.frame(",
    "    group = factor(rep(seq_len(groups), each = cluster_size)),",
    "    x = rep((x - mean(x)) / sqrt(mean((x - mean(x))^2)), groups),",
    "    w = rep((w - mean(w)) / sqrt(mean((w - mean(w))^2)), each = cluster_size)",
    "  )",
    "}",
    "",
    "# The population model: fixed effects, the groups' variances and the residual SD.",
    "model_for <- function(n_people) {",
    "  group <- matrix(c(sd_group^2, r_group * sd_group * sd_group_slope,",
    "    r_group * sd_group * sd_group_slope, sd_group_slope^2), nrow = 2)",
    "  makeLmer(y ~ x + w + x:w + (1 + x | group), fixef = c(0, b_x, b_w, b_xw),",
    "    VarCorr = list(group = group), sigma = sd_residual, data = design_for(n_people))",
    "}",
    "",
    "# One batch of simulated data sets: significant results and data sets.",
    "# simr counts a data set whose fit or test fails as not significant.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  result <- powerSim(model_for(batch_n), test = fixed(term, \"sa\"),",
    "    nsim = batch_replications, alpha = alpha, seed = batch_seed, progress = FALSE)",
    "  c(result$x, result$n)",
    "}",
    "",
    batch_section(result, "powerSim()"),
    simulation_goal_section(spec, result, inputs$cluster_size),
    comparison_section()
  )
}
