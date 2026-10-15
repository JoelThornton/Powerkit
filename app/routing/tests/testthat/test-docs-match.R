# tree.yaml and docs/decision-tree.md must describe the same end points and
# questions, so the app and the spec can't drift apart.

test_that("the end points in tree.yaml are exactly those in decision-tree.md, table 2.3", {
  doc <- doc_endpoints()
  expect_setequal(names(tree$endpoints), doc$id)
})

test_that("each end point's name matches decision-tree.md word for word", {
  doc <- doc_endpoints()
  for (i in seq_len(nrow(doc))) {
    expect_identical(tree$endpoints[[doc$id[i]]]$doc_name, doc$name[i], label = doc$id[i])
  }
})

test_that("each end point's status and tier match decision-tree.md", {
  doc <- doc_endpoints()
  expected_status <- function(status, validated) {
    if (startsWith(status, "Runs")) {
      if (startsWith(validated, "Yes")) "runs_validated" else "runs_not_yet_validated"
    } else if (startsWith(status, "Spec only")) {
      "coming_soon"
    } else {
      "not_in_powerkit"
    }
  }
  for (i in seq_len(nrow(doc))) {
    ep <- tree$endpoints[[doc$id[i]]]
    expect_identical(ep$status, expected_status(doc$status[i], doc$validated[i]), label = doc$id[i])
    expect_true(startsWith(tolower(doc$tier[i]), tolower(ep$tier)), label = paste(doc$id[i], "tier"))
  }
})

test_that("the question IDs in tree.yaml are exactly those in decision-tree.md, table 2.2", {
  yaml_ids <- unique(c(
    tree$routes$doc_id,
    vapply(tree$nodes, function(n) n$doc_id, character(1)),
    vapply(tree$closing_questions, function(q) q$doc_id, character(1))
  ))
  expect_setequal(yaml_ids, doc_question_ids())
})

test_that("the guided route's follow-up questions use question IDs from decision-tree.md", {
  ids <- doc_question_ids()
  for (a in tree$guided$analyses) {
    for (rule in a$rules) {
      if (!is.null(rule$ask)) expect_true(rule$ask$doc_id %in% ids, label = paste(a$id, rule$ask$doc_id))
    }
  }
})
