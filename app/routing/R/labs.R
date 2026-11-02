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
  list(id = "map", title = "Methods map",
       text = "Every analysis powerkit knows about, arranged by the question a study asks, with which ones powerkit calculates. Move around it and open any analysis's page."),
  list(id = "prereplication", title = "Pre-replication notes",
       text = "Before replicating a finding: three questions to think through whether, why and how to replicate it, and the smallest effect the original study could detect."),
  list(id = "picture", title = "Power visualiser",
       text = "For a two-group t-test or a correlation: move the sample size and the effect, choose alpha, and see the two distributions behind power (no effect, and the effect you set), with power, its complement and the smallest effect that would be significant."),
  list(id = "bayes", title = "Bayesian planning",
       text = "For a Bayes factor t-test: choose the prior the Bayes factor will use and, separately, what you believe about the effect, and see how often a study of the size you set would give strong evidence for an effect, strong evidence for none, or neither."),
  list(id = "published", title = "Effect size converter",
       text = "Enter an effect as a paper reported it (for example t(58) = 2.5, an F or an odds ratio) and see it as the effect size a power analysis uses, with a safeguard value that allows for published effects being too large.")
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

labs_citation <- function(path = labs_refs_path(), key = labs_ref_key,
                          fallback = "See https://doi.org/10.15626/MP.2024.4155") {
  if (!nzchar(path) || !file.exists(path)) return(fallback)
  ns <- tryCatch(asNamespace("powerkit"), error = function(e) NULL)
  # A partly loaded engine (no bib reader) or a reading error gives the
  # fallback, never an error page.
  if (is.null(ns) || !is.function(ns$read_bib) || !is.function(ns$bib_entry_text)) return(fallback)
  tryCatch({
    entry <- ns$read_bib(path)[[key]]
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
    conditionalPanel("input.labs_tool == 'map'",
      tags$button(type = "button", class = "btn btn-link labs-back", onclick = "pkLabsOpen('')", "\u2190 All Labs tools"),
      div(class = "labs-notice", role = "note", tags$strong("Experimental. "),
        "The map is drawn from powerkit's design finder; it shows where each question leads, not which analysis is right for your study."),
      map_ui(tree)),
    picture_ui(),
    bayes_ui(),
    published_ui(),
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
      " can help you think it through first (optional). ",
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
      window.pkLabsTool = tool || '';
      var s = store(); if (s) { try { if (tool) s.setItem('powerkit-labs-tool', tool); else s.removeItem('powerkit-labs-tool'); } catch (e) {} }
      var top = document.getElementById('labs-notes'); if (top) top.scrollIntoView();
      // The methods map opens full screen.
      if (tool === 'map') window.pkMapWantFull = true;
      if (tool === 'map' && window.pkMapShown) setTimeout(window.pkMapShown, 100);
    };
    $(document).on('shiny:connected', function() {
      var s = store(); var t = null; if (s) { try { t = s.getItem('powerkit-labs-tool'); } catch (e) {} }
      // A shared link (?page=labs&tool=...) opens that tool.
      var linked = new URLSearchParams(window.location.search).get('tool');
      if (linked && /^[a-z]+$/.test(linked)) t = linked;
      if (t) { Shiny.setInputValue('labs_tool', t); window.pkLabsTool = t; if (t === 'map') window.pkMapWantFull = true; }
    });
    // The map can only measure itself once it is on screen.
    $(document).on('shown.bs.tab shiny:conditional', function() {
      var v = document.getElementById('map-canvas');
      if (v && v.offsetParent && window.pkMapShown) window.pkMapShown();
    });
    Shiny.addCustomMessageHandler('labs_open', function(tool) { window.pkLabsOpen(tool); });
    window.pkLabsHideHint = function() {
      document.body.classList.add('labs-hint-hidden');
      var s = store(); if (s) { try { s.setItem('powerkit-labs-hint-hidden', '1'); } catch (e) {} }
    };
  })();
"

# Effect size converter (Labs, "Plan from a published result" until 0.25.1): the effect as a paper reported it,
# converted by the engine (convert_effect(): psych's t2d() for t and F into
# d or d_z, effectsize for the rest) into the
# effect size a card uses, and the safeguard effect size (safeguard_effect(),
# Perugini, Gallucci & Costantini, 2014) where the design has one. The app
# only calls the engine. The forms each kind of study takes follow the
# cards' (conversion_choices, R/forms.R).
published_designs <- list(
  independent_t = list(label = "Two separate groups compared on a score (t-test)", effect = "Cohen's d"),
  paired_t = list(label = "The same people measured twice (paired t-test)", effect = "d_z"),
  one_sample_t = list(label = "One group compared with a fixed value", effect = "Cohen's d"),
  correlation = list(label = "Two scores and how they are related (correlation)", effect = "r"),
  oneway_between = list(label = "Different groups in an ANOVA", effect = "partial eta-squared")
)

published_from_choices <- function(design) {
  d <- published_designs[[design]]
  own <- stats::setNames(list("as_is"), sprintf("%s itself", d$effect))
  from <- conversion_choices[[design]]
  labels <- conversion_labels[from]
  if (identical(design, "oneway_between")) labels$F <- "An F statistic, with its two degrees of freedom"
  c(own, stats::setNames(as.list(from), unname(unlist(labels))))
}

