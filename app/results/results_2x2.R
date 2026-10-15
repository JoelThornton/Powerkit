# Screen 3: required N, power curve, methods paragraph and R script.
#
# A "run" is list(spec, result, curve): the validated spec, the
# powerkit_result that run_spec() returned for it, and the power curve (a
# data frame of n and power, every point also from run_spec()). The write-up
# and script use only values in these objects; they never compute power.

results_ui <- function() {
  tagList(
    h3("3. Results"),
    uiOutput("result_headline"),
    fluidRow(
      column(6, plotOutput("power_curve", height = "340px")),
      column(6, plotOutput("result_interaction_plot", height = "340px"))
    ),
    h4("Draft methods paragraph"),
    p(class = "text-muted", "Built from the result. Edit it here before copying; check every value against your plans."),
    uiOutput("methods_box"),
    uiOutput("citation_note"),
    div(
      class = "my-3",
      downloadButton("download_script", "Download R script (reproduces this with Superpower)", class = "btn-primary"),
      downloadButton("download_spec", "Download design spec (JSON)", class = "btn-outline-secondary")
    ),
    h4("Record of this run"),
    tableOutput("provenance"),
    tags$details(
      tags$summary("Check run: does Superpower reproduce the population you specified?"),
      tableOutput("check_run")
    ),
    div(
      class = "mt-3",
      actionButton("back_to_design2", "Change the design", icon = icon("arrow-left"), class = "btn-outline-secondary")
    )
  )
}

# Participants per between-participants cell (between) or group (mixed).
group_count <- function(spec) if (spec$template == "2x2_between") 4 else 2
group_word <- function(spec) if (spec$template == "2x2_between") "cell" else "group"

# Sample sizes for the power curve, around the required n: valid sizes
# (whole groups) from about a quarter of n to 1.75 times n.
curve_sizes <- function(n_required, step, points = 10) {
  sizes <- step * round(seq(0.25 * n_required, 1.75 * n_required, length.out = points) / step)
  sort(unique(sizes[sizes >= step]))
}

# Ask the engine for power at each sample size (goal type "power"), using
# the same seed as the main run. Sizes the engine can't do (e.g. too small
# for the exact method) are left out.
engine_power_curve <- function(spec, sizes, seed, progress = function() NULL) {
  rows <- lapply(sizes, function(n) {
    point <- spec
    point$goal <- list(type = "power", n = as.integer(n))
    point$options$seed <- seed
    out <- engine_call(run_spec(point))
    progress()
    if (out$ok) out$value$curve[, c("n", "power")]
  })
  do.call(rbind, rows)
}

# Confirmed design -> list(ok, value = run, problems). The run holds the
# validated spec, run_spec()'s result and a power curve from the engine.
run_design <- function(spec, progress = function(amount, detail) NULL) {
  progress(0, detail = "Finding the required sample size")
  main <- engine_call(run_spec(spec))
  if (!main$ok) {
    return(main)
  }
  result <- main$value
  sizes <- curve_sizes(result$n_required$n, group_count(spec))
  progress(0.2, detail = "Drawing the power curve")
  curve <- engine_power_curve(
    spec, sizes, result$provenance$seed,
    progress = function() progress(0.7 / length(sizes), detail = "Drawing the power curve")
  )
  list(ok = TRUE, value = list(spec = spec, result = result, curve = curve), problems = character())
}

power_at_required <- function(result) {
  curve <- result$curve
  curve$power[curve$n == result$n_required$n][1]
}

power_curve_plot <- function(run) {
  spec <- run$spec
  n <- run$result$n_required$n
  target <- spec$goal$power
  curve <- unique(rbind(run$curve, run$result$curve[, c("n", "power")]))
  curve <- curve[order(curve$n), ]
  old <- graphics::par(mar = c(4.5, 4.5, 3, 1))
  on.exit(graphics::par(old))
  graphics::plot(
    curve$n, curve$power,
    type = "l", lwd = 3, col = "#1b6ca8", ylim = c(0, 1), las = 1, bty = "l",
    xlab = "Total sample size (N)", ylab = "Power", main = sprintf("Power for the %s", effect_phrase(spec))
  )
  graphics::points(curve$n, curve$power, pch = 19, col = "#1b6ca8", cex = 0.8)
  graphics::abline(h = target, lty = 2, col = "grey40")
  graphics::abline(v = n, lty = 3, col = "#d1495b", lwd = 2)
  graphics::text(n, 0.08, sprintf("N = %s", n), pos = 4, col = "#d1495b")
  graphics::text(min(curve$n), target, sprintf("target %s", fmt_pct(target)), adj = c(0, -0.6), col = "grey30", cex = 0.9)
}

