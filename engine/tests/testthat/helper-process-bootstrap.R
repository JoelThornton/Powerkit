# Independent equation fits on the same observations/resampling indices.
# No power4mome/manymome fitting or indirect-effect function is used here.
process_ols_effect <- function(data, inputs) {
  fits <- lapply(names(inputs$equations), function(outcome) {
    terms <- vapply(inputs$equations[[outcome]], inputs$term, "")
    stats::lm(stats::reformulate(terms, response = outcome), data = data)
  })
  names(fits) <- names(inputs$equations)
  path <- function(from, to) unname(stats::coef(fits[[to]])[inputs$term(from)])
  args <- inputs$test_args
  mediators <- args$m
  if (identical(inputs$test_name, "test_indirect_effect")) {
    nodes <- c(args$x, mediators, args$y)
    return(prod(vapply(seq_len(length(nodes) - 1L), function(i) path(nodes[i], nodes[i + 1L]), 0)))
  }
  mediator <- mediators[1]
  conditional <- function(w) {
    a <- path(args$x, mediator)
    b <- path(mediator, args$y)
    first <- paste0(args$x, args$w)
    second <- paste0(mediator, args$w)
    if (first %in% inputs$equations[[mediator]]) a <- a + path(first, mediator) * w
    if (second %in% inputs$equations[[args$y]]) b <- b + path(second, args$y) * w
    a * b
  }
  if (identical(inputs$test_name, "test_cond_indirect_diff")) return(conditional(args$w_to) - conditional(args$w_from))
  conditional(1) - conditional(0) # index for the linear model-7/14 effect
}

process_reference_interval <- function(data, inputs, boot_out) {
  ids <- attr(boot_out, "ids")
  stopifnot(length(ids) == inputs$ci_draws)
  effects <- vapply(ids, function(i) process_ols_effect(data[i, , drop = FALSE], inputs), 0)
  t0 <- process_ols_effect(data, inputs)
  ci <- suppressWarnings(boot::boot.ci(list(t0 = t0, t = matrix(effects, ncol = 1), R = length(effects)),
    type = "perc", conf = inputs$test_args$level))$perc[4:5]
  list(estimate = t0, effects = effects, ci = ci, significant = as.numeric(ci[1] > 0 || ci[2] < 0))
}

process_bootstrap_spec <- function(name, draws = 100L) {
  spec <- sim_spec(name)
  for (v in names(spec$variables)) spec$variables[[v]]$reliability <- NULL
  spec$target_test$method <- "ols_percentile_bootstrap"
  spec$options$ci_draws <- draws
  validate_quietly(spec)
}
