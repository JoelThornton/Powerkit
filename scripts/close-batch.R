# Closes a batch: gives the change notes waiting on main their version.
#
# Each pull request writes its change notes as small files of its own, so
# parallel pull requests never edit the same lines (docs/adding-a-test.md,
# "Change notes and version numbers"):
#
#   engine/news.d/<topic>.md            developer notes, Markdown bullets
#   app/routing/whats-new.d/<topic>.yaml  Updates entries, as in whats-new.yaml
#
# The pull request that finishes a batch runs this script, which
#   - sets the new version in engine/DESCRIPTION and CITATION.cff,
#   - puts every engine/news.d note under one "# powerkit <version>" heading
#     at the top of engine/NEWS.md,
#   - moves every whats-new.d entry to the top of whats-new.yaml, newest
#     first, exactly as written,
#   - and deletes the note files it used.
#
#   Rscript scripts/close-batch.R minor     # 0.44.0 -> 0.45.0 (a batch of features)
#   Rscript scripts/close-batch.R patch     # 0.44.0 -> 0.44.1 (fixes only)
#   Rscript scripts/close-batch.R 1.0.0     # a number the maintainer chose
#
# Run it from the repository root. It refuses to run with no notes waiting.

next_version <- function(current, bump) {
  parts <- as.integer(strsplit(current, ".", fixed = TRUE)[[1]])
  if (length(parts) != 3 || anyNA(parts)) stop("engine/DESCRIPTION's Version must be major.minor.patch, not ", current)
  if (identical(bump, "minor")) return(paste(parts[1], parts[2] + 1L, 0L, sep = "."))
  if (identical(bump, "patch")) return(paste(parts[1], parts[2], parts[3] + 1L, sep = "."))
  if (!grepl("^[0-9]+\\.[0-9]+\\.[0-9]+$", bump)) stop("Give minor, patch or a version such as 1.0.0, not ", bump)
  if (utils::compareVersion(bump, current) <= 0) stop(bump, " is not later than the current version, ", current)
  bump
}

# The note files waiting, in a stable order.
pending_news <- function(root) sort(Sys.glob(file.path(root, "engine", "news.d", "*.md")))
pending_updates <- function(root) sort(Sys.glob(file.path(root, "app", "routing", "whats-new.d", "*.yaml")))

read_lines <- function(path) readLines(path, encoding = "UTF-8", warn = FALSE)
write_lines <- function(lines, path) {
  force(lines) # before the file is emptied for writing, as lines may come from it
  con <- file(path, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(lines, con)
}

# A note file without blank lines at its ends.
trimmed <- function(lines) {
  keep <- which(nzchar(trimws(lines)))
  if (!length(keep)) return(character())
  lines[min(keep):max(keep)]
}

# The lines of an Updates file after its `entries:` line, as written.
update_entry_lines <- function(path) {
  lines <- read_lines(path)
  start <- match("entries:", lines)
  if (is.na(start)) stop(path, " has no 'entries:' line")
  trimmed(lines[-seq_len(start)])
}

newest_date <- function(path) {
  dates <- vapply(yaml::read_yaml(path, fileEncoding = "UTF-8")$entries, `[[`, "", "date")
  max(as.Date(dates))
}

close_batch <- function(bump, root = ".") {
  news_files <- pending_news(root)
  update_files <- pending_updates(root)
  if (!length(news_files) && !length(update_files)) {
    stop("No change notes are waiting (engine/news.d/ and app/routing/whats-new.d/ are empty).")
  }

  description_path <- file.path(root, "engine", "DESCRIPTION")
  description <- read_lines(description_path)
  line <- grep("^Version:", description)
  current <- trimws(sub("^Version:", "", description[line]))
  version <- next_version(current, bump)
  description[line] <- paste("Version:", version)
  write_lines(description, description_path)

  cff_path <- file.path(root, "CITATION.cff")
  cff <- read_lines(cff_path)
  cff[grep("^version:", cff)] <- paste("version:", version)
  write_lines(cff, cff_path)

  news_path <- file.path(root, "engine", "NEWS.md")
  notes <- unlist(lapply(news_files, function(f) c(trimmed(read_lines(f)), "")))
  if (!length(notes)) notes <- c("* No developer-facing changes; see the Updates entries.", "")
  write_lines(c(paste("# powerkit", version), "", notes, read_lines(news_path)), news_path)

  if (length(update_files)) {
    update_files <- update_files[order(-as.numeric(vapply(update_files, newest_date, numeric(1))), update_files)]
    whats_new_path <- file.path(root, "app", "routing", "whats-new.yaml")
    lines <- read_lines(whats_new_path)
    at <- match("entries:", lines)
    entries <- unlist(lapply(update_files, update_entry_lines))
    write_lines(c(lines[seq_len(at)], entries, lines[-seq_len(at)]), whats_new_path)
  }

  unlink(c(news_files, update_files))
  invisible(list(version = version, news = basename(news_files), updates = basename(update_files)))
}

if (!interactive() && sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 1) stop("Usage: Rscript scripts/close-batch.R minor|patch|<version>")
  done <- close_batch(args[[1]])
  cat(sprintf("powerkit %s: %d engine notes and %d Updates files joined.\n",
    done$version, length(done$news), length(done$updates)))
}
