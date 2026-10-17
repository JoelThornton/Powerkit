# Screen builders for the routing prototype. Each returns htmltools tags
# built from tree.yaml; none calculates anything. Every button reports its
# action through one Shiny input ("pick") as a string such as "route:known",
# "opt:2", "back" or "ep:E7"; app.R dispatches on it.

pick_button <- function(label, value, help = NULL, class = "btn btn-outline-primary choice") {
  tags$button(
    type = "button",
    class = class,
    onclick = sprintf("Shiny.setInputValue('pick', '%s', {priority: 'event'})", value),
    tags$span(class = "choice-label", label),
    if (!is.null(help)) tags$span(class = "choice-help", help)
  )
}

prototype_banner <- function(tree) {
  div(class = "alert alert-warning prototype-banner", role = "alert", tags$strong(tree$banner))
}

# Placeholders for undecided settings ---------------------------------------

placeholder_ui <- function(setting) {
  if (is_decided(setting)) {
    return(div(
      class = "decided",
      tags$strong("Maintainer decision"), tags$span(class = "ref", sprintf("(%s):", setting$ref)), " ",
      setting$options[[setting$value]] %||% setting$value
    ))
  }
  div(
    class = "placeholder",
    div(class = "placeholder-label", "Undecided: for the maintainer", tags$span(class = "ref", setting$ref)),
    p(setting$question),
    tags$ul(lapply(unname(setting$options), tags$li)),
    if (!is.null(setting$proposed_text)) p(tags$em("Proposed: "), setting$proposed_text),
    p(class = "small text-muted mb-0", sprintf("Set 'value' for '%s' in app/routing/tree.yaml to record the decision.", setting$key))
  )
}

# A one-line version for cards, next to the question it affects. The full
# question and options are on the "For the maintainer" tab.
placeholder_inline <- function(setting) {
  if (is_decided(setting)) {
    return(tags$span(class = "decided-inline", sprintf("Maintainer decision (%s): %s", setting$ref, setting$options[[setting$value]] %||% setting$value)))
  }
  tags$span(class = "placeholder-inline", tags$strong("Undecided, for the maintainer"), sprintf(" (%s): %s", setting$ref, setting$question))
}

placeholders_at <- function(tree, where) {
  shown <- settings_shown_at(tree, where)
  if (length(shown) == 0) return(NULL)
  div(class = "placeholders", lapply(shown, placeholder_ui))
}

# Start screen ---------------------------------------------------------------

start_ui <- function(tree) {
  routes <- tree$routes$options
  if (!guided_route_enabled(tree)) routes <- Filter(function(r) r$id != "guided", routes)
  tagList(
    h2(tree$routes$question),
    div(class = "choices", lapply(routes, function(r) pick_button(r$label, paste0("route:", r$id), r$help))),
    p(class = "text-muted", tree$routes$screening_note),
    placeholders_at(tree, "start")
  )
}

# Trail of answers so far ------------------------------------------------------

trail_ui <- function(history) {
  if (length(history) == 0) return(NULL)
  div(
    class = "trail",
    tags$span(class = "trail-title", "Your answers so far (click one to change it):"),
    lapply(seq_along(history), function(i) {
      tags$button(
        type = "button", class = "chip",
        onclick = sprintf("Shiny.setInputValue('pick', 'trail:%d', {priority: 'event'})", i),
        history[[i]]$answer
      )
    })
  )
}

# One question screen ("Help me choose") ------------------------------------

# `ctx` holds the screening answers so far; options are filtered by it and
# the safety net comes last. "opt:i" refers to the i-th option shown.
node_ui <- function(tree, node_id, history, ctx = list()) {
  node <- tree$nodes[[node_id]]
  label <- node$sub_id %||% node$doc_id
  opts <- visible_options(tree, node, ctx)
  screening <- node$doc_id %in% c("S1", "S2", "S3", "S4", "O5a", "T1")
  tagList(
    trail_ui(history),
    div(class = "question-id", sprintf("%s %s", if (screening) "Screening question" else "Question", label)),
    h2(node$text),
    if (!is.null(node$help)) p(class = "lead", node$help),
    div(class = "choices", lapply(seq_along(opts), function(i) {
      o <- opts[[i]]
      pick_button(o$label, paste0("opt:", i), o$help,
        class = if (isTRUE(o$safety)) "btn btn-outline-secondary choice choice-safety" else "btn btn-outline-primary choice")
    })),
    placeholders_at(tree, node_id),
    div(class = "nav-buttons", pick_button("Back", "back", class = "btn btn-secondary"), pick_button("Start again", "home", class = "btn btn-link"))
  )
}

