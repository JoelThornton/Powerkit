# Discovery metadata only: this file never runs a power calculation.
evidence_lines <- function(record) {
  if (!is.list(record) || !isTRUE(record$format_version == 1))
    return("No variant-level evidence snapshot was captured with this result.")
  labels <- c(package_agreement = "Software agreement", independent = "Independent reference",
    published = "Published example", full_validation = "Method-validation run")
  states <- c(recorded = "recorded cases", scoped_only = "scoped checks only",
    pending = "a published benchmark is still to be transcribed", not_linked = "none recorded for this method with these options",
    outside_scope = "outside the recorded case settings")
  c(vapply(names(labels), function(k) {
    item <- record$categories[[k]]
    state <- unname(states[item$status %||% "not_linked"])
    if (length(state) != 1 || is.na(state)) state <- "unrecognised status"
    # The registry's own note for a missing record repeats the status in
    # its bookkeeping terms; the status says it in plain words.
    note <- if (identical(item$status %||% "not_linked", "not_linked")) "" else item$note %||% ""
    trimws(paste0(labels[[k]], ": ", state, ". ", note))
  }, ""), paste("Coverage:", sub("Complete inputs may narrow the variant. No linked record is not a failed check.",
      "filling in all your settings can narrow which checks apply. \"None recorded\" is not a failed check.", record$scope, fixed = TRUE)),
    sprintf("For reference: evidence registry %s, record %s, SHA-256 %s.", record$registry_version, record$record_id, record$registry_sha256))
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
  c("These checks cover representative cases, not every value you could enter. Powerkit is a prototype until version 1.0, and a statistician's review of its methods is still to come.",
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

# The records match on the method and its options (the test, its sides,
# the allocation, the calculation and the goal), not on the sample size,
# effect or alpha entered, so the heading names the method (21 November
# 2026).
evidence_ui <- function(record, title = "Evidence for this analysis method") {
  tags$details(class = "result-validation small",
    tags$summary(title),
    tags$ul(lapply(evidence_lines(record), tags$li)),
    lapply(record$sources, function(s) p(tags$a(href = s$url, target = "_blank", rel = "noopener",
      paste("Source record", s$date)), ": ", s$note)),
    p("These are checks of example cases, not of every value you could enter. \"Recorded\" means a check exists for this method with these options, usually at other values than yours: a published example is matched on the method, not on your sample size, effect or alpha. \"None recorded\" means no separate check exists for this method with these options, not that one failed; the checks for this analysis in general are listed just below. A statistician's review of the methods is a different kind of evidence, and is still to come."))
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
  values <- setNames(lapply(fields, function(f) f[["default"]] %||% f$usual %||% ""), vapply(fields, `[[`, "", "id"))
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
    defaults <- setNames(lapply(fields, function(f) f[["default"]] %||% f$usual %||% ""), vapply(fields, `[[`, "", "id"))
    restrictions <- paste(c("Choices are listed individually; visibility and compatibility depend on the other answers.",
      unlist(lapply(fields, function(f) {
        if (is.null(f$help) && is.null(f$min) && is.null(f$max) && is.null(f$min_exclusive)) return(NULL)
        paste(f$label, paste(c(if (!is.null(f$min)) paste("minimum", f$min),
          if (!is.null(f$min_exclusive)) paste("greater than", f$min_exclusive),
          if (!is.null(f$max)) paste("maximum", f$max), f$help), collapse = "; "))
      }))), collapse = " ")
    add(id, "The screen as it starts (you still enter the effect and sample)", access, restrictions, capability_metadata(form, fields, defaults))
    choices <- Filter(function(f) identical(f$type, "select") && ((!is.null(f$path) && grepl("^(target_test|population|variables|goal|template|design)([.]|$)", f$path)) || length(f$sets)), fields)
    for (f in choices) for (value in names(f$choices)) {
      values <- defaults
      values[[f$id]] <- value
      note <- paste(c(f$choice_notes[[value]], if (!is.null(f$shown_if)) "Shown only when the form's other conditions apply."), collapse = " ")
      # "Which directions ...?: Positive effects only" read badly: the
      # question's own question mark goes.
      add(id, paste(sub("\\?$", "", f$label), f$choices[[value]], sep = ": "), access,
        paste(note, "Other limits are listed in this analysis's row for the screen as it starts."), capability_metadata(form, fields, values))
    }
  }
  do.call(rbind, rows)
}

# One row per analysis: what it is, what it is usually called, the test
# versions it offers and how it runs. The per-choice table above is the
# download, for anyone who wants every option and its checks.
capability_summary <- function(tree, forms, rows = capability_rows(tree, forms)) {
  ids <- unique(rows$endpoint)
  out <- lapply(ids, function(id) {
    ep <- tree$endpoints[[id]]
    form <- forms$forms[[id]]
    tests <- character()
    if (!is.null(form)) {
      fields <- form_fields(form_groups(forms, id))
      for (f in fields) if (identical(f$type, "select") && identical(f$path, "target_test.method"))
        tests <- c(tests, unlist(f$choices, use.names = FALSE))
    }
    first <- rows[rows$endpoint == id, ][1, ]
    data.frame(endpoint = id, analysis = first$analysis, called = ep$doc_name %||% "",
      tests = paste(unique(tests), collapse = "; "), access = first$access,
      restrictions = first$restrictions, evidence = first$evidence, stringsAsFactors = FALSE)
  })
  do.call(rbind, out)
}

# The download: every row of capability_rows(), with readable headings.
capability_table_csv <- function(tree, forms, file) {
  rows <- capability_rows(tree, forms)
  called <- vapply(rows$endpoint, function(id) tree$endpoints[[id]]$doc_name %||% "", character(1))
  table <- data.frame(Analysis = rows$analysis, `Usually called` = unname(called), Choice = rows$choice,
    `How it runs` = rows$access, Limits = rows$restrictions, `Checks recorded` = rows$evidence,
    check.names = FALSE, stringsAsFactors = FALSE)
  utils::write.csv(table, file, row.names = FALSE, na = "")
}

# Search: rows whose name or usual name match come first, then rows whose
# test versions match, then rows that match only in their limits and
# checks; the rest are hidden.
capability_search_js <- "window.pkFilterCapabilities=function(q){
  var words=q.toLocaleLowerCase().split(/\\s+/).filter(Boolean);var body=document.querySelector('#capability_table tbody');if(!body)return;
  var rows=Array.prototype.slice.call(body.rows),n=0;
  var has=function(t){return words.every(function(w){return t.indexOf(w)>=0;});};
  rows.forEach(function(r){var name=(r.dataset.name||'').toLocaleLowerCase(),tests=(r.dataset.tests||'').toLocaleLowerCase(),all=r.textContent.toLocaleLowerCase();
    r._score=!words.length?0:has(name)?3:has(name+' '+tests)?2:has(all)?1:-1;r.hidden=r._score<0;if(!r.hidden)n++;});
  rows.sort(function(a,b){return (b._score-a._score)||(a.dataset.order-b.dataset.order);}).forEach(function(r){body.appendChild(r);});
  document.getElementById('capability_count').textContent=(words.length?n+' of '+rows.length:rows.length)+' analyses';};"

