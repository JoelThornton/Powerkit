# Misroutes found by docs/routing-audit.md, and the screening questions and
# safety net that fix them. Each misroute test follows the answers a user
# with that design would give and checks where they now lead, in every
# route.

routes <- c("choose", "known", "guided")
screen_score <- c("A score or scale", "Independent people")

# Where a list of answers leads in each route.
leads_to <- function(labels) vapply(routes, function(r) follow_answers(tree, labels, r), character(1))

expect_all_routes <- function(labels, endpoint, ctx = list()) {
  ends <- vapply(routes, function(r) follow_answers(tree, labels, r, ctx), character(1))
  for (r in routes) expect_identical(ends[[r]], endpoint, label = paste(r, ":", paste(labels, collapse = " > ")))
}

# Screening ---------------------------------------------------------------

test_that("every route starts with the four screening questions, in order", {
  for (r in routes) expect_identical(resolve_target(tree, start_node(tree), list(), r), "s1")
  expect_identical(follow_answers(tree, "A score or scale"), "s2")
  expect_identical(follow_answers(tree, screen_score), "s3")
  # The goal is asked once, on the aim screen: after the screening a study
  # that detects an effect goes on to its route's next screen.
  expect_identical(leads_to(c(screen_score, "Once")), c(choose = "q1", known = "list", guided = "guided"))
})

test_that("no route suggests a test powerkit runs, or will run, before the screening is finished", {
  for (r in routes) {
    for (p in all_paths(tree, r)) {
      end <- p[length(p)]
      if (!is_endpoint_id(end)) next
      # Separate people are asked all of S1-S3; people in groups leave
      # after S2 for the grouped card.
      screened <- "s3" %in% p || ("s2" %in% p && end == "E34")
      if (tree$endpoints[[end]]$status != "not_in_powerkit") expect_true(screened, label = paste(p, collapse = " > "))
    }
  }
})

test_that("answers other than the simple ones leave at an honest end point", {
  expect_all_routes(c("Ordered categories (e.g. a single rating item)", "As ordered categories"), "E29")
  expect_all_routes("The time until something happens", "E43")
  # People within groups: the goal is asked before the cluster-randomised
  # trial (which calculates) is suggested.
  expect_all_routes(c("A score or scale", "People within groups"), "E34")
  # Equivalence for grouped data: not the equivalence card, which assumes
  # separate people; the grouped card says it isn't covered yet.
  expect_all_routes(c("A score or scale", "People within groups"), "E34", ctx = list(goal = "equivalence"))
  expect_all_routes(c("A score or scale", "Pairs"), "E44")
  expect_all_routes(c("A score or scale", "Many trials or stimuli per person"), "E33")
  expect_all_routes(c(screen_score, "Many times", "Measurements over time, to see how people change"), "E35")
  # Equivalence is chosen on the aim screen, before the screening.
  expect_all_routes(c(screen_score, "Once"), "E36", ctx = list(goal = "equivalence"))
  expect_identical(start_exit(tree, list(aim = "estimate")), "E46")
  for (id in c("E29", "E33", "E35", "E43", "E44", "E45", "E46")) {
    expect_identical(tree$endpoints[[id]]$status, "not_in_powerkit", label = id)
  }
  # People within groups: the cluster-randomised trial calculates (powertools).
  expect_identical(tree$endpoints$E34$status, "runs_validation_in_progress")
})

test_that("a rating analysed as a score continues as a score (decision D1)", {
  expect_identical(follow_answers(tree, c("Ordered categories (e.g. a single rating item)", "As a score (for example, comparing mean ratings)")), "s2")
})

# Safety net -------------------------------------------------------------

test_that("every question, in every context a user can reach, offers 'None of these fit / I'm not sure'", {
  expect_identical(tree$safety_net$label, "None of these fit / I'm not sure")
  card <- as.character(card_ui(tree, tree$safety_net$endpoint))
  expect_match(card, htmltools::htmlEscape("powerkit can't advise on this design yet."), fixed = TRUE)
  expect_match(card, "We suggest discussing it with a statistician.", fixed = TRUE)
  label <- htmltools::htmlEscape(tree$safety_net$label)
  # Walk every route with its context and check each question shown.
  checked <- 0
  walk <- function(id, ctx, route, depth = 0) {
    id <- resolve_target(tree, id, ctx, route)
    node <- tree$nodes[[id]]
    if (is.null(node) || depth > 40) return(invisible())
    opts <- visible_options(tree, node, ctx)
    last <- opts[[length(opts)]]
    expect_true(isTRUE(last$safety), label = id)
    expect_identical(last$`next`, "E-unsure")
    expect_match(as.character(node_ui(tree, id, list(), ctx)), label, fixed = TRUE, label = id)
    checked <<- checked + 1
    for (o in opts[-length(opts)]) walk(o$`next`, apply_sets(ctx, o), route, depth + 1)
  }
  for (r in routes) walk(start_node(tree), list(), r)
  expect_gt(checked, 100)
  for (id in names(Filter(Negate(is_automatic), tree$nodes))) {
    expect_match(as.character(node_ui(tree, id, list())), label, fixed = TRUE, label = id)
  }
  expect_match(as.character(known_ui(tree)), label, fixed = TRUE)
})

