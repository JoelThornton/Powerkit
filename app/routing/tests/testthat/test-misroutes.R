# Misroutes found by docs/routing-audit.md, and the screening questions and
# safety net that fix them. Each misroute test follows the answers a user
# with that design would give and checks where they now lead, in every
# route.

routes <- c("choose", "known", "guided")
screen_score <- c("A score or scale", "Independent people")
cluster_conditions <- "Conditions or treatments given to whole groups, or to people within the groups"
MORE <- "Something else: the spread of scores, a questionnaire's structure or fit, item bias, signal detection, or types of people"
TWO_BY_TWO <- "Two, each with exactly two levels (a 2 x 2 design)"
LARGER <- "Two, crossed, at least one with three or more levels"
cluster_measured <- "Something measured on each person, or on each group, and how it relates to the outcome"

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
      # after S2 for the grouped cards (through C1).
      # Many trials per person leave after S2's follow-up for E33. A time
      # until an event is identified by the outcome itself, at S1 (E43).
      screened <- "s3" %in% p || end == "E43" || ("s2" %in% p && end %in% c("E34", "E62", "E68", "E44", "E65")) || ("s2_trials" %in% p && end %in% c("E33", "E63", "E67"))
      if (tree$endpoints[[end]]$status != "not_in_powerkit") expect_true(screened, label = paste(p, collapse = " > "))
    }
  }
})

test_that("answers other than the simple ones leave at an honest end point", {
  # Ordered categories go through the grouping questions: two groups of
  # different people, measured once, reach the ordinal card; repeated
  # ordinal measurements the card for generalised mixed models (E75).
  ordinal <- c("Ordered categories (e.g. a single rating item)", "As ordered categories", "Independent people")
  expect_identical(follow_answers(tree, c(ordinal, "Once", "A difference between groups or conditions")), "E29")
  expect_identical(follow_answers(tree, c(ordinal, "Twice", "A difference between groups or conditions")), "E75")
  expect_all_routes("The time until something happens", "E43")
  # People within groups: the goal is asked before the cluster-randomised
  # trial (which calculates) is suggested; with a score outcome, C1 then
  # separates conditions given to groups (E34) from measured predictors
  # at either level (E62).
  expect_identical(leads_to(c("A score or scale", "People within groups")), c(choose = "c1", known = "c1", guided = "c1"))
  expect_all_routes(c("A score or scale", "People within groups", cluster_conditions, "No: one level of groups (for example, classes, or clinics)"), "E34")
  expect_all_routes(c("A score or scale", "People within groups", cluster_measured), "E62")
  # Groups within larger groups (1 November 2026): three levels.
  expect_all_routes(c("A score or scale", "People within groups", cluster_conditions,
    "Yes: groups within larger groups (for example, classes within schools, or therapists within clinics)"), "E68")
  # Equivalence for grouped data: not the equivalence card, which assumes
  # separate people; the grouped card says it isn't covered yet.
  expect_all_routes(c("A score or scale", "People within groups"), "E34", ctx = list(goal = "equivalence"))
  expect_all_routes(c("A score or scale", "Pairs", "Something measured on each member, and how it relates to their own and their partner's outcome"), "E44")
  expect_all_routes(c("A score or scale", "Many trials or stimuli per person", "Two conditions, and each person responds in both"), "E33")
  expect_all_routes(c(screen_score, "Many times", "Measurements over time, to see how people change"), "E35")
  # Equivalence is chosen on the aim screen, before the screening.
  expect_all_routes(c(screen_score, "Once"), "E36", ctx = list(goal = "equivalence"))
  expect_identical(start_exit(tree, list(aim = "estimate")), "E46")
  # Interrupted time series calculate (PITS and REML, 6 November 2026).
  expect_identical(tree$endpoints$E45$status, "runs_validation_in_progress")
  for (id in c("E65")) {
    expect_identical(tree$endpoints[[id]]$status, "not_in_powerkit", label = id)
  }
  # Growth curves calculate (longpower, 5 November 2026).
  expect_identical(tree$endpoints$E35$status, "runs_validation_in_progress")
  # Estimating precisely: the precision card calculates (MBESS, presize).
  expect_identical(tree$endpoints$E46$status, "runs_validation_in_progress")
  # Ordered categories in two groups calculate (powertools' propodds()).
  expect_identical(tree$endpoints$E29$status, "runs_validation_in_progress")
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
  expect_match(card, "intervention at a known point", fixed = TRUE)
  expect_match(card, "segmented regression", fixed = TRUE)
  expect_match(card, "breakpoint estimated from the data", fixed = TRUE)
  # Changed 17 October 2026 (maintainer): both directions, sourced to Zhang
  # et al. (2011), Table 1 (docs/card-sources.md).
  expect_match(card, "too optimistic when it's positive, too pessimistic when it's negative", fixed = TRUE)
  # Until 17 October 2026 the card said "No ready-made tool"; until 6
  # November 2026 that a recent package covered it; now it calculates
  # (docs/decisions.md).
  expect_no_match(card, "No ready-made tool", fixed = TRUE)
})

