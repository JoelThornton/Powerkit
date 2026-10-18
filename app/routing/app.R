# powerkit routing prototype: a clickable version of docs/decision-tree.md.
#
# ROUTING ONLY: it shows which analysis a study needs, and calculates
# nothing; the maths is wired in at build phase 5. Everything it shows comes
# from tree.yaml in this folder. The input screens (forms.yaml) build a design
# spec and check it with the engine's validate_spec(), read-only; no power
# calculation is run.
#
# Run: source("run_routing_prototype.R") from the project folder, or open
# this file in RStudio and click "Run App". See docs/routing-prototype.md.

library(shiny)

options(shiny.sanitize.errors = TRUE)

source(file.path("R", "tree.R"), local = TRUE)
source(file.path("R", "ui.R"), local = TRUE)
source(file.path("R", "forms.R"), local = TRUE)
source(file.path("R", "forms_ui.R"), local = TRUE)
source(file.path("R", "feedback.R"), local = TRUE)
source(file.path("R", "results.R"), local = TRUE)
source(file.path("R", "simulations.R"), local = TRUE)
source(file.path("R", "project.R"), local = TRUE)
source(file.path("R", "about.R"), local = TRUE)

tree <- load_tree("tree.yaml")
forms <- load_forms("forms.yaml")
# Cards for end points that calculate (or preview, E10-E14) don't say "No
# numbers are calculated".
tree$calculates <- c(unlist(forms$calculates), names(forms$simulations$endpoints))
options(powerkit.routing_dir = getwd())