test_that("the guided route offers the safety net for every variable and follow-up question", {
  for (v in tree$guided$variables) expect_true("notsure" %in% names(v$options), label = v$id)
  base <- list(x = "cond2", outcome = "score", mediators = "none", moderator = "none", covariate = "none")
  for (v in names(base)) {
    answers <- base
    answers[[v]] <- "notsure"
    for (a in applicable_analyses(tree, answers)) expect_identical(resolve_analysis(tree, a, answers)$endpoint, "E-unsure", label = v)
  }
  compare <- analysis_by_id(tree, "compare")
  pre_post <- modifyList(base, list(covariate = "baseline"))
  res <- resolve_analysis(tree, compare, pre_post, tree$safety_net$label)
  expect_identical(res$endpoint, "E-unsure")
  expect_false(is.null(res$asked))
  html <- as.character(guided_analyses_ui(tree, pre_post, character(), character(), list(), "each"))
  expect_match(html, htmltools::htmlEscape(tree$safety_net$label), fixed = TRUE)
})

test_that("the guided route offers only the outcome chosen in the screening", {
  html <- as.character(guided_variables_ui(tree, list(), list(outcome = "yesno", times = "once")))
  expect_match(html, "value=\"yesno\"", fixed = TRUE)
  expect_no_match(html, "value=\"count\"", fixed = TRUE)
  expect_no_match(html, "value=\"score\" checked", fixed = TRUE)
  many <- as.character(guided_variables_ui(tree, list(), list(outcome = "score", times = "many_conditions")))
  expect_match(many, "continue:choose", fixed = TRUE)
  expect_identical(resolve_target(tree, "continue", list(outcome = "score", times = "many_conditions"), "choose"), "q1")
})

# Misroutes from the audit -------------------------------------------------

segmented <- c(screen_score, "Many times", "Measurements over time, to see whether a trend changes at a known point")

test_that("segmented regression no longer reaches a t-test or a correlation, in any route", {
  # On main, path 1 reached E3 (paired t-test), path 2 reached E2
  # (independent t-test), path 3 reached E4 (correlation), and the guided
  # route reached E2. Now every route stops at the longitudinal card first.
  expect_all_routes(segmented, "E45")
  card <- as.character(card_ui(tree, "E45"))
  expect_match(card, "known breakpoint", fixed = TRUE)
  expect_match(card, "added predictor in a regression", fixed = TRUE)
  expect_match(card, "estimated from the data, a custom simulation is needed", fixed = TRUE)
  # Changed 17 October 2026 (maintainer): both directions, sourced to Zhang
  # et al. (2011), Table 1 (docs/card-sources.md).
  expect_match(card, "too optimistic when it's positive, too pessimistic when it's negative", fixed = TRUE)
  # Until 17 October 2026 the card said "No ready-made tool" (docs/decisions.md).
  expect_match(card, "A recently released package addresses the known-breakpoint case", fixed = TRUE)
})

test_that("two measurements still reach the before/after tests, and one measurement can't reach a same-people test", {
  twice <- c(screen_score, "Twice", "A difference between groups or conditions", "One")
  expect_identical(follow_answers(tree, c(twice, "Two, with the same people in both (or one group measured twice)")), "E3")
  once <- c(screen_score, "Once", "A difference between groups or conditions", "One")
  expect_identical(follow_answers(tree, c(once, "Two, with different people in each")), "E2")
  expect_error(follow_answers(tree, c(once, "Two, with the same people in both (or one group measured twice)")), "not offered")
  expect_error(follow_answers(tree, c(twice, "Two, with different people in each")), "not offered")
})

test_that("time series reach the longitudinal card, not a count or score test", {
  # On main: counts per period reached E28 for the wrong reason, and
  # scores reached E35, which doesn't mention autocorrelation.
  expect_all_routes(segmented, "E45")
})

test_that("nested data with a yes/no outcome no longer reaches the two-proportions test", {
  # On main: diff > Yes/no > Different people, two groups > E5.
  expect_all_routes(c("Yes/no, or one of several categories", "People within groups"), "E34")
})

