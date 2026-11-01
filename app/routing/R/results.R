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
# A spec the engine will simulate (pairwise comparisons, Friedman's and
# Kruskal-Wallis tests, unequal cells, the Hartung-Knapp meta-analysis and
# so on) also runs in the background, so a run of a minute or two neither
# leaves the screen without a progress bar nor holds up everyone else
# using the app (the online app has one R process). The basic tests'
# simulations (Welch's t-test, the rank tests for two groups) take a few
# seconds, less than starting a background process, so they run here.
runs_in_background <- function(forms, ep_id, spec = NULL, simulates = engine_function("runs_simulation")) {
  if (ep_id %in% names(forms$background)) return(TRUE)
  if (is.null(spec) || is.null(simulates) || identical(spec$design, "basic_test")) return(FALSE)
  isTRUE(tryCatch(simulates(spec), error = function(e) FALSE))
}
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
  # A whole-study simulation (experimental) runs run_whole_study().
  fun <- if (identical(spec$kind, "whole_study")) "run_whole_study" else "run_spec"
  run <- if (requireNamespace("powerkit", quietly = TRUE)) {
    getExportedValue("powerkit", fun)
  } else {
    suppressMessages(pkgload::load_all(engine_dir, export_all = FALSE, helpers = FALSE, quiet = TRUE, attach = FALSE))
    get(fun, envir = asNamespace("powerkit"))
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
    tost_independent = ,
    tost_two_proportions = ,
    noninf_independent = ,
    noninf_two_proportions = ,
    invariance = ,
    two_proportions = ,
    two_correlations = {
      ratio <- spec$options$allocation_ratio %||% 1
      n1 <- round(n / (1 + ratio))
      c(n1, n - n1)
    },
    "2x2_between" = rep(n / 4, 4),
    "2x2_mixed" = rep(n / 2, 2),
    factorial_between = ,
    factorial_ancova = {
      cells <- length(spec$variables$A$levels) * length(spec$variables$B$levels)
      rep(n / cells, cells)
    },
    factorial_three = {
      v <- spec$variables[c("A", "B", "C")]
      between <- vapply(v, function(x) identical(x$type, "between_factor"), logical(1))
      groups <- prod(vapply(v[between], function(x) length(x$levels), numeric(1)))
      if (groups > 1) rep(n / groups, groups) else NULL
    },
    oneway_between = ,
    mixed = ,
    oneway_ancova = {
      k <- length(spec$variables$A$levels)
      rep(n / k, k)
    },
    NULL
  )
}

group_text <- function(spec, n) {
  if (identical(spec$template, "cluster_randomised")) {
    m <- spec$population$cluster_size
    return(sprintf(" (%s groups of %s, %s groups in each condition)", whole(n / m), whole(m), whole(n / m / 2)))
  }
  if (identical(spec$template, "multisite")) {
    m <- spec$population$cluster_size
    return(sprintf(" (%s groups of %s, half of each group in each condition)", whole(n / m), whole(m)))
  }
  if (identical(spec$template, "group_treatment")) {
    m <- spec$population$cluster_size
    return(sprintf(" (%s in %s groups of %s, and %s taking part individually)", whole(n / 2), whole(n / m / 2), whole(m), whole(n / 2)))
  }
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
  if (is_sem_fit(spec)) {
    return(sprintf("the chi-square test of exact model fit at alpha = %s", alpha_text(spec$target_test$alpha)))
  }
  if (identical(spec$design, "sem")) {
    return(sprintf("%s at alpha = %s", sem_test_name(spec), alpha_text(spec$target_test$alpha)))
  }
  alt <- spec$target_test$alternative %||% "two_sided"
  if (is_bayes_test(spec)) {
    side <- switch(alt, two_sided = "two-sided", greater = "one-sided, effect positive", less = "one-sided, effect negative")
    return(sprintf("%s (%s; %s)", bayes_test_name(spec), side, bayes_settings_text(spec)))
  }
  if (is_minimum_effect(spec)) return(minimum_effect_test_text(spec))
  side <- switch(alt, two_sided = "a two-sided test", greater = "a one-sided test (effect positive)", less = "a one-sided test (effect negative)")
  # A trend test's direction is a rise or a fall across the groups in order.
  if (is_trend_test(spec) && alt != "two_sided") side <- sprintf("a one-sided test (a %s trend)", if (alt == "greater") "rising" else "falling")
  if (is.null(spec$target_test$alternative) && !is.null(unsided <- unsided_test_name(spec))) side <- unsided
  sprintf("%s at alpha = %s", side, alpha_text(spec$target_test$alpha))
}

