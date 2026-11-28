# Other programs in what researchers read and copy (28 November 2026,
# docs/decisions.md): another program is named only where it helps a
# researcher find a number in their own output ("SPSS calls them Exp(B)") or
# match a setting in the software they will analyse with (JASP's priors,
# PROCESS model numbers). Other power-analysis programs are never named in
# what researchers read: methods are stated by name, never "as in" another
# program. The cards keep them only in their validation records and a
# formula's published source, and the packages Powerkit runs are cited as
# attribution.

run <- engine_function("run_spec", file.path(repo_dir, "engine"))
skip_without_run <- function() {
  if (is.null(run) && identical(Sys.getenv("POWERKIT_APP_TESTS_NEED_ENGINE"), "true")) {
    fail("powerkit's engine couldn't be loaded, but this run needs it (POWERKIT_APP_TESTS_NEED_ENGINE).")
  }
  skip_if(is.null(run), "powerkit's engine isn't available here")
}

other_software <- "G\\*Power|GPower|\\bJASP\\b|\\bSPSS\\b|jamovi|\\bPROCESS\\b|Mplus|\\bStata\\b|MorePower|PANGEA|WebPower|PAMLj"
# Programs for planning power, which no screen, result or write-up needs to
# name: none is software a researcher analyses with.
power_programs <- "G\\*Power|GPower|MorePower|PANGEA|PAMLj|BFDA|\\bPASS\\b|nQuery"

test_that("the departures and known differences name no power-analysis program", {
  departures <- unlist(forms$departures)
  expect_equal(names(departures)[grepl(power_programs, departures)], character(), label = "departures naming one")
  known <- unlist(forms$known_differences)
  expect_equal(names(known)[grepl(power_programs, known)], character(), label = "known differences naming one")
})

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

test_that("input screens name no power-analysis program, and say nothing is 'as in' another", {
  for (ep in names(forms$forms)) {
    fields <- form_fields(form_groups(forms, ep))
    for (f in fields) {
      shown <- c(f$label, unlist(f$choices), f$writeup_label, f$help, f$default_source, unlist(f$choice_notes))
      expect_false(any(grepl(power_programs, shown)), label = paste(ep, f$id))
      expect_false(any(grepl(paste0("as in (", other_software, ")"), shown)), label = paste(ep, f$id, "'as in' another program"))
    }
  }
})

test_that("cards name a power-analysis program only in validation records and a formula's source", {
  hits <- list()
  walk <- function(x, path) {
    if (is.character(x)) {
      if (any(grepl(power_programs, x))) hits <<- c(hits, list(path))
    } else if (is.list(x)) {
      for (n in seq_along(x)) walk(x[[n]], c(path, if (!is.null(names(x)) && nzchar(names(x)[n])) names(x)[n] else "*"))
    }
  }
  for (id in names(tree$endpoints)) walk(tree$endpoints[[id]], id)
  where <- vapply(hits, function(h) h[2], "")
  # BFDA is listed with the R packages for designs not yet built.
  expect_true(all(where %in% c("validation", "backend", "packages")), label = paste(unique(where), collapse = ", "))
})

test_that("the R script a researcher runs says nothing is 'as' another program", {
  scripts <- file.path(repo_dir, "engine", "R", c("export-script.R", "export-script-pwrss.R"))
  for (path in scripts) {
    lines <- readLines(path)
    # The script's own lines are the strings in this code, not its comments.
    code <- lines[!grepl("^\\s*#", lines)]
    expect_false(any(grepl("as (in )?G\\*Power|G\\*Power's (values|fixed|approach)|as G\\*Power", code)), label = basename(path))
  }
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