test_that("cluster-randomised designs reach the multilevel card", {
  # On main: diff > score > Different people > One > Two, with different people > E2.
  expect_all_routes(c("A score or scale", "People within groups"), "E34")
  expect_match(tree$nodes$s2$options[[2]]$help, "whole groups were assigned", fixed = TRUE)
})

test_that("trials or stimuli with a yes/no outcome no longer reach McNemar's test", {
  # On main: diff > Yes/no > The same people in every condition > E26; and
  # rel > score > measured once > score > E4.
  expect_all_routes(c("Yes/no, or one of several categories", "Many trials or stimuli per person"), "E33")
  expect_all_routes(c("A score or scale", "Many trials or stimuli per person"), "E33")
})

test_that("dyadic data no longer reach a test that treats partners as independent", {
  # On main: rel > score > measured once > score > E4 (not reachable by name).
  expect_all_routes(c("A score or scale", "Pairs"), "E44")
})

test_that("growth curves and diary studies in the guided route reach the longitudinal card", {
  # On main the guided route reached E23 or E8 through a baseline covariate.
  expect_identical(follow_answers(tree, c(screen_score, "Many times", "Measurements over time, to see how people change"), "guided"), "E35")
})

test_that("time-to-event outcomes no longer reach a score test", {
  expect_all_routes("The time until something happens", "E43")
})

test_that("precision planning no longer reaches a power end point", {
  expect_identical(start_exit(tree, list(aim = "estimate")), "E46")
})

test_that("equivalence in the guided route reaches the equivalence card", {
  # On main the guided route had no goal question.
  expect_identical(follow_answers(tree, c(screen_score, "Once"), "guided", ctx = list(goal = "equivalence")), "E36")
})

test_that("SEM with latent variables is named on Q1 and reaches the SEM card", {
  base <- c(screen_score, "Once")
  expect_identical(follow_answers(tree, c(base, "That a model fits: a questionnaire structure, or a model with latent variables (SEM)")), "E37")
})

test_that("a yes/no outcome with two or more factors reaches its own card, not the two-proportions test", {
  # Found by the cross-check against the UCLA OARC table (factorial
  # logistic regression): Q3 for a yes/no difference had no answer for two
  # factors, so the nearest was "two groups" > E5.
  base <- c("Yes/no, or one of several categories", "Independent people", "Once", "A difference between groups or conditions")
  expect_identical(follow_answers(tree, c(base, "Two or more factors (e.g. a 2 x 2 design), yes/no outcome")), "E47")
})

test_that("counts no longer reach the correlation through the relationship path", {
  # On main: rel offered no count answer, so a count went in as a score > E4.
  # Since Poisson regression runs, a count is screened first like any
  # other outcome, so nested or repeated counts don't reach it.
  once <- c("A count", "Independent people", "Once")
  expect_identical(follow_answers(tree, "A count"), "s2")
  expect_identical(follow_answers(tree, c(once, "A relationship between two things you measure")), "E28")
  expect_identical(follow_answers(tree, c(once, "A difference between groups or conditions")), "E28")
  expect_identical(follow_answers(tree, c("A count", "Independent people", "Twice", "A difference between groups or conditions")), "E-unsure")
  expect_identical(follow_answers(tree, c("A count", "People within groups")), "E34")
})

test_that("two correlations in the same people reach their own card, not the independent-groups test", {
  base <- c("A score or scale", "Independent people", "Once", "A relationship between two things you measure")
  expect_identical(follow_answers(tree, c(base, "Scores, and the question is whether one correlation is stronger than another in the same people")), "E51")
  expect_identical(follow_answers(tree, c(base, "A score, and the question is whether the relationship differs between two separate groups")), "E49")
})

test_that("a hypothesis about how much scores vary reaches the variance tests, and only for a score measured once", {
  base <- c("A score or scale", "Independent people", "Once",
    "That scores are more spread out (or more consistent) in one group than another, or than a fixed value")
  expect_identical(follow_answers(tree, c(base, "One group's, against a fixed value (for example, a published norm)")), "E52")
  expect_identical(follow_answers(tree, c(base, "Two groups', with different people in each")), "E53")
  q1 <- vapply(visible_options(tree, tree$nodes$q1, list(outcome = "score", times = "twice")), `[[`, "", "label")
  expect_false(any(grepl("spread out", q1, fixed = TRUE)))
})