# F and chi-square tests have no sides (forms.yaml, sides: false), so the
# result names the test instead of calling it two-sided.
unsided_test_name <- function(spec) {
  if (spec$template %in% c("chi_square_independence", "chi_square_gof")) return("a chi-square test")
  if ((identical(spec$design, "factorial_anova") && !identical(spec$template, "oneway_contrast") &&
       !identical(spec$target_test$effect, "pairwise")) ||
      identical(spec$design, "multiple_regression") || spec$template %in% c("manova", "hotelling_one")) {
    return(if (isTRUE(spec$target_test$method %in% c("kruskal_wallis", "friedman", "jonckheere_terpstra"))) "a rank test" else "an F test")
  }
  NULL
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

# The random-effects meta-analysis planned with the Hartung-Knapp test
# (Departure 18): the default unless the z test or the fixed-effect model
# is chosen.
# A planned meta-analysis (E61): its n is the number of studies.
is_meta <- function(spec) identical(spec$design, "meta_analysis")
is_dyadic <- function(spec) identical(spec$design, "dyadic")

# What n counts, when it isn't participants: studies (a meta-analysis) or
# pairs (dyadic data).
n_unit <- function(spec) if (is_meta(spec)) "studies" else if (is_dyadic(spec)) "pairs" else NULL

# Dyadic data: the write-up counts pairs.
dyad_units <- function(text) {
  text <- gsub(" participants are needed in total", " pairs are needed", text, fixed = TRUE)
  text <- gsub("power at this sample size is", "power with this many pairs is", text, fixed = TRUE)
  text <- gsub("at a (fixed )?sample size of ([0-9,]+) participants in total", "with \\2 pairs", text)
  text
}

is_hartung_knapp <- function(spec) {
  identical(spec$design, "meta_analysis") && !isTRUE(spec$template %in% c("dependent_effects", "heterogeneity")) &&
    !identical(spec$target_test$model, "fixed") && !identical(spec$target_test$test, "z")
}

# A planned meta-analysis (E61): n is the number of studies, and the
# heterogeneity matters as much as the effect (Jackson and Turner, 2017).
# The methods paragraph's name for each meta-analysis question (E61).
meta_methods_name <- function(spec) {
  test <- if (is_hartung_knapp(spec)) "the Hartung-Knapp test" else "the z test"
  switch(spec$template,
    dependent_effects = "a meta-analysis of dependent effect sizes (the correlated and hierarchical effects model, the robust variance test of the average effect)",
    meta_regression = sprintf("a random-effects meta-regression (%s of the moderator's slope)", test),
    heterogeneity = "a meta-analysis's test of heterogeneity (Cochran's Q)",
    subgroups = sprintf("a %s subgroup analysis (%s that the kinds of study differ)",
      if (identical(spec$target_test$model, "fixed")) "fixed-effect" else "random-effects", if (is_hartung_knapp(spec)) test else "the Q test"),
    sprintf("a %s meta-analysis (%s of the average effect)", if (identical(spec$target_test$model, "fixed")) "fixed-effect" else "random-effects", test))
}

meta_sentences <- function(spec, result) {
  pop <- spec$population
  template <- spec$template
  dependent <- identical(template, "dependent_effects")
  regression <- identical(template, "meta_regression")
  heterogeneity <- identical(template, "heterogeneity")
  random <- !identical(spec$target_test$model, "fixed")
  model <- if (dependent) "the correlated and hierarchical effects model" else if (regression) "a random-effects meta-regression" else
    if (heterogeneity) "Cochran's Q test" else if (random) "the random-effects model" else "the fixed-effect model"
  subgroups <- identical(template, "subgroups")
  metric <- if (identical(pop$metric, "r")) "r" else "d"
  effect <- if (subgroups) {
    sprintf("average effects of %s = %s in the kinds of study", metric, paste(format(as.numeric(unlist(pop$effects))), collapse = ", "))
  } else if (regression) {
    sprintf("a change of %s in the effect for one SD more of the moderator (%s = %s at its mean)", format(pop$slope), metric, format(pop$effect))
  } else if (heterogeneity) {
    sprintf("heterogeneity of I-squared = %s", format(pop$i2))
  } else {
    sprintf("%s = %s", metric, format(pop$effect))
  }
  aim <- if (subgroups) "detect that the kinds of study differ, with" else if (regression) "detect" else if (heterogeneity) "detect" else
    "detect an average effect of"
  test_name <- if (dependent) " and the robust (RVE) test" else if (heterogeneity) "" else
    if (is_hartung_knapp(spec)) " and the Hartung-Knapp test" else " and the z test"
  studies <- if (dependent) {
    sprintf("studies of %s participants giving %s effects each (tau = %s between studies, omega = %s within, sampling correlation %s)",
      whole(pop$study_size), whole(pop$effects_per_study), format(pop$tau), format(pop$omega), format(pop$rho))
  } else {
    sprintf("studies of %s participants and %sI-squared = %s", whole(pop$study_size), if (regression) "residual " else "", format(pop$i2))
  }
  test <- sprintf("%s%s, alpha = %s%s, %s", model, test_name, alpha_text(spec$target_test$alpha),
    if (identical(spec$target_test$alternative %||% "two_sided", "two_sided")) "" else " one-sided", studies)
  simulated <- identical(result$provenance$method, "simulation")
  source <- if (simulated) {
    sprintf("Simulated: %s meta-analyses at each number of studies (Spower with metafor), so the answer carries a little random error.",
      whole(result$provenance$nrep))
  } else {
    sprintf("Calculated by formula (%s).", exact_source(result))
  }
  caution <- if (dependent) {
    paste("Each study's effects are allowed to differ and their estimates to be correlated; POMADE's authors advise trying",
          "a few values of the correlation and the heterogeneity when they aren't known.")
  } else if (heterogeneity) {
    "Cochran's Q test has little power with few studies, so a non-significant result says little about whether the studies differ."
  } else if (random) {
    paste("The random-effects model allows for the studies' true effects differing, which costs power; Jackson and",
          "Turner (2017) found that about five or more studies are needed before a random-effects meta-analysis",
          "reasonably consistently has more power than the studies in it.")
  } else {
    "The fixed-effect model assumes every study estimates the same effect; if they differ, its test is too optimistic."
  }
  finding <- if (subgroups) "find that the kinds of study differ" else if (regression) "find the moderator's slope significant" else
    if (heterogeneity) "find significant heterogeneity" else "find it significant"
  if (identical(result$goal_type, "sample_size")) {
    k <- result$n_required$n
    c(
      headline = sprintf("You need %s studies%s for %s power to %s %s, with %s.",
        whole(k), if (subgroups) " (split equally between the kinds)" else "", percent(spec$goal$power), aim, effect, test),
      detail = paste(source, caution)
    )
  } else {
    row <- result$curve[1, ]
    c(
      headline = if (subgroups || regression || heterogeneity) {
        sprintf("With %s studies, the meta-analysis has %s power: with %s, about %d in 100 meta-analyses like this would %s, with %s.",
          whole(row$n), percent(row$power), effect, round(100 * row$power), finding, test)
      } else {
        sprintf("With %s studies, the meta-analysis has %s power: if the average effect is %s, about %d in 100 meta-analyses like this would find it significant, with %s.",
          whole(row$n), percent(row$power), effect, round(100 * row$power), test)
      },
      detail = paste(source, caution)
    )
  }
}

# Equivalence tests (E36): the two one-sided tests, each at alpha, and the
# bounds (in the outcome's own units too, when given that way).
equivalence_bound <- function(spec, result) {
  name <- switch(spec$template, tost_paired = "d_z", tost_correlation = "r", tost_two_proportions = "p2 \u2212 p1", "d")
  u <- result$effect_from_units
  std <- sprintf("%s = \u00b1%s", name, format(round(u$bound_value %||% spec$population$bound, 3)))
  if (is.null(u$bound)) std else sprintf("\u00b1%s in your outcome's units (%s)", format(signif(u$bound, 4)), std)
}

equivalence_test_text <- function(spec, result) {
  sprintf("two one-sided tests (TOST), each at alpha = %s, and equivalence bounds of %s",
    alpha_text(spec$target_test$alpha), equivalence_bound(spec, result))
}

is_noninferiority <- function(spec) startsWith(spec$template %||% "", "noninf_")

# Minimum-effect tests on the t-test cards (E1-E3): the effect shown to be
# larger than the smallest effect of interest (the margin).
is_minimum_effect <- function(spec) identical(spec$target_test$method, "minimum_effect")

minimum_effect_margin_text <- function(spec) {
  sprintf("%s = %s", if (identical(spec$template, "paired_t")) "d_z" else "d", format(signif(spec$population$margin, 3)))
}

minimum_effect_test_text <- function(spec) {
  side <- switch(spec$target_test$alternative %||% "two_sided",
    greater = "one-sided: the effect above", less = "one-sided: the effect below minus",
    "two-sided: the effect further from 0 than")
  sprintf("a minimum-effect test at alpha = %s (%s a smallest effect of interest of %s)",
    alpha_text(spec$target_test$alpha), side, minimum_effect_margin_text(spec))
}

minimum_effect_sentence <- function(spec) {
  sprintf(paste("A minimum-effect test is significant only if the effect is larger than your smallest effect of interest (%s),",
    "not merely different from 0, so it needs more people than the ordinary t-test for the same effect."), minimum_effect_margin_text(spec))
}

# Non-inferiority: one one-sided test against the margin.
noninf_test_text <- function(spec) {
  pop <- spec$population
  unit <- switch(spec$template, noninf_paired = "d_z = ", noninf_two_proportions = "", "d = ")
  sprintf("a one-sided test at alpha = %s against a non-inferiority margin of %s%s (%s values better)",
    alpha_text(spec$target_test$alpha), unit, format(pop$margin), pop$better %||% "higher")
}

noninf_sentences <- function(spec, result) {
  test <- noninf_test_text(spec)
  shown <- "show that the new condition is no worse than the comparison by more than the margin"
  closer <- "The closer the true difference is to the margin, the lower the power; a new condition expected to be a little better needs fewer people."
  source <- sprintf("calculated for the difference you entered (%s).", exact_source(result))
  if (identical(result$goal_type, "sample_size")) {
    est <- result$n_required
    c(
      headline = sprintf("You need %s participants in total%s for %s power to %s, if the true difference is the one you entered, with %s.",
        whole(est$n), group_text(spec, est$n), percent(spec$goal$power), shown, test),
      detail = paste("This N is", source, closer),
      reading = plain_reading(spec$goal$power,
        outcome = "show that the new condition is no worse than the margin allows",
        if_not = "If the true difference is closer to the margin, fewer would.",
        condition = "the true difference is the one you entered")
    )
  } else {
    row <- result$curve[1, ]
    c(
      headline = sprintf("With %s participants in total%s, the study has %s power: if the true difference is the one you entered, about %d in 100 studies like this would %s, with %s.",
        whole(row$n), group_text(spec, row$n), percent(row$power), round(100 * row$power), shown, test),
      detail = paste("This power is", source, closer)
    )
  }
}

equivalence_sentences <- function(spec, result) {
  if (is_noninferiority(spec)) return(noninf_sentences(spec, result))
  test <- equivalence_test_text(spec, result)
  # A correlation is tested itself, not a difference.
  what <- if (identical(spec$template, "tost_correlation")) "correlation" else "difference"
  shown <- sprintf("show that the true %s lies inside the equivalence bounds (both one-sided tests significant)", what)
  closer <- sprintf("An expected %s of 0 is the most optimistic case: the closer the true %s is to a bound, the lower the power.", what, what)
  source <- sprintf("calculated for the %s you entered (%s).", what, exact_source(result))
  if (identical(result$goal_type, "sample_size")) {
    est <- result$n_required
    c(
      headline = sprintf("You need %s participants in total%s for %s power to %s, if the true %s is the one you entered, with %s.",
        whole(est$n), group_text(spec, est$n), percent(spec$goal$power), shown, what, test),
      detail = paste("This N is", source, closer),
      reading = plain_reading(spec$goal$power,
        outcome = sprintf("show that the %s lies inside the equivalence bounds", what),
        if_not = sprintf("If the true %s is closer to a bound, fewer would.", what),
        condition = sprintf("the true %s is the one you entered", what))
    )
  } else {
    row <- result$curve[1, ]
    c(
      headline = sprintf("With %s participants in total%s, the study has %s power: if the true %s is the one you entered, about %d in 100 studies like this would %s, with %s.",
        whole(row$n), group_text(spec, row$n), percent(row$power), what, round(100 * row$power), shown, test),
      detail = paste("This power is", source, closer)
    )
  }
}

# How an exact result was computed, for the detail sentence.
exact_source <- function(result) {
  if (identical(result$provenance$backend, "stats")) {
    sprintf("base R's formula, %s(), no simulation", result$provenance$backend_function)
  } else if (identical(result$provenance$backend, "Superpower")) {
    "Superpower's exact dataset, no repeated simulation"
  } else {
    sprintf("%s's formula, %s(), no simulation", result$provenance$backend, result$provenance$backend_function)
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
  if (is_precision(spec)) return(precision_sentences(spec, result))
  if (identical(spec$design, "generic_test")) return(generic_sentences(spec, result))
  if (identical(spec$design, "meta_analysis")) return(meta_sentences(spec, result))
  out <- if (identical(spec$design, "equivalence_test")) equivalence_sentences(spec, result) else goal_sentences(spec, result)
  # Dyadic data: n counts pairs.
  if (is_dyadic(spec)) out[] <- gsub(" participants in total", " pairs", out, fixed = TRUE)
  units <- units_sentence(result)
  if (!is.null(units)) out[["detail"]] <- paste(out[["detail"]], units)
  if (is_minimum_effect(spec)) out[["detail"]] <- paste(out[["detail"]], minimum_effect_sentence(spec))
  clusters <- cluster_sentence(result)
  if (!is.null(clusters)) out[["detail"]] <- paste(out[["detail"]], clusters)
  if (is_bayes_test(spec)) {
    out <- vapply(out, bayes_wording, character(1))
    out[["detail"]] <- paste(c(out[["detail"]], bayes_sentence(spec, result)), collapse = " ")
  }
  if (identical(spec$design, "sem") && !is_sem_fit(spec)) {
    out[["detail"]] <- paste(out[["detail"]], sem_restriction_sentence(spec))
  }
  if (!is.null(result$manova)) out[["detail"]] <- paste(out[["detail"]], manova_sentence(result, spec))
  sem <- if (is_sem_fit(spec)) sem_sentence(result)
  if (!is.null(sem)) {
    out[["detail"]] <- paste(out[["detail"]], sem)
    # Model fit: what is detected is the model's misfit, not an effect.
    out <- vapply(out, sem_wording, character(1))
  }
  out
}

is_sem_fit <- function(spec) identical(spec$design, "sem") && identical(spec$template, "model_fit")

# Repeated measures: the MANOVA approach's power beside the univariate F's
# (the engine's manova_summary(), from the same Superpower run).
manova_sentence <- function(result, spec = NULL) {
  m <- result$manova
  first <- if (is.null(spec) || assumes_sphericity(spec)) {
    "This assumes sphericity (equal variances of the differences between conditions). "
  } else {
    sprintf("This F test uses the SDs and correlations you gave, which need not keep sphericity, %s. ", sphericity_correction_words(spec))
  }
  sprintf(paste0(first,
    "The MANOVA approach, which doesn't need sphericity, has %s power with %s participants; ",
    "if you plan to report it instead, plan for it."),
    percent(m$power), whole(m$n))
}

# One SD and one correlation for every pair keep sphericity; an SD per cell
# or a correlation per pair need not (E54, E55, E20).
assumes_sphericity <- function(spec) {
  length(unlist(spec$population$sd)) <= 1 && length(unlist(spec$population$r)) <= 1
}

sphericity_correction_words <- function(spec) {
  switch(spec$target_test$correction %||% "none",
    none = "with no correction", GG = "with the Greenhouse-Geisser correction", HF = "with the Huynh-Feldt correction")
}

# Invariance, a factor correlation, a latent slope: the test, and the
# model it is tested in.
sem_test_name <- function(spec) {
  pop <- spec$population
  switch(
    spec$template,
    invariance = {
      where <- if (identical(pop$over, "occasions")) "on the two occasions" else "in the two groups"
      if (identical(pop$level, "metric")) {
        sprintf("the chi-square difference test of metric invariance (equal loadings %s, against the configural model)", where)
      } else {
        sprintf("the chi-square difference test of scalar invariance (equal intercepts %s, against the metric model)", where)
      }
    },
    factor_correlation = "the chi-square difference test of the correlation between the two factors against zero",
    latent_regression = sprintf("the chi-square difference test of %s against zero",
      if (length(pop$slopes) == 1) "the latent slope" else sprintf("predictor %s's latent slope", pop$tested %||% 1))
  )
}

sem_model_description <- function(spec) {
  pop <- spec$population
  items <- function(k) sprintf("%s item%s", whole(k), if (k == 1) "" else "s")
  switch(
    spec$template,
    invariance = sprintf("one factor measured by %s (standardised loading %s) %s, with %s of them %s %s",
      items(pop$indicators), format(pop$loading),
      if (identical(pop$over, "occasions")) sprintf("on two occasions (the factor correlating %s between them)", format(pop$stability)) else "in two groups",
      whole(pop$noninvariant),
      if (identical(pop$level, "metric")) sprintf("loading %s", format(pop$loading_group2))
      else sprintf("having intercepts %s %s item SDs", if (pop$intercept_difference < 0) "lower by" else "higher by", format(abs(pop$intercept_difference))),
      if (identical(pop$over, "occasions")) "on the second occasion" else "in the second group"),
    factor_correlation = sprintf("two factors measured by %s and %s (standardised loadings %s and %s), correlating %s",
      items(pop$indicators[[1]]), items(pop$indicators[[2]]), format(pop$loadings[[1]]), format(pop$loadings[[2]]), format(pop$r)),
    latent_regression = {
      k <- length(pop$slopes)
      sprintf("a latent outcome regressed on %s latent predictor%s (standardised slope%s %s%s), every factor measured by %s (standardised loading %s)",
        whole(k), if (k == 1) "" else "s", if (k == 1) "" else "s", paste(vapply(pop$slopes, format, ""), collapse = ", "),
        if (k > 1) sprintf("; the predictors correlating %s", format(pop$predictor_correlation %||% 0)) else "",
        items(pop$indicators), format(pop$loading))
    }
  )
}

sem_restriction_sentence <- function(spec) {
  sprintf("The model: %s. Power is that of %s, fitted to the whole model by maximum likelihood.",
    sem_model_description(spec), sem_test_name(spec))
}

sem_wording <- function(text) {
  text <- gsub("the true effect is the one you entered", "the model is wrong by the amount you entered", text, fixed = TRUE)
  text <- gsub("If the true effect is smaller", "If the misfit is smaller", text, fixed = TRUE)
  gsub("the effect you entered", "the misfit you entered", text, fixed = TRUE)
}

# Structural equation model fit: what "the effect" is here (misfit, as an
# RMSEA), the model's degrees of freedom from the engine's sem_summary(),
# and that this is power to reject the model.
sem_model_text <- function(s) {
  if (is.null(s$indicators)) return(sprintf("a model with %s degrees of freedom", whole(s$df)))
  sprintf("a CFA of %s items on %s correlated factor%s (%s degrees of freedom)",
    whole(s$indicators), whole(s$factors), if (s$factors == 1) "" else "s", whole(s$df))
}

sem_sentence <- function(result) {
  s <- result$sem
  if (is.null(s)) return(NULL)
  sprintf(paste0(
    "The effect here is misfit: power is the chance that the test rejects %s if the model is wrong by an RMSEA of %s in the population. ",
    "A model that is not rejected is not shown to be right; with too few people, even a poor model is rarely rejected."),
    sem_model_text(s), format(s$rmsea))
}

sem_writeup <- function(result) {
  s <- result$sem
  if (is.null(s)) return(NULL)
  sprintf("The model was %s, and the misfit to detect was a population RMSEA of %s.", sem_model_text(s), format(s$rmsea))
}

# Clustered designs: what the grouping costs, from the engine's
# cluster_summary() (the design effect and the effective sample size).
cluster_sentence <- function(result) {
  s <- result$clusters
  if (is.null(s)) return(NULL)
  n <- s$clusters * s$cluster_size
  if (identical(s$assignment, "one_condition")) {
    return(sprintf(paste0(
      "Only the condition delivered in groups is clustered: people in the same group tend to be alike (intraclass correlation %s), ",
      "so each of its groups of %s counts for less than %s separate people (a design effect of %s in that condition). ",
      "Over the whole study, these %s participants carry about as much information as %s participants randomised and treated one by one would. ",
      "Adding groups usually raises power more than adding people to each group."),
      format(s$icc), whole(s$cluster_size), whole(s$cluster_size), format(round(s$grouped_design_effect, 2), nsmall = 2),
      whole(2 * n), whole(floor(s$effective_n))))
  }
  if (identical(s$outcome, "yes/no")) {
    what <- if (identical(s$assignment, "people")) "how much the effect varies between groups" else "how much the groups' proportions differ"
    return(sprintf(paste0(
      "People in the same group tend to be alike, so the grouping costs power. For a yes/no outcome, powertools allows for it through %s ",
      "(an SD of %s on the log-odds scale; the R script prints a table to check that value is plausible). ",
      "Adding groups usually raises power more than adding people to each group."),
      what, format(s$sigma_u)))
  }
  varying <- if (s$relative_efficiency < 1) " (more, because the group sizes vary)" else ""
  paste0(cluster_score_sentence(s, n, varying), cluster_baseline_sentence(s))
}

# With a baseline score: what the adjustment gains, in the design effect.
cluster_baseline_sentence <- function(s) {
  if (!isTRUE(s$baseline)) return("")
  sprintf(" The design effect includes the adjustment for the baseline score; without it, it would be %s.",
          format(round(s$design_effect_without_baseline, 2), nsmall = 2))
}

cluster_score_sentence <- function(s, n, varying) {
  if (identical(s$assignment, "people")) {
    return(sprintf(paste0(
      "Every group has people in both conditions, so differences between the groups' averages (intraclass correlation %s) cancel out of the comparison; ",
      "what costs power is the effect varying between groups (%s of the outcome's variation). ",
      "The design effect is %s%s: these %s participants carry about as much information as %s participants randomised one by one would. ",
      "Adding groups usually raises power more than adding people to each group."),
      format(s$icc), format(s$icc_effect),
      format(round(s$design_effect, 2), nsmall = 2), varying, whole(n), whole(floor(s$effective_n))))
  }
  sprintf(paste0(
    "People in the same group tend to be alike (intraclass correlation %s), so each group of %s counts for less than %s separate people. ",
    "The design effect is %s%s: these %s participants carry about as much information as %s independent participants would. ",
    "Adding groups usually raises power more than adding people to each group."),
    format(s$icc), whole(s$cluster_size), whole(s$cluster_size),
    format(round(s$design_effect, 2), nsmall = 2), varying, whole(n), whole(floor(s$effective_n)))
}

# The design effect for the write-up.
cluster_writeup <- function(result, spec = NULL) {
  s <- result$clusters
  if (is.null(s)) return(NULL)
  if (identical(s$assignment, "one_condition")) {
    return(sprintf("Participants were randomised individually and the second condition was delivered in groups of %s; with an intraclass correlation of %s in that condition, its design effect is %s (%s).",
      whole(s$cluster_size), format(s$icc), format(round(s$grouped_design_effect, 2), nsmall = 2),
      if (identical(s$outcome, "yes/no")) "a z test of the difference in proportions, powertools' irgtt.bin()" else "a t test with Satterthwaite degrees of freedom, powertools' irgtt.cont()"))
  }
  if (identical(s$outcome, "yes/no")) {
    return(sprintf("%s; the outcome was analysed as yes/no (a z test of the log odds ratio, powertools), with %s of %s on the log-odds scale and %s participants per group.",
      if (identical(s$assignment, "people")) "Participants were randomised within each group" else "Whole groups were assigned to the conditions",
      if (identical(s$assignment, "people")) "an SD of the effect across groups" else "an SD of the groups' log odds",
      format(s$sigma_u), whole(s$cluster_size)))
  }
  baseline <- cluster_baseline_writeup(s, spec)
  if (identical(s$assignment, "people")) {
    return(paste0(sprintf("Participants were randomised within each group; with an intraclass correlation of %s, %s of the outcome's variance from the effect varying between groups and %s participants per group%s, the design effect is %s.",
      format(s$icc), format(s$icc_effect), whole(s$cluster_size), if (s$relative_efficiency < 1) " on average (group sizes varying)" else "",
      format(round(s$design_effect, 2), nsmall = 2)), baseline))
  }
  paste0(sprintf("With an intraclass correlation of %s and %s participants per group%s, the design effect is %s.",
    format(s$icc), whole(s$cluster_size), if (s$relative_efficiency < 1) " on average (group sizes varying)" else "",
    format(round(s$design_effect, 2), nsmall = 2)), baseline)
}

cluster_baseline_writeup <- function(s, spec) {
  if (!isTRUE(s$baseline) || is.null(spec)) return("")
  pop <- spec$population
  if (is.null(pop$baseline_r2_between)) {
    return(sprintf(" The analysis adjusts for a baseline score explaining %s of the outcome's variance (R-squared), which the design effect includes.",
                   format(pop$baseline_r2_within)))
  }
  sprintf(" The analysis adjusts for a baseline score explaining %s of the variance within groups and %s of the variance between the groups' averages (R-squared), which the design effect includes.",
          format(pop$baseline_r2_within), format(pop$baseline_r2_between))
}

# With the effect given in the outcome's own units: the standardised effect
# the engine worked out from them, and for the smallest detectable effect,
# that effect as a difference in the outcome's units (both from the
# engine's result).
units_sentence <- function(result) {
  u <- result$effect_from_units
  if (is.null(u)) return(NULL)
  round3 <- function(x) format(round(x, 3), nsmall = 2)
  # A point-biserial r: the d worked out from it, or the smallest r.
  if (!is.null(u$r)) {
    share <- sprintf("%s%% of the sample in group 2", format(round(100 * u$share, 1)))
    if (!is.null(u$smallest_r)) {
      return(sprintf("As a point-biserial correlation, that is r = %s (with %s).", round3(u$smallest_r), share))
    }
    return(sprintf("From the point-biserial r of %s you entered, powerkit worked out Cohen's d = %s (with %s), which gives the same test as G*Power's point-biserial model.",
      format(u$r), round3(u$value), share))
  }
  if (!is.null(u$smallest_difference)) {
    return(sprintf("In your outcome's own units, that is a difference of %s (%s × %s, %s).",
      round3(u$smallest_difference), round3(result$sensitivity$effect), format(signif(u$sd, 4)), u$sd_name))
  }
  out <- sprintf("From the means and SD you entered, powerkit worked out %s = %s: a difference of %s divided by %s (%s).",
    u$name, round3(u$value), format(signif(u$difference, 4)), u$sd_name, format(signif(u$sd, 4)))
  # Equivalence tests: the bound, divided by the same SD.
  if (!is.null(u$bound)) out <- paste(out, sprintf("The equivalence bound of %s is %s in the same units.", format(signif(u$bound, 4)), round3(u$bound_value)))
  out
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
    },
    justified_alpha = {
      j <- result$justified_alpha
      c(
        headline = sprintf(
          "With %s participants in total%s, the significance level that %s is alpha = %s. At that level, %s has %s power to detect the effect you entered.",
          whole(spec$goal$n), group_text(spec, spec$goal$n), justified_alpha_rule_text(j), justified_alpha_text(j$alpha),
          justified_alpha_test_text(spec), percent(j$power)
        ),
        detail = sprintf(
          "%s At the usual alpha = %s, power would be %s. Found by JustifyAlpha's optimal_alpha(), which searches over alpha with power from pwr's formula (%s).",
          justified_alpha_weights_text(j), alpha_text(j$conventional_alpha), percent(j$conventional_power), exact_source(result)
        )
      )
    }
  )
}

