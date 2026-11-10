test_that("every analysis and family has a curated conventional label", {
  expect_true(all(vapply(tree$endpoints, function(ep) is.character(ep$technical_name) && length(ep$technical_name) == 1 && nzchar(ep$technical_name), logical(1))))
  expect_true(all(vapply(tree$analysis_families, function(f) is.character(f$technical_label) && nzchar(f$technical_label), logical(1))))
  expect_equal(technical_name(tree$endpoints$E2), "Independent-samples t-test")
  expect_equal(technical_name(tree$endpoints$E23), "ANCOVA")
  expect_equal(technical_name(list(doc_name = "Old custom analysis")), "Old custom analysis")
})

test_that("compact names are shared by the list, card and input screen", {
  html <- as.character(known_ui(tree))
  expect_match(html, '<span class="name-tech">Independent-samples t-test</span>', fixed = TRUE)
  expect_match(html, '<span class="name-tech">t-tests</span>', fixed = TRUE)
  expect_match(html, 'welch', fixed = TRUE) # detailed documentation remains searchable
  card <- as.character(card_ui(tree, "E23"))
  expect_match(card, '<span class="name-tech">ANCOVA</span>', fixed = TRUE)
  screen <- as.character(form_ui(tree, forms, "E23", form_groups(forms, "E23"), form_examples$E23))
  expect_match(screen, '<span class="name-tech">ANCOVA</span>', fixed = TRUE)
})

test_that("short method labels retain the selected test and assumption guidance", {
  fields <- form_fields(form_groups(forms, "E2"))
  method <- Filter(function(f) identical(f$id, "method"), fields)[[1]]
  expect_equal(method$choices$welch_t, "Welch's t-test")
  expect_equal(method$choices$student_t, "Student's t-test")
  expect_match(method$choice_notes$welch_t, "normal scores", fixed = TRUE)
  expect_match(method$choice_notes$bayes_factor, "equal groups", fixed = TRUE)
  expect_equal(method$default, "welch_t")
})
