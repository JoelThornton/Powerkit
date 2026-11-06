# Reproducible locked dependency assessment; does not install/remove packages.
dependency_closure <- function(roots, packages) {
  seen <- character()
  todo <- intersect(roots, names(packages))
  while (length(todo)) {
    p <- todo[[1]]
    todo <- todo[-1]
    if (p %in% seen) next
    seen <- c(seen, p)
    todo <- unique(c(todo, intersect(unlist(packages[[p]]$Requirements), names(packages))))
  }
  sort(seen)
}

dependency_assessment <- function(root = ".") {
  lock_path <- file.path(root, "renv.lock")
  lock <- jsonlite::fromJSON(lock_path, simplifyVector = FALSE)$Packages
  desc <- read.dcf(file.path(root, "engine", "DESCRIPTION"))
  imports <- trimws(gsub("\\s*\\([^)]*\\)", "", unlist(strsplit(desc[1, "Imports"], ","))))
  manifest <- jsonlite::fromJSON(file.path(root, "app", "routing", "manifest.json"), simplifyVector = FALSE)
  profiles <- list("Full locked environment" = names(lock),
    "Current engine Imports and their locked dependencies" = dependency_closure(imports, lock),
    "Candidate formula-only roots (not an installable profile)" = dependency_closure(c("pwr", "pwrss", "digest", "jsonlite", "jsonvalidate"), lock))
  c("# Dependency and setup assessment", "", paste("Measured from renv.lock SHA-256", digest::digest(file = lock_path, algo = "sha256")), "",
    sprintf("The engine declares %d direct Imports; the deployment manifest contains %d packages. The lock includes development and validation tools as well as runtime dependencies.", length(imports), length(manifest$packages)), "",
    "| Scope | Locked packages in dependency closure |", "|---|---:|",
    vapply(names(profiles), function(n) sprintf("| %s | %d |", n, length(profiles[[n]])), ""), "",
    "These counts measure metadata reachability, not download bytes, installed disk size, startup time, redundancy or security risk. Shared transitive dependencies are counted once. Base R packages are outside the lock graph.", "",
    "## Recommendation", "",
    "Keep the complete locked environment for deployment and validation. A smaller optional basic-formula installation is worth prototyping separately, but is not currently supported: all engine Imports must load, so merely omitting packages breaks installation. Do not advertise a partial install command.", "",
    "A safe optional profile requires explicit backend capability metadata, moving truly optional packages from Imports to Suggests, guarded namespace access and clear unavailable-backend messages, plus isolated installation and script-export tests for each profile. Preserve the complete environment and numerical regression checks. Select a profile from actual requested analyses, not from package count alone.", "",
    "Browser-development tools and tests are excluded from the deployment bundle. Prefer that concrete reduction over deleting scientific fixtures or undocumented package removals. Installing the complete environment once and restarting without reinstalling is already covered on Windows and macOS.", "",
    "## Acceptance criteria before introducing optional profiles", "",
    "Measure cold install time, downloaded bytes, installed size and startup on clean supported Windows/macOS/Linux environments using the same R and lock versions. Record cache state, machine and uncertainty. Verify every advertised route, standalone script, saved-project restore, and an honest refusal for absent backends. A dependency closure estimate alone does not meet these criteria.")
}

if (!interactive() && sys.nframe() == 0) cat(dependency_assessment(), sep = "\n")