# Justified alpha (JustifyAlpha's optimal_alpha()): the wording of the
# rule, the weights and the level found.
justified_alpha_rule_text <- function(j) {
  if (identical(j$error_rule, "balance")) "makes the two weighted errors equal" else "makes the weighted total of the two errors as small as possible"
}

justified_alpha_text <- function(alpha) format(signif(alpha, 3))

justified_alpha_weights_text <- function(j, brief = FALSE) {
  cost <- if (isTRUE(all.equal(j$cost_ratio, 1))) "A false positive was weighted the same as a missed effect" else
    sprintf("A false positive was weighted %s times as heavily as a missed effect", format(j$cost_ratio))
  odds <- if (isTRUE(all.equal(j$prior_odds, 1))) ", and the effect taken as being as likely to be real as not" else
    sprintf(", and the effect taken as %s times as likely to be real as not", format(j$prior_odds))
  if (brief) return(paste0(cost, odds))
  rate <- if (identical(j$error_rule, "balance")) "" else sprintf("; the weighted error rate is %s", percent(j$error_rate))
  sprintf("%s%s%s. The chance of a false positive is then %s and of missing the effect %s.", cost, odds, rate,
    percent(j$alpha), percent(j$beta))
}

# The test, without the alpha (the alpha is the answer).
justified_alpha_test_text <- function(spec) sub(" at alpha = .*$", "", test_text(spec))

# The plain reading of a target power (the new design, 18 October 2026):
# it keeps the condition, and says what power is a chance of. Out of 10
# when the power is a whole number of tenths (80%, 90%), otherwise out of
# 100, so 95% reads "95 in 100", not "10 in 10".
plain_reading <- function(power, outcome = "get a significant result",
                          if_not = "If the true effect is smaller, fewer would.",
                          condition = "the true effect is the one you entered") {
  tenths <- 10 * power
  count <- if (abs(tenths - round(tenths)) < 1e-9) {
    sprintf("%d in 10", as.integer(round(tenths)))
  } else {
    sprintf("%d in 100", as.integer(min(99, max(1, round(100 * power)))))
  }
  sprintf("In plain words: if %s, about %s studies like this would %s. %s", condition, count, outcome, if_not)
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

# Safeguard power, in words beside the result: the earlier estimate, the
# interval and the effect size the calculation used (worked out by the
# engine, with psych).
safeguard_sentence <- function(result) {
  sg <- result$safeguard
  if (is.null(sg)) return(NULL)
  sizes <- if (!is.null(sg$n1)) sprintf("%s and %s people in its two groups", sg$n1, sg$n2) else sprintf("%s people", sg$n)
  sprintf(paste0("Safeguard power: the earlier study's estimate was %s = %s, with %s. The calculation uses the lower end ",
    "of the %d%% confidence interval around it, %s = %s, so the study keeps its power if the true effect is that small ",
    "(a %d%% chance, if the earlier estimate is unbiased; Perugini, Gallucci & Costantini, 2014)."),
    sg$effect_name, format(round(sg$estimate, 3)), sizes, round(100 * sg$conf_level), sg$effect_name,
    format(round(sg$lower, 3), nsmall = 2), round(100 * sg$protection))
}

# An effect converted from another form, in words beside the result: what
# was published, what it became and the package function that did it
# (worked out by the engine).
conversion_sentence <- function(result) {
  conv <- result$effect_conversion
  if (is.null(conv)) return(NULL)
  sprintf("Effect size converted: the published %s of %s%s gives %s = %s, %s.",
    sub("^an? ", "", conv$from_name), format(conv$value), conversion_details(conv),
    conv$effect_name, format(round(conv$converted, 3), nsmall = 2), conversion_by(conv))
}

# The published statistic's df and group sizes, in brackets.
conversion_details <- function(conv) {
  parts <- c(if (!is.null(conv$df_error)) sprintf("error df %s", conv$df_error),
    if (!is.null(conv$n1) && !is.null(conv$n2)) sprintf("groups of %s and %s", conv$n1, conv$n2))
  if (length(parts)) sprintf(" (%s)", paste(parts, collapse = ", ")) else ""
}

# Which function converted it: psych's t2d() for a t or F statistic into d
# or d_z, effectsize's for the rest; or, for a plan saved before powerkit
# 0.24.1 converted t and F that way, the value the plan keeps.
conversion_by <- function(conv) {
  if (isTRUE(conv$earlier)) {
    return(sprintf("as an earlier version of powerkit converted it and the saved plan records (this version gives %s)",
      format(round(conv$now, 3), nsmall = 2)))
  }
  conversion_package_text(conv$package$name, conv$function_used)
}

conversion_package_text <- function(package, function_used) {
  fun <- sub("\\(.*", "", sub("^[A-Za-z.]+::", "", function_used))
  if (identical(package, "effectsize")) {
    sprintf("with the effectsize package's %s() (Ben-Shachar, L\u00fcdecke & Makowski, 2020)", fun)
  } else if (identical(fun, "t2d")) {
    # The formulas are Lakens's (2013, equations 2 and 7; refs.bib).
    sprintf("with the psych package's %s(), by the formula in Lakens (2013)", fun)
  } else {
    sprintf("with the %s package's %s()", package, fun)
  }
}

# "Does this still apply?" (the new design, 18 October 2026): if the effect
# size changes after the reasoning was written, the reasoning is kept but
# flagged until the user confirms it or edits it. app.R keeps the effect
# values the reasoning was written for; these helpers compare and word them.
effect_snapshot <- function(fields, values) {
  ids <- vapply(Filter(function(f) (isTRUE(f$effect) || isTRUE(f$in_effect_text) || isTRUE(f$conversion)) && field_applies(f, values), fields), `[[`, "", "id")
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
    "For comparison: 80%% power%s needs %s %s%s; 95%% power needs %s%s. Which you choose, and why, belongs in your plan.",
    together, whole(n80), n_unit(spec) %||% "participants", group_text(spec, n80), whole(n95), group_text(spec, n95)
  )
}

