# Checks that need more than the JSON schema: the variables and paths fit
# the template, the implied population is possible, and the goal can be met.
# Each check takes a schema-valid spec and returns a character vector of
# plain-English problems (empty when all is well).

population_problems <- function(spec) {
  design_check <- switch(
    spec$design,
    basic_test = check_basic_test,
    factorial_anova = check_factorial_anova,
    regression_interaction = check_regression_interaction,
    mediation = check_path_model,
    moderated_mediation = check_path_model
  )
  design_problems <- design_check(spec)
  c(
    check_labels(spec),
    check_reliability_allowed(spec),
    check_allocation_allowed(spec),
    check_method_allowed(spec),
    design_problems,
    # The target effect can only be computed once the design itself is sound.
    check_goal(spec, check_effect = length(design_problems) == 0)
  )
}

# Advice that does not make a spec invalid. Returned as messages and issued
# as warnings by validate_spec().
spec_advice <- function(spec) {
  advice <- character()
  if (identical(spec$effect_justification$type, "pilot_study")) {
    advice <- c(advice, paste0(
      "The effect size comes from a pilot study. Pilot estimates are very ",
      "imprecise, so a sample size based on one can be far too small or too ",
      "large. Consider a smallest effect of interest instead, or adjust the ",
      "pilot estimate and say how in 'effect_justification > adjustment'."
    ))
  }
  nrep <- spec$options$nrep
  if (!is.null(nrep) && nrep < 1000 && uses_simulation(spec)) {
    advice <- c(advice, sprintf(
      paste0(
        "'options > nrep' is %s. With fewer than 1,000 replications a power ",
        "estimate of 80%% is only accurate to about +/- %s; use 1,000 or more ",
        "for a final report."
      ),
      format_number(nrep), format_number(round(1.96 * sqrt(0.8 * 0.2 / nrep), 3))
    ))
  }
  attrition <- spec$options$attrition
  if (!is.null(attrition) && attrition > 0.5) {
    advice <- c(advice, sprintf(
      paste0(
        "'options > attrition' is %s, so more than half of those recruited ",
        "would not be analysed. Check this is right."
      ),
      format_number(attrition)
    ))
  }
  advice
}

# 2x2 ANOVA designs are computed exactly unless simulation is requested;
# every other design is simulated.
uses_simulation <- function(spec) {
  default <- if (spec$design == "factorial_anova") "exact" else "simulation"
  identical(spec$options$method %||% default, "simulation")
}

# Variables -----------------------------------------------------------------

var_label <- function(spec, role) {
  label <- spec$variables[[role]]$label
  if (is.null(label)) role else sprintf("%s (%s)", label, role)
}

check_labels <- function(spec) {
  labels <- vapply(spec$variables, function(v) v$label, character(1))
  dups <- unique(labels[duplicated(labels)])
  vapply(dups, function(label) {
    roles <- names(labels)[labels == label]
    sprintf(
      "Variables %s have the same label, '%s'. Give each variable its own name so the diagram and write-up are clear.",
      quote_list(roles, "and"), label
    )
  }, character(1), USE.NAMES = FALSE)
}

check_reliability_allowed <- function(spec) {
  if (spec$design %in% c("regression_interaction", "mediation", "moderated_mediation")) {
    return(character())
  }
  has_rel <- vapply(spec$variables, function(v) !is.null(v$reliability), logical(1))
  vapply(names(has_rel)[has_rel], function(role) {
    sprintf(
      "'variables > %s > reliability' can't be used with %s designs yet; remove it.",
      role, gsub("_", " ", spec$design)
    )
  }, character(1), USE.NAMES = FALSE)
}

check_allocation_allowed <- function(spec) {
  if (is.null(spec$options$allocation_ratio) ||
    spec$template %in% c("independent_t", "two_proportions")) {
    return(character())
  }
  paste0(
    "'options > allocation_ratio' only applies to two-group designs ",
    "(independent t-test, two proportions); remove it."
  )
}

