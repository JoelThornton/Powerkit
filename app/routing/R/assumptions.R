# "How much does the answer depend on my assumptions?" (one at a time).
#
# A required N, or power at a fixed N, rests on several uncertain numbers:
# the effect, and others such as a correlation between measurements, an SD,
# a reliability or the attrition. The researcher gives a low and a high
# plausible value for any of them; each is changed on its own, the rest
# kept as planned, and the engine works out the answer at each value. The
# rows are drawn as a tornado chart, the input the answer depends on most
# at the top. Powerkit suggests no values: they come from the researcher's
# evidence, as for the effect scenarios. Only designs the engine answers
# by formula take part, so the comparison is instant; the app builds specs
# and calls the engine, never computing power itself.

# The inputs that can be varied: a single number on the input screen that
# is shown for these answers, and is either an effect (effect: true) or
# listed in forms.yaml's assumption_fields.
assumption_candidates <- function(forms, fields, values) {
  listed <- unlist(forms$assumption_fields)
  Filter(function(f) {
    identical(f$type, "number") && !is.null(f$path) && (isTRUE(f$effect) || f$id %in% listed) &&
      field_applies(f, values)
  }, fields)
}

# Shown for a result whose goal is a sample size or power, worked out by
# formula, with at least one input to vary.
assumptions_available <- function(spec, result, candidates) {
  simulates <- engine_function("runs_simulation")
  length(candidates) > 0 && isTRUE(spec$goal$type %in% c("power", "sample_size")) &&
    !is.null(simulates) && !isTRUE(suppressWarnings(simulates(spec)))
}

assumption_label <- function(f) f$writeup_label %||% f$label

assumption_answer <- function(result) {
  if (identical(result$goal_type, "sample_size")) result$n_required$n else result$curve$power[1]
}

