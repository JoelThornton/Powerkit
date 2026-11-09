#' A rough power curve for a whole study, over a few sample sizes
#'
#' Simulates the whole study at a few total sample sizes around the spec's
#' n, with `nrep` replications at each, to show roughly how power grows with
#' n and which n reaches a target. It is a quick guide, not a sample size:
#' with 200 replications each power is within about 6 percentage points,
#' so the sample size to report comes from [run_whole_study()] with the
#' goal `sample_size` (or the script from [export_whole_study_script()]).
#'
#' Each n is simulated by the same routine as [run_whole_study()]
#' (power4mome for a path model, Superpower for an experiment), with the
#' spec's seed, and the power at each n is read by the claim's criterion,
#' as in a sample size search: with one main analysis, its power; under
#' "all", the chance that every main analysis is significant; under "any",
#' that at least one is; under "each", the power of the weakest main
#' analysis. The curve is offered for experiments and for regressions
#' (effects of X, interactions, effects on the mediator); a mediation's
#' confidence intervals make even a rough curve too slow to run here.
#'
#' @param spec A whole-study specification (see [validate_whole_study()])
#'   with the goal `power`, whose `n` is the middle of the curve.
#' @param multipliers The sample sizes, as multiples of the spec's n. Each
#'   is rounded up to a size the design allows (equal groups for an
#'   experiment) and to at least the smallest n it can be analysed at.
#' @param nrep Replications at each sample size.
#' @return A `powerkit_whole_study_curve`: a list with `curve` (a data frame:
#'   `n`, `power` by the criterion, its 95% Clopper-Pearson interval
#'   `lower` and `upper`, and `nrep`), `analyses` (the same for each
#'   analysis, with its `id`, `label` and `role`), `rule` and `criterion`
#'   (what power means here, as in [run_whole_study()]'s search) and
#'   `provenance` (spec hash, seed, replications, backend, R and package
#'   versions).
#' @export
#' @examples
#' \donttest{
#' spec <- jsonlite::fromJSON(
#'   system.file("whole-study", "example.json", package = "powerkit"),
#'   simplifyVector = FALSE
#' )
#' # A moderated regression only (no mediator), with 100 simulated studies.
#' spec$analyses <- spec$analyses[c(1, 3)]
#' spec$analyses[[2]]$role <- "main"
#' spec$variables$M <- NULL
#' spec$population$paths <- list(`X->Y` = 0.25, `W->Y` = 0.1, `XW->Y` = 0.15)
#' spec$options$ci_draws <- NULL
#' spec$options$nrep <- 100L
#' curve <- whole_study_curve(spec, multipliers = c(0.5, 1, 2), nrep = 100L)
#' curve$curve
#' }
whole_study_curve <- function(spec, multipliers = c(0.5, 0.75, 1, 1.25, 1.5, 2), nrep = 200L) {
  spec <- validate_whole_study(spec)
  if (!identical(spec$goal$type, "power") || is.null(spec$goal$n)) {
    abort_spec("A power curve needs a whole-study spec with the goal \"power\" at a total n.")
  }
  if (!is.numeric(multipliers) || !length(multipliers) || any(!is.finite(multipliers) | multipliers <= 0)) {
    abort_spec("The curve's sample sizes need positive multiples of n.")
  }
  nrep <- as.integer(nrep)
  if (is.na(nrep) || nrep < 50) abort_spec("A power curve needs at least 50 replications at each sample size.")
  seed <- spec$options$seed %||% sample.int(2147483646L, 1)
  cores <- powerkit_cores()
  started <- Sys.time()
  experiment <- whole_study_is_experiment(spec)
  if (experiment) {
    inputs <- whole_study_experiment_inputs(spec)
    sp <- inputs$superpower
    step <- if (!is.null(sp$cell_ratio)) cell_ratio_step(sp$cell_ratio) else sp$groups
    min_n <- whole_study_experiment_min_n(inputs)
    counts <- function(n) whole_study_experiment_counts(inputs, n, nrep, seed, cores)
    backend <- "Superpower"
    packages <- c("powerkit", "Superpower", "afex")
  } else {
    hash <- spec_hash(spec)
    spec <- whole_study_resolve_group_d(spec, seed)
    inputs <- whole_study_inputs(spec)
    if (isTRUE(inputs$needs_draws)) {
      abort_spec("A rough power curve isn't available for a mediation, whose confidence intervals make each run slow. Use the R script for the sample size search.")
    }
    step <- 1
    min_n <- minimum_n(spec)
    counts <- function(n) whole_study_counts(inputs, n, nrep, seed, cores)
    backend <- "power4mome"
    packages <- c("powerkit", "power4mome", "manymome", "lavaan", "lmhelprs")
  }
  ns <- sort(unique(step * ceiling(pmax(min_n, spec$goal$n * multipliers) / step)))
  criterion <- whole_study_criterion(spec, inputs)
  rows <- lapply(ns, function(n) {
    totals <- counts(n)
    picked <- criterion$counts(totals)
    overall <- whole_study_rate(unname(picked[[1]]), unname(picked[[2]]), nrep)
    each <- do.call(rbind, lapply(inputs$analyses, function(a) {
      r <- whole_study_rate(totals[[paste0(a$id, ":sig")]], totals[[paste0(a$id, ":valid")]], nrep)
      data.frame(n = n, id = a$id, label = a$label, role = a$role,
        power = r[["power"]], lower = r[["lower"]], upper = r[["upper"]], nrep = r[["nrep"]])
    }))
    list(curve = data.frame(n = n, power = overall[["power"]], lower = overall[["lower"]],
      upper = overall[["upper"]], nrep = overall[["nrep"]]), analyses = each)
  })
  structure(
    list(
      curve = do.call(rbind, lapply(rows, `[[`, "curve")),
      analyses = do.call(rbind, lapply(rows, `[[`, "analyses")),
      rule = criterion$rule,
      criterion = criterion$description,
      provenance = list(
        spec_hash = if (experiment) spec_hash(spec) else hash,
        method = "simulation",
        seed = seed,
        nrep = nrep,
        cores = cores,
        backend = backend,
        r_version = R.version.string,
        packages = package_versions(packages),
        started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
        run_time_seconds = as.numeric(difftime(Sys.time(), started, units = "secs"))
      )
    ),
    class = "powerkit_whole_study_curve"
  )
}

#' @export
print.powerkit_whole_study_curve <- function(x, ...) {
  cat("Rough power curve (", x$criterion, "), ", x$provenance$nrep, " simulated studies at each n:\n", sep = "")
  for (i in seq_len(nrow(x$curve))) {
    cat(sprintf("  n = %s: %.0f%% (95%% interval %.0f%% to %.0f%%)\n", x$curve$n[i],
      100 * x$curve$power[i], 100 * x$curve$lower[i], 100 * x$curve$upper[i]))
  }
  invisible(x)
}