# What the tool shows, from its inputs: list(lines, problems). `convert`
# and `safeguard` are the engine's convert_effect() and safeguard_effect().
published_result <- function(values, convert, safeguard) {
  num <- function(x) suppressWarnings(as.numeric(trimws(as.character(x %||% ""))))
  whole <- function(x) { v <- num(x); if (is.na(v) || v != round(v)) NA else as.integer(v) }
  design <- values$pub_design %||% ""
  from <- values$pub_from %||% "as_is"
  value <- num(values$pub_value)
  problems <- character()
  if (!design %in% names(published_designs)) problems <- c(problems, "Choose the kind of study first.")
  if (is.na(value)) problems <- c(problems, "Enter the published value as a number.")
  if (from %in% c("t", "F") && is.na(whole(values$pub_df))) {
    problems <- c(problems, "Enter its error degrees of freedom as a whole number (the df of t, or the second df of F).")
  }
  if (identical(from, "F") && identical(design, "oneway_between") && is.na(whole(values$pub_df1))) {
    problems <- c(problems, "Enter the F statistic's first degrees of freedom (the effect's df) as a whole number.")
  }
  if (length(problems)) return(list(lines = character(), problems = problems))
  d <- published_designs[[design]]
  lines <- character()
  estimate <- value
  if (!identical(from, "as_is")) {
    # Two groups of unequal size: the group sizes, when both are given,
    # enter the conversion as well as the safeguard value.
    n1 <- whole(values$pub_n1)
    n2 <- whole(values$pub_n2)
    sized <- identical(design, "independent_t") && !is.na(n1) && !is.na(n2)
    out <- tryCatch(
      convert(from, value, design, df_error = if (from %in% c("t", "F")) whole(values$pub_df),
              n1 = if (sized) n1, n2 = if (sized) n2,
              df = if (identical(from, "F") && identical(design, "oneway_between")) whole(values$pub_df1)),
      error = function(e) e)
    if (inherits(out, "error")) {
      problem <- if (inherits(out, "powerkit_error")) sub("^This design spec has an? problems?:\n\\* ", "", conditionMessage(out)) else
        "powerkit couldn't convert this value: something went wrong in its engine. Please report this, with the values you entered."
      return(list(lines = character(), problems = problem))
    }
    estimate <- out$value
    lines <- c(lines, sprintf("Converted: %s = %s, %s.",
      d$effect, format(round(estimate, 3), nsmall = 2), conversion_package_text(out$package$name, out$function_used)))
  }
  sizes <- safeguard_sizes[[design]]
  if (is.null(sizes)) {
    lines <- c(lines, sprintf("Safeguard power isn't available for %s yet: use the value above, adjusted down for publication bias.", d$effect))
  } else {
    n <- if (identical(sizes, "n")) list(n = whole(values$pub_n)) else list(n1 = whole(values$pub_n1), n2 = whole(values$pub_n2))
    protection <- num(values$pub_protection %||% "0.8")
    if (any(vapply(n, function(x) is.na(x) || is.null(x), logical(1)))) {
      lines <- c(lines, "For a safeguard value, enter how many people the published study had.")
    } else {
      sg <- tryCatch(do.call(safeguard, c(list(estimate = estimate, template = design), n, list(protection = protection))), error = function(e) e)
      if (inherits(sg, "error") || is.na(sg$lower) || sign(sg$lower) != sign(estimate) || sg$lower == 0) {
        lines <- c(lines, sprintf(paste0("Safeguard: the %d%% confidence interval around this estimate includes zero, so this study ",
          "can't tell you how large the effect is. Plan from the smallest effect that would matter instead."), round(100 * (2 * protection - 1))))
      } else {
        lines <- c(lines, sprintf(paste0("Safeguard: plan with %s = %s, the lower end of the %d%% confidence interval around it, ",
          "for %s %d%% chance that the true effect is at least that large if the published estimate is unbiased ",
          "(Perugini, Gallucci & Costantini, 2014)."), d$effect, format(round(sg$lower, 3), nsmall = 2),
          round(100 * sg$conf_level), if (round(100 * sg$protection) %in% c(8, 11, 18, 80:89)) "an" else "a", round(100 * sg$protection)))
      }
    }
  }
  lines <- c(lines, paste("Published effects tend to be larger than the true effect, because studies with larger effects are",
    "more likely to be published. A single study's estimate is also uncertain. The safeguard value allows for the",
    "second; neither number corrects for the first."))
  list(lines = lines, problems = character())
}

# Power visualiser (Labs, "A picture of power" until 0.25.1): the engine's power_picture() gives the curves
# and the numbers (pwr's power, base R's t densities); the app draws them.
picture_alphas <- c("0.005", "0.01", "0.05", "0.10")

