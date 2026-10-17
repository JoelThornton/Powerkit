# "Something doesn't fit": on every card, the exact path the user took, as
# text they can copy, with a prompt asking what they expected instead.
# Everything stays in the browser: nothing is sent anywhere.

feedback_prompt <- "What did you expect instead? Copy the path below, add a sentence on what you expected, and send it to whoever asked you to try the prototype. Nothing is sent from this page."

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
    tags$button(type = "button", class = "btn btn-outline-primary", onclick = sprintf("pkCopy('%s')", id), "Copy the path"),
    div(id = paste0(id, "-status"), class = "copy-status", `aria-live` = "polite")
  )
}
