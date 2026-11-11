test_that("known mediation limitations appear before numerical answers are complete", {
  fields <- form_fields(form_groups(forms,"E17"))
  values <- list(x_type="binary",method="monte_carlo_ci",goal="power")
  spec <- selected_warning_spec(forms$forms$E12,fields,values)
  expect_identical(spec$variables$X$type,"binary")
  expect_identical(spec$target_test$method,"monte_carlo_ci")
  html <- as.character(selected_evidence_ui(forms,"E17",fields,values))
  expect_match(html,"Important limitation",fixed=TRUE)
  expect_match(html,"test too liberal",fixed=TRUE)
  expect_match(html,"Complete the required answers",fixed=TRUE)
  values$method <- "ols_percentile_bootstrap"
  html <- as.character(selected_evidence_ui(forms,"E17",fields,values))
  expect_match(html,"not a calibration estimate for the selected bootstrap",fixed=TRUE)
  expect_false(grepl("test too liberal",html,fixed=TRUE))
  values$x_type <- "continuous"
  expect_false(grepl("Important limitation",as.character(selected_evidence_ui(forms,"E17",fields,values)),fixed=TRUE))
})

test_that("power offers an explicit informed shortcut and remains blank initially", {
  fields <- form_fields(form_groups(forms,"E2"))
  f <- Filter(function(f) identical(f$id,"power"),fields)[[1]]
  expect_null(f$default)
  expect_equal(f$usual,.8)
  expect_match(as.character(field_ui(f,NULL)),'data-value="0.8"',fixed=TRUE)
  expect_match(f$help,"under the population you specify",fixed=TRUE)
  paired <- form_fields(form_groups(forms,"E3"))
  r <- Filter(function(f) identical(f$id,"raw_r"),paired)[[1]]
  expect_null(r$default)
  expect_match(r$help,"no correlation is then needed",fixed=TRUE)
  expect_match(r$help,"zero is an assumption",fixed=TRUE)
  expect_identical(forms$forms$E24$effect_waits_for,"question")
})

test_that("important result limitations precede the headline and survive copied methods", {
  fields <- form_fields(form_groups(forms,"E55"))
  values <- modifyList(form_examples$E55,list(goal="power",n="60",spread="differ",
    sds="6,6,6\n6,6,6",rs=".5,.3,.4",correction="GG"))
  spec <- build_spec(forms,"E55",fields,values)
  result <- powerkit::run_spec(spec)
  calc <- list(status="ok",spec=spec,result=result)
  html <- as.character(result_panel_ui(tree,forms,"E55",fields,values,calc))
  expect_lt(regexpr("planning-critical",html)[1],regexpr('class="result-headline',html)[1])
  expect_equal(lengths(regmatches(html,gregexpr("planning-critical",html,fixed=TRUE))),1L)
  expect_match(writeup_text(forms$forms$E55,spec,result,fields,values)[["short"]],"reason is unresolved",fixed=TRUE)
  binary <- list(design="moderated_mediation",template="process_7",variables=list(X=list(type="binary")),
    target_test=list(method="monte_carlo_ci"))
  expect_match(paste(planning_warning_notes(binary),collapse=" "),"test too liberal",fixed=TRUE)
})