app_css <- "
  body { background: #f7f8fa; }
  .prototype-banner { font-size: 1.05rem; text-align: center; margin: 0 0 1.25rem 0; }
  .app-main { max-width: 980px; margin: 0 auto 3rem auto; }
  .choices { display: flex; flex-direction: column; gap: 0.6rem; margin: 1rem 0 1.5rem 0; }
  .choice { text-align: left; padding: 0.75rem 1rem; white-space: normal; }
  .choice .choice-label { display: block; font-weight: 600; }
  .choice .choice-help { display: block; font-size: 0.85rem; margin-top: 0.15rem; color: #3d4852; }
  .choice:hover .choice-help, .choice:focus .choice-help, .choice:active .choice-help { color: #fff; }
  .trail { margin-bottom: 1rem; }
  .trail-title { display: block; font-size: 0.85rem; color: #555; margin-bottom: 0.35rem; }
  .chip { border: 1px solid #b8c2d3; background: #e8f0fb; color: #14284b; border-radius: 1.4rem;
          padding: 0.45rem 0.9rem; margin: 0 0.35rem 0.5rem 0; font-size: 0.85rem;
          min-height: 44px; min-width: 44px; } /* touch target at least 44 x 44 px (WCAG 2.5.5) */
  .question-id, .card-eid { font-size: 0.8rem; color: #545b62; text-transform: uppercase; letter-spacing: 0.04em; }
  .nav-buttons { display: flex; flex-wrap: wrap; gap: 0.75rem; margin-top: 1rem; }
  .placeholders { margin-top: 1rem; }
  .placeholder { border: 2px dashed #9a9a9a; background: #f2f2f2; color: #333; border-radius: 0.5rem; padding: 0.75rem 1rem; margin-bottom: 0.75rem;
                 opacity: 1; cursor: auto; display: block; min-height: 0; vertical-align: baseline; } /* overrides Bootstrap's loading-placeholder style */
  .placeholder .text-muted, .placeholder .ref { color: #4d4d4d !important; }
  .no-numbers { color: #545b62 !important; }
  [tabindex='-1']:focus { outline: none; }
  .placeholder-label { font-weight: 700; text-transform: uppercase; font-size: 0.8rem; letter-spacing: 0.04em; margin-bottom: 0.35rem; }
  .placeholder .ref, .decided .ref { font-weight: 400; text-transform: none; margin-left: 0.5rem; color: #555; }
  .decided { border-left: 4px solid #2e7d4f; background: #ddf2e3; padding: 0.5rem 0.75rem; margin-bottom: 0.75rem; }
  .endpoint-card { margin: 1rem 0; border-radius: 0.6rem; }
  .endpoint-card.compact { margin: 0.5rem 0 0 0; }
  .standard-name { color: #444; }
  .status { border-radius: 0.4rem; padding: 0.6rem 0.9rem; margin: 0.5rem 0 1rem 0; }
  .status-runs { background: #ddf2e3; border: 1px solid #2e7d4f; }
  .status-in-progress { background: #e8f0fb; border: 1px solid #3b6fb6; }
  .badge-progress { display: inline-block; background: #3b6fb6; color: #fff; border-radius: 1rem; padding: 0.05rem 0.6rem;
                    font-size: 0.75rem; font-weight: 600; margin-right: 0.5rem; vertical-align: 1px; }
  .status-soon { background: #fff0d1; border: 1px solid #b97a00; }
  .status-not { background: #f2f2f2; border: 1px dashed #9a9a9a; }
  .no-numbers { font-size: 0.8rem; margin: 0.75rem 0 0 0; }
  .placeholder-inline { display: inline-block; border: 1.5px dashed #9a9a9a; background: #f2f2f2; color: #333; border-radius: 0.35rem;
                        padding: 0.1rem 0.5rem; margin: 0.25rem 0 0.35rem 0; font-size: 0.82rem; }
  .decided-inline { display: inline-block; border-left: 3px solid #2e7d4f; background: #ddf2e3; padding: 0.1rem 0.5rem; margin: 0.25rem 0; font-size: 0.82rem; }
  .engine-placeholder { border: 2px dashed #3b6fb6; background: #fff; color: #14284b; border-radius: 0.5rem; padding: 0.75rem 1rem; margin: 0.5rem 0 1rem 0; font-style: italic; }
  .analysis-row { background: #fff; border: 1px solid #dde2ea; border-radius: 0.5rem; padding: 0.75rem 1rem 0.25rem 1rem; margin-bottom: 0.75rem; }
  .choice-safety { border-style: dashed; }
  .hint { font-size: 0.85rem; color: #4a4a4a; margin: 0.1rem 0 0.25rem 0; }
  .hint dfn { font-style: normal; font-weight: 600; }
  .card-points { margin-bottom: 1rem; }
  .form-group-box { background: #fff; border: 1px solid #dde2ea; border-radius: 0.6rem; padding: 0.75rem 1rem 0.25rem 1rem; margin-bottom: 1rem; }
  .form-group-box legend { float: none; width: auto; padding: 0 0.25rem; margin-bottom: 0.25rem; font-weight: 600; }
  .form-field { margin-bottom: 0.75rem; }
  .form-field .form-control, .form-field .form-select { min-height: 44px; }
  .default-source { font-size: 0.85rem; color: #4a4a4a; margin-top: -0.35rem; }
  .form-problems { border-left: 4px solid #a12a2a; background: #fbeaea; padding: 0.75rem 1rem; margin: 1rem 0; }
  .not-wired { margin-top: 1rem; }
  .spec-json { white-space: pre-wrap; font-size: 0.8rem; background: #f4f6f9; padding: 0.5rem; border-radius: 0.4rem; }
  #copy-status { margin-top: 0.5rem; font-size: 0.9rem; }
  .mismatch { margin-top: 1.25rem; border-top: 1px solid #dde2ea; padding-top: 0.75rem; }
  .mismatch summary { color: #0a5a8c; text-decoration: underline; cursor: pointer; min-height: 44px; display: flex; align-items: center; }
  .mismatch-text { font-size: 0.85rem; font-family: monospace; }
  .copy-status { margin-top: 0.5rem; font-size: 0.9rem; }
  .about { max-width: 46rem; }
  .about-endpoints li, .about-credit { margin-bottom: 0.4rem; }
  .about-citation { color: #3d4852; margin-top: 0.15rem; }
  .plan-item { background: #fff; border: 1px solid #dde2ea; border-radius: 0.6rem; padding: 0.75rem 1rem; margin-bottom: 1rem; }
"

# After each screen change, move keyboard and screen-reader focus to the new
# screen's main heading, so users don't have to tab back down from the top.
copy_js <- "
  // Copy text in the browser (nothing is sent to the server or anywhere else).
  window.pkCopyText = function(text, status) {
    var done = function(msg) { if (status) { status.textContent = msg; status.classList.remove('visually-hidden'); } };
    var ok = 'Copied. Paste it anywhere: an email, a document or a message to a colleague.';
    var fail = 'Couldn\\'t copy automatically. Select the text in the box below and copy it.';
    // Older browsers and some settings block the clipboard API: copy from a
    // hidden text box instead.
    var fallback = function() {
      var box = document.createElement('textarea');
      box.value = text; box.setAttribute('readonly', ''); box.style.position = 'fixed'; box.style.opacity = '0';
      document.body.appendChild(box); box.select();
      var copied = false; try { copied = document.execCommand('copy'); } catch (e) {}
      document.body.removeChild(box);
      done(copied ? ok : fail);
    };
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(function() { done(ok); }, fallback);
    } else {
      fallback();
    }
  };
  window.pkCopy = function(id) {
    var el = document.getElementById(id);
    if (el) pkCopyText(el.value, document.getElementById(id + '-status'));
  };
  Shiny.addCustomMessageHandler('copy_answers', function(text) {
    pkCopyText(text, document.getElementById('copy-status'));
  });
  // Move focus to the check's result, so keyboard and screen-reader users hear it.
  Shiny.addCustomMessageHandler('focus_result', function(id) {
    setTimeout(function() { var el = document.querySelector('#' + id + ' [tabindex]'); if (el) el.focus(); }, 50);
  });
  // A background calculation's estimated progress, updated in place.
  Shiny.addCustomMessageHandler('calc_progress', function(m) {
    var bar = document.getElementById('calc-progress-bar');
    var text = document.getElementById('calc-progress-text');
    if (bar) { if (m.value === null) { bar.removeAttribute('value'); } else { bar.value = m.value; } }
    if (text) text.textContent = m.text;
  });
"
focus_js <- "
  $(document).on('shiny:value', function(e) {
    if (e.name !== 'screen') return;
    setTimeout(function() {
      var h = document.querySelector('#screen h2');
      if (h && document.activeElement && document.activeElement !== document.body && !document.getElementById('screen').contains(document.activeElement)) return;
      if (h) { h.setAttribute('tabindex', '-1'); h.focus({ preventScroll: false }); }
    }, 0);
  });
"

ui <- fluidPage(
  lang = "en",
  # A darker primary blue than the default, for 4.5:1 contrast on the page
  # background (links, choice buttons, tabs).
  theme = if (requireNamespace("bslib", quietly = TRUE)) bslib::bs_theme(version = 5, primary = "#0a5a8c"),
  tags$head(tags$title("powerkit routing prototype"), tags$style(HTML(app_css)), tags$script(HTML(focus_js)), tags$script(HTML(copy_js))),
  tags$header(
    h1(class = "visually-hidden", "powerkit routing prototype"),
    prototype_banner(tree)
  ),
  tags$main(
    class = "app-main",
    tabsetPanel(
      id = "tabs",
      tabPanel("Plan a power analysis", div(class = "pt-3", uiOutput("screen"))),
      tabPanel("About this prototype", div(class = "pt-3", about_ui(tree, forms))),
      tabPanel("For the maintainer: undecided settings", div(class = "pt-3", settings_table_ui(tree)))
    )
  )
)

server <- function(input, output, session) {
  state <- reactiveValues(
    screen = "start",        # start | known | node | card | form | g_vars | g_analyses | g_plan
    start = list(),          # screen A: situation, aim and claim
    route = "choose",        # the route chosen on the start screen
    node = NULL,             # current question id (screening or "Help me choose")
    ctx = list(),            # screening answers later questions depend on
    history = list(),        # list(node, answer, ctx) for each answer given
    endpoint = NULL,         # end point shown on the card screen
    came_from = NULL,        # "known" or "node", for the card's back button
    form_values = list(),    # input screen: values typed so far (kept when it's redrawn)
    form_k = 2L,             # input screen: number of mediators (parallel and serial mediation)
    calc = NULL,             # input screen: the last calculation (run_calculation()), for the downloads
    long_spec = NULL,        # E10-E14: the checked spec, with its seed, for the full run or the R script
    answers = list(),        # guided route: variable answers
    ticked = character(), primary = character(), asks = list(), rule = "each"
  )

  # Keep the guided route's inputs in state as they change.
  save_guided_variables <- function() {
    for (v in tree$guided$variables) {
      value <- input[[paste0("g_", v$id)]]
      if (!is.null(value)) state$answers[[v$id]] <- value
    }
  }
  # The guided rules also use some screening answers (e.g. measured twice).
  routed_answers <- function() guided_answers(tree, state$answers, state$ctx)
  save_guided_analyses <- function() {
    apps <- applicable_analyses(tree, routed_answers())
    ids <- vapply(apps, function(a) a$id, character(1))
    state$ticked <- ids[vapply(ids, function(id) isTRUE(input[[paste0("tick_", id)]]), logical(1))]
    state$primary <- ids[vapply(ids, function(id) isTRUE(input[[paste0("primary_", id)]]), logical(1))]
    for (id in ids) {
      a <- input[[paste0("ask_", id)]]
      if (!is.null(a)) state$asks[[id]] <- a
    }
    if (!is.null(input$g_rule)) state$rule <- input$g_rule
  }

  # Go to where an answer leads: a card, a question, or the route's screen
  # after the screening ("list" or "guided").
  go_to <- function(target) {
    if (is_endpoint_id(target)) {
      state$endpoint <- target; state$came_from <- "node"; state$screen <- "card"
    } else if (identical(target, "list")) {
      state$screen <- "known"
    } else if (identical(target, "guided")) {
      state$screen <- "g_vars"
    } else {
      state$node <- target; state$screen <- "node"
    }
  }
  # Return to the question answered last, with the context as it was then.
  step_back <- function() {
    if (length(state$history) == 0) {
      state$screen <- "start"
      return(invisible())
    }
    last <- state$history[[length(state$history)]]
    state$history <- state$history[-length(state$history)]
    state$node <- last$node; state$ctx <- last$ctx; state$screen <- "node"
  }

  # The input screen's fields and the values typed into them.
  current_form_fields <- function() form_fields(form_groups(forms, state$endpoint, state$form_k, state$start))
  current_form_values <- function() {
    fields <- current_form_fields()
    values <- lapply(fields, function(f) input[[field_input_id(f)]])
    names(values) <- vapply(fields, `[[`, "", "id")
    values[!vapply(values, is.null, logical(1))]
  }
  observeEvent(input$pick, {
    pick <- input$pick
    kind <- sub(":.*$", "", pick)
    value <- sub("^[^:]*:", "", pick)
    if (pick == "home") {
      state$screen <- "start"; state$history <- list(); state$node <- NULL; state$ctx <- list()
    } else if (kind == "route") {
      # Screen A first: estimation and equivalence go to their cards.
      state$start <- start_answers(tree, input)
      state$route <- value; state$history <- list(); state$ctx <- list()
      exit <- start_exit(tree, state$start)
      if (!is.null(exit)) {
        state$endpoint <- exit; state$came_from <- "node"; state$screen <- "card"
      } else {
        # Every route starts with the screening questions.
        go_to(resolve_target(tree, start_node(tree), state$ctx, value))
      }
    } else if (kind == "opt") {
      option <- visible_options(tree, tree$nodes[[state$node]], state$ctx)[[as.integer(value)]]
      state$history <- c(state$history, list(list(node = state$node, answer = option$label, ctx = state$ctx)))
      state$ctx <- apply_sets(state$ctx, option)
      go_to(resolve_target(tree, option$`next`, state$ctx, state$route))
    } else if (kind == "continue") {
      # From the guided route to "Help me choose", keeping the screening answers.
      state$route <- value
      go_to(resolve_target(tree, "continue", state$ctx, value))
    } else if (pick == "back") {
      if (state$screen == "card" && identical(state$came_from, "known")) {
        state$screen <- "known"
      } else {
        step_back()
      }
    } else if (kind == "trail") {
      i <- as.integer(value)
      state$node <- state$history[[i]]$node
      state$ctx <- state$history[[i]]$ctx
      state$history <- state$history[seq_len(i - 1)]
      state$screen <- "node"
    } else if (pick == "form") {
      state$form_values <- list(); state$form_k <- 2L
      state$screen <- "form"
    } else if (pick == "form_back") {
      state$form_values <- current_form_values()
      state$screen <- "card"
    } else if (kind == "ep") {
      state$endpoint <- value; state$came_from <- "known"; state$screen <- "card"
    } else if (kind == "guided") {
      if (state$screen == "g_vars") save_guided_variables()
      if (state$screen == "g_analyses") save_guided_analyses()
      state$screen <- switch(value, variables = "g_vars", analyses = "g_analyses", plan = "g_plan")
    }
  })

  # Re-render the analyses screen when a follow-up question appears or is
  # answered (ticking doesn't need a re-render).
  observeEvent(input$g_rule, state$rule <- input$g_rule, ignoreInit = TRUE)

  # Input screen: redraw for a new number of mediators, keeping the values.
  observeEvent(input$f_n_mediators, {
    k <- as.integer(input$f_n_mediators)
    if (!is.na(k) && k != state$form_k) {
      state$form_values <- current_form_values()
      state$form_k <- k
    }
  }, ignoreInit = TRUE)
  observeEvent(input$form_check, {
    fields <- current_form_fields()
    values <- current_form_values()
    values$claim <- state$start$claim %||% "one" # screen A's claim, for the result's note
    problems <- form_problems(fields, values)
    spec <- if (length(problems) == 0) build_spec(forms, state$endpoint, fields, values)
    check <- if (length(problems) == 0) check_spec(spec, fields)
    state$calc <- NULL
    state$long_spec <- NULL
    cancel_job()
    if (identical(check$status, "ok") && runs_long(forms, state$endpoint) &&
        !has_preview(forms, state$endpoint, spec$goal$type)) {
      # E10-E14, required N: no preview; the R script straight away.
      if (is.null(spec$options$seed)) spec$options$seed <- as.integer(forms$default_seed)
      state$long_spec <- spec
      output$form_result <- renderUI(no_preview_ui(forms, state$endpoint, spec))
      session$sendCustomMessage("focus_result", "form_result")
    } else if (identical(check$status, "ok") && runs_long(forms, state$endpoint)) {
      # E10-E14, power: a rough preview first, in a separate R process. The
      # full run or the R script is offered once the preview is shown.
      if (is.null(spec$options$seed)) spec$options$seed <- as.integer(forms$default_seed)
      state$long_spec <- spec
      usual <- preview_seconds(forms, state$endpoint, spec$goal$type)
      output$form_result <- renderUI(calculating_background_ui(usual,
        sprintf("Running a rough preview (%s simulations)\u2026", whole(preview_nrep(forms)))))
      start_job("preview", preview_spec(spec, preview_nrep(forms)), usual,
        list(ep_id = state$endpoint, fields = fields, values = values, advice = check$advice))
    } else if (identical(check$status, "ok") && form_calculates(forms, state$endpoint) && runs_in_background(forms, state$endpoint)) {
      # Long runs (E9): a separate R process, polled below, with an estimated
      # progress bar and a Cancel button.
      if (is.null(spec$options$seed)) spec$options$seed <- as.integer(forms$default_seed)
      usual <- usual_seconds(forms, state$endpoint, spec$goal$type)
      output$form_result <- renderUI(calculating_background_ui(usual))
      start_job("calc", spec, usual, list(ep_id = state$endpoint, fields = fields, values = values, advice = check$advice))
    } else if (identical(check$status, "ok") && form_calculates(forms, state$endpoint)) {
      # Show "Calculating" first; the engine runs once that has reached the
      # browser (seconds for these end points).
      output$form_result <- renderUI(calculating_ui())
      ep_id <- state$endpoint
      session$onFlushed(function() {
        calc <- if (identical(values$goal, "sensitivity_curve")) run_sensitivity_curve(spec, seed = forms$default_seed) else run_calculation(spec, seed = forms$default_seed)
        isolate(state$calc <- calc)
        output$form_result <- renderUI(result_panel_ui(tree, forms, ep_id, fields, values, calc, check$advice))
        session$sendCustomMessage("focus_result", "form_result")
      }, once = TRUE)
    } else {
      output$form_result <- renderUI(form_result_ui(tree$endpoints[[state$endpoint]], problems, check, spec))
    }
    session$sendCustomMessage("focus_result", "form_result")
  })
  # A background calculation: one at a time per session.
  job <- new.env()
  job_running <- reactiveVal(FALSE)
  cancel_job <- function() {
    if (!is.null(job$process) && job$process$is_alive()) job$process$kill()
    job$process <- NULL
    job_running(FALSE)
  }
  # kind: "calc" (E9, or E10-E12's full run) shows the result; "preview"
  # shows the preview panel.
  start_job <- function(kind, spec, usual, shown) {
    job$kind <- kind
    job$process <- start_background_calculation(spec, seed = forms$default_seed)
    job$started <- Sys.time()
    job$usual <- usual
    job$shown <- shown
    job_running(TRUE)
  }
  session$onSessionEnded(cancel_job)
  observe({
    req(job_running())
    invalidateLater(500)
    elapsed <- as.numeric(difftime(Sys.time(), job$started, units = "secs"))
    if (job$process$is_alive()) {
      value <- progress_estimate(elapsed, job$usual)
      session$sendCustomMessage("calc_progress", list(
        value = if (is.na(value)) NULL else round(100 * value),
        text = progress_text(elapsed, job$usual)))
      return()
    }
    calc <- collect_background_calculation(job$process)
    job$process <- NULL
    job_running(FALSE)
    shown <- job$shown
    if (identical(job$kind, "preview")) {
      # Not a result: nothing to download from it.
      range <- if (identical(calc$status, "ok")) preview_range(calc$result)
      output$form_result <- renderUI(preview_panel_ui(forms, shown$ep_id, calc, state$long_spec, range))
    } else {
      state$calc <- calc
      output$form_result <- renderUI(result_panel_ui(tree, forms, shown$ep_id, shown$fields, shown$values, calc, shown$advice))
    }
    session$sendCustomMessage("focus_result", "form_result")
  })
  # E10-E12, power: the full run at the app's defaults, after the preview.
  observeEvent(input$full_run, {
    req(state$long_spec)
    spec <- state$long_spec
    usual <- full_seconds(forms, state$endpoint, spec$goal$type)
    output$form_result <- renderUI(calculating_background_ui(usual,
      sprintf("Running the full analysis (%s simulations)\u2026", whole(spec$options$nrep %||% 1000L))))
    start_job("calc", spec, usual, job$shown)
    session$sendCustomMessage("focus_result", "form_result")
  })
  observeEvent(input$calc_cancel, {
    cancel_job()
    output$form_result <- renderUI(cancelled_ui())
    session$sendCustomMessage("focus_result", "form_result")
  })
  # Leaving the input screen stops a run in progress.
  observeEvent(state$screen, if (!identical(state$screen, "form")) cancel_job(), ignoreInit = TRUE)

  # The engine's own exports, for the last result.
  output$download_script <- downloadHandler(
    filename = function() sprintf("powerkit-%s-script.R", state$endpoint),
    content = function(file) {
      export <- engine_function("export_script")
      export(state$calc$spec, state$calc$result, file = file)
    }
  )
  output$download_citations <- downloadHandler(
    filename = function() sprintf("powerkit-%s-citations.txt", state$endpoint),
    content = function(file) {
      export <- engine_function("export_citations")
      export(state$calc$result, format = "text", file = file)
    }
  )
  # E10-E14: the R script that runs the full analysis on the user's computer.
  output$download_run_script <- downloadHandler(
    filename = function() sprintf("powerkit-%s-run-full-analysis.R", state$endpoint),
    content = function(file) {
      export <- engine_function("export_run_script")
      export(state$long_spec, file = file, run_time = script_run_time(forms, state$endpoint, state$long_spec$goal$type))
    }
  )
  # Project files: the engine writes and reads them (write_project(),
  # read_project()); the app passes the route and puts the screen back.
  output$download_project <- downloadHandler(
    filename = function() project_file_name(state$endpoint),
    content = function(file) {
      write <- engine_function("write_project")
      write(state$calc$spec, state$calc$result,
        route = project_route(reactiveValuesToList(state), current_form_values()), file = file)
    }
  )
  observeEvent(input$open_project, {
    path <- input$open_project$datapath
    read <- engine_function("read_project")
    project <- if (is.null(read)) {
      "Opening a project needs powerkit's engine, which isn't installed where this prototype is running."
    } else {
      tryCatch(read(path), error = function(e) {
        if (inherits(e, "powerkit_error")) conditionMessage(e) else "This file couldn't be opened as a powerkit project."
      })
    }
    restored <- if (is.character(project)) project else restore_from_project(project$route, tree, forms)
    if (is.character(restored)) {
      output$open_project_message <- renderUI(div(class = "alert alert-warning", role = "alert", restored))
      return()
    }
    cancel_job()
    state$calc <- NULL
    state$long_spec <- NULL
    for (name in names(restored)) state[[name]] <- restored[[name]]
    output$form_result <- renderUI(project_opened_ui(project))
  })
  observeEvent(input$form_copy, {
    text <- answers_text(tree, route_by_id(tree, state$route)$label, state$history, state$endpoint, current_form_fields(), current_form_values())
    output$form_copy_text <- renderUI(div(class = "form-field mt-2",
      textAreaInput("copy_text_box", "Your answers as text (select and copy if the button didn't)", value = text, rows = 8, width = "100%")))
    session$sendCustomMessage("copy_answers", text)
  })
  output$screen <- renderUI({
    switch(
      state$screen,
      start = tagList(start_ui(tree, isolate(state$start)), open_project_ui()),
      known = known_ui(tree, state$history, state$ctx),
      node = node_ui(tree, state$node, state$history, state$ctx),
      card = tagList(
        trail_ui(state$history),
        card_ui(tree, state$endpoint, history = state$history),
        card_nav_ui(forms, state$endpoint),
        mismatch_ui("mismatch-path", path_text(tree, route_by_id(tree, state$route)$label, state$history, state$endpoint))
      ),
      form = form_ui(tree, forms, state$endpoint, form_groups(forms, state$endpoint, state$form_k, state$start), isolate(state$form_values), state$history),
      g_vars = guided_variables_ui(tree, state$answers, state$ctx, state$history),
      g_analyses = guided_analyses_ui(tree, routed_answers(), state$ticked, state$primary, state$asks, isolate(state$rule)),
      g_plan = guided_plan_ui(tree, routed_answers(), state$ticked, state$primary, state$asks, state$rule,
        history = state$history, route_label = route_by_id(tree, state$route)$label, raw_answers = state$answers)
    )
  })
}

shinyApp(ui, server)
