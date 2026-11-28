* Plain-language descriptions and the exported R script no longer name
  another power-analysis program: the variance tests' and the MANOVA's
  descriptions, two spec-check messages about partial eta-squared, and
  the script's argument comments ("as in G*Power" and the like). A
  formula's published source (a manual's section) is still cited.
* App: another program is named only where it helps a researcher find a
  number in their own output or match a setting in their analysis
  software (docs/decisions.md, 28 November 2026). Write-ups state each
  departure and known difference by its method (forms.yaml
  `departures_methods`, `departures_methods_for()`; reworded
  `known_differences_methods`); the results screen's departures and known
  differences, the input screens and the cards no longer name another
  power-analysis program. test-writeup-software.R guards all of these.
