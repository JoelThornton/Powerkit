# The spec the item-predictor tests (test-backend-item-predictor*.R) start
# from: mixed_model / item_predictor, E67.

item_spec <- function(binary = FALSE, goal = list(type = "power", n = 30L), nrep = 100L) {
  spec <- example_spec("item_predictor")
  if (binary) {
    spec$variables$Y <- list(type = "binary", label = "Correct")
    spec$population <- list(metric = "probability", slope = 0.3, probability = 0.75, sd_participant = 0.6,
      sd_participant_slope = 0.2, sd_item = 0.5, items = 60L)
    spec$target_test$method <- "wald"
  }
  spec$goal <- goal
  spec$options <- list(nrep = nrep, seed = 6L)
  spec
}
