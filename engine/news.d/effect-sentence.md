* The spec's `effect_justification` takes `other_sources`: where the
  values other than the effect (SDs, correlations, baseline rates) come
  from, when that differs from the effect's source.
* App: the justification box reads "Where these numbers come from" and
  "Why these numbers?" on every screen, with an optional "Where the other
  numbers come from" on screens that take such values. The write-up's
  effect sentence names the effect tested and, in a sentence of its own,
  the other values assumed and their source; counts that describe the
  design (items, raters) are left out (`effect_role()` in R/forms.R,
  `writeup_effect(roles = )`). The conversion help mentions safeguard
  power only where the screen offers it. test-effect-sentence.R.
