# Feedback: the Feedback tab (bug reports, questions, suggestions) and, on
# every card, "Something doesn't fit", the exact path the user took as text
# they can copy. The app itself sends nothing: the Feedback tab's buttons
# open the user's own email program or a GitHub issue with the message
# filled in, and the user sends it.

feedback_prompt <- "What did you expect instead? Tell us on the Feedback tab: it adds the path you took for you. Or copy the path below and paste it into an email."

# The screening and "Help me choose" answers, one line per question.
path_lines <- function(tree, history) {
  vapply(history, function(h) sprintf("- %s %s", tree$nodes[[h$node]]$text, h$answer), character(1))
}

# The guided route's variable answers, one line per variable.
guided_lines <- function(tree, answers) {
  out <- character()
  for (v in tree$guided$variables) {
    a <- answers[[v$id]]
    if (is.null(a) || length(a) == 0) next
    labels <- vapply(a, function(x) v$options[[x]] %||% x, character(1))
    out <- c(out, sprintf("- %s: %s", v$label, paste(labels, collapse = "; ")))
  }
  out
}

# The whole path as text: route, answers, the end point reached, and a
# line for what the user expected instead.
path_text <- function(tree, route_label, history, ep_id, extra = character()) {
  ep <- tree$endpoints[[ep_id]]
  paste(c(
    "powerkit routing prototype: the path I took",
    "",
    paste0("Route: ", route_label),
    path_lines(tree, history),
    extra,
    sprintf("End point: %s, %s (%s)", ep_id, ep$plain_name, ep$doc_name),
    "",
    "What I expected instead:"
  ), collapse = "\n")
}

# The collapsible "Something doesn't fit?" block. `id` must be unique on
# the page. The copy button works in the browser only.
mismatch_ui <- function(id, text) {
  tags$details(
    class = "mismatch",
    tags$summary("Something doesn't fit?"),
    p(feedback_prompt),
    div(class = "form-field",
      tags$label(`for` = id, class = "control-label", "The path you took"),
      tags$textarea(id = id, class = "form-control mismatch-text", rows = 8, readonly = NA, text)
    ),
    div(class = "nav-buttons",
      tags$button(type = "button", class = "btn btn-primary", onclick = "Shiny.setInputValue('go_feedback', 'confusing', {priority: 'event'})", "Tell us on the Feedback tab"),
      tags$button(type = "button", class = "btn btn-outline-primary", onclick = sprintf("pkCopy('%s')", id), "Copy the path")),
    div(id = paste0(id, "-status"), class = "copy-status", `aria-live` = "polite")
  )
}

# The Feedback tab ----------------------------------------------------------

feedback_kinds <- c(
  bug = "Something looks wrong: an error, or a result I doubt",
  confusing = "Something was confusing, or didn't fit my study",
  question = "A question",
  idea = "A suggestion or a feature I'd like",
  other = "Another comment"
)

# Where feedback goes (tree.yaml, `feedback`). The email address can come
# from the environment instead, so it needn't be in the repository.
feedback_config <- function(tree) {
  cfg <- tree$feedback %||% list()
  email <- Sys.getenv("POWERKIT_FEEDBACK_EMAIL")
  if (nzchar(email)) cfg$email <- email
  if (!is.null(cfg$email) && !nzchar(cfg$email)) cfg$email <- NULL
  cfg
}

# The app's screens (app.R, state$screen) in words.
feedback_screen_label <- function(screen) {
  labels <- c(start = "The start questions", known = "I know my analysis: the list of analyses",
    node = "A question in the design finder", card = "An analysis card", form = "The input and result screen",
    g_vars = "Plan my whole study: the variables", g_analyses = "Plan my whole study: the analyses",
    g_plan = "Plan my whole study: the plan", check = "Checking a saved project")
  if (screen %in% names(labels)) labels[[screen]] else screen
}

# Where the user is in the app, for the message: the route, the answers
# given, the analysis reached and the values entered on its input screen
# (if any), and the app's last update.
feedback_context <- function(tree, screen, route_label = NULL, history = list(), endpoint = NULL,
                             values = list(), updated = NULL) {
  ep <- if (!is.null(endpoint)) tree$endpoints[[endpoint]]
  values <- Filter(function(v) length(v) > 0 && !is.list(v), values)
  c(
    if (!is.null(updated)) paste0("App last updated: ", updated),
    paste0("Screen: ", screen),
    if (!is.null(route_label)) paste0("Route: ", route_label),
    path_lines(tree, history),
    if (!is.null(ep)) sprintf("Analysis: %s, %s (%s)", endpoint, ep$plain_name, ep$doc_name),
    if (length(values)) c("Values entered:", sprintf("- %s: %s", names(values), vapply(values, feedback_value, character(1))))
  )
}