# "I know my analysis" list ---------------------------------------------------

# With screening answers (`ctx`), the list offers only the end points that
# fit them (endpoints_for_context()).
known_ui <- function(tree, history = list(), ctx = NULL) {
  groups <- list(
    "Runs in powerkit (validated)" = "runs_validated",
    "Runs, validation in progress" = "runs_validation_in_progress",
    "Coming soon" = "coming_soon",
    "Not in powerkit yet" = "not_in_powerkit"
  )
  eps <- tree$endpoints
  total <- length(eps)
  if (!is.null(ctx)) eps <- eps[endpoints_for_context(tree, ctx)]
  tagList(
    trail_ui(history),
    h2("Which analysis do you want?"),
    p(class = "lead", "Pick it by name. Each one opens its card."),
    if (!is.null(ctx)) p(class = "text-muted", sprintf("Showing the %d of %d analyses that fit your screening answers. To see others, change an answer above.", length(eps), total)),
    lapply(names(groups), function(g) {
      ids <- names(eps)[vapply(eps, function(e) e$status %in% groups[[g]], logical(1))]
      if (length(ids) == 0) return(NULL)
      tagList(
        h3(class = "h4 mt-4", g),
        div(class = "choices list", lapply(ids, function(id) {
          pick_button(eps[[id]]$plain_name, paste0("ep:", id), sprintf("%s (%s)", eps[[id]]$doc_name, id))
        }))
      )
    }),
    div(class = "choices list mt-4", pick_button(tree$safety_net$label, paste0("ep:", tree$safety_net$endpoint), class = "btn btn-outline-secondary choice choice-safety")),
    div(class = "nav-buttons", pick_button("Back", "back", class = "btn btn-secondary"), pick_button("Start again", "home", class = "btn btn-link"))
  )
}

# End-point card ------------------------------------------------------------

status_ui <- function(tree, ep) {
  links <- tree$links
  validation_links <- function() tagList(
    tags$a(href = links$validation_log, target = "_blank", "Validation log"), " · ",
    tags$a(href = paste0(links$tests_folder, "/", ep$validation$file), target = "_blank", tags$code(ep$validation$file))
  )
  package_list <- function() tags$ul(lapply(ep$packages, function(pk) {
    tags$li(HTML(sprintf("<strong><a href=\"%s\" target=\"_blank\">%s</a></strong>: %s",
      htmltools::htmlEscape(pk$url), htmltools::htmlEscape(pk$name), htmltools::htmlEscape(pk$what))))
  }))
  not_five <- if (identical(ep$five_tools, "not covered")) {
    p(tags$strong("Not covered by the five tools"), " powerkit builds on (Superpower, Spower, power4mome, InteractionPoweR, G*Power).")
  }
  switch(
    ep$status,
    runs_validated = div(
      class = "status status-runs",
      tags$strong("Runs in powerkit."), " Validated: ", ep$validation$note, " ", validation_links()
    ),
    runs_validation_in_progress = div(
      class = "status status-in-progress",
      tags$span(class = "badge-progress", "Validation in progress"),
      tags$strong("Runs, validation in progress."), " ", ep$validation$note, " ", validation_links()
    ),
    coming_soon = div(class = "status status-soon", tags$strong("Coming soon."), " ", ep$coming_soon_note),
    not_in_powerkit = if (isTRUE(ep$generic)) {
      div(
        class = "status status-not",
        tags$strong(ep$card_heading %||% "Not in powerkit yet."),
        p(class = if (!isTRUE(ep$established_tools)) "mb-0", ep$card_text),
        if (isTRUE(ep$established_tools)) p(class = "mb-0", tree$established_tools_text)
      )
    } else if (isTRUE(ep$no_ready_made_tool)) {
      div(
        class = "status status-not",
        tags$strong("Not in powerkit yet."),
        not_five,
        p(ep$status_text %||% tree$no_ready_made_tool_text),
        package_list(),
        p(class = "small mb-0", if (!isFALSE(ep$from_coverage)) "From powerkit's review of what other tools cover. ", "powerkit can't check results from other tools.")
      )
    } else {
      div(
        class = "status status-not",
        tags$strong("Not in powerkit yet: use ",
          lapply(seq_along(ep$packages), function(i) {
            pk <- ep$packages[[i]]
            tagList(if (i > 1) " or ", tags$a(href = pk$url, target = "_blank", pk$name))
          })
        ),
        not_five,
        package_list(),
        if (is.character(ep$no_ready_made_tool)) p(tags$strong(paste0(ep$no_ready_made_tool, ":")), " ", tree$no_ready_made_tool_text),
        p(class = "small mb-0", "From powerkit's review of what other tools cover. powerkit can't check results from other tools.")
      )
    }
  )
}

