#' Citations for a result
#'
#' Lists what to cite for a [run_spec()] result: the package that computed
#' it (its own `citation()`), that package's method paper, powerkit, and
#' the software used underneath (the supporting packages that do real work
#' for the backend, and R), each from its own `citation()`. Citations come
#' only from powerkit's curated reference list (`inst/citations/refs.bib`)
#' or a package's own `citation()`. A method paper or powerkit paper not in
#' refs.bib yet is shown as a placeholder, never filled in from elsewhere.
#'
#' The methods paragraph is not written yet; the text export shows a
#' placeholder for it.
#'
#' @param result The `powerkit_result` returned by [run_spec()].
#' @param format `"text"` (readable, for the results screen) or `"bibtex"`
#'   (for a reference manager).
#' @param file Path to write the citations to (UTF-8), or `NULL` to only
#'   return them.
#' @param refs Path to the curated BibTeX file. Defaults to powerkit's
#'   `refs.bib`.
#'
#' @return The citations as a single string; invisibly if `file` is given.
#' @seealso [export_script()]
#' @export
#' @examples
#' \donttest{
#' spec <- read_spec(system.file("specs", "anova_2x2_mixed.json", package = "powerkit"))
#' cat(export_citations(run_spec(spec)))
#' }
export_citations <- function(result, format = c("text", "bibtex"), file = NULL, refs = refs_path()) {
  format <- match.arg(format)
  if (!inherits(result, "powerkit_result")) {
    abort_export("'result' should be the result of run_spec() (a powerkit result).")
  }
  package <- result$provenance$backend
  entries <- read_bib(refs)
  package_cit <- package_citation(package)
  method_ref <- entries[[method_paper_key(package)]]
  items <- list(
    package = list(
      label = sprintf("%s, the package that computed this power analysis (from citation(\"%s\"))", package, package),
      citation = package_cit,
      key = paste0(package, "_package")
    ),
    method = list(
      label = sprintf("%s's method paper", package),
      ref = method_ref,
      key = method_paper_key(package),
      same_as = if (!is.null(method_ref) && same_doi(method_ref, package_cit)) paste0(package, "_package")
    ),
    powerkit = list(
      label = "powerkit, the package that set up and checked the analysis (from its DESCRIPTION)",
      citation = package_citation("powerkit"),
      key = "powerkit_package"
    ),
    powerkit_paper = list(
      label = "powerkit's paper",
      ref = entries[[powerkit_paper_key()]],
      key = powerkit_paper_key()
    )
  )
  software <- lapply(supporting_software(package), function(s) {
    list(
      label = sprintf("%s, %s (from citation(\"%s\"))", s$name, s$role, s$citation),
      citation = package_citation(s$citation),
      key = paste0(s$name, "_package")
    )
  })
  text <- if (format == "text") {
    citations_text(items, software, result)
  } else {
    citations_bibtex(items, software, result)
  }
  text <- paste(c(text, ""), collapse = "\n")
  if (is.null(file)) {
    return(text)
  }
  write_utf8(text, file)
  invisible(text)
}

refs_path <- function() system.file("citations", "refs.bib", package = "powerkit")

# Keys powerkit looks up in refs.bib (listed at the top of refs.bib).
method_paper_key <- function(package) paste0(package, "_method")
powerkit_paper_key <- function() "powerkit"

# The software doing real work underneath each backend, for the "software
# used" section: packages the backend calls to simulate, fit or test (from
# the backends' sources: Spower runs its simulations with SimDesign;
# Superpower fits its ANOVAs with afex::aov_car() and generates data with
# MASS::mvrnorm(); power4mome fits with lavaan and computes indirect effects
# and their confidence intervals with manymome; InteractionPoweR uses base
# R only), then R itself. `citation` is the package whose citation() is
# used ("base" for R).
supporting_software <- function(backend) {
  s <- function(name, role, citation = name) list(name = name, role = role, citation = citation)
  packages <- switch(
    backend,
    Spower = list(s("SimDesign", "which runs Spower's simulations")),
    Superpower = list(
      s("afex", "which fits Superpower's ANOVAs (aov_car())"),
      s("MASS", "which Superpower uses to generate data (mvrnorm())")
    ),
    power4mome = list(
      s("lavaan", "which fits the model to each simulated data set"),
      s("manymome", "which computes the indirect effect or index and its confidence interval")
    ),
    list()
  )
  c(packages, list(s("R", "in which the analysis ran", "base")))
}

