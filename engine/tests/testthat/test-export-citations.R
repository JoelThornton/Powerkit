# export_citations(): the package's own citation(), its method paper and
# powerkit's citation. Method papers and powerkit's paper come only from
# inst/citations/refs.bib; anything missing there is a placeholder.

backends <- c("Spower", "Superpower", "InteractionPoweR", "power4mome")

# A fixture for the reader and formatter only. It is not a real reference
# and is never shipped in refs.bib.
fixture_bib <- function(key = "Superpower_method") {
  path <- tempfile(fileext = ".bib")
  writeLines(c(
    "% A comment line, with an @ sign that must not start an entry.",
    sprintf("@Article{%s,", key),
    "  author = {Test, Author and Fixture, Second},",
    "  title = {A {Test} Entry, Not a Real Reference},",
    "  journal = \"Journal of Test Fixtures\",",
    "  year = 2000,",
    "  volume = {1}",
    "}",
    "@comment{ignored}"
  ), path)
  path
}

test_that("with an empty reference list, method and powerkit papers are placeholders", {
  for (backend in backends) {
    text <- export_citations(fake_result(backend))
    expect_match(text, sprintf("refs.bib) has no entry '%s_method' yet", backend), fixed = TRUE)
    expect_match(text, "has no entry 'powerkit' yet", fixed = TRUE)
    expect_match(text, "[Placeholder: the methods paragraph is not written yet.]", fixed = TRUE)
  }
})

test_that("the package's own citation() is included, as the package gives it", {
  for (backend in backends) {
    text <- export_citations(fake_result(backend))
    for (line in format(utils::citation(backend), style = "text")) {
      expect_match(text, strsplit(line, "\n")[[1]][1], fixed = TRUE)
    }
    expect_match(text, sprintf("from citation(\"%s\")", backend), fixed = TRUE)
  }
})

test_that("the BibTeX export holds only citation() entries and refs.bib entries", {
  for (backend in backends) {
    bib <- export_citations(fake_result(backend), format = "bibtex")
    entries <- regmatches(bib, gregexpr("(?m)^@[A-Za-z]+\\{[^,]*,", bib, perl = TRUE))[[1]]
    # The backend's citation() entries and powerkit's own; nothing else.
    expect_length(entries, length(utils::citation(backend)) + 1)
    expect_match(bib, sprintf("{%s_package,", backend), fixed = TRUE)
    expect_match(bib, "{powerkit_package,", fixed = TRUE)
    expect_match(bib, sprintf("%% [Placeholder: powerkit's reference list (refs.bib) has no entry '%s_method'", backend), fixed = TRUE)
  }
})

test_that("an entry in refs.bib replaces its placeholder", {
  refs <- fixture_bib()
  on.exit(unlink(refs))
  text <- export_citations(fake_result("Superpower"), refs = refs)
  expect_match(text, "A Test Entry, Not a Real", fixed = TRUE)
  expect_no_match(text, "no entry 'Superpower_method'", fixed = TRUE)
  expect_match(text, "no entry 'powerkit'", fixed = TRUE)
  bib <- export_citations(fake_result("Superpower"), format = "bibtex", refs = refs)
  expect_match(bib, "@Article{Superpower_method,", fixed = TRUE)
  expect_match(bib, "journal = \"Journal of Test Fixtures\"", fixed = TRUE)
})

test_that("read_bib() reads keys and fields, and skips comments", {
  refs <- fixture_bib("Some_key")
  on.exit(unlink(refs))
  entries <- read_bib(refs)
  expect_named(entries, "Some_key")
  e <- entries$Some_key
  expect_equal(e$type, "Article")
  expect_equal(e$fields$title, "A {Test} Entry, Not a Real Reference")
  expect_equal(e$fields$journal, "Journal of Test Fixtures")
  expect_equal(e$fields$year, "2000")
  expect_match(e$raw, "^@Article\\{Some_key,")
  expect_equal(read_bib(refs_path()), list())
})

test_that("export_citations() writes a file and needs a powerkit result", {
  file <- tempfile(fileext = ".txt")
  on.exit(unlink(file))
  text <- export_citations(fake_result("Spower"))
  expect_invisible(export_citations(fake_result("Spower"), file = file))
  expect_equal(paste(c(readLines(file), ""), collapse = "\n"), text)
  expect_error(export_citations(list()), "result of run_spec", class = "powerkit_export_error")
})

test_that("CITATION.cff agrees with the package DESCRIPTION", {
  cff <- test_path("..", "..", "..", "CITATION.cff")
  skip_if_not(file.exists(cff), "CITATION.cff is outside the package (not available in R CMD check)")
  lines <- readLines(cff)
  version <- as.character(utils::packageVersion("powerkit"))
  expect_true(any(lines == paste("version:", version)))
  expect_true(any(lines == "license: GPL-3.0-or-later"))
  expect_true(any(grepl("powerkit: Unified Power Analysis for Psychology Designs", lines, fixed = TRUE)))
})