picture_ui <- function() {
  conditionalPanel("input.labs_tool == 'picture'",
    tags$button(type = "button", class = "btn btn-link labs-back", onclick = "pkLabsOpen('')", "← All Labs tools"),
    div(class = "labs-notice", role = "note", tags$strong("Experimental. "),
      "For learning what power means, not for planning a study: the numbers come from powerkit's engine (pwr for power; R's t, F, chi-square and normal distributions for the curves)."),
    h3("Power visualiser"),
    selectInput("picture_design", "Which test?", choices = c("A two-group t-test (equal groups)" = "t",
      "A paired-samples t-test (the same people twice)" = "paired", "A one-way ANOVA (equal groups)" = "anova",
      "Two groups' proportions (equal groups)" = "two_proportions", "A correlation (Pearson's r)" = "r",
      "A chi-square test (goodness of fit or a table)" = "chisq", "A regression's R-squared (the F test)" = "regression"),
      selected = "t", selectize = FALSE, width = "100%"),
    conditionalPanel("input.picture_design == 't'",
      p("A two-group t-test with equal groups. The grey curve is the t statistic you would see if there were no effect; the blue curve is the t statistic for the effect you set. A result beyond the dashed lines is significant."),
      sliderInput("picture_n", "Total number of participants (two equal groups)", min = 10, max = 400, value = 64, step = 2, width = "100%"),
      sliderInput("picture_d", "Cohen's d in the population", min = 0, max = 1.5, value = 0.5, step = 0.05, width = "100%")),
    conditionalPanel("input.picture_design == 'paired'",
      p("A paired-samples t-test: each person measured twice (or one score per person against a fixed value). The grey curve is the t statistic if there were no effect; the blue curve is the t statistic for the effect you set. Because each person is compared with themselves, the same d needs far fewer people than with two groups."),
      sliderInput("picture_n_paired", "Number of participants", min = 5, max = 200, value = 34, step = 1, width = "100%"),
      sliderInput("picture_dz", "Cohen's d_z in the population (the mean difference over the SD of the differences)", min = 0, max = 1.5, value = 0.5, step = 0.05, width = "100%")),
    conditionalPanel("input.picture_design == 'anova'",
      p("A one-way ANOVA with equal groups. The grey curve is the F statistic if the groups' means were all the same; the blue curve is the F statistic for the effect you set. Only large F values are significant, so there is one dashed line."),
      sliderInput("picture_k", "Number of groups", min = 2, max = 6, value = 3, step = 1, width = "100%"),
      sliderInput("picture_n_per", "Participants in each group", min = 3, max = 150, value = 52, step = 1, width = "100%"),
      sliderInput("picture_f", "Cohen's f in the population", min = 0, max = 0.8, value = 0.25, step = 0.05, width = "100%")),
    conditionalPanel("input.picture_design == 'two_proportions'",
      p("Two groups compared on a yes/no outcome, as pwr's formula treats it (Cohen's h, the arcsine approximation). The grey curve is the test statistic if the groups didn't differ; the blue curve is the test statistic for the proportions you set."),
      sliderInput("picture_n_2p", "Total number of participants (two equal groups)", min = 10, max = 600, value = 194, step = 2, width = "100%"),
      sliderInput("picture_p1", "Proportion of 'yes' in group 1", min = 0.05, max = 0.95, value = 0.4, step = 0.05, width = "100%"),
      sliderInput("picture_p2", "Proportion of 'yes' in group 2", min = 0.05, max = 0.95, value = 0.6, step = 0.05, width = "100%")),
    conditionalPanel("input.picture_design == 'r'",
      p("A correlation, tested two-sided. The curves are the correlation you would observe, on the scale of Fisher's z, as pwr's formula treats it: grey if there were no correlation, blue for the correlation you set. A result beyond the dashed lines is significant."),
      sliderInput("picture_n_r", "Number of participants", min = 10, max = 400, value = 84, step = 1, width = "100%"),
      sliderInput("picture_r", "Correlation in the population", min = 0, max = 0.8, value = 0.3, step = 0.05, width = "100%")),
    conditionalPanel("input.picture_design == 'chisq'",
      p(class = "small text-muted", "Cohen's w measures how far the observed counts depart from what no effect predicts (0.1 small, 0.3 medium, 0.5 large, in Cohen's terms). The degrees of freedom are the categories minus 1 for goodness of fit, or (rows - 1) × (columns - 1) for a table."),
      sliderInput("picture_n_chisq", "Number of participants", min = 10, max = 500, value = 88, step = 1, width = "100%"),
      sliderInput("picture_w", "Cohen's w in the population", min = 0, max = 0.8, value = 0.3, step = 0.05, width = "100%"),
      sliderInput("picture_df_chisq", "Degrees of freedom", min = 1, max = 8, value = 1, step = 1, width = "100%")),
    conditionalPanel("input.picture_design == 'regression'",
      p(class = "small text-muted", "The F test of whether the predictors together explain any of the outcome's variance. Cohen's f² = R² / (1 - R²)."),
      sliderInput("picture_n_reg", "Number of participants", min = 10, max = 400, value = 80, step = 1, width = "100%"),
      sliderInput("picture_r2", "R-squared in the population", min = 0, max = 0.5, value = 0.13, step = 0.01, width = "100%"),
      sliderInput("picture_u", "Number of predictors", min = 1, max = 10, value = 3, step = 1, width = "100%")),
    conditionalPanel("input.picture_design == 't' || input.picture_design == 'paired'",
      radioButtons("picture_sides", "Test", choices = c("Two-sided" = "two_sided", "One-sided (an effect in the expected direction)" = "greater"),
        selected = "two_sided", inline = TRUE)),
    radioButtons("picture_alpha", "Alpha", choices = picture_alphas, selected = "0.05", inline = TRUE),
    plotOutput("picture_plot", height = "320px"),
    uiOutput("picture_numbers"))
}

# Which test a picture is for (the first two pictures carry no `design`).
picture_design <- function(picture) picture$design %||% if (!is.null(picture$r)) "r" else "t"

# The engine's picture for the inputs on the Labs screen (`value(id,
# default)` reads one), or an error from the engine.
picture_for <- function(value, alpha) {
  num <- function(id, default) as.numeric(value(id) %||% default)
  switch(value("picture_design") %||% "t",
    r = engine_function("power_picture_r")(num("picture_n_r", 84), num("picture_r", 0.3), alpha = alpha),
    paired = engine_function("power_picture_paired")(num("picture_n_paired", 34), num("picture_dz", 0.5), alpha = alpha,
      alternative = value("picture_sides") %||% "two_sided"),
    chisq = engine_function("power_picture_chisq")(num("picture_n_chisq", 88), num("picture_w", 0.3), df = num("picture_df_chisq", 1), alpha = alpha),
    regression = engine_function("power_picture_f2")(num("picture_n_reg", 80), num("picture_r2", 0.13), u = num("picture_u", 3), alpha = alpha),
    anova = {
      k <- num("picture_k", 3)
      engine_function("power_picture_anova")(k * num("picture_n_per", 52), num("picture_f", 0.25), k = k, alpha = alpha)
    },
    two_proportions = engine_function("power_picture_2p")(num("picture_n_2p", 194), num("picture_p1", 0.4), num("picture_p2", 0.6), alpha = alpha),
    engine_function("power_picture")(num("picture_n", 64), num("picture_d", 0.5), alpha = alpha,
      alternative = value("picture_sides") %||% "two_sided"))
}

# Pictures with one critical value on the right: the F and chi-square
# tests, and one-sided t-tests.
picture_one_tail <- function(picture) {
  picture_design(picture) %in% c("anova", "chisq", "regression") || identical(picture$sides, 1)
}

# A sentence describing the picture, for screen readers.
picture_alt <- function(picture) {
  if (is.null(picture)) return("The picture of power")
  power <- sprintf("%.1f%%", 100 * picture$power)
  switch(picture_design(picture),
    r = sprintf("Two distributions of the observed correlation: power is %s for r = %s with %s participants at alpha = %s.",
      power, format(picture$r), format(picture$n), format(picture$alpha)),
    paired = sprintf("Two t distributions: power is %s for d_z = %s with %s participants at alpha = %s.",
      power, format(picture$dz), format(picture$n), format(picture$alpha)),
    anova = sprintf("Two F distributions: power is %s for f = %s with %s groups of %s at alpha = %s.",
      power, format(picture$f), format(picture$k), format(picture$n / picture$k), format(picture$alpha)),
    two_proportions = sprintf("Two distributions of the test statistic: power is %s for proportions of %s and %s with %s participants at alpha = %s.",
      power, format(picture$p1), format(picture$p2), format(picture$n), format(picture$alpha)),
    chisq = sprintf("Two chi-square distributions: power is %s for w = %s with %s participants and %s degrees of freedom at alpha = %s.",
      power, format(picture$w), format(picture$n), format(picture$df), format(picture$alpha)),
    regression = sprintf("Two F distributions: power is %s for R-squared = %s with %s predictors and %s participants at alpha = %s.",
      power, format(picture$r2), format(picture$u), format(picture$n), format(picture$alpha)),
    sprintf("Two t distributions: power is %s for d = %s with %s participants at alpha = %s.",
      power, format(picture$d), format(picture$n), format(picture$alpha)))
}

