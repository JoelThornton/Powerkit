# The input screen for an end point (R/forms.R has the logic).

field_input_id <- function(f) paste0("f_", f$id)

# One field: its label, the input, and where its default comes from. A
# default's source and the group's hints are linked to the input with
# aria-describedby, so screen readers read them with the field.
field_ui <- function(f, value, described_by = character()) {
  id <- field_input_id(f)
  # One convention (22 October 2026): everything is needed unless marked
  # optional. Effect sizes say they start empty, as nothing is filled in.
  label <- if (isTRUE(f$effect)) paste0(f$label, " (starts empty)") else if (field_is_optional(f)) paste0(f$label, " (optional)") else f$label
  source_id <- paste0(id, "_default")
  help_id <- paste0(id, "_help")
  if (!is.null(f$help)) described_by <- c(help_id, described_by)
  if (!is.null(f$default_source)) described_by <- c(described_by, source_id)
  current <- if (is.null(value) || length(value) == 0) "" else as.character(value)
  input <- switch(
    f$type,
    select = selectInput(id, label, choices = c("Choose one" = "", stats::setNames(names(f$choices), unlist(f$choices))),
                         selected = current, selectize = FALSE, width = "100%"),
    table = textAreaInput(id, label, value = current, rows = 4, width = "100%"),
    textInput(id, label, value = current, width = "100%")
  )
  # Attributes on the input element itself.
  attrs <- list(`aria-describedby` = if (length(described_by)) paste(described_by, collapse = " "))
  if (isTRUE(f$required) || isTRUE(f$effect)) attrs$`aria-required` <- "true"
  if (identical(f$type, "number")) attrs$inputmode <- "decimal"
  attrs <- attrs[!vapply(attrs, is.null, logical(1))]
  tag_name <- switch(f$type, select = "select", table = "textarea", "input")
  query <- htmltools::tagQuery(input)$find(tag_name)
  input <- do.call(query$addAttrs, attrs)$allTags()
  field <- div(
    class = paste("form-field", if (isTRUE(f$effect)) "effect-field"),
    input,
    if (!is.null(f$help)) div(id = help_id, class = "field-help", f$help),
    if (!is.null(f$default_source)) div(id = source_id, class = "default-source", title = f$default_source,
      if (!is.null(f[["default"]])) sprintf("Starts at %s: %s.", f$choices[[as.character(f[["default"]])]] %||% f[["default"]], short_source(f$default_source)) else paste0(short_source(f$default_source), ".")
    )
  )
  # Labs' one way in: a line under the effect size's source, for people
  # basing it on a previous study (R/labs.R).
  if (identical(f$id, "just_type")) field <- tagList(field, observed_power_warning_ui(), labs_signpost_ui())
  # Fields needed only for some goals (power, N) appear when that goal is
  # chosen, instead of saying which goals need them.
  # (`shown_for_goals`: the same for an optional field, such as the reason
  # for the target power.)
  goals <- f$needed_for %||% f$shown_for_goals
  if (!is.null(goals)) {
    field <- conditionalPanel(paste(sprintf("input.f_goal == '%s'", goals), collapse = " || "), field)
  }
  if (is.null(f$shown_if)) return(field)
  # Shown or hidden in the browser as the other choices change; the server
  # ignores a hidden field's value (field_applies()).
  condition <- vapply(shown_if_conditions(f), function(cond) {
    other <- sprintf("input.%s", field_input_id(list(id = cond$field)))
    if (!is.null(cond[["is"]])) sprintf("%s == '%s'", other, cond[["is"]]) else sprintf("%s != '%s'", other, cond[["is_not"]])
  }, character(1))
  conditionalPanel(paste(condition, collapse = " && "), field)
}

# Where a default comes from, without the function calls and version
# numbers in brackets: "pwr's default (pwr.t.test(sig.level = 0.05), pwr
# 1.3-0)" reads "pwr's default". The full text is the line's tooltip, and
# the R script, write-up and project file keep it.
short_source <- function(text) {
  repeat {
    shorter <- gsub("\\s*\\([^()]*\\)", "", text)
    if (identical(shorter, text)) break
    text <- shorter
  }
  trimws(text)
}

