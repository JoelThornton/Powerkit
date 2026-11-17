* The smallest detectable effect for the mixed models simr fits, by the
  simulated search (`mixed_model_search()` in `sensitivity-simulated.R`;
  `simr_backend()` gains `simulated_sensitivity`): participants and items
  in two conditions (the difference between them, E33), in three or more
  (the pattern of means scaled about its average, reported as the range or
  the pair compared, E63), with an item predictor (its slope, E67), a
  three-level design (d, E68) and a two- or three-level model with one
  coefficient tested (that coefficient, E41, E62). For a yes/no outcome the
  slope and coefficients are on the log odds, and the conditions' chances
  are scaled about their average on the log-odds scale, reported as an odds
  ratio. Several two-level coefficients tested together are not searched.
  Tests (`test-sensitivity-mixed-model.R`): each plan changes only the
  effect tested and the exported script's `set_effect()` sets the same
  value; a fresh simulation at the effect found and the script's
  reproduction run with the full validation.
