# Screen 2: the design drawn as an interaction plot and described in plain
# words, using the user's labels. Display only: nothing here computes power.

confirm_ui <- function() {
  tagList(
    h3("2. Check your design"),
    p(class = "text-muted", "This is what will be analysed. Nothing has been calculated yet."),
    fluidRow(
      column(6, plotOutput("interaction_plot", height = "360px")),
      column(6, uiOutput("design_words"))
    ),
    uiOutput("design_advice"),
    div(
      class = "mt-3",
      actionButton("back_to_design", "Back to edit", icon = icon("arrow-left"), class = "btn-outline-secondary"),
      actionButton("confirm_run", "Confirm and run", icon = icon("play"), class = "btn-success btn-lg")
    )
  )
}

# Cell means as a 2x2 matrix: rows = levels of A, columns = levels of B.
spec_means <- function(spec) {
  matrix(as.numeric(unlist(spec$population$means)), nrow = 2, byrow = TRUE)
}

spec_labels <- function(spec) {
  v <- spec$variables
  list(
    a = v$A$label, a_levels = unlist(v$A$levels),
    b = v$B$label, b_levels = unlist(v$B$levels),
    y = v$Y$label
  )
}

fmt_num <- function(x) format(signif(x, 4), trim = TRUE, scientific = FALSE, drop0trailing = TRUE)

# APA style for values that can't exceed 1: no leading zero, at least two
# decimals (0.05 -> ".05", 0.6 -> ".60", 0.005 -> ".005").
fmt_apa <- function(x) {
  s <- if (isTRUE(all.equal(round(x, 2), x))) sprintf("%.2f", x) else fmt_num(x)
  sub("^(-?)0\\.", "\\1.", s)
}

fmt_pct <- function(p) paste0(fmt_num(round(100 * p, 1)), "%")

interaction_plot_2x2 <- function(spec) {
  means <- spec_means(spec)
  lab <- spec_labels(spec)
  mixed <- spec$template == "2x2_mixed"
  colours <- c("#1b6ca8", "#d1495b")
  span <- range(means)
  pad <- max(diff(span) * 0.25, abs(span) * 0.05, 0.5)
  old <- graphics::par(mar = c(4.5, 4.5, 3, 1))
  on.exit(graphics::par(old))
  graphics::plot(
    NA,
    xlim = c(0.7, 2.3), ylim = c(span[1] - pad, span[2] + pad),
    xaxt = "n", xlab = paste0(lab$b, if (mixed) " (within participants)" else ""),
    ylab = lab$y, main = "Expected cell means", las = 1, bty = "l"
  )
  graphics::axis(1, at = 1:2, labels = lab$b_levels)
  for (i in 1:2) {
    graphics::lines(1:2, means[i, ], col = colours[i], lwd = 3)
    graphics::points(1:2, means[i, ], col = colours[i], pch = 19, cex = 1.6)
    graphics::text(1:2, means[i, ], fmt_num(means[i, ]), pos = 3, offset = 0.8, col = colours[i])
  }
  graphics::legend(
    "topright",
    legend = lab$a_levels, title = paste0(lab$a, if (mixed) " (between)" else ""),
    col = colours, lwd = 3, pch = 19, bty = "n", inset = c(0, -0.02)
  )
}

effect_phrase <- function(spec) {
  lab <- spec_labels(spec)
  switch(
    spec$target_test$effect,
    interaction = sprintf("%s × %s interaction", lab$a, lab$b),
    main_effect_A = sprintf("main effect of %s", lab$a),
    main_effect_B = sprintf("main effect of %s", lab$b)
  )
}

justification_phrase <- function(type) {
  names(justification_choices)[match(type, justification_choices)]
}

# Plain-words description: a list of HTML paragraphs.
describe_design <- function(spec) {
  lab <- spec_labels(spec)
  means <- spec_means(spec)
  pop <- spec$population
  a <- lab$a_levels
  b <- lab$b_levels
  strong <- tags$strong

  design <- if (spec$template == "2x2_between") {
    p(
      "A ", strong("2 × 2 between-participants design."),
      sprintf(
        " Each participant is in one of four equal-sized groups, formed by crossing %s (%s or %s) with %s (%s or %s).",
        lab$a, a[1], a[2], lab$b, b[1], b[2]
      )
    )
  } else {
    p(
      "A ", strong("2 × 2 mixed design."),
      sprintf(
        " Participants are split into two equal groups by %s (%s or %s). Everyone is measured under both levels of %s (%s and %s); the two measurements correlate r = %s.",
        lab$a, a[1], a[2], lab$b, b[1], b[2], fmt_apa(pop$r)
      )
    )
  }

  cell_list <- tags$ul(lapply(1:2, function(i) {
    tags$li(sprintf("%s, %s: %s;   %s, %s: %s", a[i], b[1], fmt_num(means[i, 1]), a[i], b[2], fmt_num(means[i, 2])))
  }))

  effect <- switch(
    spec$target_test$effect,
    interaction = sprintf(
      "Does the difference between %s and %s depend on %s? In your numbers, %s minus %s is %s for %s and %s for %s.",
      b[2], b[1], lab$a, b[2], b[1],
      fmt_num(means[1, 2] - means[1, 1]), a[1], fmt_num(means[2, 2] - means[2, 1]), a[2]
    ),
    main_effect_A = sprintf(
      "Averaged over %s, does %s differ between %s and %s? In your numbers the averages are %s and %s.",
      lab$b, lab$y, a[1], a[2], fmt_num(mean(means[1, ])), fmt_num(mean(means[2, ]))
    ),
    main_effect_B = sprintf(
      "Averaged over %s, does %s differ between %s and %s? In your numbers the averages are %s and %s.",
      lab$a, lab$y, b[1], b[2], fmt_num(mean(means[, 1])), fmt_num(mean(means[, 2]))
    )
  )

  just <- spec$effect_justification
  tagList(
    design,
    p(sprintf("The outcome is %s. You expect these averages, with a standard deviation of %s in every cell:", lab$y, fmt_num(pop$sd))),
    cell_list,
    p(strong(sprintf("The test: the %s. ", effect_phrase(spec))), effect),
    p(sprintf(
      "We will find the smallest total number of participants that gives at least %s power to detect this at alpha = %s (two-sided F test). Power is calculated exactly, by the Superpower package through the powerkit engine.",
      fmt_pct(spec$goal$power), fmt_apa(spec$target_test$alpha)
    )),
    p(
      strong("Why this effect size: "),
      sprintf("%s. %s", justification_phrase(just$type), just$source),
      if (!is.null(just$adjustment)) sprintf(" Adjustment: %s", just$adjustment)
    )
  )
}
