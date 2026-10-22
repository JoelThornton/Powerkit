# Labs (experimental): optional tools kept apart from the main route.
#
# The first tool is "Pre-replication notes": the three questions of
# Karhulahti, Martončik and Adamkovič (2025, refs.bib key
# Karhulahti2025_prereplication), answered in the user's own words. Nothing
# is scored, required or sent to the server; the notes are kept in the
# browser tab (sessionStorage) so a reload doesn't lose them. The one number
# shown (the original study's smallest detectable effect) comes from the
# engine's sensitivity, as in the main app.

labs_tab_title <- "Labs (experimental)"

# The tools on Labs' first screen; each opens on its own (22 October 2026),
# so that more can be added.
labs_tools <- list(
  list(id = "prereplication", title = "Pre-replication notes",
       text = "Before replicating a finding: three questions to think through whether, why and how to replicate it, and the smallest effect the original study could detect.")
)
labs_ref_key <- "Karhulahti2025_prereplication"

# The paper's three questions, word for word (its "Pre-replication" section).
labs_questions <- list(
  goals = "What are the epistemic goals in replication and how is the original study related to them?",
  quality = "Is the chosen finding or study sufficiently high in methodological quality for replication?",
  value = "Why has replication been chosen to reach the desired epistemic goals?"
)

# Every free-text box, in the order of the screen and the notes.
labs_fields <- list(
  list(id = "labs_study", step = "finding", label = "The original study (authors, year, title or link)"),
  list(id = "labs_finding", step = "finding", label = "The finding you want to replicate, in a sentence"),
  list(id = "labs_goals", step = "goals", label = labs_questions$goals),
  list(id = "labs_smallest", step = "goals", label = "What is the smallest effect that would matter, for theory or in practice? (for example, the smallest benefit worth having for the people involved)"),
  list(id = "labs_quality", step = "quality", label = labs_questions$quality),
  list(id = "labs_improve", step = "quality", label = "What weaknesses in the original design will the replication improve?"),
  list(id = "labs_value", step = "value", label = labs_questions$value),
  list(id = "labs_alternatives", step = "value", label = "What else could serve the same goal (for example, a new study of an unexplored part of the theory), and why is a replication better?")
)

labs_outcomes <- c(
  go = "Go ahead with a replication",
  change = "Change the plan (for example, a different design or population)",
  not_worth = "Not worth replicating"
)

# The tests the smallest-detectable-effect panel offers: the basic tests,
# by their main-route end point.
labs_tests <- c("E2", "E3", "E1", "E4", "E5", "E6")

# --- The original study's smallest detectable effect ---------------------------

# Builds the end point's spec the same way the input screen does (goal
# "smallest effect", no effect entered) and runs it on the engine.
# `n` is the number analysed in total (both groups together for two
# groups). Returns run_calculation()'s list, or list(status = "problems",
# problems) when an entry needs fixing.
labs_sde <- function(forms, ep_id, n, power = "0.8", alpha = "0.05", p1 = NULL,
                     rows = NULL, cols = NULL, run = engine_function("run_spec")) {
  fields <- unlist(lapply(form_groups(forms, ep_id, 2L, list()), `[[`, "fields"), recursive = FALSE)
  values <- list()
  for (f in fields) if (!is.null(f[["default"]])) values[[f$id]] <- as.character(f[["default"]])
  levels_of <- function(k) {
    k <- suppressWarnings(as.integer(k))
    if (length(k) != 1 || is.na(k) || k < 2) return("")
    paste(paste("Category", seq_len(k)), collapse = ", ")
  }
  values <- utils::modifyList(values, list(
    X_label = "Group", X_level1 = "Group 1", X_level2 = "Group 2", Y_label = "Outcome",
    X_levels = levels_of(rows), Y_levels = levels_of(cols),
    goal = "sensitivity", n = as.character(n %||% ""), power = as.character(power %||% ""),
    alpha = as.character(alpha %||% ""), p1 = as.character(p1 %||% ""), just_type = "none",
    # The input screen no longer pre-fills the direction; Labs looks at the
    # original study's test, taken as two-sided (the packages' default).
    alternative = "two_sided"
  ))
  problems <- form_problems(fields, values)
  if (length(problems)) return(list(status = "problems", problems = problems))
  spec <- build_spec(forms, ep_id, fields, values)
  calc <- run_calculation(spec, run = run, seed = forms$default_seed)
  calc$ep_id <- ep_id
  calc
}

