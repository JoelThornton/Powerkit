* App: with an SD per condition or a correlation per pair, the one-way
  repeated-measures, mixed and two-factor within forms default to the
  Greenhouse-Geisser correction (Departure 26 in `docs/conventions.md`);
  choosing no correction shows a warning above the answer. The engine's
  handling of a spec without `target_test > correction` is unchanged.
