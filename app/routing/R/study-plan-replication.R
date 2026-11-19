# Replication plans (queue item 23, docs/saving-projects.md, "Replication
# plans"): a study plan that also holds a replication's planning. The
# pre-replication notes (Karhulahti, Martončik & Adamkovič, 2025) and the
# replication planner's fields, which lived in Labs, are kept in the plan's
# `replication` record; the original's analysis, planned on its own card
# in replication mode, is the plan's analysis. The plan is saved, shared
# and downloaded like any study plan. Nothing here calculates: the goals
# come from the engine's replication_planning(), as before.

replication_plan_format <- "powerkit-replication-plan"

# Every field the replication plan keeps: the notes' boxes and where the
# researcher landed, the notes' smallest-detectable-effect panel, and the
# planner's fields.
replication_notes_ids <- c(vapply(labs_fields, `[[`, "", "id"), "labs_outcome",
  "labs_test", "labs_n", "labs_p1", "labs_rows", "labs_cols", "labs_power", "labs_alpha")
replication_plan_field_ids <- c(replication_notes_ids, replication_field_ids)

# The planner's starting values, as its screen had them.
replication_field_defaults <- list(rep_design = "two_groups", rep_analysis = "test", rep_original_prior = "default",
  rep_prior_scale = "0.707", rep_post_from = "sd", rep_cri_level = "95", rep_pool_from = "se", rep_pool_level = "95", rep_scale = "none", rep_se_from = "se", rep_ci_level = "95",
  rep_original_alpha = "0.05", rep_published = "unknown", rep_tau = "0.05", rep_tau_r = "0.025", rep_effect_type = "d",
  rep_alpha = "", rep_power = "", rep_threshold = "10", labs_power = "0.8", labs_alpha = "0.05",
  rep_purpose = "confirm", rep_goal = "auto", rep_prior = "uncertain", rep_also = "absence", rep_sided = "two.sided",
  rep_anova_kind = "between", rep_anova_effect = "factor_a", rep_f_from = "f", rep_epsilon = "1", rep_assurance = "0.8")

# Fields as the record keeps them: known ids only, each one string, blanks
# left out.
replication_clean_fields <- function(fields) {
  if (!is.list(fields)) fields <- as.list(fields)
  # A named empty list, so that its JSON is {} rather than [].
  if (!length(fields) || is.null(names(fields))) return(stats::setNames(list(), character()))
  fields <- fields[intersect(names(fields), replication_plan_field_ids)]
  fields <- lapply(fields, function(x) paste(as.character(unlist(x)), collapse = "\n"))
  # Blanks and the starting values are left out: the screen restores them.
  keep <- vapply(names(fields), function(id) nzchar(trimws(fields[[id]])) && !identical(fields[[id]], replication_field_defaults[[id]]), logical(1))
  fields <- fields[keep]
  if (!length(fields)) return(stats::setNames(list(), character()))
  fields[order(names(fields))]
}

replication_record <- function(fields = list(), endpoint = NULL) {
  ep <- if (is.character(endpoint) && length(endpoint) == 1L && grepl("^E[0-9]+$", endpoint)) endpoint
  record <- list(format = replication_plan_format, version = 2L, fields = replication_clean_fields(fields))
  if (!is.null(ep)) record$endpoint <- ep
  record
}

# A record read from a file or the browser, or NULL when it isn't one.
replication_normalise <- function(record) {
  if (!is.list(record) || !identical(record$format, replication_plan_format)) return(NULL)
  fields <- record$fields %||% list()
  if (isTRUE((record$version %||% 1L) == 1L)) {
    # An omitted filter used to select significance. The combined test
    # estimate / posterior mean was interpreted by the saved analysis.
    fields$rep_published <- fields$rep_published %||% "significant"
    if (identical(fields$rep_analysis, "posterior")) {
      fields$rep_post_mean <- fields$rep_effect
      fields$rep_effect <- NULL
    }
  }
  replication_record(fields, record$endpoint)
}