# One line for the panel and the notes.
labs_sde_sentence <- function(tree, calc, power) {
  s <- calc$result$sensitivity
  if (is.null(s$effect) || is.na(s$effect)) {
    return(sprintf("For %s, no effect could reach %s%% power at this sample size.",
      tolower(tree$endpoints[[calc$ep_id]]$plain_name), round(100 * as.numeric(power))))
  }
  sprintf("With %s analysed, the original study (%s) would detect an effect of %s or larger %s%% of the time, measured as %s.",
    calc$spec$goal$n, tolower(tree$endpoints[[calc$ep_id]]$plain_name),
    format(round(abs(s$effect), 3), nsmall = 2), round(100 * as.numeric(power)), s$effect_description)
}

labs_provenance <- function(calc) {
  p <- calc$result$provenance
  backend <- p$backend %||% "unknown"
  version <- p$packages[[backend]] %||% "unknown"
  sprintf("Calculated by powerkit's engine with the R package %s (version %s), seed %s.",
    if (identical(backend, "stats")) "stats (base R)" else backend, version, calc$spec$options$seed %||% "none")
}

# --- The citation, from refs.bib ---------------------------------------------

labs_citation <- function(path = labs_refs_path()) {
  fallback <- "See https://doi.org/10.15626/MP.2024.4155"
  if (!nzchar(path) || !file.exists(path)) return(fallback)
  ns <- tryCatch(asNamespace("powerkit"), error = function(e) NULL)
  # A partly loaded engine (no bib reader) or a reading error gives the
  # fallback, never an error page.
  if (is.null(ns) || !is.function(ns$read_bib) || !is.function(ns$bib_entry_text)) return(fallback)
  tryCatch({
    entry <- ns$read_bib(path)[[labs_ref_key]]
    if (is.null(entry)) return(fallback)
    text <- paste(ns$bib_entry_text(entry), collapse = " ")
    gsub("\\s+", " ", gsub("[*_]{1,2}([^*_]+)[*_]{1,2}", "\\1", text))
  }, error = function(e) fallback)
}

labs_refs_path <- function() {
  installed <- system.file("citations", "refs.bib", package = "powerkit")
  if (nzchar(installed)) return(installed)
  local <- file.path(routing_root(), "..", "..", "engine", "inst", "citations", "refs.bib")
  if (file.exists(local)) local else ""
}

# --- The notes as Markdown ---------------------------------------------------------

labs_notes_heading <- function(outcome) {
  switch(outcome %||% "",
    go = "These notes can go in the replication's preregistration or introduction, as a short justification of why this replication is worth running.",
    change = "These notes explain why the plan changed from a straight replication, and can go in the new study's preregistration or introduction.",
    not_worth = "A draft of a negative pre-replication report: a short note, like a correction or an expression of concern, saying why this finding is not worth replicating. It could be shared as a preprint, on OSF or as a commentary.",
    "The author's own notes, before replicating a finding."
  )
}

# `answers`: named list of the free-text boxes (labs_fields ids);
# `sde`: the panel's sentence and provenance, or NULL.
labs_markdown <- function(answers, outcome = NULL, sde = NULL, citation = labs_citation(), date = Sys.Date()) {
  answer <- function(id) {
    a <- trimws(answers[[id]] %||% "")
    if (nzchar(a)) a else "_(left blank)_"
  }
  section <- function(step) {
    ids <- Filter(function(f) identical(f$step, step), labs_fields)
    unlist(lapply(ids, function(f) c(sprintf("**%s**", f$label), "", answer(f$id), "")))
  }
  c(
    "# Pre-replication notes", "",
    sprintf("_%s_", labs_notes_heading(outcome)), "",
    "## The finding", "", section("finding"),
    "## Epistemic goals", "", section("goals"),
    "## Methodological quality", "", section("quality"),
    if (!is.null(sde)) c(sprintf("**The original study's smallest detectable effect.** %s %s", sde$sentence, sde$provenance), ""),
    "## Value", "", section("value"),
    "## Where I landed", "",
    if (!is.null(outcome) && outcome %in% names(labs_outcomes)) labs_outcomes[[outcome]] else "_(not chosen)_", "",
    "---", "",
    sprintf("The questions are from: %s", citation), "",
    sprintf("Written with powerkit Labs (experimental) on %s. These are the author's own notes; powerkit does not score or judge them.", format(date, "%d %B %Y"))
  ) |> paste(collapse = "\n")
}