check_method_allowed <- function(spec) {
  if (!identical(spec$options$method, "exact") || spec$design == "factorial_anova") {
    return(character())
  }
  paste0(
    "'options > method' 'exact' is only available for 2x2 ANOVA designs; ",
    "remove it or use 'simulation'."
  )
}

# Basic tests ----------------------------------------------------------------

check_basic_test <- function(spec) {
  if (spec$template != "chi_square_independence") {
    return(character())
  }
  check_probability_table(spec)
}

check_probability_table <- function(spec) {
  rows <- spec$population$probabilities
  widths <- lengths(rows)
  if (length(unique(widths)) != 1) {
    return(paste0(
      "'population > probabilities' must be a table: every row needs the same ",
      "number of entries (one per level of Y). The rows have ",
      paste(widths, collapse = ", "), " entries."
    ))
  }
  p <- matrix(as.numeric(unlist(rows)), nrow = length(rows), byrow = TRUE)
  problems <- character()
  n_x <- length(spec$variables$X$levels)
  n_y <- length(spec$variables$Y$levels)
  if (nrow(p) != n_x || ncol(p) != n_y) {
    problems <- c(problems, sprintf(
      "'population > probabilities' is %d x %d, but %s has %d levels (rows) and %s has %d levels (columns).",
      nrow(p), ncol(p), var_label(spec, "X"), n_x, var_label(spec, "Y"), n_y
    ))
  }
  total <- sum(p)
  if (abs(total - 1) > 1e-6) {
    problems <- c(problems, sprintf(
      "'population > probabilities' must add up to 1, but they add up to %s. Each cell is the proportion of the population with that combination of X and Y.",
      format_number(round(total, 6))
    ))
  }
  if (any(rowSums(p) == 0) || any(colSums(p) == 0)) {
    problems <- c(problems, paste0(
      "'population > probabilities' has a row or column that is all zero, so ",
      "that level never occurs. Remove the level or give it some probability."
    ))
  }
  problems
}

# Factorial ANOVA ------------------------------------------------------------

check_factorial_anova <- function(spec) {
  pop <- spec$population
  if (identical(pop$metric, "standardised") && any(unlist(pop$sd) != 1)) {
    return(paste0(
      "With metric 'standardised' the means are in SD units, so ",
      "'population > sd' must be 1. To use your own units, set metric to 'raw'."
    ))
  }
  character()
}

anova_contrast <- function(spec) {
  m <- matrix(as.numeric(unlist(spec$population$means)), nrow = 2, byrow = TRUE)
  switch(
    spec$target_test$effect,
    main_effect_A = sum(m[1, ]) - sum(m[2, ]),
    main_effect_B = sum(m[, 1]) - sum(m[, 2]),
    interaction = m[1, 1] - m[1, 2] - m[2, 1] + m[2, 2]
  )
}

# Regression interaction -----------------------------------------------------

check_regression_interaction <- function(spec) {
  pop <- spec$population
  # Correlations among X, W and their product, assuming X and W are centred
  # and jointly normal (as InteractionPoweR does): XW is uncorrelated with
  # X and W.
  predictors <- matrix(
    c(1, pop$r_X_W, 0, pop$r_X_W, 1, 0, 0, 0, 1),
    nrow = 3,
    dimnames = list(c("X", "W", "XW"), c("X", "W", "XW"))
  )
  with_y <- c(pop$r_X_Y, pop$r_W_Y, pop$r_XW_Y)
  r2 <- drop(t(with_y) %*% solve(predictors, with_y))
  if (r2 < 1 - 1e-8) {
    return(character())
  }
  sprintf(
    paste0(
      "These correlations are impossible together: they imply that %s, %s ",
      "and their interaction explain %s%% of the variance in %s (R-squared = %s), ",
      "but R-squared must be below 1. Make one or more of r_X_Y, r_W_Y and ",
      "r_XW_Y smaller, or change r_X_W."
    ),
    var_label(spec, "X"), var_label(spec, "W"), format_number(round(100 * r2, 1)),
    var_label(spec, "Y"), format_number(round(r2, 3))
  )
}

