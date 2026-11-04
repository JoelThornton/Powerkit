test_that("script offers name the actual backend and its software requirements", {
  read <- engine_function("read_spec")
  for (case in list(c("E10", "mediation_simple", "power4mome"), c("E33", "crossed_two_condition", "simr"))) {
    spec <- read(file.path(repo_dir, "engine/inst/specs", paste0(case[[2]], ".json")))
    spec$options$seed <- 3L
    html <- as.character(script_offer_ui(forms, case[[1]], spec$goal$type, 3L, spec = spec))
    expect_match(html, paste0("with ", case[[3]], " alone"), fixed = TRUE)
    expect_match(html, "records the package versions", fixed = TRUE)
    if (case[[3]] == "simr") {
      expect_match(html, "lmerTest", fixed = TRUE)
      expect_no_match(html, "power4mome", fixed = TRUE)
    }
  }
})
