# "Something doesn't fit": every card shows the path taken as copyable text,
# with a prompt; nothing is sent anywhere.

history_to <- function(labels) {
  # Follow the answers and record them as the app does.
  out <- list(); ctx <- list(); id <- start_node(tree)
  for (l in labels) {
    node <- tree$nodes[[id]]
    option <- Filter(function(o) identical(o$label, l), visible_options(tree, node, ctx))[[1]]
    out <- c(out, list(list(node = id, answer = l, ctx = ctx)))
    ctx <- apply_sets(ctx, option)
    id <- resolve_target(tree, option$`next`, ctx, "choose")
  }
  out
}

segmented <- c("A score or scale", "Independent people", "Many times",
  "Measurements over time, to see whether a trend changes at a known point")

test_that("the path text gives the route, every answer and the end point reached", {
  history <- history_to(segmented)
  text <- path_text(tree, "Help me choose", history, "E45")
  expect_match(text, "Route: Help me choose", fixed = TRUE)
  for (h in history) expect_match(text, paste0("- ", tree$nodes[[h$node]]$text, " ", h$answer), fixed = TRUE)
  expect_match(text, sprintf("End point: E45, %s (%s)", tree$endpoints$E45$plain_name, tree$endpoints$E45$doc_name), fixed = TRUE)
  expect_match(text, "What I expected instead:", fixed = TRUE)
})

test_that("every card can show the block, with the prompt, the text and a copy button", {
  for (id in names(tree$endpoints)) {
    html <- as.character(mismatch_ui("mismatch-path", path_text(tree, "Help me choose", list(), id)))
    expect_true(grepl("<summary>Something doesn't fit?</summary>", html, fixed = TRUE) || grepl("<summary>Something doesn&#39;t fit?</summary>", html, fixed = TRUE), label = id)
    expect_match(html, "What did you expect instead?", fixed = TRUE)
    expect_match(html, '<label for="mismatch-path" class="control-label">The path you took</label>', fixed = TRUE)
    expect_match(html, "readonly", fixed = TRUE)
    expect_true(grepl("pkCopy('mismatch-path')", html, fixed = TRUE) || grepl("pkCopy(&#39;mismatch-path&#39;)", html, fixed = TRUE))
    expect_match(html, htmltools::htmlEscape(sprintf("End point: %s,", id)), fixed = TRUE)
  }
})

test_that("the card screen and the guided plan include it", {
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, 'mismatch_ui("mismatch-path", path_text(', fixed = TRUE)
  answers <- list(x = "cond2", outcome = "score", mediators = "none", moderator = "none", covariate = "none")
  plan <- as.character(guided_plan_ui(tree, guided_answers(tree, answers), "compare", "compare", list(), "each",
    history = history_to(c("A score or scale", "Independent people", "Once")),
    route_label = "Plan my whole study", raw_answers = answers))
  expect_match(plan, "Something doesn", fixed = TRUE)
  expect_match(plan, "Main predictor (X): A condition with two groups", fixed = TRUE)
  expect_match(plan, "Analysis: ", fixed = TRUE)
})

test_that("the app sends nothing except a feedback message, when the user clicks Send", {
  files <- c(file.path(routing_dir, "app.R"), list.files(file.path(routing_dir, "R"), full.names = TRUE))
  code <- paste(unlist(lapply(files, readLines)), collapse = "\n")
  for (pattern in c("fetch(", "XMLHttpRequest", "sendBeacon", "httr", "download.file", "url(", "smtp")) {
    expect_false(grepl(pattern, code, fixed = TRUE), label = pattern)
  }
  # The only network call is in send_feedback(), and the only caller is
  # the Send button's observer.
  curl_files <- files[vapply(files, function(f) any(grepl("curl::", readLines(f), fixed = TRUE)), logical(1))]
  expect_identical(basename(curl_files), "feedback.R")
  body <- paste(deparse(send_feedback), collapse = "\n")
  expect_match(body, "curl_fetch_memory", fixed = TRUE)
  callers <- regmatches(code, gregexpr("send_feedback\\(feedback_config", code))[[1]]
  expect_length(callers, 1)
  expect_match(code, "observeEvent(input$fb_send,", fixed = TRUE)
  # The Feedback tab's only way out is a link the user opens and sends
  # themselves: their email program, or a new GitHub issue.
  mailto <- regmatches(code, gregexpr("mailto:", code, fixed = TRUE))[[1]]
  expect_length(mailto, 1)
  expect_match(feedback_js, "window.location.href = 'mailto:'", fixed = TRUE)
  expect_match(feedback_js, "window.open(target + '?title='", fixed = TRUE)
})