capabilities_ui <- function(tree, forms) {
  rows <- capability_rows(tree, forms)
  summary <- capability_summary(tree, forms, rows)
  tagList(
    p(sprintf("Each analysis, with the tests it offers and how it runs. The full table lists all %s choices of every analysis (each test version, effect size, goal and option), with its limits and the checks recorded for it.",
      format(nrow(rows), big.mark = ","))),
    download_button("download_capabilities", "Download the full table (spreadsheet, CSV)", class = "btn btn-outline-primary"),
    # Folded, so About stays short.
    tags$details(class = "capabilities-fold", tags$summary(sprintf("Every analysis and the tests it offers (%d)", nrow(summary))),
      p("Generated from the current cards and input forms. Each test version is one available choice, not a claim that every combination works. Evidence for your complete, selected analysis is captured with its result."),
      tags$label(`for` = "capability_search", "Search by analysis or test, for example ANOVA or Welch"),
      tags$input(id = "capability_search", type = "search", class = "form-control", oninput = "pkFilterCapabilities(this.value)"),
      p(id = "capability_count", role = "status", `aria-live` = "polite", sprintf("%d analyses", nrow(summary))),
      div(style = "overflow-x:auto; max-height:36rem; overflow-y:auto;",
        tags$table(id = "capability_table", class = "table table-sm",
          tags$caption("The analyses Powerkit covers, the tests each offers and how each runs"),
          tags$thead(tags$tr(lapply(c("Analysis", "Tests it offers", "How it runs", "Limits and checks"), function(x) tags$th(scope = "col", x)))),
          tags$tbody(lapply(seq_len(nrow(summary)), function(i) tags$tr(
            `data-order` = i, `data-name` = paste(summary$analysis[i], summary$called[i]), `data-tests` = summary$tests[i],
            tags$th(scope = "row", summary$analysis[i], if (nzchar(summary$called[i])) tags$div(class = "small text-muted", summary$called[i])),
            tags$td(if (nzchar(summary$tests[i])) summary$tests[i] else tags$span(class = "text-muted", "One version")),
            tags$td(summary$access[i]),
            tags$td(tags$details(tags$summary("Read limits and checks"), p(summary$restrictions[i]), p(summary$evidence[i])))))))),
      tags$script(HTML(capability_search_js))))
}