# Mediation and moderated mediation -------------------------------------------

# The structure of each PROCESS template: which variable is regressed on
# which, which product terms exist, and the order in which to build them.
path_model <- function(spec) {
  roles <- names(spec$variables)
  mediators <- sort(grep("^M[1-9]?$", roles, value = TRUE))
  switch(
    spec$template,
    process_4 = list(
      exogenous = "X",
      mediators = mediators,
      products = list(),
      equations = c(
        stats::setNames(rep(list("X"), length(mediators)), mediators),
        list(Y = c("X", mediators))
      )
    ),
    process_6 = list(
      exogenous = "X",
      mediators = mediators,
      serial = TRUE,
      products = list(),
      equations = c(
        stats::setNames(
          lapply(seq_along(mediators), function(i) c("X", mediators[seq_len(i - 1)])),
          mediators
        ),
        list(Y = c("X", mediators))
      )
    ),
    process_7 = list(
      exogenous = c("X", "W"),
      mediators = "M",
      products = list(XW = c("X", "W")),
      equations = list(M = c("X", "W", "XW"), Y = c("X", "M"))
    ),
    process_14 = list(
      exogenous = c("X", "W"),
      mediators = "M",
      products = list(MW = c("M", "W")),
      equations = list(M = "X", Y = c("X", "M", "W", "MW"))
    )
  )
}

model_paths <- function(model) {
  unlist(lapply(names(model$equations), function(outcome) {
    paste0(model$equations[[outcome]], "->", outcome)
  }), use.names = FALSE)
}

check_path_model <- function(spec) {
  model <- path_model(spec)
  problems <- check_mediator_names(spec, model)
  if (length(problems) > 0) {
    return(problems)
  }
  problems <- c(
    check_path_names(spec, model),
    check_correlation_names(spec, model),
    check_target_path(spec, model)
  )
  if (length(problems) > 0) {
    return(problems)
  }
  check_implied_variances(spec, model)
}

check_mediator_names <- function(spec, model) {
  mediators <- model$mediators
  numbered <- paste0("M", seq_along(mediators))
  ok <- switch(
    spec$template,
    process_4 = identical(mediators, "M") ||
      (length(mediators) >= 2 && setequal(mediators, numbered)),
    process_6 = length(mediators) >= 2 && setequal(mediators, numbered),
    TRUE
  )
  if (ok) {
    return(character())
  }
  advice <- if (spec$template == "process_4") {
    "Name a single mediator 'M', or several mediators M1, M2, M3, ... with no gaps"
  } else {
    "Name the mediators M1, M2, ... in causal order, with no gaps"
  }
  sprintf("%s. The mediators are currently named %s.", advice, quote_list(mediators, "and"))
}

check_path_names <- function(spec, model) {
  required <- model_paths(model)
  given <- names(spec$population$paths)
  problems <- character()
  missing <- setdiff(required, given)
  if (length(missing) > 0) {
    problems <- c(problems, sprintf(
      "'population > paths' is missing %s. Give every path in the model a value (use 0 for no effect).",
      quote_list(missing, "and")
    ))
  }
  for (extra in setdiff(given, required)) {
    hint <- if (spec$template == "process_4" && grepl("^M[0-9]->M[0-9]$", extra)) {
      " Paths between mediators belong in serial mediation (template 'process_6')."
    } else {
      suggestion(extra, missing)
    }
    problems <- c(problems, sprintf(
      "'population > paths' has '%s', which is not a path in %s.%s",
      extra, template_name(spec$template), hint
    ))
  }
  problems
}

template_name <- function(template) {
  sprintf("PROCESS model %s", sub("process_", "", template, fixed = TRUE))
}