# The explore panel (the new design): power by sample size for any effect
# size the user tries, kept apart from the plan. The t-tests and the
# correlation by formula only for now. The app only calls the engine.
explore_effect <- function(spec) {
  if (!identical(spec$design, "basic_test") || identical(spec$options$method, "simulation") ||
      identical(spec$target_test$method, "welch_t") || is_rank_test(spec) || is_rank_correlation(spec)) return(NULL)
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

# A curve or scenario sets the effect itself, so no safeguard is applied
# to it.
without_safeguard <- function(spec) {
  if (!is.null(spec$effect_justification$safeguard)) {
    spec$effect_justification <- list(type = "smallest_effect_of_interest")
  }
  spec
}

explore_curve <- function(spec, result, effect, run = engine_function("run_spec"), seed = 1L) {
  e <- explore_effect(spec)
  ns <- explore_sizes(spec, result)
  power <- vapply(ns, function(n) {
    s <- spec
    # The slider is in standardised units, whatever units the plan used.
    s$population <- stats::setNames(list("standardised", effect), c("metric", e$field))
    s <- without_safeguard(s)
    s$goal <- list(type = "power", n = as.integer(n))
    calc <- run_calculation(s, run, seed)
    if (identical(calc$status, "ok")) calc$result$curve$power[1] else NA_real_
  }, numeric(1))
  data.frame(n = ns, power = power)
}

explore_ui <- function(spec, result = NULL) {
  e <- explore_effect(spec)
  if (is.null(e)) return(NULL)
  planned <- result$safeguard$lower %||% result$effect_conversion$converted %||% result$effect_from_units$value %||% spec$population[[e$field]]
  start <- if (is.null(planned) || planned == 0) 0.3 else abs(planned)
  div(class = "explore-panel",
    h5(class = "h6", "If the effect were different"),
    p(class = "small", "Move the slider: the line shows power at each sample size for that effect, and the circle marks your plan. Exploring doesn't change your plan."),
    sliderInput("explore_effect", e$label, min = 0.05, max = e$max, value = round(start, 2), step = 0.01, width = "100%"),
    plotOutput("explore_plot", height = "300px")
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
  result$safeguard$lower %||% result$effect_conversion$converted %||% result$effect_from_units$value %||% spec$population[[e$field]]
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
      s <- without_safeguard(s)
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
    s <- without_safeguard(s)
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
    h5(class = "h6", "A cautious and a hopeful guess"),
    p(class = "small", sprintf(paste0(
      "Your plan uses %s = %s. Enter a smaller effect you would still find plausible (conservative) and a larger one (optimistic), ",
      "and powerkit draws power for all three. Choose values you could defend; powerkit won't suggest them."),
      e$label, format(round(planned, 3)))),
    div(class = "d-flex gap-3 flex-wrap",
      numericInput("scenario_conservative", sprintf("Conservative %s", e$label), value = NA, step = 0.01, width = "14rem"),
      numericInput("scenario_optimistic", sprintf("Optimistic %s", e$label), value = NA, step = 0.01, width = "14rem")),
    conditionalPanel("input.scenario_conservative != null || input.scenario_optimistic != null",
      plotOutput("scenario_plot", height = "300px"),
      uiOutput("scenario_n")))
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
  if (!identical(values$just_type, "prior_study") || identical(values$sg_use, "yes")) return(NULL)
  "Your effect size comes from one earlier study. Published effects from single studies tend to be larger than the true effect, so a sample size based on one can be too small. Adjusting it (and saying how) helps; the BUCSS R package offers a bias-corrected approach."
}

# The power the reported N actually gives (judgement-calls.md G5; the
# maintainer's decision of 17 October 2026). Rounding up to whole people,
# and to equal groups, puts it at or a little above the target. Exact
# results only: the engine's curve holds the exact power at the reported
# N. A simulated N comes from a fitted curve, with no simulation at
# exactly that N, so nothing is shown for it.
actual_power_sentence <- function(spec, result) {
  if (!identical(result$goal_type, "sample_size")) return(NULL)
  n <- result$n_required$n
  # A simulated required n: the power the fitted curve gives there, with
  # its 95% interval (run_spec()'s n_required).
  fitted <- simulated(result)
  at_n <- if (fitted) result$n_required$power %||% NA_real_ else result$curve$power[result$curve$n == n]
  if (length(at_n) != 1 || is.na(at_n)) return(NULL)
  sizes <- group_sizes(spec, n)
  who <- if (!is.null(n_unit(spec))) {
    sprintf("With %s %s", whole(n), n_unit(spec))
  } else if (is.null(sizes)) {
    sprintf("With %s participants", whole(n))
  } else if (length(unique(sizes)) == 1) {
    unit <- if (identical(spec$template, "2x2_between")) "per cell" else "per group"
    sprintf("With %s %s", whole(sizes[1]), unit)
  } else {
    sprintf("With %s in group 1 and %s in group 2", whole(sizes[1]), whole(sizes[2]))
  }
  if (fitted) {
    return(sprintf(
      "%s, power is about %.1f%% (95%% interval %.1f%% to %.1f%%, from the curve fitted to the simulations).",
      who, 100 * at_n, 100 * result$n_required$power_lower, 100 * result$n_required$power_upper
    ))
  }
  sprintf("%s, power is %.1f%%.", who, 100 * at_n)
}

# A yes/no predictor's correlation with Y, read as the difference between
# its groups (E15): the engine works it out (implied_group_difference(),
# psych::r2d() for equal groups); this only words it.
group_difference_note <- function(spec) {
  entries <- tryCatch(engine_function("implied_group_difference")(spec), error = function(e) NULL)
  if (!length(entries)) return(NULL)
  label <- function(role) spec$variables[[role]]$label %||% role
  number <- function(x) formatC(x, digits = 2, format = "f")
  vapply(entries, function(d) {
    split <- if (isTRUE(all.equal(d$p, 0.5))) "two equal groups" else sprintf("%s%% in %s", round(100 * d$p), d$levels[2])
    if (identical(d$kind, "correlation")) {
      sprintf(
        "A correlation of %s between %s and %s means that %s differs from %s by d = %s SDs of %s, averaged over the other predictor (%s). The interaction is what is tested.",
        number(d$r), d$label, label(d$outcome), d$levels[2], d$levels[1], number(d$d), label(d$outcome), split
      )
    } else {
      sprintf(
        "A standardised path of %s from %s to %s means that %s differs from %s by d = %s SDs of %s (%s).",
        number(d$r), d$label, label(d$outcome), d$levels[2], d$levels[1], number(d$d), label(d$outcome), split
      )
    }
  }, character(1))
}

# Technical details, for checking a result against G*Power or R: the
# test's statistic, degrees of freedom, critical value and noncentrality,
# as the package reported them at the n analysed (run_spec()'s `details`).
# powerkit never computes them; where no package reports them, the section
# says so.
technical_details_ui <- function(result) {
  d <- result$details
  # Generic tests (E50) take the statistic and df from the user.
  if (is.null(d) && identical(result$goal_type, "power") && is.na(result$curve$n[1])) return(NULL)
  number <- function(x) trimws(formatC(x, digits = 3, format = "fg", big.mark = ","))
  lines <- if (simulated(result)) {
    list("Not applicable: this result was simulated, so there is no single critical value or noncentrality parameter. The reproducibility record gives the seed and replications, and the R script reruns every simulation.")
  } else if (identical(result$goal_type, "sensitivity")) {
    list("Not given for a sensitivity analysis, where the effect size is the answer rather than an input; calculate power at that effect to see them.")
  } else if (is.null(d)) {
    list(sprintf("Not reported for this design: %s doesn't return them.", result$provenance$backend))
  } else {
    stat <- if (d$statistic == "chi-square") "Chi-square" else d$statistic
    df <- if (all(is.na(d$df))) NULL else if (length(d$df) == 2) {
      sprintf("Degrees of freedom: %s and %s.", number(d$df[1]), number(d$df[2]))
    } else {
      sprintf("Degrees of freedom: %s.", number(d$df))
    }
    critical <- if (d$statistic == "count") {
      sprintf("Critical counts: %s (as %s reports them). Because counts are whole numbers, the test's actual alpha is %.2f%%, not the alpha you set.",
        paste(number(d$critical), collapse = " and "), d$source, 100 * d$actual_alpha)
    } else if (length(d$critical) == 2 && isTRUE(all.equal(d$critical[1], -d$critical[2]))) {
      sprintf("Critical value: %s = ±%s (two-sided).", stat, number(d$critical[2]))
    } else {
      sprintf("Critical value: %s = %s.", stat, paste(number(d$critical), collapse = " and "))
    }
    ncp <- if (is.na(d$ncp)) NULL else if (d$statistic == "z") {
      sprintf("Noncentrality: the mean of z under your effect is %s.", number(d$ncp))
    } else {
      sprintf("Noncentrality parameter: %s.", number(d$ncp))
    }
    c(list(sprintf("Test statistic: %s.", stat)), list(df), list(critical), list(ncp),
      list(sprintf("Reported by %s at N = %s.", d$source, whole(n_analysed(result)))))
  }
  tags$details(class = "result-more result-technical",
    tags$summary("Technical details (for checking against G*Power or R)"),
    tags$ul(lapply(Filter(Negate(is.null), lines), tags$li)),
    p(class = "small", "The R script (under \u201cWrite it up and save it\u201d) reproduces the whole calculation with the package alone."))
}

# The n the result is about: the required n, or the goal's n.
n_analysed <- function(result) {
  if (identical(result$goal_type, "sample_size")) result$n_required$n else result$curve$n[1]
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

# Pairwise comparisons after a one-way ANOVA (E18, E54): the chosen pair's
# t-test, adjusted across all the pairwise comparisons, simulated by the
# engine with Superpower's ANOVA_power().
is_pairwise <- function(spec) identical(spec$target_test$effect, "pairwise")

pairwise_test_name <- function(spec) {
  k <- length(unlist(spec$variables$A$levels))
  pair <- unlist(spec$target_test$comparison)
  adjust <- switch(spec$target_test$p_adjust %||% "holm",
    holm = "Holm's adjustment", bonferroni = "Bonferroni's adjustment", none = "no adjustment")
  sprintf("a %s comparing %s with %s, one of the %d pairwise comparisons, with %s for their number",
    if (identical(spec$template, "oneway_within")) "paired t-test" else "t-test", pair[1], pair[2], choose(k, 2), adjust)
}

# The rank tests (Wilcoxon signed-rank, Mann-Whitney, Kruskal-Wallis,
# Friedman): a test version on E1, E2, E3, E18 and E54, simulated by the
# engine with Spower.
is_rank_test <- function(spec) {
  isTRUE(spec$target_test$method %in% c("wilcoxon_signed_rank", "mann_whitney", "kruskal_wallis", "friedman"))
}

# The trend tests across groups in order: Jonckheere-Terpstra (E64) and
# Cochran-Armitage (E66).
is_trend_test <- function(spec) {
  identical(spec$target_test$method, "jonckheere_terpstra") || identical(spec$template, "proportion_trend")
}

# Spearman's rho and Kendall's tau: a test version on E4, simulated by the
# engine with Spower on scores of the chosen shape.
is_rank_correlation <- function(spec) isTRUE(spec$target_test$method %in% c("spearman", "kendall"))

rank_correlation_name <- function(spec) {
  sprintf("a test of %s, simulated assuming %s with Pearson's correlation as entered",
    if (identical(spec$target_test$method, "spearman")) "Spearman's rho" else "Kendall's tau",
    score_shape_text(spec$population$score_shape))
}

score_shape_text <- function(shape) {
  switch(shape %||% "normal",
    normal = "normally distributed scores",
    skewed = "skewed scores (a standardised chi-square distribution with 10 df)",
    heavy_tailed = "heavy-tailed scores (a t distribution with 3 df)")
}

rank_test_name <- function(spec) {
  test <- switch(spec$template,
    one_sample_t = "a one-sample Wilcoxon signed-rank test",
    paired_t = "a Wilcoxon signed-rank test of paired measurements",
    independent_t = "a Mann-Whitney (Wilcoxon rank-sum) test",
    oneway_between = "a Kruskal-Wallis test",
    oneway_within = "Friedman's test")
  shape <- score_shape_text(spec$population$score_shape)
  if (identical(spec$template, "paired_t")) shape <- sub("scores", "differences", shape)
  if (identical(spec$template, "oneway_within")) shape <- sub("scores", "deviations from each person's own level", shape)
  sprintf("%s, simulated assuming %s", test, shape)
}

# Bayes factor t-tests: a test version on E1, E2 and E3, calculated by
# the engine with bfpwr. There is no alpha: "power" is the chance that
# BF10 reaches the threshold.
is_bayes_test <- function(spec) identical(spec$target_test$method, "bayes_factor")

bayes_settings_text <- function(spec) {
  tt <- spec$target_test
  if (is_bayes_binomial(spec)) {
    return(sprintf("strong evidence: BF10 of at least %s; Beta(%s, %s) prior%s",
      format(tt$evidence_threshold %||% 10), format(tt$prior_a %||% 1), format(tt$prior_b %||% 1),
      if (identical(tt$alternative %||% "two_sided", "two_sided")) "" else if (identical(tt$one_sided_null, "directional"))
        "; at or below the fixed value against above it" else "; the fixed value against one side, as in JASP"))
  }
  sprintf("strong evidence: BF10 of at least %s; Cauchy prior scale %s",
    format(tt$evidence_threshold %||% 10), format(signif(tt$prior_scale %||% (1 / sqrt(2)), 3)))
}

is_bayes_binomial <- function(spec) is_bayes_test(spec) && identical(spec$template, "one_proportion")

bayes_test_name <- function(spec) {
  switch(spec$template,
    one_proportion = "a Bayes factor test of one proportion",
    one_sample_t = "a one-sample Bayes factor t-test",
    paired_t = "a paired-samples Bayes factor t-test",
    independent_t = "an independent-samples Bayes factor t-test")
}

# Results in Bayes factor terms: what the chance is a chance of, and what
# the same sample would show if there were no effect (from the engine's
# bayes summary).
bayes_wording <- function(text) {
  text <- gsub("would get a significant result with", "would find strong evidence for the effect with", text, fixed = TRUE)
  text <- gsub("would get a significant result", "would find strong evidence for the effect", text, fixed = TRUE)
  text <- gsub("([0-9]+%) power to detect the effect you entered", "a \\1 chance of strong evidence for the effect you entered (its power)", text)
  text <- gsub("the study has ([0-9]+%) power", "the study has a \\1 chance of strong evidence (its power)", text)
  # "an 80%", "an 11%", "an 18%".
  gsub("\\ba ((8[0-9]?|11|18)%)", "an \\1", text, perl = TRUE)
}

bayes_sentence <- function(spec, result) {
  b <- result$bayes
  if (is.null(b)) return(NULL)
  k <- format(b$evidence_threshold)
  c(
    if (b$effect_sd > 0) sprintf(paste(
      if (is_bayes_binomial(spec)) "This averages over true proportions spread around yours with an SD of %s (a beta design prior), so it is the study's assurance:" else
      "This averages over true effects spread around yours with an SD of %s (the design prior), so it is the study's assurance:",
      "the chance of strong evidence given what you believe now, rather than if one guessed effect were exactly right",
      "(O'Hagan, Stevens and Campbell, 2005)."), format(b$effect_sd)),
    if (b$evidence_for_null > 0) sprintf(
      "If there were no effect, a study of %s would give strong evidence that there is none (BF01 of at least %s) %s of the time, and misleading strong evidence for an effect %s of the time.",
      whole(b$n), k, percent(b$evidence_for_null), percent(b$misleading_evidence)
    ) else sprintf(
      "If there were no effect, a study of %s couldn't give strong evidence that there is none (BF01 of at least %s): it is too small for that, however the data fall. It would give misleading strong evidence for an effect %s of the time.",
      whole(b$n), k, percent(b$misleading_evidence)
    )
  )
}

departures_for <- function(forms, ep_id, spec) {
  keys <- unlist(forms$forms[[ep_id]]$departures)
  # Departure 1 is about the interaction's required N only.
  if (!identical(spec$target_test$effect, "interaction")) keys <- setdiff(keys, "1")
  # Departures 9, 10 and 11 (a formula for basic tests; Fisher's z for a
  # correlation; the z test for two proportions) apply only when the formula was used, not to simulation
  # or Welch's t-test (whose formula, pwrss's, is chosen by the user).
  if (identical(spec$options$method, "simulation") || identical(spec$target_test$method, "welch_t") || is_rank_test(spec) || is_rank_correlation(spec) || is_bayes_test(spec)) keys <- setdiff(keys, c("9", "10", "11"))
  # Departure 15 is about the Bayes factor tests' design prior, when the
  # user keeps powerkit's default (no uncertainty about the effect).
  if (!is_bayes_test(spec) || !isTRUE((spec$population$effect_sd %||% spec$population$p_sd %||% 0) == 0)) keys <- setdiff(keys, "15")
  # Departure 3 is about Superpower's exact dataset, which the
  # Kruskal-Wallis test and Welch's F (Spower) don't use.
  if (is_rank_test(spec) || identical(spec$target_test$method, "welch_f") || is_pairwise(spec)) keys <- setdiff(keys, "3")
  # Departure 16 (Satterthwaite's tests) is for a score on each trial; a
  # yes/no outcome is tested by glmer's Wald or likelihood-ratio test.
  if (identical(spec$variables$Y$type, "binary") && identical(spec$design, "mixed_model")) keys <- setdiff(keys, "16")
  # Departure 18 is about the Hartung-Knapp test, when it is used.
  if (!is_hartung_knapp(spec)) keys <- setdiff(keys, "18")
  # Departure 17 is about adjusting pairwise comparisons, when they are
  # adjusted.
  if (!is_pairwise(spec) || identical(spec$target_test$p_adjust %||% "holm", "none")) keys <- setdiff(keys, "17")
  # Fisher's exact test (E5's option) is pwrss's exact test: none of the z
  # test's departures, nor the continuity correction, apply.
  if (identical(spec$target_test$method, "fisher_exact")) keys <- setdiff(keys, c("5", "9", "10", "11"))
  # Departure 14 is about the smallest detectable d of a group treatment
  # trial with a score outcome only.
  if (!(identical(spec$template, "group_treatment") && identical(spec$population$metric, "standardised") &&
        identical(spec$goal$type, "sensitivity"))) keys <- setdiff(keys, "14")
  vapply(keys, function(k) forms$departures[[k]], character(1))
}

# `known_differences_if_method` limits a known difference to one test
# version (E5: Known difference 2 applies only to Fisher's exact test).
known_difference_keys <- function(forms, ep_id, spec = NULL) {
  form <- forms$forms[[ep_id]]
  keys <- unlist(form$known_differences)
  # Known difference 9 is about metapower, which the Hartung-Knapp test
  # doesn't use.
  # Known difference 9 is mpower()'s rounding of Fisher's z; mod_power()
  # doesn't round, and the Hartung-Knapp test is powerkit's simulation.
  if (!is.null(spec) && (isTRUE(is_hartung_knapp(spec)) || isTRUE(spec$template %in% c("subgroups", "dependent_effects", "meta_regression", "heterogeneity")))) keys <- setdiff(keys, "9")
  only <- form$known_differences_if_method
  keys <- Filter(function(k) is.null(only[[k]]) || identical(spec$target_test$method, only[[k]]), keys)
  # Some apply to one goal (Known difference 11, a justified alpha).
  by_goal <- form$known_differences_if_goal
  keys <- Filter(function(k) is.null(by_goal[[k]]) || identical(spec$goal$type, by_goal[[k]]), keys)
  # Some apply to one way of giving the effect (E9: Known difference 1 to
  # the correlations, which are simulated; 7 to the R-squared change).
  by_metric <- form$known_differences_if_metric
  keys <- Filter(function(k) is.null(by_metric[[k]]) || identical(spec$population$metric %||% "correlation", by_metric[[k]]), keys)
  # Some apply only when a population value is above 0 (E27's Known
  # difference 3, logistic regression with other predictors).
  above <- form$known_differences_if_above_zero
  keys <- Filter(function(k) is.null(above[[k]]) || isTRUE((spec$population[[above[[k]]]] %||% 0) > 0), keys)
  # Some apply only above a number of groups (E59's Known difference 8 to
  # MANOVA with three or more groups; two groups are calculated exactly).
  groups <- form$known_differences_if_groups_above
  keys <- Filter(function(k) is.null(groups[[k]]) || length(spec$variables$A$levels) > groups[[k]] || !is.null(spec$variables$B), keys)
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
# The answer as one figure (1 November 2026): the number a researcher came
# for, in large type, with what it is and what it assumes beside it. Only
# words the engine's result; NULL where a design has no single figure, and
# the sentence underneath says it all.
result_figure <- function(spec, result) {
  unit <- n_unit(spec) %||% "participants"
  fig <- tryCatch(switch(
    result$goal_type %||% "",
    sample_size = {
      n <- result$n_required$n
      if (is.null(n) || is.na(n)) NULL else list(value = whole(n), label = paste(unit, "in total"),
        sub = trimws(gsub("^ *\\(|\\) *$", "", group_text(spec, n))))
    },
    power = {
      row <- result$curve[1, ]
      if (is.null(row$power) || is.na(row$power)) NULL else list(value = percent(row$power), label = "power",
        sub = sprintf("with %s %s%s", whole(row$n), unit, group_text(spec, row$n)))
    },
    sensitivity = {
      s <- result$sensitivity
      if (is.null(s$effect) || is.na(s$effect)) NULL else {
        name <- if (!is.null(s$cohen_f)) "Cohen's f" else switch(s$effect_name %||% "", d = "d", d_z = "d_z", r = "r", w = "w", p2 = "group 2's proportion", "effect")
        value <- if (!is.null(s$cohen_f)) sprintf("%.3f", s$cohen_f) else format(round(s$effect, 3), nsmall = 2)
        list(value = value, label = if (identical(name, "group 2's proportion")) "group 2's proportion you could detect" else paste("the smallest", name, "you could detect"),
          sub = sprintf("with %s %s, at %s power", whole(spec$goal$n), unit, percent(spec$goal$power)))
      }
    },
    justified_alpha = {
      j <- result$justified_alpha
      if (is.null(j$alpha)) NULL else list(value = justified_alpha_text(j$alpha), label = "the justified alpha",
        sub = sprintf("with %s %s; power at that level %s", whole(spec$goal$n), unit, percent(j$power)))
    },
    NULL), error = function(e) NULL)
  if (is.null(fig)) return(NULL)
  if (is_dyadic(spec)) fig <- lapply(fig, function(x) gsub("participants", "pairs", x, fixed = TRUE))
  if (is_bayes_test(spec)) fig <- lapply(fig, bayes_wording)
  if (is_sem_fit(spec)) fig <- lapply(fig, sem_wording)
  if (!nzchar(fig$sub %||% "")) fig$sub <- NULL
  fig
}

# What the figure assumes, as short tags beside it: the effect, the test
# and the target power (or the sample size it was given).
result_assumptions <- function(spec, result, fields, values) {
  test <- test_text(spec)
  out <- c(
    effect = writeup_effect(fields, values) %||% NA_character_,
    test = paste0(toupper(substr(test, 1, 1)), substr(test, 2, nchar(test))),
    target = if (!is.null(spec$goal$power) && !identical(result$goal_type, "power")) sprintf("Target power %s", percent(spec$goal$power)) else NA_character_
  )
  out <- out[!is.na(out) & nzchar(out)]
  if (is_bayes_test(spec)) out[] <- vapply(out, bayes_wording, character(1))
  out
}

result_hero_ui <- function(spec, result, fields, values) {
  fig <- result_figure(spec, result)
  if (is.null(fig)) return(NULL)
  assumes <- result_assumptions(spec, result, fields, values)
  div(class = "result-hero",
    div(class = "result-figure",
      tags$span(class = "result-figure-value", fig$value),
      tags$span(class = "result-figure-label", fig$label),
      if (!is.null(fig$sub)) tags$span(class = "result-figure-sub", fig$sub)),
    if (length(assumes)) div(class = "result-assumes",
      tags$span(class = "result-assumes-title", "Assuming"),
      tags$ul(lapply(unname(assumes), tags$li))))
}

# The sections of a result, as links along its top.
result_sections_ui <- function(items) {
  tags$nav(class = "result-sections", `aria-label` = "Parts of this result",
    lapply(names(items), function(id) tags$a(href = paste0("#", id), onclick = sprintf(
      "var e = document.getElementById('%s'); if (e) { e.scrollIntoView({behavior: 'smooth', block: 'start'}); } return false;", id), items[[id]])))
}

# A power curve drawn in powerkit's style: power by N, the target power,
# and the plan's N marked. `df` has n and power; more lines (scenarios)
# come as a list of data frames with their colours and labels.
power_curve_plot <- function(lines, target = NULL, planned_n = NULL, xlab = "Participants analysed") {
  navy <- "#14284B"; grid <- "#e3e7ef"; ink <- "#4a5568"
  ns <- unlist(lapply(lines, function(l) l$df$n))
  op <- par(mar = c(4.4, 4.6, 1.2, 1.2), mgp = c(2.8, 0.7, 0), family = "sans", col.axis = ink, col.lab = ink, cex.lab = 1.05)
  on.exit(par(op))
  plot(NA, xlim = range(c(ns, planned_n), na.rm = TRUE), ylim = c(0, 1), axes = FALSE, xlab = xlab, ylab = "Power")
  abline(h = seq(0, 1, 0.2), col = grid, lwd = 1)
  axis(1, col = NA, col.ticks = grid, tcl = -0.3)
  axis(2, at = seq(0, 1, 0.2), labels = paste0(seq(0, 100, 20), "%"), las = 1, col = NA, col.ticks = NA)
  if (!is.null(target)) {
    abline(h = target, col = "#d08a1c", lty = 2, lwd = 1.5)
    text(par("usr")[2], target, sprintf("Target %s", percent(target)), adj = c(1, -0.5), col = "#a0660a", cex = 0.85)
  }
  for (l in lines) {
    d <- l$df[order(l$df$n), ]
    d <- d[!is.na(d$power), ]
    if (isTRUE(l$fill) && nrow(d) > 1) polygon(c(d$n, rev(d$n)), c(d$power, rep(0, nrow(d))), col = grDevices::adjustcolor(l$col, 0.08), border = NA)
    lines(d$n, d$power, col = l$col, lwd = 3, lty = l$lty %||% 1)
  }
  if (!is.null(planned_n) && !is.na(planned_n) && length(lines)) {
    d <- lines[[1]]$df
    d <- d[order(d$n) & !is.na(d$power), ]
    if (nrow(d) > 1 && planned_n >= min(d$n) && planned_n <= max(d$n)) {
      y <- stats::approx(d$n, d$power, xout = planned_n)$y
      segments(planned_n, 0, planned_n, y, col = navy, lty = 3, lwd = 1.5)
      points(planned_n, y, pch = 21, bg = "#ffffff", col = navy, cex = 1.8, lwd = 2.5)
      text(planned_n, y - 0.1, sprintf("Your plan: %s", whole(planned_n)), pos = 4, offset = 0.6, col = navy, font = 2, cex = 0.9)
    }
  }
  invisible()
}

result_panel_ui <- function(tree, forms, ep_id, fields, values, calc, check_advice = character()) {
  # Dyadic data: every count of the sample on the screen counts pairs.
  if (identical(calc$status, "ok") && is_dyadic(calc$spec)) {
    panel <- result_panel_core(tree, forms, ep_id, fields, values, calc, check_advice)
    return(HTML(gsub("([0-9][0-9,]*) participants", "\\1 pairs", as.character(panel))))
  }
  result_panel_core(tree, forms, ep_id, fields, values, calc, check_advice)
}

result_panel_core <- function(tree, forms, ep_id, fields, values, calc, check_advice = character()) {
  if (!identical(calc$status, "ok")) {
    return(div(class = "form-problems", role = "alert", tabindex = "-1",
      h3(class = "h5", "The calculation didn't finish"), p(calc$message)))
  }
  if (is_precision(calc$spec)) return(precision_panel_ui(tree, forms, ep_id, fields, values, calc))
  ep <- tree$endpoints[[ep_id]]
  spec <- calc$spec
  result <- calc$result
  words <- result_sentences(spec, result)
  p_ <- result$provenance
  departures <- departures_for(forms, ep_id, spec)
  known <- known_differences_for(forms, ep_id, spec)
  folded <- names(departures) %in% unlist(forms$departures_folded)
  departures_in_view <- departures[!folded]
  notes <- unique(c(claim_result_note(values, spec$target_test$alpha, values$goal), source_note(values), group_difference_note(spec), check_advice, calc$notes))
  # The reasoning is needed to save or export, not to calculate.
  can_export <- !blank(values$just_source) && !isTRUE(values$source_stale)
  # In cards: the answer first, with notes on reading it; then exploring
  # it; then saving and the write-up; then how it was calculated, where
  # powerkit differs from the usual tools, and the technical records. The
  # details a reader rarely needs (the values used, the seed, what power
  # can't tell you) are folded under "More about this result".
  hero <- result_hero_ui(spec, result, fields, values)
  explore <- explore_ui(spec, result)
  scen <- scenarios_ui(spec, result)
  sections <- c(`result-answer` = "The answer",
    `result-sure` = if (!is.null(explore) || !is.null(scen) || !is.null(calc$curve_table)) "How sure can you be?",
    `result-take` = "Write it up and save it", `result-how-card` = "How it was calculated")
  div(
    class = "result-panel", role = "status", tabindex = "-1",
    result_sections_ui(as.list(sections[!is.na(sections)])),
    div(class = paste("result-card result-main", if (!is.null(hero)) "has-hero"), id = "result-answer",
    h3(class = "h4", "Your result"),
    hero,
    p(class = "result-headline lead", words[["headline"]]),
    if (!is.null(guess <- guess_line(values, result))) p(class = "result-guess", tags$strong(guess)),
    if (!is.na(words["reading"])) p(class = "result-reading", words[["reading"]]),
    if (!is.null(calc$cost_line)) p(class = "result-cost-line", calc$cost_line),
    if (!is.null(line <- reasoning_line(values))) p(class = "result-reasoning", line),
    if (!is.null(cv <- conversion_sentence(result))) p(class = "result-conversion", cv),
    if (!is.null(sg <- safeguard_sentence(result))) p(class = "result-safeguard", sg),
    source_stale_ui(fields, values),
    if (!is.null(actual <- actual_power_sentence(spec, result))) p(class = "result-actual-power", actual),
    if (!is.null(recruit <- recruitment_lines(result))) div(class = "result-recruitment",
      p(tags$strong(recruit[["analysed"]])), p(tags$strong(recruit[["recruit"]])),
      p(class = "small", recruit[["caveat"]])),
    p(class = "result-detail", words[["detail"]]),
    if (length(notes)) tagList(h4(class = "h6", "Notes"), tags$ul(class = "result-notes", lapply(notes, tags$li))),
    if (length(known) || length(departures_in_view)) p(class = "result-differs-pointer small",
      "Other established tools can give a slightly different answer for this design: see \u201cHow it was calculated\u201d below.")),
    if (!is.null(calc$curve_table) || !is.null(explore) || !is.null(scen)) div(class = "result-card result-sure", id = "result-sure",
      h4(class = "h5", "How sure can you be?"),
      p(class = "small", "The answer holds only if the effect is about the size you entered. See how it changes if the effect is smaller or larger. Nothing here changes your plan."),
      if (!is.null(calc$curve_table)) curve_table_ui(spec, result, calc$curve_table),
      explore,
      scen),
    div(class = "result-card result-save", id = "result-take",
    h4(class = "h5", "Write it up and save it"),
    writeup_ui(writeup_text(forms$forms[[ep_id]], spec, result, fields, values, departures,
      vapply(known_difference_keys(forms, ep_id, spec), function(k) forms$known_differences_methods[[k]], character(1)), known)),
    h4(class = "h6 mt-3", "Downloads"),
    if (!can_export && blank(values$just_source)) p(class = "export-needs-reasoning",
      tags$strong("To save this plan, download its R script or get its write-up, "),
      "write your reasoning under \u201cWhere your effect size comes from\u201d and press \u201cCheck my answers\u201d again. Exploring doesn't need it; a plan you keep or share does."),
    div(class = "nav-buttons",
      if (can_export) downloadButton("download_script", "Download R script", class = "btn btn-outline-primary"),
      downloadButton("download_citations", "Citations", class = "btn btn-outline-primary"),
      if (can_export) downloadButton("download_project", "Save project", class = "btn btn-outline-primary")),
    if (can_export) uiOutput("study_plan_bar"),
    p(class = "small", "The R script reproduces this result with ", p_$backend, " alone (powerkit isn't needed). Citations lists the package's own citation(), its method paper and the software used. Save project keeps your answers, values, seed and result in one file on your computer; open it from the start screen to carry on or reproduce the result."),
    simulated_data_ui(spec, result)),
    div(class = "result-card result-how", id = "result-how-card",
    h4(class = "h5", "How it was calculated"),
    if (simulated(result)) p(class = "result-simulation", simulation_note(result)),
    p(class = "result-credit",
      "Calculated by the R package ", tags$strong(p_$backend), sprintf(" (version %s), with %s. ", p_$packages[[p_$backend]], p_$backend_function),
      if (p_$backend %in% c("pwr", "stats", "pwrss", "powertools")) "powerkit built the call from your answers and checked the effect size it passes. " else
        "powerkit built the call from your answers and checked that it reproduces the population you entered. ",
      "Cite the package: see Citations above."),
    validation_ui(ep),
    technical_details_ui(result),
    if (length(departures_in_view)) tagList(
      h4(class = "h6", "Where powerkit differs from the tool's defaults"),
      tags$ul(class = "result-departures", lapply(unname(departures_in_view), tags$li))
    ),
    if (any(folded)) tags$details(class = "result-more result-departures-minor",
      tags$summary("Small differences from the tools' defaults, which don't change the answer in practice"),
      tags$ul(class = "result-departures", lapply(unname(departures[folded]), tags$li))),
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
      p(class = "result-limits small", if (is_bayes_test(spec)) bayes_wording(power_limits) else power_limits)),
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
    value <- trimws(as.character(values[[f$id]]))
    # A table (one line per row) reads as bracketed rows on one line.
    if (identical(f$type, "table")) {
      rows <- trimws(strsplit(value, "\n", fixed = TRUE)[[1]])
      value <- paste0("(", rows[nzchar(rows)], ")", collapse = ", ")
    }
    out <- c(out, sprintf("%s = %s", f$writeup_label %||% f$label, value))
  }
  if (length(out)) paste(out, collapse = "; ") else NULL
}

writeup_sides <- function(spec) {
  alt <- spec$target_test$alternative %||% "two_sided"
  if (is_trend_test(spec) && alt != "two_sided") return(sprintf("one-sided, a %s trend", if (alt == "greater") "rising" else "falling"))
  switch(alt, two_sided = "two-sided", greater = "one-sided, effect positive", less = "one-sided, effect negative")
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
  fun <- if (grepl("(", p$backend_function, fixed = TRUE)) p$backend_function else paste0(p$backend_function, "()")
  s <- sprintf("Power was calculated %s, with the R package %s (version %s; %s), set up by powerkit (version %s) in %s.",
    how, p$backend, p$packages[[p$backend]], fun, p$packages[["powerkit"]], p$r_version)
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
    any = if (!is.null(spec$target_test$alpha)) sprintf("The claim is supported if any one of %s tests is significant, so alpha was divided by %s (Bonferroni), giving α = %s for this test.",
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

# A meta-analysis's effect for the write-up: the average effect, with what
# it is measured in, the study size and the heterogeneity.
meta_effect_text <- function(spec) {
  pop <- spec$population
  if (identical(spec$template, "subgroups")) {
    return(sprintf("average effects of %s = %s in %d kinds of study (the studies split equally between them), in studies of %s participants each with I-squared = %s",
      if (identical(pop$metric, "r")) "r" else "Cohen's d", paste(format(as.numeric(unlist(pop$effects))), collapse = ", "),
      length(unlist(pop$effects)), whole(pop$study_size), format(pop$i2)))
  }
  sprintf("an average effect of %s = %s, in studies of %s participants each with I-squared = %s",
    if (identical(pop$metric, "r")) "r" else "Cohen's d", format(pop$effect), whole(pop$study_size), format(pop$i2))
}

# The write-up's sample-size sentences, for a number of studies.
meta_units <- function(text) {
  text <- gsub(" participants are needed in total", " studies are needed", text, fixed = TRUE)
  text <- gsub("power at this sample size is", "power with this many studies is", text, fixed = TRUE)
  text <- gsub("for an effect of an average effect", "for an average effect", text, fixed = TRUE)
  text <- gsub("at a (fixed )?sample size of ([0-9,]+) participants in total", "with \\2 studies", text)
  text
}

# Returns c(short = ..., full = ...), or NULL when there is no reasoning
# (the write-up, like saving, needs it).
writeup_text <- function(form, spec, result, fields, values, departures = character(), known_methods = character(), known = character()) {
  if (blank(values$just_source) || isTRUE(values$source_stale)) return(NULL)
  name <- form$methods_name
  if (identical(spec$target_test$method, "welch_t")) name <- paste0(name, " (Welch's)")
  if (identical(spec$target_test$method, "fisher_exact")) name <- "Fisher's exact test of two proportions"
  if (is_rank_test(spec)) name <- rank_test_name(spec)
  if (is_rank_correlation(spec)) name <- rank_correlation_name(spec)
  if (identical(spec$target_test$method, "welch_f")) name <- "Welch's one-way ANOVA (F test not assuming equal variances)"
  if (is_pairwise(spec)) name <- pairwise_test_name(spec)
  if (is_meta(spec)) name <- meta_methods_name(spec)
  # A sphericity correction (E54, when the SDs or correlations differ).
  correction <- spec$target_test$correction %||% "none"
  if (!identical(correction, "none") && !is_pairwise(spec)) {
    name <- sprintf("%s with the %s correction for sphericity", name, c(GG = "Greenhouse-Geisser", HF = "Huynh-Feldt")[[correction]])
  }
  if (is_bayes_test(spec)) name <- bayes_test_name(spec)
  if (is_minimum_effect(spec)) name <- sprintf("%s as a minimum-effect test against a smallest effect of interest of %s (pwrss's t-test against the margin)",
    name, minimum_effect_margin_text(spec))
  if (identical(spec$design, "sem") && !is_sem_fit(spec)) name <- sem_test_name(spec)
  if (spec$template %in% c("2x2_between", "2x2_mixed", "mixed", "factorial_between", "factorial_within", "factorial_ancova", "factorial_three")) name <- sprintf("%s (target effect: %s)", name, gsub("_", " ", spec$target_test$effect))
  equivalence <- identical(spec$design, "equivalence_test")
  if (equivalence) {
    name <- paste(name, switch(spec$template, tost_independent = "of two independent groups",
      tost_paired = "of two paired measurements", tost_one_sample = "of one mean against a fixed value",
      tost_correlation = "of a correlation (z tests on Fisher's z)", tost_two_proportions = "of two independent proportions (z tests)",
      noninf_independent = "of two independent groups", noninf_paired = "of two paired measurements",
      noninf_one_sample = "of one mean against a reference value", noninf_two_proportions = "of two independent proportions"))
    if (is_noninferiority(spec)) name <- sub("^an equivalence test \\(two one-sided tests, TOST\\)", "a non-inferiority test (one-sided, against the margin)", name)
  }
  # F and chi-square tests have no sides (forms.yaml, sides: false).
  sides <- if (isFALSE(form$sides)) NULL else writeup_sides(spec)
  generic <- identical(spec$design, "generic_test")
  if (generic) {
    # The statistic and its degrees of freedom; only t and z have sides.
    name <- paste("a generic", sub("^an? ", "", sub(" \\(two-sided.*| \\(one-sided.*| at alpha.*", "", generic_test_text(spec))))
    sides <- if (spec$template %in% c("t", "z")) writeup_sides(spec)
  }
  test <- if (!is.null(spec$target_test$alpha)) sprintf("%s (%s)", name, paste(c(sides, paste("α =", writeup_alpha(spec$target_test$alpha))), collapse = ", "))
  if (is_bayes_binomial(spec)) {
    tt <- spec$target_test
    test <- sprintf("%s (%s; a binomial Bayes factor with a Beta(%s, %s) prior on the proportion, testing %s, computed with bfpwr; strong evidence defined as BF10 ≥ %s)",
      name, sides, format(tt$prior_a %||% 1), format(tt$prior_b %||% 1), result$bayes$hypotheses %||% "", format(tt$evidence_threshold %||% 10))
  } else if (is_bayes_test(spec)) {
    tt <- spec$target_test
    test <- sprintf("%s (%s; a JZS Bayes factor with a Cauchy prior of scale %s, computed with bfpwr; strong evidence defined as BF10 ≥ %s)",
      name, sides, format(signif(tt$prior_scale %||% (1 / sqrt(2)), 3)), format(tt$evidence_threshold %||% 10))
  }
  if (equivalence) test <- if (is_noninferiority(spec)) {
    sprintf("%s (α = %s, one-sided; margin %s, %s values better)", name, writeup_alpha(spec$target_test$alpha), format(spec$population$margin), spec$population$better %||% "higher")
  } else sprintf("%s (each one-sided test at α = %s)", name, writeup_alpha(spec$target_test$alpha))
  power_line <- if (equivalence && is_noninferiority(spec)) {
    "Power to show non-inferiority (the new condition no worse than the margin allows), if the true difference is as expected, is %.1f%%."
  } else if (equivalence) {
    what <- if (identical(spec$template, "tost_correlation")) "correlation" else "difference"
    sprintf("Power to show equivalence (the %s lying inside the bounds), if the true %s is as expected, is %%.1f%%%%.", what, what)
  } else if (is_minimum_effect(spec)) {
    "Power to show the effect is larger than the smallest effect of interest, if it is as expected, is %.1f%%."
  } else "Power to detect this effect is %.1f%%."
  effect <- if (is_meta(spec)) meta_effect_text(spec) else writeup_effect(fields, values)
  # A converted effect: the published value, what it became and how.
  if (is.null(effect) && !is.null(conv <- result$effect_conversion)) {
    effect <- sprintf("%s = %s, converted from the published %s of %s%s %s",
      conv$effect_name, format(round(conv$converted, 3), nsmall = 2), sub("^an? ", "", conv$from_name), format(conv$value),
      conversion_details(conv), conversion_by(conv))
  }
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
    adj <- if (!blank(values$just_adjustment) && is.null(result$safeguard)) sprintf(" It was adjusted as follows: %s.", writeup_quote(values$just_adjustment)) else ""
    if (!is.null(sg <- result$safeguard)) {
      adj <- sprintf(paste0(" Following the safeguard power approach (Perugini, Gallucci & Costantini, 2014), the calculation used ",
        "the lower bound of the %d%% confidence interval around that estimate (%s, computed with the psych package's %s), %s = %s, ",
        "giving %d%% protection against the estimate being too large."),
        round(100 * sg$conf_level), if (!is.null(sg$n1)) sprintf("n = %s and %s", sg$n1, sg$n2) else sprintf("n = %s", sg$n),
        sub("\\(.*", "()", sub("^psych::", "", sg$function_used)), sg$effect_name, format(round(sg$lower, 3), nsmall = 2), round(100 * sg$protection))
    }
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
        basis, sprintf(power_line, 100 * row$power))
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
    },
    justified_alpha = {
      j <- result$justified_alpha
      c(sprintf("The significance level for %s was chosen by weighing the two errors (the R package JustifyAlpha, version %s, optimal_alpha()).",
          if (is.null(sides)) name else sprintf("%s (%s)", name, sides), result$provenance$packages[["JustifyAlpha"]] %||% "unknown"),
        sprintf("The sample size was %s %s participants in total%s.", if (fixed) "fixed by resource constraints at" else "set at",
          whole(spec$goal$n), group_text(spec, spec$goal$n)),
        basis,
        sprintf("%s, so alpha was set to %s the weighted errors: alpha = %s, giving %.1f%% power (at alpha = %s, power would be %.1f%%).",
          justified_alpha_weights_text(j, brief = TRUE),
          if (identical(j$error_rule, "balance")) "balance" else "minimise the total of",
          justified_alpha_text(j$alpha), 100 * j$power, writeup_alpha(j$conventional_alpha), 100 * j$conventional_power))
    }
  )
  if (is_bayes_test(spec)) {
    main <- gsub("Power to detect this effect is", "The probability of strong evidence for this effect (its power) is", main, fixed = TRUE)
    main <- gsub("For a target power of", "For a target probability of strong evidence of", main, fixed = TRUE)
    main <- gsub("; power at this sample size is", "; the probability at this sample size is", main, fixed = TRUE)
    main <- gsub("An a priori power analysis", "An a priori Bayes factor design analysis", main, fixed = TRUE)
    main <- gsub("A power analysis was conducted", "A Bayes factor design analysis was conducted", main, fixed = TRUE)
    main <- c(main, bayes_sentence(spec, result))
  }
  if (is_meta(spec)) main <- meta_units(main)
  if (is_dyadic(spec)) main <- dyad_units(main)
  main <- append(main, writeup_choices(fields, values), after = 1)
  main <- c(main, cluster_writeup(result, spec), if (is_sem_fit(spec)) sem_writeup(result),
            if (!is.null(result$manova)) {
              if (assumes_sphericity(spec)) sprintf("Assuming sphericity; the MANOVA approach (Pillai's trace), which does not, has %.1f%% power at this sample size.", 100 * result$manova$power)
              else sprintf("The F test used the SDs and correlations given, without assuming sphericity; the MANOVA approach (Pillai's trace) has %.1f%% power at this sample size.", 100 * result$manova$power)
            },
            if (identical(spec$design, "sem") && !is_sem_fit(spec)) sprintf("The model was %s.", sem_model_description(spec)))
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
  alpha <- if (is.null(spec$target_test$alpha)) NA_character_ else paste0(format(100 * spec$target_test$alpha), "%")
  fixed <- identical(values$situation, "fixed")
  effect <- if (is_meta(spec)) meta_effect_text(spec) else writeup_effect(fields, values)
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
  # Equivalence tests: the aim is to show the difference is too small to
  # matter.
  if (identical(spec$design, "equivalence_test") && is_noninferiority(spec)) chance <- function(p) sprintf(
    "If the real difference is the one we expect, the chance that a study of this size shows the new approach is no worse than the margin we set (one test, using a %s threshold) is %s, and the chance that it fails to show this is %s. If the real difference is closer to the margin, the chance of failing is higher.",
    alpha, percent(p), percent(1 - p))
  else if (identical(spec$design, "equivalence_test")) chance <- function(p) sprintf(
    "If the real difference is the one we expect, the chance that a study of this size shows it is too small to matter (inside the bounds we set, with two tests each using a %s threshold) is %s, and the chance that it fails to show this is %s. If the real difference is closer to a bound, the chance of failing is higher.",
    alpha, percent(p), percent(1 - p))
  # Bayes factor tests: strong evidence, not a significant result.
  if (is_bayes_test(spec)) chance <- function(p) sprintf(
    "If that effect is real, the chance that a study of this size finds strong evidence for it (a Bayes factor of at least %s in its favour) is %s, and the chance that it doesn't is %s. If the real effect is smaller, that chance is lower.",
    format(spec$target_test$evidence_threshold %||% 10), percent(p), percent(1 - p))
  # Model fit: the aim is to find out whether the model is wrong.
  if (is_sem_fit(spec)) chance <- function(p) sprintf(
    "If our model is wrong by the amount we set, the chance that a study of this size detects it (a statistically significant test of the model's fit, using a %s threshold) is %s, and the chance that it misses it is %s. Smaller errors in the model are more likely to be missed.",
    alpha, percent(p), percent(1 - p))
  include <- sprintf("We plan to include %s participants in the analysis%s.", whole(n), group_text(spec, n))
  if (is_meta(spec)) {
    include <- sprintf("We plan to include %s studies in the meta-analysis.", whole(n))
    chance <- function(p) sprintf(
      "If that average effect is real, the chance that a meta-analysis of this many studies finds it (a statistically significant result, using a %s threshold) is %s, and the chance that it misses it is %s. If the real effect is smaller, the chance of missing it is higher.",
      alpha, percent(p), percent(1 - p))
  }
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
    },
    justified_alpha = {
      j <- result$justified_alpha
      c(include, recruit_line, set_by, basis,
        sprintf("Rather than use the usual %s threshold for statistical significance, we chose one by weighing the two mistakes a study can make: finding an effect that isn't there, and missing one that is. %s. That gives a threshold of %s%%, with a %s chance of finding the effect if it is real.",
          alpha, justified_alpha_weights_text(j, brief = TRUE), format(signif(100 * j$alpha, 3)), percent(j$power)))
    })
  if (is_meta(spec)) body <- meta_units(body)
  if (is_dyadic(spec)) body <- dyad_units(body)
  p <- result$provenance
  paste(c(body, sprintf("The calculation was made with powerkit and the R package %s (version %s) and can be reproduced from the saved plan.",
    p$backend, p$packages[[p$backend]])), collapse = " ")
}