# The Feedback tab --------------------------------------------------------

test_that("the Feedback tab offers every kind of message, a preview and the ways to send it", {
  html <- as.character(feedback_tab_ui(tree))
  for (k in feedback_kinds) expect_match(html, htmltools::htmlEscape(k), fixed = TRUE)
  expect_match(html, 'id="fb_message"', fixed = TRUE)
  expect_match(html, 'id="fb_preview"', fixed = TRUE)
  expect_match(html, "Post it on GitHub", fixed = TRUE)
  expect_match(html, tree$feedback$issues_url, fixed = TRUE)
  expect_match(html, "Copy it", fixed = TRUE)
  expect_match(html, "identify a participant", fixed = TRUE)
  # With the database set (tree.yaml), Send comes first and says what it stores.
  expect_match(html, 'id="fb_send"', fixed = TRUE)
  expect_match(html, "which only the developer can read", fixed = TRUE)
  expect_match(html, 'id="fb_contact"', fixed = TRUE)
  # Without it, the tab says nothing is sent from the page.
  t2 <- tree; t2$feedback$database_url <- NULL
  withr::local_envvar(POWERKIT_FEEDBACK_URL = "")
  html2 <- as.character(feedback_tab_ui(t2))
  expect_false(grepl('id="fb_send"', html2, fixed = TRUE))
  expect_match(html2, "Nothing is sent from this page", fixed = TRUE)
})

test_that("Send posts the message to the feedback database's function and reports its answer", {
  skip_if_not_installed("callr")
  skip_if_not_installed("httpuv")
  port <- httpuv::randomPort()
  # A stand-in for the database: records each request, answers "ok".
  log <- tempfile(fileext = ".rds")
  server <- callr::r_bg(function(port, log) {
    seen <- list()
    s <- httpuv::startServer("127.0.0.1", port, list(call = function(req) {
      body <- rawToChar(req$rook.input$read())
      seen[[length(seen) + 1]] <<- list(path = req$PATH_INFO, apikey = req$HTTP_APIKEY, auth = req$HTTP_AUTHORIZATION, body = body)
      saveRDS(seen, log)
      list(status = 200L, headers = list(`Content-Type` = "application/json"), body = '"ok"')
    }))
    repeat httpuv::service(100)
  }, args = list(port = port, log = log))
  on.exit(server$kill(), add = TRUE)
  Sys.sleep(1.5)
  cfg <- list(database_url = sprintf("http://127.0.0.1:%d/", port), database_key = "sb_publishable_test")
  result <- send_feedback(cfg, "bug", "The N looks wrong", context = c("Screen: x", "Route: y"),
    contact = "me@example.org", meta = list(app_updated = "2026-10-22"))
  expect_identical(result, "ok")
  seen <- readRDS(log)
  expect_identical(seen[[1]]$path, "/rest/v1/rpc/send_powerkit_feedback")
  expect_identical(seen[[1]]$apikey, "sb_publishable_test")
  expect_null(seen[[1]]$auth)
  sent <- jsonlite::fromJSON(seen[[1]]$body)
  expect_identical(sent$p_kind, "bug")
  expect_identical(sent$p_message, "The N looks wrong")
  expect_identical(sent$p_context, "Screen: x\nRoute: y")
  expect_identical(sent$p_contact, "me@example.org")
  expect_identical(sent$p_meta$app_updated, "2026-10-22")
  # An old-style (JWT) key also goes in the Authorization header.
  send_feedback(modifyList(cfg, list(database_key = "eyJtest")), "idea", "An idea")
  expect_identical(readRDS(log)[[2]]$auth, "Bearer eyJtest")
})

