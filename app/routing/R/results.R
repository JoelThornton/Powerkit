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

# --- Sharing the server ---------------------------------------------------------

# Everyone using the online app shares one server, and each background
# calculation is a separate R process with its own core and memory. A room
# of people starting long runs at once could use up the server's memory
# and stop the app for everyone, so at most background_limit() run at
# once, across all visitors (forms.yaml, `background_limit`, or the
# environment variable POWERKIT_BACKGROUND_LIMIT). The registry lives in
# the app's one R process, so every visitor's session sees it.
background_registry <- new.env()
background_registry$processes <- list()

background_limit <- function(forms) {
  from_env <- suppressWarnings(as.integer(Sys.getenv("POWERKIT_BACKGROUND_LIMIT")))
  if (!is.na(from_env) && from_env > 0) return(from_env)
  as.integer(forms$background_limit %||% 2L)
}

# How many background calculations are running now (finished ones are
# dropped from the registry).
background_running <- function() {
  alive <- Filter(function(p) p$is_alive(), background_registry$processes)
  background_registry$processes <- alive
  length(alive)
}

register_background <- function(process) {
  background_registry$processes <- c(background_registry$processes, list(process))
  process
}

# Shown instead of starting a run when the limit is reached.
busy_ui <- function() {
  div(class = "form-problems", role = "status", tabindex = "-1",
    h3(class = "h5", "powerkit is busy just now"),
    p("Other people's long calculations are using the server, so this one can't start yet. ",
      "Please choose \u201cCheck my answers\u201d again in a minute or two. ",
      "Quick calculations, such as t-tests, correlations and ANOVA, still work as usual."))
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
  so_far <- if (elapsed < 120) {
    secs <- as.integer(round(elapsed))
    sprintf("Running for %d second%s.", secs, if (secs == 1L) "" else "s")
  } else {
    sprintf("Running for %d minutes.", as.integer(floor(elapsed / 60)))
  }
  if (is.na(usual)) return(so_far)
  usual_words <- if (usual < 120) sprintf("%s seconds", whole(usual)) else sprintf("%s minutes", whole(round(usual / 60)))
  if (elapsed > usual) {
    return(sprintf("%s This is taking longer than the usual %s; larger samples take longer.", so_far, usual_words))
  }
  sprintf("%s This usually takes about %s.", so_far, usual_words)
}

# --- Numbers in words --------------------------------------------------------------

percent <- function(p) sprintf("%.0f%%", 100 * p)
alpha_text <- function(a) sub("^0", "", format(a, nsmall = 2))
whole <- function(n) format(n, big.mark = ",", scientific = FALSE, trim = TRUE)