# One value as text, kept short so the message fits in a link (long
# reasoning text is cut).
feedback_value <- function(v) {
  text <- paste(v, collapse = ", ")
  if (nchar(text) > 200) paste0(substr(text, 1, 197), "...") else text
}

# The subject line and the whole message, as the user will send it.
feedback_subject <- function(kind, message) {
  first <- trimws(strsplit(message %||% "", "\n")[[1]][1] %||% "")
  if (is.na(first)) first <- ""
  if (nchar(first) > 60) first <- paste0(substr(first, 1, 57), "...")
  label <- c(bug = "Problem", confusing = "Confusing", question = "Question", idea = "Suggestion", other = "Comment")[[kind %||% "other"]]
  if (nzchar(first)) sprintf("powerkit feedback (%s): %s", label, first) else sprintf("powerkit feedback (%s)", label)
}

feedback_text <- function(kind, message, context = character()) {
  paste(c(
    paste0("Type: ", feedback_kinds[[kind %||% "other"]]),
    "",
    if (nzchar(trimws(message %||% ""))) message else "(No message written yet.)",
    if (length(context)) c("", "Where I was in powerkit:", context)
  ), collapse = "\n")
}

feedback_tab_ui <- function(tree) {
  cfg <- feedback_config(tree)
  tagList(
    h2("Feedback, questions and problems"),
    p("Found a mistake, got stuck, or have a question or an idea? Please say so: \"I didn't understand this screen\" ",
      "is as useful as a bug report. powerkit is still being built, and what you tell us decides what gets fixed first."),
    radioButtons("fb_kind", "What is it about?", choices = stats::setNames(names(feedback_kinds), unname(feedback_kinds)), selected = "bug", width = "100%"),
    textAreaInput("fb_message", "Your message", rows = 6, width = "100%",
      placeholder = "What happened, what you expected, and the numbers you entered if it's about a result."),
    checkboxInput("fb_include_path", "Include where I am in powerkit (the questions I answered and the analysis I reached)", value = TRUE, width = "100%"),
    div(class = "form-field",
      tags$label(`for` = "fb-preview", class = "control-label", "What you'll send"),
      uiOutput("fb_preview")),
    h3(class = "h5", "Send it"),
    p(class = "hint", "Nothing is sent from this page. Each button opens your message, filled in, for you to check and send yourself. ",
      "Please don't include anything that could identify a participant."),
    div(class = "nav-buttons",
      if (!is.null(cfg$email)) tags$button(type = "button", class = "btn btn-primary",
        onclick = "pkSendFeedback('email')", `data-address` = cfg$email, id = "fb-email", "Email it"),
      if (!is.null(cfg$issues_url)) tags$button(type = "button", class = if (is.null(cfg$email)) "btn btn-primary" else "btn btn-outline-primary",
        onclick = "pkSendFeedback('github')", `data-target` = cfg$issues_url, id = "fb-github", "Post it on GitHub"),
      tags$button(type = "button", class = "btn btn-outline-primary", onclick = "pkSendFeedback('copy')", "Copy it")),
    if (!is.null(cfg$issues_url)) p(class = "hint", "GitHub needs a free account, and posts there are public."),
    div(id = "fb-status", class = "copy-status", `aria-live` = "polite")
  )
}

# The preview, redrawn as the user types; the buttons send exactly this.
feedback_preview_ui <- function(subject, text) {
  tags$textarea(id = "fb-preview", class = "form-control mismatch-text", rows = 10, readonly = NA, `data-subject` = subject, text)
}

# In the browser: open the user's email program or a new GitHub issue with
# the preview's text, or copy it. Nothing is sent by the app.
feedback_js <- "
  window.pkSendFeedback = function(how) {
    var status = document.getElementById('fb-status');
    var say = function(msg) { if (status) status.textContent = msg; };
    var msg = document.getElementById('fb_message');
    var box = document.getElementById('fb-preview');
    if (!box) return;
    if (how !== 'copy' && msg && !msg.value.trim()) { say('Write your message first.'); if (msg) msg.focus(); return; }
    var subject = encodeURIComponent(box.getAttribute('data-subject') || 'powerkit feedback');
    var body = encodeURIComponent(box.value);
    if (how === 'email') {
      var address = document.getElementById('fb-email').getAttribute('data-address');
      window.location.href = 'mailto:' + address + '?subject=' + subject + '&body=' + body;
      say('Your email program should open with the message filled in. If it doesn\\'t, use Copy it and paste it into an email.');
    } else if (how === 'github') {
      var target = document.getElementById('fb-github').getAttribute('data-target');
      window.open(target + '?title=' + subject + '&body=' + body, '_blank', 'noopener');
      say('GitHub should open in a new tab with the message filled in. Check it and click Create.');
    } else {
      pkCopyText(box.value, status);
    }
  };
"
