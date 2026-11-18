* New `replication_bucss()`: the replication's sample size for a
  significant result, with the original's effect corrected for
  publication bias and uncertainty by BUCSS (Anderson, Kelley & Maxwell,
  2017), at each level of assurance. It covers t-test and correlation
  originals and ANOVA originals from between-subjects, within-subjects
  and mixed designs, reported as an F or as a partial eta-squared with
  its error degrees of freedom (moved to F by Lakens, 2013). An original
  that BUCSS can't plan from is reported (`reason`), not an error. BUCSS
  joins Suggests and `renv.lock`; its two method papers join `refs.bib`
  from its own `citation()`.
* `replication_planning()` gains `bias_corrected` for t-test and
  correlation originals analysed with a test (BUCSS at 50% and 80%
  assurance), and its full script repeats it.
* App: the replication plan's design "An ANOVA effect" (`rep_anova_*`,
  `rep_f_from`, `rep_eta`, `rep_df_error`, `rep_epsilon`,
  `rep_assurance`) plans with `replication_bucss()`. Its Goals show only
  the settings BUCSS uses, and its write-up, references and script come
  from it. Forms.yaml's `replication_effects` mark the ANOVA cards (E7,
  E8, E18, E20, E21, E22, E54, E55), so a plan opened from one starts on
  the new design. Queue item 28.
