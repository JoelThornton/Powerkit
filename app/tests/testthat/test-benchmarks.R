test_that("benchmark specs are valid", {
  for (b in benchmarks_2x2) {
    expect_true(engine_call(validate_spec(benchmark_spec(b)))$ok, info = b$id)
  }
})

test_that("the engine reproduces every published benchmark", {
  for (b in benchmarks_2x2) {
    row <- benchmark_row(b, engine_call(run_spec(benchmark_spec(b))))
    expect_match(row$Agreement, "matches", info = paste(b$id, row$powerkit))
  }
})

test_that("unrun benchmarks say so", {
  expect_identical(benchmark_row(benchmarks_2x2[[1]])$powerkit, "not run yet")
})