# Draft APA-style methods paragraph. Every value comes from the run: the
# spec that run_spec() was given (checked against the hash it recorded) or
# the result it returned.
methods_paragraph <- function(run) {
  spec <- run$spec
  result <- run$result
  prov <- result$provenance
  stopifnot(identical(spec_hash(spec), prov$spec_hash))
  lab <- spec_labels(spec)
  means <- spec_means(spec)
  pop <- spec$population
  just <- spec$effect_justification
  n <- result$n_required$n
  a <- lab$a_levels
  b <- lab$b_levels
  versions <- prov$packages
  strip_stop <- function(x) sub("[.\\s]+$", "", x, perl = TRUE)

  design <- if (spec$template == "2x2_between") {
    "a 2 \u00d7 2 between-participants design"
  } else {
    sprintf("a 2 \u00d7 2 mixed design (%s between participants, %s within participants)", lab$a, lab$b)
  }
  justification <- switch(
    just$type,
    smallest_effect_of_interest = sprintf("These values define the smallest effect of interest (%s).", strip_stop(just$source)),
    meta_analysis = sprintf("The assumed effect is based on a meta-analysis (%s).", strip_stop(just$source)),
    prior_study = sprintf(
      "The assumed effect is based on an earlier study (%s), adjusted as follows: %s.",
      strip_stop(just$source), strip_stop(just$adjustment)
    ),
    pilot_study = sprintf("The assumed effect is based on a pilot study (%s).", strip_stop(just$source))
  )
  cells <- sprintf("%s (%s, %s)", fmt_num(c(t(means))), rep(a, each = 2), rep(b, times = 2))
  method <- if (prov$method == "exact") {
    sprintf("computed exactly with the %s() function", sub("^.*::", "", prov$backend_function))
  } else {
    sprintf("estimated by simulation (%s replications, seed %s) with the %s() function", prov$nrep, prov$seed, sub("^.*::", "", prov$backend_function))
  }

  paste0(
    "We determined the sample size for the ", effect_phrase(spec), " in ", design,
    ", with ", lab$y, " as the outcome. ", justification,
    " We assumed population cell means of ", cells[1], ", ", cells[2], ", ", cells[3], " and ", cells[4],
    ", with a standard deviation of ", fmt_num(pop$sd), " in every cell",
    if (spec$template == "2x2_mixed") sprintf(" and a correlation of r = %s between the two %s measurements", fmt_apa(pop$r), lab$b) else "",
    ". Power for the two-sided F test at \u03b1 = ", fmt_apa(spec$target_test$alpha), " was ", method,
    " of the Superpower R package (version ", versions[["Superpower"]], "; afex version ", versions[["afex"]],
    "), run through powerkit (version ", versions[["powerkit"]], ") in ", sub(" \\(.*$", "", prov$r_version), ". ",
    "A total sample of N = ", n, " (", n / group_count(spec), " per ", group_word(spec), ") is the smallest that gives at least ",
    fmt_pct(spec$goal$power), " power; its power is ", fmt_pct(power_at_required(result)), ". ",
    "(powerkit specification hash ", substr(prov$spec_hash, 1, 12), ", seed ", prov$seed, ".)"
  )
}

