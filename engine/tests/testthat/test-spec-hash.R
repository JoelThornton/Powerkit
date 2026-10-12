reverse_names <- function(x) {
  if (!is.list(x)) {
    return(x)
  }
  if (!is.null(names(x))) {
    x <- rev(x)
  }
  lapply(x, reverse_names)
}

test_that("spec_hash() is a SHA-256 hex string", {
  hash <- spec_hash(read_spec(example_path("process_7")))
  expect_match(hash, "^[0-9a-f]{64}$")
})

test_that("field order and whitespace don't change the hash", {
  spec <- example_spec("process_7")
  compact <- jsonlite::toJSON(spec, auto_unbox = TRUE, digits = NA)
  expect_identical(spec_hash(reverse_names(spec)), spec_hash(spec))
  expect_identical(spec_hash(read_spec(compact)), spec_hash(spec))
})

test_that("a spec built in R hashes the same as the same spec from JSON", {
  built <- example_spec("anova_2x2_between")
  built$population$means <- matrix(c(10, 10, 10, 13), nrow = 2, byrow = TRUE)
  expect_identical(spec_hash(built), spec_hash(example_spec("anova_2x2_between")))
})

test_that("any change of value changes the hash", {
  spec <- example_spec("process_7")
  changed <- spec
  changed$population$paths[["XW->M"]] <- 0.16
  expect_false(identical(spec_hash(changed), spec_hash(spec)))
  changed <- spec
  changed$options$seed <- spec$options$seed + 1
  expect_false(identical(spec_hash(changed), spec_hash(spec)))
})
