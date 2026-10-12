# Helpers for the spec unit tests.

example_spec_names <- function() {
  files <- list.files(system.file("specs", package = "powerkit"), pattern = "\\.json$")
  sub("\\.json$", "", files)
}

example_path <- function(name) {
  system.file("specs", paste0(name, ".json"), package = "powerkit", mustWork = TRUE)
}

# An example spec as a plain list, ready to be broken by a test.
example_spec <- function(name) {
  unclass(read_spec(example_path(name), validate = FALSE))
}

# validate_spec() must reject `spec`, and one of the reported problems must
# match `pattern`. Returns the error so tests can inspect it further.
expect_spec_problem <- function(spec, pattern, fixed = TRUE) {
  err <- expect_error(validate_spec(spec), class = "powerkit_spec_error")
  expect_match(err$problems, pattern, fixed = fixed, all = FALSE)
  invisible(err)
}

expect_valid_spec <- function(spec) {
  expect_no_error(out <- validate_spec(spec))
  expect_s3_class(out, "powerkit_spec")
  invisible(out)
}
