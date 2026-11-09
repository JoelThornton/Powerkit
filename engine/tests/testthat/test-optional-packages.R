# Backends in Suggests (R/optional-packages.R): a missing one stops the run
# with a plain message naming what to install.

test_that("a run whose backend isn't installed stops with a plain message", {
  spec <- read_spec(system.file("specs", "tost_independent.json", package = "powerkit"))
  local_mocked_bindings(package_installed = function(package) !identical(package, "TOSTER"))
  expect_error(
    run_spec(spec),
    "needs the R package 'TOSTER', which isn't installed. Install it with install.packages(\"TOSTER\")",
    fixed = TRUE, class = "powerkit_missing_package"
  )
})

test_that("the message names every missing package once", {
  expect_identical(
    missing_packages_message(c("ARTool", "vegan")),
    paste(
      "This analysis needs the R packages 'ARTool' and 'vegan', which aren't installed.",
      "Install them with install.packages(c(\"ARTool\", \"vegan\")), then run it again."
    )
  )
  expect_true(need_packages(c("stats", "powerkit")))
})

test_that("a backend call that can't load its package gives the same message", {
  expect_error(
    call_backend("nopackage", loadNamespace("powerkitNoSuchPackage")),
    "needs the R package 'powerkitNoSuchPackage'",
    fixed = TRUE, class = "powerkit_missing_package"
  )
})

test_that("optional_packages() reads the installed Suggests", {
  optional <- optional_packages()
  expect_true(all(c("TOSTER", "semPower", "testthat") %in% optional))
  expect_false("pwr" %in% optional)
})

test_that("the CRAN test set names files that exist", {
  # tests/testthat.R runs only these files when NOT_CRAN isn't "true".
  runner <- test_path("..", "testthat.R")
  skip_if_not(file.exists(runner), "tests/testthat.R not found (installed tests)")
  env <- new.env()
  lines <- readLines(runner)
  start <- grep("^cran_files <- c\\(", lines)
  end <- start + which(grepl("^\\)", lines[start:length(lines)]))[1] - 1
  files <- eval(parse(text = lines[start:end]), env)
  expect_true(all(file.exists(test_path(paste0("test-", files, ".R")))), label = paste(files, collapse = ", "))
})