test_that("Send fails gently: no database, or one that can't be reached", {
  expect_identical(send_feedback(list(), "bug", "hello"), "error")
  cfg <- list(database_url = sprintf("http://127.0.0.1:%d", httpuv::randomPort()), database_key = "k")
  expect_identical(send_feedback(cfg, "bug", "hello", timeout = 2), "error")
  for (r in c("ok", "empty", "busy", "limit", "error")) expect_true(nzchar(feedback_result_message(r)))
  expect_match(feedback_result_message("error"), "copy it", fixed = TRUE)
})

test_that("the email button appears only when an address is set, from tree.yaml or the environment", {
  withr::local_envvar(POWERKIT_FEEDBACK_EMAIL = "")
  t2 <- tree; t2$feedback$email <- NULL
  expect_false(grepl("Email it", as.character(feedback_tab_ui(t2)), fixed = TRUE))
  withr::local_envvar(POWERKIT_FEEDBACK_EMAIL = "feedback@example.org")
  html <- as.character(feedback_tab_ui(t2))
  expect_match(html, "Email it", fixed = TRUE)
  expect_match(html, 'data-address="feedback@example.org"', fixed = TRUE)
})

test_that("the message gives its type, the user's words and where they were", {
  history <- history_to(segmented)
  context <- feedback_context(tree, feedback_screen_label("form"), "Help me choose", history, "E2",
    values = list(d = "0.4", power = "0.8", empty = NULL), updated = "2026-10-22")
  text <- feedback_text("bug", "The N looks too small.", context)
  expect_match(text, "Type: Something looks wrong", fixed = TRUE)
  expect_match(text, "The N looks too small.", fixed = TRUE)
  expect_match(text, "Screen: The input and result screen", fixed = TRUE)
  expect_match(text, "Route: Help me choose", fixed = TRUE)
  expect_match(text, paste0("- ", tree$nodes[[history[[1]]$node]]$text), fixed = TRUE)
  expect_match(text, sprintf("Analysis: E2, %s", tree$endpoints$E2$plain_name), fixed = TRUE)
  expect_match(text, "- d: 0.4", fixed = TRUE)
  expect_false(grepl("empty", text, fixed = TRUE))
  expect_match(text, "App last updated: 2026-10-22", fixed = TRUE)
  # Without the context, and before anything is written.
  expect_false(grepl("Where I was", feedback_text("idea", "", character()), fixed = TRUE))
  expect_match(feedback_text("idea", "", character()), "(No message written yet.)", fixed = TRUE)
})

test_that("long values are cut, so the message fits in a link", {
  context <- feedback_context(tree, "x", values = list(reason = strrep("a", 1000)))
  expect_lt(max(nchar(context)), 220)
})

test_that("the subject names the kind and starts the message", {
  expect_identical(feedback_subject("question", ""), "powerkit feedback (Question)")
  expect_identical(feedback_subject("bug", "Wrong N\nmore"), "powerkit feedback (Problem): Wrong N")
  expect_lt(nchar(feedback_subject("idea", strrep("b", 200))), 100)
})

test_that("'Something doesn't fit?' leads to the Feedback tab", {
  html <- as.character(mismatch_ui("x", "path"))
  expect_match(html, "Tell us on the Feedback tab", fixed = TRUE)
  expect_match(html, "go_feedback", fixed = TRUE)
  code <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(code, 'tabPanel("Feedback", div(class = "pt-3", feedback_tab))', fixed = TRUE)
  expect_match(code, 'feedback_tab <- feedback_tab_ui(tree)', fixed = TRUE)
  expect_match(code, "observeEvent(input$go_feedback,", fixed = TRUE)
})

test_that("the Feedback tab keeps the exact message a click away and the reasons as buttons", {
  html <- as.character(feedback_tab_ui(tree))
  expect_match(html, "See exactly what you'll send", fixed = TRUE)
  expect_match(html, "feedback-kinds", fixed = TRUE)
  expect_match(html, "Posts on GitHub are public", fixed = TRUE)
})
