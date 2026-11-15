# Backend adapter: a clustered trial with a yes/no outcome, simulated
# (cluster_trial / cluster_randomised or multisite, population > metric
# "proportion", target_test > method "glmer_simulation"; E34).
#
# powertools' crt.parallel.bin() and multisite.bin() (backend-powertools.R,
# the default) give the z test of the log odds ratio by formula, with the
# variance multiplied by 1.2, a factor their help pages give no source for
# (docs/upstream-questions.md; Known difference 16). This route simulates
# the same trial and analyses each simulated study as researchers do, with
# lme4's glmer(), so the answer carries no such factor:
#
#   cluster-randomised  J groups of m, half the groups in each condition.
#                       Each group's log odds are its condition's,
#                       qlogis(p1) or qlogis(p2), plus a normal deviation
#                       with SD sigma_u (crt.parallel.bin()'s model).
#                       Analysed with glmer(y ~ cond + (1 | cluster),
#                       family = binomial).
#   multisite           J groups of m, half of each group in each condition
#                       (m - m %/% 2 in the first when m is odd). The log
#                       odds ratio varies between groups with SD sigma_u
#                       around log(OR), the conditions coded -1/2 and +1/2
#                       around the average of qlogis(p1) and qlogis(p2)
#                       (multisite.bin()'s model, which has no variation in
#                       the groups' average rates). Analysed with
#                       glmer(y ~ cond + (0 + cond | cluster), family =
#                       binomial), the model the formula describes.
#
# The test is glmer's Wald z test of cond, as in the formulas: two-sided,
# or one-sided in the direction the spec gives (validate_spec() refuses a
# one-sided test pointing away from the effect). A study whose model can't
# be fitted counts as not significant, as simr counts it. Spower runs the
# experiment p_cluster_glmer(). The data are drawn exactly as the
# simulated-data section of the exported script draws them
# (sim_cluster_model_code()).

cluster_glmer_test <- function(spec) {
  identical(spec$design, "cluster_trial") && isTRUE(spec$template %in% c("cluster_randomised", "multisite")) &&
    identical(spec$population$metric, "proportion") && identical(spec$target_test$method, "glmer_simulation")
}

cluster_glmer_inputs <- function(spec) {
  pop <- spec$population
  alternative <- spec$target_test$alternative %||% "two_sided"
  list(
    m = as.integer(pop$cluster_size),
    p1 = as.numeric(pop$p1),
    p2 = as.numeric(pop$p2),
    sigma_u = as.numeric(pop$sigma_u),
    multisite = is_multisite(spec),
    # 0 two-sided, 1 when the second condition is expected higher, -1 lower.
    direction = if (identical(alternative, "two_sided")) 0L else if (identical(alternative, "less")) -1L else 1L,
    alpha = spec$target_test$alpha
  )
}

# One study's data: cluster (a factor), cond (0 the first condition, 1 the
# second; centred to -1/2 and +1/2 for a multisite trial) and y (0 or 1).
cluster_glmer_data <- function(n, m, p1, p2, sigma_u, multisite) {
  clusters <- as.integer(n %/% m)
  cluster <- rep(seq_len(clusters), each = m)
  if (multisite) {
    condition <- rep(rep(0:1, c(m - m %/% 2, m %/% 2)), clusters)
    effect <- log((p2 / (1 - p2)) / (p1 / (1 - p1))) + stats::rnorm(clusters, sd = sigma_u)
    log_odds <- (stats::qlogis(p1) + stats::qlogis(p2)) / 2 + effect[cluster] * (condition - 0.5)
    cond <- condition - 0.5
  } else {
    condition <- rep(0:1, each = clusters * m / 2)
    log_odds <- stats::qlogis(c(p1, p2))[condition + 1] + stats::rnorm(clusters, sd = sigma_u)[cluster]
    cond <- condition
  }
  data.frame(cluster = factor(cluster), cond = cond, y = stats::rbinom(length(cluster), 1, stats::plogis(log_odds)))
}

cluster_glmer_formula <- function(multisite) {
  stats::as.formula(if (multisite) "y ~ cond + (0 + cond | cluster)" else "y ~ cond + (1 | cluster)", env = globalenv())
}

cluster_glmer_fit <- function(data, multisite) {
  tryCatch(suppressMessages(suppressWarnings(
    lme4::glmer(cluster_glmer_formula(multisite), data = data, family = stats::binomial())
  )), error = function(e) NULL)
}