# The simulated data set: a CSV of one sample of the planned size, drawn
# from the population entered, for writing the analysis code (the engine's
# simulated_data()). The note says what it is for, and what it is not.
simulated_data_ui <- function(spec, result) {
  n <- simulated_data_n_for(spec, result)
  available <- !is.na(n) && isTRUE(tryCatch(engine_function("simulated_data_available")(spec), error = function(e) FALSE))
  if (!available) {
    return(p(class = "small simulated-data-unavailable", "A simulated data set isn't available for this design yet."))
  }
  div(class = "simulated-data",
    downloadButton("download_simulated_data", sprintf("Simulated data set (CSV, n = %s)", format(n)), class = "btn btn-outline-secondary"),
    p(class = "small simulated-data-note", tags$strong("Simulated, not real data. "),
      "One made-up data set of the planned size, drawn from the population you entered. Use it to write and check your analysis code (in R, SPSS, JASP, jamovi or Python) before the real data arrive. It is not evidence, not a pilot, and not a substitute for your analysis plan. Every row says SIMULATED_NOT_REAL_DATA in its first column, and the R script builds the same data set.",
      # A choice the data set makes that the plan leaves open (the engine's
      # simulated_data_note()).
      tryCatch(engine_function("simulated_data_note")(spec), error = function(e) NULL)))
}

