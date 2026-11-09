# Packages that only some designs need are in Suggests, not Imports, so
# installing powerkit doesn't install every backend (CRAN's guidance for
# packages with many dependencies). Each entry point checks the packages a
# run needs before it calls any of them, and a missing one stops the run
# with a plain message naming what to install. The online app installs
# them all (app/routing/optional-packages.R).

# The packages in powerkit's Suggests, read from its installed DESCRIPTION
# so there is one list.
optional_packages <- function() {
  field <- utils::packageDescription("powerkit", fields = "Suggests")
  if (is.null(field) || is.na(field)) {
    return(character())
  }
  trimws(sub("\\(.*", "", strsplit(gsub("\n", " ", field), ",")[[1]]))
}

# Is a package installed? A wrapper, so tests can pretend one is missing.
package_installed <- function(package) {
  requireNamespace(package, quietly = TRUE)
}

# Stop with a plain message when any of `packages` isn't installed.
need_packages <- function(packages) {
  packages <- unique(setdiff(packages[!is.na(packages)], "powerkit"))
  missing <- packages[!vapply(packages, package_installed, logical(1))]
  if (length(missing) == 0) {
    return(invisible(TRUE))
  }
  abort_run(missing_packages_message(missing), class = "powerkit_missing_package")
}

missing_packages_message <- function(missing) {
  quoted <- paste0("\"", missing, "\"")
  sprintf(
    "This analysis needs the R %s %s, which %s installed. Install %s with install.packages(%s), then run it again.",
    if (length(missing) == 1) "package" else "packages",
    quote_list(missing, "and"),
    if (length(missing) == 1) "isn't" else "aren't",
    if (length(missing) == 1) "it" else "them",
    if (length(missing) == 1) quoted else paste0("c(", paste(quoted, collapse = ", "), ")")
  )
}
