# Fixes for the flags raised by docs/walkthroughs.md (F1, F2, F3, F5, F9,
# F13, F14): the guided route uses the screening answers, the end-point
# list fits them, and user-facing text has no internal references.

once_score <- list(outcome = "score", times = "once")
twice_score <- list(outcome = "score", times = "twice")
var <- function(id) Filter(function(v) v$id == id, tree$guided$variables)[[1]]
compare <- analysis_by_id(tree, "compare")
guided <- function(ctx, ...) guided_answers(tree, utils::modifyList(list(x = "cond2", outcome = "score", mediators = "none", moderator = "none", covariate = "none"), list(...)), ctx)

test_that("F1: after 'Twice', the guided route offers the same people in two conditions and reaches the paired tests", {
  expect_false("within2" %in% names(guided_options(var("x"), once_score)))
  expect_true("within2" %in% names(guided_options(var("x"), twice_score)))
  expect_identical(resolve_analysis(tree, compare, guided(twice_score, x = "within2"))$endpoint, "E3")
  twice_yesno <- list(outcome = "yesno", times = "twice")
  expect_identical(resolve_analysis(tree, compare, guided(twice_yesno, x = "within2", outcome = "yesno"))$endpoint, "E26")
  # Two groups, each measured twice: the pre-post question, never E2.
  res <- resolve_analysis(tree, compare, guided(twice_score))
  expect_setequal(vapply(res$ask$options, function(o) o$endpoint, character(1)), c("E23", "E8"))
  for (x in c("cond2", "within2", "cond3", "score")) {
    for (outcome in c("score", "yesno", "categories")) {
      ctx <- list(outcome = if (outcome == "score") "score" else "yesno", times = "twice")
      res <- resolve_analysis(tree, compare, guided(ctx, x = x, outcome = outcome))
      ends <- c(res$endpoint, vapply(res$ask$options %||% list(), function(o) o$endpoint, character(1)))
      expect_false(any(ends %in% c("E1", "E2", "E4", "E5", "E6", "E7")), label = paste(x, outcome))
    }
  }
})

test_that("F2: the guided route offers an outcome with several categories, which reaches E6", {
  expect_setequal(names(guided_options(var("outcome"), list(outcome = "yesno", times = "once"))), c("yesno", "categories", "notsure"))
  expect_setequal(names(guided_options(var("outcome"), once_score)), c("score", "notsure"))
  yesno_once <- list(outcome = "yesno", times = "once")
  expect_identical(resolve_analysis(tree, compare, guided(yesno_once, outcome = "categories"))$endpoint, "E6")
  expect_identical(resolve_analysis(tree, compare, guided(yesno_once, x = "cond3", outcome = "categories"))$endpoint, "E6")
})

test_that("F3: a yes/no outcome with two crossed factors reaches E47 in 'Help me choose' and in the guided route", {
  base <- c("Yes/no, or one of several categories", "Independent people", "Once", "Detect an effect", "A difference between groups or conditions")
  expect_identical(follow_answers(tree, c(base, "Two or more factors (e.g. a 2 x 2 design), yes/no outcome")), "E47")
  moderation <- analysis_by_id(tree, "moderation")
  expect_identical(resolve_analysis(tree, moderation, guided(list(outcome = "yesno", times = "once"), outcome = "yesno", moderator = "two"))$endpoint, "E47")
  html <- withr::with_options(list(powerkit.maintainer_view = TRUE), as.character(card_ui(tree, "E47")))
  # Named tools (setting name_other_tools, decided 22 October 2026).
  expect_match(html, "p_glm()", fixed = TRUE)
  expect_match(html, "Open question 18", fixed = TRUE)
  expect_null(tree$endpoints$E47$packages)
})

