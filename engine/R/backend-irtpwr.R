# Backend adapter: differential item functioning (DIF) in a 2PL IRT model,
# by irtpwr's analytical method.
#
# irtpwr (Zimmer and Debelak, 2023, the package's citation()) gives
# the power of the Wald, likelihood-ratio, score and gradient tests of a
# linear hypothesis about IRT parameters from their noncentrality per
# person. Its preset "DIF2PL" tests whether items' parameters differ between
# two groups of equal size whose abilities are standard normal, every other
# item's parameters being equal; it builds the hypothesis from the
# parameters that differ in the population given. powerkit passes the
# package's own preset with its res() function, which builds that
# hypothesis matrix, replaced through setup.hypothesis(type = <list>), the
# package's documented way to give a custom preset, for two reasons:
#   - the preset stops with an error when only one parameter differs (a
#     matrix subset drops to a vector; docs/upstream-questions.md), fixed by
#     drop = FALSE;
#   - the usual likelihood-ratio test of DIF frees both of an item's
#     parameters (2 df), so by default the hypothesis, and the unrestricted
#     model the preset's unres() builds, name both parameters of each DIF
#     item whether or not both differ; target_test > free_parameters =
#     "differing" keeps the preset's own choice (docs/conventions.md).
# Items are entered as discrimination a and difficulty b, as researchers
# report them; irtpwr's intercept is d = -a b.

irt_stat_names <- c(likelihood_ratio = "LR", wald = "Wald", score = "Score", gradient = "Gradient")

# The parameters the hypothesis names: both of each DIF item's, or those
# that differ between the groups' parameter sets.
irt_hypothesis_matrix <- function(altpars, items, free) {
  n.items <- length(altpars[[1]][[1]])
  reA <- altpars[[1]]
  reB <- altpars[[2]]
  if (identical(free, "both")) {
    hyp_a <- sort(items)
    hyp_d <- sort(items)
  } else {
    hyp_a <- which(reA$a != reB$a)
    hyp_d <- which(reA$d != reB$d)
  }
  Amat <- matrix(0, nrow = length(c(hyp_a, hyp_d)), ncol = n.items * 2)
  i <- 1
  for (j in hyp_a) {
    Amat[i, j * 2 - 1] <- 1
    i <- i + 1
  }
  for (j in hyp_d) {
    Amat[i, j * 2] <- 1
    i <- i + 1
  }
  Amat <- cbind(Amat, -Amat)
  delcols <- (colSums(Amat) == 0) & (1:(n.items * 2 * 2)) > 2 * n.items
  list(n.items = n.items, hyp_a = hyp_a, hyp_d = hyp_d, Amat = Amat, delcols = delcols)
}

irt_preset <- function(items, free = "both") {
  preset <- utils::getFromNamespace("h_DIF2PL", "irtpwr")
  pars_long <- utils::getFromNamespace("pars.long", "irtpwr")
  preset$res <- function(altpars, nullpars = NULL) {
    h <- irt_hypothesis_matrix(altpars, items, free)
    n.items <- h$n.items
    delcols <- h$delcols
    relpars <- colSums(h$Amat[, 1:(2 * n.items), drop = FALSE]) == 1
    Amat <- h$Amat[, !delcols, drop = FALSE]
    list(n.items = n.items, itemtype = "2PL", Amat = Amat, cvec = 0,
      model = mirt::mirt.model(paste("F = 1-", n.items, "\n CONSTRAINB = (1-", n.items, ", d), (1-", n.items, ", a1)")),
      multigroup = TRUE, delcols = delcols, relpars = relpars)
  }
  preset$unres <- function(altpars) {
    h <- irt_hypothesis_matrix(altpars, items, free)
    n.items <- h$n.items
    reA <- altpars[[1]]
    reB <- altpars[[2]]
    reA$itemtype <- reB$itemtype <- "2PL"
    reA$longpars <- pars_long(pars = reA, itemtype = "2PL")
    reB$longpars <- pars_long(pars = reB, itemtype = "2PL")
    constrain_a <- setdiff(seq_len(n.items), h$hyp_a)
    constrain_d <- setdiff(seq_len(n.items), h$hyp_d)
    list(parsets = list(reA, reB),
      model = mirt::mirt.model(paste("F = 1-", n.items, "\n CONSTRAINB = (", paste(constrain_d, collapse = ","), ", d), (", paste(constrain_a, collapse = ","), ", a1)")),
      longpars = c(reA$longpars, reB$longpars)[!h$delcols], multigroup = TRUE, itemtype = "2PL", delcols = h$delcols)
  }
  preset
}