test_that("two measurements still reach the before/after tests, and one measurement can't reach a same-people test", {
  # One factor measured twice can only be the same people in both
  # conditions, so it goes straight to the paired test.
  expect_identical(follow_answers(tree, c(screen_score, "Twice", "A difference between groups or conditions", "One")), "E3")
  once <- c(screen_score, "Once", "A difference between groups or conditions", "One")
  expect_identical(follow_answers(tree, c(once, "Two, with different people in each")), "E2")
  f2 <- vapply(visible_options(tree, tree$nodes$f2, list(outcome = "score", times = "once")), `[[`, "", "label")
  expect_false(any(grepl("same people", f2, fixed = TRUE)))
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
  expect_all_routes(c("A score or scale", "People within groups", cluster_conditions, "No: one level of groups (for example, classes, or clinics)"), "E34")
  expect_match(tree$nodes$s2$options[[2]]$help, "whole groups were assigned", fixed = TRUE)
})

test_that("trials or stimuli with a yes/no outcome no longer reach McNemar's test", {
  # On main: diff > Yes/no > The same people in every condition > E26; and
  # rel > score > measured once > score > E4.
  # A yes/no outcome per trial calculates too (31 October 2026): E33, by a
  # logistic mixed model; a count still reaches the multilevel card.
  expect_all_routes(c("Yes/no, or one of several categories", "Many trials or stimuli per person", "Two conditions, and each person responds in both"), "E33")
  expect_all_routes(c("A score or scale", "Many trials or stimuli per person", "Two conditions, and each person responds in both"), "E33")
  expect_all_routes(c("A score or scale", "Many trials or stimuli per person", "Something else"), "E41")
  # A score measured on each item (1 November 2026): E67.
  expect_all_routes(c("A score or scale", "Many trials or stimuli per person", "A score measured on each item, and how it relates to the response"), "E67")
  # Conditions given to different people (31 October 2026): E33 with the
  # condition between participants; a yes/no outcome per trial still E41.
  expect_all_routes(c("A score or scale", "Many trials or stimuli per person", "Two conditions, and each person is in one of them"), "E33")
  expect_all_routes(c("Yes/no, or one of several categories", "Many trials or stimuli per person", "Two conditions, and each person is in one of them"), "E33")
  # Three or more conditions, everyone in all of them (31 October 2026): E63.
  expect_all_routes(c("A score or scale", "Many trials or stimuli per person", "Three or more conditions, and each person responds in all of them"), "E63")
  expect_all_routes(c("A score or scale", "Many trials or stimuli per person", "Three or more conditions, and each person is in one of them"), "E63")
})

test_that("dyadic data no longer reach a test that treats partners as independent", {
  # On main: rel > score > measured once > score > E4 (not reachable by name).
  # Pairs (1 November 2026): actor and partner effects calculate (E44);
  # conditions given to whole pairs are a cluster trial with groups of two.
  expect_all_routes(c("A score or scale", "Pairs", "Something measured on each member, and how it relates to their own and their partner's outcome"), "E44")
  expect_all_routes(c("A score or scale", "Pairs", "Conditions given to whole pairs"), "E34")
  expect_all_routes(c("A score or scale", "Pairs", "Something else, such as a condition given to one member of each pair"), "E65")
  expect_all_routes(c("Yes/no, or one of several categories", "Pairs", "Something measured on each member, and how it relates to their own and their partner's outcome"), "E65")
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
  expect_identical(follow_answers(tree, c(base, MORE, "Something about latent variables: that a model or questionnaire structure fits, that a questionnaire measures the same in two groups, or a path between factors (SEM)")), "E37")
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
  expect_identical(follow_answers(tree, c("A count", "Independent people", "Twice", "A difference between groups or conditions")), "E75")
  expect_identical(follow_answers(tree, c("A count", "People within groups")), "E34")
})

