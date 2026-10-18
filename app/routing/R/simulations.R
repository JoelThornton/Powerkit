# Mediation and moderated mediation (E10-E14): simulations too long to run
# while the user waits for a result (the maintainer's decision of
# 17 October 2026; docs/phase5-simulations.md, docs/decisions.md).
#
# * For power at a fixed N, first a rough preview: the same spec and seed
#   with few replications (forms.yaml, simulations > preview_nrep), run in a
#   separate R process and shown as a range, never as a result. It has no
#   script or citations. A required N has no preview (has_preview()).
# * Then, for the goals listed under `full_run` (mediation power at a fixed
#   N), the full run at the app's defaults in a separate process, with a
#   progress bar and Cancel, as for E9.
# * For every other goal, an R script that runs the full analysis on the
#   user's own computer (the engine's export_run_script()).
#
# Background jobs (option C) are not built; option E (fewer replications)
# is not a default.
#
# As everywhere in the app, the engine does every calculation: the preview
# and the full run are run_spec(); the preview's range is power_interval()
# or the engine's interval for the required N.

runs_long <- function(forms, ep_id) ep_id %in% names(forms$simulations$endpoints)

long_settings <- function(forms, ep_id) forms$simulations$endpoints[[ep_id]]

preview_nrep <- function(forms) as.integer(forms$simulations$preview_nrep)

# Whether the full analysis runs in the app for this goal (else: the R script).
full_run_in_app <- function(forms, ep_id, goal) goal %in% unlist(long_settings(forms, ep_id)$full_run)

preview_seconds <- function(forms, ep_id, goal) long_settings(forms, ep_id)$preview[[goal]] %||% NA_real_
full_seconds <- function(forms, ep_id, goal) long_settings(forms, ep_id)$full[[goal]] %||% NA_real_
script_run_time <- function(forms, ep_id, goal) long_settings(forms, ep_id)$script[[goal]] %||% "unknown"

# The preview's spec: the user's spec, with its seed, and few replications.
# Everything else (including the Monte Carlo draws per interval) is left as
# the user set it, so the preview runs the same test as the full analysis.
preview_spec <- function(spec, nrep) {
  spec$options$nrep <- as.integer(nrep)
  spec
}

# A wait in words: seconds below two minutes, then minutes.
duration_text <- function(seconds) {
  if (is.na(seconds)) return(NA_character_)
  if (seconds < 120) return(sprintf("about %s seconds", whole(round(seconds))))
  sprintf("about %s minutes", whole(round(seconds / 60)))
}

# Whether a goal has a rough preview. Only power at a fixed N does: a
# required N simulates many sample sizes, and with 100 replications each the
# search took over 15 minutes for simple mediation and still couldn't narrow
# the N down (docs/phase5-simulations.md, "Preview times").
has_preview <- function(forms, ep_id, goal) !is.na(preview_seconds(forms, ep_id, goal))

# The preview as a range, with the warning not to report it. `range` is the
# engine's power_interval().
preview_sentence <- function(range, nrep) {
  sprintf(
    "Rough preview from %s simulations: power is likely between %s and %s. Don't report this; run the full analysis.",
    whole(nrep), percent(range[["lower"]]), percent(range[["upper"]])
  )
}

preview_range <- function(result, interval = engine_function("power_interval")) interval(result)

# The R version a backend package needs, from its installed DESCRIPTION
# (for the "what you need" list); NULL if it doesn't say.
backend_r_requirement <- function(package) {
  depends <- tryCatch(utils::packageDescription(package, fields = "Depends"), error = function(e) NA)
  if (is.na(depends)) return(NULL)
  found <- regmatches(depends, regexpr("R \\(>=\\s*[0-9.]+\\)", depends))
  if (length(found) == 0) return(NULL)
  sub("^R \\(>=\\s*([0-9.]+)\\)$", "\\1", found)
}

# The preview panel: the range and its warning, then either the full run's
# button (with the wait stated before it starts) or the R script to run the
# full analysis at home. `calc` is run_calculation()'s value for the
# preview spec.
preview_panel_ui <- function(forms, ep_id, calc, full_spec, range) {
  if (!identical(calc$status, "ok")) {
    return(div(class = "form-problems", role = "alert", tabindex = "-1",
      h3(class = "h5", "The preview didn't finish"), p(calc$message)))
  }
  result <- calc$result
  goal <- result$goal_type
  nrep <- result$provenance$nrep
  full_nrep <- full_spec$options$nrep %||% 1000L
  div(
    class = "result-panel preview-panel", role = "status", tabindex = "-1",
    h3(class = "h4", "Rough preview (not a result)"),
    p(class = "preview-range lead", tags$strong(preview_sentence(range, nrep))),
    p(class = "small", sprintf(
      "A preview runs only %s simulations, so it is imprecise: the range shows where the full result is likely to fall. It isn't kept, and it has no R script or citations. Seed: %s, the same as the full analysis.",
      whole(nrep), result$provenance$seed)),
    if (length(calc$notes)) tagList(h4(class = "h6", "Notes"), tags$ul(lapply(calc$notes, tags$li))),
    if (full_run_in_app(forms, ep_id, goal)) {
      wait <- duration_text(full_seconds(forms, ep_id, goal))
      div(class = "full-run-offer",
        h4(class = "h5", "The full analysis"),
        p(sprintf(
          "It runs %s simulations (the app's default) in a separate process. It usually takes %s on one core; you can cancel it, and leaving this screen stops it.",
          whole(full_nrep), wait)),
        actionButton("full_run", sprintf("Run the full analysis (%s)", wait), class = "btn btn-primary"))
    } else {
      script_offer_ui(forms, ep_id, goal, result$provenance$seed)
    }
  )
}

# A required N (E10-E14): no preview, straight to the R script.
no_preview_ui <- function(forms, ep_id, spec) {
  div(
    class = "result-panel script-panel", role = "status", tabindex = "-1",
    h3(class = "h4", "Run the full analysis on your computer"),
    p("There is no rough preview for a required sample size: even with 100 simulations per sample size, finding the N takes 15 minutes or more and often can't narrow it down."),
    script_offer_ui(forms, ep_id, spec$goal$type, spec$options$seed, heading = FALSE)
  )
}

# The R script offer: run time, what to install, and the download button.
script_offer_ui <- function(forms, ep_id, goal, seed, heading = TRUE) {
  r_needs <- backend_r_requirement("power4mome")
  div(class = "script-offer",
    if (heading) h4(class = "h5", "Run the full analysis on your computer"),
    p(sprintf(
      "This calculation takes %s, too long to run here. The R script runs it on your computer with the same spec and seed (%s), so it gives the result powerkit would.",
      script_run_time(forms, ep_id, goal), seed)),
    p("What you need:"),
    tags$ul(
      tags$li(sprintf("R%s, from cran.r-project.org.", if (is.null(r_needs)) "" else sprintf(" %s or later", r_needs))),
      tags$li("powerkit and power4mome. In R, run once: ",
        tags$code("install.packages(\"remotes\")"), " then ",
        tags$code("remotes::install_github(\"JoelThornton/Powerkit\", subdir = \"engine\")"), "."),
      tags$li("Then run the script. It saves the result, a script that reproduces it with power4mome alone, and the citations.")),
    downloadButton("download_run_script", "Download R script to run the full analysis on your computer", class = "btn btn-primary"))
}
