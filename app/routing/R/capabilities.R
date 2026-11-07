# Discovery metadata only: this file never runs a power calculation.
evidence_lines <- function(record) {
  if (!is.list(record) || !isTRUE(record$format_version == 1))
    return("No variant-level evidence snapshot was captured with this result.")
  labels <- c(package_agreement = "Software agreement", independent = "Independent reference",
    published = "Published example", full_validation = "Method-validation run")
  states <- c(recorded = "recorded cases", scoped_only = "scoped checks only",
    pending = "benchmark pending transcription", not_linked = "no linked record",
    outside_scope = "outside the recorded case settings")
  c(vapply(names(labels), function(k) {
    item <- record$categories[[k]]
    state <- unname(states[item$status %||% "not_linked"])
    if (length(state) != 1 || is.na(state)) state <- "unrecognised status"
    paste0(labels[[k]], ": ", state, ". ", item$note %||% "")
  }, ""), paste("Coverage:", record$scope),
    sprintf("Evidence registry %s; record %s; SHA-256 %s.", record$registry_version, record$record_id, record$registry_sha256))
}

# The same record for a reader of the planning document: what was checked,
# in words, with the registry's identifiers last.
evidence_reader_lines <- function(record) {
  if (!is.list(record) || !isTRUE(record$format_version == 1))
    return("No record of the checks behind this analysis was saved with this result.")
  labels <- c(package_agreement = "Agreement with other software", independent = "Agreement with an independent calculation",
    published = "Agreement with a published example", full_validation = "Large simulation check of the method")
  states <- c(recorded = "checked on the example cases recorded in the validation log",
    scoped_only = "checked only in limited settings",
    pending = "a published benchmark is still to be transcribed",
    not_linked = "no record yet, so how well it is covered is unknown",
    outside_scope = "your settings fall outside the cases that were checked")
  c("These checks cover representative cases, not every value you could enter. powerkit is a prototype until version 1.0, and a statistician's review of its methods is still to come.",
    vapply(names(labels), function(k) {
      item <- record$categories[[k]]
      state <- unname(states[item$status %||% "not_linked"])
      if (length(state) != 1 || is.na(state)) state <- "status not recognised"
      note <- trimws(item$note %||% "")
      paste0("- ", labels[[k]], ": ", state, ".", if (nzchar(note)) paste0(" ", note) else "")
    }, "", USE.NAMES = FALSE),
    paste("Cases covered:", record$scope),
    sprintf("(Evidence record %s, registry version %s.)", record$record_id, record$registry_version))
}

evidence_ui <- function(record, title = "Evidence for this analysis variant") {
  tags$details(class = "result-validation small",
    tags$summary(title),
    tags$ul(lapply(evidence_lines(record), tags$li)),
    lapply(record$sources, function(s) p(tags$a(href = s$url, target = "_blank", rel = "noopener",
      paste("Source record", s$date)), ": ", s$note)),
    p("These are representative case records, not validation of every parameter value. No linked record means unknown coverage. Ordinary tests, method checks and review by a statistician are different kinds of evidence."))
}

capability_metadata <- function(form, fields, values) {
  lookup <- engine_function("analysis_evidence")
      spec <- form$base
      for (f in fields) {
        value <- values[[f$id]]
        if (blank(value) || !field_applies(f, values)) next
        if (!is.null(f$path)) spec <- set_path(spec, split_path(f$path), field_value(f, value, values))
        for (extra in f$sets[[as.character(value)]]) {
          if (field_applies(extra, values)) spec <- set_path(spec, split_path(extra$path), extra$value)
        }
      }
      if (is.null(lookup) || length(spec$design) != 1 || length(spec$template) != 1) NULL else lookup(spec)
    }

default_evidence <- function(forms, id) {
  form <- forms$forms[[id]]
  if (is.null(form)) return(NULL)
  fields <- form_fields(form_groups(forms, id))
  values <- setNames(lapply(fields, function(f) f[["default"]] %||% ""), vapply(fields, `[[`, "", "id"))
  capability_metadata(form, fields, values)
}