test_that("an outcome measured twice or more never falls through to the safety net unasked", {
  # A count or ordered categories measured twice (before and after, or in
  # two conditions) is a common design, and the questions had nowhere to
  # send it: a difference reaches the generalised mixed model card (E75),
  # a relationship the within-person card (E41), as for a score.
  ordinal <- c("Ordered categories (e.g. a single rating item)", "As ordered categories")
  diff <- "A difference between groups or conditions"
  rel <- "A relationship between two things you measure"
  many <- c("Many times", "The same people in three or more conditions")
  for (outcome in list("A count", ordinal)) {
    for (times in list("Twice", many)) {
      base <- c(outcome, "Independent people", times)
      expect_identical(follow_answers(tree, c(base, diff)), "E75", label = paste(c(base, diff), collapse = " > "))
      expect_identical(follow_answers(tree, c(base, rel)), "E41", label = paste(c(base, rel), collapse = " > "))
    }
  }
  # A yes/no relationship measured twice went to logistic regression, which
  # assumes separate people; measured once it still does.
  yesno <- c("Yes/no, or one of several categories", "Independent people")
  expect_identical(follow_answers(tree, c(yesno, "Twice", rel)), "E41")
  expect_identical(follow_answers(tree, c(yesno, "Once", rel, "Yes/no")), "E27")
  expect_identical(follow_answers(tree, c("A count", "Independent people", "Once", rel)), "E28")
  # Walking every answer in "Help me choose", only "Four or more" factors
  # and an ordinal outcome with a measured predictor, measured once, still
  # reach the safety net without choosing it.
  ends <- character()
  walk <- function(id, ctx, trail, depth = 0) {
    id <- resolve_target(tree, id, ctx, "choose")
    if (identical(id, "E-unsure")) { ends <<- c(ends, paste(trail, collapse = " > ")); return(invisible()) }
    node <- tree$nodes[[id]]
    if (is.null(node) || depth > 40) return(invisible())
    for (o in visible_options(tree, node, ctx)) {
      if (!isTRUE(o$safety)) walk(o$`next`, apply_sets(ctx, o), c(trail, o$label), depth + 1)
    }
  }
  walk(start_node(tree), list(), character())
  expect_gt(length(ends), 0)
  allowed <- grepl("Four or more$", ends) | grepl(paste0("As ordered categories > Independent people > Once > ", rel, "$"), ends, fixed = FALSE)
  expect_identical(ends[!allowed], character())
})

test_that("the guided route reaches the safety net unasked only for the gaps listed here", {
  # Every combination of answers, none of them "None of these fit": a
  # combination that ends at the safety net must be a known gap with no
  # card (coverage-roadmap.md), never a common design the questions forgot.
  allowed <- c(
    # Unordered categories measured twice: no card or ready-made tool.
    "categories cond2 twice", "categories cond3 twice", "categories score twice",
    # Ordered categories with three or more groups or a measured predictor:
    # E29 compares two groups only (coverage-roadmap.md, B29).
    "ordinal cond3 once", "ordinal score once"
  )
  vars <- tree$guided$variables
  opts <- lapply(vars, function(v) setdiff(names(v$options), "notsure"))
  names(opts) <- vapply(vars, `[[`, "", "id")
  grid <- expand.grid(c(opts, list(times = c("once", "twice"))), stringsAsFactors = FALSE)
  gaps <- character()
  for (i in seq_len(nrow(grid))) {
    a <- as.list(grid[i, ])
    if ((a$x == "within2" || a$covariate == "baseline") && a$times != "twice") next
    for (an in applicable_analyses(tree, a)) {
      if (identical(resolve_analysis(tree, an, a)$endpoint, "E-unsure")) gaps <- c(gaps, paste(a$outcome, a$x, a$times))
    }
  }
  expect_setequal(unique(gaps), allowed)
})