# The draft note on other defensible analyses: shown only once the setting
# other_analyses_note is "show" (open question 20; off while undecided).
other_analyses_ui <- function(tree, ep) {
  if (is.null(ep$alternatives) || !identical(setting_by_key(tree, "other_analyses_note")$value, "show")) return(NULL)
  p(class = "other-analyses", sub("{alternatives}", paste(unlist(ep$alternatives), collapse = "; "), tree$other_analyses_text, fixed = TRUE))
}

# On the safety-net card: what to write down for a statistician, filled in
# from the answers so far (`history`: list(node, answer, ctx) entries).
prepare_ui <- function(tree, history = list()) {
  prep <- tree$safety_net$prepare
  answer_for <- function(nodes) {
    got <- vapply(Filter(function(h) h$node %in% nodes && !identical(h$answer, tree$safety_net$label), history), function(h) h$answer, character(1))
    if (length(got) == 0) tags$em(prep$not_answered) else paste(got, collapse = "; ")
  }
  stopped <- Filter(function(h) identical(h$answer, tree$safety_net$label), history)
  div(
    class = "prepare",
    h3(class = "h5", "What to write down for a statistician"),
    p(prep$intro),
    tags$ul(
      lapply(prep$items, function(it) tags$li(tags$strong(paste0(it$label, ": ")), answer_for(unlist(it$nodes)))),
      if (length(stopped) > 0) tags$li(tags$strong(paste0(prep$stopped_at, ": ")), tree$nodes[[stopped[[length(stopped)]]$node]]$text),
      lapply(unlist(prep$also), tags$li)
    )
  )
}

card_ui <- function(tree, ep_id, compact = FALSE, history = list()) {
  ep <- tree$endpoints[[ep_id]]
  # Headings follow the page outline: the full card's title is the screen's
  # h2; a compact card sits under the plan's h2.
  section_heading <- function(text) (if (compact) h4 else h3)(class = "h5", text)
  runs <- ep$status %in% c("runs_validated", "runs_validation_in_progress", "coming_soon")
  jp <- tree$justification_prompt
  div(
    class = paste("card endpoint-card", if (compact) "compact"),
    div(
      class = "card-body",
      div(class = "card-eid", ep_id),
      (if (compact) h3 else h2)(class = "card-title h3", ep$plain_name),
      p(class = "standard-name", "Standard name: ", tags$strong(ep$doc_name), if (!is.null(ep$template)) tagList(" · ", tags$code(ep$template))),
      status_ui(tree, ep),
      if (identical(ep_id, tree$safety_net$endpoint) && !compact) prepare_ui(tree, history),
      if (!is.null(ep$card_points)) tags$ul(class = "card-points", lapply(ep$card_points, tags$li)),
      if (!is.null(ep$inputs)) tagList(section_heading("What you would enter"), tags$ul(lapply(ep$inputs, function(input) tags$li(
        input,
        lapply(glossary_for(tree, input), function(g) div(class = "hint", tags$dfn(g$term), ": ", g$hint))
      )))),
      if (!compact && !isTRUE(ep$generic)) tagList(
        section_heading("Where your effect size comes from"),
        p(jp$text),
        tags$ul(lapply(unname(jp$types), tags$li))
      ),
      other_analyses_ui(tree, ep),
      if (runs) p(class = "backend", tags$strong("Backend: "), ep$backend, " · ", tags$strong("Default method: "), ep$method),
      if (!compact && runs) tagList(
        section_heading("What you'd be asked next"),
        tags$ol(lapply(closing_questions_for(tree, ep_id), function(q) tags$li(
          q$text,
          if (!is.null(q$note)) tags$span(class = "text-muted", paste0(" ", q$note)),
          lapply(unlist(q$setting), function(key) div(placeholder_inline(setting_by_key(tree, key))))
        )))
      ),
      if (!compact && ep$status == "not_in_powerkit" && !isTRUE(ep$generic)) div(
        lapply(c("not_in_spec_wording", "r_script_for_uncovered"), function(key) div(placeholder_inline(setting_by_key(tree, key))))
      ),
      if (!compact) placeholders_at(tree, ep_id),
      p(class = "no-numbers", "No numbers are calculated in this prototype.")
    )
  )
}

