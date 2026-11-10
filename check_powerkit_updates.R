# Optional, read-only update check. Run after stopping the local app:
# source("check_powerkit_updates.R")
local({
  root <- getwd()
  for (i in rev(seq_len(sys.nframe()))) {
    f <- sys.frame(i)$ofile
    if (!is.null(f)) { root <- dirname(normalizePath(f)); break }
  }
  source(file.path(root, "scripts", "local-updates.R"), local = TRUE)
  powerkit_check_updates(root)
})
