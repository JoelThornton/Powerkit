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
  conditions <- identical(spec$template, "crossed_conditions")
  three <- identical(spec$template, "three_level")
  item <- identical(spec$template, "item_predictor")
  inputs <- if (two_level) two_level_inputs(spec) else if (conditions) crossed_conditions_inputs(spec) else
    if (three) three_level_inputs(spec) else if (item) item_predictor_inputs(spec) else simr_inputs(spec)
  if (conditions) inputs$test <- crossed_conditions_test(inputs)
  list(
    name = "simr",
    packages = c("simr", "lme4", "lmerTest"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = if (conditions) sprintf("simr::powerSim with %s", inputs$test_label) else
      sprintf("simr::powerSim with simr::fixed(\"%s\", \"%s\")", inputs$term %||% "cond", inputs$method %||% "sa")),
    n_step = if (two_level) inputs$unit_size else if (three) inputs$site_size * if (identical(inputs$level, "site")) 2 else 1 else 1,
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(k, chunk_seed) {
        simr_rejections(inputs, n, k, chunk_seed)
      })
    },
    sensitivity = NULL,
    check_run = function() {
      if (two_level) two_level_check_run(spec, inputs, seed) else if (conditions) crossed_conditions_check_run(spec, inputs, seed) else
        if (three) three_level_check_run(spec, inputs, seed) else if (item) item_predictor_check_run(spec, inputs, seed) else
          simr_check_run(spec, inputs, seed)
    }
  )
}

# A yes/no outcome on each trial (31 October 2026): a logistic mixed
# model, glmer's binomial family, built by simr's makeGlmer(). The
# condition's probabilities are those of a typical participant and item
# (random effects 0), and every SD is on the log-odds scale. The test is
# the Wald test ("wald": glmer's z test, simr's default for a numeric
# predictor; for three or more conditions the Wald chi-square test, simr's
# "chisq" through car; for a pair car's Wald test of its contrast) or the
# likelihood-ratio test ("likelihood_ratio": simr's "lr"; for a pair, the
# model against one in which the pair's two conditions share a mean).
crossed_binary <- function(spec) identical(spec$variables$Y$type, "binary")