# The picture: both densities, the critical values, power shaded under the
# blue curve beyond them and alpha under the grey one.
picture_plot <- function(picture) {
  curves <- picture$curves
  design <- picture_design(picture)
  # The axis: t for the t-tests, Fisher's z for a correlation, z for two
  # proportions, F (one-sided) for the ANOVA.
  t <- switch(design, r = curves$z, two_proportions = curves$z, anova = curves$F, regression = curves$F, chisq = curves$x, curves$t)
  crit <- switch(design, r = picture$z_crit, two_proportions = picture$z_crit, anova = picture$f_crit, regression = picture$f_crit,
    chisq = picture$chi_crit, picture$t_crit)
  one_tail <- picture_one_tail(picture)
  skewed <- design %in% c("anova", "chisq", "regression")
  beyond <- if (one_tail) t >= crit else abs(t) >= crit
  shade <- function(y, keep, colour) {
    runs <- split(seq_along(t)[keep], cumsum(c(1, diff(seq_along(t)[keep]) != 1)))
    for (i in runs) graphics::polygon(c(t[i], rev(t[i])), c(y[i], rep(0, length(i))), col = colour, border = NA)
  }
  # The F density can be very tall near 0 with one or two numerator df.
  top <- if (skewed) min(max(curves$null, curves$alternative), 3 * max(curves$alternative)) else max(curves$null, curves$alternative)
  graphics::par(mar = c(4, 4, 1, 1))
  graphics::plot(t, curves$null, type = "n", ylim = c(0, top * 1.05),
    xlab = switch(design, r = "Observed correlation, as Fisher's z", two_proportions = "Test statistic (z)", anova = "F statistic",
      regression = "F statistic", chisq = "Chi-square statistic", "t statistic"),
    ylab = "Density", las = 1, bty = "l")
  shade(curves$alternative, beyond, grDevices::adjustcolor("#2166ac", alpha.f = 0.35))
  shade(curves$null, beyond, grDevices::adjustcolor("#b2182b", alpha.f = 0.5))
  graphics::lines(t, curves$null, col = "grey40", lwd = 2)
  graphics::lines(t, curves$alternative, col = "#2166ac", lwd = 2)
  graphics::abline(v = if (one_tail) crit else c(-1, 1) * crit, lty = 2)
  labels <- switch(design,
    r = c("No correlation", sprintf("r = %s", format(picture$r))),
    paired = c("No effect (central t)", sprintf("d_z = %s (noncentral t)", format(picture$dz))),
    anova = c("No effect (central F)", sprintf("f = %s (noncentral F)", format(picture$f))),
    regression = c("No effect (central F)", sprintf("R² = %s (noncentral F)", format(picture$r2))),
    chisq = c("No effect (central chi-square)", sprintf("w = %s (noncentral chi-square)", format(picture$w))),
    two_proportions = c("No difference", sprintf("%s against %s", format(picture$p1), format(picture$p2))),
    c("No effect (central t)", sprintf("d = %s (noncentral t)", format(picture$d))))
  graphics::legend("topright", bty = "n", cex = 0.85,
    legend = c(labels, "Power (shaded blue)", "Type I error (shaded red)"),
    col = c("grey40", "#2166ac", grDevices::adjustcolor("#2166ac", alpha.f = 0.35), grDevices::adjustcolor("#b2182b", alpha.f = 0.5)),
    lwd = c(2, 2, 8, 8))
}

