# "Which assumption matters most?": each uncertain input at a low and a
# high value, one at a time, worked out by the engine.

assumption_setup <- function(ep = "E2") {
  fields <- form_fields(form_groups(forms, ep, 2))
  values <- form_examples[[ep]]
  spec <- build_spec(forms, ep, fields, values)
  calc <- run_calculation(spec, engine_function("run_spec"), 1L)
  list(fields = fields, values = values, calc = calc, candidates = assumption_candidates(forms, fields, values))
}

test_that("the effect and listed assumptions are offered, design choices are not", {
  x <- assumption_setup("E2")
  ids <- vapply(x$candidates, `[[`, "", "id")
  expect_true(all(c("d", "welch_sd_ratio") %in% ids))
  expect_false(any(c("alpha", "power", "allocation_ratio") %in% ids))
  # Every listed id is a number field on some input screen.
  all_numbers <- unique(unlist(lapply(names(forms$forms), function(ep)
    vapply(Filter(function(f) identical(f$type, "number"), form_fields(form_groups(forms, ep, 2))), `[[`, "", "id"))))
  expect_true(all(unlist(forms$assumption_fields) %in% all_numbers),
    info = paste(setdiff(unlist(forms$assumption_fields), all_numbers), collapse = ", "))
})

test_that("each assumption is varied on its own and sorted by how much it moves the answer", {
  x <- assumption_setup("E2")
  expect_identical(x$calc$status, "ok")
  expect_true(assumptions_available(x$calc$spec, x$calc$result, x$candidates))
  tab <- run_assumption_ranges(forms, "E2", x$fields, x$values, list(welch_sd_ratio = c(1, 1.5), d = c(0.3, 0.5)))
  expect_identical(tab$id[1], "d")
  # A smaller effect needs more people, a larger one fewer, around the plan.
  planned <- assumption_answer(x$calc$result)
  expect_gt(tab$at_low[1], planned)
  expect_lt(tab$at_high[1], planned)
  # Same as running the changed screen directly.
  v <- x$values; v$d <- "0.3"
  direct <- run_calculation(build_spec(forms, "E2", x$fields, v), engine_function("run_spec"), 1L)
  expect_equal(tab$at_low[1], assumption_answer(direct$result))
})

test_that("a value the input screen refuses is reported, not run", {
  x <- assumption_setup("E2")
  tab <- run_assumption_ranges(forms, "E2", x$fields, x$values, list(d = c(NA, 0.5), welch_sd_ratio = c(-1, NA)))
  bad <- tab[tab$id == "welch_sd_ratio", ]
  expect_true(is.na(bad$at_low))
  expect_true(nzchar(bad$problem))
  ok <- tab[tab$id == "d", ]
  expect_true(is.na(ok$at_low))
  expect_false(is.na(ok$at_high))
})

test_that("the panel suggests no values, and only formula results show it", {
  x <- assumption_setup("E2")
  html <- as.character(assumptions_ui(x$calc$spec, x$calc$result, x$candidates))
  expect_match(html, "Which assumption matters most?", fixed = TRUE)
  expect_match(html, "won't suggest the values", fixed = TRUE)
  expect_false(grepl('value="0', html, fixed = TRUE))
  sens <- x$calc$result; sens$goal_type <- "sensitivity"
  spec <- x$calc$spec; spec$goal$type <- "sensitivity"
  expect_null(assumptions_ui(spec, sens, x$candidates))
  expect_null(assumptions_ui(x$calc$spec, x$calc$result, list()))
})

test_that("the chart and table draw for the compared values", {
  x <- assumption_setup("E2")
  tab <- run_assumption_ranges(forms, "E2", x$fields, x$values, list(d = c(0.3, 0.5)))
  path <- tempfile(fileext = ".png")
  grDevices::png(path)
  expect_no_error(assumptions_plot(tab, x$calc$result, x$calc$spec))
  grDevices::dev.off()
  html <- as.character(assumptions_result_ui(tab, x$calc$result, x$calc$spec))
  expect_match(html, "Cohen", fixed = TRUE)
  expect_match(html, "don't add up", fixed = TRUE)
  expect_match(as.character(assumptions_result_ui(tab[0, ], x$calc$result, x$calc$spec)), "at least one assumption")
})

test_that("the two-way grid changes the effect and one assumption together", {
  x <- assumption_setup("E2")
  ranges <- list(d = c(0.3, 0.5), welch_sd_ratio = c(1, 2))
  grid <- run_assumption_grid(forms, "E2", x$fields, x$values, "d", "welch_sd_ratio", ranges, steps = 3L)
  expect_equal(nrow(grid$cells), 9)
  expect_false(anyNA(grid$cells$answer))
  # A smaller effect needs more people at every value of the other.
  small <- grid$cells[grid$cells$effect == 0.3, "answer"]
  large <- grid$cells[grid$cells$effect == 0.5, "answer"]
  expect_true(all(small > large))
  expect_null(run_assumption_grid(forms, "E2", x$fields, x$values, "d", "welch_sd_ratio", list(d = c(0.3, NA))))
  path <- tempfile(fileext = ".png")
  grDevices::png(path)
  expect_no_error(assumptions_grid_plot(grid, x$calc$result, x$calc$spec))
  grDevices::dev.off()
  expect_match(as.character(assumptions_grid_ui(grid, x$calc$result, x$calc$spec)), "changed together", fixed = TRUE)
  expect_match(as.character(assumptions_grid_ui(NULL, x$calc$result, x$calc$spec)), "lowest and a highest")
  expect_match(as.character(assumptions_ui(x$calc$spec, x$calc$result, x$candidates)), "No two-way grid", fixed = TRUE)
})