# Guided route ----------------------------------------------------------------

# `ctx` holds the screening answers: a variable with `screen_key` offers
# only the option the screening chose (plus the safety net).
guided_variables_ui <- function(tree, answers, ctx = list(), history = list()) {
  g <- tree$guided
  if (identical(ctx$times, "many_conditions")) {
    return(tagList(
      trail_ui(history),
      h2("Plan my whole study: your variables"),
      div(class = "status status-soon", g$many_conditions_note),
      placeholders_at(tree, "guided_variables"),
      div(class = "nav-buttons",
        pick_button("Continue in 'Help me choose'", "continue:choose", class = "btn btn-primary"),
        pick_button("Back", "back", class = "btn btn-secondary"),
        pick_button("Start again", "home", class = "btn btn-link"))
    ))
  }
  tagList(
    trail_ui(history),
    h2("Plan my whole study: your variables"),
    p(class = "lead", g$intro),
    p(class = "text-muted", g$scope_note),
    placeholders_at(tree, "guided_variables"),
    lapply(g$variables, function(v) {
      opts <- guided_options(v, ctx)
      selected <- answers[[v$id]]
      if (is.null(selected) || !selected %in% names(opts)) selected <- names(opts)[1]
      radioButtons(paste0("g_", v$id), v$label, choiceNames = unname(unlist(opts)), choiceValues = names(opts), selected = selected, width = "100%")
    }),
    div(class = "nav-buttons", pick_button("Next: choose the analyses", "guided:analyses", class = "btn btn-primary"), pick_button("Start again", "home", class = "btn btn-link"))
  )
}

guided_analyses_ui <- function(tree, answers, ticked, primary, asks, rule) {
  apps <- applicable_analyses(tree, answers)
  g <- tree$guided
  tagList(
    h2("Plan my whole study: your analyses"),
    p(class = "lead", "Tick the analyses you plan on these variables, and mark the ones the study must be powered for (primary)."),
    lapply(apps, function(a) {
      res <- resolve_analysis(tree, a, answers, asks[[a$id]])
      ask <- res$ask %||% res$asked
      div(
        class = "analysis-row",
        checkboxInput(paste0("tick_", a$id), tags$strong(a$label), value = a$id %in% ticked, width = "100%"),
        if (!is.null(ask)) radioButtons(paste0("ask_", a$id), ask$text, choices = c(vapply(ask$options, function(o) o$label, character(1)), tree$safety_net$label), selected = asks[[a$id]] %||% character(0), width = "100%"),
        checkboxInput(paste0("primary_", a$id), "Primary: the study must be powered for this", value = a$id %in% primary, width = "100%")
      )
    }),
    radioButtons("g_rule", "How do the primary analyses support the study's claim?",
      choiceNames = lapply(g$combination_rules, function(r) tagList(tags$strong(r$label), tags$br(), tags$span(class = "text-muted", r$note))),
      choiceValues = vapply(g$combination_rules, function(r) r$id, character(1)),
      selected = rule %||% "each", width = "100%"
    ),
    div(class = "nav-buttons",
      pick_button("Back to the variables", "guided:variables", class = "btn btn-secondary"),
      pick_button("Show my plan", "guided:plan", class = "btn btn-primary"))
  )
}

