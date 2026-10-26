# Read tables from the docs, so the tests can compare them with tree.yaml.

read_doc <- function(name) {
  paste(readLines(file.path(repo_dir, "docs", name), encoding = "UTF-8", warn = FALSE), collapse = "\n")
}

# The cells of every table row between two headings of a markdown file.
table_rows <- function(text, from, to) {
  start <- regexpr(from, text, fixed = TRUE)
  end <- regexpr(to, substring(text, start), fixed = TRUE)
  section <- substring(text, start, start + end - 2)
  lines <- strsplit(section, "\n", fixed = TRUE)[[1]]
  lines <- lines[startsWith(lines, "| ") & !startsWith(lines, "| ---")]
  lapply(lines, split_row)
}

# The cells of one markdown table row, split on unescaped pipes.
split_row <- function(line) {
  inner <- sub("\\|\\s*$", "", sub("^\\|", "", line))
  trimws(strsplit(inner, "(?<!\\\\)\\|", perl = TRUE)[[1]])
}

# decision-tree.md, table 2.3: one row per end point.
doc_endpoints <- function() {
  rows <- table_rows(read_doc("decision-tree.md"), "### 2.3 End points", "**For \"not in spec\" end points")
  rows <- Filter(function(r) grepl("^E", r[1]), rows)
  data.frame(
    id = vapply(rows, `[`, "", 1),
    name = vapply(rows, `[`, "", 2),
    tier = vapply(rows, `[`, "", 8),
    status = vapply(rows, `[`, "", 9),
    validated = vapply(rows, `[`, "", 7),
    stringsAsFactors = FALSE
  )
}

# decision-tree.md, table 2.2: the question IDs in the first column.
# "F1–F3" expands to F1, F2, F3; "Every design: Q-goal" gives Q-goal; rows
# whose first cell holds no question ID (the form's path question, run
# settings) are skipped.
doc_question_ids <- function() {
  rows <- table_rows(read_doc("decision-tree.md"), "### 2.2 Questions and their spec fields", "**Power at a given N (planned effect size) is not observed power.**")
  ids <- character()
  for (r in rows[-1]) {
    cell <- sub("^Every design: ", "", r[1])
    for (part in trimws(strsplit(cell, ",", fixed = TRUE)[[1]])) {
      range <- regmatches(part, regexec("^([A-Z]+)([0-9]+)–[A-Z]+([0-9]+)$", part))[[1]]
      if (length(range) == 4) {
        ids <- c(ids, paste0(range[2], seq(as.integer(range[3]), as.integer(range[4]))))
      } else if (grepl("^(S[0-9]+|Q[0-9]+|O5a|F[0-9]+[a-z]?|R[0-9]+|T[0-9]+|MO[0-9]+|ME[0-9]+|MM[0-9]+|PP[0-9]+|Q-[a-z]+)$", part)) {
        ids <- c(ids, part)
      }
    }
  }
  unique(ids)
}

# coverage.md: capability rows whose tier starts with "MVP".
coverage_mvp_capabilities <- function() {
  lines <- strsplit(read_doc("coverage.md"), "\n", fixed = TRUE)[[1]]
  lines <- lines[startsWith(lines, "| ") & !startsWith(lines, "| ---")]
  caps <- character()
  for (l in lines) {
    cells <- split_row(l)
    if (length(cells) >= 6 && startsWith(cells[4], "MVP")) caps <- c(caps, cells[1])
  }
  caps
}

# coverage-roadmap.md, Parts A to C: one row per design, with the end point
# it reaches and its status. The columns are in different positions in the
# three parts, so the cells are found by what they look like instead.
roadmap_rows <- function() {
  lines <- strsplit(read_doc("coverage-roadmap.md"), "\n", fixed = TRUE)[[1]]
  rows <- lapply(lines[grepl("^\\| [ABC][0-9]+ \\|", lines)], split_row)
  ids <- vapply(rows, `[`, "", 1)
  rows <- rows[!duplicated(ids)]
  statuses <- paste0(
    "^(Done|Validated|Planned|Wired|Unknown|Foundation tool|",
    "G\\\\\\*Power covers|No ready-made tool|Partly working|Out of scope)"
  )
  first_match <- function(cells, pattern) {
    cell <- Find(function(x) grepl(pattern, x), cells)
    if (is.null(cell)) NA_character_ else cell
  }
  data.frame(
    id = ids[!duplicated(ids)],
    # "E9" and "E50 (only from ...)" both give the end point; cells like
    # "none: reaches E4" don't start with an id and are left out.
    endpoint = vapply(rows, function(r) {
      sub("^(E[0-9]+)\\b.*", "\\1", first_match(r[-1], "^E[0-9]+\\b"))
    }, ""),
    status = vapply(rows, function(r) first_match(r[-1], statuses), ""),
    stringsAsFactors = FALSE
  )
}
