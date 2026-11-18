* Mediation with a mediator in three or more ordered categories (E39,
  template `ordinal_mediator`): the latent-response model, simulated by
  Spower and analysed by `lavaan::sem()` with the mediator (and a yes/no
  outcome) declared ordered, WLSMV and the theta parameterisation; the
  indirect effect a*b is tested by the delta method. X two groups or a
  score, Y a score or yes/no. New `backend-mediation-ordm.R`, schema
  definition `template_mediation_ordinal_mediator` (population metric
  `latent_response`: `m_probabilities`, `a`, `b`, `direct`, `y_baseline`),
  example spec, check run, simulated-data code and exported R script, and
  the validation chunk `mediation_ordm` (an independent simulation in
  lavaan's delta parameterisation with its own delta-method test, and the
  Type I error).
