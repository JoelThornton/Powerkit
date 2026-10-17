# Results for the end points whose calculation takes seconds (forms.yaml,
# `calculates`). The app never computes power itself: it passes the checked
# spec to the engine's run_spec() and shows what comes back, with the
# engine's own exports (export_script(), export_citations()).
#
# How results are worded, how N is rounded and whether a power curve is
# shown are undecided (settings result_wording, n_rounding and power_curve
# in tree.yaml; judgement-calls.md). The wording below is a draft.

form_calculates <- function(forms, ep_id) ep_id %in% unlist(forms$calculates)

# End points whose calculation takes long enough to run in the background,
# with a progress bar and a Cancel button (forms.yaml, `background`: the
# usual run time in seconds for each goal).
runs_in_background <- function(forms, ep_id) ep_id %in% names(forms$background)
usual_seconds <- function(forms, ep_id, goal) forms$background[[ep_id]][[goal]] %||% NA_real_

# Run the engine on a checked spec. The input screen puts the seed in the
# spec (a fixed default the user can change; forms.yaml, default_seed); a
# spec without one gets `seed`, so the same answers always give the same
# result and the result (and its script) can be reproduced. Returns
# list(status = "ok", spec, result, notes) or list(status = "error",
# message) with a plain-English message.
run_calculation <- function(spec, run = engine_function("run_spec"), seed = 1L) {
  if (is.null(run)) {
    return(list(status = "error", message = "The calculation needs powerkit's engine, which isn't installed where this prototype is running."))
  }
  if (is.null(spec$options$seed)) {
    spec$options$seed <- as.integer(seed)
  }
  notes <- character()
  result <- tryCatch(
    withCallingHandlers(run(spec), warning = function(w) {
      notes <<- c(notes, conditionMessage(w))
      invokeRestart("muffleWarning")
    }),
    error = function(e) {
      message <- if (inherits(e, "powerkit_error")) conditionMessage(e) else "powerkit's engine stopped unexpectedly. Please report this, with the answers you copied."
      structure(list(message = message), class = "calc_error")
    }
  )
  if (inherits(result, "calc_error")) return(list(status = "error", message = result$message))
  list(status = "ok", spec = spec, result = result, notes = unique(notes))
}

# --- Running in the background ----------------------------------------------------

# The background R process's job: load the engine (the installed package, or
# the source in engine_dir, as engine_function() does) and run
# run_calculation(), passed in, so it's the same code as the in-session run.
background_worker <- function(spec, seed, engine_dir, cores, run_calculation) {
  options(powerkit.cores = cores)
  run <- if (requireNamespace("powerkit", quietly = TRUE)) {
    getExportedValue("powerkit", "run_spec")
  } else {
    suppressMessages(pkgload::load_all(engine_dir, export_all = FALSE, helpers = FALSE, quiet = TRUE, attach = FALSE))
    get("run_spec", envir = asNamespace("powerkit"))
  }
  run_calculation(spec, run, seed)
}

# Start a calculation in a separate R process (callr), so the app stays
# responsive and the run can be cancelled. Returns the process.
start_background_calculation <- function(spec, seed = 1L,
                                         engine_dir = file.path(routing_root(), "..", "..", "engine")) {
  calc_fun <- run_calculation
  environment(calc_fun) <- baseenv()
  callr::r_bg(
    background_worker,
    args = list(spec = spec, seed = seed, engine_dir = normalizePath(engine_dir, mustWork = FALSE),
                cores = getOption("powerkit.cores"), run_calculation = calc_fun),
    supervise = TRUE
  )
}

# The finished process's value: run_calculation()'s list, or a plain-English
# error if the process itself failed (e.g. the engine couldn't be loaded).
collect_background_calculation <- function(job) {
  tryCatch(job$get_result(), error = function(e) {
    list(status = "error", message = "powerkit's engine stopped unexpectedly. Please report this, with the answers you copied.")
  })
}

# Estimated progress from the time so far and the usual run time: the
# backends don't report their own progress, so the bar is an estimate and
# says so. It stops at 95% until the run finishes.
progress_estimate <- function(elapsed, usual) {
  if (is.na(usual) || usual <= 0) return(NA_real_)
  min(elapsed / usual, 0.95)
}

