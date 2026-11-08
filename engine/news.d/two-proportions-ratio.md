* Two proportions (`two_proportions`) take a published odds ratio or risk
  ratio in `effect_justification > conversion` (`from` "odds_ratio" or
  "risk_ratio"), with group 1's proportion in `population > p1`:
  `convert_effect(..., p0 = )` gives group 2's proportion, an odds ratio
  through effectsize's `oddsratio_to_riskratio()` times p1, a risk ratio
  as RR times p1 (base R; not added to the provenance's packages). A ratio
  that would put group 2's proportion at 1 or more is refused in words.
