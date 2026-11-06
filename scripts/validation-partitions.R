# Choose bounded independent jobs without reducing any test's replications.
source("scripts/run-validation.R", local = TRUE)
tests <- validation_tests(validation_root(), Sys.getenv("CHUNK"))
# Estimates are conservative planning aids, not completion guarantees.
# A single test can still exceed the host limit; its NOT RUN is retained.
count <- if (sum(tests$estimate) / 4 > 120 || max(tests$estimate) > 120) min(4L, nrow(tests)) else 1L
cat(jsonlite::toJSON(list(include = lapply(seq_len(count), function(i)
  list(index = i, count = count))), auto_unbox = TRUE))
