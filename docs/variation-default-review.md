# Explicit effect assumptions: review and checklist

10 November 2026. Approved by the maintainer; included in the open review PR.
This is an interface/default correction, not new validation of the formulas.

## What a new ordinary plan means

For one-sample, paired and independent t-tests and Pearson correlation,
new plans calculate power at the effect entered. Between-study variation
starts empty. That does not assert that effects really are identical
everywhere; it states the condition on which this particular answer rests.

A researcher can intentionally enter variation to average significance
across differing true study effects. This can raise or lower the answer.
It does not guarantee target power at the average effect or in each setting.
Two-sided significance counts either direction and does not establish that
the average effect across settings differs from zero.

For example, using the existing t-test variation backend with two equal
groups, d = .01, variation SD = .05, two-sided alpha = .05 and total
N = 100,000 gives .809425 average significance, versus .352603 with no
variation. This is a deliberately extreme illustration of different
questions, not evidence that variation usually lowers the N for an 80% plan.
For the existing d = .3, 80% example, variation instead increases N from
352 to 376. The engine formulas and published expected values are unchanged.

The literature gives good reasons to examine heterogeneity. This policy
does not reject those reasons. McShane and Bockenholt explicitly advocate
sensitivity comparisons and caution against treating particular
heterogeneity benchmarks as universal rules.
Sources: [McShane and Bockenholt (2014)](https://doi.org/10.1177/1745691614548513),
[Kenny and Judd (2019)](https://doi.org/10.1037/met0000209); existing
implementation references and restrictions are in [conventions.md](conventions.md).

## Implementation checklist

- [x] Start new ordinary plans without an assumed variation magnitude.
- [x] Keep the optional variation field and its existing restrictions.
- [x] Explain the change of question before calculation and in results/methods.
- [x] Preserve explicit values in existing saved plans, including zero.
- [x] Keep smaller/larger-effect comparisons visible without suggesting their values.
- [x] Include the exact analysed sample size in each scenario curve.
- [x] Display scenario power at that sample size directly, without interpolating plotted points.
- [x] Update the decision record, conventions, status, queue and generated inventory.
- [x] Check new defaults, restored values, exported wording and exact-N scenario power.
- [x] Check saved projects, generated inventory and repository consistency.
- [ ] Finish the wider departure audit, especially mediation versus PROCESS,
  continuity correction, random predictors and multiple-claim targets.
- [ ] Merge and verify the deployed app after review.

The engine is still a prototype with outstanding scientific validation
issues. These changes prevent one silent change of question; they cannot
guarantee achieved power when planning assumptions are wrong.

Local verification: the broader result-screen file initially stopped at its
interrupted-time-series check because the private test library lacked PITS.
Restoring the lockfile's PITS 0.1.0 and rerunning that check passed. The
remaining result checks had no failures, with seven intentional CRAN-mode
skips and warnings from deliberately small simulation fixtures. Focused
default/scenario/inventory checks and project/consistency checks pass. Hosted
checks on the new PR head remain a separate release gate.
