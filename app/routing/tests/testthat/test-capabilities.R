test_that("the current capability table includes every card and declared test choice", {
  rows <- capability_rows(tree, forms)
  expect_setequal(unique(rows$endpoint), names(tree$endpoints))
  e2 <- rows[rows$endpoint == "E2", ]
  expect_true(any(grepl("Welch", e2$choice)))
  expect_true(any(grepl("Mann-Whitney", e2$choice)))
  expect_true(all(nzchar(rows$access)))
  expect_match(paste(e2$restrictions, collapse = " "), "root mean square", fixed = TRUE)
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

test_that("results show captured evidence and older results remain explicitly unknown", {
  html <- as.character(validation_ui(tree$endpoints$E2, list(provenance = list())))
  expect_match(html, "No variant-level evidence snapshot was captured", fixed = TRUE)
  expect_match(html, "Historical design-level note", fixed = TRUE)
  lookup <- engine_function("analysis_evidence")
  skip_if(is.null(lookup))
  record <- lookup(list(design = "basic_test", template = "independent_t", target_test = list(method = "student_t")))
  html <- as.character(evidence_ui(record))
  for (label in c("Software agreement", "Independent reference", "Published example", "Method-validation run")) expect_match(html, label, fixed = TRUE)
  expect_match(html, record$registry_sha256, fixed = TRUE)
})
