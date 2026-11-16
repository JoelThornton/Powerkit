* No pre-selected count model on the repeated-measures counts card (E75,
  `glmm_distribution`) or on moderation and mediation with a count
  outcome (E32, `count_model` and `med_count_model`): the researcher
  chooses Poisson or negative binomial, and the help says what each
  costs (`decisions.md`, 16 November 2026). E28 keeps Poisson.
* Simple mediation's quick estimate (joint significance) is labelled
  "Validation in progress" in its choice note, the result's estimate
  notice and E10's validation note: the 16 October full run covers the
  Monte Carlo simulation only.
* Exported R scripts list the variant evidence record in a closing
  "Checks recorded for this analysis" section, which says that "no
  linked record" is not a failed check, instead of in the header before
  the code (`evidence_section()`).
* Plain wording: a number field typed with a % sign says what proportion
  to type; the non-numeric message gives a neutral example; two
  spec-check messages name the screen's goal choices instead of "goal
  type 'power'"; the paired d_z box says what d_z is; the effect-size
  help describes the rule-of-thumb source instead of discouraging it.
