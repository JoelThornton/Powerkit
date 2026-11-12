test_that("input evidence uses complete selected settings and preserves unknown coverage", {
  fields <- form_fields(form_groups(forms, "E2"))
  expect_no_match(as.character(selected_evidence_ui(forms, "E2", fields, list())), "Evidence depends on", fixed=TRUE)
  v <- modifyList(form_examples$E2, list(goal="power", n="120"))
  html <- as.character(selected_evidence_ui(forms, "E2", fields, v))
  expect_match(html, "Checks covering my selected settings", fixed=TRUE)
  expect_match(html, "does not validate every test version", fixed=TRUE)
  expect_match(html, "Source record|no linked record|outside the recorded case settings")
  expect_match(as.character(form_ui(tree, forms, "E2", form_groups(forms, "E2"), v)), 'id="selected_evidence"', fixed=TRUE)
})

test_that("corrected ANOVA offers a matched fixed-N check and records the warning", {
  fields <- form_fields(form_groups(forms, "E55"))
  v <- modifyList(form_examples$E55, list(goal="power", n="60", spread="differ",
    sds="1, 1, 1\n1, 1, 1", rs="0.5, 0.3, 0.4", correction="GG", method="exact"))
  spec <- build_spec(forms, "E55", fields, v)
  expect_match(gg_planning_note(spec), "unresolved", fixed=TRUE)
  calc <- list(status="ok", spec=spec, result=list(goal_type="power",
    curve=data.frame(n=60,power=.8), provenance=list(method="exact")))
  new <- corrected_anova_verification_values(calc,v)
  expect_identical(new$method, "simulation")
  expect_identical(new$n, "60")
  expect_identical(new$correction, "GG")
  calc$result$provenance$method <- "simulation"
  expect_null(corrected_anova_verification_values(calc,v))
})