irt_inputs <- function(spec) {
  pop <- spec$population
  a <- as.numeric(unlist(pop$a))
  b <- as.numeric(unlist(pop$b))
  items <- as.integer(unlist(pop$dif_items))
  shift <- as.numeric(unlist(pop$b_shift %||% rep(0, length(items))))
  change <- as.numeric(unlist(pop$a_change %||% rep(0, length(items))))
  focal_a <- a
  focal_b <- b
  focal_a[items] <- a[items] + change
  focal_b[items] <- b[items] + shift
  list(
    reference = list(a = a, d = -a * b), focal = list(a = focal_a, d = -focal_a * focal_b),
    items = items, shift = shift, change = change, alpha = spec$target_test$alpha,
    stat = irt_stat_names[[spec$target_test$method %||% "likelihood_ratio"]],
    free = spec$target_test$free_parameters %||% "both"
  )
}

# The noncentrality per person of each statistic (irtpwr's analytical
# method), computed once.
irt_result <- function(inputs, seed = NULL) {
  hyp <- irtpwr::setup.hypothesis(type = irt_preset(inputs$items, inputs$free), altpars = list(inputs$reference, inputs$focal))
  with_seed(seed %||% 1L, quietly(irtpwr::irtpwr(hyp = hyp, N = 100, alpha = inputs$alpha)))
}

irt_power <- function(result, inputs, n) {
  unname(summary(result, N = n, alpha = inputs$alpha)$result[[inputs$stat]])
}

irt_backend <- function(spec, seed = NULL) {
  inputs <- irt_inputs(spec)
  step <- valid_n_step(spec)
  result <- NULL
  power_at <- function(n) {
    if (is.null(result)) result <<- call_backend("irtpwr", irt_result(inputs, seed))
    call_backend("irtpwr", irt_power(result, inputs, n))
  }
  list(
    name = "irtpwr",
    packages = c("irtpwr", "mirt"),
    methods = "exact",
    default_method = "exact",
    functions = c(exact = sprintf("irtpwr::irtpwr(method = \"analytical\") (%s statistic), DIF in a 2PL model", inputs$stat)),
    n_step = step,
    exact_min_n = step * ceiling(minimum_n(spec) / step),
    exact_power = power_at,
    bracket_power = power_at,
    simulate = NULL,
    sensitivity = NULL,
    check_run = function() irt_check_run(spec, inputs, seed)
  )
}

# Check run: a large sample drawn from the two groups' models (mirt's
# simdata(), as irtpwr draws them), and each DIF item's proportion of
# 'yes' in each group against the model's expectation over a standard
# normal ability.
irt_check_run <- function(spec, inputs, seed) {
  n <- 50000
  expected <- function(a, d) vapply(seq_along(a), function(i) stats::integrate(function(th) stats::plogis(a[i] * th + d[i]) * stats::dnorm(th), -Inf, Inf)$value, numeric(1))
  draw <- function(pars) {
    th <- matrix(stats::rnorm(n), ncol = 1)
    p <- stats::plogis(outer(th[, 1], pars$a) + matrix(pars$d, n, length(pars$a), byrow = TRUE))
    matrix(stats::runif(length(p)) < p, n)
  }
  ref <- with_seed(seed %||% 1L, draw(inputs$reference))
  foc <- with_seed((seed %||% 1L) + 1L, draw(inputs$focal))
  items <- inputs$items
  e_ref <- expected(inputs$reference$a, inputs$reference$d)[items]
  e_foc <- expected(inputs$focal$a, inputs$focal$d)[items]
  o_ref <- colMeans(ref)[items]
  o_foc <- colMeans(foc)[items]
  check_run_rows(
    c(sprintf("proportion of 'yes' to item %d, reference group", items), sprintf("proportion of 'yes' to item %d, focal group", items)),
    c(e_ref, e_foc), c(o_ref, o_foc), sqrt(c(e_ref * (1 - e_ref), e_foc * (1 - e_foc)) / n)
  )
}