# The Wald z test's p value for cond: two-sided, or one-sided in the
# expected direction. 1 when the model can't be fitted or the outcome
# doesn't vary.
cluster_glmer_p <- function(data, multisite, direction) {
  if (length(unique(data$y)) < 2) return(1)
  fit <- cluster_glmer_fit(data, multisite)
  if (is.null(fit)) return(1)
  coefs <- tryCatch(summary(fit)$coefficients, error = function(e) NULL)
  if (is.null(coefs) || !"cond" %in% rownames(coefs)) return(1)
  z <- coefs["cond", "z value"]
  if (!is.finite(z)) return(1)
  if (direction == 0L) 2 * stats::pnorm(-abs(z)) else stats::pnorm(direction * z, lower.tail = FALSE)
}

# The experiment Spower runs: one study, TRUE when the test is significant.
p_cluster_glmer <- function(n, m, p1, p2, sigma_u, multisite, direction, alpha) {
  data <- cluster_glmer_data(n, m, p1, p2, sigma_u, multisite)
  cluster_glmer_p(data, multisite, direction) < alpha
}

cluster_glmer_count <- function(inputs, n, nrep, seed) {
  args <- c(list(n = n), inputs[c("m", "p1", "p2", "sigma_u", "multisite", "direction", "alpha")])
  # Spower's sig.level is unused: the experiment returns its own decision.
  result <- spower_eval(as.name("p_cluster_glmer"), args, nrep, 0.05, seed)
  round(result$power * nrep)
}

cluster_glmer_label <- function(inputs) {
  sprintf("Spower::Spower(p_cluster_glmer()) (lme4::glmer(%s, family = binomial), Wald z test of cond)",
    if (inputs$multisite) "y ~ cond + (0 + cond | cluster)" else "y ~ cond + (1 | cluster)")
}

cluster_glmer_backend <- function(spec, seed = NULL) {
  inputs <- cluster_glmer_inputs(spec)
  list(
    name = "Spower",
    packages = c("Spower", "SimDesign", "lme4"),
    methods = "simulation",
    default_method = "simulation",
    functions = c(simulation = cluster_glmer_label(inputs)),
    n_step = valid_n_step(spec),
    exact_min_n = minimum_n(spec),
    simulate = function(n, nrep, seed, cores) {
      simulate_in_chunks(nrep, seed, cores, function(chunk, chunk_seed) cluster_glmer_count(inputs, n, chunk, chunk_seed))
    },
    sensitivity = NULL,
    check_run = function() cluster_glmer_check_run(inputs, seed)
  )
}

# Check run: one large trial (400 groups) drawn as the experiment draws it
# and fitted with glmer(): the log odds ratio within 5 of its standard
# errors, and sigma_u within 5 of its approximate standard error. That SE
# is the delta-method SE of an SD from the variance's, (sigma_u^2 + noise)
# sqrt(2 / (J - 1)), where noise is the binomial sampling variance of one
# group's estimate on the log-odds scale (of its intercept, or of its log
# odds ratio for a multisite trial); it is generous, so a translation
# error (an SD given as a variance, a swapped condition) is many SEs out.
cluster_glmer_check_run <- function(inputs, seed) {
  clusters <- 400L
  n <- clusters * inputs$m
  data <- with_seed(seed %||% 1L, cluster_glmer_data(n, inputs$m, inputs$p1, inputs$p2, inputs$sigma_u, inputs$multisite))
  fit <- call_backend("lme4", cluster_glmer_fit(data, inputs$multisite))
  if (is.null(fit)) abort_run("The check run's mixed-effects logistic model could not be fitted.")
  coefs <- summary(fit)$coefficients
  log_or <- stats::qlogis(inputs$p2) - stats::qlogis(inputs$p1)
  unit <- function(p) 1 / (p * (1 - p))
  noise <- if (inputs$multisite) {
    (unit(inputs$p1) + unit(inputs$p2)) / (inputs$m / 2)
  } else {
    mean(c(unit(inputs$p1), unit(inputs$p2))) / inputs$m
  }
  se_sd <- (inputs$sigma_u^2 + noise) * sqrt(2 / (clusters - 1)) / (2 * max(inputs$sigma_u, 0.05))
  sigma_u <- as.data.frame(lme4::VarCorr(fit))$sdcor[1]
  check <- rbind(
    check_run_rows("log odds ratio, condition 2 against condition 1", log_or, coefs["cond", "Estimate"], coefs["cond", "Std. Error"]),
    check_run_rows(if (inputs$multisite) "SD of the log odds ratio across groups (sigma_u)" else "SD of the groups' log odds (sigma_u)",
      inputs$sigma_u, sigma_u, se_sd)
  )
  rownames(check) <- NULL
  check
}