# The numbers behind the picture, in words.
picture_numbers <- function(picture) {
  pct <- function(x) sprintf("%.1f%%", 100 * x)
  power_line <- function(what) tags$li(tags$strong("Power: "), pct(picture$power),
    sprintf(" (the blue area beyond the dashed %s), so beta, the chance of missing %s, is %s.",
      if (picture_one_tail(picture)) "line" else "lines", what, pct(picture$beta)))
  # A t-test's critical value and the words for its sides.
  t_crit_text <- function() if (identical(picture$sides, 1)) sprintf("%.3f", picture$t_crit) else sprintf("±%.3f", picture$t_crit)
  sides_text <- function() if (identical(picture$sides, 1)) "a one-sided test (an effect in the expected direction)" else "a two-sided test"
  source_line <- function(curves) p(class = "small text-muted", sprintf("Power from %s; curves from R's %s.", picture$function_used, curves))
  switch(picture_design(picture),
    r = tagList(
      tags$ul(class = "picture-numbers",
        power_line("the correlation"),
        tags$li(tags$strong("Spread: "), sprintf("%.3f", picture$se), sprintf(" = 1 / √(n - 3), the standard error of Fisher's z with %s participants; it shrinks as n grows, so the curves overlap less.", format(picture$n))),
        tags$li(tags$strong("Centre of the blue curve: "), sprintf("%.3f", picture$z_r), sprintf(" = Fisher's z of r = %s, with pwr's small bias correction.", format(picture$r))),
        tags$li(tags$strong("Critical value: "), sprintf("±%.3f", picture$z_crit), sprintf(" on the z scale, from the critical t of ±%.3f with %s degrees of freedom (n - 2) at alpha = %s.", picture$t_crit, picture$df, format(picture$alpha))),
        tags$li(tags$strong("Smallest significant r: "), sprintf("%.3f", picture$r_crit),
          " = critical t / √(critical t² + n - 2). Any observed correlation smaller than this isn't significant, whatever the true correlation.")),
      source_line("dnorm()")),
    paired = tagList(
      tags$ul(class = "picture-numbers",
        power_line("the effect"),
        tags$li(tags$strong("Degrees of freedom: "), picture$df, " (n - 1)."),
        tags$li(tags$strong("Noncentrality: "), sprintf("%.3f", picture$ncp), " = d_z × √n, where the blue curve is centred."),
        tags$li(tags$strong("Critical t: "), t_crit_text(), sprintf(" for %s at alpha = %s.", sides_text(), format(picture$alpha))),
        tags$li(tags$strong("Smallest significant d_z: "), sprintf("%.3f", picture$dz_crit),
          " = critical t / √n, since the paired t is d_z × √n. Any observed d_z smaller than this isn't significant, whatever the true effect.")),
      source_line("dt()")),
    anova = tagList(
      tags$ul(class = "picture-numbers",
        power_line("the effect"),
        tags$li(tags$strong("Degrees of freedom: "), sprintf("%s and %s", picture$df1, picture$df2),
          sprintf(" (k - 1 groups, and n - k with %s in each of %s groups).", format(picture$n / picture$k), format(picture$k))),
        tags$li(tags$strong("Noncentrality: "), sprintf("%.3f", picture$ncp), " = f² × n (all participants): the larger it is, the further right the blue curve sits."),
        tags$li(tags$strong("Critical F: "), sprintf("%.3f", picture$f_crit), sprintf(" at alpha = %s. Only large F values count, so the test has one critical value.", format(picture$alpha))),
        tags$li(tags$strong("Smallest significant f: "), sprintf("%.3f", picture$effect_crit),
          " = √(critical F × df1 / df2). Any observed f smaller than this isn't significant, whatever the true effect.")),
      source_line("df()")),
    regression = tagList(
      tags$ul(class = "picture-numbers",
        power_line("the effect"),
        tags$li(tags$strong("Cohen's f²: "), sprintf("%.3f", picture$f2), sprintf(" = R² / (1 - R²) for R² = %s.", format(picture$r2))),
        tags$li(tags$strong("Degrees of freedom: "), sprintf("%s and %s", picture$u, picture$v),
          sprintf(" (u = %s predictors, and v = n - u - 1).", format(picture$u))),
        tags$li(tags$strong("Noncentrality: "), sprintf("%.3f", picture$ncp), " = f² × n: the larger it is, the further right the blue curve sits."),
        tags$li(tags$strong("Critical F: "), sprintf("%.3f", picture$f_crit), sprintf(" at alpha = %s. Only large F values count, so the test has one critical value.", format(picture$alpha))),
        tags$li(tags$strong("Smallest significant R²: "), sprintf("%.3f", picture$r2_crit),
          sprintf(" (f² = %.3f = critical F × u / v). Any observed R² smaller than this isn't significant, whatever the true one.", picture$effect_crit))),
      source_line("df()")),
    chisq = tagList(
      tags$ul(class = "picture-numbers",
        power_line("the effect"),
        tags$li(tags$strong("Degrees of freedom: "), picture$df, "."),
        tags$li(tags$strong("Noncentrality: "), sprintf("%.3f", picture$ncp), " = w² × n: the larger it is, the further right the blue curve sits."),
        tags$li(tags$strong("Critical chi-square: "), sprintf("%.3f", picture$chi_crit), sprintf(" at alpha = %s. Only large values count, so the test has one critical value.", format(picture$alpha))),
        tags$li(tags$strong("Smallest significant w: "), sprintf("%.3f", picture$effect_crit),
          " = √(critical chi-square / n). Any observed w smaller than this isn't significant, whatever the true effect.")),
      source_line("dchisq()")),
    two_proportions = tagList(
      tags$ul(class = "picture-numbers",
        power_line("the difference"),
        tags$li(tags$strong("Cohen's h: "), sprintf("%.3f", picture$h), sprintf(" = 2 asin(√%s) - 2 asin(√%s): the difference between the proportions on the arcsine scale pwr uses.", format(picture$p2), format(picture$p1))),
        tags$li(tags$strong("Centre of the blue curve: "), sprintf("%.3f", picture$centre), sprintf(" = |h| × √(n per group / 2), with %s in each group.", format(picture$n / 2))),
        tags$li(tags$strong("Critical z: "), sprintf("±%.3f", picture$z_crit), sprintf(" for a two-sided test at alpha = %s.", format(picture$alpha))),
        tags$li(tags$strong("Smallest significant h: "), sprintf("%.3f", picture$h_crit),
          " = critical z × √(2 / n per group). Any observed difference smaller than this isn't significant, whatever the true one.")),
      source_line("dnorm()")),
    tagList(
      tags$ul(class = "picture-numbers",
        power_line("the effect"),
        tags$li(tags$strong("Degrees of freedom: "), picture$df, sprintf(" (n - 2, with %s in each group).", format(picture$n / 2))),
        tags$li(tags$strong("Noncentrality: "), sprintf("%.3f", picture$ncp), " = d × √(n per group / 2), where the blue curve is centred."),
        tags$li(tags$strong("Critical t: "), t_crit_text(), sprintf(" for %s at alpha = %s.", sides_text(), format(picture$alpha))),
        tags$li(tags$strong("Smallest significant d: "), sprintf("%.3f", picture$d_crit),
          " = critical t × √(1/n1 + 1/n2) (Lakens, 2013). Any observed d smaller than this isn't significant, whatever the true effect.")),
      source_line("dt()")))
}

published_ui <- function() {
  designs <- stats::setNames(names(published_designs), vapply(published_designs, `[[`, "", "label"))
  conditionalPanel("input.labs_tool == 'published'",
    tags$button(type = "button", class = "btn btn-link labs-back", onclick = "pkLabsOpen('')", "\u2190 All Labs tools"),
    div(class = "labs-notice", role = "note", tags$strong("Experimental. "),
      "The numbers come from powerkit's engine (effectsize and psych for the conversion, psych for the safeguard interval); nothing is sent anywhere."),
    h3("Effect size converter"),
    p("Enter an effect as a paper reported it. powerkit shows it as the effect size a power analysis uses and, where it can, a safeguard value to plan with instead."),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "The published result"),
      selectInput("pub_design", "What kind of study was it?", choices = c("Choose one" = "", designs), selectize = FALSE, width = "100%"),
      uiOutput("pub_from_ui"),
      textInput("pub_value", "The published value", width = "100%"),
      conditionalPanel("input.pub_from == 'F' && input.pub_design == 'oneway_between'",
        textInput("pub_df1", "Its first degrees of freedom (the effect's df, the first number in F(df1, df2))", width = "100%")),
      conditionalPanel("input.pub_from == 't' || input.pub_from == 'F'",
        textInput("pub_df", "Its error degrees of freedom (the second df of F, or the df of t)", width = "100%"))),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "The published study's size (for the safeguard value, and for converting a t or F from groups of different sizes)"),
      conditionalPanel("input.pub_design == 'independent_t'",
        textInput("pub_n1", "People in group 1 of the published study", width = "100%"),
        textInput("pub_n2", "People in group 2 of the published study", width = "100%")),
      conditionalPanel("input.pub_design == 'paired_t' || input.pub_design == 'one_sample_t' || input.pub_design == 'correlation'",
        textInput("pub_n", "People in the published study", width = "100%")),
      selectInput("pub_protection", "Protection against the estimate being too large", selectize = FALSE, width = "100%",
        choices = c("80% (the lower end of a 60% confidence interval)" = "0.8", "95% (the lower end of a 90% confidence interval)" = "0.95"))),
    actionButton("pub_run", "Work it out", class = "btn btn-primary"),
    uiOutput("pub_result"))
}

