* New `implied_effect_size()`: the standardised effect that an input
  screen's means and SD give, without running power. Cohen's d or d_z for
  the t-tests in the measure's own units (the engine's own conversion);
  Cohen's f and partial eta-squared of the tested effect for the ANOVAs
  (Superpower's `ANOVA_exact()` on its exact data set at 1,000 per group,
  within 0.1% of the population values; checked against pwrss's
  `means.to.etasq()` and the definition of f) and the ANCOVAs (Shieh's
  adjusted effect, as for fixed covariates); and Cohen's f for an ANOVA
  given by partial eta-squared (effectsize's `eta2_to_f()`). It returns
  `NULL` for incomplete inputs rather than an error.
* App: on the ANOVA and ANCOVA screens, "How you'll give the effect"
  (the `metric` field, once "Units of the means") opens the effect section
  in a box of its own, offering expected means with an SD or an effect
  size from earlier work, with nothing preselected (`split_route_question()`
  in R/forms.R). The screens that take means and an SD, the t-tests'
  own-units route included, show the effect size those numbers give as
  they are typed (`output$implied_effect`, `implied_effect_text()`), and
  the source question reads "Source of the numbers above". The choices and
  help on this route no longer name another program.
