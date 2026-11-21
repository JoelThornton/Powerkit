test_that("the current capability table includes every card and declared test choice", {
  rows <- capability_rows(tree, forms)
  expect_setequal(unique(rows$endpoint), names(tree$endpoints))
  e2 <- rows[rows$endpoint == "E2", ]
  expect_true(any(grepl("Welch", e2$choice)))
  expect_true(any(grepl("Mann-Whitney", e2$choice)))
  expect_true(all(nzchar(rows$access)))
  expect_match(paste(e2$restrictions, collapse = " "), "sqrt((SD1 squared + SD2 squared) / 2)", fixed = TRUE)
  # Adding a form choice updates discovery without editing a second list.
  changed <- forms
  for (i in seq_along(changed$forms$E2$groups)) {
    for (j in seq_along(changed$forms$E2$groups[[i]]$fields)) {
      if (identical(changed$forms$E2$groups[[i]]$fields[[j]]$id, "method"))
        changed$forms$E2$groups[[i]]$fields[[j]]$choices$student_t <- "Renamed declared Student choice"
    }
  }
  expect_true(any(grepl("Renamed declared Student choice", capability_rows(tree, changed)$choice)))
  html <- as.character(capabilities_ui(tree, forms))
  expect_match(html, 'type="search"', fixed = TRUE)
  expect_match(html, 'scope="col"', fixed = TRUE)
  expect_match(html, "not a claim that every combination works", fixed = TRUE)
})

test_that("the capability table has one row per analysis, names its tests, ranks a search by name and downloads in full", {
  rows <- capability_rows(tree, forms)
  summary <- capability_summary(tree, forms, rows)
  expect_setequal(summary$endpoint, names(tree$endpoints))
  expect_match(summary$tests[summary$endpoint == "E2"], "Welch's t-test; Student's t-test", fixed = TRUE)
  html <- as.character(capabilities_ui(tree, forms))
  expect_match(html, "Download the full table (spreadsheet, CSV)", fixed = TRUE)
  expect_lt(regexpr("download_capabilities", html, fixed = TRUE), regexpr("capabilities-fold", html, fixed = TRUE))
  expect_match(html, "data-name=", fixed = TRUE)
  # Searching "anova" puts analyses named ANOVA before others that only
  # mention it (Student's t-test's limits do): name matches score 3.
  expect_match(capability_search_js, "has(name)?3", fixed = TRUE)
  e2 <- which(summary$endpoint == "E2")
  expect_false(grepl("anova", tolower(paste(summary$analysis[e2], summary$called[e2]))))
  expect_true(any(grepl("anova", tolower(paste(summary$analysis, summary$called)))))
  file <- withr::local_tempfile(fileext = ".csv")
  capability_table_csv(tree, forms, file)
  csv <- utils::read.csv(file, check.names = FALSE)
  expect_identical(names(csv), c("Analysis", "Usually called", "Choice", "How it runs", "Limits", "Checks recorded"))
  expect_identical(nrow(csv), nrow(rows))
})

test_that("results show captured evidence and older results remain explicitly unknown", {
  html <- as.character(validation_ui(tree$endpoints$E2, list(provenance = list())))
  expect_match(html, "No variant-level evidence snapshot was captured", fixed = TRUE)
  expect_match(html, "Checks for this analysis in general", fixed = TRUE)
  lookup <- engine_function("analysis_evidence")
  skip_if(is.null(lookup))
  record <- lookup(list(design = "basic_test", template = "independent_t", target_test = list(method = "student_t")))
  html <- as.character(evidence_ui(record))
  for (label in c("Software agreement", "Independent reference", "Published example", "Method-validation run")) expect_match(html, label, fixed = TRUE)
  expect_match(html, record$registry_sha256, fixed = TRUE)
  # The records match the method and its options, not the values entered,
  # so the panel doesn't claim to cover exactly these settings.
  expect_match(html, "Evidence for this analysis method", fixed = TRUE)
  expect_match(html, "not on your sample size, effect or alpha", fixed = TRUE)
  expect_no_match(html, "exactly these settings", fixed = TRUE)
})