plan_is_replication <- function(plan) is.list(plan$replication)

new_replication_plan <- function(name = NULL, now = Sys.time()) {
  plan <- new_plan(name %||% plan_default_name(as.Date(now), "Replication plan"), now = now)
  plan$replication <- replication_record()
  plan
}

# Every field's value for the screen: the record's, else the starting one.
replication_values <- function(record) {
  fields <- replication_normalise(record)$fields %||% list()
  stats::setNames(lapply(replication_plan_field_ids, function(id) fields[[id]] %||% replication_field_defaults[[id]] %||% ""),
    replication_plan_field_ids)
}

# What a record holds, for telling two copies of a plan apart.
replication_content <- function(record) {
  r <- replication_normalise(record)
  if (is.null(r)) return(NULL)
  as.character(jsonlite::toJSON(list(r$fields, r$endpoint), auto_unbox = TRUE, null = "null"))
}

# The fields (and the original's card) as they stand, kept in the plan,
# which counts as changed only when they do.
plan_set_replication <- function(plan, fields = NULL, endpoint = NULL, now = Sys.time()) {
  old <- replication_normalise(plan$replication) %||% replication_record()
  record <- replication_record(if (is.null(fields)) old$fields else fields,
    if (is.null(endpoint)) old$endpoint else endpoint)
  if (identical(replication_content(old), replication_content(record)) && is.list(plan$replication)) return(plan)
  plan$replication <- record
  plan_touch(plan, now)
}

# A replication plan with no calculated analysis yet: a plan file needs an
# analysis, so it is saved as the replication planner's file (which the
# version before this one opens in Labs), with the record and the plan's
# id, name and description beside it.
plan_replication_only_text <- function(plan) {
  record <- replication_normalise(plan$replication)
  fields <- record$fields
  if (identical(fields$rep_analysis, "posterior")) fields$rep_effect <- fields$rep_post_mean
  file <- replication_file(fields, powerkit_version())
  file$replication <- record
  file$study_plan <- list(id = plan$id, name = plan$name, description = plan$description %||% "")
  as.character(jsonlite::toJSON(file, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA))
}

# A replication planner file: one a replication plan saved before it had
# an analysis (it names the plan), or one the Labs planner saved, which
# becomes a new replication plan. NULL when the text isn't one.
plan_from_replication_text <- function(text, now = Sys.time()) {
  data <- tryCatch(jsonlite::parse_json(text, simplifyVector = FALSE), error = function(e) NULL)
  if (!is.list(data) || !identical(data$app, "powerkit-replication-planner") || !is.list(data$fields)) return(NULL)
  meta <- data$study_plan
  saved_date <- tryCatch(as.Date(substr(data$saved %||% "", 1L, 10L)), error = function(e) NA)
  if (is.na(saved_date)) saved_date <- as.Date(now)
  plan <- new_plan(if (is.list(meta)) meta$name else plan_default_name(saved_date, "Replication plan"), now = now)
  if (is.list(meta) && is.character(meta$id) && grepl("^[0-9a-f]{16}$", meta$id)) plan$id <- meta$id
  if (is.list(meta)) plan$description <- plan_clean_text(meta$description %||% "", plan_description_max)
  legacy <- list(format = replication_plan_format, version = 1L, fields = data$fields)
  plan$replication <- replication_normalise(data$replication) %||% replication_normalise(legacy)
  plan_mark_saved(plan, "file", now = now)
}