# Whether a refs.bib entry has the same DOI as an entry of a citation().
same_doi <- function(ref, cit) {
  doi <- tolower(ref$fields$doi %||% "")
  nzchar(doi) && doi %in% tolower(unlist(lapply(unclass(cit), function(e) e$doi)))
}

# A package's own citation(). powerkit's comes from its DESCRIPTION when it
# isn't installed (as under devtools::load_all()).
package_citation <- function(package) {
  cit <- tryCatch(suppressWarnings(utils::citation(package)), error = function(e) NULL)
  if (is.null(cit) && package == "powerkit") {
    meta <- as.list(read.dcf(system.file("DESCRIPTION", package = "powerkit"))[1, ])
    class(meta) <- "packageDescription"
    cit <- suppressWarnings(utils::citation(auto = meta))
  }
  cit
}

placeholder_text <- function(key) {
  sprintf(
    "[Placeholder: powerkit's reference list (refs.bib) has no entry '%s' yet. The maintainer adds it.]",
    key
  )
}

methods_placeholder <- function() {
  "[Placeholder: the methods paragraph is not written yet.]"
}

citations_text <- function(items, software, result) {
  p <- result$provenance
  entry_text <- function(item) {
    if (!is.null(item$citation)) {
      return(format(item$citation, style = "text"))
    }
    if (is.null(item$ref)) {
      return(placeholder_text(item$key))
    }
    text <- bib_entry_text(item$ref)
    if (is.null(item$same_as)) text else c(text, "(The same as the package citation above.)")
  }
  section <- function(items) {
    unlist(lapply(items, function(item) {
      c(paste0(item$label, ":"), paste0("  ", gsub("\n", "\n  ", entry_text(item))), "")
    }), use.names = FALSE)
  }
  c(
    "Citations for this power analysis",
    sprintf("(powerkit %s; %s %s; spec hash %s)", p$packages[["powerkit"]], p$backend, p$packages[[p$backend]], p$spec_hash),
    "",
    section(items),
    "Software used (doing work underneath; each from its own citation()):",
    "",
    section(software),
    "Methods paragraph:",
    paste0("  ", methods_placeholder())
  )
}

citations_bibtex <- function(items, software, result) {
  p <- result$provenance
  section <- function(items) {
    unlist(lapply(items, function(item) {
      if (!is.null(item$citation)) {
        return(c(sprintf("%% %s", item$label), bibentry_bibtex(item$citation, item$key), ""))
      }
      if (is.null(item$ref)) {
        return(c(sprintf("%% %s", item$label), paste("%", placeholder_text(item$key)), ""))
      }
      if (!is.null(item$same_as)) {
        return(c(sprintf("%% %s: the same as %s above.", item$label, item$same_as), ""))
      }
      c(sprintf("%% %s (from powerkit's refs.bib)", item$label), item$ref$raw, "")
    }), use.names = FALSE)
  }
  c(
    sprintf(
      "%% Citations for this power analysis (powerkit %s; %s %s; spec hash %s)",
      p$packages[["powerkit"]], p$backend, p$packages[[p$backend]], p$spec_hash
    ),
    "",
    section(items),
    "% Software used (doing work underneath; each from its own citation())",
    "",
    section(software)
  )
}

# BibTeX for a citation() object, with keys key, key_2, ...
bibentry_bibtex <- function(cit, key) {
  keys <- if (length(cit) == 1) key else paste0(key, c("", paste0("_", seq_len(length(cit) - 1) + 1)))
  unlist(lapply(seq_along(cit), function(i) {
    entry <- cit[i]
    entry$key <- keys[i]
    c(as.character(utils::toBibtex(entry)), "")
  }), use.names = FALSE)
}