test_that("the guided route sends repeated counts, ratings and yes/no groups to the generalised mixed model card", {
  compare <- analysis_by_id(tree, "compare")
  base <- list(mediators = "none", moderator = "none", covariate = "none", times = "twice")
  for (outcome in c("count", "ordinal")) {
    for (x in c("within2", "cond2", "cond3")) {
      expect_identical(resolve_analysis(tree, compare, modifyList(base, list(x = x, outcome = outcome)))$endpoint, "E75", label = paste(outcome, x))
    }
  }
  for (x in c("cond2", "cond3")) {
    expect_identical(resolve_analysis(tree, compare, modifyList(base, list(x = x, outcome = "yesno")))$endpoint, "E75", label = x)
  }
  expect_identical(resolve_analysis(tree, compare, modifyList(base, list(x = "within2", outcome = "yesno")))$endpoint, "E26")
  once <- modifyList(base, list(times = "once"))
  expect_identical(resolve_analysis(tree, compare, modifyList(once, list(x = "cond2", outcome = "count")))$endpoint, "E28")
  expect_identical(resolve_analysis(tree, compare, modifyList(once, list(x = "cond2", outcome = "ordinal")))$endpoint, "E29")
})

test_that("two correlations in the same people reach their own card, not the independent-groups test", {
  base <- c("A score or scale", "Independent people", "Once", "A relationship between two things you measure")
  expect_identical(follow_answers(tree, c(base, "Scores, and the question is whether one correlation is stronger than another in the same people")), "E51")
  expect_identical(follow_answers(tree, c(base, "A score, and the question is whether the relationship differs between two separate groups")), "E49")
})

