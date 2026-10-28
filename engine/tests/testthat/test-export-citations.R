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

empty_bib <- function() {
  path <- tempfile(fileext = ".bib")
  writeLines("% no entries", path)
  path
}

test_that("with an empty reference list, method and powerkit papers are placeholders", {
  refs <- empty_bib()
  on.exit(unlink(refs))
  for (backend in backends) {
    text <- export_citations(fake_result(backend), refs = refs)
    expect_match(text, sprintf("refs.bib) has no entry '%s_method' yet", backend), fixed = TRUE)
    expect_match(text, "has no entry 'powerkit' yet", fixed = TRUE)
    expect_match(text, "The write-up (a short methods paragraph and a full version) is on powerkit's result screen.", fixed = TRUE)
  }
})

test_that("powerkit's refs.bib: method papers only where citation() gives one", {
  # Spower's and power4mome's citation() give only their manuals, so their
  # method papers stay placeholders, as does powerkit's own citation.
  for (backend in c("Spower", "power4mome")) {
    expect_match(export_citations(fake_result(backend)), sprintf("no entry '%s_method' yet", backend), fixed = TRUE)
  }
  expect_match(export_citations(fake_result("Spower")), "no entry 'powerkit' yet", fixed = TRUE)
  # Superpower's and InteractionPoweR's are copied from their citation(), so
  # the export says they are the same as the package citation.
  for (backend in c("Superpower", "InteractionPoweR")) {
    text <- export_citations(fake_result(backend))
    expect_no_match(text, sprintf("no entry '%s_method'", backend), fixed = TRUE)
    expect_match(text, "(The same as the package citation above.)", fixed = TRUE)
    bib <- export_citations(fake_result(backend), format = "bibtex")
    expect_match(bib, sprintf("method paper: the same as %s_package above.", backend), fixed = TRUE)
  }
})

# Where a refs.bib entry comes from (CLAUDE.md: refs.bib or a package's own
# citation(); never from memory). An entry is accepted if either:
# * "citation": its key is <package>_method and its DOI is among the DOIs of
#   that package's citation() (copied with toBibtex()); or
# * "verified": it has a DOI and a `note` saying where and when it was
#   verified: "Verified", an ISO date (YYYY-MM-DD, not in the future), then
#   the URL a session opened, or "from full-text PDF held by the maintainer"
#   (the maintainer's rule of 17 October 2026), e.g.
#   note = {Verified 2026-10-17 at https://doi.org/10.1234/abcd} or
#   note = {Verified 2026-10-17 from full-text PDF held by the maintainer}.
# Anything else is "unverified".
refs_entry_source <- function(key, entry) {
  package <- sub("_method$", "", key)
  if (!identical(package, key) && requireNamespace(package, quietly = TRUE) &&
    same_doi(entry, utils::citation(package))) {
    return("citation")
  }
  doi <- entry$fields$doi %||% ""
  note <- entry$fields$note %||% ""
  date <- regmatches(note, regexpr("[0-9]{4}-[0-9]{2}-[0-9]{2}", note))
  dated <- length(date) == 1 && !is.na(as.Date(date, optional = TRUE)) &&
    as.Date(date) <= Sys.Date()
  where <- grepl("https?://", note) ||
    grepl("^Verified [0-9-]+ from full-text PDF held by the maintainer", note)
  if (nzchar(doi) && grepl("^Verified\\b", note) && dated && where) {
    return("verified")
  }
  "unverified"
}

test_that("every refs.bib entry is copied from citation() or a DOI verified with a dated note", {
  entries <- read_bib(refs_path())
  for (key in names(entries)) {
    expect_true(refs_entry_source(key, entries[[key]]) %in% c("citation", "verified"), label = key)
  }
  # Two method papers copied from their packages' citation(), five
  # sources the maintainer checked in full text, and four on test
  # direction and multiple tests (19 October 2026), and the safeguard
  # power paper (27 October 2026).
  expect_equal(
    vapply(names(entries), function(k) refs_entry_source(k, entries[[k]]), character(1)),
    c(
      Superpower_method = "citation", InteractionPoweR_method = "citation",
      Rubin2021_alpha = "verified", Rubin2024_inconsistent = "verified",
      RubinMikael2025_power = "verified", Frane2019_misguided = "verified",
      Karhulahti2025_prereplication = "verified",
      Rubin2022_twosided = "verified", Rubin2024_typeI = "verified",
      FrancisThunell2021_reversing = "verified", Mayo2018_severe = "verified",
      Perugini2014_safeguard = "verified", semPower_method = "verified",
      bfpwr_method = "citation"
    )
  )
})

