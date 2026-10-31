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
  list(id = "map", title = "A map of the methods",
       text = "Every analysis powerkit knows about, arranged by the question a study asks, with which ones powerkit calculates. Move around it and open any analysis's page."),
  list(id = "prereplication", title = "Pre-replication notes",
       text = "Before replicating a finding: three questions to think through whether, why and how to replicate it, and the smallest effect the original study could detect."),
  list(id = "published", title = "Plan from a published result",
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
    conditionalPanel("input.labs_tool == 'map'",
      tags$button(type = "button", class = "btn btn-link labs-back", onclick = "pkLabsOpen('')", "\u2190 All Labs tools"),
      div(class = "labs-notice", role = "note", tags$strong("Experimental. "),
        "The map is drawn from powerkit's design finder; it shows where each question leads, not which analysis is right for your study."),
      map_ui(tree)),
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
      window.pkLabsTool = tool || '';
      var s = store(); if (s) { try { if (tool) s.setItem('powerkit-labs-tool', tool); else s.removeItem('powerkit-labs-tool'); } catch (e) {} }
      var top = document.getElementById('labs-notes'); if (top) top.scrollIntoView();
      if (tool === 'map' && window.pkMapShown) setTimeout(window.pkMapShown, 100);
    };
    $(document).on('shiny:connected', function() {
      var s = store(); var t = null; if (s) { try { t = s.getItem('powerkit-labs-tool'); } catch (e) {} }
      // A shared link (?page=labs&tool=...) opens that tool.
      var linked = new URLSearchParams(window.location.search).get('tool');
      if (linked && /^[a-z]+$/.test(linked)) t = linked;
      if (t) { Shiny.setInputValue('labs_tool', t); window.pkLabsTool = t; }
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

# Plan from a published result (Labs): the effect as a paper reported it,
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

published_ui <- function() {
  designs <- stats::setNames(names(published_designs), vapply(published_designs, `[[`, "", "label"))
  conditionalPanel("input.labs_tool == 'published'",
    tags$button(type = "button", class = "btn btn-link labs-back", onclick = "pkLabsOpen('')", "\u2190 All Labs tools"),
    div(class = "labs-notice", role = "note", tags$strong("Experimental. "),
      "The numbers come from powerkit's engine (effectsize and psych for the conversion, psych for the safeguard interval); nothing is sent anywhere."),
    h3("Plan from a published result"),
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
