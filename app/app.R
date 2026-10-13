# powerkit prototype: 2x2 between and 2x2 mixed designs.
#
# Run from RStudio: open Powerkit.Rproj, then source("run_app.R") (or open
# this file and click "Run App"). The app builds a design spec and calls the
# powerkit engine (run_spec()); it never computes power itself.

library(shiny)

options(shiny.sanitize.errors = TRUE)

source("engine-bridge.R", local = TRUE)
source(file.path("forms", "form_2x2.R"), local = TRUE)
source(file.path("confirm", "confirm_2x2.R"), local = TRUE)
source(file.path("results", "results_2x2.R"), local = TRUE)
source(file.path("checks", "benchmarks.R"), local = TRUE)

load_engine()

prototype_banner <- div(
  class = "alert alert-warning prototype-banner",
  role = "alert",
  icon("triangle-exclamation"),
  tags$strong("Prototype — not yet for use in real studies.")
)

app_css <- "
  .prototype-banner { font-size: 1.1rem; text-align: center; margin: 0 0 1rem 0; }
  .means-grid { width: auto; }
  .means-grid td, .means-grid th { vertical-align: middle; padding: 0.25rem 0.75rem; }
  .means-grid .form-group { margin-bottom: 0; width: 9rem; }
  .steps { margin-bottom: 1rem; }
  .steps span { padding: 0.3rem 0.8rem; border-radius: 1rem; margin-right: 0.4rem; color: #6c757d; background: #f1f3f5; }
  .steps span.active { color: #fff; background: #1b6ca8; }
  .headline { font-size: 2.2rem; font-weight: 600; }
  .problems ul { margin-bottom: 0; }
  textarea.methods { font-family: Georgia, serif; font-size: 1rem; }
"

ui <- navbarPage(
  title = "powerkit",
  id = "nav",
  theme = if (requireNamespace("bslib", quietly = TRUE)) bslib::bs_theme(version = 5),
  header = tagList(tags$head(tags$style(HTML(app_css))), div(class = "container-fluid", prototype_banner)),
  tabPanel(
    "Power analysis",
    uiOutput("steps"),
    tabsetPanel(
      id = "screen",
      type = "hidden",
      tabPanelBody("design", design_form_ui()),
      tabPanelBody("confirm", confirm_ui()),
      tabPanelBody("results", results_ui())
    )
  ),
  tabPanel("How we check this", checks_ui())
)

`%||%` <- function(x, y) if (is.null(x)) y else x

problem_box <- function(problems, spec = NULL, heading = "Please check the following:") {
  if (length(problems) == 0) {
    return(NULL)
  }
  if (!is.null(spec)) {
    problems <- friendly_problems(problems, spec)
  }
  div(class = "alert alert-danger problems mt-3", tags$strong(heading), tags$ul(lapply(problems, tags$li)))
}

advice_box <- function(advice) {
  if (length(advice) == 0) {
    return(NULL)
  }
  div(class = "alert alert-info mt-3", tags$strong("Advice: "), lapply(advice, tags$p))
}

server <- function(input, output, session) {
  state <- reactiveValues(spec = NULL, advice = character(), problems = character(), run = NULL, run_problems = character())

  output$steps <- renderUI({
    current <- input$screen %||% "design"
    step <- function(id, text) tags$span(class = if (identical(current, id)) "active", text)
    div(class = "steps", step("design", "1 Design"), step("confirm", "2 Confirm"), step("results", "3 Results"))
  })

  # Screen 1 -----------------------------------------------------------------

  heading <- function(id, fallback) renderText({
    value <- trimws(input[[id]] %||% "")
    if (nzchar(value)) value else fallback
  })
  output$a1_head <- heading("a1", "A level 1")
  output$a2_head <- heading("a2", "A level 2")
  output$b1_head <- heading("b1", "B level 1")
  output$b2_head <- heading("b2", "B level 2")

  example_loaded <- reactiveVal(NULL)
  observeEvent(input$load_example, {
    fill_example(session, examples_2x2[[input$template]])
    example_loaded(input$template)
  })
  output$example_note <- renderUI({
    req(example_loaded())
    p(class = "small text-muted mt-2", if (example_loaded() == "2x2_between") {
      "Loaded the Superpower vignette crossover example (means 1, 0, 0, 1; SD 2)."
    } else {
      "Loaded the Superpower vignette mixed-design crossover example (means -0.25, 0.25, 0.25, -0.25; SD 1; r .5)."
    })
  })

  form_values <- function() {
    ids <- c(
      "template", "a_label", "a1", "a2", "b_label", "b1", "b2", "y_label",
      "m11", "m12", "m21", "m22", "sd", "r", "effect", "alpha", "power",
      "just_type", "just_source", "just_adjustment"
    )
    stats::setNames(lapply(ids, function(id) input[[id]]), ids)
  }

  observeEvent(input$to_confirm, {
    spec <- build_spec_2x2(form_values())
    checked <- engine_call(validate_spec(spec))
    state$run <- NULL
    if (checked$ok) {
      state$spec <- checked$value
      state$advice <- checked$advice
      state$problems <- character()
      updateTabsetPanel(session, "screen", selected = "confirm")
    } else {
      state$spec <- NULL
      state$problems <- friendly_problems(checked$problems, spec)
    }
  })
  output$form_problems <- renderUI(problem_box(state$problems))

  # Screen 2 -----------------------------------------------------------------

  output$interaction_plot <- renderPlot({
    req(state$spec)
    interaction_plot_2x2(state$spec)
  })
  output$design_words <- renderUI({
    req(state$spec)
    describe_design(state$spec)
  })
  output$design_advice <- renderUI(tagList(advice_box(state$advice), problem_box(state$run_problems, heading = "The power analysis couldn't run:")))

  back_to_design <- function() {
    state$run_problems <- character()
    updateTabsetPanel(session, "screen", selected = "design")
  }
  observeEvent(input$back_to_design, back_to_design())
  observeEvent(input$back_to_design2, back_to_design())

  observeEvent(input$confirm_run, {
    req(state$spec)
    state$run_problems <- character()
    run <- withProgress(message = "Running the power analysis", value = 0.1, {
      run_design(state$spec, progress = incProgress)
    })
    if (run$ok) {
      state$run <- run$value
      updateTabsetPanel(session, "screen", selected = "results")
    } else {
      state$run_problems <- run$problems
    }
  })

  # Screen 3 -----------------------------------------------------------------

  output$result_headline <- renderUI({
    run <- req(state$run)
    n <- run$result$n_required$n
    spec <- run$spec
    div(
      class = "mb-3",
      div(class = "headline", sprintf("Required total N = %s", n)),
      p(sprintf(
        "%s per %s. Power at N = %s is %s (target %s), for the %s at alpha = %s. Exact calculation, so there is no simulation uncertainty.",
        n / group_count(spec), group_word(spec), n, fmt_pct(power_at_required(run$result)),
        fmt_pct(spec$goal$power), effect_phrase(spec), fmt_apa(spec$target_test$alpha)
      ))
    )
  })
  output$power_curve <- renderPlot(power_curve_plot(req(state$run)))
  output$result_interaction_plot <- renderPlot(interaction_plot_2x2(req(state$run)$spec))
  output$methods_box <- renderUI({
    run <- req(state$run)
    tags$textarea(class = "form-control methods", rows = 7, methods_paragraph(run))
  })
  output$citation_note <- renderUI({
    req(state$run)
    p(
      class = "small text-muted",
      "References for R, Superpower and powerkit will come from the project's curated reference list",
      "(engine/inst/citations/refs.bib), which is still empty, so none are inserted yet."
    )
  })
  output$provenance <- renderTable(provenance_table(req(state$run)), striped = TRUE)
  output$check_run <- renderTable(req(state$run)$result$check_run, digits = 6)

  output$download_script <- downloadHandler(
    filename = function() sprintf("powerkit-reproduce-%s.R", substr(state$run$result$provenance$spec_hash, 1, 8)),
    content = function(file) {
      con <- file(file, open = "w", encoding = "UTF-8")
      on.exit(close(con))
      writeLines(reproduction_script(state$run), con, sep = "")
    }
  )
  output$download_spec <- downloadHandler(
    filename = function() sprintf("powerkit-spec-%s.json", substr(state$run$result$provenance$spec_hash, 1, 8)),
    content = function(file) {
      jsonlite::write_json(unclass(state$run$spec), file, auto_unbox = TRUE, pretty = TRUE, digits = NA)
    }
  )

  # How we check this ----------------------------------------------------------

  checks <- reactiveVal(NULL)
  observeEvent(input$run_checks, {
    withProgress(message = "Running the published benchmarks", value = 0, {
      results <- lapply(benchmarks_2x2, function(b) {
        incProgress(1 / length(benchmarks_2x2), detail = b$id)
        engine_call(run_spec(benchmark_spec(b)))
      })
    })
    checks(results)
  })
  output$checks_table <- renderTable(
    {
      results <- checks()
      rows <- lapply(seq_along(benchmarks_2x2), function(i) benchmark_row(benchmarks_2x2[[i]], results[[i]]))
      do.call(rbind, rows)
    },
    striped = TRUE
  )
  output$checks_problems <- renderUI({
    results <- req(checks())
    problems <- unlist(lapply(results, function(r) r$problems))
    problem_box(problems, heading = "Engine messages:")
  })
}

shinyApp(ui, server)
