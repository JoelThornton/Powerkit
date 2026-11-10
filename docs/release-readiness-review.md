# Powerkit: scientific, researcher and release review

10 November 2026. Reviewed v0.59.0, source `4758821874b1909d777c2cd4eaea7b9a089b2c6c`, against the previously checked v0.33.0 merge `3340dd8c11a7495c002628e01f5c081a8cd601aa`.

## Overall assessment

Powerkit is substantially more capable, but its next milestone should be a trustworthy, understandable set of research workflows rather than another count of supported tests. It is a promising development prototype, not yet a generally validated planning product or a CRAN-ready release.

Since the earlier review, 93 commits have reached main. Important additions include EFA, latent profiles, cross-lagged panels, interrupted time series, replication planning, small telescopes, between-study variation, Bayesian design priors, joint planning, planning-document downloads, and optional engine backends. Welch defaults, explicit choices of alpha and power, better routing and background computation are useful improvements. These additions need individual evaluation; their presence does not establish validity.

The source describes 70 running cards out of 77, 55 direct calculation routes, 20 cards with historical validation status and 17 transcribed published examples. Those are project records, not independently re-established totals for every current variant. Ordinary checks on the reviewed main revision passed. The latest scheduled validation inspected was [run 42570428222](https://github.com/JoelThornton/Powerkit/actions/runs/42570428222), at `1539d39`, engine 0.57.0, on 9 November. It still failed the mixed-design Greenhouse-Geisser comparison and binary-X moderated-mediation null check. It does not validate all later v0.59.0 changes.

This review inspected source, change history, hosted check results and the two failing jobs. A live v0.59.0 session opened successfully; the start, analysis list, two-group card and its input screen were inspected. This is not a new every-card walkthrough, full mathematical proof, fresh installation benchmark or participant usability study.

## Fix checklist

The corrections below merged in [PR #367](https://github.com/JoelThornton/Powerkit/pull/367), v0.60.0, main 950b7ad. Checked means completed within the stated scope; it does not mean deployed, independently endorsed or scientifically validated. The follow-on [first-release support plan](v1-support-plan.md) operationalises R15–R28; its inventory and protocol do not complete those scientific or human reviews.

### Corrections and practical preparation in this branch

- [x] R01. Keep historical ordinary-test evidence separate from between-study variation and small-telescopes decision rules. Previously a matching template could attach evidence for a different calculation.
- [x] R02. Explain when a sensitivity target is already reached at an average effect of zero. Variation between studies can produce significant individual studies even with zero average effect; root-finding must not fail cryptically or imply a positive detectable average.
- [x] R03. Describe the two-group default consistently as Welch's test and identify its formula provider. The live card still named Student's first. It now distinguishes the Welch formula from the pwr adjustment used when between-study variation is included.
- [x] R04. Remove the blanket claim that all non-simulated Bayesian planning is exact. bfpwr's documented t-test approximation matters at small samples.
- [x] R05. Scope the binary-X warning to the checked model/scenario and stop implying authors have already been contacted. Preserve the failure and the original test constants.
- [x] R06. Put the known Greenhouse-Geisser disagreement in the affected larger-mixed-design card/input warning, before a researcher relies on a calculation.
- [x] R07. Prevent the local launcher from installing changed engine files while an older engine namespace remains loaded. Ask for a fresh R session instead of silently combining software versions.
- [x] R08. Offer a clear website download route and explain local CPU use, first-install requirements, offline limits, and the distinction between the CRAN engine and the complete app.
- [x] R09. Add an optional, read-only update check for numbered releases, including clearly labelled prototypes. No study data is sent and no code is automatically installed or replaced.
- [x] R10. Recommend numbered full-app downloads and a separate folder/fresh R session for updates. Keep old versions and saved studies; the main ZIP is a development snapshot.
- [x] R11. Exercise the actual CRAN test branch with current repository dependencies on R release and devel. The added Linux workflow passed on R release and devel with current hard dependencies and NOT_CRAN=false (run 42735853076, final head 8ac0268). Locked CI remains a separate check; optional backends and other operating systems remain R29.
- [x] R12. Prepare the author-review and paper protocol below, with a clear distinction between technical questions, collaboration and endorsement.
- [x] R13. Document the release gates and give every remaining recommendation an explicit owner action or acceptance condition.

### Scientific work still required

- [ ] R14. Resolve the two repeated validation failures. The inspected ANOVA job gives simulated power .2130 versus .2313 by the exact-data route; the binary-X job gives a null rejection rate .077 in 1,000 simulations, above its .0707 tolerance. Earlier recorded rates differ. The 10 November independent GG investigation now records .21805 in 20,000, same-data afex agreement and .21960 with fixed epsilon; estimating epsilon alone does not explain .2313. See validation-log.md. Both issues remain unresolved. Establish the cause on a frozen version before changing a method or a threshold; do not tune seeds or expected values to obtain a pass.
- [ ] R15. Complete a release-specific, variant-specific evidence matrix and publish the underlying results. The existing registry is now dated 10 November and links scoped corrected-count and two OLS/bootstrap null checks; the queue refers to extending it. Most new routes still need linked, release-specific evidence. Each default needs appropriate evidence; unknown remains unknown.
- [ ] R16. Replace a single green-card interpretation with evidence for the selected test, population assumptions and analysis. A fixed Type I tolerance of .04-.06 at alpha .05 is not sufficient for every exact, discrete, conservative, equivalence or Bayesian procedure. Predefine method-appropriate acceptance criteria and Monte Carlo uncertainty; retain historical definitions as history.
- [ ] R17. Validate complete analysis pipelines, including failures. Compare planned versus achieved power at the returned integer N using fresh random draws; assess null behaviour, interval coverage, bias and convergence. Counts of successful runs alone can conceal selection. Use [ADEMP](https://doi.org/10.1002/sim.8086): aims, data generation, estimands, methods and performance measures.
- [ ] R18. Validate claims newly introduced by EFA, profiles, cross-lagged and interrupted-series cards. Recovering loadings or selecting a number of profiles is not ordinary rejection power. Model selection, factor rotation, inadmissible fits, local maxima, stationarity, time spacing and short-series calibration need explicit boundaries. Request family specialists; do not infer assurance from successful execution.
- [ ] R19. Independently review whole-study planning. Define whether success means all primary claims, any, a conjunction, or a hierarchy; keep exploratory/manipulation checks separate. Validate multiplicity, covariance, shared data and estimand alignment. A significant indirect path alone does not establish a causal mechanism.
- [ ] R20. This branch refuses Welch plus between-study variation with unequal allocation: the adjustment uses Student's degrees of freedom, which are different for unequal groups even with equal population SDs. Equal-allocation use retains the documented approximation. The maintainer reviewed the between-study defaults on 10 November: new ordinary plans now start without variation, and nonzero variation is an explicit optional scenario. A literature-motivated tau is still a substantive assumption, and a single population's power differs from success averaged over settings. Keep both meanings visible. Zero-average rejection under heterogeneity is not a Type I error under a point null for each study. Validate unequal allocation and both tails across an agreed range before broad claims.
- [ ] R21. Make each simulation correspond to the analysis researchers will actually run. PROCESS percentile bootstrap, Monte Carlo intervals, lmer tests and alternative robust/rank analyses need separately identified targets. The OLS/casewise-bootstrap and corrected-count routes are now selectable, with scoped checks; the OLS chunk passed its two named null scenarios with 1,000 resamples. Direct PROCESS comparisons and broader pipelines remain unfinished. Generic missing-data, noncompliance, exclusions and measurement-error handling cannot be inferred from an attrition percentage or a selectable score shape.
- [x] R22. Correct the crossover scope claim: the paired card/input now cover only an ordinary paired analysis with no period, sequence or carry-over terms, and copied methods state this. Remove the one-degree-of-freedom/close-approximation assurance. The mixed card/input also disclaims a separately validated crossover analysis. A dedicated validated crossover model remains open in the roadmap; this check completes the misleading-scope correction, not that new capability.

### Researcher experience and fundamental design decisions

- [ ] R23. Test a question-first entry route: “How many people can I recruit?”, “How precise must the answer be?”, “What effect matters?” or “What evidence would change my decision?”. Choosing a test is not always the researcher's first problem. Preserve expert access to named analyses.
- [ ] R24. Reconsider compulsory blank alpha/power/prior boxes. They prevent accidental defaults but can demand expertise a newcomer lacks. Offer an explicit informed choice with a short consequence, help and editable value; measure comprehension instead of treating more clicks as better justification. An optional rationale is not evidence of a defensible choice.
- [ ] R25. Make unknown numbers a supported workflow across specialist models: source, plausible range, sensitivity and an honest “not enough information yet” outcome. For multiple nuisance parameters, show a small coherent scenario table rather than asking researchers to invent a full covariance matrix. Never silently replace uncertainty with zero.
- [ ] R26. Elicit Bayesian design priors in meaningful ranges as well as SDs, distinguish design from analysis priors, and check the reader's understanding. Switching to “Bayes mode” cannot make an unspecified scientific hypothesis or prior defensible. A prior that reproduces an earlier estimate does not automatically address publication selection.
- [ ] R27. Keep the result's answer, analysed/recruited counts and major limitations visible; fold secondary material. Connect the saved plan to preregistration and the analysis script. Support fixed numbers of schools, dyads or items where these are the real constraints. Existing recruitment and scenario helpers are foundations, not generic solutions to all clustered recruitment.
- [ ] R28. Run the existing researcher sessions and manual accessibility checks. Include psychology students and experienced researchers, a fixed-budget task, an unknown correlation, a published adjusted estimate and a specialist design. Measure correct decisions, input mistakes, completion, time and confidence, not satisfaction alone. Compare fairly with the actual alternative each participant would use; do not claim universal superiority.

### Distribution and maintenance

- [ ] R29. Test the candidate tarball with current CRAN dependencies on Linux, Windows and macOS, R release/devel and only required dependencies. Run examples, minimal-dependency tests and a separate full optional-backend suite. The new workflow is a readiness check, not submission or full scientific validation. Check the current and historical package name, licences/borrowed code, installed size, documentation, URLs, notes and maintainer contact before submission. Prepare cran-comments.md from real results.
- [ ] R30. Treat the engine, GUI and download launcher as distinct products with one release manifest. CRAN installation alone currently gives the engine, not a local GUI. Decide whether a companion GUI package or full-app bundle is maintained. Do not duplicate mathematical implementations to achieve portability.
- [ ] R31. Connection recovery and engine-install status checks are now implemented in the follow-on PR. An isolated Windows binary restore of three locked packages recovered real TLS failures; this is not the complete acceptance test. Measure clean install size/time and first/repeat startup, including university machines without admin rights, Intel and Apple-silicon Macs, and Linux. Optional backends help engine users, but the full-app launcher still restores the complete lock environment. A dependency count is not a measured download improvement.
- [ ] R32. Build a signed/notarised desktop installer only after the R-based route passes usability and update tests. Bundle a compatible runtime where appropriate, retain required licences/source access, bind local services to loopback, test interruption/rollback and avoid silent method-changing updates. Evaluate institutional IT restrictions before committing to Electron or another shell.
- [ ] R33. Prototype a limited browser-compute route with webR/Shinylive. [Shinylive](https://posit-dev.github.io/r-shinylive/) can run Shiny on the user's device, but package binaries must be compatible with WebAssembly; source installation and desktop process workers cannot be assumed. Start with basic formula routes, compare results and memory/time, then decide. A PWA or downloaded HTML by itself does not move R computation off Posit.
- [ ] R34. Verify GitHub Pages activation, public URLs and search indexing. A failed fetch in this review is not proof the page is down. Add the new download page to the sitemap and verify it after deployment. Local use also needs offline-start and optional-feedback/update tests; do not promise air-gapped installation.
- [ ] R35. Establish a release channel and scientific-change policy. Keep stable/reviewed, prototype and development revisions distinct. Detect package-version drift, retain source/lock/checksum metadata and archive long-run evidence beyond the current 30-day Actions retention. Release notes must explain changed numerical answers. Do not automatically upload or recompute old projects.
- [ ] R36. Measure hosted use and concurrency, then set per-visitor limits. Local downloads reduce calculation load only when users actually launch them locally. Session-bound workers, disconnects and costs remain hosting limitations. Introduce persistent job storage based on measured need, with explicit retention and retrieval rules.

## Preparing package-author contact and a validation paper

Do not wait until every validation is finished to ask narrow technical questions: an answer about a model or argument could change the validation design. First reproduce the question against the installed version, and, separately, the current public version. Check existing issues and package help. An old-version result is not a current-version bug report.

Use one short dossier per package/family. It should contain the package/version and source; exact exported function/arguments; target hypothesis and effect units; a minimal direct-package R example with sessionInfo and seed; Powerkit's translation and workaround; expected behaviour and its source; observed behaviour with uncertainty, failures and sample sizes; and two or three answerable questions. Separate confirmed discrepancies from documentation ambiguity and requests for new features. Include a de-identified public issue only with suitable professional wording; private correspondence stays outside the repository.

### First contacts to prepare

| Package/family | First technical question | Evidence to attach |
|---|---|---|
| power4mome / manymome | Binary-X interval calibration, fitted product/residual handling, recommended interval settings and PROCESS comparability | Existing question 6, dated null runs and independent OLS interval; distinguish the model 7 case from all models |
| Superpower | Population epsilon in ANOVA_exact versus estimated epsilon in ANOVA_power; which route represents the planned corrected analysis? | Exact mixed-covariance spec and failing job, Monte Carlo uncertainty and independent reruns |
| bfpwr | Small-N t-test approximation and asymmetric informed-prior critical regions; behaviour in the current release | Historical 0.1.6 example plus a new current-version comparison before sending |
| BayesRepDesign | Meaning of level for TOST and applicability of normal/known-SE replication approximations | Existing direct call, the 2*alpha translation and closed-form comparison |
| Spower | Direction/unequal-group handling in variance tests and nonzero-null correlation direction | Existing docs/upstream/spower-var-test.R and the restricted/bypassed routes |
| powertools | Binary-outcome multiplier, unequal-cluster formula and covariate variance definitions | Direct function calls, documented algebra and current restrictions |
| longpower / irtpwr / metapower | Their separately recorded numerical/interface questions; appropriateness of current workarounds | Existing reproductions, exact affected versions and comparisons where both routes run |
| powRICLPM / PITS / psych / mclust / semPower / PUMP | Whether the generator, estimand, fit success and success criterion reflect intended use | A compact supported-variants table, direct examples and validation design for each family |

Verify each maintainer/contact and current release from the package's official metadata immediately before contact. Do not invent addresses, assume one author speaks for every coauthor, or send one mass request asking people to certify the whole product.

Offer three independent levels of involvement: a brief technical answer; review of that family's adapter/validation design; or an active contribution to study design, interpretation and writing. A technical reply is not endorsement, approval of Powerkit, or automatic paper authorship. Agree contributions and consent explicitly. Use the intended journal's authorship policy; [CRediT](https://credit.niso.org/) records roles, while [ICMJE](https://www.icmje.org/recommendations/browse/roles-and-responsibilities/defining-the-role-of-authors-and-contributors.html) provides one possible authorship/accountability framework, not a universal psychology-journal rule. Acknowledgement also needs permission. Preserve unfavourable results even when a package's author becomes a collaborator.

### Before calling the paper's evidence complete

- [ ] P01. Freeze a release candidate and prerecord the supported estimands, scenarios and pass/qualification rules.
- [ ] P02. Design independent reference calculations that do not reuse the same backend, generator or erroneous translation on both sides.
- [ ] P03. Cover nulls, meaningful alternatives, boundary cases, allocations, correlations, nonnormality and failures, with simulation effort chosen from a Monte Carlo precision goal. Discrete/conservative procedures need appropriate criteria.
- [ ] P04. Validate the returned sample-size decision using fresh simulation, separately from searching for it; give uncertainty and failed-fit denominators.
- [ ] P05. Add independently transcribed published cases, with source/page/table, units and a second transcription check. Leave unresolved placeholders visibly pending.
- [ ] P06. Test source versus installed package, locked versus current backends, OS/R versions, serial/parallel seeds, and exported-script reproduction.
- [ ] P07. Complete researcher comprehension/usability and manual accessibility work; keep it a separate study from numerical validation.
- [ ] P08. Archive machine-readable scenarios, code, summaries, failures and environment manifests in a durable, citable repository with an agreed release DOI.
- [ ] P09. Have family experts review interpretations and an independent statistician challenge the full chain from question to reported result.
- [ ] P10. Record replies/consent/contributions privately; describe the public validation without implying unreceived endorsement. No contact has been made as part of this review.

For researcher planning, the conceptual foundation should remain the inferential goal and information a study can provide, not a ritual target of .80/.05; see [Lakens, Sample Size Justification](https://doi.org/10.1525/collabra.33267). Small telescopes, safeguard effects, assurance and precision are different answers, not interchangeable corrections for every uncertain effect.

## Recommended order and release gates

1. Review the concrete corrections in R01-R13. Keep this PR open until maintainer review; do not publish its app or submit to CRAN from this branch.
2. Resolve R14 with the family authors/statistician and extend R15-R21 around an agreed first-release scope. If a specialist route cannot meet the standard, explicitly keep it experimental or outside the supported first release.
3. Run R28's user/accessibility work. Use its errors and hesitation to decide R23-R27, rather than assuming the current four-screen structure or blank fields must stay.
4. Choose and measure the local route, finish latest-dependency/OS checks, and verify the hosted/static site. A stable engine can be released separately from an experimental GUI if its scope is clear.
5. Submit to CRAN only after its actual candidate passes the agreed checks and scientific claims match the evidence. [CRAN policy](https://cran.r-project.org/web/packages/policies.html) requires current dependency compatibility, short checks/examples, conditional optional packages and limited resource use. A successful CRAN check is not a statistical endorsement.

The new readiness workflow intentionally tests the quick CRAN suite with current hard dependencies. It does not replace the complete locked suite, optional-backend checks, win-builder, manual audit or high-replication validation. Any new failure must be reported, not converted into a green claim.

## Checks for the merged correction

Focused engine tests for evidence routing and between-study variation: 326 assertions passed in the final focused run, with no failures, warnings or skips. New local-distribution checks and final repository consistency passed. The consistency check caught a missing documentation-index link and a change-note formatting error; both were corrected. After numbering the batch, the isolated engine library was refreshed so its version matched the source. The full hosted app suite then caught sitemap, endpoint-documentation and glossary alignment failures; these were corrected and the focused connection/documentation/local-distribution checks pass. The optional checker also successfully read the real public GitHub release list without installing anything. Final required hosted checks passed, including engine/app/browser/manifest, clean Windows/macOS launchers and Linux CRAN quick suites on R release/devel. PR #367 merged at 950b7ad. This does not establish that the hosted app has republished. Existing high-replication validation failures are untouched.

## Wording audit: first pass and remaining sweep

The open review PR includes an initial pass over interpretation-critical
text. No engine formula, numeric benchmark or claim-planning default changes
in this pass. Each correction must agree with the selected computation and
its recorded evidence; a shorter sentence must not hide an assumption.

- [x] Correct the assertion that equal group sizes make Welch and Student
  require the same N regardless of group spreads.
- [x] Explain before calculation that the interaction R-squared route uses a
  formula while its correlation route simulates newly sampled predictors.
- [x] Remove the implied universal 1.4-point/3%-N bound and direct G*Power
  comparison: the recorded 72-case grid compared InteractionPoweR methods.
- [x] Stop extrapolating the two-way comparison to a supposedly small
  three-way discrepancy that has not been measured.
- [x] Label interaction sensitivity as a formula approximation, with an
  instruction to verify power for the proposed effect at the planned N.
- [x] State that one Bonferroni-adjusted test's power is not the probability
  that any of the family's tests succeeds.
- [x] Say the all-tests rule plans this test; every other required test must
  meet the target under common assumptions, with independent decisions for
  the product rule. It does not verify the other tests.
- [x] Replace the blanket claim that other tools must assume independence
  with a description of the supported experimental whole-study calculation.
- [x] Explain the zero-main-effect-R-squared assumption without calling it
  generally safe against other misspecified inputs.
- [x] Audit conventional display names for all 77 analysis entries and
  14 families. Compact mode removes duplicate explanatory subtitles and
  shares names across list/card/form/recent-entry headings; common test
  selectors are short while method guidance and warnings stay visible.
- [ ] Review all remaining finder questions, card summaries and alternative-method text.
- [ ] Review all form labels, defaults, optional/required fields, tooltips,
  errors and empty states; check that people know what to do when unsure.
- [ ] Review all result variants, warning visibility, uncertainty, methods,
  technical details and saved-result restoration, including Bayesian routes.
- [ ] Review Labs, About, glossary, evidence explanations and citations.
- [ ] Review static-site copy, local installation/update instructions, data
  and project downloads, generated R scripts and planning documents.
- [ ] Walk through complete tasks on desktop/mobile; remove repetition while
  keeping the answer, analysis identity and key assumptions visible.
- [x] Check three selected analytic sensitivity thresholds with fresh
  10,000-study simulations; archive settings, seeds and uncertainty.
- [ ] Finish the method work wording cannot solve: audit broader interaction parameter settings
  after the matched-verification handoff,
  and verify family-level success independently under common populations.

Sources checked: [R t.test](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/t.test.html),
[InteractionPoweR analytic method](https://dbaranger.github.io/InteractionPoweR/reference/power_interaction_r2.html),
and the existing scoped grid record in conventions.md (Known difference 1).
The distinction between an individual probability and an any/all event
follows the existing Bonferroni/product/union-bound implementation; this
pass adds no new statistical rule. Full wording and usability sign-off
remain open.

The [fresh sensitivity checks](validation/2026-11-10-interaction-sensitivity.json)
used the existing InteractionPoweR backend, not a separate data generator or
software package. Simulated power at the formula's 80% threshold was
79.00%, 80.35% and 80.61% (10,000 studies each; all 99% intervals included
80%). These selected results neither establish universal agreement nor a
fixed direction or maximum discrepancy. Reproduce with
[interaction-sensitivity.R](upstream/interaction-sensitivity.R).

Compact naming uses explicit display metadata, not automatic removal of
parentheses: qualifiers that distinguish designs remain (independent versus
paired, between versus within, number of factors, categorical predictors,
corrected versus uncorrected tests). Detailed documented names and search
aliases are preserved. Explanation mode changes presentation only; it does
not select a different analysis. Desktop and narrow-screen browser checks
cover headings, repeated subtitles, persistent preference, legacy recent
entries, visible prototype status and unchanged selected test.

R34 partial verification: the public landing page and download page returned
HTTP 200 in direct HTTPS checks on 10 November; the sitemap endpoint also
returned 200. Some requests reset during TLS negotiation, so this is not
a reliability benchmark. The source sitemap includes download.html; live
body verification, search indexing and the offline/update checks remain open.

Local verification for compact labels/R22: label and copied-method checks,
screen rendering, Labs/map data, documentation alignment, generated
inventory, repository consistency, Updates and citation exports pass. Five
Chromium checks cover desktop/mobile naming, old recent entries, visible
crossover scope, Labs history and card links. These are interface/scope
checks, not new statistical validation or a complete accessibility review.

## Five priority safeguards (10 November)

- [x] Make the unresolved corrected repeated-measures discrepancy visible before
  calculation, beside the answer and in copied methods. Offer a fixed-N
  simulation handoff for exact-data power/sample-size results. This exposes
  the risk; it does **not** resolve the scientific failure or validate HF.
- [x] Start new all-tests-required plans with unknown dependence and the existing
  sufficient union-bound target. Retain explicit choices and historical
  independence calculations when reopening projects, drafts and guided plans.
- [x] Let a two-way continuous-predictor interaction sensitivity result carry its
  proposed effect, N and assumptions into the supported fixed-N simulation.
  A user must run the check; the formula result remains an approximation.
- [x] Independently check four corrected count-test recommended sample sizes,
  archive the small shortfalls as well as agreement, explain discrete-test
  curve-fit uncertainty, and offer a fixed-N check.
- [x] Show the existing selected-variant evidence record on complete input
  screens; incomplete inputs state that coverage cannot yet be determined.
  No broad card or evidence badge is promoted.

The underlying GG discrepancy, older binary-X ML/Monte-Carlo calibration failure,
broader count-test search accuracy, PROCESS reference comparison and full
selected-variant audit remain open. These five safeguards are finite completed
tasks, not completion of R14, R15, R16 or R17 as whole release requirements.
