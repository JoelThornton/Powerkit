# Mediation and PROCESS-style planning

10 November 2026. Prototype implementation in the open review PR (0.61.0 candidate).

PROCESS is a way to analyse mediation, not a different scientific design.
Powerkit now asks which estimation and interval method the researcher will
use, on each supported mediation and moderated-mediation form.

| Planned analysis | Powerkit choice | Default draws per study |
| --- | --- | --- |
| Ordinary regression, including the usual complete-data PROCESS approach | Ordinary regression + percentile bootstrap (PROCESS-style) | 5,000 casewise resamples |
| A path model fitted by maximum likelihood with a Monte Carlo interval | Maximum likelihood + Monte Carlo interval | 1,000 Monte Carlo draws |
| A path model fitted by maximum likelihood with a bootstrap interval | Maximum likelihood + percentile bootstrap | 1,000 resamples (existing engine default) |

The count is a numerical accuracy setting, not a population assumption. It
is optional and can be changed to match the analysis. The method remains
visible on the form and result, in copied methods, in saved projects and
in the standalone R script. Existing saved plans retain their method.

## What the PROCESS-style choice does

The existing power4mome generator creates studies from the entered
standardised population: continuous exogenous variables and equation errors
are normal, with binary X/W where specified. Products and binary groups can
make the marginal outcomes non-normal; this is not arbitrary score-shape
or missing-data simulation. Each regression equation is fitted by OLS through lmhelprs.
Manymome resamples whole observations and computes the selected indirect
effect, index, or conditional indirect-effect difference. Its percentile
interval uses boot::boot.ci. A study counts as significant when the chosen
confidence interval excludes zero. Powerkit adapts these packages; it does
not implement a new power formula or include the PROCESS software.

The separate formula-only and whole-study routes are unchanged. A PROCESS
model number alone never establishes agreement: the target indirect path,
regressions, coding, resampling unit, interval and confidence level matter.
Use the same settings when analysing the actual study.

The option covers the displayed complete-data models with independent
observations and continuous mediators and outcomes. Supported binary X/W
settings retain their recorded coding and population assumptions. It does
not support every PROCESS option: logistic outcomes, arbitrary covariates,
clustered/stratified bootstrap, missing-data mechanisms, measurement-error
correction and bias-corrected intervals require distinct implementations
and checks. Attrition only adjusts the recruitment count.

## Running a bootstrap plan

Bootstrap options go directly to the downloaded R script for both power
and sample size. They do not use the old Monte Carlo preview time or
silently reduce the chosen resample count. The script preserves the full
specification, package requirements and seed, then saves the result,
backend-only reproduction script, citations and an app project file that
can reopen the finished result without recomputation. This currently requires R
and Powerkit on the researcher's computer; it is not an instant browser
calculation. The existing Monte Carlo browser workflow is unchanged.

A local Windows/R 4.5.3 probe of four simple-mediation studies at N = 250
and 1,000 resamples took 11.44 seconds. This is a small timing probe, not
a stable prediction for every model or machine. Thousands of studies with
5,000 resamples each can take hours; the interface says so before starting.

## Evidence and remaining work

- [x] Add an explicit OLS + percentile-bootstrap engine method and schema option.
- [x] Keep both existing ML methods unchanged.
- [x] Expose method and resample settings on all nine applicable forms.
- [x] Keep the method in results, saved settings and standalone exports.
- [x] Route bootstrap plans to the local script without a misleading quick-preview estimate.
- [x] Fix project reopening for the supported longer simulation routes,
  which previously rejected mediation projects despite their available forms.
- [x] Compare estimates, intervals and significance decisions with separate
  base-R equation fits on identical observations and bootstrap indices,
  across simple, parallel, serial, models 7/14 with one or parallel
  mediators, and conditional-difference models 8/58/59 examples. These are
  scoped numerical checks, not population-wide power validation.
- [x] Verify the complete local-script-to-app-project handoff end to end.
- [x] Reproduce a selected OLS/bootstrap power calculation in a standalone
  R script without loading Powerkit.
- [x] Complete and archive the selected process_bootstrap null-calibration
  chunk: two passes and one archived-PROCESS-reference skip.
- [ ] Archive a direct comparison with a named PROCESS version, exact
  data/settings and resamples before claiming PROCESS-software equivalence.
- [ ] Obtain independently published numerical comparisons where available.
- [x] Link the two recorded null scenarios in the existing evidence registry,
  scoped to N=250, alpha .05, 1,000 resamples and the archived model settings.
- [ ] Extend evidence to other models/nulls and the 5,000-resample default;
  do not treat these two checks as validation of every bootstrap plan.

The existing binary-X ML/Monte-Carlo calibration failure remains open.
Selecting a bootstrap does not itself prove that failure is resolved; its
calibration is checked separately. Low-resample unit checks also emit
manymome warnings in some conditional-model checks about extra product-term
moderators set to zero; the tested estimates and intervals match the
explicit regression reference, but the warning deserves author review.
No package author has been contacted or asked to endorse this work.

## Sources checked

- [Hayes FAQ](https://www.afhayes.com/faq.html): OLS for continuous outcomes;
  percentile bootstrap is the default from PROCESS version 3 onwards.
- [PROCESS addendum](https://www.afhayes.com/public/processdocaddendum.pdf):
  casewise bootstrap and the separate clustered/stratified options.
- [power4mome fit_model](https://sfcheung.github.io/power4mome/reference/fit_model.html)
  and [power4test](https://sfcheung.github.io/power4mome/reference/power4test.html):
  lm fitting and bootstrap selection. Checked against installed power4mome
  0.2.1, manymome 0.3.7 and lmhelprs 0.4.5, rather than relying only on the
  newer development documentation.

Random seeds and finite resampling can produce different numerical output
from another program. Exact PROCESS percentile endpoint conventions have
not yet been compared directly. No existing whole-card badge is evidence
for every setting of this new method.

The latest hosted result-screen check exposed method-omitted historical
metadata being described as bootstrap. The helper now uses the existing
Monte Carlo default for that metadata; the explicit bootstrap warning stays
separate. The missing OLS-example zero-effect registry entry found by the
engine/CRAN checks is also corrected. Hosted reruns are still required.

Local checks completed: independent equation/interval comparisons, a
backend-only reproduction, an executed local-run script with saved and
restored analysis metadata, existing power4mome and standard-result
regressions, all forms, project handling, documentation alignment, source
inventory, repository consistency and Updates checks. The conditional-model
warnings above and existing upstream deprecation warnings remain recorded;
none is represented as a resolved scientific validation result.

The [completed calibration](validation/2026-11-10-process-bootstrap-summary.txt)
ran 2,000 studies per scenario with 1,000 resamples each: simple-mediation
null rejection .0495 (99/2,000), binary-X model-7 index null .0585
(117/2,000). Both meet the pre-existing [.04,.06] rule at alpha .05.
The [settings and frozen source identities](validation/2026-11-10-process-bootstrap.json)
are archived; adapter/helper/test Git blobs match the later candidate.
This is not a direct PROCESS-software comparison, a test of the interface's
5,000-resample default, or a resolution of the existing ML/Monte-Carlo
failure. No card badge is upgraded.