# A group of fields: a fieldset whose legend is the card's "What you would
# enter" line (or the group's title), with that line's plain-English hints.
group_ui <- function(tree, g, values, index) {
  legend <- g$input %||% g$title
  hint_id <- sprintf("group-%d-hints", index)
  hints <- if (!is.null(g$input)) glossary_for(tree, g$input) else list()
  # Short name fields sit two to a row on wider screens; a legend that
  # repeats its section's title is kept for screen readers only.
  names_only <- length(g$fields) > 1 && all(vapply(g$fields, function(f) identical(f$type, "text") && grepl("_(label|level[0-9]*|levels)$", f$id), logical(1)))
  tags$fieldset(
    class = paste("form-group-box", if (names_only) "form-group-names"),
    tags$legend(class = if (identical(legend, "What you want to find out")) "visually-hidden" else "h6", legend),
    # Definitions open on request; notes that change what's needed stay in
    # view, except the reason the direction is asked first.
    if (length(hints)) tags$details(class = "form-terms", tags$summary("What these terms mean"),
      div(id = hint_id, lapply(hints, function(h) div(class = "hint", tags$dfn(h$term), ": ", h$hint)))),
    if (!is.null(g$note) && identical(g$note, direction_note)) tags$details(class = "form-terms", tags$summary("Why this is asked first"), p(class = "group-note", g$note))
    else if (!is.null(g$note)) p(class = "group-note", g$note),
    lapply(g$fields, function(f) field_ui(f, values[[f$id]] %||% f[["default"]], if (length(hints)) hint_id else character()))
  )
}

# The whole screen. `values` keeps what the user typed when the screen is
# redrawn (e.g. after changing the number of mediators).
form_ui <- function(tree, forms, ep_id, groups, values = list(), history = list()) {
  ep <- tree$endpoints[[ep_id]]
  tagList(
    screen_nav_ui("form_back", "Back to the card"),
    trail_ui(history),
    div(class = "card-eid", hidden = NA, `aria-hidden` = "true", ep_id),
    h2(paste0("Your values: ", ep$plain_name)),
    p(class = "lead", "Everything is needed unless it says optional. Effect sizes start empty: enter the value you expect, and say where it comes from."),
    if (identical(ep$status, "runs_validation_in_progress")) div(class = "status status-in-progress",
      tags$span(class = "badge-progress", "Validation in progress"), tags$strong("Runs, validation in progress."), " ", ep$validation$note),
    placeholders_at(tree, "form"),
    form_sections_ui(tree, groups, values, forms$forms[[ep_id]]),
    action_bar(
      actionButton("form_copy", "Copy my answers", class = "btn btn-outline-primary"),
      actionButton("form_check", "Check my answers", class = "btn btn-primary")
    ),
    div(id = "copy-status", class = "visually-hidden", `aria-live` = "polite"),
    uiOutput("form_copy_text"),
    uiOutput("form_result")
  )
}

# What the check found: the problems to fix, or the checked spec with a
# "calculation not wired in yet" panel.
form_result_ui <- function(ep, local_problems, check, spec = NULL) {
  if (length(local_problems)) {
    return(div(class = "form-problems", role = "alert", tabindex = "-1",
      h3(class = "h5", sprintf("%d thing%s to fix", length(local_problems), if (length(local_problems) == 1) "" else "s")),
      tags$ul(lapply(local_problems, tags$li))))
  }
  if (identical(check$status, "unavailable")) {
    return(div(class = "form-problems", role = "status", tabindex = "-1",
      h3(class = "h5", "The spec is complete, but it couldn't be checked here"),
      p("Checking needs powerkit's engine, which isn't installed where this prototype is running.")))
  }
  if (identical(check$status, "problems")) {
    return(div(class = "form-problems", role = "alert", tabindex = "-1",
      h3(class = "h5", "powerkit's checker found a problem"),
      tags$ul(lapply(check$problems, tags$li)),
      p(class = "small", "These messages come from powerkit's engine (validate_spec()).")))
  }
  div(class = "engine-placeholder not-wired", role = "status", tabindex = "-1",
    h3(class = "h5", "Calculation not wired in yet"),
    p("Your answers make a valid design spec: powerkit's checker (validate_spec()) accepted it. The calculation for this design isn't wired into the prototype yet; in the full app this spec would go to powerkit's engine."),
    if (length(check$advice)) tagList(p(tags$strong("Notes from the checker:")), tags$ul(lapply(check$advice, tags$li))),
    tags$details(tags$summary("The checked design spec (JSON)"), tags$pre(class = "spec-json", spec_json(spec)))
  )
}