# The workspace on a replication plan's page: its sections, one at a time,
# in any order. Drawn once with the Study plans page and shown for a
# replication plan, so typing never redraws it; the server fills its
# fields from the plan when the plan opens, and keeps them in the plan.
replication_workspace_ui <- function(tree) {
  div(class = "replication-workspace",
    h3(class = "h5", "Planning the replication"),
    p(class = "small", "Work through the steps in order, or open any step and come back to it later. Everything is kept in this plan: save the plan to keep it."),
    div(class = "replication-steps", role = "group", `aria-label` = "Steps of the replication plan",
      radioButtons("rep_section", NULL, choices = replication_sections, selected = "whether", inline = TRUE, width = "100%")),
    # Finished steps get a tick, as the input screens' step bar has.
    tags$script(HTML("Shiny.addCustomMessageHandler('rep-steps-done', function(m) { var done = m.done || []; document.querySelectorAll('.replication-steps input[name=rep_section]').forEach(function(r) { var l = r.closest('label'); if (l) { l.classList.toggle('rep-step-done', done.indexOf(r.value) >= 0); } }); });")),
    conditionalPanel("input.rep_section == 'whether'", class = "form-section", rep_section_title("whether"), replication_notes_ui(tree)),
    # Not worth replicating: the planning steps don't apply, and say so.
    conditionalPanel("input.labs_outcome == 'not_worth' && ['original', 'goals', 'differences'].indexOf(input.rep_section) >= 0",
      div(class = "alert alert-info rep-skip-note", role = "note",
        "You decided this finding isn't worth replicating, so this step isn't needed: the write-up is your negative pre-replication report. ",
        tags$button(type = "button", class = "btn btn-link p-0 align-baseline",
          onclick = "var r = document.querySelector('input[name=rep_section][value=writeup]'); if (r) r.click();", "Go to the write-up"),
        " You can still fill these steps in if you change your mind.")),
    replication_planner_sections(),
    replication_next_step_ui(),
    replication_references_ui())
}

# Under each step, a button to the next one, so the plan reads in order
# while every step stays open to come back to.
replication_next_step_ui <- function() {
  ids <- unname(replication_sections)
  tagList(lapply(seq_len(length(ids) - 1L), function(i) {
    # After "Not worth replicating", the notes' own button goes to the
    # write-up instead.
    conditionalPanel(sprintf("input.rep_section == '%s'%s", ids[[i]], if (i == 1L) " && input.labs_outcome != 'not_worth'" else ""),
      div(class = "nav-buttons rep-next-step",
        tags$button(type = "button", class = "btn btn-outline-primary",
          onclick = sprintf("var r = document.querySelector('input[name=rep_section][value=%s]'); if (r) { r.click(); r.closest('.replication-workspace').scrollIntoView(); }", ids[[i + 1L]]),
          sprintf("Next: %s", names(replication_sections)[[i + 1L]]))))
  }))
}

# The planner's fields when the original's card is chosen: its design and,
# for another design, the card's effect and scale (forms.yaml's
# replication_effects), until an original effect has been entered.
replication_fields_for_card <- function(fields, forms, ep) {
  fields <- fields %||% list()
  e <- replication_card_effect(forms, ep)
  if (is.null(e) || nzchar(trimws(as.character(fields$rep_effect %||% ""))) ||
      nzchar(trimws(as.character(fields$rep_bf %||% ""))) ||
      nzchar(trimws(as.character(fields$rep_post_mean %||% "")))) return(fields)
  if (!is.null(e$exact)) {
    fields$rep_design <- e$exact
  } else if (!is.null(e$anova) && !nzchar(trimws(as.character(fields$rep_anova_f %||% ""))) &&
      !nzchar(trimws(as.character(fields$rep_eta %||% "")))) {
    fields$rep_design <- "anova"
    fields$rep_anova_kind <- e$anova
  } else if (!is.null(e$effect) || !is.null(e$multi_df)) {
    fields$rep_design <- "generic"
    fields$rep_effect_name <- e$effect %||% ""
    fields$rep_scale <- e$scale %||% "none"
  }
  fields
}

# Under "The original study": the original's analysis on its own card,
# which plans the replication for its design (12 November 2026).
# Which of the plan's analyses is the original's: the first planned on the
# original's card, else the first that wasn't added as an extension (none,
# if every one was). Any others (an extension, a check) are the
# researcher's own additions and are reported apart from it.
replication_original_index <- function(plan) {
  if (!length(plan$entries)) return(NA_integer_)
  ext <- vapply(plan$entries, function(e) isTRUE(e$extension), logical(1))
  ep <- plan$replication$endpoint
  hit <- which(!ext & vapply(plan$entries, function(e) identical(e$endpoint, ep), logical(1)))
  if (length(hit)) return(hit[[1]])
  if (all(ext)) NA_integer_ else which(!ext)[[1]]
}