# Group sizes for a total n, for designs with separate groups; NULL for
# designs where everyone is in one group (one sample, paired, correlation,
# chi-square, goodness of fit, one proportion, McNemar, regression). Follows the engine's split (powerkit's spower_inputs()).
group_sizes <- function(spec, n) {
  switch(
    spec$template,
    independent_t = ,
    two_proportions = ,
    two_correlations = {
      ratio <- spec$options$allocation_ratio %||% 1
      n1 <- round(n / (1 + ratio))
      c(n1, n - n1)
    },
    "2x2_between" = rep(n / 4, 4),
    "2x2_mixed" = rep(n / 2, 2),
    oneway_between = ,
    oneway_ancova = {
      k <- length(spec$variables$A$levels)
      rep(n / k, k)
    },
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

# Generic tests (E50): which statistic, with its degrees of freedom. Only t
# and z have a direction.
generic_test_text <- function(spec) {
  pop <- spec$population
  stat <- switch(
    spec$template,
    t = sprintf("a t test with %s degrees of freedom", format(pop$df)),
    f = sprintf("an F test with %s and %s degrees of freedom", format(pop$df1), format(pop$df2)),
    chi_square = sprintf("a chi-square test with %s degrees of freedom", format(pop$df)),
    z = "a z test (standard deviation 1)"
  )
  if (spec$template %in% c("t", "z")) {
    side <- switch(spec$target_test$alternative %||% "two_sided", two_sided = "two-sided", greater = "one-sided, effect positive", less = "one-sided, effect negative")
    sprintf("%s (%s) at alpha = %s", stat, side, alpha_text(spec$target_test$alpha))
  } else {
    sprintf("%s at alpha = %s", stat, alpha_text(spec$target_test$alpha))
  }
}

# Generic tests have no sample size: the noncentrality already reflects it.
generic_sentences <- function(spec, result) {
  test <- generic_test_text(spec)
  no_n <- "There is no sample size here: the noncentrality parameter already reflects it."
  if (identical(result$goal_type, "power")) {
    power <- result$curve$power[1]
    c(
      headline = sprintf(
        "With a noncentrality parameter of %s, %s has %s power: if the true effect is the one this noncentrality stands for, about %d in 100 studies like this would get a significant result.",
        format(spec$population$ncp), test, percent(power), round(100 * power)
      ),
      detail = sprintf("%s Calculated by formula (%s).", no_n, exact_source(result))
    )
  } else {
    c(
      headline = sprintf(
        "For %s power with %s, the noncentrality parameter needs to be at least %s.",
        percent(spec$goal$power), test, format(round(result$sensitivity$effect, 3), nsmall = 2)
      ),
      detail = sprintf("%s Worked out by formula (%s), which finds the noncentrality directly.", no_n, exact_source(result))
    )
  }
}

# How an exact result was computed, for the detail sentence.
exact_source <- function(result) {
  if (identical(result$provenance$backend, "stats")) {
    sprintf("base R's formula, %s(), no simulation", result$provenance$backend_function)
  } else if (result$provenance$backend %in% c("pwr", "pwrss")) {
    sprintf("%s's formula, %s(), no simulation", result$provenance$backend, result$provenance$backend_function)
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
  if (identical(spec$design, "generic_test")) return(generic_sentences(spec, result))
  out <- goal_sentences(spec, result)
  units <- units_sentence(result)
  if (!is.null(units)) out[["detail"]] <- paste(out[["detail"]], units)
  out
}

# With the effect given in the outcome's own units: the standardised effect
# the engine worked out from them, and for the smallest detectable effect,
# that effect as a difference in the outcome's units (both from the
# engine's result).
units_sentence <- function(result) {
  u <- result$effect_from_units
  if (is.null(u)) return(NULL)
  round3 <- function(x) format(round(x, 3), nsmall = 2)
  if (!is.null(u$smallest_difference)) {
    return(sprintf("In your outcome's own units, that is a difference of %s (%s × %s, %s).",
      round3(u$smallest_difference), round3(result$sensitivity$effect), format(signif(u$sd, 4)), u$sd_name))
  }
  sprintf("From the means and SD you entered, powerkit worked out %s = %s: a difference of %s divided by %s (%s).",
    u$name, round3(u$value), format(signif(u$difference, 4)), u$sd_name, format(signif(u$sd, 4)))
}

goal_sentences <- function(spec, result) {
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
        },
        reading = plain_reading(spec$goal$power)
      )
    },
    power = {
      row <- result$curve[1, ]
      c(
        headline = sprintf(
          "With %s participants in total%s, the study has %s power: if the true effect is the one you entered, about %d in 100 studies like this would get a significant result with %s.",
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
      if (is.null(s$cohen_f)) {
        # Basic tests (pwr): the effect is solved for directly.
        name <- switch(s$effect_name %||% "", d = "d", d_z = "d_z", r = "r", w = "w", p2 = "group 2's proportion",
          r_XW_Y = "the correlation of the interaction with Y", "the effect")
        c(
          headline = sprintf(
            "With %s participants in total%s, the smallest effect you could detect with %s power, with %s, is %s = %s. The effect: %s.",
            whole(spec$goal$n), group_text(spec, spec$goal$n), percent(spec$goal$power), test,
            name, format(round(s$effect, 3), nsmall = 2), s$effect_description
          ),
          detail = if (isTRUE(s$approximation)) {
            sprintf(
              "Smaller true effects than this would give a significant result less often than %s of the time. Worked out by InteractionPoweR's fixed-model formula (%s(), no simulation), which is quick; sample size and power for this design are simulated. The formula gives slightly higher power than simulation, so the smallest effect you could detect may be slightly larger than this (see the known difference below).",
              percent(spec$goal$power), result$provenance$backend_function
            )
          } else {
            sprintf(
              "Smaller true effects than this would give a significant result less often than %s of the time. Worked out by formula (%s), which finds the effect directly.",
              percent(spec$goal$power), exact_source(result)
            )
          }
        )
      } else {
        c(
          headline = sprintf(
            "With %s participants in total%s, the smallest effect you could detect with %s power, with %s, is %s (Cohen's f = %.3f). The effect: %s.",
            whole(spec$goal$n), group_text(spec, spec$goal$n), percent(spec$goal$power), test,
            format(signif(s$effect, 3)), s$cohen_f, s$effect_description
          ),
          detail = "The pattern of means you entered keeps its shape and is scaled until the effect reaches the target power (exact, Superpower)."
        )
      }
    }
  )
}

# The plain reading of a target power (the new design, 18 October 2026):
# it keeps the condition, and says what power is a chance of.
plain_reading <- function(power) {
  sprintf(
    "In plain words: if the true effect is the one you entered, about %d in 10 studies like this would get a significant result. If the true effect is smaller, fewer would.",
    round(10 * power)
  )
}

# What power can't tell you, under every result.
power_limits <- "Power is only about how often a study like this would get a significant result. It can't tell you whether your measures are valid and reliable, whether the design tests your theory, or whether the effect is worth caring about."

# Where the effect size comes from, in the user's own words, beside the
# number.
reasoning_line <- function(values) {
  if (blank(values$just_type)) return(NULL)
  types <- list(smallest_effect_of_interest = "the smallest effect that would matter", meta_analysis = "a meta-analysis",
                prior_study = "a previous study", pilot_study = "a pilot study",
                own_study_result = "the finished study's own result (observed power)", none = "none (you said you can't justify an effect size)")
  label <- types[[values$just_type]] %||% values$just_type
  if (blank(values$just_source)) return(sprintf("Effect size source: %s.", label))
  sprintf("Effect size source: %s. Your reasoning: \u201c%s\u201d", label, trimws(values$just_source))
}

# "Does this still apply?" (the new design, 18 October 2026): if the effect
# size changes after the reasoning was written, the reasoning is kept but
# flagged until the user confirms it or edits it. app.R keeps the effect
# values the reasoning was written for; these helpers compare and word them.
effect_snapshot <- function(fields, values) {
  ids <- vapply(Filter(function(f) (isTRUE(f$effect) || isTRUE(f$in_effect_text)) && field_applies(f, values), fields), `[[`, "", "id")
  vapply(ids, function(id) trimws(paste(as.character(values[[id]] %||% ""), collapse = ", ")), character(1))
}

# Updates the record of which effect values the reasoning was written for,
# and says whether the reasoning is stale. `record` is NULL or
# list(endpoint, source, effect); returns list(record, stale, was).
source_check <- function(record, endpoint, fields, values) {
  src <- trimws(values$just_source %||% "")
  now <- effect_snapshot(fields, values)
  if (!nzchar(src)) return(list(record = NULL, stale = FALSE))
  fresh <- list(endpoint = endpoint, source = src, effect = now)
  if (is.null(record) || !identical(record$endpoint, endpoint) || !identical(record$source, src)) {
    return(list(record = fresh, stale = FALSE))
  }
  if (identical(record$effect, now)) return(list(record = record, stale = FALSE))
  was <- writeup_effect(fields, modifyList(values, as.list(record$effect)))
  list(record = record, stale = TRUE, was = was)
}

source_stale_ui <- function(fields, values) {
  if (!isTRUE(values$source_stale)) return(NULL)
  now <- writeup_effect(fields, values)
  div(class = "alert alert-warning source-stale", role = "alert",
    p(tags$strong("Does your reasoning still apply?"), " You changed the effect size after writing it",
      if (!blank(values$source_was) && !blank(now)) sprintf(" (it was %s; it is now %s)", values$source_was, now), ". ",
      "Your reasoning is kept as you wrote it. Until you confirm it or edit it, the plan can't be saved or exported and there is no write-up."),
    actionButton("source_still_applies", "Yes, it still applies", class = "btn btn-outline-primary"),
    span(class = "small", " or edit your reasoning under \u201cWhere your effect size comes from\u201d and press \u201cCheck my answers\u201d again."))
}

# The sample size at 80% and at 95% power side by side (the new design:
# no silent default for target power). Exact results only: two more engine
# calls, instant for the formula designs. With "all of several" tests
# (`values`), 80% and 95% are for all of them together.
cost_line <- function(spec, result, run = engine_function("run_spec"), seed = 1L, values = list()) {
  if (!identical(result$goal_type, "sample_size") || simulated(result)) return(NULL)
  n_at <- function(power) {
    if (isTRUE(all.equal(power, spec$goal$power))) return(result$n_required$n)
    s <- spec
    s$goal$power <- power
    calc <- run_calculation(s, run, seed)
    if (identical(calc$status, "ok")) calc$result$n_required$n else NA
  }
  n80 <- n_at(claim_power(0.8, values)); n95 <- n_at(claim_power(0.95, values))
  if (is.na(n80) || is.na(n95)) return(NULL)
  together <- if (!identical(claim_power(0.8, values), 0.8)) " (for all the tests together)" else ""
  sprintf(
    "For comparison: 80%% power%s needs %s participants%s; 95%% power needs %s%s. Which you choose, and why, belongs in your plan.",
    together, whole(n80), group_text(spec, n80), whole(n95), group_text(spec, n95)
  )
}

# The explore panel (the new design): power by sample size for any effect
# size the user tries, kept apart from the plan. The t-tests and the
# correlation by formula only for now. The app only calls the engine.
explore_effect <- function(spec) {
  if (!identical(spec$design, "basic_test") || identical(spec$options$method, "simulation") ||
      identical(spec$target_test$method, "welch_t")) return(NULL)
  switch(spec$template,
    one_sample_t = list(field = "d", label = "Cohen's d", max = 1.5),
    independent_t = list(field = "d", label = "Cohen's d", max = 1.5),
    paired_t = list(field = "dz", label = "d_z", max = 1.5),
    correlation = list(field = "r", label = "Correlation r", max = 0.9),
    NULL)
}

explore_sizes <- function(spec, result) {
  n <- if (identical(result$goal_type, "sample_size")) result$n_required$n else spec$goal$n
  step <- if (identical(spec$template, "independent_t") && isTRUE(all.equal(spec$options$allocation_ratio %||% 1, 1))) 2 else 1
  ns <- step * round(seq(max(8, n / 4), 2 * n, length.out = 12) / step)
  unique(pmax(ns, 8))
}

explore_curve <- function(spec, result, effect, run = engine_function("run_spec"), seed = 1L) {
  e <- explore_effect(spec)
  ns <- explore_sizes(spec, result)
  power <- vapply(ns, function(n) {
    s <- spec
    # The slider is in standardised units, whatever units the plan used.
    s$population <- stats::setNames(list("standardised", effect), c("metric", e$field))
    s$goal <- list(type = "power", n = as.integer(n))
    calc <- run_calculation(s, run, seed)
    if (identical(calc$status, "ok")) calc$result$curve$power[1] else NA_real_
  }, numeric(1))
  data.frame(n = ns, power = power)
}

explore_ui <- function(spec, result = NULL) {
  e <- explore_effect(spec)
  if (is.null(e)) return(NULL)
  planned <- result$effect_from_units$value %||% spec$population[[e$field]]
  start <- if (is.null(planned) || planned == 0) 0.3 else abs(planned)
  div(class = "explore-panel",
    h4(class = "h6", "Explore: what if the effect were different?"),
    p(class = "small", "Move the slider to see how power changes with the sample size for other effect sizes. Exploring doesn't change your plan: it keeps the effect size and reasoning you entered."),
    sliderInput("explore_effect", e$label, min = 0.05, max = e$max, value = round(start, 2), step = 0.01, width = "100%"),
    plotOutput("explore_plot", height = "280px")
  )
}

# Three effects side by side: the plan's effect with a smaller
# (conservative) and a larger (optimistic) one the user gives. One number
# hides how much the answer depends on being right about the effect; three
# lines show it. powerkit suggests neither value. The same designs as the
# explore panel; the app only calls the engine.
scenario_names <- c(conservative = "Conservative", expected = "Your plan's effect", optimistic = "Optimistic")

# The plan's effect, standardised (worked out by the engine where the
# effect was given in the measure's own units).
scenario_planned <- function(spec, result = NULL) {
  e <- explore_effect(spec)
  if (is.null(e)) return(NULL)
  result$effect_from_units$value %||% spec$population[[e$field]]
}

scenario_effects <- function(spec, result = NULL, conservative = NA, optimistic = NA) {
  planned <- scenario_planned(spec, result)
  effects <- c(conservative = conservative, expected = if (is.null(planned)) NA else planned, optimistic = optimistic)
  effects[!is.na(effects)]
}

scenario_curves <- function(spec, result, conservative = NA, optimistic = NA, n = NULL, run = engine_function("run_spec"), seed = 1L) {
  e <- explore_effect(spec)
  effects <- scenario_effects(spec, result, conservative, optimistic)
  # Wide enough to show where every line reaches the target power.
  top <- max(c(explore_sizes(spec, result), 1.25 * n), na.rm = TRUE)
  step <- if (identical(spec$template, "independent_t") && isTRUE(all.equal(spec$options$allocation_ratio %||% 1, 1))) 2 else 1
  ns <- unique(pmax(8, step * round(seq(8, top, length.out = 15) / step)))
  do.call(rbind, lapply(names(effects), function(k) {
    power <- vapply(ns, function(at) {
      s <- spec
      s$population <- stats::setNames(list("standardised", effects[[k]]), c("metric", e$field))
      s$goal <- list(type = "power", n = as.integer(at))
      calc <- run_calculation(s, run, seed)
      if (identical(calc$status, "ok")) calc$result$curve$power[1] else NA_real_
    }, numeric(1))
    data.frame(n = ns, power = power, scenario = k)
  }))
}

# The N each effect needs at the plan's target power (or 80% for a plan at
# a fixed N), from the engine; NA where the engine can't give one.
scenario_n <- function(spec, result, conservative = NA, optimistic = NA, run = engine_function("run_spec"), seed = 1L) {
  e <- explore_effect(spec)
  effects <- scenario_effects(spec, result, conservative, optimistic)
  power <- spec$goal$power %||% 0.8
  vapply(effects, function(effect) {
    s <- spec
    s$population <- stats::setNames(list("standardised", effect), c("metric", e$field))
    s$goal <- list(type = "sample_size", power = power)
    calc <- run_calculation(s, run, seed)
    if (identical(calc$status, "ok")) calc$result$n_required$n else NA_real_
  }, numeric(1))
}

scenario_sentence <- function(spec, n) {
  power <- spec$goal$power %||% 0.8
  parts <- vapply(names(n), function(k) {
    sprintf("%s needs %s", tolower(scenario_names[[k]]), if (is.na(n[[k]])) "a number powerkit couldn't find" else whole(n[[k]]))
  }, character(1))
  sprintf("For %s power, %s participants in total.", percent(power), paste(parts, collapse = "; "))
}

scenarios_ui <- function(spec, result = NULL) {
  e <- explore_effect(spec)
  planned <- scenario_planned(spec, result)
  # Nothing to compare with a plan for the smallest detectable effect, or
  # with no effect.
  if (is.null(e) || identical(spec$goal$type, "sensitivity") || is.null(planned) || planned == 0) return(NULL)
  div(class = "scenario-panel",
    h4(class = "h6", "How much does the answer depend on the effect?"),
    p(class = "small", sprintf(paste0(
      "Your plan uses %s = %s. Enter a smaller effect you would still find plausible (conservative) and a larger one (optimistic), ",
      "and powerkit draws power for all three. Choose values you could defend; powerkit won't suggest them, and they don't change your plan."),
      e$label, format(round(planned, 3)))),
    div(class = "d-flex gap-3 flex-wrap",
      numericInput("scenario_conservative", sprintf("Conservative %s", e$label), value = NA, step = 0.01, width = "14rem"),
      numericInput("scenario_optimistic", sprintf("Optimistic %s", e$label), value = NA, step = 0.01, width = "14rem")),
    plotOutput("scenario_plot", height = "300px"),
    uiOutput("scenario_n"))
}

# "The smallest effect I could detect across a range of sample sizes": the
# engine's smallest detectable effect at eight sample sizes up to the
# largest one, at 80% and 95% power. The app only calls the engine.
curve_sizes <- function(spec) {
  n_max <- spec$goal$n
  step <- if (identical(spec$template, "independent_t") && isTRUE(all.equal(spec$options$allocation_ratio %||% 1, 1))) 2 else 1
  ns <- step * round(seq(n_max / 8, n_max, length.out = 8) / step)
  unique(pmax(ns, 8))
}

run_sensitivity_curve <- function(spec, run = engine_function("run_spec"), seed = 1L) {
  main <- run_calculation(spec, run, seed)
  if (!identical(main$status, "ok")) return(main)
  ns <- curve_sizes(spec)
  at <- function(n, power) {
    s <- spec
    s$goal <- list(type = "sensitivity", n = as.integer(n), power = power)
    calc <- run_calculation(s, run, seed)
    if (identical(calc$status, "ok")) calc$result$sensitivity$effect else NA_real_
  }
  main$curve_table <- data.frame(
    n = ns,
    power_80 = vapply(ns, at, numeric(1), power = 0.8),
    power_95 = vapply(ns, at, numeric(1), power = 0.95)
  )
  main
}

curve_table_ui <- function(spec, result, table) {
  name <- switch(result$sensitivity$effect_name %||% "", d = "d", d_z = "d_z", r = "r", w = "w", p2 = "p2", "effect")
  # Two proportions: the column is group 2's proportion, not a size.
  heading <- function(power) {
    if (identical(name, "p2")) sprintf("Group 2's proportion, %s power", power) else sprintf("Smallest %s, %s power", name, power)
  }
  tagList(
    h4(class = "h6", "The smallest effect you could detect at each sample size"),
    p(class = "small", if (identical(name, "p2")) {
      sprintf("Group 2's proportion needed (group 1's kept at %s). Larger samples can detect smaller differences; read across to see what each sample size buys.", format(result$sensitivity$p1))
    } else {
      sprintf("%s. Larger samples can detect smaller effects; read across to see what each sample size buys.", result$sensitivity$effect_description)
    }),
    tags$table(class = "table table-sm result-curve-table",
      tags$thead(tags$tr(tags$th("Participants analysed"), tags$th(heading("80%")), tags$th(heading("95%")))),
      tags$tbody(lapply(seq_len(nrow(table)), function(i) tags$tr(
        tags$td(whole(table$n[i])),
        tags$td(format(round(table$power_80[i], 3), nsmall = 3)),
        tags$td(format(round(table$power_95[i], 3), nsmall = 3))
      )))
    )
  )
}

# Guess first: the user's guess next to the answer (forms.R, closing_groups()).
# A guess for power above 1 is read as a percentage.
guess_line <- function(values, result) {
  if (blank(values$guess)) return(NULL)
  g <- parse_number(values$guess)
  if (is.nan(g) || is.na(g)) return(NULL)
  switch(
    result$goal_type,
    sample_size = {
      answer <- result$n_required$n
      sprintf("Your guess: %s participants. The answer: %s, %s.", whole(g), whole(answer), guess_gap(g, answer))
    },
    power = {
      guessed <- if (g > 1) g / 100 else g
      sprintf("Your guess: %s power. The answer: %s.", percent(guessed), percent(result$curve$power[1]))
    },
    sensitivity = sprintf("Your guess: %s. The answer: %s.", format(g), format(round(result$sensitivity$effect, 3), nsmall = 2)),
    NULL
  )
}

guess_gap <- function(guess, answer) {
  if (guess <= 0) return("so your guess was too small")
  ratio <- answer / guess
  if (abs(ratio - 1) <= 0.1) return("close to your guess")
  if (ratio >= 1.5) return(sprintf("%s times your guess", format(round(ratio, 1), nsmall = 1)))
  if (ratio > 1) return(sprintf("%d%% more than your guess", round(100 * (ratio - 1))))
  sprintf("%d%% fewer than your guess", round(100 * (1 - ratio)))
}

# A short warning for effect sizes taken from one earlier study.
source_note <- function(values) {
  if (!identical(values$just_type, "prior_study")) return(NULL)
  "Your effect size comes from one earlier study. Published effects from single studies tend to be larger than the true effect, so a sample size based on one can be too small. Adjusting it (and saying how) helps; the BUCSS R package offers a bias-corrected approach."
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

# Analysed and to recruit, when the user gave an attrition rate (the
# maintainer's decision of 17 October 2026). The engine works out the
# number to recruit (run_spec()'s `recruitment`); this only words it.
recruitment_lines <- function(result) {
  r <- result$recruitment
  if (!is.list(r)) return(NULL)
  groups <- function(sizes) {
    if (length(sizes) < 2 || is.na(r$unit)) return("")
    if (length(unique(sizes)) == 1) return(sprintf(" (%s per %s)", whole(sizes[1]), r$unit))
    sprintf(" (%s)", paste(sprintf("%s in %s %d", whole(sizes), r$unit, seq_along(sizes)), collapse = " and "))
  }
  c(
    analysed = sprintf("Analysed: %s participants%s.", whole(r$n_analysed), groups(r$groups_analysed)),
    recruit = sprintf(
      "To recruit: %s participants%s, allowing for %s attrition (each group's analysed number divided by %s, rounded up).",
      whole(r$n_recruit), groups(r$groups_recruit), percent_attrition(r$attrition), format(1 - r$attrition)
    ),
    caveat = attrition_caveat
  )
}

percent_attrition <- function(a) paste0(format(100 * a), "%")

attrition_caveat <- "Dividing by (1 \u2212 attrition) is a common but crude heuristic: it ignores how missing data will be handled in the analysis (Rubin, M., 2025, International Journal of Psychology, doi:10.1002/ijop.70017)."

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
calculating_background_ui <- function(usual, title = "Calculating with powerkit's engine\u2026") {
  usual_words <- if (is.na(usual)) NULL else if (usual < 120) sprintf("%s seconds", whole(usual)) else sprintf("%s minutes", whole(round(usual / 60)))
  div(class = "result-panel calculating calc-progress", tabindex = "-1",
    p(role = "status", tags$strong(title),
      if (!is.null(usual_words)) sprintf(" This usually takes about %s on one core.", usual_words)),
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
  # Departures 9, 10 and 11 (a formula for basic tests; Fisher's z for a
  # correlation; the z test for two proportions) apply only when the formula was used, not to simulation
  # or Welch's t-test (whose formula, pwrss's, is chosen by the user).
  if (identical(spec$options$method, "simulation") || identical(spec$target_test$method, "welch_t")) keys <- setdiff(keys, c("9", "10", "11"))
  # Fisher's exact test (E5's option) is pwrss's exact test: none of the z
  # test's departures, nor the continuity correction, apply.
  if (identical(spec$target_test$method, "fisher_exact")) keys <- setdiff(keys, c("5", "9", "10", "11"))
  vapply(keys, function(k) forms$departures[[k]], character(1))
}

# `known_differences_if_method` limits a known difference to one test
# version (E5: Known difference 2 applies only to Fisher's exact test).
known_difference_keys <- function(forms, ep_id, spec = NULL) {
  form <- forms$forms[[ep_id]]
  keys <- unlist(form$known_differences)
  only <- form$known_differences_if_method
  keys <- Filter(function(k) is.null(only[[k]]) || identical(spec$target_test$method, only[[k]]), keys)
  # Some apply only when a population value is above 0 (E27's Known
  # difference 3, logistic regression with other predictors).
  above <- form$known_differences_if_above_zero
  keys <- Filter(function(k) is.null(above[[k]]) || isTRUE((spec$population[[above[[k]]]] %||% 0) > 0), keys)
  # A known difference may have its own wording for the smallest detectable
  # effect (key "1 sensitivity": E9's comes from the fixed-model formula).
  if (identical(spec$goal$type, "sensitivity")) {
    keys <- vapply(keys, function(k) if (is.null(forms$known_differences[[paste(k, "sensitivity")]])) k else paste(k, "sensitivity"), character(1), USE.NAMES = FALSE)
  }
  keys
}

known_differences_for <- function(forms, ep_id, spec = NULL) {
  keys <- known_difference_keys(forms, ep_id, spec)
  vapply(keys, function(k) forms$known_differences[[k]], character(1))
}

validation_ui <- function(ep) {
  if (identical(ep$status, "runs_validated")) {
    p(class = "result-validation small text-muted", tags$strong("Validated. "), ep$validation$note)
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
  known <- known_differences_for(forms, ep_id, spec)
  notes <- unique(c(claim_result_note(values, spec$target_test$alpha, values$goal), source_note(values), check_advice, calc$notes))
  # The reasoning is needed to save or export, not to calculate.
  can_export <- !blank(values$just_source) && !isTRUE(values$source_stale)
  # In cards: the answer first, with notes on reading it; then exploring
  # it; then saving and the write-up; then how it was calculated, where
  # powerkit differs from the usual tools, and the technical records. The
  # details a reader rarely needs (the values used, the seed, what power
  # can't tell you) are folded under "More about this result".
  div(
    class = "result-panel", role = "status", tabindex = "-1",
    div(class = "result-card result-main",
    h3(class = "h4", "Your result"),
    p(class = "result-headline lead", words[["headline"]]),
    if (!is.null(guess <- guess_line(values, result))) p(class = "result-guess", tags$strong(guess)),
    if (!is.na(words["reading"])) p(class = "result-reading", words[["reading"]]),
    if (!is.null(calc$cost_line)) p(class = "result-cost-line", calc$cost_line),
    if (!is.null(line <- reasoning_line(values))) p(class = "result-reasoning", line),
    source_stale_ui(fields, values),
    if (!is.null(actual <- actual_power_sentence(spec, result))) p(class = "result-actual-power", actual),
    if (!is.null(recruit <- recruitment_lines(result))) div(class = "result-recruitment",
      p(tags$strong(recruit[["analysed"]])), p(tags$strong(recruit[["recruit"]])),
      p(class = "small", recruit[["caveat"]])),
    p(class = "result-detail", words[["detail"]]),
    if (length(notes)) tagList(h4(class = "h6", "Notes"), tags$ul(class = "result-notes", lapply(notes, tags$li))),
    if (length(known)) p(class = "result-differs-pointer small",
      "Other established tools can give a slightly different answer for this design: see \u201cHow it was calculated\u201d below.")),
    if (!is.null(calc$curve_table)) div(class = "result-card", curve_table_ui(spec, result, calc$curve_table)),
    div(class = "result-card result-explore", explore_ui(spec, result)),
    if (!is.null(scen <- scenarios_ui(spec, result))) div(class = "result-card result-scenarios", scen),
    div(class = "result-card result-save",
    h4(class = "h5", "Save and share"),
    if (!can_export && blank(values$just_source)) p(class = "export-needs-reasoning",
      tags$strong("To save this plan, download its R script or get its write-up, "),
      "write your reasoning under \u201cWhere your effect size comes from\u201d and press \u201cCheck my answers\u201d again. Exploring doesn't need it; a plan you keep or share does."),
    div(class = "nav-buttons",
      if (can_export) downloadButton("download_script", "Download R script", class = "btn btn-outline-primary"),
      downloadButton("download_citations", "Citations", class = "btn btn-outline-primary"),
      if (can_export) downloadButton("download_project", "Save project", class = "btn btn-outline-primary")),
    p(class = "small", "The R script reproduces this result with ", p_$backend, " alone (powerkit isn't needed). Citations lists the package's own citation(), its method paper and the software used. Save project keeps your answers, values, seed and result in one file on your computer; open it from the start screen to carry on or reproduce the result."),
    writeup_ui(writeup_text(forms$forms[[ep_id]], spec, result, fields, values, departures,
      vapply(known_difference_keys(forms, ep_id, spec), function(k) forms$known_differences_methods[[k]], character(1)), known))),
    div(class = "result-card result-how",
    h4(class = "h5", "How it was calculated"),
    if (simulated(result)) p(class = "result-simulation", simulation_note(result)),
    p(class = "result-credit",
      "Calculated by the R package ", tags$strong(p_$backend), sprintf(" (version %s), with %s. ", p_$packages[[p_$backend]], p_$backend_function),
      if (p_$backend %in% c("pwr", "stats", "pwrss")) "powerkit built the call from your answers and checked the effect size it passes. " else
        "powerkit built the call from your answers and checked that it reproduces the population you entered. ",
      "Cite the package: see Citations above."),
    validation_ui(ep),
    if (length(departures)) tagList(
      h4(class = "h6", "Where powerkit differs from the tool's defaults"),
      tags$ul(class = "result-departures", lapply(unname(departures), tags$li))
    ),
    if (length(known)) tagList(
      h4(class = "h6", "Where other established tools give a different answer"),
      tags$ul(class = "result-known-differences", lapply(unname(known), tags$li))
    ),
    tags$details(class = "result-more",
      tags$summary("More about this result: the values it used, the seed, and what power can't tell you"),
      h4(class = "h6", "What this result used"),
      tags$ul(class = "result-inputs", lapply(entered_lines(fields, values), tags$li)),
      p(class = "result-seed small",
        sprintf("Seed: %s. ", p_$seed),
        if (simulated(result)) "You can change it under \u201cRandom seed\u201d above and calculate again." else
          "Nothing was simulated, so the seed doesn't change this result in practice."),
      p(class = "result-observed small", not_observed_power),
      p(class = "result-limits small", power_limits)),
    placeholders_at(tree, "result"),
    tags$details(class = "result-more", tags$summary("Reproducibility record"), tags$ul(lapply(provenance_lines(result), tags$li))),
    tags$details(class = "result-more", tags$summary("The design spec that was run (JSON)"), tags$pre(class = "spec-json", spec_json(spec))))
  )
}

# --- The write-up (methods paragraph) -----------------------------------------
# What it states was decided on 18 October 2026 (docs/decisions.md, "What
# the methods paragraph reports"): the test and its sides; alpha; the
# target power and the user's reason; the effect size with the user's
# reasoning, word for word; N in total and per group, with the power
# reached; the package, its version and function; the seed and the number
# of simulations; and the departures. No noncentrality parameter or
# critical value. A short version for the paper and a full one for the
# supplement or preregistration. It only words the engine's result.

writeup_source <- c(
  smallest_effect_of_interest = "the smallest effect that would matter",
  meta_analysis = "an estimate from a meta-analysis",
  prior_study = "an estimate from a previous study",
  pilot_study = "an estimate from a pilot study",
  own_study_result = "the effect observed in the finished study itself (observed power)"
)

# "Cohen's d = 0.4", from the fields marked as the effect.
writeup_effect <- function(fields, values) {
  out <- character()
  for (f in fields) {
    if (!(isTRUE(f$effect) || isTRUE(f$in_effect_text)) || blank(values[[f$id]]) || !field_applies(f, values)) next
    out <- c(out, sprintf("%s = %s", f$writeup_label %||% f$label, trimws(as.character(values[[f$id]]))))
  }
  if (length(out)) paste(out, collapse = "; ") else NULL
}

writeup_sides <- function(spec) {
  switch(spec$target_test$alternative %||% "two_sided",
    two_sided = "two-sided", greater = "one-sided, effect positive", less = "one-sided, effect negative")
}

# The reasons given for a changed alpha or a one-sided test, as sentences
# (each reason box is shown only when its setting was changed).
writeup_choices <- function(fields, values) {
  given <- function(id) {
    f <- Filter(function(f) identical(f$id, id), fields)
    length(f) == 1 && !blank(values[[id]]) && field_applies(f[[1]], values)
  }
  because <- function(x) sub("[.]\\s*$", "", trimws(gsub("\\s+", " ", as.character(x))))
  c(
    if (given("alpha_reason")) sprintf("The significance level of %s was chosen because %s.",
      writeup_alpha(as.numeric(values$alpha)), because(values$alpha_reason)),
    if (given("alternative_reason")) sprintf("A one-sided test was used because %s.", because(values$alternative_reason))
  )
}

writeup_alpha <- function(a) sub("^0\\.", ".", format(signif(a, 3)))

writeup_quote <- function(x) sprintf("“%s”", trimws(gsub("\\s+", " ", as.character(x))))

writeup_software <- function(result, full = FALSE) {
  p <- result$provenance
  how <- if (simulated(result)) {
    sprintf("by simulation with %s replications%s (seed %s)", whole(p$nrep),
      if (identical(result$goal_type, "sample_size")) " per sample size" else "", p$seed)
  } else {
    "by formula (no simulation)"
  }
  s <- sprintf("Power was calculated %s, with the R package %s (version %s; %s()), set up by powerkit (version %s) in %s.",
    how, p$backend, p$packages[[p$backend]], p$backend_function, p$packages[["powerkit"]], p$r_version)
  if (full) {
    s <- paste(s, sprintf("Seed: %s. Spec hash: %s. Check that the backend reproduces the population entered: %s.",
      p$seed, p$spec_hash, if (all(result$check_run$ok)) "passed" else "failed"))
  }
  s
}

writeup_claim <- function(values, spec) {
  switch(values$claim %||% "one",
    one = NULL,
    each = "Each hypothesis supports its own claim, so no correction for multiple tests was applied; each test is powered on its own.",
    any = sprintf("The claim is supported if any one of %s tests is significant, so alpha was divided by %s (Bonferroni), giving α = %s for this test.",
      values$n_tests, values$n_tests, writeup_alpha(spec$target_test$alpha)),
    all = {
      k <- claim_tests(values)
      if (!is.na(k) && isTRUE(values$goal %in% c("sample_size", "sensitivity"))) {
        sprintf("The claim requires all %s tests to be significant, so no correction to alpha was applied, and each test was planned at power %s^(1/%s) = %s, so that if the tests are independent all of them succeed with probability %s.",
          whole(k), format(parse_number(values$power)), whole(k), format(signif(spec$goal$power, 3)), format(parse_number(values$power)))
      } else {
        "The claim requires every one of several tests to be significant; the chance that all succeed is lower than the power of each test."
      }
    })
}

# Returns c(short = ..., full = ...), or NULL when there is no reasoning
# (the write-up, like saving, needs it).
writeup_text <- function(form, spec, result, fields, values, departures = character(), known_methods = character(), known = character()) {
  if (blank(values$just_source) || isTRUE(values$source_stale)) return(NULL)
  name <- form$methods_name
  if (identical(spec$target_test$method, "welch_t")) name <- paste0(name, " (Welch's)")
  if (identical(spec$target_test$method, "fisher_exact")) name <- "Fisher's exact test of two proportions"
  if (spec$template %in% c("2x2_between", "2x2_mixed")) name <- sprintf("%s (target effect: %s)", name, gsub("_", " ", spec$target_test$effect))
  # F and chi-square tests have no sides (forms.yaml, sides: false).
  sides <- if (isFALSE(form$sides)) NULL else writeup_sides(spec)
  generic <- identical(spec$design, "generic_test")
  if (generic) {
    # The statistic and its degrees of freedom; only t and z have sides.
    name <- paste("a generic", sub("^an? ", "", sub(" \\(two-sided.*| \\(one-sided.*| at alpha.*", "", generic_test_text(spec))))
    sides <- if (spec$template %in% c("t", "z")) writeup_sides(spec)
  }
  test <- sprintf("%s (%s)", name, paste(c(sides, paste("α =", writeup_alpha(spec$target_test$alpha))), collapse = ", "))
  effect <- writeup_effect(fields, values)
  # Means and SD: the standardised effect the engine worked out from them.
  u <- result$effect_from_units
  if (!is.null(effect) && !is.null(u) && !identical(result$goal_type, "sensitivity")) {
    effect <- sprintf("%s (%s = %s)", effect, u$name, format(round(u$value, 3), nsmall = 2))
  }
  reasoning <- writeup_quote(values$just_source)
  none <- identical(values$just_type, "none")
  basis <- if (none) {
    sprintf("No effect size was chosen in advance (no formal justification of an effect size); the reasoning: %s.", reasoning)
  } else if (!is.null(effect)) {
    adj <- if (!blank(values$just_adjustment)) sprintf(" It was adjusted as follows: %s.", writeup_quote(values$just_adjustment)) else ""
    sprintf("The effect size, %s, was based on %s: %s.%s", effect, writeup_source[[values$just_type %||% "smallest_effect_of_interest"]], reasoning, adj)
  } else {
    sprintf("The reasoning about the effect size: %s.", reasoning)
  }
  reason <- if (!blank(values$power_reason)) sprintf(", chosen because %s", sub("[.]\\s*$", "", trimws(values$power_reason))) else ""
  fixed <- identical(values$situation, "fixed")
  no_n <- "from a noncentrality parameter, which already reflects the sample size"
  main <- if (generic && identical(result$goal_type, "power")) {
    c(sprintf("A power analysis was conducted for %s, %s.", test, no_n), basis,
      sprintf("Power to detect this effect is %.1f%%.", 100 * result$curve$power[1]))
  } else if (generic) {
    c(sprintf("A sensitivity power analysis was conducted for %s, %s.", test, no_n),
      sprintf("The smallest noncentrality parameter giving %s power%s is %s.", percent(spec$goal$power), reason, format(round(result$sensitivity$effect, 3), nsmall = 2)),
      basis)
  } else switch(result$goal_type,
    sample_size = {
      n <- result$n_required$n
      at_n <- result$curve$power[result$curve$n == n]
      reached <- if (length(at_n) == 1 && !simulated(result)) sprintf("; power at this sample size is %.1f%%", 100 * at_n) else ""
      c(sprintf("An a priori power analysis was conducted for %s.", test), basis,
        sprintf("For a target power of %s%s, %s participants are needed in total%s%s.",
          percent(spec$goal$power), reason, whole(n), group_text(spec, n), reached))
    },
    power = {
      row <- result$curve[1, ]
      c(sprintf("A power analysis was conducted for %s at a %ssample size of %s participants in total%s.",
          test, if (fixed) "fixed " else "", whole(row$n), group_text(spec, row$n)),
        basis, sprintf("Power to detect this effect is %.1f%%.", 100 * row$power))
    },
    sensitivity = {
      s <- result$sensitivity
      size <- if (is.null(s$cohen_f)) {
        sprintf("%s = %s (%s)", s$effect_name %||% "effect", format(round(s$effect, 3), nsmall = 2), s$effect_description)
      } else {
        sprintf("Cohen's f = %.3f (%s)", s$cohen_f, s$effect_description)
      }
      c(sprintf("A sensitivity power analysis was conducted for %s.", test),
        sprintf("%s %s participants in total%s.", if (fixed) "The sample size was fixed by resource constraints at" else "For a sample size of",
          whole(spec$goal$n), group_text(spec, spec$goal$n)),
        sprintf("The smallest effect detectable with %s power%s is %s.", percent(spec$goal$power), reason, size),
        basis)
    }
  )
  main <- append(main, writeup_choices(fields, values), after = 1)
  recruit <- result$recruitment
  recruit_line <- if (is.list(recruit)) sprintf("Allowing for %s attrition, %s participants will be recruited.",
    percent_attrition(recruit$attrition), whole(recruit$n_recruit))
  claim <- writeup_claim(values, spec)
  # The short version names only the differences that change the answer
  # (known_methods); departures from a tool's defaults are listed in the
  # full version, to keep the paper's paragraph short.
  short <- paste(c(main, recruit_line, claim, writeup_software(result), unname(known_methods)), collapse = " ")
  interval <- if (simulated(result) && identical(result$goal_type, "sample_size")) {
    sprintf("The 95%% interval for the required sample size, from the simulation, is %s to %s.", whole(result$n_required$lower), whole(result$n_required$upper))
  }
  full <- paste(c(
    paste(c(main, interval, recruit_line, claim), collapse = " "),
    writeup_software(result, full = TRUE),
    if (length(departures)) paste("Departures from the established tools' defaults:", paste(unname(departures), collapse = " ")),
    if (length(known)) paste("Where other established tools give a different answer:", paste(unname(known), collapse = " "))
  ), collapse = "\n\n")
  tidy <- function(x) gsub("([.!?])\u201d\\.", "\\1\u201d", x)
  c(short = tidy(short), full = tidy(full), ethics = tidy(ethics_text(spec, result, fields, values)))
}

# The ethics-board version (optional feature, 19 October 2026): the same
# result in plain words for a lay ethics panel, saying why this many
# participants. It only words the engine's result, like the write-up, and
# passes no verdict on whether the study is ethical.
ethics_text <- function(spec, result, fields, values) {
  # Generic tests (E50) have no participants to describe.
  if (identical(spec$design, "generic_test")) return(NA_character_)
  alpha <- paste0(format(100 * spec$target_test$alpha), "%")
  fixed <- identical(values$situation, "fixed")
  effect <- writeup_effect(fields, values)
  reasoning <- writeup_quote(values$just_source)
  basis <- if (identical(values$just_type, "none") || is.null(effect)) {
    sprintf("Our reasoning about the size of the effect: %s.", reasoning)
  } else {
    sprintf("We are planning for an effect of %s, based on %s: %s.", effect,
      writeup_source[[values$just_type %||% "smallest_effect_of_interest"]], reasoning)
  }
  n <- switch(result$goal_type, sample_size = result$n_required$n, power = result$curve$n[1], spec$goal$n)
  chance <- function(p) sprintf(
    "If that effect is real, the chance that a study of this size finds it (a statistically significant result, using a %s threshold) is %s, and the chance that it misses it is %s. If the real effect is smaller, the chance of missing it is higher.",
    alpha, percent(p), percent(1 - p))
  include <- sprintf("We plan to include %s participants in the analysis%s.", whole(n), group_text(spec, n))
  recruit <- result$recruitment
  recruit_line <- if (is.list(recruit)) sprintf(
    "To allow for about %s who may drop out or be excluded, we will recruit %s.",
    percent_attrition(recruit$attrition), whole(recruit$n_recruit))
  set_by <- if (fixed) "This number is set by the resources available, not chosen by a power analysis."
  body <- switch(result$goal_type,
    sample_size = c(include, recruit_line, "This number comes from a power analysis.", basis, chance(spec$goal$power),
      "With fewer participants, the study would be more likely to miss the effect, so people's time could go into a study that can't answer its question. This number is enough for that aim without asking more people to take part than it needs."),
    power = c(include, recruit_line, set_by, basis, chance(result$curve$power[1])),
    sensitivity = {
      s <- result$sensitivity
      size <- if (is.null(s$cohen_f)) {
        sprintf("%s, measured as %s", format(round(s$effect, 3), nsmall = 2), s$effect_description)
      } else {
        sprintf("%s (Cohen's f = %.3f), measured as %s", format(signif(s$effect, 3)), s$cohen_f, s$effect_description)
      }
      c(include, recruit_line, set_by,
        sprintf("A power analysis shows the smallest effect a study of this size would find %s of the time (using a %s threshold for statistical significance) is %s. Smaller effects would more often be missed.",
          percent(spec$goal$power), alpha, size),
        sprintf("Our reasoning about the size of the effect: %s.", reasoning))
    })
  p <- result$provenance
  paste(c(body, sprintf("The calculation was made with powerkit and the R package %s (version %s) and can be reproduced from the saved plan.",
    p$backend, p$packages[[p$backend]])), collapse = " ")
}

writeup_ui <- function(text) {
  if (is.null(text)) return(NULL)
  # The short version is open; the longer ones are a click away, so the
  # card stays short.
  div(class = "result-writeup",
    h4(class = "h6", "Write-up"),
    p(class = "small", "Edit as you like before you copy it."),
    tags$label(`for` = "writeup_short", "Short version (for the paper)"),
    tags$textarea(id = "writeup_short", class = "form-control writeup", rows = 6, text[["short"]]),
    tags$details(class = "result-more",
      tags$summary("Full version (for a supplement or preregistration)"),
      tags$label(`for` = "writeup_full", class = "visually-hidden", "Full version (for a supplement or preregistration)"),
      tags$textarea(id = "writeup_full", class = "form-control writeup", rows = 10, text[["full"]])),
    if (!is.na(text["ethics"])) tags$details(class = "result-more",
      tags$summary("Plain-words version (for an ethics application)"),
      tags$label(`for` = "writeup_ethics", class = "visually-hidden", "Plain-words version (for an ethics application)"),
      p(class = "small", "Why this many participants, for a panel that may not know statistics. It describes the plan; it doesn't say whether the study is ethical."),
      tags$textarea(id = "writeup_ethics", class = "form-control writeup", rows = 7, text[["ethics"]])))
}
