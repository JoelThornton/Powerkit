# Drafts store editable answers, never a calculation or evidence record.
# They are deliberately separate from engine project/plan files.
write_draft <- function(route, file) {
  route$form_values <- lapply(route$form_values, function(x) {
    if (is.null(x) || !length(x) || anyNA(x)) "" else as.character(x)
  })
  record <- list(format = "powerkit-draft", version = 1L,
    saved_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC"), route = route)
  jsonlite::write_json(record, file, auto_unbox = TRUE, pretty = TRUE, null = "null")
  invisible(record)
}

read_draft_record <- function(path) {
  if (!file.exists(path) || file.info(path)$size > 5e6) return(NULL)
  record <- tryCatch(jsonlite::read_json(path, simplifyVector = FALSE), error = function(e) NULL)
  if (!is.list(record) || !identical(record$format, "powerkit-draft")) NULL else record
}

restore_draft <- function(record, tree, forms) {
  bad <- "This draft cannot be reopened by this version of Powerkit."
  if (!is.list(record) || !identical(record$format, "powerkit-draft") || !identical(as.character(record$version), "1")) return(bad)
  route <- record$route
  if (!is.list(route) || !is.list(route$form_values) || (length(route$form_values) && is.null(names(route$form_values))) ||
      !is.list(route$start %||% list()) || !is.list(route$ctx %||% list()) || !is.list(route$history %||% list())) return(bad)
  k <- suppressWarnings(as.numeric(route$form_k %||% 2L))
  if (length(k) != 1 || !is.finite(k) || k < 1 || k > 100 || k != floor(k)) return(bad)
  route$form_k <- as.integer(k)
  values <- route$form_values
  for (id in names(values)) {
    x <- values[[id]]
    if (is.list(x)) {
      if (any(vapply(x, is.list, logical(1)))) return(bad)
      x <- unlist(x, use.names = FALSE)
    }
    if (length(x) > 10000 || !is.atomic(x)) return(bad)
    values[id] <- list(if (is.null(x) || !length(x) || anyNA(x)) "" else as.character(x))
  }
  route$form_values <- values
  restored <- tryCatch(restore_from_project(route, tree, forms), error = function(e) bad)
  if (is.character(restored)) return(restored)
  fields <- tryCatch(form_fields(form_groups(forms, restored$endpoint, restored$form_k, restored$start)), error = function(e) NULL)
  if (is.null(fields) || !all(names(values) %in% vapply(fields, `[[`, "", "id"))) return(bad)
  # Validate history structure before it can drive a Back action.
  if (length(restored$history) > 500 || any(!vapply(restored$history, function(h) {
    is.list(h) && is.character(h$node) && length(h$node) == 1 && h$node %in% names(tree$nodes) &&
      is.character(h$answer) && length(h$answer) == 1 && is.list(h$ctx %||% list())
  }, logical(1)))) return(bad)
  restored$calc <- NULL
  restored$long_spec <- NULL
  restored
}

draft_opened_ui <- function(saved_at) {
  div(class = "alert alert-info", role = "status",
    tags$strong("Unfinished draft opened. "),
    "Your editable answers were restored, including blanks. No calculated or validated result was restored. Complete or change the answers, then check them before calculating.",
    if (is.character(saved_at) && length(saved_at) == 1) p(class = "mb-0", "Draft saved ", saved_time_ui(saved_at), "."))
}

# When a draft was saved, in the visitor's own time and plain words
# ("today at 13:05"): the record holds UTC ("2026-11-07 13:05:16 UTC"),
# which the browser turns into local time. Without JavaScript the UTC
# time stays.
saved_time_ui <- function(saved_at) {
  when <- as.POSIXct(sub(" UTC$", "", saved_at), tz = "UTC", format = "%Y-%m-%d %H:%M:%S")
  if (is.na(when)) return(saved_at)
  tagList(tags$time(class = "pk-local-time", datetime = format(when, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      paste("on", format(when, "%d %B %Y at %H:%M UTC", tz = "UTC"))),
    tags$script(HTML("(function() {
  document.querySelectorAll('time.pk-local-time:not([data-done])').forEach(function(el) {
    var t = new Date(el.getAttribute('datetime')); if (isNaN(t)) return;
    var day = function(d) { return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime(); };
    var diff = Math.round((day(new Date()) - day(t)) / 86400000);
    var clock = t.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'});
    var date = diff === 0 ? 'today' : diff === 1 ? 'yesterday' : 'on ' + t.toLocaleDateString([], {day: 'numeric', month: 'long'});
    el.textContent = date + ' at ' + clock; el.setAttribute('data-done', '1');
  });
})();")))
}

# The offer to continue an unfinished plan, on the plan tab's first
# screen only (it covered every tab as a dialog until 7 November 2026).
# "Not now" keeps the draft; only "Discard my draft" deletes it.
draft_offer_ui <- function(name, saved_at) {
  div(class = "draft-offer", role = "region", `aria-labelledby` = "draft_offer_title",
    h3(id = "draft_offer_title", class = "h5", "Continue your unfinished plan?"),
    p(sprintf("You were filling in \"%s\", saved ", name), saved_time_ui(saved_at),
      ". Your answers are kept in this browser."),
    div(class = "draft-offer-actions",
      actionButton("pk_restore_yes", "Continue my plan", class = "btn-primary"),
      actionButton("pk_restore_later", "Not now", class = "btn-outline-secondary"),
      actionButton("pk_restore_no", "Discard my draft", class = "btn-outline-danger")))
}

# --- The guided plan ("Plan my whole study") --------------------------------------

# "Save this plan": the variables, the analyses and their roles, the claim,
# the values entered on each analysis's input screen (with the sample sizes
# found there) and the whole-study simulation's inputs. Like a draft it
# holds answers, not a result: reopening puts the plan back on its screen,
# and a calculation is run again from the same values and seed (8 November
# 2026). The whole-study spec of the last run is kept for its R script.
guided_plan_fields <- c("route", "start", "ctx", "answers", "ticked", "primary", "asks", "rule",
  "plan_values", "plan_shared", "plan_results", "ws_values", "ws_names", "ws_spec")

write_guided_plan <- function(state, file) {
  plan <- state[guided_plan_fields]
  names(plan) <- guided_plan_fields
  plan$history <- lapply(state$history, function(h) list(node = h$node, answer = h$answer, ctx = h$ctx))
  record <- list(format = "powerkit-guided-plan", version = 1L,
    saved_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC"),
    powerkit_version = powerkit_version(), plan = plan)
  jsonlite::write_json(record, file, auto_unbox = TRUE, pretty = TRUE, null = "null", digits = NA)
  invisible(record)
}

read_guided_plan_record <- function(path) {
  if (!file.exists(path) || file.info(path)$size > 5e6) return(NULL)
  record <- tryCatch(jsonlite::read_json(path, simplifyVector = FALSE), error = function(e) NULL)
  if (!is.list(record) || !identical(record$format, "powerkit-guided-plan")) NULL else record
}

# What to put back into the app's state, or a plain-English problem.
restore_guided_plan <- function(record, tree) {
  bad <- "This plan cannot be reopened by this version of Powerkit."
  if (!identical(as.character(record$version), "1") || !is.list(record$plan)) return(bad)
  p <- record$plan
  chars <- function(x) as.character(unlist(x %||% list(), use.names = FALSE))
  g <- tree$guided
  variables <- stats::setNames(lapply(g$variables, function(v) names(v$options)), vapply(g$variables, `[[`, "", "id"))
  answers <- lapply(p$answers %||% list(), function(x) chars(x))
  if (!all(names(answers) %in% names(variables)) ||
      !all(vapply(names(answers), function(k) length(answers[[k]]) == 1 && answers[[k]] %in% variables[[k]], logical(1)))) return(bad)
  ids <- vapply(g$analyses, `[[`, "", "id")
  ticked <- chars(p$ticked)
  primary <- chars(p$primary)
  rules <- vapply(g$combination_rules, `[[`, "", "id")
  rule <- chars(p$rule %||% "each")
  if (!all(ticked %in% ids) || !all(primary %in% ticked) || length(rule) != 1 || !rule %in% rules) return(bad)
  history <- p$history %||% list()
  if (length(history) > 500 || any(!vapply(history, function(h) {
    is.list(h) && length(chars(h$node)) == 1 && chars(h$node) %in% names(tree$nodes) &&
      length(chars(h$answer)) == 1 && is.list(h$ctx %||% list())
  }, logical(1)))) return(bad)
  history <- lapply(history, function(h) list(node = chars(h$node), answer = chars(h$answer), ctx = h$ctx %||% list()))
  values_of <- function(x) lapply(x %||% list(), function(v) lapply(v, function(y) if (is.list(y)) chars(y) else y))
  list(
    screen = "g_plan", route = chars(p$route %||% "plan"), start = p$start %||% list(), ctx = p$ctx %||% list(),
    history = history, answers = answers, ticked = ticked, primary = primary,
    asks = lapply(p$asks %||% list(), chars), rule = rule,
    plan_values = lapply(values_of(p$plan_values), legacy_claim_values), plan_shared = p$plan_shared %||% list(),
    plan_results = p$plan_results %||% list(), ws_values = lapply(p$ws_values %||% list(), function(y) if (is.list(y)) lapply(y, chars) else y),
    ws_names = lapply(p$ws_names %||% list(), chars), ws_spec = p$ws_spec,
    plan_id = NULL, endpoint = NULL, came_from = NULL, calc = NULL, long_spec = NULL, ws_calc = NULL
  )
}

guided_plan_opened_ui <- function(record) {
  div(class = "alert alert-info", role = "status",
    tags$strong("Plan opened. "),
    "Your variables, analyses, claim and the values you entered were restored. Sample sizes found earlier are shown; open an analysis and check your answers to calculate it again, or run the whole-study simulation again (the same seed gives the same numbers).",
    if (is.character(record$saved_at) && length(record$saved_at) == 1) p(class = "mb-0", "Plan saved ", saved_time_ui(record$saved_at),
      if (is.character(record$powerkit_version)) sprintf(" with powerkit %s.", record$powerkit_version) else "."))
}

guided_plan_save_ui <- function(k = 0) {
  div(class = "plan-save mt-3",
    div(class = "nav-buttons",
      download_button("download_guided_plan", "Save this plan", class = "btn btn-outline-primary"),
      share_link_ui("guided_plan"),
      if (k > 0) actionLink("plan_view", sprintf("See your study plan (%d %s)", k, if (k == 1) "analysis" else "analyses"))),
    if (k > 0) p(class = "small mt-1", "Each analysis you calculate from this plan is also in your study plan, which collects analyses from any card and saves their results in one file."),
    p(class = "text-muted small mt-1", "A file on your computer: open it later on the start screen, under “Open a saved or shared project”, to carry on where you left off. Copy a link puts the same inside a link that opens it on any computer; powerkit stores nothing, so anyone with the link can open it."))
}

# A whole-study specification downloaded from the simulation's result is
# for R, not for reopening here: say so in plain words.
whole_study_spec_file <- function(path) {
  if (!file.exists(path) || file.info(path)$size > 5e6) return(FALSE)
  spec <- tryCatch(jsonlite::read_json(path, simplifyVector = FALSE), error = function(e) NULL)
  is.list(spec) && identical(spec$kind, "whole_study")
}
whole_study_spec_message <- "This is a whole-study specification: it runs in R with powerkit's run_whole_study(), or with the R script under “Write it up and save it”. To carry on with the plan here, use “Save this plan” and open that file."
