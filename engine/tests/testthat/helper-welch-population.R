welch_spread_spec <- function(method = "exact", raw = TRUE) {
  spec <- example_spec("independent_t")
  spec$target_test$method <- "welch_t"
  spec$goal <- list(type = "power", n = 120)
  spec$options <- list(method = method, allocation_ratio = 2, seed = 177, nrep = 1000)
  spec$population <- if (raw) list(metric = "raw", raw = list(mean_1 = 20, mean_2 = 24, sd1 = 5, sd2 = 15)) else
    list(metric = "standardised", d = 4 / sqrt(125), sd_ratio = 3)
  validate_spec(spec)
}