# The n the simulated data set uses: the required n for a sample-size
# goal, the n of a precision plan, otherwise the n entered.
simulated_data_n_for <- function(spec, result) {
  n <- if (identical(result$goal_type, "sample_size")) {
    result$n_required$n
  } else if (identical(result$goal_type, "precision")) {
    result$precision$n
  } else {
    spec$goal$n
  }
  if (is.numeric(n) && length(n) == 1 && !is.na(n)) n else NA_real_
}

writeup_ui <- function(text) {
  if (is.null(text)) return(NULL)
  # The short version is open; the longer ones are a click away, so the
  # card stays short.
  copy <- function(id) tagList(
    tags$button(type = "button", class = "btn btn-sm btn-outline-primary writeup-copy",
      onclick = sprintf("pkCopyText(document.getElementById('%s').value, this.parentNode.querySelector('.writeup-copied'))", id), "Copy"),
    tags$span(class = "writeup-copied small visually-hidden", role = "status"))
  div(class = "result-writeup",
    p(class = "small", "A methods paragraph built from your answers. Edit it as you like, then copy it."),
    div(class = "writeup-head", tags$label(`for` = "writeup_short", "Short version (for the paper)"), copy("writeup_short")),
    tags$textarea(id = "writeup_short", class = "form-control writeup", rows = 6, text[["short"]]),
    tags$details(class = "result-more",
      tags$summary("Full version (for a supplement or preregistration)"),
      div(class = "writeup-head", tags$label(`for` = "writeup_full", class = "visually-hidden", "Full version (for a supplement or preregistration)"), copy("writeup_full")),
      tags$textarea(id = "writeup_full", class = "form-control writeup", rows = 10, text[["full"]])),
    if (!is.na(text["ethics"])) tags$details(class = "result-more",
      tags$summary("Plain-words version (for an ethics application)"),
      p(class = "small", "Why this many participants, for a panel that may not know statistics. It describes the plan; it doesn't say whether the study is ethical."),
      div(class = "writeup-head", tags$label(`for` = "writeup_ethics", class = "visually-hidden", "Plain-words version (for an ethics application)"), copy("writeup_ethics")),
      tags$textarea(id = "writeup_ethics", class = "form-control writeup", rows = 7, text[["ethics"]])))
}