# --- The screen -----------------------------------------------------------------

labs_box <- function(f, rows = 4) {
  div(class = "form-field", textAreaInput(f$id, f$label, rows = rows, width = "100%"))
}
labs_boxes <- function(step) lapply(Filter(function(f) identical(f$step, step), labs_fields), labs_box)

labs_ui <- function(tree) {
  test_choices <- c("Choose one" = "", stats::setNames(labs_tests,
    vapply(labs_tests, function(e) tree$endpoints[[e]]$plain_name, character(1))))
  div(id = "labs-notes", class = "labs",
    h2("Labs (experimental)"),
    p(class = "lead", "Tools that may help you think about a study before you plan it. They are not part of the main route, nothing here is required, and they may change or disappear."),
    # First screen: the list of tools.
    conditionalPanel("!input.labs_tool",
      div(class = "labs-menu", lapply(labs_tools, function(t) div(class = "labs-tool-card",
        h3(class = "h5", t$title), p(t$text),
        tags$button(type = "button", class = "btn btn-primary", onclick = sprintf("pkLabsOpen('%s')", t$id), paste("Open", t$title))))),
      p(class = "small text-muted", "More tools will be added here.")),
    conditionalPanel("input.labs_tool == 'prereplication'",
    tags$button(type = "button", class = "btn btn-link labs-back", onclick = "pkLabsOpen('')", "\u2190 All Labs tools"),
    div(class = "labs-notice", role = "note",
      tags$strong("Experimental and not validated. "),
      "Nothing you write is scored, checked or sent anywhere. Your notes stay in this browser tab, so reloading the page keeps them; closing the tab or pressing “Clear notes” removes them."),
    h3("Pre-replication notes"),
    p("Before replicating a finding, answer three questions in your own words. They come from Karhulahti, Martončik and Adamkovič (2025), who describe the purpose as “to make researchers critically reflect on their work before having started it”. Write as much or as little as you like."),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "1. The finding"),
      p(class = "group-note", "The paper asks you to replicate findings, not studies: name the finding you care about, not only the paper it came from."),
      labs_boxes("finding")),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "2. Epistemic goals"),
      p(class = "group-note", "What the replication is meant to tell you, for theory or for practice."),
      labs_boxes("goals")),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "3. Methodological quality"),
      p(class = "group-note", "Two parts: was the original design strong enough for its finding to be worth attention, and what should the replication do better? The paper notes that methodology can't be judged by statistics alone. Things to think about: whether the measures and setting fit the finding, who the sample was and who it leaves out, and whether the original data and analysis can be checked."),
      labs_boxes("quality"),
      tags$details(class = "labs-sde",
        tags$summary("Optional: the smallest effect the original study could detect"),
        p(class = "small", "Enter the original study's test and sample size. powerkit finds the smallest effect that design would detect at the power you choose. Compare it with the smallest effect that matters, from step 2. This is one part of quality, not a verdict on it."),
        selectInput("labs_test", "The original study's test", choices = test_choices, selectize = FALSE, width = "100%"),
        textInput("labs_n", "Participants analysed in the original study (in total, all groups together)", width = "100%"),
        conditionalPanel("input.labs_test == 'E5'",
          textInput("labs_p1", "Group 1's proportion in the original study (for example 0.3)", width = "100%")),
        conditionalPanel("input.labs_test == 'E6'",
          textInput("labs_rows", "Number of categories in the first variable", width = "100%"),
          textInput("labs_cols", "Number of categories in the second variable", width = "100%")),
        textInput("labs_power", "Power (the chance of detecting the effect)", value = "0.8", width = "100%"),
        textInput("labs_alpha", "Significance level", value = "0.05", width = "100%"),
        actionButton("labs_sde_run", "Find the smallest detectable effect", class = "btn btn-outline-primary"),
        uiOutput("labs_sde_result"))),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "4. Value"),
      p(class = "group-note", "Why a replication, rather than another way of reaching the same goal."),
      labs_boxes("value")),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "5. Where you landed"),
      p(class = "group-note", "All three are good outcomes. The paper counts deciding a finding is not worth replicating, before spending time and participants on it, as a useful result."),
      radioButtons("labs_outcome", NULL, choices = stats::setNames(names(labs_outcomes), unname(labs_outcomes)), selected = character(0), width = "100%")),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "6. Your notes"),
      uiOutput("labs_next"),
      div(class = "nav-buttons",
        downloadButton("labs_download", "Download the notes (Markdown)", class = "btn btn-primary"),
        actionButton("labs_copy", "Copy the notes", class = "btn btn-outline-primary"),
        tags$button(type = "button", class = "btn btn-outline-primary", onclick = "window.print()", "Print or save as PDF"),
        tags$button(type = "button", id = "labs_clear", class = "btn btn-link", onclick = "pkLabsClear()", "Clear notes")),
      div(id = "labs-copy-status", class = "visually-hidden", `aria-live` = "polite"),
      uiOutput("labs_copy_text")),
    p(class = "small text-muted", "Reference: ", labs_citation())
    )
  )
}