# The card's next step, pinned to the bottom of the window: "Enter your
# values" where the end point has an input screen (Back and Start again are
# at the top of the screen, screen_nav_ui()).
card_nav_ui <- function(forms, ep_id) {
  if (!has_form(forms, ep_id)) return(NULL)
  action_bar(pick_button("Enter your values \u2192", "form", class = "btn btn-primary btn-lg"))
}

# Observed power (judgement call 3.1, decided 22 October 2026: warn and
# allow). Shown as soon as the source is chosen; the engine's checker gives
# the same warning with the result.
observed_power_warning_ui <- function() {
  conditionalPanel("input.f_just_type == 'own_study_result'",
    div(class = "observed-power-warning", role = "note",
      tags$strong("Observed power is widely discouraged. "),
      "Power calculated from a finished study's own effect is a post hoc power analysis, and ",
      "\u201cpost hoc power analyses are useless at best, misleading at worst\u201d ",
      "(Rubin, 2025, p. 14, citing Dziak et al., 2020). Use it only if you have to, for example if a reviewer asks, ",
      "and say how it was calculated. To plan a new study, choose the smallest effect that would matter instead."))
}

# Sections of the input screen (22 October 2026) ---------------------------

# The same groups as form_groups(), in four parts: what you want to find
# out (asked first, as it decides which other fields are needed), your
# study and hypothesis, your effect size and where it comes from (kept
# together: powerkit's main question), and the settings that start at a
# tool's default, folded into one line that shows their values. The spec,
# project files and write-up don't depend on this order.
form_section <- function(g) {
  ids <- vapply(g$fields, `[[`, "", "id")
  if ("goal" %in% ids || identical(g$title, "Your claim")) return("goal")
  if ("guess" %in% ids) return("guess")
  if ("just_type" %in% ids || any(vapply(g$fields, function(f) isTRUE(f$effect), logical(1)))) return("effect")
  starts_set <- vapply(g$fields, function(f) !is.null(f[["default"]]) || isTRUE(f$optional), logical(1))
  if (length(ids) && all(starts_set) && !"n_mediators" %in% ids) return("settings")
  "study"
}

field_is_optional <- function(f) {
  isTRUE(f$optional) && !grepl("optional|needed", f$label, ignore.case = TRUE)
}

# A choice's or value's short form for the settings line: up to the first
# colon or bracket ("Formula (pwr; ...): assumes ..." becomes "Formula").
setting_value_text <- function(f, value) {
  value <- if (is.null(value) || length(value) == 0 || identical(as.character(value), "")) NULL else as.character(value)
  if (is.null(value)) return(if (isTRUE(f$optional)) "none" else "not set")
  text <- if (identical(f$type, "select")) f$choices[[value]] %||% value else value
  trimws(sub("[:(].*$", "", text))
}

settings_summary_ui <- function(groups, values) {
  # Fields that depend on another choice (e.g. Welch's method) are left out
  # of the line; they show inside when that choice is made.
  fields <- Filter(function(f) is.null(f$shown_if), unlist(lapply(groups, `[[`, "fields"), recursive = FALSE))
  items <- lapply(fields, function(f) {
    name <- trimws(sub("[:(;].*$", "", f$label))
    tags$span(class = "setting-item", paste0(name, ": "),
      tags$strong(`data-setting-for` = field_input_id(f), setting_value_text(f, values[[f$id]] %||% f[["default"]])))
  })
  Reduce(function(a, b) tagList(a, " \u00b7 ", b), items)
}

