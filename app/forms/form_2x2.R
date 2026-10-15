# Screen 1: the 2x2 design form, the examples behind "Load example", and
# the translation from form values to a design spec.

justification_choices <- c(
  "Smallest effect of interest" = "smallest_effect_of_interest",
  "Meta-analysis" = "meta_analysis",
  "Earlier study (with an adjustment for bias)" = "prior_study",
  "Pilot study" = "pilot_study"
)

effect_choices <- c(
  "The interaction (A x B)" = "interaction",
  "Main effect of factor A" = "main_effect_A",
  "Main effect of factor B" = "main_effect_B"
)

# Worked examples. Means are in the order A1 B1, A1 B2, A2 B1, A2 B2.
examples_2x2 <- list(
  "2x2_between" = list(
    a_label = "Factor A", a1 = "a1", a2 = "a2",
    b_label = "Factor B", b1 = "b1", b2 = "b2",
    y_label = "Score",
    means = c(1, 0, 0, 1), sd = 2, r = NA,
    effect = "interaction", alpha = 0.05, power = 0.90,
    just_type = "smallest_effect_of_interest",
    just_source = paste(
      "Demonstration values: the crossover interaction from the Superpower",
      "package vignette 'More ANOVA designs' (two-way between-participants design)"
    )
  ),
  "2x2_mixed" = list(
    a_label = "Factor A", a1 = "a1", a2 = "a2",
    b_label = "Factor B", b1 = "b1", b2 = "b2",
    y_label = "Score",
    means = c(-0.25, 0.25, 0.25, -0.25), sd = 1, r = 0.5,
    effect = "interaction", alpha = 0.05, power = 0.90,
    just_type = "smallest_effect_of_interest",
    just_source = paste(
      "Demonstration values: the crossover interaction from the Superpower",
      "package vignette 'More ANOVA designs' (2x2 within-between design)"
    )
  )
)

design_form_ui <- function() {
  tagList(
    h3("1. Describe your design"),
    p(
      class = "text-muted",
      "Two factors with two levels each. Enter what you expect in the population;",
      "nothing is calculated until you confirm on the next screen."
    ),
    fluidRow(
      column(
        8,
        radioButtons(
          "template", "Design",
          choices = c(
            "2 x 2 between participants (everyone is in one of four groups)" = "2x2_between",
            "2 x 2 mixed (factor A between participants, factor B within)" = "2x2_mixed"
          ),
          width = "100%"
        )
      ),
      column(
        4,
        actionButton("load_example", "Load example", icon = icon("flask"), class = "btn-outline-secondary mt-4"),
        uiOutput("example_note")
      )
    ),
    h4("Names"),
    fluidRow(
      column(4, textInput("a_label", "Factor A name", placeholder = "e.g. Feedback")),
      column(4, textInput("a1", "Factor A, level 1", placeholder = "e.g. None")),
      column(4, textInput("a2", "Factor A, level 2", placeholder = "e.g. Praise"))
    ),
    fluidRow(
      column(4, textInput("b_label", "Factor B name", placeholder = "e.g. Task difficulty")),
      column(4, textInput("b1", "Factor B, level 1", placeholder = "e.g. Easy")),
      column(4, textInput("b2", "Factor B, level 2", placeholder = "e.g. Hard"))
    ),
    fluidRow(
      column(8, textInput("y_label", "Outcome name", placeholder = "e.g. Persistence (minutes)", width = "100%"))
    ),
    h4("Expected population values"),
    p(class = "text-muted", "Cell means in the outcome's own units, and the standard deviation within each cell."),
    tags$table(
      class = "table table-sm means-grid",
      tags$thead(tags$tr(
        tags$th(""),
        tags$th(textOutput("b1_head", inline = TRUE)),
        tags$th(textOutput("b2_head", inline = TRUE))
      )),
      tags$tbody(
        tags$tr(
          tags$th(textOutput("a1_head", inline = TRUE)),
          tags$td(numericInput("m11", NULL, value = NA)),
          tags$td(numericInput("m12", NULL, value = NA))
        ),
        tags$tr(
          tags$th(textOutput("a2_head", inline = TRUE)),
          tags$td(numericInput("m21", NULL, value = NA)),
          tags$td(numericInput("m22", NULL, value = NA))
        )
      )
    ),
    fluidRow(
      column(4, numericInput("sd", "Standard deviation (every cell)", value = NA, min = 0)),
      column(
        4,
        conditionalPanel(
          "input.template == '2x2_mixed'",
          numericInput("r", "Correlation between the repeated measures", value = NA, min = -1, max = 1, step = 0.05)
        )
      )
    ),
    h4("Test and goal"),
    fluidRow(
      column(4, selectInput("effect", "Effect to detect", choices = effect_choices)),
      column(4, numericInput("alpha", "Alpha", value = 0.05, min = 0.001, max = 0.5, step = 0.01)),
      column(4, numericInput("power", "Target power", value = 0.90, min = 0.5, max = 0.99, step = 0.05))
    ),
    h4("Why this effect size?"),
    fluidRow(
      column(4, selectInput("just_type", "Where the effect size comes from", choices = justification_choices)),
      column(8, textAreaInput("just_source", "Effect-size justification", rows = 2, width = "100%",
        placeholder = "In your own words: the reference or reasoning behind these means"
      ))
    ),
    conditionalPanel(
      "input.just_type == 'prior_study'",
      textInput("just_adjustment", "Adjustment to the earlier estimate", width = "100%",
        placeholder = "e.g. halved to allow for publication bias"
      )
    ),
    uiOutput("form_problems"),
    actionButton("to_confirm", "Continue to check the design", icon = icon("arrow-right"), class = "btn-primary btn-lg")
  )
}