# The standalone script (export_script()).
cluster_glmer_script <- function(spec, result) {
  inputs <- cluster_glmer_inputs(spec)
  v <- spec$variables
  levels <- unlist(v$X$levels)
  header <- script_header(spec, result, "Spower", "Spower::Spower, lme4::glmer")
  test_line <- if (inputs$direction == 0L) {
    "  2 * pnorm(-abs(z)) < alpha # two-sided Wald z test"
  } else {
    sprintf("  pnorm(%sz, lower.tail = FALSE) < alpha # one-sided Wald z test: %s higher in condition 2",
      if (inputs$direction < 0) "-" else "", if (inputs$direction < 0) "'yes' less often" else "'yes' more often")
  }
  data_lines <- if (inputs$multisite) c(
    "  condition <- rep(rep(0:1, c(m - m %/% 2, m %/% 2)), clusters) # half of each group in each condition",
    "  effect <- log((p2 / (1 - p2)) / (p1 / (1 - p1))) + rnorm(clusters, sd = sigma_u) # each group's log odds ratio",
    "  log_odds <- (qlogis(p1) + qlogis(p2)) / 2 + effect[cluster] * (condition - 0.5)",
    "  cond <- condition - 0.5 # coded -1/2 and +1/2"
  ) else c(
    "  condition <- rep(0:1, each = clusters * m / 2) # each whole group in one condition",
    "  log_odds <- qlogis(c(p1, p2))[condition + 1] + rnorm(clusters, sd = sigma_u)[cluster] # each group's own deviation",
    "  cond <- condition"
  )
  c(
    header,
    "library(Spower)",
    "library(lme4)",
    "",
    "# Inputs ----",
    sprintf("# The outcome, %s, is yes/no; the conditions are %s: 1 = %s, 2 = %s.",
      comment_text(v$Y$label), comment_text(v$X$label), comment_text(levels[1]), comment_text(levels[2])),
    sprintf("p1 <- %s # proportion of 'yes' in condition 1", r_code(inputs$p1)),
    sprintf("p2 <- %s # proportion of 'yes' in condition 2", r_code(inputs$p2)),
    sprintf("sigma_u <- %s # %s", r_code(inputs$sigma_u),
      if (inputs$multisite) "SD of the log odds ratio across groups" else "SD of the groups' log odds"),
    sprintf("m <- %s # people analysed in each group", r_code(inputs$m)),
    goal_inputs(spec, result),
    "",
    sprintf("# One simulated study: %s, then lme4's glmer() with %s.",
      if (inputs$multisite) "groups with both conditions, each with its own effect" else "whole groups in each condition, each with its own rate",
      if (inputs$multisite) "the effect varying across groups" else "a random intercept for the groups"),
    "# TRUE when the Wald z test of the conditions is significant; a study",
    "# whose model can't be fitted counts as not significant.",
    "p_cluster_glmer <- function(n) {",
    "  clusters <- n %/% m",
    "  cluster <- rep(seq_len(clusters), each = m)",
    data_lines,
    "  y <- rbinom(length(cluster), 1, plogis(log_odds))",
    "  if (length(unique(y)) < 2) return(FALSE)",
    "  fit <- tryCatch(suppressMessages(suppressWarnings(glmer(",
    sprintf("    %s, data = data.frame(y, cond, cluster = factor(cluster)), family = binomial",
      if (inputs$multisite) "y ~ cond + (0 + cond | cluster)" else "y ~ cond + (1 | cluster)"),
    "  ))), error = function(e) NULL)",
    "  if (is.null(fit)) return(FALSE)",
    "  z <- summary(fit)$coefficients[\"cond\", \"z value\"]",
    "  if (!is.finite(z)) return(FALSE)",
    test_line,
    "}",
    "",
    "# One batch: significant results, and studies run.",
    "run_batch <- function(batch_n, batch_replications, batch_seed) {",
    "  set.seed(batch_seed)",
    "  result <- Spower(p_cluster_glmer(n = batch_n), replications = batch_replications, parallel = FALSE, verbose = FALSE)",
    "  c(round(result$power * batch_replications), batch_replications)",
    "}",
    "",
    batch_section(result, "Spower()"),
    simulation_goal_section(spec, result, valid_n_step(spec)),
    comparison_section()
  )
}