# --- Precision planning (E46) ----------------------------------------------------
# The engine's design "precision": the confidence interval's width, not
# power. The result screen, the write-up and the ethics version only word
# the engine's result$precision.

is_precision <- function(spec) identical(spec$design, "precision")

precision_estimate_text <- function(spec) {
  v <- spec$variables
  switch(spec$template,
    two_groups = sprintf("Cohen's d for the difference in %s between %s and %s", v$Y$label, v$X$levels[[1]], v$X$levels[[2]]),
    paired = sprintf("d_z for the change in %s from %s to %s", v$Y$label, v$X$levels[[1]], v$X$levels[[2]]),
    one_group = sprintf("the standardised mean of %s", v$Y$label),
    correlation = sprintf("%s between %s and %s", switch(spec$target_test$method, spearman = "Spearman's rho", kendall = "Kendall's tau", "the correlation"),
      v$X$label, v$Y$label),
    proportion = sprintf("the proportion %s", v$Y$label))
}

precision_interval_name <- function(spec) {
  level <- sprintf("%s%%", format(100 * (1 - spec$target_test$alpha)))
  kind <- switch(spec$template,
    proportion = switch(spec$target_test$method, wilson = "Wilson", agresti_coull = "Agresti-Coull", exact = "exact (Clopper-Pearson)", wald = "Wald"),
    correlation = if (identical(spec$target_test$method, "pearson")) "Fisher's z" else NULL,
    "noncentral t")
  if (is.null(kind)) sprintf("%s confidence interval", level) else sprintf("%s %s confidence interval", level, kind)
}