# Bayesian planning (Labs): the engine's bayes_planning() gives every chance
# (bfpwr's ptbf01(), powertbf01() and tbf01()) and the prior densities; the
# app draws them. The analysis prior and the design prior are set apart, as
# bfpwr keeps them (its vignette "using-bfpwr"), and no single power figure
# is shown: the three outcomes appear under the belief and with no effect.
bayes_types <- c("Two groups (people in each group)" = "two.sample",
  "One group against a fixed value (people)" = "one.sample",
  "Paired or repeated measures (pairs)" = "paired")
bayes_thresholds <- c("3" = "3", "6" = "6", "10" = "10", "30" = "30")
bayes_designs <- c("Once, at the sample size above (a fixed design)" = "fixed",
  "As the data come in, stopping when the evidence is strong (a sequential design)" = "sequential")
bayes_directions <- c("Either direction (two-sided)" = "two.sided",
  "A positive effect (one-sided)" = "greater", "A negative effect (one-sided)" = "less")

bayes_ui <- function() {
  conditionalPanel("input.labs_tool == 'bayes'",
    tags$button(type = "button", class = "btn btn-link labs-back", onclick = "pkLabsOpen('')", "← All Labs tools"),
    div(class = "labs-notice", role = "note", tags$strong("Experimental. "),
      "Every number comes from powerkit's engine, with the R package bfpwr (Pawel and Held); nothing is sent anywhere."),
    h3("Bayesian planning"),
    p("A Bayes factor compares how well two hypotheses predict the data: an effect against no effect. A study can end three ways: strong evidence for an effect, strong evidence for no effect, or neither. This tool shows how often each happens, for the study size you set, in two worlds: if the effect is what you believe, and if there is no effect."),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "1. The study"),
      selectInput("bayes_type", "The design", choices = bayes_types, selectize = FALSE, width = "100%"),
      numericInput("bayes_n", "Sample size (in each group, for two groups)", value = 120, min = 3, max = 10000, step = 1, width = "100%"),
      radioButtons("bayes_alternative", "The hypothesis", choices = bayes_directions, selected = "two.sided", width = "100%")),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "2. The analysis prior: what the Bayes factor will assume"),
      p(class = "group-note", "When the data are in, the Bayes factor compares no effect with a spread of possible effects: a Cauchy distribution centred on 0. Its scale says how large effects are expected to be; 0.707 is the usual default (bfpwr's, and JASP's). A reader should be able to accept it, so it is chosen before the data and reported."),
      numericInput("bayes_scale", "Scale of the Cauchy prior", value = 0.707, min = 0.05, max = 5, step = 0.05, width = "100%")),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "3. The design prior: what you believe about the effect now"),
      p(class = "group-note", "Separate from the analysis prior. This is your honest belief about the true standardised effect (Cohen's d, or d_z for pairs), with your uncertainty about it as an SD. An SD of 0 plans for exactly that effect, as most power analyses do; a larger SD averages over the effects you think plausible, which usually lowers the chances."),
      numericInput("bayes_effect", "The effect you expect", value = 0.5, min = -5, max = 5, step = 0.05, width = "100%"),
      numericInput("bayes_effect_sd", "Your uncertainty about it (an SD; 0 for none)", value = 0.15, min = 0, max = 5, step = 0.05, width = "100%")),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "4. What counts as strong evidence"),
      radioButtons("bayes_threshold", "A Bayes factor of at least (either way)", choices = bayes_thresholds, selected = "10", inline = TRUE),
      p(class = "group-note", "There is no correct threshold: a higher one asks more of the data, and evidence for no effect needs larger studies than evidence for an effect."),
      numericInput("bayes_target", "Find the sample size that gives strong evidence for an effect with this chance", value = 0.8, min = 0.05, max = 0.99, step = 0.05, width = "100%")),
    tags$fieldset(class = "form-group-box", tags$legend(class = "h6", "5. When you look at the data"),
      radioButtons("bayes_design", NULL, choices = bayes_designs, selected = "fixed", width = "100%"),
      conditionalPanel("input.bayes_design == 'sequential'",
        p(class = "group-note", "A sequential design computes the Bayes factor as the data come in, and stops as soon as it is strong either way, or at the largest sample size you can afford: the sample size in section 1. Decide every setting before the data, and report them."),
        numericInput("bayes_n_min", "First look, after this many (in each group, for two groups)", value = 20, min = 3, max = 10000, step = 1, width = "100%"),
        numericInput("bayes_step", "Then look again after every", value = 1, min = 1, max = 1000, step = 1, width = "100%"),
        radioButtons("bayes_threshold_null", "Stop for no effect at a Bayes factor of at least", choices = bayes_thresholds, selected = "10", inline = TRUE),
        p(class = "group-note", "It can differ from the threshold for an effect: a lower one for no effect stops sooner when there is none, at the cost of more misleading evidence for no effect."))),
    actionButton("bayes_run", "Work it out", class = "btn btn-primary"),
    uiOutput("bayes_result"))
}

# The engine's refusal in the words of the form: its messages name the
# argument, which is swapped for the field's label; anything else is a
# plain apology, never R's own text.
bayes_problem <- function(e) {
  if (!inherits(e, "powerkit_error")) {
    return("powerkit couldn't work this out: something went wrong in its engine. Please report this, with the values you entered.")
  }
  labels <- c("'n'" = "The sample size", "'effect_sd' (the uncertainty about the effect)" = "Your uncertainty about the effect",
    "'effect'" = "The effect you expect", "'prior_scale'" = "The scale of the Cauchy prior",
    "'threshold'" = "The threshold", "'target'" = "The chance to aim for",
    "'n_min' (the first look)" = "The first look", "'n_max' (the largest sample size)" = "The sample size",
    "'step' (participants between looks)" = "The number between looks",
    "'threshold_null' (the threshold for no effect)" = "The threshold for no effect")
  message <- conditionMessage(e)
  for (arg in names(labels)) message <- sub(arg, labels[[arg]], message, fixed = TRUE)
  message
}