# One row a side: the answer with that input at each of its two values.
# `ranges` is a named list (field id) of c(low, high), either of which may
# be NA. Each changed set of answers is checked as the input screen checks
# it, and an answer that can't be worked out is NA with the reason.
run_assumption_ranges <- function(forms, ep_id, fields, values, ranges, run = engine_function("run_spec"), seed = 1L) {
  simulates <- engine_function("runs_simulation")
  by_id <- stats::setNames(fields, vapply(fields, `[[`, "", "id"))
  rows <- lapply(names(ranges), function(id) {
    f <- by_id[[id]]
    one <- function(x) {
      if (is.na(x)) return(list(value = NA_real_, problem = NA_character_))
      v <- values
      v[[id]] <- format(x, scientific = FALSE, trim = TRUE)
      problems <- form_problems(fields, v)
      if (length(problems)) return(list(value = NA_real_, problem = unname(problems[[1]])))
      spec <- build_spec(forms, ep_id, fields, v)
      if (!is.null(simulates) && isTRUE(suppressWarnings(simulates(spec)))) {
        return(list(value = NA_real_, problem = "This value needs a simulation, which this comparison doesn't run."))
      }
      calc <- run_calculation(spec, run, seed)
      if (!identical(calc$status, "ok")) return(list(value = NA_real_, problem = calc$message))
      list(value = assumption_answer(calc$result), problem = NA_character_)
    }
    low <- one(ranges[[id]][1])
    high <- one(ranges[[id]][2])
    # The answer needn't be monotone over the range: a difference from -0.5
    # to +0.5 has the same power at both ends and 5% at zero. So the values
    # inside the range are worked out too (an odd number, so the midpoint is
    # one, and zero for an effect whose range crosses it), and an answer
    # inside that goes beyond both ends is reported.
    inside_x <- assumption_inside_values(ranges[[id]], isTRUE(f$effect))
    inside <- vapply(inside_x, function(x) one(x)$value, numeric(1))
    ends <- c(low$value, high$value)
    beyond <- assumption_beyond(ends, inside_x, inside)
    data.frame(id = id, label = assumption_label(f), planned = values[[id]] %||% "",
      low = ranges[[id]][1], high = ranges[[id]][2], at_low = low$value, at_high = high$value,
      inside_low = beyond$low, inside_low_at = beyond$low_at, inside_high = beyond$high, inside_high_at = beyond$high_at,
      inside_missing = if (length(inside) && all(!is.na(ends))) sum(is.na(inside)) else 0L,
      spread = if (all(is.na(c(ends, inside)))) -1 else diff(range(c(ends, inside), na.rm = TRUE)),
      problem = paste(stats::na.omit(c(low$problem, high$problem)), collapse = " "), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  # The input the answer depends on most first, over its whole range.
  out[order(-out$spread), , drop = FALSE]
}

# Values strictly inside a range: seven evenly spaced (with the ends, nine,
# so the midpoint is one), and zero for an effect when the range crosses it.
assumption_inside_values <- function(r, effect = FALSE) {
  if (any(is.na(r)) || r[1] == r[2]) return(numeric(0))
  x <- seq(r[1], r[2], length.out = 9)[2:8]
  if (effect && min(r) < 0 && max(r) > 0) x <- sort(unique(c(x, 0)))
  signif(x, 6)
}

# The lowest and highest answers inside the range, where they go beyond
# both ends' answers (NA otherwise), with the value of the input there.
assumption_beyond <- function(ends, inside_x, inside) {
  none <- list(low = NA_real_, low_at = NA_real_, high = NA_real_, high_at = NA_real_)
  ok <- !is.na(inside)
  if (!any(ok) || all(is.na(ends))) return(none)
  tol <- 1e-6 * max(1, abs(c(ends, inside)), na.rm = TRUE)
  out <- none
  i <- which(ok)[which.min(inside[ok])]
  if (inside[i] < min(ends, na.rm = TRUE) - tol) { out$low <- inside[i]; out$low_at <- inside_x[i] }
  j <- which(ok)[which.max(inside[ok])]
  if (inside[j] > max(ends, na.rm = TRUE) + tol) { out$high <- inside[j]; out$high_at <- inside_x[j] }
  out
}

# What the row says about the values inside its range, or NULL when the
# answer stays between the two ends' answers.
assumption_inside_text <- function(row, goal) {
  parts <- c(
    if (!is.na(row$inside_low)) sprintf("%s at %s", assumption_answer_text(row$inside_low, goal), format(row$inside_low_at)),
    if (!is.na(row$inside_high)) sprintf("%s at %s", assumption_answer_text(row$inside_high, goal), format(row$inside_high_at)))
  missing <- if (isTRUE(row$inside_missing > 0)) "not worked out at some values" else NULL
  if (!length(c(parts, missing))) return(NULL)
  paste(c(parts, missing), collapse = "; ")
}

# The ranges typed on the result screen: both blank leaves an input out;
# one value compares that side only.
assumption_ranges_from_input <- function(input, candidates) {
  ranges <- lapply(candidates, function(f) {
    read <- function(side) {
      x <- input[[sprintf("assume_%s_%s", side, f$id)]]
      if (is.null(x) || is.na(x)) NA_real_ else as.numeric(x)
    }
    c(read("low"), read("high"))
  })
  names(ranges) <- vapply(candidates, `[[`, "", "id")
  Filter(function(r) any(!is.na(r)), ranges)
}

assumptions_ui <- function(spec, result, candidates) {
  if (!assumptions_available(spec, result, candidates)) return(NULL)
  answer <- if (identical(result$goal_type, "sample_size")) "the sample size you need" else "power at your sample size"
  others <- Filter(function(f) !isTRUE(f$effect), candidates)
  effect <- Filter(function(f) isTRUE(f$effect), candidates)
  div(class = "assumption-panel",
    h5(class = "h6", "Which assumption matters most?"),
    p(class = "small", sprintf(paste(
      "Enter the lowest and highest value your evidence supports for each number you're unsure of. Powerkit changes one at a time",
      "and shows %s at each end (or inside the range, where that goes further), the one that moves it most first.",
      "It doesn't suggest values."), answer)),
    div(class = "assumption-inputs", style = "max-width:100%; overflow-x:auto", tabindex = "0", role = "region",
      `aria-label` = "Plausible values for each assumption",
      tags$table(class = "table table-sm",
        tags$thead(tags$tr(tags$th(scope = "col", "Assumption (as planned)"),
          tags$th(scope = "col", "Lowest plausible"), tags$th(scope = "col", "Highest plausible"))),
        # The planned value sits under the name rather than in a column of
        # its own, so the table fits a 320px screen.
        tags$tbody(lapply(candidates, function(f) tags$tr(
          tags$th(scope = "row", class = "fw-normal", assumption_label(f),
            tags$br(), span(class = "small", sprintf("planned %s", format_planned_value(spec, f)))),
          tags$td(numericInput(sprintf("assume_low_%s", f$id), span(class = "visually-hidden", sprintf("Lowest plausible %s", assumption_label(f))), value = NA, width = "100%")),
          tags$td(numericInput(sprintf("assume_high_%s", f$id), span(class = "visually-hidden", sprintf("Highest plausible %s", assumption_label(f))), value = NA, width = "100%"))))))),
    if (length(effect) && length(others)) div(class = "assumption-grid-choice",
      selectInput("assumptions_grid", "Also show the effect against one assumption",
        choices = c("No two-way grid" = "", stats::setNames(vapply(others, `[[`, "", "id"), vapply(others, assumption_label, ""))),
        width = "100%"),
      p(class = "small text-muted", "Both assumptions need a lowest and a highest value.")),
    actionButton("assumptions_run", "Compare these assumptions", class = "btn btn-outline-primary"),
    uiOutput("assumptions_result"))
}

# The planned value as the input screen holds it, read from the spec's
# field path (what was calculated).
format_planned_value <- function(spec, f) {
  x <- tryCatch(Reduce(function(acc, k) if (is.list(acc)) acc[[k]] else NULL, split_path(f$path), spec), error = function(e) NULL)
  if (is.null(x) || !is.numeric(x) || length(x) != 1) return("as entered")
  format(signif(x, 4), scientific = FALSE, trim = TRUE)
}

assumption_answer_text <- function(x, goal_type) {
  if (is.na(x)) return("not worked out")
  if (identical(goal_type, "sample_size")) whole(x) else sprintf("%.0f%%", 100 * x)
}

assumptions_result_ui <- function(table, result, spec) {
  if (!nrow(table)) return(p(role = "alert", "Enter a lowest or highest plausible value for at least one assumption."))
  goal <- result$goal_type
  unit <- sample_description(spec)$unit
  heading <- if (identical(goal, "sample_size")) sprintf("Sample size needed (%s)", unit) else sprintf("Power at N = %s %s", whole(spec$goal$n), unit)
  tagList(
    plotOutput("assumptions_plot", height = sprintf("%dpx", 120 + 46 * nrow(table))),
    div(style = "max-width:100%; overflow-x:auto", tabindex = "0", role = "region", `aria-label` = "Answer at each assumption's lowest and highest value",
      tags$table(class = "table table-sm",
        tags$caption(sprintf("%s with each assumption at its lowest and highest plausible value, the others as planned (planned answer: %s)",
          heading, assumption_answer_text(assumption_answer(result), goal))),
        tags$thead(tags$tr(tags$th(scope = "col", "Assumption"), tags$th(scope = "col", "Lowest"), tags$th(scope = "col", "Answer"),
          tags$th(scope = "col", "Highest"), tags$th(scope = "col", "Answer"), tags$th(scope = "col", "Inside the range"))),
        tags$tbody(lapply(seq_len(nrow(table)), function(i) tags$tr(
          tags$td(table$label[i]),
          tags$td(if (is.na(table$low[i])) "-" else format(table$low[i])), tags$td(assumption_answer_text(table$at_low[i], goal)),
          tags$td(if (is.na(table$high[i])) "-" else format(table$high[i])), tags$td(assumption_answer_text(table$at_high[i], goal)),
          tags$td(assumption_inside_text(table[i, ], goal) %||% (if (is.na(table$low[i]) || is.na(table$high[i])) "-" else "between the two"))))))),
    if (any(nzchar(table$problem))) tags$ul(class = "small", lapply(which(nzchar(table$problem)), function(i)
      tags$li(sprintf("%s: %s", table$label[i], table$problem[i])))),
    p(class = "small", "Each row changes one assumption with the others as planned; the answers don't add up when several are wrong together. Powerkit also works out seven values evenly spaced inside each range (and zero for an effect whose range crosses it); a value between those can go a little further. This comparison doesn't change your plan or what you save."))
}

# The tornado chart: a bar per assumption from the answer at its lowest
# value to the answer at its highest, around the planned answer.
assumptions_plot <- function(table, result, spec) {
  goal <- result$goal_type
  planned <- assumption_answer(result)
  d <- table[!(is.na(table$at_low) & is.na(table$at_high)), , drop = FALSE]
  if (!nrow(d)) {
    graphics::plot.new()
    graphics::text(0.5, 0.5, "No answer could be worked out for these values.", col = chart_colours$ink)
    return(invisible())
  }
  lo <- ifelse(is.na(d$at_low), planned, d$at_low)
  hi <- ifelse(is.na(d$at_high), planned, d$at_high)
  k <- nrow(d)
  y <- rev(seq_len(k))
  op <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(op))
  # Room for the labels on the left, in lines (about two characters a line).
  width <- max(nchar(d$label)) * 0.5
  chart_start(key_rows = 1, left = min(max(4.6, width + 1.2), 18))
  xr <- range(c(lo, hi, planned, d$inside_low, d$inside_high), na.rm = TRUE)
  xr <- xr + c(-1, 1) * max(diff(xr) * 0.08, if (identical(goal, "sample_size")) 1 else 0.01)
  if (!identical(goal, "sample_size")) xr <- c(max(0, xr[1]), min(1, xr[2]))
  plot(NA, xlim = xr, ylim = c(0.4, k + 0.6), axes = FALSE, ylab = "",
    xlab = if (identical(goal, "sample_size")) sprintf("Sample size needed (%s)", sample_description(spec)$unit) else "Power at your sample size")
  at <- graphics::axTicks(1)
  graphics::abline(v = at, col = chart_colours$grid)
  graphics::axis(1, at = at, labels = if (identical(goal, "sample_size")) whole(at) else paste0(round(100 * at), "%"),
    col = chart_colours$grid, col.ticks = chart_colours$grid, tcl = -0.3)
  graphics::axis(2, at = y, labels = d$label, col = NA, col.ticks = NA, cex.axis = 0.95)
  # Each side drawn from the planned answer to the answer at that value,
  # whichever way it goes (a higher correlation can need fewer people):
  # the lowest value in the top half of the row, the highest below.
  graphics::rect(pmin(lo, planned), y, pmax(lo, planned), y + 0.34, col = grDevices::adjustcolor(chart_colours$amber, 0.75), border = NA)
  graphics::rect(pmin(hi, planned), y - 0.34, pmax(hi, planned), y, col = grDevices::adjustcolor(chart_colours$blue, 0.75), border = NA)
  # An answer inside the range that goes beyond both ends: a line out to it
  # with its value, so a range that crosses no effect doesn't look flat.
  for (i in seq_len(k)) for (side in c("low", "high")) {
    v <- d[[paste0("inside_", side)]][i]
    if (is.na(v)) next
    from <- if (side == "low") min(lo[i], hi[i], planned) else max(lo[i], hi[i], planned)
    graphics::segments(from, y[i], v, y[i], col = chart_colours$ink, lwd = 2, lty = 2)
    graphics::points(v, y[i], pch = 19, col = chart_colours$ink)
    graphics::text(v, y[i], sprintf("%s inside the range", assumption_answer_text(v, goal)),
      pos = 1, offset = 0.6, cex = 0.8, col = chart_colours$ink, xpd = NA)
  }
  graphics::abline(v = planned, col = chart_colours$navy, lwd = 2)
  flat_inside <- is.na(d$inside_low) & is.na(d$inside_high)
  same <- abs(lo - planned) < 1e-9 & abs(hi - planned) < 1e-9
  if (any(same & flat_inside)) graphics::text(planned, y[same & flat_inside], "  no change", pos = 4, cex = 0.85, col = chart_colours$ink)
  ends_same <- abs(lo - hi) < 1e-9 & !flat_inside
  if (any(ends_same)) graphics::text(planned, y[ends_same] + 0.3, "same at both ends", pos = 4, cex = 0.8, col = chart_colours$ink)
  graphics::mtext(sprintf("Planned: %s", assumption_answer_text(planned, goal)), side = 3, line = 0.1, at = planned, cex = 0.85, col = chart_colours$navy)
  chart_key(legend = c("At the lowest plausible value", "At the highest plausible value"),
    fill = grDevices::adjustcolor(c(chart_colours$amber, chart_colours$blue), 0.75), border = NA)
  invisible()
}

# The two-way grid: the effect and one other assumption, each at five
# values from its lowest to its highest plausible value, the rest as
# planned. Both change together here, so the grid shows what the one-at-a-
# time rows can't: how much a weaker effect and a worse value of the other
# assumption cost when they come together.
run_assumption_grid <- function(forms, ep_id, fields, values, effect_id, other_id, ranges, steps = 5L,
                                run = engine_function("run_spec"), seed = 1L) {
  simulates <- engine_function("runs_simulation")
  grid_values <- function(id) {
    r <- ranges[[id]]
    if (is.null(r) || any(is.na(r)) || r[1] == r[2]) return(NULL)
    signif(seq(min(r), max(r), length.out = steps), 4)
  }
  ex <- grid_values(effect_id)
  ox <- grid_values(other_id)
  if (is.null(ex) || is.null(ox)) return(NULL)
  cells <- expand.grid(effect = ex, other = ox)
  cells$answer <- NA_real_
  cells$problem <- NA_character_
  for (i in seq_len(nrow(cells))) {
    v <- values
    v[[effect_id]] <- format(cells$effect[i], scientific = FALSE, trim = TRUE)
    v[[other_id]] <- format(cells$other[i], scientific = FALSE, trim = TRUE)
    problems <- form_problems(fields, v)
    if (length(problems)) { cells$problem[i] <- unname(problems[[1]]); next }
    spec <- build_spec(forms, ep_id, fields, v)
    if (!is.null(simulates) && isTRUE(suppressWarnings(simulates(spec)))) {
      cells$problem[i] <- "This value needs a simulation, which this comparison doesn't run."
      next
    }
    calc <- run_calculation(spec, run, seed)
    if (identical(calc$status, "ok")) cells$answer[i] <- assumption_answer(calc$result) else cells$problem[i] <- calc$message
  }
  by_id <- stats::setNames(fields, vapply(fields, `[[`, "", "id"))
  list(cells = cells, effect_label = assumption_label(by_id[[effect_id]]), other_label = assumption_label(by_id[[other_id]]))
}

# The grid as a heatmap with each cell's answer written in it: darker is a
# larger sample size (or lower power), so the costly corner stands out.
assumptions_grid_plot <- function(grid, result, spec) {
  goal <- result$goal_type
  cells <- grid$cells
  ex <- sort(unique(cells$effect))
  ox <- sort(unique(cells$other))
  m <- matrix(NA_real_, length(ex), length(ox))
  m[cbind(match(cells$effect, ex), match(cells$other, ox))] <- cells$answer
  op <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(op))
  ylab <- paste(strwrap(grid$other_label, 24), collapse = "\n")
  lines <- length(strsplit(ylab, "\n")[[1]])
  chart_start(left = 4.2 + 1.1 * lines)
  # Worse answers darker: more people needed, or less power.
  score <- if (identical(goal, "sample_size")) m else -m
  ramp <- grDevices::colorRampPalette(c("#eef3f9", chart_colours$blue, chart_colours$navy))(64)
  rng <- range(score, na.rm = TRUE)
  idx <- if (diff(rng) > 0) 1 + round(63 * (score - rng[1]) / diff(rng)) else matrix(20, nrow(m), ncol(m))
  plot(NA, xlim = c(0.5, length(ex) + 0.5), ylim = c(0.5, length(ox) + 0.5), axes = FALSE,
    xlab = grid$effect_label, ylab = "")
  graphics::mtext(ylab, side = 2, line = 3, las = 0, col = chart_colours$ink, cex = 1.05)
  for (i in seq_along(ex)) for (j in seq_along(ox)) {
    fill <- if (is.na(m[i, j])) "#ffffff" else ramp[idx[i, j]]
    graphics::rect(i - 0.5, j - 0.5, i + 0.5, j + 0.5, col = fill, border = "#ffffff", lwd = 2)
    dark <- !is.na(m[i, j]) && idx[i, j] > 32
    graphics::text(i, j, assumption_answer_text(m[i, j], goal), col = if (dark) "#ffffff" else chart_colours$navy, cex = 0.9)
  }
  graphics::axis(1, at = seq_along(ex), labels = format(ex), col = NA, col.ticks = NA)
  graphics::axis(2, at = seq_along(ox), labels = format(ox), col = NA, col.ticks = NA)
  invisible()
}

assumptions_grid_ui <- function(grid, result, spec) {
  if (is.null(grid)) {
    return(p(class = "small", role = "alert",
      "For the two-way grid, give the effect and the chosen assumption both a lowest and a highest plausible value, different from each other."))
  }
  goal <- result$goal_type
  cells <- grid$cells
  ex <- sort(unique(cells$effect))
  ox <- sort(unique(cells$other))
  what <- if (identical(goal, "sample_size")) "Sample size needed" else "Power"
  tagList(
    h6(class = "mt-3", sprintf("%s for %s and %s together", what, grid$effect_label, grid$other_label)),
    plotOutput("assumptions_grid_plot", height = "340px"),
    div(style = "max-width:100%; overflow-x:auto", tabindex = "0", role = "region", `aria-label` = "Two-way grid of answers",
      tags$table(class = "table table-sm",
        tags$caption(sprintf("%s with %s (columns) and %s (rows) changed together, the others as planned",
          what, grid$effect_label, grid$other_label)),
        tags$thead(tags$tr(tags$th(scope = "col", grid$other_label), lapply(ex, function(e) tags$th(scope = "col", format(e))))),
        tags$tbody(lapply(rev(ox), function(o) tags$tr(tags$th(scope = "row", format(o)),
          lapply(ex, function(e) tags$td(assumption_answer_text(cells$answer[cells$effect == e & cells$other == o], goal)))))))),
    if (any(!is.na(cells$problem))) p(class = "small", sprintf("Cells left blank couldn't be worked out: %s",
      unique(stats::na.omit(cells$problem))[1])))
}