precision_number <- function(x) format(round(x, 3), nsmall = 2)

precision_people <- function(spec, n) {
  if (identical(spec$template, "two_groups")) sprintf("%s participants in total (%s per group)", whole(n), whole(n / 2)) else
    if (identical(spec$template, "paired")) sprintf("%s pairs of scores", whole(n)) else sprintf("%s participants", whole(n))
}

precision_sentences <- function(spec, result) {
  pr <- result$precision
  estimate <- precision_estimate_text(spec)
  interval <- precision_interval_name(spec)
  expected <- sprintf("If the estimate comes out at %s = %s, its %s runs from %s to %s, a width of %s.",
    pr$effect_name, format(pr$effect), interval, precision_number(pr$lower), precision_number(pr$upper), precision_number(pr$width))
  how <- sprintf("Calculated by formula with %s (%s()), which powerkit called with your answers.", result$provenance$backend, pr$function_used)
  if (!is.na(pr$target_width)) {
    headline <- if (is.na(pr$assurance)) {
      sprintf("With %s, the %s for %s is expected to be no wider than %s.", precision_people(spec, pr$n), interval, estimate, format(pr$target_width))
    } else {
      sprintf("With %s, the %s for %s would be no wider than %s in %s of studies like this.", precision_people(spec, pr$n), interval, estimate,
        format(pr$target_width), percent(pr$assurance))
    }
    more <- if (spec$template %in% c("two_groups", "one_group", "paired")) "give a chance (assurance) that it is no wider, or plan a smaller width" else "plan a smaller width"
    reading <- if (is.na(pr$assurance)) sprintf("“Expected” means the typical study: about half of studies this size would get a somewhat wider interval. For more certainty, %s.", more) else
      "This is the chance (MBESS's assurance) that the interval is no wider than the width you set."
  } else {
    headline <- sprintf("With %s, the %s for %s would be about %s wide.", precision_people(spec, pr$n), interval, estimate, precision_number(pr$width))
    reading <- "A narrower interval says more precisely how large the effect is; its width doesn't depend on whether the effect is significant."
  }
  c(headline = headline, reading = reading, detail = paste(expected, how))
}

precision_writeup <- function(form, spec, result, fields, values) {
  if (blank(values$just_source) || isTRUE(values$source_stale)) return(NULL)
  pr <- result$precision
  p <- result$provenance
  estimate <- precision_estimate_text(spec)
  interval <- precision_interval_name(spec)
  basis <- sprintf("The expected value, %s = %s, was based on %s: %s.", pr$effect_name, format(pr$effect),
    writeup_source[[values$just_type %||% "smallest_effect_of_interest"]] %||% "our reasoning", writeup_quote(values$just_source))
  aim <- if (!is.na(pr$target_width)) {
    sprintf("We planned the sample size for precision rather than power: the %s for %s should be no wider than %s%s. This requires %s.",
      interval, estimate, format(pr$target_width),
      if (is.na(pr$assurance)) " on average" else sprintf(" with %s assurance", percent(pr$assurance)), precision_people(spec, pr$n))
  } else {
    sprintf("With %s, the %s for %s is expected to be %s wide.", precision_people(spec, pr$n), interval, estimate, precision_number(pr$width))
  }
  recruit <- result$recruitment
  recruit_line <- if (is.list(recruit)) sprintf("Allowing for %s attrition, we will recruit %s.", percent_attrition(recruit$attrition), whole(recruit$n_recruit))
  software <- sprintf("The calculation used the R package %s (version %s; %s()), set up by powerkit (version %s) in %s.",
    p$backend, p$packages[[p$backend]], pr$function_used, p$packages[["powerkit"]], p$r_version)
  short <- paste(c(aim, basis, recruit_line, software), collapse = " ")
  full <- paste(c(short, sprintf("Spec hash: %s.", p$spec_hash)), collapse = "\n\n")
  ethics <- paste(c(
    sprintf("We plan to include %s.", precision_people(spec, pr$n)), recruit_line,
    "This number comes from planning how precisely the study can estimate the result, not from a power analysis.",
    sprintf("With this many, the range of plausible values the study reports (its %s) is expected to be about %s wide, which we judged narrow enough to be informative. Fewer people would give a wider, less informative range.",
      interval, precision_number(pr$width)),
    basis,
    sprintf("The calculation was made with powerkit and the R package %s (version %s) and can be reproduced from the saved plan.", p$backend, p$packages[[p$backend]])
  ), collapse = " ")
  c(short = short, full = full, ethics = ethics)
}

precision_panel_ui <- function(tree, forms, ep_id, fields, values, calc) {
  ep <- tree$endpoints[[ep_id]]
  spec <- calc$spec
  result <- calc$result
  words <- precision_sentences(spec, result)
  p_ <- result$provenance
  can_export <- !blank(values$just_source) && !isTRUE(values$source_stale)
  div(
    class = "result-panel", role = "status", tabindex = "-1",
    div(class = "result-card result-main",
      h3(class = "h4", "Your result"),
      p(class = "result-headline lead", words[["headline"]]),
      p(class = "result-reading", words[["reading"]]),
      if (!is.null(line <- reasoning_line(values))) p(class = "result-reasoning", line),
      source_stale_ui(fields, values),
      if (!is.null(recruit <- recruitment_lines(result))) div(class = "result-recruitment",
        p(tags$strong(recruit[["analysed"]])), p(tags$strong(recruit[["recruit"]])),
        p(class = "small", recruit[["caveat"]])),
      p(class = "result-detail", words[["detail"]]),
      if (length(calc$notes)) tagList(h4(class = "h6", "Notes"), tags$ul(class = "result-notes", lapply(calc$notes, tags$li)))),
    div(class = "result-card result-save",
      h4(class = "h5", "Write it up and save it"),
      if (!can_export && blank(values$just_source)) p(class = "export-needs-reasoning",
        tags$strong("To save this plan, download its R script or get its write-up, "),
        "write your reasoning under “Where your effect size comes from” and press “Check my answers” again."),
      div(class = "nav-buttons",
        if (can_export) downloadButton("download_script", "Download R script", class = "btn btn-outline-primary"),
        downloadButton("download_citations", "Citations", class = "btn btn-outline-primary"),
        if (can_export) downloadButton("download_project", "Save project", class = "btn btn-outline-primary")),
      p(class = "small", "The R script reproduces this result with ", p_$backend, " alone (powerkit isn't needed)."),
      simulated_data_ui(spec, result),
      writeup_ui(precision_writeup(forms$forms[[ep_id]], spec, result, fields, values))),
    div(class = "result-card result-how",
      h4(class = "h5", "How it was calculated"),
      p(class = "result-credit",
        "Calculated by the R package ", tags$strong(p_$backend), sprintf(" (version %s), with %s(). ", p_$packages[[p_$backend]], p_$backend_function),
        "powerkit built the call from your answers and checked the values it passes. Cite the package: see Citations above."),
      validation_ui(ep),
      tags$details(class = "result-more",
        tags$summary("More about this result: the values it used"),
        tags$ul(class = "result-inputs", lapply(entered_lines(fields, values), tags$li))),
      tags$details(class = "result-more", tags$summary("Reproducibility record"), tags$ul(lapply(provenance_lines(result), tags$li))),
      tags$details(class = "result-more", tags$summary("The design spec that was run (JSON)"), tags$pre(class = "spec-json", spec_json(spec))))
  )
}
