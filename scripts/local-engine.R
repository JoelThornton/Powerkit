# Decide without loading powerkit: loading an installed old namespace while
# checking it would leave that code in use after the files are replaced.
powerkit_local_engine_action <- function(stamp_file, stamp,
  installed_path = find.package("powerkit", quiet = TRUE),
  loaded = isNamespaceLoaded("powerkit")) {
  matches <- length(installed_path) > 0 && file.exists(stamp_file) &&
    identical(readLines(stamp_file, warn = FALSE), stamp)
  if (matches) return("reuse")
  if (loaded) return("restart")
  "install"
}