bayes_ref_key <- "bfpwr_method"
bayes_citation <- function(path = labs_refs_path()) {
  labs_citation(path, key = bayes_ref_key, fallback = "Pawel, S., & Held, L. (2025), the R package bfpwr.")
}

# Fewer than 50 degrees of freedom: where powerkit's validation finds bfpwr's
# normal approximation a few points below simulation (conventions.md,
# "Known differences").
bayes_small <- function(plan) {
  df <- if (identical(plan$type, "two.sample")) 2 * plan$n - 2 else plan$n - 1
  df < 50
}

bayes_size_words <- function(plan) {
  if (identical(plan$type, "two.sample")) sprintf("%s in each group", format(plan$n)) else
    sprintf("%s %s", format(plan$n), if (identical(plan$type, "paired")) "pairs" else "people")
}

# The three outcomes under the belief and with no effect, as a table, with
# the misleading outcomes named.
bayes_numbers <- function(plan) {
  pct <- function(x) sprintf("%.1f%%", 100 * x)
  o <- plan$outcomes
  belief <- o[o$truth == "belief", ]
  null <- o[o$truth == "null", ]
  k <- format(plan$threshold)
  belief_words <- if (plan$effect_sd > 0) sprintf("If the effect is about %s (give or take %s)", format(plan$effect), format(plan$effect_sd)) else
    sprintf("If the effect is exactly %s", format(plan$effect))
  target <- paste0(format(100 * plan$target), "%")
  a_target <- paste(if (grepl("^(8|11|18)", target)) "an" else "a", target)
  needed <- if (is.na(plan$n_needed)) sprintf("More than 10,000 %s would be needed for %s chance of strong evidence for an effect.",
      if (identical(plan$type, "two.sample")) "in each group" else "participants", a_target) else
    sprintf("For %s chance of strong evidence for an effect, under your belief: %s %s.", a_target, format(plan$n_needed),
      if (identical(plan$type, "two.sample")) "in each group" else if (identical(plan$type, "paired")) "pairs" else "people")
  tagList(
    h4(class = "h5 mt-3", sprintf("With %s", bayes_size_words(plan))),
    tags$table(class = "table table-sm bayes-outcomes",
      tags$caption(sprintf("How often the study ends each way (strong evidence: a Bayes factor of at least %s).", k)),
      tags$thead(tags$tr(tags$th(scope = "col", ""), tags$th(scope = "col", "Strong evidence for an effect"),
        tags$th(scope = "col", "Strong evidence for no effect"), tags$th(scope = "col", "Neither"))),
      tags$tbody(
        tags$tr(tags$th(scope = "row", belief_words), tags$td(pct(belief$for_effect)),
          tags$td(pct(belief$for_null), if (plan$effect != 0) " (misleading)"), tags$td(pct(belief$neither))),
        tags$tr(tags$th(scope = "row", "If there is no effect"), tags$td(pct(null$for_effect), " (misleading)"),
          tags$td(pct(null$for_null)), tags$td(pct(null$neither))))),
    tags$ul(class = "bayes-notes",
      tags$li(needed),
      if (plan$effect_sd > 0) tags$li(sprintf(
        "Averaged over your uncertainty like this, the %s chance of strong evidence for an effect is the study's assurance: the chance it succeeds given what you believe now, rather than if one guessed effect were exactly right (O'Hagan, Stevens and Campbell, 2005, who define it for clinical trials).",
        pct(belief$for_effect))),
      if (!is.na(plan$largest_bf01)) tags$li(sprintf(
        "The most evidence for no effect this study can give is a Bayes factor of %.1f (when the observed effect is exactly 0)%s.",
        plan$largest_bf01, if (plan$largest_bf01 < plan$threshold) sprintf(", so it can never reach %s in favour of no effect, however true that is", k) else "")),
      tags$li("These chances are not power in the usual sense: they don't depend on a significance level, and a study can end with neither, which is a result, not a failure."),
      if (bayes_small(plan)) tags$li("With this few participants, bfpwr's calculation (which treats the effect estimate as normally distributed) gives a chance of strong evidence for an effect a few points lower than simulated Bayes factors do.")),
    p(class = "small text-muted", sprintf("From %s, bfpwr version %s.", plan$function_used, plan$package$version)),
    p(class = "small text-muted", "Reference: ", bayes_citation()),
    if (plan$effect_sd > 0) p(class = "small text-muted", "Assurance: ", labs_citation(key = "OHagan2005_assurance",
      fallback = "O'Hagan, A., Stevens, J. W., & Campbell, M. J. (2005). Assurance in clinical trial design. Pharmaceutical Statistics.")))
}