test_that("F5: the end-point list offers only the analyses that fit the screening answers", {
  shown <- function(ctx) endpoints_for_context(tree, ctx)
  once <- shown(once_score)
  expect_true(all(c("E1", "E2", "E4", "E7", "E-unsure", "E-bayes") %in% once))
  expect_false(any(c("E3", "E5", "E6", "E26", "E8") %in% once))
  twice <- shown(twice_score)
  expect_true(all(c("E3", "E8", "E23") %in% twice))
  expect_false(any(c("E1", "E2", "E4", "E5", "E7") %in% twice))
  yesno <- shown(list(outcome = "yesno", times = "once"))
  expect_true(all(c("E5", "E6", "E25", "E27", "E47") %in% yesno))
  expect_false(any(c("E1", "E2", "E3", "E4") %in% yesno))
  # Designs the screening sends elsewhere are never listed after it.
  for (ctx in list(once_score, twice_score, list(outcome = "score", times = "many_conditions"), list(outcome = "yesno", times = "twice"))) {
    expect_false(any(c("E28", "E29", "E33", "E34", "E35", "E43", "E44", "E45", "E46") %in% shown(ctx)))
  }
  html <- as.character(known_ui(tree, list(), twice_score))
  expect_match(html, "fit your screening answers", fixed = TRUE)
  expect_no_match(html, "ep:E2&#39;", fixed = TRUE)
  expect_match(html, "ep:E3&#39;", fixed = TRUE)
})

test_that("F9: the dyadic card says power can be overstated or understated, and why", {
  text <- tree$endpoints$E44$card_text
  expect_match(text, "overstate or understate", fixed = TRUE)
  expect_match(text, "between dyads", fixed = TRUE)
  expect_match(text, "within dyads", fixed = TRUE)
  expect_match(text, "dyadic methods are needed", fixed = TRUE)
})

test_that("F13: the equivalence card names non-inferiority", {
  expect_match(tree$endpoints$E36$plain_name, "non-inferiority", fixed = TRUE)
})

test_that("F14: user-facing text has no internal references", {
  texts <- character()
  for (n in tree$nodes) texts <- c(texts, n$text, n$help, unlist(lapply(n$options, function(o) c(o$label, o$help))))
  for (e in tree$endpoints) {
    texts <- c(texts, e$plain_name, e$card_text, e$card_heading, e$backend, e$method, e$coming_soon_note, e$validation$note,
      unlist(e$inputs), unlist(e$card_points), unlist(lapply(e$packages, function(p) p$what)))
  }
  for (q in tree$closing_questions) texts <- c(texts, q$text, q$note)
  g <- tree$guided
  texts <- c(texts, g$intro, g$scope_note, g$many_conditions_note, unlist(lapply(g$combination_rules, function(r) c(r$label, r$note))))
  for (a in g$analyses) for (rule in a$rules) if (!is.null(rule$ask)) texts <- c(texts, rule$ask$text)
  pattern <- "Departure [0-9]|decisions? [DN][0-9]|maintainer decision|[Pp]hase 3b|transcribed|docs/|decision-tree\\.md|judgement call|build guide"
  expect_identical(texts[grepl(pattern, texts)], character())
  html <- paste(vapply(names(tree$endpoints), function(id) {
    h <- as.character(card_ui(tree, id))
    gsub("<div class=\"placeholder[^\"]*\">.*?</div>", "", h)
  }, character(1)), collapse = "\n")
  expect_false(grepl("docs/coverage.md", html, fixed = TRUE))
})

test_that("the analyses screen has one choice per analysis and asks how main analyses combine only when there are two or more", {
  answers <- list()
  html <- as.character(guided_analyses_ui(tree, answers, character(), character(), list(), "each"))
  expect_no_match(html, "primary_", fixed = TRUE)
  expect_match(html, "value=\"main\"", fixed = TRUE)
  expect_match(html, "value=\"extra\"", fixed = TRUE)
  expect_match(html, "data-display-if=", fixed = TRUE)
  expect_match(html, ".length &gt;= 2", fixed = TRUE)
  expect_identical(analysis_role("a", character(), character()), "none")
  expect_identical(analysis_role("a", "a", character()), "extra")
  expect_identical(analysis_role("a", "a", "a"), "main")
})