# Planning the replication from the notes (22 October 2026): the user's own
# words go into "Why this effect size?" on the input screen, never a
# number into a box. NULL when the notes say nothing to carry.
labs_seed_reasoning <- function(answers) {
  a <- function(id) trimws(answers[[id]] %||% "")
  parts <- c(
    if (nzchar(a("labs_finding"))) sprintf("Replicating: %s%s.", sub("[.]$", "", a("labs_finding")),
      if (nzchar(a("labs_study"))) sprintf(" (original study: %s)", a("labs_study")) else ""),
    if (nzchar(a("labs_smallest"))) sprintf("The smallest effect that would matter, from my pre-replication notes: %s", a("labs_smallest"))
  )
  if (!length(parts)) return(NULL)
  paste(parts, collapse = " ")
}

# On the main route's card and input screens while planning from the notes.
labs_return_ui <- function(on_form = FALSE, carried = FALSE) {
  div(class = "labs-return", role = "note",
    "You're planning the replication from your pre-replication notes. Your notes are kept in Labs. ",
    actionLink("labs_back", "Back to the notes"),
    if (on_form && carried) p(class = "small mb-0 mt-1", "Your notes' finding and smallest effect that would matter are copied into \u201cWhy this effect size?\u201d below; edit them as you like."))
}

# Asked before planning from the notes replaces a plan in progress.
labs_replace_modal <- function() {
  modalDialog(
    title = "Replace the plan in progress?",
    p("You have a plan in progress on \u201cPlan a power analysis\u201d. Planning the replication starts a new one there, and the plan in progress will be lost unless you save it first (\u201cSave this project\u201d on its result) or copy your answers."),
    p("Your pre-replication notes are kept either way."),
    footer = tagList(
      modalButton("Keep my plan"),
      actionButton("labs_plan_confirm", "Start the replication's plan", class = "btn btn-primary")),
    easyClose = TRUE)
}

# What step 6 offers depends on where the user landed.
labs_next_ui <- function(outcome, has_test) {
  plan_label <- if (has_test) "the same test" else "the start screen"
  switch(outcome %||% "",
    go = tagList(p(labs_notes_heading("go")),
      actionButton("labs_plan", "Plan the replication's sample size", class = "btn btn-primary"),
      p(class = "small", sprintf("Opens the main app on %s.", plan_label))),
    change = tagList(p(labs_notes_heading("change")),
      actionButton("labs_plan", "Plan the sample size for the new design", class = "btn btn-primary"),
      p(class = "small", "Opens the main app on the start screen, so you can choose the new design's analysis.")),
    not_worth = p(labs_notes_heading("not_worth")),
    p(class = "small", "Choose where you landed (step 5) to see what comes next. You can download or copy the notes at any time.")
  )
}