# The catalogue lists each declared discrete choice separately, rather than
# inventing a Cartesian product of choices whose conditions may conflict.
capability_rows <- function(tree, forms) {
  how <- about_endpoint_how(forms)
  rows <- list()
  add <- function(id, choice, access, restrictions, record = NULL) {
    rows[[length(rows) + 1L]] <<- data.frame(
      analysis = tree$endpoints[[id]]$plain_name %||% tree$endpoints[[id]]$doc_name %||% id, choice = choice, access = access,
      restrictions = restrictions, evidence = paste(evidence_lines(record), collapse = " "),
      endpoint = id, stringsAsFactors = FALSE)
  }
  for (id in names(tree$endpoints)) {
    form <- forms$forms[[id]]
    ep <- tree$endpoints[[id]]
    route <- unname(how[id])
    access <- if (length(route) == 1 && !is.na(route)) unname(about_how_words[route]) else "Guidance only"
    if (is.null(form)) {
      add(id, "Card and signposting", access, ep$card_text %||% ep$status_text %||% ep$coming_soon_note %||% "No calculation form is offered.")
      next
    }
    fields <- form_fields(form_groups(forms, id))
    defaults <- setNames(lapply(fields, function(f) f[["default"]] %||% ""), vapply(fields, `[[`, "", "id"))
    restrictions <- paste(c("Choices are listed individually; visibility and compatibility depend on the other answers.",
      unlist(lapply(fields, function(f) {
        if (is.null(f$help) && is.null(f$min) && is.null(f$max) && is.null(f$min_exclusive)) return(NULL)
        paste(f$label, paste(c(if (!is.null(f$min)) paste("minimum", f$min),
          if (!is.null(f$min_exclusive)) paste("greater than", f$min_exclusive),
          if (!is.null(f$max)) paste("maximum", f$max), f$help), collapse = "; "))
      }))), collapse = " ")
    add(id, "Form defaults (population values still required)", access, restrictions, capability_metadata(form, fields, defaults))
    choices <- Filter(function(f) identical(f$type, "select") && ((!is.null(f$path) && grepl("^(target_test|population|variables|goal|template|design)([.]|$)", f$path)) || length(f$sets)), fields)
    for (f in choices) for (value in names(f$choices)) {
      values <- defaults
      values[[f$id]] <- value
      note <- paste(c(f$choice_notes[[value]], if (!is.null(f$shown_if)) "Shown only when the form's other conditions apply."), collapse = " ")
      add(id, paste(f$label, f$choices[[value]], sep = ": "), access,
        paste(note, "Other limits are listed in this analysis's form-default row."), capability_metadata(form, fields, values))
    }
  }
  do.call(rbind, rows)
}

capabilities_ui <- function(tree, forms) {
  rows <- capability_rows(tree, forms)
  tagList(
    p("Generated from the current cards and input forms. Each row is one available choice, not a claim that every combination works. Conditional fields, mathematical limits and population assumptions still apply. Evidence for your complete, selected analysis is captured with its result."),
    tags$label(`for` = "capability_search", "Search analyses, test versions or assumptions"),
    tags$input(id = "capability_search", type = "search", class = "form-control", oninput = "pkFilterCapabilities(this.value)"),
    p(id = "capability_count", role = "status", `aria-live` = "polite", sprintf("%d choices", nrow(rows))),
    download_button("download_capabilities", "Download current capability table (CSV)", class = "btn btn-outline-primary"),
    div(style = "overflow-x:auto; max-height:36rem; overflow-y:auto;",
      tags$table(id = "capability_table", class = "table table-sm",
        tags$caption("Current analysis choices, access routes, limits and evidence"),
        tags$thead(tags$tr(lapply(c("Analysis", "Choice", "Access", "Limits and evidence"), function(x) tags$th(scope = "col", x)))),
        tags$tbody(lapply(seq_len(nrow(rows)), function(i) tags$tr(
          tags$th(scope = "row", rows$analysis[i]), tags$td(rows$choice[i]), tags$td(rows$access[i]),
          tags$td(tags$details(tags$summary("Read limits and evidence"), p(rows$restrictions[i]), p(rows$evidence[i])))))))),
    tags$script(HTML("window.pkFilterCapabilities=function(q){var n=0;q=q.toLocaleLowerCase();document.querySelectorAll('#capability_table tbody tr').forEach(function(r){r.hidden=!r.textContent.toLocaleLowerCase().includes(q);if(!r.hidden)n++;});document.getElementById('capability_count').textContent=n+' choices';};")))
}