test_that("a hypothesis about how much scores vary reaches the variance tests, for a score measured once or twice", {
  base <- c("A score or scale", "Independent people", "Once", MORE,
    "That scores are more spread out (or more consistent) in one group than another, or than a fixed value")
  expect_identical(follow_answers(tree, c(base, "One group's, against a fixed value (for example, a published norm)")), "E52")
  expect_identical(follow_answers(tree, c(base, "Two groups', with different people in each")), "E53")
  # Measured twice: the same people's spread, the Pitman-Morgan test (E57).
  twice <- c("A score or scale", "Independent people", "Twice", MORE,
    "That scores are more spread out (or more consistent) in one group than another, or than a fixed value")
  # Measured twice, the same people's spread is the only answer, so the
  # question is skipped.
  expect_identical(follow_answers(tree, twice), "E57")
  q1 <- vapply(visible_options(tree, tree$nodes$q1_more, list(outcome = "score", times = "many_conditions")), `[[`, "", "label")
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
    "Paired t-test" = list(c(twice(score), diff, "One"), "E3"),
    "McNemar's test" = list(c(twice(yesno), diff), "E26"),
    "One-way ANOVA" = list(c(once(score), diff, "One", "Three or more", "Any difference among the groups"), "E18"),
    "Three-factor ANOVA, group by time by task" = list(c(twice(score), diff, "Three, crossed (every combination appears)"), "E56"),
    "One-way repeated measures ANOVA" = list(c(score, "Independent people", "Many times", "The same people in three or more conditions", diff, "One", "Any difference among the conditions"), "E54"),
    "Mixed ANOVA, group by three timepoints" = list(c(score, "Independent people", "Many times", "The same people in three or more conditions", diff, LARGER, "One factor different people, the other everyone got every level"), "E55"),
    "Mixed ANOVA, three groups before and after" = list(c(twice(score), diff, LARGER), "E55"),
    "Two-factor within ANOVA, 2 x 3" = list(c(score, "Independent people", "Many times", "The same people in three or more conditions", diff, LARGER, "Both factors: everyone got every level"), "E20"),
    "Two-factor within ANOVA, 2 x 2" = list(c(score, "Independent people", "Many times", "The same people in three or more conditions", diff, TWO_BY_TWO), "E20"),
    "Two-factor between ANOVA, 2 x 3" = list(c(once(score), diff, LARGER), "E21"),
    "Factorial ANOVA" = list(c(once(score), diff, TWO_BY_TWO, "Yes: the same number in every group", "Whether the effect of one depends on the other (the interaction)", "One effect shrinks"), "E7"),
    "Ordered logistic regression" = list(c("Ordered categories (e.g. a single rating item)", "As ordered categories", "Independent people", "Once", diff), "E29"),
    "Factorial logistic regression" = list(c(once(yesno), diff, "Two or more factors (e.g. a 2 x 2 design), yes/no outcome"), "E47"),
    "Correlation and simple linear regression" = list(c(once(score), rel, "A score or scale"), "E4"),
    "Simple and multiple logistic regression" = list(c(once(yesno), rel, "Yes/no"), "E27"),
    "Multiple regression" = list(c(once(score), rel, "Several predictors at once, or controlling for other variables"), "E24"),
    "Analysis of covariance" = list(c(twice(score), diff, TWO_BY_TWO, "Yes: before and after", "Yes, randomly assigned", "ANCOVA: the after score, adjusting for the before score (recommended)"), "E23"),
    "Factor analysis (confirmatory)" = list(c(once(score), MORE, "Something about latent variables: that a model or questionnaire structure fits, that a questionnaire measures the same in two groups, or a path between factors (SEM)"), "E37")
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

# Design-finder routes (review of 7 November 2026) ----------------------


test_that("a two-arm before/after study reaches the cards that take unequal groups, without a question that changes nothing", {
  path <- c(screen_score, "Twice", "A difference between groups or conditions", TWO_BY_TWO)
  expect_identical(follow_answers(tree, path), "f4b")
  expect_match(tree$nodes$f4b$help, "differ", fixed = TRUE)
  expect_null(tree$nodes$f4a_mixed)
})

test_that("a randomised before/after trial is pointed to ANCOVA, keeping the mixed interaction as an option", {
  path <- c(screen_score, "Twice", "A difference between groups or conditions", TWO_BY_TWO, "Yes: before and after", "Yes, randomly assigned")
  expect_identical(follow_answers(tree, c(path, "ANCOVA: the after score, adjusting for the before score (recommended)")), "E23")
  expect_identical(follow_answers(tree, c(path, "The 2 x 2 mixed ANOVA interaction (group x time)")), "f6_mixed")
  expect_match(tree$nodes$pp2_random$options[[1]]$label, "(recommended)", fixed = TRUE)
})

test_that("a moderation in a before/after trial reaches the regression card, and a group-by-condition one the ANOVA questions", {
  path <- c(screen_score, "Twice", "That an effect depends on something else (moderation)")
  expect_identical(follow_answers(tree, path), "mo_within")
  expect_identical(follow_answers(tree, c(path, "A treatment or group, and a measured score, with the outcome measured before and after")), "E24")
  expect_identical(follow_answers(tree, c(path, "Both are groups or conditions (for example, the emotion effect is bigger in the clinical group, or the treatment group improves more over time)")), "f1")
  expect_identical(follow_answers(tree, c(path, "Things measured within each person (for example, daily stress and sleep in a diary study)")), "E41")
  expect_identical(whole_study_twice_endpoints[["moderation"]], "E24")
})

test_that("one factor measured twice goes straight to the paired card, with crossover guidance", {
  expect_identical(follow_answers(tree, c(screen_score, "Twice", "A difference between groups or conditions", "One")), "E3")
  expect_true(any(grepl("crossover", tolower(unlist(tree$endpoints$E3$card_points)), fixed = TRUE)))
  expect_true(any(grepl("crossover", tolower(unlist(tree$endpoints$E8$card_points)), fixed = TRUE)))
})

test_that("the rarer hypotheses sit behind one choice, and still reach their cards", {
  expect_lte(length(tree$nodes$q1$options), 6)
  expect_identical(follow_answers(tree, c(screen_score, "Once", MORE)), "q1_more")
  expect_identical(follow_answers(tree, c(screen_score, "Twice", MORE,
    "That scores are more spread out (or more consistent) in one group than another, or than a fixed value")), "E57")
})

test_that("no question in the design finder has only one answer for the answers given before it", {
  single <- character()
  walk <- function(id, ctx, seen) {
    id <- resolve_target(tree, id, ctx, "choose")
    node <- if (is.na(id)) NULL else tree$nodes[[id]]
    if (is.null(node) || id %in% seen) return(invisible())
    opts <- visible_options(tree, node, ctx, safety = FALSE)
    if (length(opts) == 1) single <<- c(single, id)
    for (o in opts) walk(o$`next`, apply_sets(ctx, o), c(seen, id))
  }
  walk(start_node(tree), list(), character())
  expect_identical(unique(single), character())
})

test_that("search on \"I know my analysis\" finds the names researchers type", {
  words <- function(id) tolower(paste(unlist(tree$endpoints[[id]]$search_words), collapse = " "))
  expect_match(words("E2"), "cohen's d", fixed = TRUE)
  expect_match(words("E3"), "crossover", fixed = TRUE)
  expect_match(words("E23"), "ancova", fixed = TRUE)
})

test_that("a whole-study plan with nested data, pairs or many trials says it becomes one analysis", {
  expect_match(tree$guided$single_analysis_note, "one analysis at a time", fixed = TRUE)
})
