# Other programs in what researchers read and copy (28 November 2026,
# docs/decisions.md): write-ups state each method by name, never "as in"
# another program; input screens name another program only where its answer
# differs (the fields listed below), and the cards only in their validation
# records and a formula's published source.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
skip_without_run <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

other_software <- "G\\*Power|GPower|\\bJASP\\b|\\bSPSS\\b|jamovi|\\bPROCESS\\b|Mplus|\\bStata\\b|MorePower|PANGEA|WebPower|PAMLj"

test_that("the write-up's departures and known differences name no other program", {
  departures <- unlist(forms$departures)
  in_writeup <- departures_methods_for(forms, stats::setNames(as.character(departures), names(departures)))
  named <- names(in_writeup)[grepl(other_software, in_writeup)]
  expect_equal(named, character(), label = "departures whose methods wording names another program (add a departures_methods entry)")
  known <- unlist(forms$known_differences_methods)
  expect_equal(names(known)[grepl(other_software, known)], character(), label = "known_differences_methods naming another program")
  # Every methods wording is for a departure that exists.
  expect_true(all(names(forms$departures_methods) %in% names(forms$departures)))
})

test_that("the write-up's own headings and sentences name no other program", {
  code <- paste(readLines(file.path(routing_dir, "R", "results.R")), collapse = "\n")
  body <- paste(deparse(writeup_text), collapse = "\n")
  expect_false(grepl(other_software, body), label = "writeup_text()")
  expect_no_match(code, "Departures from the established tools", fixed = TRUE)
})

test_that("input screens name G*Power only where its answer differs", {
  allowed <- list(E2 = "method", E18 = "test_version", E23 = "covariate_model", E24 = "predictor_model", E53 = "method")
  for (ep in names(forms$forms)) {
    fields <- form_fields(form_groups(forms, ep))
    for (f in fields) {
      shown <- c(f$label, unlist(f$choices), f$writeup_label)
      expect_false(any(grepl("G\\*Power", shown)), label = paste(ep, f$id, "label or choices"))
      explained <- c(f$help, f$default_source, unlist(f$choice_notes))
      if (any(grepl("G\\*Power", explained))) expect_true(f$id %in% allowed[[ep]], label = paste(ep, f$id, "help names G*Power"))
    }
  }
})

test_that("cards name G*Power only in validation records and a formula's source", {
  hits <- list()
  walk <- function(x, path) {
    if (is.character(x)) {
      if (any(grepl("G\\*Power", x))) hits <<- c(hits, list(path))
    } else if (is.list(x)) {
      for (n in seq_along(x)) walk(x[[n]], c(path, if (!is.null(names(x)) && nzchar(names(x)[n])) names(x)[n] else "*"))
    }
  }
  for (id in names(tree$endpoints)) walk(tree$endpoints[[id]], id)
  where <- vapply(hits, function(h) h[2], "")
  expect_true(all(where %in% c("validation", "backend", "card_points")), label = paste(unique(where), collapse = ", "))
  # A card point may name it only as a check still to come.
  points <- unlist(lapply(tree$endpoints, function(e) unlist(e$card_points)))
  points <- points[!is.na(points)]
  expect_true(all(grepl("checks against G\\*Power", points[grepl("G\\*Power", points)])))
})

test_that("a calculated write-up names no other program", {
  skip_without_run()
  for (case in list(
    list(ep = "E18", values = list(metric = "eta_squared", eta_squared = "0.06", test_version = "anova_f", goal = "sample_size", power = "0.8")),
    list(ep = "E23", values = list(goal = "sample_size", power = "0.8", covariate_model = "random")))) {
    fields <- form_fields(form_groups(forms, case$ep))
    values <- modifyList(form_examples[[case$ep]], case$values)
    spec <- build_spec(forms, case$ep, fields, values)
    calc <- run_calculation(spec, run, seed = forms$default_seed)
    expect_identical(calc$status, "ok", label = case$ep)
    known <- vapply(known_difference_keys(forms, case$ep, spec), function(k) forms$known_differences_methods[[k]], character(1))
    text <- writeup_text(forms$forms[[case$ep]], spec, calc$result, fields, values,
      departures_methods_for(forms, departures_for(forms, case$ep, spec)), known, known_differences_for(forms, case$ep, spec))
    expect_false(any(grepl(other_software, text)), label = paste(case$ep, "write-up"))
  }
})
