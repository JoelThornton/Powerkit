# Property checks for one example design: checks every result should
# pass whatever the design, with no published value needed.
#
#   1. The example runs, and its result records the spec hash, seed,
#      backend, R version and package versions; the backend's check that
#      it reproduces the population entered passes.
#   2. For a sample-size goal, power at the recommended n reaches the
#      target, and (by formula) one fewer doesn't.
#   3. Power at 2n is at least power at n (within simulation error).
#   4. The same seed gives the same power and the same spec hash.
#   5. With the tested effect set to zero, power is about alpha (no more
#      than alpha plus three simulation standard errors).
#
# Run from the repository root, with the engine installed:
#   Rscript scripts/release-checks/property-check-one.R <spec.json> <out.json> [nrep]
# nrep 0 leaves each spec's replications as written. property-checks.R
# runs it on every spec in engine/inst/specs and summarises the results.
suppressPackageStartupMessages({
  library(powerkit)
  library(jsonlite)
})
args <- commandArgs(TRUE)
spec_path <- args[1]
out_path <- args[2]
nrep <- if (length(args) >= 3) as.integer(args[3]) else 200L

base <- fromJSON(spec_path, simplifyVector = FALSE)
name <- sub("\\.json$", "", basename(spec_path))
out <- list(spec = name, template = base$template, goal = base$goal$type,
            method = base$target_test$method %||% NA)

set_nrep <- function(s) {
  if (is.null(s$options)) s$options <- list()
  # Fewer replications than a report needs: these checks allow for the
  # simulation error. 0 leaves the spec's own number.
  if (nrep > 0) s$options$nrep <- nrep
  if (is.null(s$options$seed)) s$options$seed <- 12345L
  s
}

run <- function(s, label) {
  t0 <- Sys.time()
  warn <- character()
  res <- tryCatch(
    withCallingHandlers(run_spec(s), warning = function(w) {
      warn <<- c(warn, conditionMessage(w)); invokeRestart("muffleWarning")
    }),
    error = function(e) structure(list(msg = conditionMessage(e), cls = class(e)), class = "err")
  )
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  out$timings[[label]] <<- round(secs, 1)
  if (length(warn)) out$warnings[[label]] <<- unique(warn)
  res
}

power_of <- function(res) {
  if (!is.null(res$curve) && nrow(res$curve) >= 1) return(res$curve$power[1])
  NA_real_
}
mcse_of <- function(res) {
  if (is.null(res$curve)) return(0)
  if (!is.null(res$curve$mcse)) return(res$curve$mcse[1])
  0
}

# Zero the tested effect, where we know how. Returns NULL if unknown.
null_spec <- function(s) {
  p <- s$population
  tt <- s$template
  flat_mean <- function(x) mean(unlist(x))
  set_all <- function(x, v) rapply(x, function(z) v, how = "replace")
  done <- TRUE
  if (!is.null(p$means) && is.null(p$mu0)) {
    p$means <- set_all(p$means, flat_mean(p$means))
  } else if (!is.null(p$means) && !is.null(p$mu0)) {
    p$means <- p$mu0
  } else if (tt %in% c("independent_t", "one_sample_t", "cluster_randomised",
                       "group_treatment", "multisite", "three_level") && !is.null(p$d)) {
    p$d <- 0
  } else if (!is.null(p$dz)) {
    p$dz <- 0
  } else if (tt == "correlation") {
    p$r <- 0
  } else if (!is.null(p$p1) && !is.null(p$p2) && !grepl("noninf|tost", tt)) {
    p$p2 <- p$p1
  } else if (tt == "one_proportion") {
    p$p <- p$p0
  } else if (tt == "one_variance") {
    p$var <- p$var0
  } else if (tt == "two_variances" || tt == "paired_variances") {
    p$var2 <- p$var1
  } else if (tt == "two_correlations") {
    p$r2 <- p$r1
  } else if (tt == "overlapping_correlations") {
    p$r_X_Z <- p$r_X_Y
  } else if (tt == "nonoverlapping_correlations") {
    p$r_X2_Y2 <- p$r_X1_Y1
  } else if (!is.null(p$ncp)) {
    p$ncp <- 0
  } else if (!is.null(p$odds_ratio) && is.null(p$probabilities)) {
    p$odds_ratio <- 1
  } else if (!is.null(p$odds_ratio_xw)) {
    p$odds_ratio_xw <- 1
  } else if (!is.null(p$rate_ratio)) {
    p$rate_ratio <- 1
  } else if (!is.null(p$hazard_ratio)) {
    p$hazard_ratio <- 1
  } else if (!is.null(p$r_XW_Y) && tt == "two_way") {
    p$r_XW_Y <- 0
  } else if (!is.null(p$b_XWZ)) {
    p$b_XWZ <- 0
  } else if (tt == "two_level" && s$target_test$effect == "cross_level_interaction") {
    p$b_XW <- 0
  } else if (tt == "r2_increase") {
    p$r2_full <- p$r2_reduced
  } else if (tt == "mean_effect" || tt == "dependent_effects") {
    p$effect <- 0
  } else if (tt == "meta_regression") {
    p$slope <- 0
  } else if (tt == "growth_curve") {
    p$slope_difference <- 0
  } else if (tt == "crossed_two_condition") {
    p$difference <- 0
  } else if (tt == "item_predictor") {
    p$slope <- 0
  } else if (tt == "its") {
    eff <- s$target_test$effect %||% "level_change"
    if (!is.null(p[[eff]])) p[[eff]] <- 0 else { p$level_change <- 0; p$slope_change <- 0 }
  } else if (tt == "riclpm") {
    p[[s$target_test$effect]] <- 0
  } else if (tt == "apim") {
    p[[s$target_test$effect]] <- 0
  } else if (tt == "dprime") {
    p$dprime <- rep(p$dprime[[1]], length(p$dprime))
  } else if (!is.null(p$paths)) {
    # indirect effect: zero the first path only (power should be <= alpha)
    nm <- names(p$paths)[1]
    p$paths[[nm]] <- 0
  } else if (tt == "chi_square_gof") {
    k <- length(p$probabilities)
    p$probabilities <- as.list(rep(1 / k, k))
  } else if (tt == "chi_square_independence" || tt == "factorial" || tt == "multinomial") {
    done <- FALSE
  } else {
    done <- FALSE
  }
  if (!done) return(NULL)
  s$population <- p
  s
}