check_irt <- function(spec) {
  pop <- spec$population
  k <- length(unlist(pop$a))
  problems <- character()
  if (length(unlist(pop$b)) != k) {
    problems <- c(problems, sprintf("'population > b' needs one difficulty for each of the %d items in 'population > a'; it has %d.", k, length(unlist(pop$b))))
  }
  items <- as.integer(unlist(pop$dif_items))
  if (any(items > k)) {
    problems <- c(problems, sprintf("'population > dif_items' names an item beyond the %d given.", k))
  }
  if (length(items) && all(seq_len(k) %in% items)) {
    problems <- c(problems, "At least one item must work the same way in both groups (an anchor item); 'population > dif_items' names every item.")
  }
  if (anyDuplicated(items)) {
    problems <- c(problems, "'population > dif_items' names an item twice.")
  }
  for (field in c("b_shift", "a_change")) {
    if (!is.null(pop[[field]]) && length(unlist(pop[[field]])) != length(items)) {
      problems <- c(problems, sprintf("'population > %s' needs one value for each DIF item (%d); it has %d.", field, length(items), length(unlist(pop[[field]]))))
    }
  }
  if (is.null(pop$b_shift) && is.null(pop$a_change)) {
    problems <- c(problems, "Give the DIF: 'population > b_shift' (a change in difficulty) or 'population > a_change' (a change in discrimination), one value per DIF item.")
  }
  problems
}

irt_design_description <- function(spec, label) {
  inputs <- irt_inputs(spec)
  sprintf("differential item functioning in %s between %s (%s): %d items in a 2PL IRT model, DIF in item%s %s; the %s test of the multigroup model%s",
    label("Y"), label("G"), paste(unlist(spec$variables$G$levels), collapse = ", "), length(inputs$reference$a),
    if (length(inputs$items) > 1) "s" else "", paste(inputs$items, collapse = ", "),
    switch(inputs$stat, LR = "likelihood-ratio", Wald = "Wald", Score = "score", Gradient = "gradient"),
    if (identical(inputs$free, "both")) " with each DIF item's discrimination and difficulty free" else " with only the differing parameters free")
}

irt_script <- function(spec, result) {
  inputs <- irt_inputs(spec)
  c(
    script_header(spec, result, "irtpwr", "irtpwr::irtpwr"),
    "library(irtpwr)",
    "",
    "# Inputs ----",
    goal_inputs(spec, result),
    sprintf("reference <- list(a = %s, d = %s) # 2PL slopes and intercepts (d = -a b), reference group", r_code(inputs$reference$a), r_code(inputs$reference$d)),
    sprintf("focal <- list(a = %s, d = %s) # the same items in the focal group", r_code(inputs$focal$a), r_code(inputs$focal$d)),
    sprintf("statistic <- %s", r_code(inputs$stat)),
    "",
    sprintf("dif_items <- %s", r_code(inputs$items)),
    sprintf("free <- %s # \"both\": each DIF item's slope and intercept tested (2 df each); \"differing\": only the parameters that differ", r_code(inputs$free)),
    "",
    "# irtpwr's preset \"DIF2PL\", with its res() and unres(), which build the",
    "# hypothesis and the unrestricted model, naming the parameters chosen",
    "# above (the preset names those that differ) and keeping a one-row matrix",
    "# from dropping to a vector (drop = FALSE), so that one parameter works.",
    paste0("irt_hypothesis_matrix <- ", paste(deparse(irt_hypothesis_matrix), collapse = "\n")),
    "items <- dif_items",
    "pars_long <- utils::getFromNamespace(\"pars.long\", \"irtpwr\")",
    "preset <- utils::getFromNamespace(\"h_DIF2PL\", \"irtpwr\")",
    paste0("preset$res <- ", paste(deparse(irt_preset(inputs$items, inputs$free)$res), collapse = "\n")),
    paste0("preset$unres <- ", paste(deparse(irt_preset(inputs$items, inputs$free)$unres), collapse = "\n")),
    "hyp <- setup.hypothesis(type = preset, altpars = list(reference, focal))",
    "set.seed(1)",
    "fitted <- irtpwr(hyp = hyp, N = 100, alpha = alpha)",
    "power_at <- function(n_total) unname(summary(fitted, N = n_total, alpha = alpha)$result[[statistic]])",
    "",
    pwr_goal_section(spec, result),
    comparison_section()
  )
}
