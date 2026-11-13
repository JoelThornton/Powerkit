# A zip holding the given files (names may have folders), for testing
# the zip readers.
make_zip <- function(files) {
  dir <- tempfile(); dir.create(dir)
  for (name in names(files)) {
    dir.create(dirname(file.path(dir, name)), showWarnings = FALSE, recursive = TRUE)
    writeLines(files[[name]], file.path(dir, name))
  }
  out <- tempfile(fileext = ".zip")
  zip::zip(out, files = names(files), root = dir, mode = "mirror")
  out
}