progress_text <- function(elapsed, usual) {
  so_far <- sprintf("Running for %d seconds.", as.integer(round(elapsed)))
  if (is.na(usual)) return(so_far)
  if (elapsed > usual) {
    return(sprintf("%s This is taking longer than the usual %s seconds; larger samples take longer.", so_far, whole(usual)))
  }
  sprintf("%s This usually takes about %s seconds.", so_far, whole(usual))
}

# --- Numbers in words --------------------------------------------------------------

percent <- function(p) sprintf("%.0f%%", 100 * p)
alpha_text <- function(a) sub("^0", "", format(a, nsmall = 2))
whole <- function(n) format(n, big.mark = ",", scientific = FALSE, trim = TRUE)

# Group sizes for a total n, for designs with separate groups; NULL for
# designs where everyone is in one group (one sample, paired, correlation,
# chi-square). Follows the engine's split (powerkit's spower_inputs()).
group_sizes <- function(spec, n) {
  switch(
    spec$template,
    independent_t = ,
    two_proportions = {
      ratio <- spec$options$allocation_ratio %||% 1
      n1 <- round(n / (1 + ratio))
      c(n1, n - n1)
    },
    "2x2_between" = rep(n / 4, 4),
    "2x2_mixed" = rep(n / 2, 2),
    NULL
  )
}

group_text <- function(spec, n) {
  sizes <- group_sizes(spec, n)
  if (is.null(sizes)) return("")
  unit <- if (identical(spec$template, "2x2_between")) "per cell" else "per group"
  if (length(unique(sizes)) == 1) {
    sprintf(" (%s %s)", whole(sizes[1]), unit)
  } else {
    sprintf(" (%s in group 1 and %s in group 2)", whole(sizes[1]), whole(sizes[2]))
  }
}

test_text <- function(spec) {
  alt <- spec$target_test$alternative %||% "two_sided"
  side <- switch(alt, two_sided = "a two-sided test", greater = "a one-sided test (effect positive)", less = "a one-sided test (effect negative)")
  sprintf("%s at alpha = %s", side, alpha_text(spec$target_test$alpha))
}

simulated <- function(result) identical(result$provenance$method, "simulation")

# How an exact result was computed, for the detail sentence.
exact_source <- function(result) {
  if (identical(result$provenance$backend, "pwr")) {
    sprintf("pwr's formula, %s(), no simulation", result$provenance$backend_function)
  } else {
    "Superpower's exact dataset, no repeated simulation"
  }
}

# Under a simulated result (judgement-calls.md B15).
simulation_note <- function(result) {
  sprintf(
    "Calculated by simulation with %s replications; a different seed can shift the result slightly.",
    whole(result$provenance$nrep)
  )
}

# The headline and supporting sentences for a result (draft wording; setting
# result_wording).
result_sentences <- function(spec, result) {
  test <- test_text(spec)
  switch(
    result$goal_type,
    sample_size = {
      est <- result$n_required
      c(
        headline = sprintf(
          "You need %s participants in total%s for %s power to detect the effect you entered, with %s.",
          whole(est$n), group_text(spec, est$n), percent(spec$goal$power), test
        ),
        detail = if (simulated(result)) {
          sprintf(
            "This N comes from simulation (%s replications per sample size); the 95%% interval for the required N is %s to %s.",
            whole(result$provenance$nrep), whole(est$lower), whole(est$upper)
          )
        } else {
          sprintf("This N is calculated for the population you entered (%s).", exact_source(result))
        }
      )
    },
    power = {
      row <- result$curve[1, ]
      c(
        headline = sprintf(
          "With %s participants in total%s, the study has %s power: if the true effect is the one you entered, about %d in 100 studies like this would give a significant result with %s.",
          whole(row$n), group_text(spec, row$n), percent(row$power), round(100 * row$power), test
        ),
        detail = if (simulated(result)) {
          sprintf(
            "Estimated by simulation from %s replications (Monte Carlo standard error %.1f percentage points).",
            whole(result$provenance$nrep), 100 * row$mcse
          )
        } else {
          sprintf("This power is calculated for the population you entered (%s).", exact_source(result))
        }
      )
    },
    sensitivity = {
      s <- result$sensitivity
      c(
        headline = sprintf(
          "With %s participants in total%s, the smallest effect you could detect with %s power, with %s, is %s (Cohen's f = %.3f). The effect: %s.",
          whole(spec$goal$n), group_text(spec, spec$goal$n), percent(spec$goal$power), test,
          format(signif(s$effect, 3)), s$cohen_f, s$effect_description
        ),
        detail = "The pattern of means you entered keeps its shape and is scaled until the effect reaches the target power (exact, Superpower)."
      )
    }
  )
}