# The planner's designs that a card's original effect can be entered as
# (forms.yaml's replication_effects): one of the four exact designs;
# "anova" for an ANOVA card, which can also go as "generic" (its one
# contrast as a number); "generic" for any other one-number effect; NULL
# when the card has none.
replication_card_planner_design <- function(forms, ep) {
  e <- replication_card_effect(forms, ep)
  if (is.null(e)) return(NULL)
  if (!is.null(e$exact)) return(e$exact)
  c(if (!is.null(e$anova)) "anova", if (!is.null(e$effect) || !is.null(e$multi_df)) "generic")
}

# When the design chosen under "The original study" and the original's
# card disagree, the plan describes two different studies: said in words.
replication_design_mismatch <- function(plan, forms) {
  ep <- plan$replication$endpoint
  if (is.null(ep) || is.null(forms)) return(NULL)
  want <- replication_card_planner_design(forms, ep)
  have <- replication_values(plan$replication)$rep_design
  if (is.null(want) || isTRUE(have %in% want)) return(NULL)
  label <- function(x) names(replication_designs_ui)[replication_designs_ui == x[[1]]]
  sprintf("These describe different studies: the design chosen above is \u201c%s\u201d, but the original's card is for \u201c%s\u201d. Change the design above, or choose the card for the original's design, so the goals and the card plan the same analysis.",
    label(have), label(want))
}

# Why the card and the Goals can give different sample sizes (queue item 28).
replication_card_vs_goals <- paste(
  "The card and the Goals can give different sample sizes. The card is an ordinary power analysis: it takes the effect you enter as the true one.",
  "The Goals allow for the original's estimate being uncertain, and often too large, and for the true effect varying between studies, so under those beliefs they usually need more people.",
  "Say in the write-up which one the sample size is based on.")

replication_card_status_ui <- function(tree, plan, forms = NULL) {
  ep <- plan$replication$endpoint
  i <- replication_original_index(plan)
  entry <- if (!is.na(i)) plan$entries[[i]]
  mismatch <- replication_design_mismatch(plan, forms)
  div(class = "rep-card-status form-group-box",
    h4(class = "h6", "Its analysis, on its own card"),
    if (is.null(ep)) tagList(
      rep_note("Choose the analysis the original study used: its paper usually names it. Its card plans the replication's sample size for that design, starting from this plan's significance level, chance of success and the original's effect, and the result is kept in this plan."),
      div(class = "nav-buttons",
        actionButton("rep_pick_design", "Choose it from the list of analyses", class = "btn btn-primary"),
        actionButton("rep_find_design", "Not sure? Answer questions about the study", class = "btn btn-outline-secondary")))
    else tagList(
      p(HTML(sprintf("The original's design: <strong>%s</strong>%s.", htmltools::htmlEscape(tree$endpoints[[ep]]$plain_name %||% ep),
        if (!is.null(entry)) sprintf(" (planned: %s)", htmltools::htmlEscape(plan_item_summary(entry))) else ""))),
      if (!is.null(mismatch)) p(class = "rep-design-mismatch alert alert-warning", role = "alert", mismatch),
      if (!is.null(forms)) {
        note <- replication_card_effect_note(forms, ep)
        if (!is.null(note)) p(class = "small", note)
      },
      p(class = "small rep-card-vs-goals", replication_card_vs_goals),
      div(class = "nav-buttons",
        actionButton("rep_open_card", if (is.null(entry)) "Plan it on its card" else "Open its card again", class = "btn btn-primary"),
        actionButton("rep_pick_design", "Choose a different analysis", class = "btn btn-outline-secondary"))))
}