form_sections_ui <- function(tree, groups, values, form = list()) {
  section <- vapply(groups, form_section, character(1))
  index <- seq_along(groups)
  part <- function(which) lapply(index[section == which], function(i) group_ui(tree, groups[[i]], values, i))
  settings <- groups[section == "settings"]
  # Open when a setting has been changed from its default (e.g. a reopened
  # project), so a changed value is never hidden.
  changed <- any(vapply(unlist(lapply(settings, `[[`, "fields"), recursive = FALSE), function(f) {
    v <- values[[f$id]]
    !is.null(v) && length(v) && nzchar(as.character(v)) && !identical(as.character(v), as.character(f[["default"]] %||% ""))
  }, logical(1)))
  tagList(
    div(class = "form-section", h3(class = "h5 form-section-title", "1. What you want to find out"), part("goal")),
    if (any(section == "study")) div(class = "form-section", h3(class = "h5 form-section-title", "2. Your study and hypothesis"), part("study")),
    div(class = "form-section form-section-effect", h3(class = "h5 form-section-title", sprintf("%d. Your effect size, and where it comes from", if (any(section == "study")) 3 else 2)),
      p(class = "hint", "This is the heart of a power analysis: the result is only as good as the effect size and your reason for it."),
      effect_unsure_ui(form),
      effect_help_ui(form, groups),
      part("effect")),
    if (length(settings)) tags$details(class = "form-settings", open = if (changed) NA,
      tags$summary(tags$span(class = "form-settings-title", "Settings"), " (each starts at the default of the tool powerkit uses; open to change): ",
        settings_summary_ui(settings, values)),
      part("settings")),
    if (any(section == "guess")) tags$details(class = "form-guess", tags$summary("Guess first (optional)"), part("guess"))
  )
}