guided_plan_ui <- function(tree, answers, ticked, primary, asks, rule) {
  g <- tree$guided
  rule_def <- Filter(function(r) identical(r$id, rule), g$combination_rules)[[1]]
  cards <- lapply(ticked, function(id) {
    a <- analysis_by_id(tree, id)
    res <- resolve_analysis(tree, a, answers, asks[[id]])
    head <- div(class = "plan-head", tags$strong(a$label), if (id %in% primary) tags$span(class = "badge bg-primary ms-2", "Primary") else tags$span(class = "badge bg-secondary ms-2", "Secondary"))
    body <- if (!is.null(res$endpoint)) {
      card_ui(tree, res$endpoint, compact = TRUE)
    } else if (!is.null(res$ask)) {
      div(class = "status status-soon", "Answer the follow-up question on the previous screen: ", res$ask$text)
    } else {
      div(class = "status status-not", tags$strong("Not in powerkit yet. "), res$unmapped,
        if (!is.null(res$package)) p(tags$a(href = res$package$url, target = "_blank", res$package$name), ": ", res$package$what))
    }
    div(class = "plan-item", head, body)
  })
  shared <- shared_relationships(tree, ticked)
  labels <- vapply(g$analyses, function(a) a$label, character(1))
  names(labels) <- vapply(g$analyses, function(a) a$id, character(1))
  tagList(
    h2("Your plan"),
    if (length(ticked) == 0) p("No analyses ticked yet.") else cards,
    h3(class = "h4 mt-4", "Combined sample size"),
    p(tags$strong("Rule:"), paste0(" ", rule_def$label, ". ", rule_def$note)),
    div(class = "engine-placeholder", g$placeholders$combined_n),
    h3(class = "h4 mt-4", "Consistency between analyses"),
    if (length(shared) == 0) p("No shared relationships among the ticked analyses.") else tags$ul(lapply(shared, function(s) {
      tags$li(sprintf("%s%s appears in: %s.", toupper(substr(s$label, 1, 1)), substr(s$label, 2, nchar(s$label)), paste(labels[s$sharing], collapse = "; ")), if (!is.null(s$note)) tags$span(class = "text-muted", paste0(" ", s$note)))
    })),
    div(class = "engine-placeholder", g$placeholders$consistency),
    placeholders_at(tree, "plan"),
    div(class = "nav-buttons",
      pick_button("Back to the analyses", "guided:analyses", class = "btn btn-secondary"),
      pick_button("Start again", "home", class = "btn btn-link"))
  )
}

# For the maintainer -------------------------------------------------------------

settings_table_ui <- function(tree) {
  tagList(
    h2("Undecided judgement calls and open questions"),
    p("Each is a setting in app/routing/tree.yaml. While its value is empty, the app shows a placeholder where it applies. Set the value to one of the option keys to record a decision; no code changes are needed."),
    div(class = "table-responsive", tabindex = "0", role = "region", `aria-label` = "Undecided settings", tags$table(
      class = "table table-sm",
      tags$caption(class = "visually-hidden", "Undecided settings, their sources, questions, options and current values"),
      tags$thead(tags$tr(tags$th(scope = "col", "Setting"), tags$th(scope = "col", "Source"), tags$th(scope = "col", "Question"), tags$th(scope = "col", "Options (key: label)"), tags$th(scope = "col", "Current value"))),
      tags$tbody(lapply(tree$settings, function(s) tags$tr(
        tags$td(tags$code(s$key)), tags$td(s$ref), tags$td(s$question),
        tags$td(tags$ul(lapply(names(s$options), function(k) tags$li(tags$code(k), ": ", s$options[[k]])))),
        tags$td(if (is_decided(s)) s$value else tags$em("Undecided"))
      )))
    ))
  )
}
