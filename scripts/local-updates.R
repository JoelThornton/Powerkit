# Read-only, explicit update discovery for a downloaded app. Never installs,
# sources downloaded R, overwrites a project or changes the active library.
powerkit_release_update <- function(releases, current) {
  usable <- Filter(function(x) !isTRUE(x$draft) &&
    is.character(x$tag_name) && length(x$tag_name) == 1 &&
    grepl("^v[0-9]+\\.[0-9]+\\.[0-9]+$", x$tag_name), releases)
  if (!length(usable)) stop("No numbered Powerkit release was found.", call. = FALSE)
  versions <- vapply(usable, function(x) sub("^v", "", x$tag_name), "")
  index <- order(numeric_version(versions), decreasing = TRUE)[1]
  release <- usable[[index]]
  list(current = current, latest = versions[index],
    newer = numeric_version(versions[index]) > numeric_version(current),
    prerelease = isTRUE(release$prerelease),
    url = paste0("https://github.com/JoelThornton/Powerkit/releases/tag/", release$tag_name))
}

powerkit_check_updates <- function(root, fetch = function() {
  path <- tempfile(fileext = ".json")
  on.exit(unlink(path))
  old <- options(timeout = 10)
  on.exit(options(old), add = TRUE)
  utils::download.file("https://api.github.com/repos/JoelThornton/Powerkit/releases?per_page=100",
    path, quiet = TRUE, mode = "wb")
  jsonlite::read_json(path, simplifyVector = FALSE)
}) {
  current <- unname(read.dcf(file.path(root, "engine", "DESCRIPTION"), fields = "Version")[1, 1])
  tryCatch({
    update <- powerkit_release_update(fetch(), current)
    message(if (update$newer) paste0("A newer Powerkit release is available: ", update$latest)
      else paste0("No newer numbered release was found (this folder: ", current, ")."))
    if (update$prerelease) message("The listed release is a development pre-release; it is not a validated production release.")
    message(update$url)
    message("Nothing was installed or changed. Save your study, stop Powerkit and follow the download guide if you choose to update.")
    invisible(update)
  }, error = function(e) {
    message("Couldn't check Powerkit updates. Your installed app still works offline. Try again later or visit https://github.com/JoelThornton/Powerkit/releases")
    invisible(NULL)
  })
}
