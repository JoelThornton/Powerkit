test_that("paired and mixed cards do not promise general crossover power", {
  paired <- paste(unlist(tree$endpoints$E3$card_points), collapse = " ")
  expect_match(paired, "ordinary paired comparison", fixed = TRUE)
  expect_false(grepl("close approximation|degree of freedom fewer", paired))
  expect_match(paste(tree$endpoints$E8$card_points, collapse = " "), "not a separately validated crossover analysis", fixed = TRUE)
  for (ep in c("E3", "E8")) {
    ui <- as.character(form_ui(tree, forms, ep, form_groups(forms, ep), form_examples[[ep]]))
    expect_match(ui, 'class="analysis-scope-note"', fixed = TRUE)
    expect_match(ui, "carry-over", fixed = TRUE)
  }
})

test_that("paired copied methods state what the analysis does not model", {
  fields <- form_fields(form_groups(forms, "E3"))
  values <- modifyList(form_examples$E3, list(goal = "power", n = "60"))
  spec <- build_spec(forms, "E3", fields, values)
  result <- powerkit::run_spec(spec)
  methods <- writeup_text(forms$forms$E3, spec, result, fields, values)
  expect_match(methods[["short"]], "without period, sequence or carry-over terms", fixed = TRUE)
})