# Keeps the settings line in step with the fields inside it.
settings_js <- "
  $(document).on('change input', '.form-settings input, .form-settings select', function() {
    var out = document.querySelector('[data-setting-for=\"' + this.id + '\"]');
    if (!out) return;
    var text = this.tagName === 'SELECT' ? (this.selectedIndex >= 0 ? this.options[this.selectedIndex].text : '') : this.value;
    text = (text || '').split(/[:(]/)[0].trim();
    out.textContent = text || (this.tagName === 'SELECT' ? 'not set' : 'none');
  });
"

# Problems next to their fields (22 October 2026), as well as in the list
# under the buttons: form_problems() names each problem by its field.
field_problems_js <- "
  Shiny.addCustomMessageHandler('field_problems', function(problems) {
    document.querySelectorAll('.field-problem').forEach(function(el) {
      var input = document.getElementById(el.getAttribute('data-for'));
      if (input) {
        input.removeAttribute('aria-invalid');
        var ids = (input.getAttribute('aria-describedby') || '').split(' ').filter(function(x) { return x && x !== el.id; });
        if (ids.length) input.setAttribute('aria-describedby', ids.join(' ')); else input.removeAttribute('aria-describedby');
      }
      el.remove();
    });
    Object.keys(problems || {}).forEach(function(field) {
      var input = document.getElementById('f_' + field);
      if (!input) return;
      var note = document.createElement('div');
      note.className = 'field-problem'; note.id = 'f_' + field + '_problem'; note.setAttribute('data-for', input.id);
      note.textContent = problems[field];
      var box = input.closest('.form-field') || input.parentNode;
      box.appendChild(note);
      input.setAttribute('aria-invalid', 'true');
      input.setAttribute('aria-describedby', ((input.getAttribute('aria-describedby') || '') + ' ' + note.id).trim());
      var folded = input.closest('details');
      if (folded) folded.open = true;
    });
  });
"

# Help with the effect size (22 October 2026) -------------------------------

# For people new to power analysis: ways to a number they can defend, in
# plain words, never a suggested value (no defaults or small/medium/large;
# decided 18 October 2026). `form`: the end point's entry in forms.yaml.

# "Don't know what effect to expect?", in view, with a button where the
# design can find the smallest detectable effect instead. The button only
# sets the two choices (what to find out, and the source); it fills in no
# number.
effect_unsure_ui <- function(form) {
  if (isTRUE(form$sensitivity_without_effect)) {
    return(div(class = "effect-unsure",
      tags$strong("Don't know what effect to expect? "), "That's common. Tell powerkit how many people you can get, and it shows the smallest effect your study could detect; you then judge whether that is small enough.",
      div(tags$button(type = "button", class = "btn btn-outline-primary btn-sm mt-2", onclick = "pkEffectUnsure(true)", "I don't know my effect size"))))
  }
  if (isTRUE(form$sensitivity)) {
    return(div(class = "effect-unsure",
      tags$strong("Don't know how big the effect is? "), "If you know its pattern, enter that, and powerkit can scale it up or down to the smallest size your sample could detect.",
      div(tags$button(type = "button", class = "btn btn-outline-primary btn-sm mt-2", onclick = "pkEffectUnsure(false)", "Find the smallest effect I could detect"))))
  }
  NULL
}

# "Not sure what number to put here?": the four honest routes.
effect_help_ui <- function(form, groups) {
  ids <- unlist(lapply(groups, function(g) vapply(g$fields, `[[`, "", "id")))
  convert <- if ("d" %in% ids) {
    "To turn it into Cohen's d, divide it by how much people usually vary on the measure (its SD): 3 points where the SD is 10 gives d = 0.3."
  } else if ("dz" %in% ids) {
    "To turn it into d_z, divide it by how much people's changes usually vary (the SD of the differences, second minus first)."
  }
  unsure <- if (isTRUE(form$sensitivity_without_effect)) {
    "Choose \u201cI can't justify an effect size\u201d as the source (or use the button above): powerkit shows the smallest effect your sample could detect."
  } else if (isTRUE(form$sensitivity)) {
    "Enter the pattern you expect and choose \u201cThe smallest effect I could detect at a given sample size\u201d: powerkit scales your pattern to the smallest size your sample could detect."
  } else {
    "This design can't yet work out the smallest effect your sample could detect. Talk to a colleague or a statistician about a value you can defend; powerkit won't suggest one."
  }
  tags$details(class = "effect-help",
    tags$summary("Not sure what number to put here?"),
    p("powerkit won't suggest a number: a value you can't explain is no better than a guess. These are the ways to one you can defend."),
    tags$dl(
      tags$dt("The smallest effect that would matter"),
      tags$dd("Start in your measure's own units: the smallest difference that would matter for your theory or in practice (for example, 3 points on a questionnaire). ", convert,
        " Choose \u201cThe smallest effect that would matter\u201d as the source and say why that difference matters."),
      tags$dt("A meta-analysis"),
      tags$dd("If someone has pooled studies like yours, use the meta-analysis's estimate, say which estimate you took, and why. Choose \u201cA meta-analysis\u201d as the source."),
      tags$dt("One previous study"),
      tags$dd("A single published effect tends to be larger than the true one, so reduce it and say how; powerkit asks you to. Choose \u201cA previous study\u201d as the source."),
      tags$dt("You don't know"),
      tags$dd(unsure)))
}

# The button above: sets what to find out (and, where the design allows,
# the source to "I can't justify an effect size"), then moves to the
# number of participants.
effect_unsure_js <- "
  window.pkEffectUnsure = function(noEffect) {
    var set = function(id, value) {
      var el = document.getElementById(id);
      if (!el || !Array.prototype.some.call(el.options, function(o) { return o.value === value; })) return false;
      el.value = value; $(el).trigger('change'); return true;
    };
    set('f_goal', 'sensitivity');
    if (noEffect) set('f_just_type', 'none');
    setTimeout(function() { var n = document.getElementById('f_n'); if (n) { n.scrollIntoView({ block: 'center' }); n.focus(); } }, 150);
  };
"
