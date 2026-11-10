# Decide without loading powerkit: loading an installed old namespace while
# checking it would leave that code in use after the files are replaced.
powerkit_local_engine_action <- function(stamp_file, stamp,
  installed_path = find.package("powerkit", quiet = TRUE),
  loaded = isNamespaceLoaded("powerkit"),
  loaded_path = if (loaded) getNamespaceInfo(getNamespace("powerkit"), "path") else NULL) {
  matches <- length(installed_path) > 0 && file.exists(stamp_file) &&
    identical(readLines(stamp_file, warn = FALSE), stamp)
  same_path <- function(a, b) identical(
    normalizePath(a, winslash = "/", mustWork = FALSE),
    normalizePath(b, winslash = "/", mustWork = FALSE))
  # Another downloaded version may already have loaded its namespace,
  # even if this folder's installed files and stamp are up to date.
  if (loaded && !same_path(loaded_path, dirname(stamp_file))) return("restart")
  if (matches) return("reuse")
  if (loaded) return("restart")
  "install"
}