# Fill the form with an example.
fill_example <- function(session, example) {
  for (id in c("a_label", "a1", "a2", "b_label", "b1", "b2", "y_label")) {
    updateTextInput(session, id, value = example[[id]])
  }
  cells <- c("m11", "m12", "m21", "m22")
  for (k in seq_along(cells)) {
    updateNumericInput(session, cells[k], value = example$means[k])
  }
  updateNumericInput(session, "sd", value = example$sd)
  updateNumericInput(session, "r", value = example$r)
  updateSelectInput(session, "effect", selected = example$effect)
  updateNumericInput(session, "alpha", value = example$alpha)
  updateNumericInput(session, "power", value = example$power)
  updateSelectInput(session, "just_type", selected = example$just_type)
  updateTextAreaInput(session, "just_source", value = example$just_source)
}

# Form values (a plain list, as read from Shiny's `input`) to a design spec
# (named list). Nothing is checked here: the engine's validator does that,
# so its messages are the ones users see. Blank numbers become missing
# fields, which the validator reports by name.
build_spec_2x2 <- function(x) {
  text <- function(v) if (is.null(v) || length(v) == 0 || is.na(v)) "" else trimws(as.character(v))
  number <- function(v) {
    v <- suppressWarnings(as.numeric(v))
    if (length(v) == 0 || is.na(v)) NULL else v
  }
  cell <- function(v) {
    v <- suppressWarnings(as.numeric(v))
    if (length(v) == 0) NA_real_ else v
  }
  drop_null <- function(l) l[!vapply(l, is.null, logical(1))]

  mixed <- identical(x$template, "2x2_mixed")
  factor_variable <- function(type, label, l1, l2) {
    list(type = type, label = text(label), levels = list(text(l1), text(l2)))
  }
  justification <- list(type = text(x$just_type), source = text(x$just_source))
  if (identical(x$just_type, "prior_study") || nzchar(text(x$just_adjustment))) {
    justification$adjustment <- text(x$just_adjustment)
  }

  list(
    spec_version = "0.1",
    design = "factorial_anova",
    template = if (mixed) "2x2_mixed" else "2x2_between",
    variables = list(
      A = factor_variable("between_factor", x$a_label, x$a1, x$a2),
      B = factor_variable(if (mixed) "within_factor" else "between_factor", x$b_label, x$b1, x$b2),
      Y = list(type = "continuous", label = text(x$y_label))
    ),
    population = drop_null(list(
      metric = "raw",
      means = list(list(cell(x$m11), cell(x$m12)), list(cell(x$m21), cell(x$m22))),
      sd = number(x$sd),
      r = if (mixed) number(x$r)
    )),
    effect_justification = justification,
    target_test = drop_null(list(effect = text(x$effect), method = "anova_f", alpha = number(x$alpha))),
    goal = drop_null(list(type = "sample_size", power = number(x$power))),
    options = list(method = "exact")
  )
}
