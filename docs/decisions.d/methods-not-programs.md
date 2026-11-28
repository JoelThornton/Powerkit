## 2026-11-28 · Name another program only to find a number or match a setting

A methods paragraph is read as a description of what was done, and an
input screen as a description of the choice in front of the researcher.
A sentence such as "as in G*Power" says which program someone else might
use rather than what the analysis does, and it ties powerkit's choices to
another tool's conventions instead of to the reasons for them.

**Rule.** Powerkit names another program in what researchers read only
where it helps them:

- find a number in their own output (for example "SPSS calls them
  Exp(B)", or "lavaan, Mplus and other SEM software report this"); or
- match a setting in the software they will analyse with (JASP's default
  priors and sampling plans, a test's continuity-correction default,
  PROCESS model numbers).

Everything else states the method by name. In particular:

- **No other power-analysis program** (G*Power, MorePower, PANGEA,
  PAMLj, BFDA and the like) is named on an input screen, the results
  screen, a write-up or the R script's lines. A departure from common
  practice is still shown and stated, as conventions.md requires, by
  comparing methods ("the usual planning formula is for the classical F
  test", "treating the covariates as fixed gives a little more power").
- **Write-ups** (the short and full methods paragraphs, the ethics
  paragraph, the planning document and the study plan report) state each
  departure in the words of `departures_methods` in forms.yaml and each
  known difference in `known_differences_methods`. The full write-up's
  headings read "Where these methods differ from common defaults" and
  "Where other methods give a different answer".
- **Kept:** the packages Powerkit runs, cited as attribution for what
  calculated the result; a published source of a formula, such as a
  manual's section, on the card and in the R script; and the cards'
  validation records, which say what each result was checked against.
- **Guard:** app/routing/tests/testthat/test-writeup-software.R checks the
  departures and known differences, the write-up's wording and a
  calculated write-up, every input screen's labels, choices, help and
  notes, the cards, and the R script's lines.

This replaces the first version of this entry (earlier on 28 November
2026), which still let input screens name another program where its
answer differs.