# The power the reported N actually gives (judgement-calls.md G5; the
# maintainer's decision of 17 October 2026). Rounding up to whole people,
# and to equal groups, puts it at or a little above the target. Exact
# results only: the engine's curve holds the exact power at the reported
# N. A simulated N comes from a fitted curve, with no simulation at
# exactly that N, so nothing is shown for it.
actual_power_sentence <- function(spec, result) {
  if (!identical(result$goal_type, "sample_size") || simulated(result)) return(NULL)
  n <- result$n_required$n
  at_n <- result$curve$power[result$curve$n == n]
  if (length(at_n) != 1) return(NULL)
  sizes <- group_sizes(spec, n)
  who <- if (is.null(sizes)) {
    sprintf("With %s participants", whole(n))
  } else if (length(unique(sizes)) == 1) {
    unit <- if (identical(spec$template, "2x2_between")) "per cell" else "per group"
    sprintf("With %s %s", whole(sizes[1]), unit)
  } else {
    sprintf("With %s in group 1 and %s in group 2", whole(sizes[1]), whole(sizes[2]))
  }
  sprintf("%s, power is %.1f%%.", who, 100 * at_n)
}

# Planned power, not "observed power" (setting result_wording).
not_observed_power <- "This is planned power for the effect you entered, before the study is run. It is not \"observed power\" calculated from a finished study's results, which says nothing beyond the study's p-value."

# --- The result screen -------------------------------------------------------------

calculating_ui <- function() {
  div(class = "result-panel calculating", role = "status", tabindex = "-1",
    p(tags$strong("Calculating with powerkit's engine…"), " This takes a few seconds."))
}

# For a background run: an estimated progress bar, the time so far and a
# Cancel button. The bar and time are updated in place (calc_progress
# message in app.R); only the first line is announced to screen readers.
calculating_background_ui <- function(usual) {
  div(class = "result-panel calculating calc-progress", tabindex = "-1",
    p(role = "status", tags$strong("Calculating with powerkit's engine…"),
      if (!is.na(usual)) sprintf(" This usually takes about %s seconds.", whole(usual))),
    tags$label(`for` = "calc-progress-bar", class = "small", "Estimated progress (from the usual run time; the backend doesn't report its own)"),
    tags$progress(id = "calc-progress-bar", max = "100", value = "0", style = "width: 100%; height: 1.25rem;"),
    p(id = "calc-progress-text", class = "small", progress_text(0, usual)),
    actionButton("calc_cancel", "Cancel", class = "btn btn-outline-danger"))
}

cancelled_ui <- function() {
  div(class = "form-problems", role = "status", tabindex = "-1",
    h3(class = "h5", "Calculation cancelled"),
    p("Nothing was calculated. Change your answers if you like, and choose \u201cCheck my answers\u201d to run it again."))
}

# The values the user entered, as "label: value" lines (fields that apply
# only).
entered_lines <- function(fields, values) {
  out <- character()
  for (f in fields) {
    v <- values[[f$id]]
    if (blank(v) || !field_applies(f, values)) next
    shown <- if (!is.null(f$choices) && !is.null(f$choices[[as.character(v)]])) f$choices[[as.character(v)]] else gsub("\n", " / ", as.character(v))
    out <- c(out, sprintf("%s: %s", f$label, shown))
  }
  out
}

departures_for <- function(forms, ep_id, spec) {
  keys <- unlist(forms$forms[[ep_id]]$departures)
  # Departure 1 is about the interaction's required N only.
  if (!identical(spec$target_test$effect, "interaction")) keys <- setdiff(keys, "1")
  # Departures 9 and 10 (pwr's formula for basic tests; Fisher's z for a
  # correlation) apply only when the formula was used, not to simulation
  # or Welch's t-test.
  if (identical(spec$options$method, "simulation") || identical(spec$target_test$method, "welch_t")) keys <- setdiff(keys, c("9", "10"))
  vapply(keys, function(k) forms$departures[[k]], character(1))
}

