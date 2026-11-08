# Educational repeated studies. All data generation and numerical summaries
# come from the engine; this file displays and exports the returned run.
study_variation_ui <- function() {
  conditionalPanel("input.labs_tool == 'variation'",
    labs_tool_head("variation"),
    p("Imagine repeating the same study 1,000 times, drawing new participants each time. The population effect stays fixed, but the estimates and p-values vary."),
    p(class = "small", "The studies have two independent, equal-sized groups, normally distributed scores with equal population SDs, and a two-sided Student t-test. No missing data or publication selection is generated. The highlighted subset simply shows what happens if you look only at significant results."),
    sliderInput("variation_n", "Total participants in each study (both groups together)", min = 6, max = 1000, value = 64, step = 2, width = "100%"),
    sliderInput("variation_d", "True population effect, Cohen's d (group 2 minus group 1)", min = -1, max = 1, value = 0.3, step = 0.05, width = "100%"),
    p(class = "small", "Cohen's d is the difference between the population means divided by the within-group SD. Zero means no difference; a negative value reverses the direction. The starting value is an illustration, not a recommended assumption."),
    selectInput("variation_alpha", "Significance threshold (alpha)", choices = c("0.005", "0.01", "0.05", "0.10"), selected = "0.05"),
    p(class = "small", "A result is highlighted when its two-sided p-value is below alpha. With no true effect, this happens at approximately the alpha rate under these assumptions. A p-value is not the probability that the null hypothesis is true."),
    tags$details(tags$summary("Reproduce a particular simulation"),
      checkboxInput("variation_fixed_seed", "Use a fixed random seed", FALSE),
      numericInput("variation_seed", "Seed (a number identifying the random draws)", value = 20261104, min = 1, max = 2147483646, step = 1),
      p(class = "small", "The same settings and seed reproduce the same studies with the same software versions. Otherwise each run draws a new seed, recorded with its results.")),
    actionButton("variation_run", "Run 1,000 studies", class = "btn btn-primary"),
    uiOutput("variation_summary"),
    conditionalPanel("input.variation_run > 0",
      plotOutput("variation_grid", height = "360px"),
      plotOutput("variation_pvalues", height = "320px"),
      plotOutput("variation_estimates", height = "380px"),
      download_button("variation_csv", "Download simulated study results (CSV)", class = "btn btn-outline-primary")),
    p(class = "small", "This example teaches sampling variation and significance selection. It is not a power calculation for every study design, and does not show that a non-significant result proves no effect."))
}

study_variation_summary <- function(run, changed = FALSE) {
  if (!is.null(run$problem)) return(div(class = "alert alert-warning", role = "alert", run$problem))
  s <- run$summary
  a <- run$settings
  percent <- function(x) sprintf("%.1f%%", 100 * x)
  div(class = "result-panel mt-3", role = "status",
    if (changed) p(class = "alert alert-warning", "Settings have changed. These are the previous run's results; press Run 1,000 studies to update them."),
    h4(sprintf("%s of %s studies were significant (%s)", whole(s$significant), whole(s$valid), percent(s$proportion_significant))),
    p(sprintf("Run settings: %s participants in total (%s per group), true d = %s, alpha = %s; seed %s.", whole(a$n), whole(a$n_per_group), format(a$d), format(a$alpha), format(a$seed, scientific = FALSE))),
    p(sprintf("Monte Carlo 95%% interval for the significant-result rate: %s to %s. This reflects the finite number of simulated studies, not uncertainty about the true population effect.", percent(s$simulation_interval[1]), percent(s$simulation_interval[2]))),
    if (a$d == 0) p("The true effect is exactly zero, so every significant result here is a false positive. An exaggeration ratio relative to zero is undefined.")
    else if (s$significant == 0) p("No study was significant in this run, so there is no significant subset to summarise.")
    else tagList(
      p(sprintf("Among significant studies, %s of %s (%s) estimated an effect larger in absolute magnitude than the true effect. %s estimated the wrong direction.",
        whole(s$overestimated_significant), whole(s$significant), percent(s$overestimated_significant / s$significant), whole(s$wrong_direction_significant))),
      p(sprintf("Their mean absolute estimate was %.3f, or %.2f times the true magnitude of %.3f. Across all studies, the mean signed estimate was %.3f.", s$selected_mean_magnitude, s$selected_magnitude_ratio, abs(a$d), s$mean_estimate))),
    p(class = "small", "All observations and results here are simulated. Highlighting significant studies illustrates selection; it does not estimate the publication bias in any real literature."),
    tags$details(tags$summary("How this was calculated"),
      p("Each study generates independent normal observations with means 0 and d and both SDs 1. R's stats::t.test uses pooled variance and a two-sided decision; effectsize::cohens_d computes the pooled-SD estimate from the same observations. Positive estimates mean group 2 scored higher."),
      p(sprintf("R: %s. Packages: %s. Run hash: %s.", run$provenance$r_version,
        paste(paste(names(run$provenance$packages), run$provenance$packages), collapse = "; "), run$provenance$spec_hash))))
}

