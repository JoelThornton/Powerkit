# The app's only route to the engine. Every power value the app shows comes
# from powerkit::run_spec(); this file loads the engine and turns its
# conditions into plain English for the UI.

# Load powerkit from this repository's engine/ folder (so the app always
# uses the engine in the same checkout), or the installed package if the
# folder isn't there.
load_engine <- function(engine_dir = file.path("..", "engine")) {
  if (file.exists(file.path(engine_dir, "DESCRIPTION")) &&
    requireNamespace("pkgload", quietly = TRUE)) {
    suppressMessages(pkgload::load_all(
      engine_dir,
      export_all = FALSE, helpers = FALSE, attach_testthat = FALSE, quiet = TRUE
    ))
  } else if (requireNamespace("powerkit", quietly = TRUE)) {
    suppressMessages(library(powerkit))
  } else {
    stop(
      "Couldn't find the powerkit engine. Open Powerkit.Rproj and run ",
      "the app from the project (source(\"run_app.R\")).",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

# Evaluate an engine call. Returns a list:
#   ok        TRUE if the call succeeded;
#   value     its value (NULL on failure);
#   problems  plain-English problems (the validator's own messages);
#   advice    the engine's advice warnings (class powerkit_spec_warning).
# Other warnings (e.g. deprecation notices from backend packages) are not
# meant for users and are dropped. Unexpected errors are logged to the
# console and shown as a plain message, never as a stack trace.
engine_call <- function(expr) {
  advice <- character()
  outcome <- withCallingHandlers(
    tryCatch(
      list(ok = TRUE, value = expr, problems = character()),
      powerkit_spec_error = function(e) {
        list(ok = FALSE, value = NULL, problems = e$problems)
      },
      powerkit_error = function(e) {
        list(ok = FALSE, value = NULL, problems = conditionMessage(e))
      },
      error = function(e) {
        cat("powerkit app: unexpected error:", conditionMessage(e), "\n", file = stderr())
        list(ok = FALSE, value = NULL, problems = paste(
          "Something went wrong inside the app, so nothing was calculated.",
          "Please note what you entered and report it."
        ))
      }
    ),
    powerkit_spec_warning = function(w) {
      advice <<- c(advice, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    warning = function(w) invokeRestart("muffleWarning")
  )
  outcome$advice <- unique(advice)
  outcome
}

# All of the validator's messages, in the form's terms. "Repeated entries"
# for a factor whose level names are still blank is dropped: the blank
# names are already reported.
friendly_problems <- function(problems, spec) {
  for (role in c("A", "B")) {
    levels <- unlist(spec$variables[[role]]$levels)
    if (any(!nzchar(levels))) {
      problems <- problems[!startsWith(problems, sprintf("'variables > %s > levels' has repeated entries", role))]
    }
  }
  vapply(problems, friendly_problem, character(1), spec = spec, USE.NAMES = FALSE)
}

# Rewrite the spec field names in the validator's messages as the labels on
# the form, e.g. "'population > sd'" -> "\"Standard deviation\"".
friendly_problem <- function(message, spec) {
  labels <- field_labels(spec)
  missing <- regmatches(message, regexec("^'([^']+)' is missing '([^']+)'\\.", message))[[1]]
  if (length(missing) == 3) {
    path <- paste(missing[2], missing[3], sep = " > ")
    if (!is.null(labels[[path]])) {
      return(sprintf("Please fill in \"%s\".", labels[[path]]))
    }
  }
  empty <- regmatches(message, regexec("^'([^']+)' should be a number, but it is empty \\(null\\)\\.$", message))[[1]]
  if (length(empty) == 2 && !is.null(labels[[empty[2]]])) {
    return(sprintf("Please fill in \"%s\".", labels[[empty[2]]]))
  }
  quoted <- regmatches(message, gregexpr("'[^']+'", message))[[1]]
  for (q in unique(quoted)) {
    label <- labels[[gsub("'", "", q)]]
    if (!is.null(label)) {
      message <- gsub(q, paste0("\"", label, "\""), message, fixed = TRUE)
    }
  }
  message
}

field_labels <- function(spec) {
  level <- function(role, i, fallback) {
    x <- tryCatch(spec$variables[[role]]$levels[[i]], error = function(e) NULL)
    if (is.character(x) && length(x) == 1 && nzchar(x)) x else fallback
  }
  labels <- list(
    "variables > A > label" = "Factor A name",
    "variables > A > levels" = "Factor A levels",
    "variables > A > levels > 0" = "Factor A, level 1",
    "variables > A > levels > 1" = "Factor A, level 2",
    "variables > B > label" = "Factor B name",
    "variables > B > levels" = "Factor B levels",
    "variables > B > levels > 0" = "Factor B, level 1",
    "variables > B > levels > 1" = "Factor B, level 2",
    "variables > Y > label" = "Outcome name",
    "population > sd" = "Standard deviation",
    "population > r" = "Correlation between the repeated measures",
    "target_test > alpha" = "Alpha",
    "target_test > effect" = "Effect to detect",
    "goal > power" = "Target power",
    "effect_justification > type" = "Where the effect size comes from",
    "effect_justification > source" = "Effect-size justification",
    "effect_justification > adjustment" = "Adjustment to the earlier estimate"
  )
  for (i in 0:1) {
    for (j in 0:1) {
      labels[[sprintf("population > means > %d > %d", i, j)]] <- sprintf(
        "Mean for %s, %s",
        level("A", i + 1, sprintf("A level %d", i + 1)),
        level("B", j + 1, sprintf("B level %d", j + 1))
      )
    }
  }
  labels
}