# simr's method for the test chosen.
simr_method <- function(spec) {
  three <- identical(spec$template, "crossed_conditions")
  switch(spec$target_test$method, satterthwaite_t = "sa", satterthwaite_f = "sa", wald = if (three) "chisq" else "z",
    likelihood_ratio = "lr")
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
  binary <- crossed_binary(spec)
  logits <- if (binary) stats::qlogis(as.numeric(unlist(pop$probabilities)))
  list(
    formula = stats::as.formula(paste("y ~ cond +", participant_term, "+", item_term), env = globalenv()),
    participants_between = participants_between,
    binary = binary,
    method = simr_method(spec),
    fixef = if (binary) c(mean(logits), diff(logits)) else c(0, pop$difference),
    VarCorr = list(participant = participant, item = item),
    sigma = if (!binary) pop$sd_residual,
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
  data <- (inputs$design %||% simr_design)(inputs, n)
  if (isTRUE(inputs$binary)) {
    return(call_backend("simr", quietly(simr::makeGlmer(
      inputs$formula, family = "binomial", fixef = inputs$fixef, VarCorr = inputs$VarCorr, data = data
    ))))
  }
  call_backend("simr", quietly(simr::makeLmer(
    inputs$formula, fixef = inputs$fixef, VarCorr = inputs$VarCorr,
    sigma = inputs$sigma, data = data
  )))
}

# Refit the population model to one data set: lme4's lmer() or, for a
# yes/no outcome, glmer().
simr_refit <- function(inputs, data) {
  if (isTRUE(inputs$binary)) {
    return(call_backend("lme4", quietly(lme4::glmer(inputs$formula, data = data, family = stats::binomial()))))
  }
  call_backend("lme4", quietly(lme4::lmer(inputs$formula, data = data)))
}

# The residual noise in one group's estimate, for a check run's SD rows:
# the residual variance, or on the log-odds scale for a yes/no outcome
# the binomial variance 1 / (p (1 - p)) averaged over the conditions,
# over the observations in each group.
simr_noise <- function(inputs, pop, per_group) {
  unit <- if (isTRUE(inputs$binary)) {
    p <- stats::plogis(inputs$fixef[1] + c(0, inputs$fixef[-1]))
    mean(1 / (p * (1 - p)))
  } else {
    pop$sd_residual^2
  }
  unit / per_group
}

# Significant results in `nrep` data sets at n, as simr counts them: a
# data set whose fit or test fails counts as not significant (powerSim()'s
# x out of its n).
simr_rejections <- function(inputs, n, nrep, seed) {
  result <- call_backend("simr", quietly(simr::powerSim(
    simr_model(inputs, n),
    test = inputs$test %||% simr::fixed(inputs$term %||% "cond", inputs$method %||% "sa"),
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
  fit <- simr_refit(inputs, data)
  coefs <- summary(fit)$coefficients
  vc <- as.data.frame(lme4::VarCorr(fit))
  sd_of <- function(group, var1) vc$sdcor[vc$grp == group & vc$var1 %in% var1 & is.na(vc$var2)]
  pop <- spec$population
  # An SD is estimated from its groups' own estimates, which also carry
  # the residual noise over each group's observations (as for E62).
  sd_row <- function(label, specified, recovered, groups) {
    se_var <- (specified^2 + simr_noise(inputs, pop, nrow(data) / groups)) * sqrt(2 / (groups - 1))
    check_run_rows(label, specified, recovered, se_var / (2 * max(specified, 0.05)))
  }
  rows <- list(
    if (isTRUE(inputs$binary)) {
      check_run_rows("difference between conditions (log odds)", inputs$fixef[2], coefs["cond", "Estimate"], coefs["cond", "Std. Error"])
    } else {
      check_run_rows("difference between conditions", pop$difference, coefs["cond", "Estimate"], coefs["cond", "Std. Error"])
    },
    sd_row("SD of participant intercepts", pop$sd_participant, sd_of("participant", "(Intercept)"), n),
    if (!isTRUE(inputs$participants_between)) {
      sd_row("SD of participant condition slopes", pop$sd_participant_slope, sd_of("participant", "cond"), n)
    },
    sd_row("SD of item intercepts", pop$sd_item, sd_of("item", "(Intercept)"), big$items),
    if (!isTRUE(inputs$binary)) check_run_rows("residual SD", pop$sd_residual, sd_of("Residual", NA), pop$sd_residual / sqrt(2 * nrow(data)))
  )
  r <- pop$r_participant %||% 0
  recovered_r <- vc$sdcor[vc$grp == "participant" & vc$var1 == "(Intercept)" & vc$var2 %in% "cond"]
  if (length(recovered_r) && pop$sd_participant > 0 && pop$sd_participant_slope > 0) {
    # The correlation is estimated from participants' own intercepts and
    # slopes, each with noise over the participant's observations (a
    # slope's over their spread in cond, 0.25 per observation): its
    # standard error grows as their reliabilities fall.
    per <- nrow(data) / n
    reliability <- function(sd, noise) sd^2 / (sd^2 + noise)
    rel <- reliability(pop$sd_participant, simr_noise(inputs, pop, per)) *
      reliability(pop$sd_participant_slope, simr_noise(inputs, pop, per * 0.25))
    rows <- c(rows, list(check_run_rows("correlation of participant intercepts and slopes", r, recovered_r,
      max(1 - r^2, 0.1) / sqrt(n - 3) / sqrt(rel))))
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
# fixed, as simr's are; only the outcome is simulated. A yes/no outcome
# (1 November 2026) is a logistic mixed model built by makeGlmer(): the
# chance of 'yes' for a typical group at the average X and W, every effect
# and SD on the log-odds scale, tested by glmer's Wald z test (simr's
# default for a numeric predictor) or the likelihood ratio, as for E33 and
# E67.
two_level_inputs <- function(spec) {
  pop <- spec$population
  r <- pop$r_group %||% 0
  group <- matrix(c(pop$sd_group^2, r * pop$sd_group * pop$sd_group_slope,
                    r * pop$sd_group * pop$sd_group_slope, pop$sd_group_slope^2), nrow = 2)
  binary <- crossed_binary(spec)
  three <- !is.null(pop$groups_per_site)
  # Three levels (1 November 2026): the groups are in sites, with a
  # predictor Z measured on each site, its interaction with X, and the
  # sites' own intercepts and (when sd_site_slope is above 0) X slopes.
  site_slope <- three && (pop$sd_site_slope %||% 0) > 0
  formula <- if (three) {
    paste("y ~ x + w + z + x:w + x:z +", if (site_slope) "(1 + x | site)" else "(1 | site)", "+ (1 + x | site:group)")
  } else {
    "y ~ x + w + x:w + (1 + x | group)"
  }
  var_corr <- if (three) {
    list(site = if (site_slope) diag(c(pop$sd_site^2, pop$sd_site_slope^2)) else pop$sd_site^2, "site:group" = group)
  } else {
    list(group = group)
  }
  list(
    formula = stats::as.formula(formula, env = globalenv()),
    binary = binary,
    three = three,
    method = switch(spec$target_test$method, satterthwaite_t = "sa", wald = "z", likelihood_ratio = "lr"),
    fixef = c(if (binary) stats::qlogis(pop$probability) else 0, pop$b_X, pop$b_W, if (three) pop$b_Z, pop$b_XW, if (three) pop$b_XZ),
    VarCorr = var_corr,
    sigma = if (!binary) pop$sd_residual,
    cluster_size = pop$cluster_size,
    groups_per_site = pop$groups_per_site,
    unit_size = pop$cluster_size * (pop$groups_per_site %||% 1),
    term = switch(spec$target_test$effect, within_effect = "x", between_effect = "w", site_effect = "z",
      cross_level_interaction = "x:w", site_interaction = "x:z"),
    design = two_level_design,
    alpha = spec$target_test$alpha
  )
}

# One data set's design: n people in n / cluster_size groups (and, with
# three levels, the groups in sites of groups_per_site). X takes the same
# standardised normal quantiles in every group; W takes them across the
# groups (within each site, with three levels, so that W is uncorrelated
# with Z); Z takes them across the sites.
two_level_design <- function(inputs, n) {
  spread <- function(k, inner) {
    v <- stats::qnorm(if (inner) seq_len(k) / (k + 1) else (seq_len(k) - 0.5) / k)
    (v - mean(v)) / sqrt(mean((v - mean(v))^2))
  }
  m <- inputs$cluster_size
  if (!isTRUE(inputs$three)) {
    groups <- n %/% m
    return(data.frame(
      group = factor(rep(seq_len(groups), each = m)),
      x = rep(spread(m, TRUE), groups),
      w = rep(spread(groups, FALSE), each = m)
    ))
  }
  k <- inputs$groups_per_site
  sites <- n %/% (m * k)
  data.frame(
    site = factor(rep(seq_len(sites), each = m * k)),
    group = factor(rep(rep(seq_len(k), each = m), sites)),
    x = rep(spread(m, TRUE), sites * k),
    w = rep(rep(spread(k, FALSE), each = m), sites),
    z = rep(spread(sites, FALSE), each = m * k)
  )
}

# Check run: one large data set (2,000 groups; with three levels, 400
# sites) simulated from simr's model and refitted with lme4: each fixed
# effect within 5 of its standard errors, each SD within 5 of its
# approximate standard errors, as for E33.
two_level_check_run <- function(spec, inputs, seed) {
  three <- isTRUE(inputs$three)
  n <- if (three) 400L * inputs$unit_size else 2000L * inputs$cluster_size
  model <- simr_model(inputs, n)
  data <- two_level_design(inputs, n)
  data$y <- with_seed(seed, stats::simulate(model)[[1]])
  fit <- simr_refit(inputs, data)
  coefs <- summary(fit)$coefficients
  vc <- as.data.frame(lme4::VarCorr(fit))
  group_name <- if (three) "site:group" else "group"
  sd_of <- function(grp, var1) vc$sdcor[vc$grp == grp & vc$var1 %in% var1 & is.na(vc$var2)]
  pop <- spec$population
  groups <- n / inputs$cluster_size
  binary <- isTRUE(inputs$binary)
  # The noise in one person's outcome: the residual variance, or on the
  # log-odds scale the binomial variance at the typical probability.
  unit <- if (binary) 1 / (pop$probability * (1 - pop$probability)) else pop$sd_residual^2
  # A group SD is estimated from the groups' own estimates, which also
  # carry each group's sampling error (the residual variance over the
  # group's size, for the intercept, or over its sum of squared X, for the
  # slope): the variance's standard error is that total times
  # sqrt(2 / (groups - 1)), and the SD's is half of it over the SD.
  m <- inputs$cluster_size
  sd_row <- function(label, specified, recovered, noise, count = groups) {
    se_var <- (specified^2 + noise) * sqrt(2 / (count - 1))
    check_run_rows(label, specified, recovered, se_var / (2 * max(specified, 0.05)))
  }
  scale <- if (binary) " (log odds)" else ""
  terms <- c("x", "w", if (three) "z", "x:w", if (three) "x:z")
  labels <- c(x = "X's effect within groups", w = "W's effect between groups", z = "Z's effect between sites",
    "x:w" = "cross-level interaction", "x:z" = "X's interaction with Z")
  specified <- c(x = pop$b_X, w = pop$b_W, z = pop$b_Z %||% NA, "x:w" = pop$b_XW, "x:z" = pop$b_XZ %||% NA)
  sites <- if (three) n / inputs$unit_size
  check <- rbind(
    check_run_rows(paste0(labels[terms], scale), specified[terms], coefs[terms, "Estimate"], coefs[terms, "Std. Error"]),
    sd_row("SD of group intercepts", pop$sd_group, sd_of(group_name, "(Intercept)"), unit / m),
    sd_row("SD of group X slopes", pop$sd_group_slope, sd_of(group_name, "x"), unit / m),
    if (three) sd_row("SD of site intercepts", pop$sd_site, sd_of("site", "(Intercept)"), pop$sd_group^2 / inputs$groups_per_site + unit / inputs$unit_size, sites),
    if (three && length(sd_of("site", "x"))) {
      sd_row("SD of site X slopes", pop$sd_site_slope, sd_of("site", "x"), pop$sd_group_slope^2 / inputs$groups_per_site + unit / inputs$unit_size, sites)
    },
    if (!binary) check_run_rows("residual SD", pop$sd_residual, vc$sdcor[vc$grp == "Residual"], pop$sd_residual / sqrt(2 * n))
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
  binary <- isTRUE(inputs$binary)
  three <- isTRUE(inputs$three)
  scale <- if (binary) " (log odds)" else ""
  site_slope <- three && length(inputs$VarCorr$site) > 1
  c(
    script_header(spec, result, "simr", sprintf("simr::powerSim() with fixed(\"%s\", \"%s\")", inputs$term, inputs$method)),
    "library(simr)",
    if (binary) sprintf("# A yes/no outcome: a logistic mixed model (glmer), tested by %s.",
      if (identical(inputs$method, "lr")) "the likelihood ratio (simr's method \"lr\")" else "glmer's Wald z test (simr's method \"z\")") else
      "library(lmerTest) # the Satterthwaite t test (simr's method \"sa\")",
    "",
    "# Inputs ----",
    sprintf("# The outcome, %s, %s; x is %s (per SD, centred within each group),",
      comment_text(v$Y$label), if (binary) "yes/no (effects and SDs on the log-odds scale)" else "in its own units", comment_text(v$X$label)),
    sprintf("# w is %s (per SD, measured on each group)%s.", comment_text(v$W$label),
      if (three) sprintf(", z is %s (per SD, measured on each site)", comment_text(v$Z$label)) else ""),
    if (binary) sprintf("probability <- %s # the chance of 'yes' for a typical group at the average predictors", r_code(pop$probability)),
    sprintf("b_x <- %s # X's effect within groups%s", r_code(pop$b_X), scale),
    sprintf("b_w <- %s # W's effect between groups%s", r_code(pop$b_W), scale),
    if (three) sprintf("b_z <- %s # Z's effect between sites%s", r_code(pop$b_Z), scale),
    sprintf("b_xw <- %s # the cross-level interaction%s", r_code(pop$b_XW), scale),
    if (three) sprintf("b_xz <- %s # X's interaction with Z%s", r_code(pop$b_XZ), scale),
    sprintf("sd_group <- %s # SD of the groups' intercepts", r_code(pop$sd_group)),
    sprintf("sd_group_slope <- %s # SD of the groups' X slopes", r_code(pop$sd_group_slope)),
    sprintf("r_group <- %s # correlation of the groups' intercepts and slopes", r_code(pop$r_group %||% 0)),
    if (three) sprintf("sd_site <- %s # SD of the sites' intercepts", r_code(pop$sd_site)),
    if (site_slope) sprintf("sd_site_slope <- %s # SD of the sites' X slopes", r_code(pop$sd_site_slope)),
    if (!binary) sprintf("sd_residual <- %s # residual SD", r_code(pop$sd_residual)),
    sprintf("cluster_size <- %s # people in each group", r_code(pop$cluster_size)),
    if (three) sprintf("groups_per_site <- %s # groups in each site", r_code(pop$groups_per_site)),
    sprintf("term <- %s # the effect tested", r_code(inputs$term)),
    goal_inputs(spec, result),
    "",
    "# One data set's design: x takes the same evenly spread standard normal",
    if (three) "# values in every group, w across each site's groups, z across the sites" else
      "# values in every group, w evenly spread values across the groups",
    "# (all standardised).",
    "spread <- function(k, inner) {",
    "  v <- qnorm(if (inner) seq_len(k) / (k + 1) else (seq_len(k) - 0.5) / k)",
    "  (v - mean(v)) / sqrt(mean((v - mean(v))^2))",
    "}",
    "design_for <- function(n_people) {",
    if (three) {
      c("  sites <- n_people %/% (cluster_size * groups_per_site)",
        "  data.frame(",
        "    site = factor(rep(seq_len(sites), each = cluster_size * groups_per_site)),",
        "    group = factor(rep(rep(seq_len(groups_per_site), each = cluster_size), sites)),",
        "    x = rep(spread(cluster_size, TRUE), sites * groups_per_site),",
        "    w = rep(rep(spread(groups_per_site, FALSE), each = cluster_size), sites),",
        "    z = rep(spread(sites, FALSE), each = cluster_size * groups_per_site)",
        "  )")
    } else {
      c("  groups <- n_people %/% cluster_size",
        "  data.frame(",
        "    group = factor(rep(seq_len(groups), each = cluster_size)),",
        "    x = rep(spread(cluster_size, TRUE), groups),",
        "    w = rep(spread(groups, FALSE), each = cluster_size)",
        "  )")
    },
    "}",
    "",
    "# The population model: fixed effects, the variances and the residual SD.",
    "model_for <- function(n_people) {",
    "  group <- matrix(c(sd_group^2, r_group * sd_group * sd_group_slope,",
    "    r_group * sd_group * sd_group_slope, sd_group_slope^2), nrow = 2)",
    sprintf("  variances <- %s", if (three) {
      sprintf("list(site = %s, `site:group` = group)", if (site_slope) "diag(c(sd_site^2, sd_site_slope^2))" else "sd_site^2")
    } else "list(group = group)"),
    sprintf("  fixed <- c(%s, b_x, b_w, %sb_xw%s)", if (binary) "qlogis(probability)" else "0", if (three) "b_z, " else "", if (three) ", b_xz" else ""),
    if (binary) {
      sprintf("  makeGlmer(%s, family = \"binomial\", fixef = fixed, VarCorr = variances, data = design_for(n_people))", deparse1(inputs$formula))
    } else {
      sprintf("  makeLmer(%s, fixef = fixed, VarCorr = variances, sigma = sd_residual, data = design_for(n_people))", deparse1(inputs$formula))
    },
    "}",
    "",
    "# One batch of simulated data sets: significant results and data sets.",
    "# simr counts a data set whose fit or test fails as not significant.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    sprintf("  result <- powerSim(model_for(batch_n), test = fixed(term, \"%s\"),", inputs$method),
    "    nsim = batch_replications, alpha = alpha, seed = batch_seed, progress = FALSE)",
    "  c(result$x, result$n)",
    "}",
    "",
    batch_section(result, "powerSim()"),
    simulation_goal_section(spec, result, inputs$unit_size),
    comparison_section()
  )
}

# Participants responding to many items in three or more conditions within
# participants (mixed_model / crossed_conditions, E63):
#   y ~ cond + (1 | participant) + (1 | participant:cond) + (1 | item)
# with cond a factor in treatment coding (its coefficients are each
# condition's mean minus the first's), a participant intercept and one
# participant-by-condition variance shared by every condition, and an
# item intercept; with every item in every condition, an item-by-condition
# variance may be added, (1 | item:cond). The test is lmerTest's
# Satterthwaite F test that the conditions differ (the several-condition
# form of E33's Satterthwaite t test, Departure 16), or the Satterthwaite t
# test of one pair of conditions, adjusted with stats::p.adjust() for all
# the pairs as on the one-way ANOVA cards (Departure 17); each is passed to
# simr's powerSim() as its test function.
crossed_conditions_inputs <- function(spec) {
  pop <- spec$population
  levels <- unlist(spec$variables$X$levels)
  k <- length(levels)
  means <- as.numeric(unlist(pop$means))
  within <- identical(pop$item_design %||% "between", "within")
  # Conditions between participants (X a between factor): each participant
  # is in one condition, so there is no participant-by-condition term.
  participants_between <- identical(spec$variables$X$type, "between_factor")
  item_condition <- within && (pop$sd_item_condition %||% 0) > 0
  terms <- c("(1 | participant)", if (!participants_between) "(1 | participant:cond)", "(1 | item)",
    if (item_condition) "(1 | item:cond)")
  var_corr <- c(list(participant = pop$sd_participant^2),
    if (!participants_between) list("participant:cond" = pop$sd_participant_condition^2),
    list(item = pop$sd_item^2))
  if (item_condition) var_corr[["item:cond"]] <- pop$sd_item_condition^2
  pairwise <- identical(spec$target_test$effect, "pairwise")
  binary <- crossed_binary(spec)
  centre <- if (binary) stats::qlogis(as.numeric(unlist(pop$probabilities))) else means
  list(
    formula = stats::as.formula(paste("y ~ cond +", paste(terms, collapse = " + ")), env = globalenv()),
    binary = binary,
    method = simr_method(spec),
    fixef = c(centre[1], centre[-1] - centre[1]),
    VarCorr = var_corr,
    sigma = if (!binary) pop$sd_residual,
    items = pop$items,
    levels = levels,
    within = within,
    participants_between = participants_between,
    pairwise = pairwise,
    pair = if (pairwise) match(unlist(spec$target_test$comparison), levels),
    p_adjust = spec$target_test$p_adjust %||% "holm",
    alpha = spec$target_test$alpha,
    design = crossed_conditions_design,
    test_label = if (binary) {
      if (pairwise) "car::linearHypothesis() (Wald), adjusted by stats::p.adjust()" else
        sprintf("simr::fixed(\"cond\", \"%s\")", simr_method(spec))
    } else if (pairwise) "lmerTest::contest() (Satterthwaite), adjusted by stats::p.adjust()" else
      "lmerTest's anova() (Satterthwaite F)"
  )
}

# One data set's design: every participant responds to every item, the
# items split into equal blocks, one per condition (items between
# conditions), or every item in every condition (within).
crossed_conditions_design <- function(inputs, n) {
  k <- length(inputs$levels)
  if (isTRUE(inputs$participants_between)) {
    # The participants split into k equal groups, one per condition; each
    # responds to every item (items within) or to its condition's block.
    data <- expand.grid(participant = seq_len(n), item = seq_len(inputs$items))
    data$cond <- inputs$levels[ceiling(data$participant / (n / k))]
    if (!inputs$within) data <- data[ceiling(data$item / (inputs$items / k)) == match(data$cond, inputs$levels), ]
  } else if (inputs$within) {
    data <- expand.grid(participant = seq_len(n), item = seq_len(inputs$items), cond = inputs$levels,
      stringsAsFactors = FALSE)
  } else {
    data <- expand.grid(participant = seq_len(n), item = seq_len(inputs$items))
    data$cond <- inputs$levels[ceiling(data$item / (inputs$items / k))]
  }
  data$participant <- factor(data$participant)
  data$item <- factor(data$item)
  data$cond <- factor(data$cond, levels = inputs$levels)
  data
}

# The p-value of the test, for simr's powerSim(): the Satterthwaite F test
# of cond, or the chosen pair's Satterthwaite t test adjusted for all the
# pairs. A fit lmerTest can't test counts as not significant (NA).
crossed_conditions_test <- function(inputs) {
  k <- length(inputs$levels)
  pairs <- utils::combn(k, 2)
  chosen <- if (inputs$pairwise) which(pairs[1, ] == min(inputs$pair) & pairs[2, ] == max(inputs$pair))
  if (isTRUE(inputs$binary)) {
    # The test that the conditions differ is simr's own; a pair is car's
    # Wald test of its contrast, adjusted for all the pairs.
    if (!inputs$pairwise) return(simr::fixed("cond", inputs$method))
    lr <- identical(inputs$method, "lr")
    return(function(fit) {
      p <- apply(pairs, 2, function(ij) {
        if (lr) return(crossed_pair_lr(fit, inputs, ij))
        contrast <- numeric(k)
        contrast[ij[2]] <- 1
        if (ij[1] > 1) contrast[ij[1]] <- -1
        car::linearHypothesis(fit, matrix(contrast, nrow = 1))[["Pr(>Chisq)"]][2]
      })
      stats::p.adjust(p, inputs$p_adjust)[[chosen]]
    })
  }
  function(fit) {
    model <- if (inherits(fit, "lmerModLmerTest")) fit else lmerTest::as_lmerModLmerTest(fit)
    if (!inputs$pairwise) {
      return(stats::anova(model, ddf = "Satterthwaite")["cond", "Pr(>F)"])
    }
    p <- apply(pairs, 2, function(ij) {
      contrast <- numeric(k)
      contrast[ij[2]] <- 1
      if (ij[1] > 1) contrast[ij[1]] <- -1
      lmerTest::contest(model, contrast, ddf = "Satterthwaite")[["Pr(>F)"]]
    })
    stats::p.adjust(p, inputs$p_adjust)[[chosen]]
  }
}

# The likelihood-ratio test of one pair of conditions with a yes/no
# outcome: the model against the same model in which the pair's two
# conditions share their fixed effect (the random-effect terms keep every
# condition), compared by lme4's anova().
crossed_pair_lr <- function(fit, inputs, pair) {
  # The model frame holds the response the model was fitted to (in simr's
  # refits, the simulated one).
  data <- stats::model.frame(fit)
  data$cond_merged <- data$cond
  levels(data$cond_merged)[pair[2]] <- levels(data$cond_merged)[pair[1]]
  random <- sub("^y ~ cond", "", deparse1(inputs$formula))
  reduced <- stats::as.formula(paste("y ~ cond_merged", random), env = globalenv())
  full <- call_backend("lme4", quietly(lme4::glmer(inputs$formula, data = data, family = stats::binomial())))
  restricted <- call_backend("lme4", quietly(lme4::glmer(reduced, data = data, family = stats::binomial())))
  stats::anova(restricted, full)[["Pr(>Chisq)"]][2]
}

# Check run: one large data set (300 participants, at least 60 items per
# condition) simulated from simr's model and refitted with lme4: each
# condition's difference from the first within 5 of its standard errors,
# each SD within 5 of its approximate standard errors.
crossed_conditions_check_run <- function(spec, inputs, seed) {
  n <- 300L
  k <- length(inputs$levels)
  big <- inputs
  big$items <- max(inputs$items, 60L * k)
  if (!big$within) big$items <- k * ceiling(big$items / k)
  model <- simr_model(big, n)
  data <- crossed_conditions_design(big, n)
  data$y <- with_seed(seed, stats::simulate(model)[[1]])
  fit <- simr_refit(inputs, data)
  coefs <- summary(fit)$coefficients
  vc <- as.data.frame(lme4::VarCorr(fit))
  sd_of <- function(group) vc$sdcor[vc$grp == group]
  pop <- spec$population
  # A variance is estimated from its groups' own estimates, which also
  # carry the residual variance over the observations in each group: the
  # variance's standard error is that total times sqrt(2 / (groups - 1)),
  # the SD's half of it over the SD (as for E62).
  sd_row <- function(label, specified, recovered, groups) {
    noise <- simr_noise(inputs, pop, nrow(data) / groups)
    se_var <- (specified^2 + noise) * sqrt(2 / (groups - 1))
    check_run_rows(label, specified, recovered, se_var / (2 * max(specified, 0.05)))
  }
  names <- paste0("cond", inputs$levels[-1])
  rows <- list(
    check_run_rows(sprintf("%s minus %s%s", inputs$levels[-1], inputs$levels[1], if (inputs$binary) " (log odds)" else ""), inputs$fixef[-1],
      coefs[names, "Estimate"], coefs[names, "Std. Error"]),
    sd_row("SD of participant intercepts", pop$sd_participant, sd_of("participant"), n),
    if (!inputs$participants_between) {
      sd_row("SD of participant-by-condition effects", pop$sd_participant_condition, sd_of("participant:cond"), n * k)
    },
    sd_row("SD of item intercepts", pop$sd_item, sd_of("item"), big$items),
    if ("item:cond" %in% names(inputs$VarCorr)) {
      sd_row("SD of item-by-condition effects", pop$sd_item_condition, sd_of("item:cond"), big$items * k)
    },
    if (!inputs$binary) check_run_rows("residual SD", pop$sd_residual, sd_of("Residual"), pop$sd_residual / sqrt(2 * nrow(data)))
  )
  check <- do.call(rbind, rows)
  rownames(check) <- NULL
  check
}

# The standalone script: simr alone, with the same design and test
# (export_script()).
crossed_conditions_script <- function(spec, result) {
  inputs <- crossed_conditions_inputs(spec)
  pop <- spec$population
  v <- spec$variables
  var_corr <- paste(sprintf("`%s` = %s", names(inputs$VarCorr), vapply(inputs$VarCorr, r_code, "")), collapse = ", ")
  c(
    script_header(spec, result, "simr", sprintf("simr::powerSim() with %s", inputs$test_label)),
    "library(simr)",
    if (inputs$binary) "# A yes/no outcome: a logistic mixed model (glmer), every SD on the log-odds scale." else
      "library(lmerTest) # Satterthwaite's tests",
    "",
    "# Inputs ----",
    sprintf("# The outcome, %s, in its own units; cond is %s, a factor whose", comment_text(v$Y$label), comment_text(v$X$label)),
    "# coefficients are each condition's mean minus the first condition's.",
    sprintf("conditions <- %s", r_code(inputs$levels)),
    if (inputs$binary) {
      sprintf("probabilities <- %s # each condition's chance of 'yes', for a typical participant and item",
        r_code(as.numeric(unlist(pop$probabilities))))
    } else {
      sprintf("means <- %s # each condition's mean", r_code(as.numeric(unlist(pop$means))))
    },
    sprintf("variances <- list(%s) # participant, participant-by-condition and item variances", var_corr),
    if (!inputs$binary) sprintf("sd_residual <- %s # residual SD", r_code(pop$sd_residual)),
    sprintf("items <- %s # number of items", r_code(pop$items)),
    sprintf("item_design <- %s # %s", r_code(if (inputs$within) "within" else "between"),
      if (inputs$within) "every item in every condition" else "the items split equally, one block per condition"),
    if (inputs$pairwise) c(
      sprintf("pair <- %s # the pair of conditions tested", r_code(inputs$levels[sort(inputs$pair)])),
      sprintf("p_adjust <- %s # adjustment for all the pairwise comparisons", r_code(inputs$p_adjust))
    ),
    goal_inputs(spec, result),
    "",
    sprintf("participant_design <- %s # %s", r_code(if (inputs$participants_between) "between" else "within"),
      if (inputs$participants_between) "each participant in one condition, the participants split equally" else "every participant in every condition"),
    "",
    "design_for <- function(n_participants) {",
    "  k <- length(conditions)",
    "  if (participant_design == \"between\") {",
    "    data <- expand.grid(participant = seq_len(n_participants), item = seq_len(items))",
    "    data$cond <- conditions[ceiling(data$participant / (n_participants / k))]",
    "    if (item_design == \"between\") data <- data[ceiling(data$item / (items / k)) == match(data$cond, conditions), ]",
    "  } else if (item_design == \"within\") {",
    "    data <- expand.grid(participant = seq_len(n_participants), item = seq_len(items), cond = conditions,",
    "      stringsAsFactors = FALSE)",
    "  } else {",
    "    data <- expand.grid(participant = seq_len(n_participants), item = seq_len(items))",
    "    data$cond <- conditions[ceiling(data$item / (items / k))]",
    "  }",
    "  data$participant <- factor(data$participant)",
    "  data$item <- factor(data$item)",
    "  data$cond <- factor(data$cond, levels = conditions)",
    "  data",
    "}",
    "",
    "model_for <- function(n_participants) {",
    if (inputs$binary) {
      c(sprintf("  makeGlmer(%s, family = \"binomial\",", deparse1(inputs$formula)),
        "    fixef = c(qlogis(probabilities[1]), qlogis(probabilities[-1]) - qlogis(probabilities[1])),",
        "    VarCorr = variances, data = design_for(n_participants))")
    } else {
      c(sprintf("  makeLmer(%s,", deparse1(inputs$formula)),
        "    fixef = c(means[1], means[-1] - means[1]), VarCorr = variances,",
        "    sigma = sd_residual, data = design_for(n_participants))")
    },
    "}",
    "",
    if (inputs$binary && inputs$pairwise) c(
      "# The chosen pair's Wald test (car), adjusted for all the pairs.",
      "test_p <- function(fit) {",
      "  k <- length(conditions)",
      "  pairs <- combn(k, 2)",
      "  p <- apply(pairs, 2, function(ij) {",
      "    contrast <- numeric(k)",
      "    contrast[ij[2]] <- 1",
      "    if (ij[1] > 1) contrast[ij[1]] <- -1",
      "    car::linearHypothesis(fit, matrix(contrast, nrow = 1))[[\"Pr(>Chisq)\"]][2]",
      "  })",
      "  at <- sort(match(pair, conditions))",
      "  p.adjust(p, p_adjust)[[which(pairs[1, ] == at[1] & pairs[2, ] == at[2])]]",
      "}"
    ) else if (inputs$binary) c(
      sprintf("# The test that the conditions differ: simr's fixed(\"cond\", \"%s\").", inputs$method),
      sprintf("test_p <- fixed(\"cond\", \"%s\")", inputs$method)
    ) else if (inputs$pairwise) c(
      "# The chosen pair's Satterthwaite t test, adjusted for all the pairs.",
      "test_p <- function(fit) {",
      "  model <- as_lmerModLmerTest(fit)",
      "  k <- length(conditions)",
      "  pairs <- combn(k, 2)",
      "  p <- apply(pairs, 2, function(ij) {",
      "    contrast <- numeric(k)",
      "    contrast[ij[2]] <- 1",
      "    if (ij[1] > 1) contrast[ij[1]] <- -1",
      "    contest(model, contrast, ddf = \"Satterthwaite\")[[\"Pr(>F)\"]]",
      "  })",
      "  at <- sort(match(pair, conditions))",
      "  p.adjust(p, p_adjust)[[which(pairs[1, ] == at[1] & pairs[2, ] == at[2])]]",
      "}"
    ) else c(
      "# The Satterthwaite F test that the conditions differ.",
      "test_p <- function(fit) anova(as_lmerModLmerTest(fit), ddf = \"Satterthwaite\")[\"cond\", \"Pr(>F)\"]"
    ),
    "",
    "# One batch of simulated data sets: significant results and data sets.",
    "# simr counts a data set whose fit or test fails as not significant.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  result <- powerSim(model_for(batch_n), test = test_p,",
    "    nsim = batch_replications, alpha = alpha, seed = batch_seed, progress = FALSE)",
    "  c(result$x, result$n)",
    "}",
    "",
    batch_section(result, "powerSim()"),
    simulation_goal_section(spec, result, 1),
    comparison_section()
  )
}

# Three levels (mixed_model / three_level, E68): people (level 1) in
# groups (level 2, classes) in sites (level 3, schools), with two
# conditions assigned to whole sites, to groups within each site, or to
# people within each group. On the scale of the outcome's total SD (1),
# the sites' share of the variance is icc_site, the groups' icc_group and
# the rest is residual; the condition, coded -0.5 and 0.5, has the
# standardised effect d. When it is assigned below the sites, its effect
# may vary across sites (icc_effect_site, a share of the total variance),
# and when it is assigned to people, across groups too
# (icc_effect_group):
#   y ~ cond + (1 + cond | site) + (1 + cond | site:group)
# with the condition's terms only where they apply. Simulated with simr
# and tested by Satterthwaite's t test, as for E33 and E62 (Departure 16).
# A yes/no outcome (1 November 2026) is a logistic mixed model built by
# makeGlmer(): each condition's chance of 'yes' for a typical site and
# group, and in place of the shares of variance the SDs of the sites'
# and groups' intercepts and of the effect, on the log-odds scale; tested
# by glmer's Wald z test or the likelihood ratio, as for E33.
three_level_inputs <- function(spec) {
  pop <- spec$population
  level <- pop$assignment
  binary <- crossed_binary(spec)
  # The variances: shares of the total for a score outcome, squared SDs on
  # the log-odds scale for a yes/no one.
  v_site <- if (binary) pop$sd_site^2 else pop$icc_site
  v_group <- if (binary) pop$sd_group^2 else pop$icc_group
  v_effect_site <- if (binary) (pop$sd_effect_site %||% 0)^2 else pop$icc_effect_site %||% 0
  v_effect_group <- if (binary) (pop$sd_effect_group %||% 0)^2 else pop$icc_effect_group %||% 0
  effect_site <- !identical(level, "site") && v_effect_site > 0
  effect_group <- identical(level, "person") && v_effect_group > 0
  terms <- c(if (effect_site) "(1 + cond | site)" else "(1 | site)",
    if (effect_group) "(1 + cond | site:group)" else "(1 | site:group)")
  var_corr <- list(
    site = if (effect_site) diag(c(v_site, v_effect_site)) else v_site,
    "site:group" = if (effect_group) diag(c(v_group, v_effect_group)) else v_group
  )
  logits <- if (binary) stats::qlogis(as.numeric(unlist(pop$probabilities)))
  list(
    formula = stats::as.formula(paste("y ~ cond +", paste(terms, collapse = " + ")), env = globalenv()),
    binary = binary,
    fixef = if (binary) c(mean(logits), diff(logits)) else c(0, pop$d),
    VarCorr = var_corr,
    sigma = if (!binary) sqrt(1 - pop$icc_site - pop$icc_group),
    level = level,
    group_size = pop$group_size,
    groups_per_site = pop$groups_per_site,
    site_size = pop$group_size * pop$groups_per_site,
    term = "cond",
    method = switch(spec$target_test$method, satterthwaite_t = "sa", wald = "z", likelihood_ratio = "lr"),
    alpha = spec$target_test$alpha,
    design = three_level_design
  )
}

# One data set's design: n people in sites of groups_per_site groups of
# group_size; the first half of the sites, of each site's groups, or of
# each group's people in the first condition.
three_level_design <- function(inputs, n) {
  sites <- n %/% inputs$site_size
  data <- expand.grid(person = seq_len(inputs$group_size), group = seq_len(inputs$groups_per_site), site = seq_len(sites))
  half <- switch(inputs$level,
    site = data$site <= sites / 2,
    group = data$group <= inputs$groups_per_site / 2,
    person = data$person <= inputs$group_size / 2)
  data$cond <- ifelse(half, -0.5, 0.5)
  data$site <- factor(data$site)
  data$group <- factor(data$group)
  data$person <- NULL
  data
}

# Check run: one large data set (400 sites) simulated from simr's model
# and refitted with lme4: the effect within 5 of its standard errors, each
# SD within 5 of its approximate standard errors, allowing for the noise
# in each group's own estimate (as for E62).
three_level_check_run <- function(spec, inputs, seed) {
  n <- 400L * inputs$site_size
  model <- simr_model(inputs, n)
  data <- three_level_design(inputs, n)
  data$y <- with_seed(seed, stats::simulate(model)[[1]])
  fit <- simr_refit(inputs, data)
  coefs <- summary(fit)$coefficients
  vc <- as.data.frame(lme4::VarCorr(fit))
  sd_of <- function(group, var1) vc$sdcor[vc$grp == group & vc$var1 %in% var1 & is.na(vc$var2)]
  pop <- spec$population
  sites <- n / inputs$site_size
  binary <- isTRUE(inputs$binary)
  # The noise in one person's outcome: the residual variance, or on the
  # log-odds scale the binomial variance averaged over the conditions.
  unit <- if (binary) simr_noise(inputs, pop, 1) else inputs$sigma^2
  sd_row <- function(label, specified, recovered, groups, per_group) {
    se_var <- (specified^2 + unit / per_group) * sqrt(2 / (groups - 1))
    check_run_rows(label, specified, recovered, se_var / (2 * max(specified, 0.05)))
  }
  sds <- sqrt(c(inputs$VarCorr$site[1], inputs$VarCorr$`site:group`[1],
    if (length(inputs$VarCorr$site) > 1) inputs$VarCorr$site[2, 2] else 0,
    if (length(inputs$VarCorr$`site:group`) > 1) inputs$VarCorr$`site:group`[2, 2] else 0))
  rows <- list(
    if (binary) {
      check_run_rows("difference between conditions (log odds)", inputs$fixef[2], coefs["cond", "Estimate"], coefs["cond", "Std. Error"])
    } else {
      check_run_rows("effect (d)", pop$d, coefs["cond", "Estimate"], coefs["cond", "Std. Error"])
    },
    sd_row(if (binary) "SD of sites (log odds)" else "SD of sites (square root of icc_site)", sds[1], sd_of("site", "(Intercept)"), sites, inputs$site_size),
    sd_row(if (binary) "SD of groups (log odds)" else "SD of groups (square root of icc_group)", sds[2], sd_of("site:group", "(Intercept)"),
      sites * inputs$groups_per_site, inputs$group_size),
    if (length(sd_of("site", "cond"))) {
      sd_row("SD of the effect across sites", sds[3], sd_of("site", "cond"), sites, inputs$site_size / 4)
    },
    if (length(sd_of("site:group", "cond"))) {
      sd_row("SD of the effect across groups", sds[4], sd_of("site:group", "cond"), sites * inputs$groups_per_site,
        inputs$group_size / 4)
    },
    if (!binary) check_run_rows("residual SD", inputs$sigma, sd_of("Residual", NA), inputs$sigma / sqrt(2 * nrow(data)))
  )
  check <- do.call(rbind, rows)
  rownames(check) <- NULL
  check
}

# The standalone script: simr alone, with the same design and test.
three_level_script <- function(spec, result) {
  inputs <- three_level_inputs(spec)
  pop <- spec$population
  v <- spec$variables
  levels <- comment_text(unlist(v$X$levels))
  var_corr <- paste(sprintf("`%s` = %s", names(inputs$VarCorr),
    vapply(inputs$VarCorr, function(x) if (length(x) > 1) sprintf("diag(%s)", r_code(diag(x))) else r_code(x), "")), collapse = ", ")
  binary <- isTRUE(inputs$binary)
  c(
    script_header(spec, result, "simr", sprintf("simr::powerSim() with fixed(\"cond\", \"%s\")", inputs$method)),
    "library(simr)",
    if (binary) sprintf("# A yes/no outcome: a logistic mixed model (glmer), tested by %s.",
      if (identical(inputs$method, "lr")) "the likelihood ratio (simr's method \"lr\")" else "glmer's Wald z test (simr's method \"z\")") else
      "library(lmerTest) # the Satterthwaite t test (simr's method \"sa\")",
    "",
    "# Inputs ----",
    sprintf("# The outcome, %s, %s; cond is %s coded -0.5 (%s) and 0.5 (%s).",
      comment_text(v$Y$label), if (binary) "yes/no (on the log-odds scale)" else "on the scale of its total SD",
      comment_text(v$X$label), levels[1], levels[2]),
    if (binary) {
      c(sprintf("probabilities <- %s # the chance of 'yes' in each condition, typical site and group", r_code(as.numeric(unlist(pop$probabilities)))),
        "fixed <- c(mean(qlogis(probabilities)), diff(qlogis(probabilities))) # intercept and difference (log odds)",
        sprintf("variances <- list(%s) # the sites' and groups' variances (and the effect's), log-odds scale", var_corr))
    } else {
      c(sprintf("d <- %s # the effect over the outcome's total SD", r_code(pop$d)),
        sprintf("variances <- list(%s) # sites' and groups' shares of the variance (and of the effect's)", var_corr),
        sprintf("sd_residual <- %s # sqrt(1 - icc_site - icc_group)", r_code(inputs$sigma)))
    },
    sprintf("group_size <- %s # people in each group", r_code(inputs$group_size)),
    sprintf("groups_per_site <- %s # groups in each site", r_code(inputs$groups_per_site)),
    sprintf("assignment <- %s # what is assigned to the conditions", r_code(inputs$level)),
    goal_inputs(spec, result),
    "",
    "design_for <- function(n_people) {",
    "  sites <- n_people %/% (group_size * groups_per_site)",
    "  data <- expand.grid(person = seq_len(group_size), group = seq_len(groups_per_site), site = seq_len(sites))",
    "  half <- switch(assignment, site = data$site <= sites / 2, group = data$group <= groups_per_site / 2,",
    "    person = data$person <= group_size / 2)",
    "  data$cond <- ifelse(half, -0.5, 0.5)",
    "  data$site <- factor(data$site)",
    "  data$group <- factor(data$group)",
    "  data$person <- NULL",
    "  data",
    "}",
    "",
    "model_for <- function(n_people) {",
    if (binary) sprintf("  makeGlmer(%s, family = \"binomial\", fixef = fixed, VarCorr = variances,", deparse1(inputs$formula)) else
      sprintf("  makeLmer(%s, fixef = c(0, d), VarCorr = variances,", deparse1(inputs$formula)),
    if (binary) "    data = design_for(n_people))" else "    sigma = sd_residual, data = design_for(n_people))",
    "}",
    "",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    sprintf("  result <- powerSim(model_for(batch_n), test = fixed(\"cond\", \"%s\"),", inputs$method),
    "    nsim = batch_replications, alpha = alpha, seed = batch_seed, progress = FALSE)",
    "  c(result$x, result$n)",
    "}",
    "",
    batch_section(result, "powerSim()"),
    simulation_goal_section(spec, result, inputs$site_size),
    comparison_section()
  )
}

# A predictor measured on each item (mixed_model / item_predictor, E67):
# participants respond to many items that differ on a score X (word
# frequency, a face's rated attractiveness), standardised across the items
# (normal quantiles, centred, SD 1):
#   y ~ x + (1 + x | participant) + (1 | item)
# with the effect of X per SD of X, each participant's own slope on X
# (sd_participant_slope, correlated r_participant with their intercept),
# and the items varying beyond what X explains (sd_item). A score outcome
# is tested by Satterthwaite's t test (Departure 16); a yes/no outcome
# (Y binary: the chance of 'yes' at the items' mean X for a typical
# participant, every SD on the log-odds scale) by glmer's Wald z test or
# the likelihood ratio, as for E33.
item_predictor_inputs <- function(spec) {
  pop <- spec$population
  binary <- crossed_binary(spec)
  r <- pop$r_participant %||% 0
  participant <- matrix(c(pop$sd_participant^2, r * pop$sd_participant * pop$sd_participant_slope,
    r * pop$sd_participant * pop$sd_participant_slope, pop$sd_participant_slope^2), nrow = 2)
  # A predictor measured on each trial (1 November 2026) varies within
  # items too, so its effect may vary across items (sd_item_slope).
  trial <- identical(pop$x_level, "trial")
  item_slope <- trial && (pop$sd_item_slope %||% 0) > 0
  list(
    formula = stats::as.formula(paste("y ~ x + (1 + x | participant) +", if (item_slope) "(1 + x | item)" else "(1 | item)"), env = globalenv()),
    binary = binary,
    trial = trial,
    method = switch(spec$target_test$method, satterthwaite_t = "sa", wald = "z", likelihood_ratio = "lr"),
    term = "x",
    fixef = c(if (binary) stats::qlogis(pop$probability) else 0, pop$slope),
    VarCorr = list(participant = participant, item = if (item_slope) diag(c(pop$sd_item^2, pop$sd_item_slope^2)) else pop$sd_item^2),
    sigma = if (!binary) pop$sd_residual,
    items = pop$items,
    alpha = spec$target_test$alpha,
    design = item_predictor_design
  )
}

# One data set's design: every participant responds to every item; X's
# values are evenly spread standard normal values (normal quantiles),
# centred with SD 1, one per item, or with X measured on each trial each
# participant's values rotated across the items.
item_predictor_design <- function(inputs, n) {
  x <- stats::qnorm(seq_len(inputs$items) / (inputs$items + 1))
  x <- (x - mean(x)) / sqrt(mean((x - mean(x))^2))
  data <- expand.grid(participant = seq_len(n), item = seq_len(inputs$items))
  # Measured on each trial: each participant meets every value once, in an
  # order rotated across participants, so X varies within items as well.
  data$x <- if (isTRUE(inputs$trial)) x[(data$participant + data$item - 2) %% inputs$items + 1] else x[data$item]
  data$participant <- factor(data$participant)
  data$item <- factor(data$item)
  data
}

# Check run: one large data set (300 participants, at least 200 items),
# refitted with lme4: the slope within 5 of its standard errors, each SD
# within 5 of its approximate standard errors allowing for the noise in
# each group's own estimate.
item_predictor_check_run <- function(spec, inputs, seed) {
  n <- 300L
  big <- inputs
  big$items <- max(inputs$items, 200L)
  model <- simr_model(big, n)
  data <- item_predictor_design(big, n)
  data$y <- with_seed(seed, stats::simulate(model)[[1]])
  fit <- simr_refit(inputs, data)
  coefs <- summary(fit)$coefficients
  vc <- as.data.frame(lme4::VarCorr(fit))
  sd_of <- function(group, var1) vc$sdcor[vc$grp == group & vc$var1 %in% var1 & is.na(vc$var2)]
  pop <- spec$population
  sd_row <- function(label, specified, recovered, groups, per_group) {
    se_var <- (specified^2 + simr_noise(inputs, pop, per_group)) * sqrt(2 / (groups - 1))
    check_run_rows(label, specified, recovered, se_var / (2 * max(specified, 0.05)))
  }
  rows <- list(
    check_run_rows(if (inputs$binary) "slope of X (log odds per SD)" else "slope of X (per SD)", pop$slope,
      coefs["x", "Estimate"], coefs["x", "Std. Error"]),
    sd_row("SD of participant intercepts", pop$sd_participant, sd_of("participant", "(Intercept)"), n, big$items),
    sd_row("SD of participant slopes on X", pop$sd_participant_slope, sd_of("participant", "x"), n, big$items),
    sd_row("SD of item intercepts beyond X", pop$sd_item, sd_of("item", "(Intercept)"), big$items, n),
    if (length(sd_of("item", "x"))) sd_row("SD of item slopes on X", pop$sd_item_slope, sd_of("item", "x"), big$items, n),
    if (!inputs$binary) check_run_rows("residual SD", pop$sd_residual, sd_of("Residual", NA), pop$sd_residual / sqrt(2 * nrow(data)))
  )
  check <- do.call(rbind, rows)
  rownames(check) <- NULL
  check
}

# The standalone script: simr alone, with the same design and test.
item_predictor_script <- function(spec, result) {
  inputs <- item_predictor_inputs(spec)
  pop <- spec$population
  v <- spec$variables
  c(
    script_header(spec, result, "simr", sprintf("simr::powerSim() with fixed(\"x\", \"%s\")", inputs$method)),
    "library(simr)",
    if (inputs$binary) "# A yes/no outcome: a logistic mixed model (glmer), every SD on the log-odds scale." else
      "library(lmerTest) # the Satterthwaite t test (simr's method \"sa\")",
    "",
    "# Inputs ----",
    sprintf("# x is %s, measured on each %s and standardised; the outcome is %s.",
      comment_text(v$X$label), if (isTRUE(inputs$trial)) "trial" else "item", comment_text(v$Y$label)),
    sprintf("slope <- %s # the effect of one SD more of x%s", r_code(pop$slope), if (inputs$binary) ", on the log odds" else ""),
    if (inputs$binary) sprintf("probability <- %s # the chance of 'yes' at the items' mean x, for a typical participant", r_code(pop$probability)),
    sprintf("sd_participant <- %s # SD of participants' intercepts", r_code(pop$sd_participant)),
    sprintf("sd_participant_slope <- %s # SD of participants' slopes on x", r_code(pop$sd_participant_slope)),
    sprintf("r_participant <- %s # correlation of participants' intercepts and slopes", r_code(pop$r_participant %||% 0)),
    sprintf("sd_item <- %s # SD of items beyond what x explains", r_code(pop$sd_item)),
    if (length(inputs$VarCorr$item) > 1) sprintf("sd_item_slope <- %s # SD of items' slopes on x", r_code(pop$sd_item_slope)),
    if (!inputs$binary) sprintf("sd_residual <- %s # residual SD", r_code(pop$sd_residual)),
    sprintf("items <- %s # number of items", r_code(pop$items)),
    goal_inputs(spec, result),
    "",
    "design_for <- function(n_participants) {",
    "  x <- qnorm(seq_len(items) / (items + 1))",
    "  x <- (x - mean(x)) / sqrt(mean((x - mean(x))^2))",
    "  data <- expand.grid(participant = seq_len(n_participants), item = seq_len(items))",
    if (isTRUE(inputs$trial)) "  data$x <- x[(data$participant + data$item - 2) %% items + 1] # each participant's values rotated across the items" else
      "  data$x <- x[data$item]",
    "  data$participant <- factor(data$participant)",
    "  data$item <- factor(data$item)",
    "  data",
    "}",
    "",
    "model_for <- function(n_participants) {",
    "  participant <- matrix(c(sd_participant^2, r_participant * sd_participant * sd_participant_slope,",
    "    r_participant * sd_participant * sd_participant_slope, sd_participant_slope^2), nrow = 2)",
    sprintf("  item <- %s", if (length(inputs$VarCorr$item) > 1) "diag(c(sd_item^2, sd_item_slope^2))" else "sd_item^2"),
    if (inputs$binary) {
      c(sprintf("  makeGlmer(%s, family = \"binomial\", fixef = c(qlogis(probability), slope),", deparse1(inputs$formula)),
        "    VarCorr = list(participant = participant, item = item), data = design_for(n_participants))")
    } else {
      c(sprintf("  makeLmer(%s, fixef = c(0, slope),", deparse1(inputs$formula)),
        "    VarCorr = list(participant = participant, item = item), sigma = sd_residual, data = design_for(n_participants))")
    },
    "}",
    "",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    sprintf("  result <- powerSim(model_for(batch_n), test = fixed(\"x\", \"%s\"),", inputs$method),
    "    nsim = batch_replications, alpha = alpha, seed = batch_seed, progress = FALSE)",
    "  c(result$x, result$n)",
    "}",
    "",
    batch_section(result, "powerSim()"),
    simulation_goal_section(spec, result, 1),
    comparison_section()
  )
}
