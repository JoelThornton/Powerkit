* `goal > unit` takes `"observations"` (E41, within-person moderation):
  for `mixed_model / two_level` without `groups_per_site`, `goal.n` then
  counts observations (people times occasions, a whole number of people)
  instead of participants. `sample_structure()` reports the unit and a
  note; `check_goal()` refuses `"observations"` on any other template and,
  newly, `"items"` on any template but `crossed_two_condition`. The R
  script's design description and sample-size comment describe occasions
  within people when the unit is observations.