# Readable text for a refs.bib entry, or its BibTeX if R can't format it
# (for example, a required field is missing).
bib_entry_text <- function(entry) {
  fields <- lapply(entry$fields, function(x) gsub("[{}]", "", x))
  formatted <- tryCatch(
    format(do.call(utils::bibentry, c(list(bibtype = entry$type, key = entry$key), fields)), style = "text"),
    error = function(e) NULL
  )
  formatted %||% entry$raw
}

# A small reader for the curated refs.bib: a named list (by key) of
# entries, each list(type, key, fields, raw). Lines starting with % are
# comments; @comment, @preamble and @string blocks are ignored.
read_bib <- function(path) {
  if (!nzchar(path) || !file.exists(path)) {
    return(list())
  }
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  lines <- lines[!grepl("^\\s*%", lines)]
  chars <- strsplit(paste(lines, collapse = "\n"), "")[[1]]
  entries <- list()
  i <- 1
  while (i <= length(chars)) {
    if (chars[i] != "@") {
      i <- i + 1
      next
    }
    open <- i + 1
    while (open <= length(chars) && !chars[open] %in% c("{", "(")) open <- open + 1
    close <- matching_brace(chars, open)
    type <- trimws(paste(chars[(i + 1):(open - 1)], collapse = ""))
    if (!tolower(type) %in% c("comment", "preamble", "string")) {
      entry <- parse_bib_body(type, paste(chars[(open + 1):(close - 1)], collapse = ""))
      entry$raw <- paste(chars[i:close], collapse = "")
      entries[[entry$key]] <- entry
    }
    i <- close + 1
  }
  entries
}

# Position of the brace (or parenthesis) closing the one at `open`.
matching_brace <- function(chars, open) {
  closer <- if (chars[open] == "(") ")" else "}"
  depth <- 0
  for (k in open:length(chars)) {
    if (chars[k] == chars[open]) depth <- depth + 1
    if (chars[k] == closer) depth <- depth - 1
    if (depth == 0) {
      return(k)
    }
  }
  abort_export("powerkit's reference list (refs.bib) has an entry with unbalanced braces.")
}

parse_bib_body <- function(type, body) {
  chars <- strsplit(body, "")[[1]]
  comma <- match(",", chars)
  key <- trimws(paste(chars[seq_len((comma %|NA|% (length(chars) + 1)) - 1)], collapse = ""))
  fields <- list()
  i <- (comma %|NA|% length(chars)) + 1
  while (i <= length(chars)) {
    while (i <= length(chars) && grepl("[[:space:],]", chars[i])) i <- i + 1
    if (i > length(chars)) break
    eq <- i
    while (eq <= length(chars) && chars[eq] != "=") eq <- eq + 1
    if (eq > length(chars)) break
    name <- tolower(trimws(paste(chars[i:(eq - 1)], collapse = "")))
    j <- eq + 1
    while (j <= length(chars) && grepl("[[:space:]]", chars[j])) j <- j + 1
    if (chars[j] == "{") {
      end <- matching_brace(chars, j)
      value <- paste(chars[seq_len(end - j - 1) + j], collapse = "")
    } else if (chars[j] == "\"") {
      end <- j + 1
      while (end <= length(chars) && chars[end] != "\"") end <- end + 1
      value <- paste(chars[seq_len(end - j - 1) + j], collapse = "")
    } else {
      end <- j
      while (end <= length(chars) && chars[end] != ",") end <- end + 1
      value <- trimws(paste(chars[j:(end - 1)], collapse = ""))
      end <- end - 1
    }
    fields[[name]] <- gsub("\\s+", " ", trimws(value))
    i <- end + 1
  }
  list(type = type, key = key, fields = fields)
}

`%|NA|%` <- function(x, y) if (is.na(x)) y else x