# Standalone R script that reproduces the required N with Superpower
# directly (no powerkit), mirroring how the engine calls it.
reproduction_script <- function(run) {
  spec <- run$spec
  result <- run$result
  prov <- result$provenance
  lab <- spec_labels(spec)
  means <- spec_means(spec)
  mixed <- spec$template == "2x2_mixed"
  n <- result$n_required$n
  step <- group_count(spec)
  effect_row <- c(main_effect_A = "a", main_effect_B = "b", interaction = "a:b")[[spec$target_test$effect]]
  num <- function(x) vapply(x, function(v) format(v, digits = 15), character(1))
  quote_r <- function(x) encodeString(x, quote = "\"")

  lines <- c(
    "# Reproduces a powerkit sample-size result using Superpower directly.",
    "# powerkit itself is not needed to run this script.",
    "#",
    sprintf("# Generated by the powerkit prototype app on %s.", format(Sys.Date())),
    sprintf("# powerkit %s; specification hash %s", prov$packages[["powerkit"]], prov$spec_hash),
    sprintf("# powerkit used Superpower %s and afex %s, in %s.", prov$packages[["Superpower"]], prov$packages[["afex"]], prov$r_version),
    "#",
    sprintf("# Design: 2 x 2 %s; outcome: %s", if (mixed) "mixed (a between, b within participants)" else "between participants", lab$y),
    "# Superpower names the factors a and b and their levels a1, a2, b1, b2:",
    sprintf("#   a = %s: a1 = %s, a2 = %s", lab$a, lab$a_levels[1], lab$a_levels[2]),
    sprintf("#   b = %s: b1 = %s, b2 = %s", lab$b, lab$b_levels[1], lab$b_levels[2]),
    sprintf("# Effect tested: %s (row \"%s\" in Superpower's results)", effect_phrase(spec), effect_row),
    "",
    "library(Superpower)",
    "",
    sprintf("mu <- c(%s) # cell means: a1_b1, a1_b2, a2_b1, a2_b2", paste(num(c(t(means))), collapse = ", ")),
    sprintf("cell_sd <- %s", num(spec$population$sd)),
    sprintf("r <- %s # correlation between repeated measures%s", if (mixed) num(spec$population$r) else "0", if (mixed) "" else " (none in a between design)"),
    sprintf("alpha <- %s", num(spec$target_test$alpha)),
    sprintf("target_power <- %s", num(spec$goal$power)),
    sprintf("groups <- %d # Superpower's n is per %s; the total N is split equally", step, if (mixed) "group" else "cell"),
    sprintf("n_total <- %d # powerkit's required total N", n),
    sprintf("powerkit_power <- %s # powerkit's power at that N", num(power_at_required(result))),
    "",
    "# ANOVA_exact() builds its data set with the random-number generator, so",
    "# powerkit runs it under a recorded seed; using the same seed reproduces",
    "# its power bit for bit (other seeds differ around the 15th decimal).",
    sprintf("seed <- %s", prov$seed),
    "",
    "exact_power <- function(n_total) {",
    "  design <- ANOVA_design(",
    sprintf("    design = %s,", quote_r(if (mixed) "2b*2w" else "2b*2b")),
    "    n = n_total / groups,",
    "    mu = mu,",
    "    sd = cell_sd,",
    "    r = r,",
    "    plot = FALSE",
    "  )",
    "  set.seed(seed)",
    "  result <- ANOVA_exact(design, alpha_level = alpha, verbose = FALSE)",
    sprintf("  result$main_results[%s, \"power\"] / 100", quote_r(effect_row)),
    "}",
    "",
    "power_at_n <- exact_power(n_total)",
    "power_below <- exact_power(n_total - groups) # the next smaller valid N",
    "cat(sprintf(\"Power with N = %d: %.4f\\n\", n_total, power_at_n))",
    "cat(sprintf(\"Power with N = %d: %.4f\\n\", n_total - groups, power_below))",
    "",
    "stopifnot(",
    "  power_at_n >= target_power, # N reaches the target power ...",
    "  power_below < target_power, # ... and no smaller valid N does",
    "  abs(power_at_n - powerkit_power) < 1e-8 # and the power matches powerkit's",
    ")",
    "cat(\"Reproduced: N =\", n_total, \"is the smallest total sample size with power of at least\", target_power, \"\\n\")",
    "",
    "sessionInfo()"
  )
  # Plain ASCII, so the script opens cleanly in any editor.
  paste0(gsub("\u00d7", "x", paste(lines, collapse = "\n")), "\n")
}

provenance_table <- function(run) {
  prov <- run$result$provenance
  data.frame(
    Item = c(
      "Required total N", "Method", "Backend function", "Seed", "Specification hash",
      "Check run", "R", "Package versions", "Run started", "Run time"
    ),
    Value = c(
      run$result$n_required$n,
      prov$method,
      prov$backend_function,
      prov$seed,
      prov$spec_hash,
      if (all(run$result$check_run$ok)) "passed" else "FAILED",
      prov$r_version,
      paste(sprintf("%s %s", names(prov$packages), prov$packages), collapse = ", "),
      prov$started,
      sprintf("%.1f s", prov$run_time_seconds)
    )
  )
}
