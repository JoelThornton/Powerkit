# The input screen for an end point (R/forms.R has the logic).

field_input_id <- function(f) paste0("f_", f$id)

# One field: its label, the input, and where its default comes from. A
# default's source and the group's hints are linked to the input with
# aria-describedby, so screen readers read them with the field.
field_ui <- function(f, value, described_by = character()) {
  id <- field_input_id(f)
  label <- if (isTRUE(f$effect)) paste0(f$label, " (required; starts empty)") else if (isTRUE(f$required)) paste0(f$label, " (required)") else f$label
  source_id <- paste0(id, "_default")
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
    if (!is.null(f$default_source)) div(id = source_id, class = "default-source",
      if (!is.null(f[["default"]])) sprintf("Starts at %s: %s.", f$choices[[as.character(f[["default"]])]] %||% f[["default"]], f$default_source) else paste0(f$default_source, ".")
    )
  )
  if (is.null(f$shown_if)) return(field)
  # Shown or hidden in the browser as the other choice changes; the server
  # ignores a hidden field's value (field_applies()).
  other <- sprintf("input.%s", field_input_id(list(id = f$shown_if$field)))
  condition <- if (!is.null(f$shown_if[["is"]])) {
    sprintf("%s == '%s'", other, f$shown_if[["is"]])
  } else {
    sprintf("%s != '%s'", other, f$shown_if[["is_not"]])
  }
  conditionalPanel(condition, field)
}

# A group of fields: a fieldset whose legend is the card's "What you would
# enter" line (or the group's title), with that line's plain-English hints.
group_ui <- function(tree, g, values, index) {
  legend <- g$input %||% g$title
  hint_id <- sprintf("group-%d-hints", index)
  hints <- if (!is.null(g$input)) glossary_for(tree, g$input) else list()
  tags$fieldset(
    class = "form-group-box",
    tags$legend(class = "h6", legend),
    if (length(hints)) div(id = hint_id, lapply(hints, function(h) div(class = "hint", tags$dfn(h$term), ": ", h$hint))),
    if (!is.null(g$note)) p(class = "group-note", g$note),
    lapply(g$fields, function(f) field_ui(f, values[[f$id]] %||% f[["default"]], if (length(hints)) hint_id else character()))
  )
}

# The whole screen. `values` keeps what the user typed when the screen is
# redrawn (e.g. after changing the number of mediators).
form_ui <- function(tree, forms, ep_id, groups, values = list(), history = list()) {
  ep <- tree$endpoints[[ep_id]]
  tagList(
    trail_ui(history),
    div(class = "card-eid", ep_id),
    h2(paste0("Your values: ", ep$plain_name)),
    p(class = "lead", "Fill in the values for your study. Nothing is calculated here: the screen builds a design spec and checks it with powerkit's engine."),
    if (identical(ep$status, "runs_validation_in_progress")) div(class = "status status-in-progress",
      tags$span(class = "badge-progress", "Validation in progress"), tags$strong("Runs, validation in progress."), " ", ep$validation$note),
    p("Effect sizes, SDs and correlations start empty: enter the values you expect, and say where they come from. Other settings start at the default of the tool powerkit uses, and say whose default it is."),
    placeholders_at(tree, "form"),
    lapply(seq_along(groups), function(i) group_ui(tree, groups[[i]], values, i)),
    div(class = "nav-buttons",
      actionButton("form_check", "Check my answers", class = "btn btn-primary"),
      actionButton("form_copy", "Copy my answers", class = "btn btn-outline-primary"),
      pick_button("Back to the card", "form_back", class = "btn btn-secondary"),
      pick_button("Start again", "home", class = "btn btn-link")
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

# The buttons under a card: "Enter your values" where the end point has an
# input screen, then Back and Start again.
card_nav_ui <- function(forms, ep_id) {
  div(class = "nav-buttons",
    if (has_form(forms, ep_id)) pick_button("Enter your values", "form", class = "btn btn-primary"),
    pick_button("Back", "back", class = "btn btn-secondary"),
    pick_button("Start again", "home", class = "btn btn-link"))
}
