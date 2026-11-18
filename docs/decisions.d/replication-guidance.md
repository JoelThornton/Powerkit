## 2026-11-18 · Replication plans: the publication filter, and the other routes beside BUCSS

BUCSS's sample sizes can grow far past the original's: for d = 0.6 with
40 per group, a significant replication with 80% power needs 162
participants at 50% assurance and 6,336 at 80%. That is BUCSS working as
designed (an original near its threshold is, once the significance
filter is undone, consistent with a very small effect), but shown alone
it reads as a sample size researchers must reach, and it would rule out
most conceptual replications and extensions.

- **The publication filter is the researcher's to set.** The plan asks
  whether the original was published because it was significant. The
  default is BUCSS's own assumption (yes, or unknown). "No: it would
  have been published whatever it found", for a Registered Report or a
  journal that publishes null results, passes `alpha_prior = 1`, which
  corrects for uncertainty only (Anderson, Kelley & Maxwell, 2017,
  p. 1552); the example above then needs 90 and 194. The engine's
  `replication_bucss()` and `replication_planning()` take
  `publication_filter`.
- **Large numbers are explained, not just shown.** When the higher
  assurance needs over three times the 50% figure, over ten times the
  original's sample size, or can't be planned at all, the result says
  why, and that the number is a finding about the original (how little
  it pins down the effect), not a sample size to reach.
- **Other routes are offered as equals**, each with where to do it: the
  smallest effect that would matter (suited to conceptual replications
  and extensions); what the researcher's resources allow, reporting what
  that sample can show (Lakens, 2022); a sequential design (the Bayesian
  planning tool); several originals or a meta-analysis; and the
  publication filter itself. No route is recommended over the others:
  which fits depends on the study.
- **50% beside 80% for ANOVA originals.** 80% stays the default, as
  BUCSS's own; the 50% figure (planning for the corrected estimate
  itself) is now stated under the headline, not only in the table.
