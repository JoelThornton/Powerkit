# Every author-year reference that researchers read (cards, input screens,
# results, write-ups, R scripts and engine messages) must be one powerkit
# can cite: an entry in engine/inst/citations/refs.bib or in the citation()
# of a package the engine uses (CLAUDE.md: citations come only from these).
# Code comments are not checked; string literals in R files and every string
# in the two YAML files are.

user_text_strings <- function() {
  r_strings <- function(path) {
    pd <- utils::getParseData(parse(path, keep.source = TRUE))
    pd$text[pd$token == "STR_CONST"]
  }
  yaml_strings <- function(path) {
    x <- unlist(yaml::read_yaml(path), use.names = FALSE)
    as.character(x[is.character(x)])
  }
  r_files <- c(list.files(file.path(routing_dir, "R"), pattern = "\\.R$", full.names = TRUE),
    list.files(file.path(repo_dir, "engine", "R"), pattern = "\\.R$", full.names = TRUE))
  c(unlist(lapply(file.path(routing_dir, c("forms.yaml", "tree.yaml")), yaml_strings)),
    unlist(lapply(r_files, r_strings)))
}

# Surname and year of each author-year citation in a text: "Shieh's (2020)",
# "Jackson and Turner, 2017", "Dziak et al., 2020".
author_years <- function(texts) {
  pattern <- "\\b([A-Z][A-Za-z'-]+)((?: et al\\.)|(?:(?:, [A-Z][A-Za-z'-]+)*,? (?:and|&) [A-Z][A-Za-z'-]+))?(?:'s)?,? \\(?((?:19|20)[0-9]{2})[a-z]?\\b"
  hits <- unlist(regmatches(texts, gregexpr(pattern, texts, perl = TRUE)))
  out <- data.frame(text = hits, surname = sub("'s$", "", sub("^([A-Z][A-Za-z'-]+).*$", "\\1", hits)),
    year = sub("^.*((19|20)[0-9]{2})[a-z]?$", "\\1", hits), stringsAsFactors = FALSE)
  # Dates ("18 October 2026") and version labels are not citations.
  out[!out$surname %in% c(month.name, "R", "G", "Version", "Since", "From", "Until", "In", "On", "Updated"), , drop = FALSE]
}

ascii <- function(x) {
  x <- gsub("\\{\\\\[^a-zA-Z]?([a-zA-Z])\\}", "\\1", x)
  iconv(x, "UTF-8", "ASCII//TRANSLIT", sub = "")
}

citable_references <- function() {
  bib <- paste(readLines(file.path(repo_dir, "engine", "inst", "citations", "refs.bib"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
  entries <- strsplit(bib, "\n@", fixed = TRUE)[[1]][-1]
  field <- function(e, name) {
    m <- regmatches(e, regexec(sprintf("\\b%s\\s*=\\s*\\{((?:[^{}]|\\{[^{}]*\\})*)\\}", name), e, perl = TRUE))[[1]]
    if (length(m) == 2) m[2] else NA_character_
  }
  known <- data.frame(authors = vapply(entries, field, "", "author"), year = vapply(entries, field, "", "year"), stringsAsFactors = FALSE)
  description <- read.dcf(file.path(repo_dir, "engine", "DESCRIPTION"), c("Imports", "Suggests"))
  packages <- trimws(sub("\\(.*$", "", unlist(strsplit(paste(description[!is.na(description)], collapse = ","), ","))))
  packages <- setdiff(packages[nzchar(packages)], c("R", "testthat", "knitr", "rmarkdown"))
  for (p in packages) {
    cites <- tryCatch(utils::citation(p), error = function(e) NULL)
    if (is.null(cites)) next
    for (i in seq_along(cites)) {
      entry <- cites[i]
      authors <- vapply(entry$author %||% list(), function(a) paste(a$family, collapse = " "), "")
      known <- rbind(known, data.frame(authors = paste(authors, collapse = "; "), year = as.character(entry$year %||% NA), stringsAsFactors = FALSE))
    }
  }
  known$authors <- ascii(known$authors)
  known
}

test_that("every author-year reference in user-facing text can be cited from refs.bib or a package's citation()", {
  skip_if_not_installed("pwrss")
  refs <- author_years(user_text_strings())
  expect_gt(nrow(refs), 50)
  known <- citable_references()
  found <- mapply(function(surname, year) {
    any(grepl(ascii(surname), known$authors, fixed = TRUE) & known$year == year)
  }, refs$surname, refs$year)
  expect_equal(sort(unique(refs$text[!found])), character())
})

test_that("the reference check finds a citation that is not in the bibliography", {
  refs <- author_years(c("as Nobody and Someone (1999) showed", "on 18 October 2026", "Shieh's (2020) method"))
  expect_equal(refs$surname, c("Nobody", "Shieh"))
  expect_equal(refs$year, c("1999", "2020"))
})