check_correlation_names <- function(spec, model) {
  field <- if (spec$design == "mediation") "residual_correlations" else "correlations"
  correlations <- spec$population[[field]]
  if (length(correlations) == 0) {
    return(character())
  }
  allowed_vars <- if (spec$design == "mediation") model$mediators else c("X", "W")
  if (spec$design == "mediation" && length(model$mediators) < 2) {
    return(sprintf(
      "'population > %s' is only used when there are two or more mediators; remove it.",
      field
    ))
  }
  problems <- character()
  pairs <- character()
  for (key in names(correlations)) {
    ends <- trimws(strsplit(key, "<->", fixed = TRUE)[[1]])
    if (length(ends) != 2 || !all(ends %in% allowed_vars) || ends[1] == ends[2]) {
      problems <- c(problems, sprintf(
        "'population > %s > %s' isn't a valid pair. Write pairs as 'A<->B' using %s.",
        field, key, quote_list(allowed_vars)
      ))
      next
    }
    pair <- paste(sort(ends), collapse = "<->")
    if (pair %in% pairs) {
      problems <- c(problems, sprintf(
        "'population > %s' gives the correlation %s twice; keep only one.",
        field, pair
      ))
    }
    pairs <- c(pairs, pair)
  }
  problems
}

indirect_paths <- function(model) {
  mediators <- model$mediators
  if (!isTRUE(model$serial)) {
    return(paste0("X->", mediators, "->Y"))
  }
  # Serial mediation: every ordered subset of the mediators is a path.
  chains <- lapply(seq_along(mediators), function(k) {
    vapply(
      utils::combn(mediators, k, simplify = FALSE),
      function(m) paste(c("X", m, "Y"), collapse = "->"),
      character(1)
    )
  })
  unlist(chains)
}

check_target_path <- function(spec, model) {
  path <- spec$target_test$path
  if (is.null(path)) {
    return(character())
  }
  normalised <- paste(trimws(strsplit(path, "->", fixed = TRUE)[[1]]), collapse = "->")
  valid <- indirect_paths(model)
  if (normalised %in% valid) {
    return(character())
  }
  sprintf(
    "'target_test > path' is '%s', which isn't an indirect path in this model. Choose one of %s.",
    path, quote_list(valid)
  )
}

# Build the model-implied covariance matrix one variable at a time, with all
# observed variables standardised. Exogenous variables are standardised and
# correlated as given; a product term of two standardised, jointly normal
# variables with correlation r has variance 1 + r^2 and is uncorrelated with
# every other variable. Each endogenous variable's explained variance is
# b' S b; its residual variance (1 - R-squared) must be positive. Stops at
# the first variable where it is not.
implied_r_squared <- function(spec, model) {
  paths <- spec$population$paths
  correlations <- correlation_lookup(spec)
  order <- c(model$exogenous, endogenous_order(model))
  s <- matrix(0, 0, 0)
  r_squared <- c()
  residual_var <- c()
  for (v in order) {
    if (v %in% model$exogenous) {
      covs <- vapply(rownames(s), function(u) correlations(u, v), numeric(1))
      s <- grow_cov(s, v, covs, 1)
    } else if (v %in% names(model$products)) {
      parts <- model$products[[v]]
      s <- grow_cov(s, v, rep(0, nrow(s)), 1 + s[parts[1], parts[2]]^2)
    } else {
      preds <- model$equations[[v]]
      b <- vapply(preds, function(p) as.numeric(paths[[paste0(p, "->", v)]]), numeric(1))
      explained <- drop(t(b) %*% s[preds, preds, drop = FALSE] %*% b)
      r_squared[v] <- explained
      if (explained >= 1 - 1e-8) {
        # Later variables would be built on an impossible covariance matrix.
        break
      }
      residual_var[v] <- 1 - explained
      covs <- drop(t(b) %*% s[preds, , drop = FALSE])
      # Correlated residuals between parallel mediators.
      for (u in intersect(names(residual_var), rownames(s))) {
        rho <- correlations(u, v, residual = TRUE)
        if (rho != 0 && residual_var[u] > 0 && residual_var[v] > 0) {
          covs[u] <- covs[u] + rho * sqrt(residual_var[u] * residual_var[v])
        }
      }
      s <- grow_cov(s, v, covs, 1)
    }
  }
  list(r_squared = r_squared, cov = s)
}