# The one way in from the main route: shown under the effect size's source
# when it is a previous study, and hidden for the rest of the tab's life
# if the user says so.
labs_signpost_ui <- function() {
  conditionalPanel("input.f_just_type == 'prior_study'",
    div(class = "labs-signpost",
      "Planning a replication? ", actionLink("go_labs", "Pre-replication notes in Labs"),
      " may help you think it through first (optional). ",
      tags$button(type = "button", class = "btn btn-link btn-sm labs-hide", onclick = "pkLabsHideHint()", "Hide this")))
}

# Keeps the notes in the browser tab (sessionStorage), restores them after
# a reload, and clears them on request. Nothing is sent anywhere but the
# app's own server session.
labs_js <- "
  (function() {
    var key = 'powerkit-labs-';
    var store = function() { try { return window.sessionStorage; } catch (e) { return null; } };
    var fields = function() { return document.querySelectorAll('#labs-notes textarea, #labs-notes input[type=text], #labs-notes select'); };
    var save = function(el) { var s = store(); if (!s || !el.id) return; try { s.setItem(key + el.id, el.value); } catch (e) {} };
    $(document).on('input change', '#labs-notes textarea, #labs-notes input[type=text], #labs-notes select', function() { save(this); });
    $(document).on('change', '#labs-notes input[name=labs_outcome]', function() {
      var s = store(); if (s) { try { s.setItem(key + 'labs_outcome', this.value); } catch (e) {} }
    });
    $(document).on('shiny:connected', function() {
      var s = store();
      if (s) { try { if (s.getItem('powerkit-labs-hint-hidden')) document.body.classList.add('labs-hint-hidden'); } catch (e) {} }
      if (!s) return;
      fields().forEach(function(el) {
        var v = null; try { v = s.getItem(key + el.id); } catch (e) {}
        if (v !== null) { el.value = v; $(el).trigger('change'); }
      });
      var o = null; try { o = s.getItem(key + 'labs_outcome'); } catch (e) {}
      if (o) { var r = document.querySelector('#labs-notes input[name=labs_outcome][value=' + o + ']'); if (r) { r.checked = true; $(r).trigger('change'); } }
    });
    window.pkLabsClear = function() {
      if (!window.confirm('Clear all your pre-replication notes from this tab?')) return;
      var s = store();
      fields().forEach(function(el) {
        if (s) { try { s.removeItem(key + el.id); } catch (e) {} }
        el.value = (el.id === 'labs_power') ? '0.8' : (el.id === 'labs_alpha') ? '0.05' : '';
        $(el).trigger('change');
      });
      if (s) { try { s.removeItem(key + 'labs_outcome'); } catch (e) {} }
      document.querySelectorAll('#labs-notes input[name=labs_outcome]').forEach(function(r) { r.checked = false; });
      Shiny.setInputValue('labs_outcome', null);
    };
    // Which Labs tool is open, kept for the tab like the notes.
    window.pkLabsOpen = function(tool) {
      Shiny.setInputValue('labs_tool', tool || '');
      var s = store(); if (s) { try { if (tool) s.setItem('powerkit-labs-tool', tool); else s.removeItem('powerkit-labs-tool'); } catch (e) {} }
      var top = document.getElementById('labs-notes'); if (top) top.scrollIntoView();
    };
    $(document).on('shiny:connected', function() {
      var s = store(); var t = null; if (s) { try { t = s.getItem('powerkit-labs-tool'); } catch (e) {} }
      if (t) Shiny.setInputValue('labs_tool', t);
    });
    Shiny.addCustomMessageHandler('labs_open', function(tool) { window.pkLabsOpen(tool); });
    window.pkLabsHideHint = function() {
      document.body.classList.add('labs-hint-hidden');
      var s = store(); if (s) { try { s.setItem('powerkit-labs-hint-hidden', '1'); } catch (e) {} }
    };
  })();
"