# The three charts, in the result page's chart style: significant studies
# in the app's blue, the rest pale, the threshold and the true effect as
# dashed lines, and the key below each chart.
study_variation_plot <- function(run, view) {
  data <- run$studies
  selected <- data$significant
  blue <- chart_colours$blue
  pale <- chart_colours$pale
  op <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(op))
  if (identical(view, "grid")) {
    chart_start(chart_key_rows(2), top = 2.4, bottom = 0.5, left = 0.5)
    i <- seq_len(nrow(data)) - 1L
    graphics::plot(i %% 40, -(i %/% 40), pch = 16, cex = 0.75, col = ifelse(selected, blue, pale), axes = FALSE, xlab = "", ylab = "")
    chart_title("Each dot is one simulated study")
    chart_key(pch = 16, pt.cex = 1.4, col = c(blue, pale), legend = c("Significant", "Not significant"))
  } else if (identical(view, "pvalues")) {
    chart_start(chart_key_rows(1), top = 2.4)
    graphics::hist(data$p_value, breaks = seq(0, 1, by = 0.05), col = pale, border = "white", axes = FALSE,
      main = "", xlab = "Two-sided p-value", ylab = "Number of studies", xlim = c(0, 1))
    chart_axes()
    graphics::abline(v = run$settings$alpha, col = chart_colours$navy, lwd = 2, lty = 2)
    chart_title("P-values from all studies")
    chart_key(lty = 2, lwd = 2, col = chart_colours$navy, legend = "The significance threshold (alpha)")
  } else {
    chart_start(chart_key_rows(3), top = 2.4)
    h <- graphics::hist(data$estimate, breaks = 30, col = pale, border = "white", axes = FALSE,
      main = "", xlab = "Estimated Cohen's d", ylab = "Number of studies")
    chart_axes()
    if (any(selected)) graphics::hist(data$estimate[selected], breaks = h$breaks, add = TRUE, col = blue, border = "white")
    graphics::abline(v = run$settings$d, col = chart_colours$red, lwd = 2, lty = 2)
    chart_title("Effect estimates")
    chart_key(pch = c(15, 15, NA), pt.cex = 1.8, lty = c(NA, NA, 2), lwd = c(NA, NA, 2),
      col = c(pale, blue, chart_colours$red), legend = c("All studies", "The significant ones", "The true population effect"))
  }
}

study_variation_csv <- function(run) {
  data <- run$studies
  data$data_kind <- "SIMULATED_STUDY_RESULTS_NOT_REAL_DATA"
  data$total_n <- run$settings$n
  data$n_per_group <- run$settings$n_per_group
  data$true_d <- run$settings$d
  data$alpha <- run$settings$alpha
  data$seed <- run$settings$seed
  data$population <- run$settings$population
  data$analysis <- run$settings$analysis
  data$spec_hash <- run$provenance$spec_hash
  data$r_version <- run$provenance$r_version
  data$packages <- paste(paste(names(run$provenance$packages), run$provenance$packages), collapse = "; ")
  data
}

study_variation_server <- function(input, output, session) {
  run <- shiny::eventReactive(input$variation_run, {
    engine <- engine_function("study_variation")
    if (is.null(engine)) return(list(problem = "This tool needs the current powerkit engine."))
    seed <- if (isTRUE(input$variation_fixed_seed)) input$variation_seed else sample.int(2147483646, 1)
    tryCatch(engine(n = input$variation_n, d = input$variation_d,
      alpha = as.numeric(input$variation_alpha), seed = seed, replications = 1000L),
      powerkit_run_error = function(e) list(problem = conditionMessage(e)),
      error = function(e) list(problem = "The simulation could not finish. Please try again or report the settings."))
  })
  output$variation_summary <- shiny::renderUI({
    shiny::req(run())
    a <- run()$settings
    changed <- !is.null(a) && (!isTRUE(all.equal(a$n, input$variation_n)) ||
      !isTRUE(all.equal(a$d, input$variation_d)) || !isTRUE(all.equal(a$alpha, as.numeric(input$variation_alpha))) ||
      (isTRUE(input$variation_fixed_seed) && !isTRUE(all.equal(a$seed, input$variation_seed))))
    study_variation_summary(run(), changed)
  })
  for (view in c("grid", "pvalues", "estimates")) local({
    kind <- view
    output[[paste0("variation_", kind)]] <- shiny::renderPlot({
      shiny::req(run(), is.null(run()$problem))
      study_variation_plot(run(), kind)
    }, res = 96, alt = shiny::reactive({
      shiny::req(run(), is.null(run()$problem))
      sprintf("%s plot of %s simulated studies with true d %s. %s studies were significant. Numerical summaries and a CSV are provided alongside the plots.", kind,
        run()$settings$replications, run()$settings$d, run()$summary$significant)
    }))
  })
  output$variation_csv <- shiny::downloadHandler(filename = function() "powerkit-SIMULATED-study-results.csv",
    content = function(file) {
      shiny::req(run(), is.null(run()$problem))
      utils::write.csv(study_variation_csv(run()), file, row.names = FALSE, na = "")
    })
}