# A sequential design (the engine's bayes_sequential()): how often the study
# stops each way, and how large it is when it stops, under the belief and
# with no effect, beside a single test at the largest sample size.
bayes_sequential_numbers <- function(plan) {
  pct <- function(x) sprintf("%.1f%%", 100 * x)
  o <- plan$outcomes
  belief <- o[o$truth == "belief", ]
  null <- o[o$truth == "null", ]
  unit <- if (identical(plan$type, "two.sample")) " in each group" else if (identical(plan$type, "paired")) " pairs" else ""
  size <- function(row) sprintf("%s (80%% stop by %s)", format(row$n_median), format(row$n_80))
  belief_words <- if (plan$effect_sd > 0) sprintf("If the effect is about %s (give or take %s)", format(plan$effect), format(plan$effect_sd)) else
    sprintf("If the effect is exactly %s", format(plan$effect))
  looks <- if (plan$step == 1) "after every participant" else sprintf("after every %s participants", format(plan$step))
  if (identical(plan$type, "two.sample")) looks <- paste(looks, "in each group")
  at_max_words <- function(row, truth) {
    if (is.na(row$at_max_toward_effect) || row$at_max == 0) return(NULL)
    sprintf("%s: of the %s that reach %s, %s end with a BF10 above 3, %s below 1/3, and %s in between.",
      truth, pct(row$at_max), format(plan$n_max), pct(row$at_max_toward_effect), pct(row$at_max_toward_null), pct(row$at_max_neither))
  }
  f <- plan$fixed
  mc <- max(o$mcse_for_effect, sqrt(0.25 / plan$nsim))
  tagList(
    h4(class = "h5 mt-3", sprintf("Looking from %s%s, %s, up to %s%s", format(plan$n_min), unit, looks, format(plan$n_max), unit)),
    tags$table(class = "table table-sm bayes-outcomes",
      tags$caption(sprintf("How often the study stops each way (strong evidence: a BF10 of at least %s for an effect, a BF01 of at least %s for no effect), and its size when it stops.",
        format(plan$threshold), format(plan$threshold_null))),
      tags$thead(tags$tr(tags$th(scope = "col", ""), tags$th(scope = "col", "Stops with strong evidence for an effect"),
        tags$th(scope = "col", "Stops with strong evidence for no effect"), tags$th(scope = "col", "Reaches the largest size without either"),
        tags$th(scope = "col", sprintf("Size when it stops: median%s", unit)))),
      tags$tbody(
        tags$tr(tags$th(scope = "row", belief_words), tags$td(pct(belief$for_effect)),
          tags$td(pct(belief$for_null), if (plan$effect != 0) " (misleading)"), tags$td(pct(belief$at_max)), tags$td(size(belief))),
        tags$tr(tags$th(scope = "row", "If there is no effect"), tags$td(pct(null$for_effect), " (misleading)"),
          tags$td(pct(null$for_null)), tags$td(pct(null$at_max)), tags$td(size(null))))),
    tags$ul(class = "bayes-notes",
      tags$li(sprintf("Testing once at %s%s instead: strong evidence for an effect %s of the time under your belief, and misleading strong evidence for an effect %s of the time if there is none.",
        format(plan$n_max), unit, pct(f$for_effect[f$truth == "belief"]), pct(f$for_effect[f$truth == "null"]))),
      if (!is.null(at_max_words(belief, "Under your belief"))) tags$li(at_max_words(belief, "Under your belief"), " ",
        at_max_words(null, "With no effect")),
      tags$li("Looking more often raises the chance of misleading evidence a little, and most of it happens at the early looks, so a later first look, or a higher threshold, lowers it (Schönbrodt and Wagenmakers, 2018)."),
      tags$li(sprintf("Simulated: %s studies under your belief and %s with no effect (seed %s), each with its own true effect drawn from your design prior; each chance is within about %s points either way.",
        format(plan$nsim, big.mark = ","), format(plan$nsim, big.mark = ","), format(plan$seed), sprintf("%.1f", 200 * mc)))),
    p(class = "small text-muted", sprintf("From %s, with the Bayes factor from bfpwr version %s (tbf01()).", plan$function_used, plan$package$version)),
    p(class = "small text-muted", "References: ", bayes_sequential_citations()))
}

bayes_sequential_citations <- function(path = labs_refs_path()) {
  paste(
    labs_citation(path, key = "Schonbrodt2017_sequential",
      fallback = "Schönbrodt, F. D., Wagenmakers, E.-J., Zehetleitner, M., & Perugini, M. (2017). Psychological Methods."),
    labs_citation(path, key = "SchonbrodtWagenmakers2018_bfda",
      fallback = "Schönbrodt, F. D., & Wagenmakers, E.-J. (2018). Psychonomic Bulletin & Review."),
    bayes_citation(path)
  )
}

# The share of simulated studies that have stopped by each sample size,
# under the belief and with no effect.
bayes_stops_plot <- function(plan) {
  st <- plan$stops
  graphics::par(mar = c(4, 4, 1, 1))
  belief <- st[st$truth == "belief", ]
  null <- st[st$truth == "null", ]
  graphics::plot(belief$n, 100 * cumsum(belief$count) / plan$nsim, type = "s", lwd = 2, col = "#2166ac", ylim = c(0, 100),
    xlim = range(st$n), las = 1, bty = "l",
    xlab = if (identical(plan$type, "two.sample")) "Sample size in each group" else "Sample size",
    ylab = "Studies stopped by this size (%)")
  graphics::lines(null$n, 100 * cumsum(null$count) / plan$nsim, type = "s", lwd = 2, col = "#b2182b", lty = 2)
  graphics::legend("bottomright", bty = "n", cex = 0.85, lwd = 2, col = c("#2166ac", "#b2182b"), lty = c(1, 2),
    legend = c("If your belief is right", "If there is no effect"))
}

# The two priors: the analysis prior (Cauchy) and the design prior (normal,
# or a line at the effect when there is no uncertainty).
bayes_priors_plot <- function(plan) {
  pr <- plan$priors
  top <- max(pr$analysis, pr$design, na.rm = TRUE) * 1.05
  graphics::par(mar = c(4, 4, 1, 1))
  graphics::plot(pr$x, pr$analysis, type = "l", lwd = 2, col = "grey40", ylim = c(0, top), las = 1, bty = "l",
    xlab = "True standardised effect", ylab = "Density")
  if (plan$effect_sd > 0) graphics::lines(pr$x, pr$design, lwd = 2, col = "#2166ac") else
    graphics::abline(v = plan$effect, lwd = 2, col = "#2166ac")
  graphics::legend("topright", bty = "n", cex = 0.85, lwd = 2, col = c("grey40", "#2166ac"),
    legend = c(sprintf("Analysis prior (Cauchy, scale %s)", format(plan$prior_scale)),
      if (plan$effect_sd > 0) sprintf("Design prior (normal, %s ± %s)", format(plan$effect), format(plan$effect_sd)) else
        sprintf("Design prior (exactly %s)", format(plan$effect))))
}

# The chance of strong evidence for an effect (under the belief) and for no
# effect (with none), as the sample size grows.
bayes_curves_plot <- function(plan) {
  cu <- plan$curves
  graphics::par(mar = c(4, 4, 1, 1))
  graphics::plot(cu$n, 100 * cu$for_effect, type = "l", lwd = 2, col = "#2166ac", ylim = c(0, 100), las = 1, bty = "l",
    xlab = if (identical(plan$type, "two.sample")) "Sample size in each group" else "Sample size",
    ylab = "Chance of strong evidence (%)")
  graphics::lines(cu$n, 100 * cu$for_null, lwd = 2, col = "#b2182b", lty = 2)
  graphics::abline(v = plan$n, lty = 3)
  graphics::legend("bottomright", bty = "n", cex = 0.85, lwd = 2, col = c("#2166ac", "#b2182b"), lty = c(1, 2),
    legend = c("For an effect, if your belief is right", "For no effect, if there is none"))
}