test_that("the analyses in the UCLA OARC test-selection table reach the end points recorded in docs/routing-audit.md", {
  once <- function(outcome) c(outcome, "Independent people", "Once")
  twice <- function(outcome) c(outcome, "Independent people", "Twice")
  score <- "A score or scale"
  yesno <- "Yes/no, or one of several categories"
  diff <- "A difference between groups or conditions"
  rel <- "A relationship between two things you measure"
  rows <- list(
    "One-sample t-test" = list(c(once(score), diff, "One", "One group, compared with a fixed value"), "E1"),
    "Binomial test" = list(c(once(yesno), diff, "One group, compared with a fixed proportion"), "E25"),
    "Two independent samples t-test" = list(c(once(score), diff, "One", "Two, with different people in each"), "E2"),
    "Chi-square test of independence" = list(c(once(yesno), diff, "Different people, outcome in categories"), "E6"),
    "Chi-square test, relationship path" = list(c(once(yesno), rel, "One of several categories (and the other variable is categories too)"), "E6"),
    "Paired t-test" = list(c(twice(score), diff, "One", "Two, with the same people in both (or one group measured twice)"), "E3"),
    "McNemar's test" = list(c(twice(yesno), diff, "The same people in every condition"), "E26"),
    "One-way ANOVA" = list(c(once(score), diff, "One", "Three or more", "Any difference among the groups"), "E18"),
    "One-way repeated measures ANOVA" = list(c(score, "Independent people", "Many times", "The same people in three or more conditions", diff, "One", "Three or more", "Any difference among the groups"), "E18"),
    "Factorial ANOVA" = list(c(once(score), diff, "Two, crossed (every combination appears)", "Yes: 2 x 2", "Both factors: different people", "Yes: the same number in every group", "Whether the effect of one depends on the other (the interaction)", "One effect shrinks"), "E7"),
    "Ordered logistic regression" = list(c("Ordered categories (e.g. a single rating item)", "As ordered categories"), "E29"),
    "Factorial logistic regression" = list(c(once(yesno), diff, "Two or more factors (e.g. a 2 x 2 design), yes/no outcome"), "E47"),
    "Correlation and simple linear regression" = list(c(once(score), rel, "A score or scale"), "E4"),
    "Simple and multiple logistic regression" = list(c(once(yesno), rel, "Yes/no"), "E27"),
    "Multiple regression" = list(c(once(score), rel, "Several predictors at once, or controlling for other variables"), "E24"),
    "Analysis of covariance" = list(c(twice(score), diff, "Two, crossed (every combination appears)", "Yes: 2 x 2", "One factor different people, the other everyone got both", "Yes: the same number in every group", "Yes: before and after", "Yes, randomly assigned", "ANCOVA: the after score, adjusting for the before score"), "E23"),
    "Factor analysis (confirmatory)" = list(c(once(score), "That a model fits: a questionnaire structure, or a model with latent variables (SEM)"), "E37")
  )
  for (name in names(rows)) expect_identical(follow_answers(tree, rows[[name]][[1]]), rows[[name]][[2]], label = name)
})

test_that("the audit has a row for each of the 31 analyses in the UCLA OARC table, and the chi-square test twice", {
  expected <- c("one-sample t-test", "one-sample median", "binomial test", "chi-square goodness-of-fit",
    "two independent samples t-test", "wilcoxon–mann–whitney", "chi-square test", "fisher's exact test",
    "one-way anova", "kruskal–wallis", "paired t-test", "wilcoxon signed ranks", "mcnemar",
    "one-way repeated measures anova", "friedman", "repeated measures logistic regression", "factorial anova",
    "ordered logistic regression", "factorial logistic regression", "correlation", "simple linear regression",
    "non-parametric correlation", "simple logistic regression", "multiple regression", "analysis of covariance",
    "multiple logistic regression", "discriminant analysis", "one-way manova", "multivariate multiple regression",
    "factor analysis", "canonical correlation")
  expect_length(expected, 31)
  text <- read_doc("routing-audit.md")
  start <- regexpr("## Cross-check against the UCLA OARC", text, fixed = TRUE)
  end <- regexpr("**Result.**", text, fixed = TRUE)
  lines <- strsplit(substring(text, start, end), "\n", fixed = TRUE)[[1]]
  lines <- lines[startsWith(lines, "| ") & !startsWith(lines, "| ---") & !startsWith(lines, "| Analysis (UCLA OARC row)")]
  names <- tolower(vapply(lines, function(l) split_row(l)[1], character(1), USE.NAMES = FALSE))
  expect_length(names, 32)
  expect_identical(sum(startsWith(names, "chi-square test (")), 2L)
  expect_setequal(unique(sub(" \\(two (groups|or more groups)\\)$", "", names)), expected)
})
