# The routing data must be complete: every route ends at an end point, and
# nothing is unreachable or points nowhere.

test_that("the 'Help me choose' tree has no dead ends, missing targets, unreachable questions or cycles", {
  expect_identical(tree_problems(tree), character())
})

test_that("every path through the tree ends at an end point", {
  paths <- all_paths(tree)
  expect_gt(length(paths), 50)
  for (p in paths) expect_true(is_endpoint_id(p[length(p)]), label = paste(p, collapse = " > "))
})

test_that("in the other two routes, every path leaves the screening at an end point or at the route's own screen", {
  for (route in c("known", "guided")) {
    after <- after_screening(tree, route)
    paths <- all_paths(tree, route)
    ends <- vapply(paths, function(p) p[length(p)], character(1))
    expect_true(all(is_endpoint_id(ends) | ends == after), label = route)
    expect_true(after %in% ends, label = route)
    # The screening alone: no path reaches a question beyond it.
    for (p in paths) expect_true(all(p %in% c("s1", "o5a", "s2", "s3", "t1", "s4", after) | is_endpoint_id(p)), label = paste(p, collapse = " > "))
  }
})

test_that("generic 'not covered' cards have their own text, and those that claim tools exist use the neutral sentence", {
  expect_identical(tree$established_tools_text, "Established tools exist for this design; powerkit hasn't checked them.")
  for (id in names(tree$endpoints)) {
    ep <- tree$endpoints[[id]]
    if (!isTRUE(ep$generic)) next
    expect_null(ep$packages, label = id)
    html <- as.character(card_ui(tree, id))
    expect_match(html, htmltools::htmlEscape(ep$card_text), fixed = TRUE, label = id)
    if (isTRUE(ep$established_tools)) expect_match(html, htmltools::htmlEscape(tree$established_tools_text), fixed = TRUE, label = id)
  }
})

test_that("every end point can be reached: from the tree, or from the 'I know my analysis' list", {
  from_tree <- reachable(tree, start_node(tree))$endpoints
  # The list offers every end point; check that the tree reaches all but
  # the ones decision-tree.md reaches only by other routes (Bayes factors:
  # open question 8).
  expect_setequal(setdiff(names(tree$endpoints), from_tree), "E-bayes")
})

test_that("the three routes are defined, and each starts with the screening questions", {
  expect_setequal(vapply(tree$routes$options, function(r) r$id, character(1)), c("known", "choose", "guided"))
  expect_identical(start_node(tree), "s1")
  expect_identical(after_screening(tree, "choose"), "q1")
  expect_identical(after_screening(tree, "known"), "list")
  expect_identical(after_screening(tree, "guided"), "guided")
})

test_that("every end point has a name, inputs and a known status", {
  for (id in names(tree$endpoints)) {
    ep <- tree$endpoints[[id]]
    expect_true(nzchar(ep$plain_name %||% ""), label = id)
    if (isTRUE(ep$generic)) {
      expect_true(nzchar(ep$card_text %||% ""), label = id)
    } else {
      expect_gt(length(ep$inputs), 0, label = id)
    }
    expect_true(ep$status %in% c("runs_validated", "runs_validation_in_progress", "coming_soon", "not_in_powerkit"), label = id)
    expect_true(ep$tier %in% c("MVP", "v2", "later", "none"), label = id)
  }
})

test_that("end points that run have a backend, a method and a validation file", {
  for (id in names(tree$endpoints)) {
    ep <- tree$endpoints[[id]]
    if (ep$status %in% c("runs_validated", "runs_validation_in_progress")) {
      expect_true(nzchar(ep$backend %||% ""), label = id)
      expect_true(nzchar(ep$method %||% ""), label = id)
      expect_match(ep$validation$file, "^test-validation-.*\\.R$", label = id)
    }
  }
})

test_that("every 'not in powerkit' end point names a package, a link and what it does", {
  for (id in names(tree$endpoints)) {
    ep <- tree$endpoints[[id]]
    if (ep$status != "not_in_powerkit" || isTRUE(ep$generic)) next
    expect_gt(length(ep$packages), 0, label = id)
    for (pk in ep$packages) {
      expect_true(nzchar(pk$name %||% ""), label = id)
      expect_match(pk$url %||% "", "^https://", label = id)
      expect_true(nzchar(pk$what %||% ""), label = id)
    }
  }
})

test_that("every MVP capability in coverage.md appears in the app", {
  mvp <- coverage_mvp_capabilities()
  expect_gt(length(mvp), 20)
  mapped <- vapply(tree$coverage_map, function(m) m$capability, character(1))
  expect_setequal(mapped, mvp)
  known <- c(names(tree$endpoints), names(tree$nodes), vapply(tree$closing_questions, function(q) q$doc_id, character(1)))
  for (m in tree$coverage_map) {
    expect_true(all(unlist(m$covered_by) %in% known), label = m$capability)
  }
})

test_that("every setting is either undecided or set to one of its options, and appears somewhere", {
  screens <- c("start", "card", "plan", "guided_variables", names(Filter(Negate(is_automatic), tree$nodes)), names(tree$endpoints))
  for (s in tree$settings) {
    expect_true(is.null(s$value) || s$value %in% names(s$options), label = s$key)
    expect_gt(length(s$options), 0, label = s$key)
    expect_true(all(unlist(s$shown_at) %in% screens), label = s$key)
  }
})

test_that("every setting shown on cards is attached to a closing question or to the 'not in powerkit' status", {
  inline <- c(unlist(lapply(tree$closing_questions, function(q) q$setting)), "not_in_spec_wording", "r_script_for_uncovered")
  for (s in tree$settings) {
    if ("card" %in% unlist(s$shown_at)) expect_true(s$key %in% inline, label = s$key)
  }
})

test_that("the guided route reaches an end point (or a named package) for every combination of answers", {
  for (answers in all_variable_combinations(tree)) {
    for (a in applicable_analyses(tree, answers)) {
      res <- resolve_analysis(tree, a, answers)
      if (!is.null(res$ask)) {
        for (o in res$ask$options) {
          expect_true(o$endpoint %in% names(tree$endpoints), label = paste(a$id, o$label))
          expect_identical(resolve_analysis(tree, a, answers, o$label)$endpoint, o$endpoint)
        }
      } else if (!is.null(res$unmapped)) {
        expect_false(is.null(res$package), label = paste(a$id, paste(unlist(answers), collapse = "/")))
        expect_match(res$package$url, "^https://")
      } else {
        expect_true(res$endpoint %in% names(tree$endpoints), label = paste(a$id, res$endpoint))
      }
    }
  }
})

test_that("the guided route offers the comparison for every study, and moderation or mediation only when there is a moderator or mediator", {
  ids <- function(answers) vapply(applicable_analyses(tree, answers), function(a) a$id, character(1))
  base <- list(x = "cond2", outcome = "score", mediators = "none", moderator = "none", covariate = "none")
  expect_identical(ids(base), "compare")
  expect_setequal(ids(modifyList(base, list(mediators = "one", moderator = "score"))), c("compare", "moderation", "mediation", "modmed"))
})