# Above the list of every analysis when it is opened from a replication
# plan: what to choose, and where the choice is kept.
replication_known_note <- function(plan) {
  div(class = "status status-soon replication-known-note",
    p(class = "mb-0", if (plan_is_replication(plan)) sprintf(
      "Choose the analysis the original study used. Its card plans the replication and is kept in the replication plan \u201c%s\u201d.", plan$name)
      else "Choose the analysis the original study used. Its card plans the replication."))
}

# Above the list and the card when an extension analysis is being chosen
# for a replication plan (queue item 28): an ordinary analysis, with its
# own effect size, kept in the plan under its own heading.
replication_extension_note <- function(plan, card = FALSE) {
  name <- if (plan_is_replication(plan)) sprintf(" \u201c%s\u201d", plan$name) else ""
  div(class = "status status-soon replication-extension-note",
    p(class = "mb-0", if (card) sprintf(
      "An extension of the replication plan%s: plan it with the effect you expect for what you added, which has no original estimate. Comparing the original condition with a changed version of it? Give the original condition the effect you believe under the plan's Goals, and the changed one the effect you expect. \u201cAdd to plan\u201d keeps it in the plan, reported apart from the original's analysis.", name)
      else sprintf("Choose the analysis for what the replication adds. Its card plans it as an ordinary power analysis, and it is kept in the replication plan%s, reported apart from the original's analysis.", name)))
}

# "N = 128" or the card's own goal, for one line.
plan_item_summary <- function(entry) {
  if (is.numeric(entry$n) && length(entry$n) == 1 && is.finite(entry$n)) sprintf("N = %s", whole(entry$n)) else entry$label %||% "calculated"
}

# The original's analysis, as its card planned it, for the write-up: what
# it found and the card's own methods paragraph. Nothing is recalculated.
replication_analysis_lines <- function(plan, tree, forms) {
  if (!length(plan$entries)) return(NULL)
  one <- function(e) {
    text <- tryCatch(planning_methods_text(tree, forms, plan_entry_calc(e)), error = function(err) NULL)
    c(sprintf("- %s: %s", e$label, plan_item_summary(e)), "",
      text %||% "The methods paragraph for this analysis is in its own report.", "")
  }
  i <- replication_original_index(plan)
  others <- if (is.na(i)) plan$entries else plan$entries[-i]
  # The other analyses (an extension, a check) under their own heading, so
  # none is reported as the original's (the report's next heading follows).
  c(if (is.na(i)) c("_(Not planned yet: under The original study, choose the original's analysis and plan it on its card.)_", "")
    else one(plan$entries[[i]]),
    if (length(others)) c("## Other analyses in this plan", "",
      "Planned beside the replication, such as an extension or a check; not part of the original study.", "",
      unlist(lapply(others, one))))
}

# On the card's input screen when replicating: each effect field says it
# takes the original study's effect (12 November 2026).
replication_effect_labels <- function(groups) {
  lapply(groups, function(g) {
    g$fields <- lapply(g$fields, function(f) {
      if (isTRUE(f$effect) && is.character(f$label) && !grepl("original study", f$label, fixed = TRUE)) {
        f$label <- paste0(f$label, ", as the original study reported it")
      }
      f
    })
    g
  })
}

# A replication plan's write-up from its record alone, as "Download
# everything" gives it: the goals table is calculated by the engine when
# the original study is filled in, as the workspace would.
replication_plan_report <- function(plan, tree, forms, engine = engine_function) {
  values <- replication_values(plan$replication)
  table <- if (!length(replication_missing(values))) {
    tryCatch(replication_run(values, engine("replication_planning"), engine("replication_bucss"),
      engine("replication_anova_smallest")), error = function(e) NULL)
  }
  notes <- values[vapply(labs_fields, `[[`, "", "id")]
  replication_report(values, table, notes, values$labs_outcome, powerkit_version(),
    analyses = replication_analysis_lines(plan, tree, forms), title = plan$name)
}