endogenous_order <- function(model) {
  products <- names(model$products)
  steps <- character()
  for (v in names(model$equations)) {
    # Add any product term as soon as both its parts exist.
    for (p in setdiff(products, steps)) {
      if (all(model$products[[p]] %in% c(model$exogenous, steps)) && p %in% model$equations[[v]]) {
        steps <- c(steps, p)
      }
    }
    steps <- c(steps, v)
  }
  steps
}

grow_cov <- function(s, name, covs, variance) {
  k <- nrow(s)
  out <- matrix(0, k + 1, k + 1, dimnames = list(c(rownames(s), name), c(rownames(s), name)))
  if (k > 0) {
    out[seq_len(k), seq_len(k)] <- s
    out[k + 1, seq_len(k)] <- covs
    out[seq_len(k), k + 1] <- covs
  }
  out[k + 1, k + 1] <- variance
  out
}

correlation_lookup <- function(spec) {
  exo <- spec$population$correlations
  resid <- spec$population$residual_correlations
  lookup <- function(values, a, b) {
    for (key in names(values)) {
      ends <- trimws(strsplit(key, "<->", fixed = TRUE)[[1]])
      if (setequal(ends, c(a, b))) {
        return(as.numeric(values[[key]]))
      }
    }
    0
  }
  function(a, b, residual = FALSE) {
    lookup(if (residual) resid else exo, a, b)
  }
}

check_implied_variances <- function(spec, model) {
  problems <- check_residual_correlation_matrix(spec, model)
  if (length(problems) > 0) {
    return(problems)
  }
  r2 <- implied_r_squared(spec, model)$r_squared
  for (v in names(r2)) {
    if (r2[[v]] >= 1 - 1e-8) {
      preds <- model$equations[[v]]
      problems <- c(problems, sprintf(
        paste0(
          "The paths into %s are impossible together: they would explain %s%% ",
          "of its variance (R-squared = %s), but R-squared must be below 1. ",
          "Make one or more of these paths smaller: %s."
        ),
        var_label(spec, v), format_number(round(100 * r2[[v]], 1)),
        format_number(round(r2[[v]], 3)), quote_list(paste0(preds, "->", v))
      ))
    }
  }
  problems
}

check_residual_correlation_matrix <- function(spec, model) {
  mediators <- model$mediators
  if (spec$design != "mediation" || length(mediators) < 3 ||
    length(spec$population$residual_correlations) == 0) {
    return(character())
  }
  lookup <- correlation_lookup(spec)
  r <- outer(mediators, mediators, Vectorize(function(a, b) {
    if (a == b) 1 else lookup(a, b, residual = TRUE)
  }))
  if (min(eigen(r, symmetric = TRUE, only.values = TRUE)$values) > 1e-8) {
    return(character())
  }
  paste0(
    "The residual correlations between the mediators are impossible together ",
    "(no population could have all of them at once). Make some of them closer to 0."
  )
}

# Goal --------------------------------------------------------------------------

check_goal <- function(spec, check_effect = TRUE) {
  goal <- spec$goal
  alpha <- spec$target_test$alpha
  problems <- character()
  if (!is.null(goal$power) && goal$power <= alpha) {
    problems <- c(problems, sprintf(
      paste0(
        "'goal > power' (%s) must be greater than alpha (%s): even with no ",
        "real effect, a test is significant alpha of the time."
      ),
      format_number(goal$power), format_number(alpha)
    ))
  }
  if (!is.null(goal$n)) {
    problems <- c(problems, check_n(spec, goal$n))
  }
  if (check_effect && goal$type %in% c("sample_size", "sensitivity") &&
    target_effect_is_zero(spec)) {
    consequence <- if (goal$type == "sample_size") {
      "no sample size can reach the target power"
    } else {
      "there is no effect pattern to scale for a sensitivity analysis"
    }
    problems <- c(problems, paste0(
      "The effect you want to detect is zero in this population, so ",
      consequence, ". Check the population values, or use goal type 'power' ",
      "to check the Type I error rate."
    ))
  }
  problems
}