as_power <- function(s, n) {
  s$goal <- list(type = "power", n = as.integer(n))
  s
}

base <- set_nrep(base)
is_precision <- identical(base$goal$type, "precision")

# 1. The example as written ------------------------------------------------
r0 <- run(base, "example")
if (inherits(r0, "err")) {
  out$example_error <- r0$msg
} else {
  pv <- r0$provenance
  miss <- c("spec_hash", "seed", "backend", "r_version", "packages")[
    !vapply(c("spec_hash", "seed", "backend", "r_version", "packages"),
            function(k) !is.null(pv[[k]]) && length(pv[[k]]) > 0 && !all(is.na(pv[[k]])), logical(1))]
  if (length(miss)) out$provenance_missing <- miss
  out$backend <- pv$backend
  out$prov_method <- pv$method
  if (!is.null(r0$check_run) && is.data.frame(r0$check_run) && "ok" %in% names(r0$check_run) &&
      any(!r0$check_run$ok)) {
    out$check_run_failed <- r0$check_run[!r0$check_run$ok, , drop = FALSE]
  }
}

if (!inherits(r0, "err") && !is_precision) {
  sim <- identical(r0$provenance$method, "simulation")
  out$simulation <- sim
  alpha <- base$target_test$alpha %||% 0.05
  # n to test at
  n_at <- if (identical(base$goal$type, "sample_size")) r0$n_required$n else base$goal$n %||% NA
  if (identical(base$goal$type, "sensitivity")) n_at <- base$goal$n
  out$n_at <- n_at

  # 2. Consistency: power at the recommended n --------------------------------
  if (identical(base$goal$type, "sample_size") && !is.null(n_at) && !is.na(n_at)) {
    target <- base$goal$power
    rp <- run(as_power(base, n_at), "power_at_n")
    if (inherits(rp, "err")) {
      out$consistency_error <- rp$msg
    } else {
      pw <- power_of(rp); se <- mcse_of(rp)
      out$consistency <- list(target = target, n = n_at, power = pw, mcse = se)
      if (!is.na(pw) && pw < target - max(3 * se, 1e-6)) out$flags$consistency <- TRUE
      # n one step below should be below target for exact methods
      if (!sim && n_at > 4) {
        rb <- run(as_power(base, n_at - 1), "power_at_n_minus_1")
        if (!inherits(rb, "err")) {
          out$consistency$power_n_minus_1 <- power_of(rb)
          if (!is.na(power_of(rb)) && power_of(rb) >= target) out$flags$not_smallest_n <- TRUE
        } else out$consistency$n_minus_1_error <- rb$msg
      }
    }
  }

  # 3. Monotone in n (power at n and 2n) ---------------------------------------
  if (!is.na(n_at)) {
    a <- run(as_power(base, n_at), "power_n")
    b <- run(as_power(base, 2 * n_at), "power_2n")
    if (!inherits(a, "err") && !inherits(b, "err")) {
      out$monotone <- list(p_n = power_of(a), p_2n = power_of(b))
      tol <- if (sim) 3 * sqrt(mcse_of(a)^2 + mcse_of(b)^2) else 1e-8
      if (!is.na(power_of(a)) && !is.na(power_of(b)) && power_of(b) < power_of(a) - tol) {
        out$flags$non_monotone_n <- TRUE
      }
      # 4. Same seed, same answer
      a2 <- run(as_power(base, n_at), "power_n_repeat")
      if (!inherits(a2, "err") && !identical(power_of(a), power_of(a2))) {
        out$flags$not_reproducible <- c(power_of(a), power_of(a2))
      }
      if (!inherits(a2, "err") && !identical(a$provenance$spec_hash, a2$provenance$spec_hash)) {
        out$flags$hash_changes <- TRUE
      }
    } else {
      out$monotone_error <- c(if (inherits(a, "err")) a$msg, if (inherits(b, "err")) b$msg)
    }

    # 5. No effect gives about alpha ------------------------------------------
    ns <- null_spec(as_power(base, n_at))
    if (is.null(ns)) {
      out$null <- "not_tested"
    } else {
      rn <- run(ns, "null")
      if (inherits(rn, "err")) {
        out$null <- list(error = rn$msg)
      } else {
        pw <- power_of(rn); se <- if (sim) sqrt(alpha * (1 - alpha) / nrep) else 0
        out$null <- list(power = pw, alpha = alpha, mcse = se)
        if (!is.na(pw) && pw > alpha + max(3 * se, 0.005)) out$flags$null_above_alpha <- TRUE
        if (!is.na(pw) && pw < alpha / 2 - 3 * se && !grepl("monte_carlo|bic|congruence", out$method)) {
          out$flags$null_well_below_alpha <- TRUE
        }
      }
    }
  }
}

writeLines(toJSON(out, auto_unbox = TRUE, null = "null", na = "null", digits = 6, pretty = TRUE,
                  force = TRUE), out_path)
