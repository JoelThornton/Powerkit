* Unequal groups: a group-size ratio typed as a rounded decimal (0.67, 0.33, 1.37) is now planned as the simplest whole-number split that rounds to it (2 : 3, 1 : 3, 19 : 26) when the exact split would need a step above 50 in the total sample size. Taken exactly, 0.67 is 67 : 100, so only multiples of 167 were searched and the two-group t-test returned 167 people where about 133 are needed; it now returns 135. Applies to every two-group design with `options > allocation_ratio`. The result carries the split used (`allocation`), and the app states it on the result and in the methods paragraph.
* Non-inferiority t-tests (one sample, paired, two groups) are planned as the one-sided t-test of the difference from minus the margin, with the margin fixed in the outcome's units, as G*Power's shifted-null t-tests are. pwrss's `margin` argument, used before, fixes the margin in SD units and gave sample sizes about two too small (one sample, margin 0.3, one-sided alpha .025, 80% power: 88, now 90). Checked against pwr's one-sided t-test. Sample sizes for these three designs rise slightly; two proportions are unchanged.
* A sample size search whose power does not rise with the sample (a one-sided test pointed away from the effect, or a zero effect) now says that no sample size reaches the target, instead of suggesting a larger sample might.
- Precision planning: `template_precision_one_group` and
  `template_precision_paired` accept `goal.assurance`, which
  `MBESS::ss.aipe.sm()` has always supported; the schema refused it, so the
  app's starting settings for those two estimates failed.
- App: exports no longer require a written effect-size justification
  (the write-up records that none was given); the run button is
  "Calculate"; Welch's t-test gets the explore panels; a form-level check
  catches partial eta-squared with a test version other than the
  classical F; whole-number percentages get a specific message.
- `effect_justification.type` accepts `convention` (a benchmark such as
  Cohen's small, medium or large), with advice from `validate_spec()` that
  a convention is not evidence about the effect (Lakens, 2022).