validation_ui <- function(ep) {
  if (identical(ep$status, "runs_validated")) {
    div(class = "status status-runs", tags$strong("Validated. "), ep$validation$note)
  } else {
    div(class = "status status-in-progress", tags$strong("Validation in progress. "), ep$validation$note %||% "")
  }
}

provenance_lines <- function(result) {
  p <- result$provenance
  c(
    sprintf("Backend: %s %s, %s", p$backend, p$packages[[p$backend]], p$backend_function),
    sprintf("Method: %s", if (p$method == "simulation") sprintf("simulation, %s replications", whole(p$nrep)) else "exact"),
    sprintf("Seed: %s", p$seed),
    sprintf("Spec hash: %s", p$spec_hash),
    sprintf("R: %s", p$r_version),
    sprintf("Packages: %s", paste(sprintf("%s %s", names(p$packages), p$packages), collapse = ", ")),
    sprintf("Check run (does the backend reproduce your population?): %s", if (all(result$check_run$ok)) "passed" else "failed"),
    sprintf("Run time: %.1f seconds", p$run_time_seconds)
  )
}

# The whole result panel. `calc` is run_calculation()'s value.
result_panel_ui <- function(tree, forms, ep_id, fields, values, calc, check_advice = character()) {
  if (!identical(calc$status, "ok")) {
    return(div(class = "form-problems", role = "alert", tabindex = "-1",
      h3(class = "h5", "The calculation didn't finish"), p(calc$message)))
  }
  ep <- tree$endpoints[[ep_id]]
  spec <- calc$spec
  result <- calc$result
  words <- result_sentences(spec, result)
  p_ <- result$provenance
  departures <- departures_for(forms, ep_id, spec)
  notes <- unique(c(check_advice, calc$notes))
  div(
    class = "result-panel", role = "status", tabindex = "-1",
    h3(class = "h4", "Your result"),
    p(class = "result-headline lead", words[["headline"]]),
    if (!is.null(actual <- actual_power_sentence(spec, result))) p(class = "result-actual-power", actual),
    p(class = "result-detail", words[["detail"]]),
    if (simulated(result)) p(class = "result-simulation", simulation_note(result)),
    p(class = "result-seed small",
      sprintf("Seed: %s. ", p_$seed),
      if (simulated(result)) "You can change it under \u201cRandom seed\u201d above and calculate again." else
        "Nothing was simulated, so the seed doesn't change this result in practice."),
    p(class = "result-observed small", not_observed_power),
    validation_ui(ep),
    p(class = "result-credit",
      "Calculated by the R package ", tags$strong(p_$backend), sprintf(" (version %s), with %s. ", p_$packages[[p_$backend]], p_$backend_function),
      if (identical(p_$backend, "pwr")) "powerkit built the call from your answers and checked the effect size it passes. " else
        "powerkit built the call from your answers and checked that it reproduces the population you entered. ",
      "Cite the package: see Citations below."),
    h4(class = "h6", "What this result used"),
    tags$ul(class = "result-inputs", lapply(entered_lines(fields, values), tags$li)),
    if (length(departures)) tagList(
      h4(class = "h6", "Where powerkit differs from the tool's defaults"),
      tags$ul(class = "result-departures", lapply(unname(departures), tags$li))
    ),
    if (length(notes)) tagList(h4(class = "h6", "Notes"), tags$ul(lapply(notes, tags$li))),
    div(class = "nav-buttons",
      downloadButton("download_script", "Download R script", class = "btn btn-outline-primary"),
      downloadButton("download_citations", "Citations", class = "btn btn-outline-primary")),
    p(class = "small", "The R script reproduces this result with ", p_$backend, " alone (powerkit isn't needed). Citations lists the package's own citation(), its method paper and the software used."),
    div(class = "engine-placeholder methods-placeholder",
      tags$strong("Methods paragraph: "), "not written yet (a placeholder until build phase 4 is finished)."),
    placeholders_at(tree, "result"),
    tags$details(tags$summary("Reproducibility record"), tags$ul(lapply(provenance_lines(result), tags$li))),
    tags$details(tags$summary("The design spec that was run (JSON)"), tags$pre(class = "spec-json", spec_json(spec)))
  )
}
