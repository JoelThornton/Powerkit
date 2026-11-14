* Two groups in a ratio other than 1 (`options > allocation_ratio`) are
  rounded to whole people at every total, as a researcher would recruit
  them: group 1 is n / (1 + ratio) rounded to the nearest person (a half
  rounds up), group 2 the rest (`rounded_groups()`). The sample size
  search now looks at every total, and the required n is the smallest
  total whose rounded groups reach the target. `route_backend()` wraps the
  backend (`rounded_ratio_backend()`): each calculation at a total runs
  the backend for that total's exact whole-group ratio (`spec_at_total()`),
  so no backend changed its maths. This replaces the 11 November 2026
  rule (a rounded decimal planned as the simplest whole split that rounds
  to it), which still moved the total in steps and could need up to about
  four people more. Against G*Power: its variance-test example at
  N2/N1 = 2 now agrees (148 + 295 = 443, was 444); for two proportions at
  N2/N1 = 2 and 95% power powerkit gives 371 (124 + 247) where G*Power
  gives 370, whose groups fall just short of the target (was 372). The
  result's `allocation` gives the groups at the total and the ratio they
  achieve; `n_step` is 1. `minimum_n()` asks each rounded group for what
  one of two equal groups needs. Spower's two-group generators get group
  2's size from the total (nudged by a relative 1e-12 so that a truncated
  product can't drop a person), and the R scripts round the same way
  (`floor(n / (1 + ratio) + 0.5)` throughout).
