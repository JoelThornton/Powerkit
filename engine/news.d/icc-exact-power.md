* The ICC on the reliability card (E69) is planned by the F test's exact
  power by default (Donner & Eliasziw, 1987): under the one-way
  random-effects model MSB/MSW is F(n - 1, n(k - 1)) scaled by
  (1 + (k - 1) rho) / (1 - rho), so power is a `stats::pf()` tail at the
  critical value scaled by the ratio of that factor under the null and the
  alternative (both tails when two-sided). New method `icc_test` (default,
  backend `stats`, function `icc_exact_power()`); `icc_walter` keeps
  ICC.Sample.Size's `calculateIccPower()` (Walter, Eliasziw and Donner's
  normal approximation). For an ICC of 0.8 against 0.6 with 3 raters,
  one-sided, the exact power needs 26 subjects where the approximation
  asks for 27. Departure 29; the schema's ICC method is now an enum. The
  exported R script for the exact route uses base R only. Tests in
  `test-backend-reliability.R` check the formula, the two-sided tails,
  agreement with 4,000 simulated studies and the script; reference
  `Donner1987_icc` added to `refs.bib` (specialist maths review, M-16).
