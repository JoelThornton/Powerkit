# Every screen renders from the data file, shows the prototype banner, and
# the app never calls the engine or calculates power.

test_that("the banner says it's a prototype that calculates nothing", {
  expect_identical(tree$banner, "Prototype: shows which analysis you need; it doesn't calculate anything yet.")
  expect_match(as.character(prototype_banner(tree)), tree$banner, fixed = TRUE)
})

test_that("every end-point card renders, with its status and inputs", {
  for (id in names(tree$endpoints)) {
    html <- as.character(card_ui(tree, id))
    expect_match(html, htmltools::htmlEscape(tree$endpoints[[id]]$plain_name), fixed = TRUE, label = id)
    expect_match(html, "What you would enter", fixed = TRUE, label = id)
    expected <- switch(tree$endpoints[[id]]$status,
      runs_validated = "Runs in powerkit.", runs_not_yet_validated = "Runs in powerkit.",
      coming_soon = "Coming soon.", not_in_powerkit = "Not in powerkit yet: use")
    expect_match(html, expected, fixed = TRUE, label = id)
  }
})

test_that("validated cards link to the validation log", {
  html <- as.character(card_ui(tree, "E7"))
  expect_match(html, tree$links$validation_log, fixed = TRUE)
})

test_that("every question screen renders with a back button", {
  for (id in names(tree$nodes)) {
    html <- as.character(node_ui(tree, id, list()))
    expect_match(html, htmltools::htmlEscape(tree$nodes[[id]]$text), fixed = TRUE, label = id)
    expect_match(html, "&#39;back&#39;", fixed = TRUE, label = id)
  }
})

test_that("undecided settings show a labelled placeholder; decided ones show the decision", {
  s <- setting_by_key(tree, "observed_power")
  expect_null(s$value)
  expect_match(as.character(placeholder_ui(s)), "Undecided: for the maintainer", fixed = TRUE)
  s$value <- "warn"
  html <- as.character(placeholder_ui(s))
  expect_match(html, "Maintainer decision", fixed = TRUE)
  expect_match(html, "Warn and allow", fixed = TRUE)
})

test_that("cards show undecided settings as compact labelled placeholders", {
  html <- as.character(card_ui(tree, "E7"))
  expect_match(html, "Undecided, for the maintainer", fixed = TRUE)
  expect_match(html, "Judgement call 3.1", fixed = TRUE)
  html_not <- as.character(card_ui(tree, "E36"))
  expect_match(html_not, "Open question 6", fixed = TRUE)
})

test_that("deciding against the guided route hides it, with no code change", {
  expect_match(as.character(start_ui(tree)), "Plan my whole study", fixed = TRUE)
  t2 <- tree
  for (i in seq_along(t2$settings)) if (t2$settings[[i]]$key == "guided_route") t2$settings[[i]]$value <- "no"
  expect_false(grepl("Plan my whole study", as.character(start_ui(t2)), fixed = TRUE))
})

test_that("the plan screen shows placeholders for the combined N and the consistency check, and no numbers", {
  answers <- list(x = "cond2", outcome = "score", mediators = "one", moderator = "score", covariate = "baseline")
  html <- as.character(guided_plan_ui(tree, answers, c("compare", "moderation", "mediation"), c("compare", "moderation", "mediation"),
    list(compare = "ANCOVA: the outcome adjusting for the baseline"), "any"))
  expect_match(html, "calculated here once the engine is connected", fixed = TRUE)
  expect_match(html, "The effect of x on the outcome appears in", ignore.case = TRUE)
  expect_match(html, "needs an alpha correction", fixed = TRUE)
  expect_match(html, "E23", fixed = TRUE)
  expect_match(html, "E15", fixed = TRUE)
  expect_match(html, "E16", fixed = TRUE)
})

test_that("the prototype never calls the engine or a power function", {
  files <- c(file.path(routing_dir, "app.R"), list.files(file.path(routing_dir, "R"), full.names = TRUE))
  code <- paste(unlist(lapply(files, readLines)), collapse = "\n")
  for (pattern in c("run_spec", "powerkit::", "load_engine", "Spower::", "Superpower::", "power4mome::", "InteractionPoweR::", "power.t.test", "pwr::")) {
    expect_false(grepl(pattern, code, fixed = TRUE), label = pattern)
  }
})
