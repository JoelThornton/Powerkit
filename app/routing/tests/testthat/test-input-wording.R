# Labels and wording on the input screens (input-screen review of 28
# November 2026): cell boxes named by the levels typed, the second
# moderator called a moderator, help that describes what its box asks, and
# menus in plain words.

field <- function(ep, id) Filter(function(f) identical(f$id, id), form_fields(form_groups(forms, ep)))[[1]]

test_that("the 2 x 2 cell boxes take the level names typed, on screen and in the write-up", {
  for (ep in c("E7", "E22", "E8")) {
    f <- field(ep, "m11")
    expect_identical(sort(unname(unlist(f$label_names))), c("A_level1", "B_level1"), label = ep)
    html <- as.character(field_ui(f, ""))
    expect_match(html, "class=\"named-label\"", fixed = TRUE, label = ep)
    expect_match(html, "f_A_level1", fixed = TRUE, label = ep)
  }
  f <- field("E7", "m12")
  values <- list(A_level1 = "None", A_level2 = "Praise", B_level1 = "Easy", B_level2 = "Hard", m12 = "5")
  expect_identical(named_label(f$label, f$label_names, values), "Mean: None, Hard")
  expect_match(writeup_effect(list(f), values), "mean: None, Hard = 5", fixed = TRUE)
  # A level not yet named keeps its generic phrase.
  expect_identical(named_label(f$label, f$label_names, list(A_level1 = "None")), "Mean: None, B level 2")
  expect_identical(named_label(field("E8", "m21")$label, field("E8", "m21")$label_names,
    list(A_level2 = "Therapy", B_level1 = "Before")), "Mean: Therapy, Before")
  # Screens without these phrases are unchanged.
  expect_null(field("E18", "means")$label_names)
})

test_that("the three-way interaction's Z is the second moderator", {
  expect_identical(field("E31", "Z_label")$label, "Z (the second moderator)")
})

test_that("the averaging question's help explains the averaging on every Bayes ANOVA", {
  for (ep in c("E7", "E8", "E20", "E21", "E22", "E54", "E55")) {
    f <- Filter(function(f) identical(f$id, "inclusion"), form_fields(form_groups(forms, ep)))
    if (!length(f)) next
    expect_match(f[[1]]$help, "^The inclusion Bayes factor compares", label = ep)
  }
})

test_that("help describes the number its box asks for", {
  expect_match(field("E43", "p_event2")$help, "^Group 2's proportion by then")
  expect_no_match(field("E43", "p_event2")$help, "difference", fixed = TRUE)
  expect_no_match(field("E37", "loading_group2")$help, "difference", fixed = TRUE)
})

test_that("the ANCOVA card says what the covariate box takes", {
  expect_true(any(grepl("for one covariate, its correlation with the outcome, squared", tree$endpoints$E23$inputs, fixed = TRUE)))
})

test_that("a one-choice mediator count isn't asked, and the method help is in plain words", {
  for (ep in c("E11", "E40")) {
    ids <- vapply(form_fields(form_groups(forms, ep)), function(f) f$id, "")
    expect_false("n_mediators" %in% ids, label = ep)
    expect_true(all(c("M1_label", "M2_label") %in% ids), label = ep)
  }
  expect_true("n_mediators" %in% vapply(form_fields(form_groups(forms, "E12")), function(f) f$id, ""))
  expect_no_match(field("E10", "method")$help, "existing browser workflow", fixed = TRUE)
})

test_that("menus name a package, not its functions, unless the function is the setting to match", {
  # R's own tests in a menu tell the researcher which analysis default it
  # matches (binom.test()'s p-value, prop.test()'s continuity correction);
  # car's functions name the output to read.
  allowed <- "binom\\.test\\(\\)|prop\\.test\\(|Anova\\(type|linearHypothesis\\(\\)|glmer\\(\\)"
  for (ep in names(forms$forms)) for (f in form_fields(form_groups(forms, ep))) {
    shown <- c(f$label, unlist(f$choices))
    calls <- shown[grepl("[A-Za-z0-9_.]+\\(\\)|::", shown)]
    expect_true(all(grepl(allowed, calls)), label = paste(ep, f$id, paste(calls, collapse = " | ")))
  }
})
