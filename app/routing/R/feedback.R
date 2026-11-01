# Feedback: the Feedback tab (bug reports, questions, suggestions) and, on
# every card, "Something doesn't fit", the exact path the user took as text
# they can copy. The Feedback tab's Send button stores the message in
# powerkit's feedback database (send_feedback()); it is the only thing the
# app ever sends, and only when the user clicks it. The other buttons open
# a GitHub issue or the user's email program, or copy the message.

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

# Where feedback goes (tree.yaml, `feedback`). Each setting can come from
# the environment instead: POWERKIT_FEEDBACK_EMAIL, POWERKIT_FEEDBACK_URL
# and POWERKIT_FEEDBACK_KEY (the database's address and publishable key).
feedback_config <- function(tree) {
  cfg <- tree$feedback %||% list()
  from_env <- c(email = "POWERKIT_FEEDBACK_EMAIL", database_url = "POWERKIT_FEEDBACK_URL", database_key = "POWERKIT_FEEDBACK_KEY")
  for (k in names(from_env)) {
    value <- Sys.getenv(from_env[[k]])
    if (nzchar(value)) cfg[[k]] <- value
    if (!is.null(cfg[[k]]) && !nzchar(cfg[[k]])) cfg[[k]] <- NULL
  }
  cfg
}

can_send_feedback <- function(cfg) !is.null(cfg$database_url) && !is.null(cfg$database_key)

# Store one message in the feedback database: a POST to its
# send_powerkit_feedback() function (Supabase's REST interface), which
# checks the kind and length, caps how many arrive in an hour, and
# returns "ok", "empty", "bad" or "busy". Anything else (no connection, a
# server error) comes back as "error". Nobody can read the messages with
# the publishable key; only the database's owner can.
send_feedback <- function(cfg, kind, message, context = character(), contact = "", meta = list(),
                          timeout = 5) {
  if (!can_send_feedback(cfg)) return("error")
  body <- jsonlite::toJSON(list(
    p_kind = kind, p_message = message, p_context = paste(context, collapse = "\n"),
    p_contact = contact %||% "", p_meta = meta
  ), auto_unbox = TRUE, null = "null")
  handle <- curl::new_handle(customrequest = "POST", postfields = as.character(body), timeout = timeout)
  headers <- list(apikey = cfg$database_key, `Content-Type` = "application/json")
  # Older Supabase keys are JWTs and also go in the Authorization header.
  if (startsWith(cfg$database_key, "eyJ")) headers$Authorization <- paste("Bearer", cfg$database_key)
  do.call(curl::handle_setheaders, c(list(handle), headers))
  target <- paste0(sub("/+$", "", cfg$database_url), "/rest/v1/rpc/send_powerkit_feedback")
  tryCatch({
    res <- curl::curl_fetch_memory(target, handle = handle)
    if (res$status_code != 200) return("error")
    answer <- jsonlite::fromJSON(rawToChar(res$content))
    if (is.character(answer) && length(answer) == 1) answer else "error"
  }, error = function(e) "error")
}

# What the user sees after clicking Send.
feedback_result_message <- function(result) {
  switch(result,
    ok = "Thank you: your message has been sent.",
    empty = "Write a few words first.",
    busy = "A lot of messages have arrived in the last hour, so this one wasn't stored. Please copy it and try again later.",
    limit = "You've sent several messages already. Please copy this one and send it another way.",
    "It couldn't be sent just now. Please try again, or copy it and send it another way."
  )
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
  # One card: what it's about (as buttons), the message, then sending. The
  # exact text that will be sent is a click away.
  tagList(
    h2("Feedback, questions and problems"),
    p(class = "lead feedback-lead", "Found a mistake, got stuck, or have an idea? \"I didn't understand this screen\" is as useful as a bug report."),
    div(class = "result-card feedback-card",
      div(class = "feedback-kinds",
        radioButtons("fb_kind", "What is it about?", choices = stats::setNames(names(feedback_kinds), unname(feedback_kinds)), selected = "bug", width = "100%")),
      textAreaInput("fb_message", "Your message", rows = 6, width = "100%",
        placeholder = "What happened, what you expected, and the numbers you entered if it's about a result."),
      textInput("fb_contact", "Your email, if you'd like a reply (optional)", width = "100%"),
      checkboxInput("fb_include_path", "Include where I am in powerkit (the questions I answered and the analysis I reached)", value = TRUE, width = "100%"),
      tags$details(class = "result-more feedback-preview",
        tags$summary("See exactly what you'll send"),
        div(class = "form-field",
          tags$label(`for` = "fb-preview", class = "control-label visually-hidden", "What you'll send"),
          uiOutput("fb_preview"))),
      div(class = "nav-buttons feedback-send",
        if (can_send_feedback(cfg)) actionButton("fb_send", "Send", class = "btn btn-primary"),
        if (!is.null(cfg$email)) tags$button(type = "button", class = if (can_send_feedback(cfg)) "btn btn-outline-primary" else "btn btn-primary",
          onclick = "pkSendFeedback('email')", `data-address` = cfg$email, id = "fb-email", "Email it"),
        if (!is.null(cfg$issues_url)) tags$button(type = "button", class = if (is.null(cfg$email) && !can_send_feedback(cfg)) "btn btn-primary" else "btn btn-outline-primary",
          onclick = "pkSendFeedback('github')", `data-target` = cfg$issues_url, id = "fb-github", "Post it on GitHub"),
        tags$button(type = "button", class = "btn btn-outline-primary", onclick = "pkSendFeedback('copy')", "Copy it")),
      div(id = "fb-status", class = "copy-status", `aria-live` = "polite"),
      if (can_send_feedback(cfg)) p(class = "hint", "Send stores the message, and your email if you give one, ",
        "in powerkit's feedback database, which only the developer can read. Nothing else you enter in powerkit is sent. ",
        "Please don't include anything that could identify a participant.",
        if (!is.null(cfg$issues_url)) " Posts on GitHub are public and need a free account.")
      else p(class = "hint", "Nothing is sent from this page. Each button opens your message, filled in, for you to check and send yourself. ",
        "Please don't include anything that could identify a participant.",
        if (!is.null(cfg$issues_url)) " Posts on GitHub are public and need a free account."))
  )
}

# The preview, redrawn as the user types; the buttons send exactly this.
feedback_preview_ui <- function(subject, text) {
  tags$textarea(id = "fb-preview", class = "form-control mismatch-text", rows = 10, readonly = NA, `data-subject` = subject, text)
}

# In the browser: open the user's email program or a new GitHub issue with
# the preview's text, or copy it. Nothing is sent by the app.
feedback_js <- "
  Shiny.addCustomMessageHandler('fb_status', function(text) {
    var status = document.getElementById('fb-status');
    if (status) status.textContent = text;
  });
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