check_n <- function(spec, n) {
  minimum <- minimum_n(spec)
  if (n < minimum) {
    return(sprintf(
      "'goal > n' is %s, but this design needs at least %s participants.",
      format_number(n), format_number(minimum)
    ))
  }
  groups <- group_split(spec)
  if (is.null(groups)) {
    return(character())
  }
  if (groups$valid(n)) {
    return(character())
  }
  below <- if (n > minimum) seq(max(minimum, n - 1000), n - 1) else numeric()
  nearby <- c(
    utils::tail(Filter(groups$valid, below), 1),
    utils::head(Filter(groups$valid, seq(n + 1, n + 1000)), 1)
  )
  if (length(nearby) == 0) {
    return(sprintf(
      "'options > allocation_ratio' (%s) can't split any nearby n into whole groups. Use a simple ratio such as 2 or 1.5.",
      format_number(spec$options$allocation_ratio)
    ))
  }
  sprintf(
    "'goal > n' must %s; %s doesn't. The nearest that do: %s.",
    groups$rule, format_number(n), paste(nearby, collapse = " and ")
  )
}

minimum_n <- function(spec) {
  switch(
    spec$design,
    basic_test = switch(
      spec$template,
      one_sample_t = 3,
      paired_t = 3,
      chi_square_independence = length(unlist(spec$population$probabilities)),
      4
    ),
    factorial_anova = if (spec$template == "2x2_between") 8 else 4,
    regression_interaction = 6,
    # Enough for the largest regression in the model plus two residual df.
    max(lengths(path_model(spec)$equations)) + 3
  )
}

group_split <- function(spec) {
  whole <- function(x) abs(x - round(x)) < 1e-9
  if (spec$template == "2x2_between") {
    return(list(rule = "split into 4 equal cells for a 2x2 between-participants design", valid = function(n) n %% 4 == 0))
  }
  if (spec$template == "2x2_mixed") {
    return(list(rule = "split into 2 equal groups for the between-participants factor", valid = function(n) n %% 2 == 0))
  }
  if (spec$template %in% c("independent_t", "two_proportions")) {
    ratio <- spec$options$allocation_ratio %||% 1
    return(list(
      rule = sprintf("split into two whole groups in the ratio 1 : %s", format_number(ratio)),
      valid = function(n) whole(n / (1 + ratio)) && whole(n * ratio / (1 + ratio))
    ))
  }
  NULL
}

target_effect_is_zero <- function(spec) {
  pop <- spec$population
  paths <- pop$paths
  value <- switch(
    spec$design,
    basic_test = switch(
      spec$template,
      one_sample_t = pop$d,
      independent_t = pop$d,
      paired_t = pop$dz,
      correlation = pop$r,
      two_proportions = pop$p1 - pop$p2,
      chi_square_independence = {
        p <- matrix(as.numeric(unlist(pop$probabilities)), nrow = length(pop$probabilities), byrow = TRUE)
        max(abs(p - outer(rowSums(p), colSums(p))))
      }
    ),
    factorial_anova = anova_contrast(spec),
    regression_interaction = pop$r_XW_Y,
    mediation = {
      nodes <- trimws(strsplit(spec$target_test$path, "->", fixed = TRUE)[[1]])
      prod(vapply(seq_len(length(nodes) - 1), function(i) {
        as.numeric(paths[[paste0(nodes[i], "->", nodes[i + 1])]])
      }, numeric(1)))
    },
    moderated_mediation = switch(
      spec$template,
      process_7 = paths[["XW->M"]] * paths[["M->Y"]],
      process_14 = paths[["X->M"]] * paths[["MW->Y"]]
    )
  )
  isTRUE(abs(value) < 1e-12)
}
