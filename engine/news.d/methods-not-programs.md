* Plain-language descriptions no longer name another program: the
  variance tests' function description and the MANOVA's Pillai's V
  description (which reach the write-up), and two spec-check messages
  about partial eta-squared.
* App: write-ups state each departure and known difference by its method
  (forms.yaml `departures_methods`, `departures_methods_for()`; reworded
  `known_differences_methods`), with the full write-up's headings "Where
  these methods differ from common defaults" and "Where other methods give
  a different answer". Input-screen labels, choices, help and
  starting-value notes, and the cards, drop asides naming G*Power where
  its answer is the same. test-writeup-software.R guards all of these.
