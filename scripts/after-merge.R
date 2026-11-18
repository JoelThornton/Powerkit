# Numbers what a merge brought to main. Run by .github/workflows/after-merge.yaml
# after every merge to main, never by a pull request (decided 18 November 2026;
# docs/adding-a-test.md, "Change notes and version numbers").
#
# Pull requests write only files of their own (change notes, decision
# entries) and the lines of shared pages that their change is about. Every
# line that each merge would otherwise rewrite is written here, once, on
# main, so parallel pull requests never conflict over it:
#   - the change notes in engine/news.d/ and app/routing/whats-new.d/ get
#     the next version (scripts/close-batch.R): engine/DESCRIPTION,
#     CITATION.cff, engine/NEWS.md and whats-new.yaml;
#   - the decision entries in docs/decisions.d/ are added to the end of
#     docs/decisions.md, oldest first;
#   - docs/status.md's "Last updated" line gets the date;
#   - docs/release-support-inventory.json is regenerated
#     (scripts/release-support.R).
#
#   Rscript scripts/after-merge.R patch    # the default
#   Rscript scripts/after-merge.R minor    # the merged pull request had the "minor" label
#
# Run it from the repository root. It prints the new version, or nothing
# when no change notes were waiting (the other steps still run).

script_dir <- function() {
  file <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
  if (length(file)) dirname(normalizePath(file[1])) else "scripts"
}

# The decision entries waiting, oldest first: by the date in each entry's
# heading ("## 2026-11-18 · Title"), then by file name.
pending_decisions <- function(root) {
  files <- Sys.glob(file.path(root, "docs", "decisions.d", "*.md"))
  if (!length(files)) return(character())
  dates <- vapply(files, function(f) {
    first <- grep("^## ", readLines(f, encoding = "UTF-8", warn = FALSE), value = TRUE)[1]
    sub("^## ([0-9]{4}-[0-9]{2}-[0-9]{2}) .*$", "\\1", first %||% "")
  }, "")
  files[order(dates, basename(files), method = "radix")]
}

`%||%` <- function(x, y) if (is.null(x) || is.na(x)) y else x

join_decisions <- function(root = ".") {
  files <- pending_decisions(root)
  if (!length(files)) return(invisible(character()))
  path <- file.path(root, "docs", "decisions.md")
  log <- readLines(path, encoding = "UTF-8", warn = FALSE)
  while (length(log) && !nzchar(trimws(log[length(log)]))) log <- log[-length(log)]
  entries <- unlist(lapply(files, function(f) {
    lines <- readLines(f, encoding = "UTF-8", warn = FALSE)
    keep <- which(nzchar(trimws(lines)))
    c("", lines[min(keep):max(keep)])
  }))
  con <- file(path, open = "w", encoding = "UTF-8")
  writeLines(c(log, entries), con)
  close(con)
  unlink(files)
  invisible(basename(files))
}

# "*Last updated: 18 November 2026.*", the page's third line.
set_status_date <- function(root = ".", date = Sys.Date()) {
  path <- file.path(root, "docs", "status.md")
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  at <- grep("^\\*Last updated: ", lines)[1]
  if (is.na(at)) stop(path, " has no '*Last updated: ' line")
  day <- format(as.Date(date), "%d %B %Y")
  lines[at] <- paste0("*Last updated: ", sub("^0", "", day), ".*")
  con <- file(path, open = "w", encoding = "UTF-8")
  writeLines(lines, con)
  close(con)
  invisible(lines[at])
}

after_merge <- function(bump = "patch", root = ".", date = Sys.Date(), scripts = script_dir()) {
  if (!bump %in% c("patch", "minor")) stop("Give patch or minor, not ", bump)
  closer <- new.env()
  sys.source(file.path(scripts, "close-batch.R"), envir = closer)
  waiting <- c(closer$pending_news(root), closer$pending_updates(root))
  closed <- if (length(waiting)) withr_dir(root, closer$close_batch(bump)) else NULL
  decisions <- join_decisions(root)
  set_status_date(root, date)
  inventory <- new.env(parent = globalenv())
  sys.source(file.path(scripts, "release-support.R"), envir = inventory)
  writeBin(charToRaw(withr_dir(root, inventory$release_support_text())),
    file.path(root, "docs", "release-support-inventory.json"))
  invisible(list(version = closed$version, decisions = decisions))
}

withr_dir <- function(dir, code) {
  old <- setwd(dir)
  on.exit(setwd(old))
  force(code)
}

if (!interactive() && sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  done <- after_merge(if (length(args)) args[[1]] else "patch")
  if (!is.null(done$version)) cat(done$version, "\n", sep = "")
}