test_that("an entry not from citation() needs a DOI and a note saying where and when it was verified", {
  # Fixtures only: not real references, never shipped in refs.bib.
  entry <- function(...) list(type = "Article", key = "x", fields = list(...))
  ok_note <- "Verified 2026-10-01 at https://doi.org/10.0000/fixture"
  expect_equal(refs_entry_source("Some_paper", entry(doi = "10.0000/fixture", note = ok_note)), "verified")
  # A method key whose DOI isn't in the package's citation() may still be verified.
  expect_equal(refs_entry_source("Spower_method", entry(doi = "10.0000/fixture", note = ok_note)), "verified")
  expect_equal(refs_entry_source("Some_paper", entry(note = ok_note)), "unverified")
  expect_equal(refs_entry_source("Some_paper", entry(doi = "10.0000/fixture")), "unverified")
  expect_equal(
    refs_entry_source("Some_paper", entry(doi = "10.0000/fixture", note = "Verified at https://doi.org/10.0000/fixture")),
    "unverified"
  )
  expect_equal(
    refs_entry_source("Some_paper", entry(doi = "10.0000/fixture", note = "Verified 2026-10-01")),
    "unverified"
  )
  expect_equal(
    refs_entry_source("Some_paper", entry(doi = "10.0000/fixture", note = "Verified 2999-01-01 at https://doi.org/x")),
    "unverified"
  )
  expect_equal(
    refs_entry_source("Some_paper", entry(doi = "10.0000/fixture", note = "Seen 2026-10-01 at https://doi.org/x")),
    "unverified"
  )
  # A full text the maintainer checked counts in place of an opened URL.
  pdf_note <- "Verified 2026-10-01 from full-text PDF held by the maintainer"
  expect_equal(refs_entry_source("Some_paper", entry(doi = "10.0000/fixture", note = pdf_note)), "verified")
  expect_equal(refs_entry_source("Some_paper", entry(note = pdf_note)), "unverified")
  expect_equal(
    refs_entry_source("Some_paper", entry(doi = "10.0000/fixture", note = "Verified 2026-10-01 from a PDF")),
    "unverified"
  )
})

test_that("a verification note is shown in neither the text nor the BibTeX export", {
  path <- tempfile(fileext = ".bib")
  on.exit(unlink(path))
  writeLines(c(
    "@Article{Spower_method,",
    "  author = {Test, Author},",
    "  title = {A Fixture, Not a Real Reference},",
    "  journal = {Journal of Test Fixtures},",
    "  year = {2000},",
    "  doi = {10.0000/fixture},",
    "  note = {Verified 2026-10-01 at https://doi.org/10.0000/fixture},",
    "}"
  ), path)
  text <- export_citations(fake_result("Spower"), refs = path)
  expect_match(text, "A Fixture, Not a Real", fixed = TRUE)
  expect_no_match(text, "Verified 2026-10-01", fixed = TRUE)
  bib <- export_citations(fake_result("Spower"), format = "bibtex", refs = path)
  expect_match(bib, "@Article{Spower_method,", fixed = TRUE)
  expect_match(bib, "doi = {10.0000/fixture},", fixed = TRUE)
  expect_no_match(bib, "Verified", fixed = TRUE)
})

test_that("the software used underneath is listed, each from its own citation()", {
  expected <- list(
    Spower = "SimDesign", Superpower = c("afex", "MASS"),
    InteractionPoweR = character(), power4mome = c("lavaan", "manymome")
  )
  for (backend in backends) {
    text <- export_citations(fake_result(backend))
    expect_match(text, "Software used (doing work underneath; each from its own citation()):", fixed = TRUE)
    for (package in c(expected[[backend]], "base")) {
      expect_match(text, sprintf("(from citation(\"%s\"))", package), fixed = TRUE)
      first_line <- strsplit(format(utils::citation(package), style = "text")[1], "\n")[[1]][1]
      expect_match(text, first_line, fixed = TRUE)
    }
  }
})

test_that("a package only some of a backend's tests use is cited only then", {
  # Spower's p_var.test() runs EnvStats::varTest() for the variance of one
  # group, and nothing else powerkit sends to Spower touches EnvStats. The
  # run's own package list decides, so the citation follows the provenance.
  plain <- export_citations(fake_result("Spower"))
  expect_no_match(plain, "EnvStats", fixed = TRUE)

  result <- fake_result("Spower")
  result$provenance$packages <- c(result$provenance$packages, EnvStats = "3.1.0")
  text <- export_citations(result)
  expect_match(text, "(from citation(\"EnvStats\"))", fixed = TRUE)
  first_line <- strsplit(format(utils::citation("EnvStats"), style = "text")[1], "\n")[[1]][1]
  expect_match(text, first_line, fixed = TRUE)
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
  refs <- empty_bib()
  on.exit(unlink(refs))
  software <- list(
    Spower = "SimDesign", Superpower = c("afex", "MASS"),
    InteractionPoweR = character(), power4mome = c("lavaan", "manymome")
  )
  for (backend in backends) {
    bib <- export_citations(fake_result(backend), format = "bibtex", refs = refs)
    entries <- regmatches(bib, gregexpr("(?m)^@[A-Za-z]+\\{[^,]*,", bib, perl = TRUE))[[1]]
    # The citation() entries of the backend, powerkit, the software used
    # and R; nothing else.
    expected <- sum(vapply(
      c(backend, software[[backend]], "base"), function(p) length(utils::citation(p)), integer(1)
    )) + 1
    expect_length(entries, expected)
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
