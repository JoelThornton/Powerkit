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
    history = history_to(c("A score or scale", "Independent people", "Once", "Detect an effect")),
    route_label = "Plan my whole study", raw_answers = answers))
  expect_match(plan, "Something doesn", fixed = TRUE)
  expect_match(plan, "Main predictor (X): A condition with two groups", fixed = TRUE)
  expect_match(plan, "Analysis: ", fixed = TRUE)
})

test_that("nothing is sent anywhere: no network calls in the app", {
  files <- c(file.path(routing_dir, "app.R"), list.files(file.path(routing_dir, "R"), full.names = TRUE))
  code <- paste(unlist(lapply(files, readLines)), collapse = "\n")
  for (pattern in c("fetch(", "XMLHttpRequest", "sendBeacon", "httr", "curl::", "download.file", "url(", "mailto:", "smtp")) {
    expect_false(grepl(pattern, code, fixed = TRUE), label = pattern)
  }
})
