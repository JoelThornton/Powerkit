* Small fixes on screens colleague testers meet (left for later by the
  15 November 2026 completeness and design review):
  - The progress steps show "Your numbers" on a study plan's page and on
    its whole-study simulation, and "Result" once that simulation has
    finished (`screen_step()`); both had shown "Find your analysis".
  - "Or calculate each analysis on its own" on a study plan's page is the
    size of the page's other headings rather than a large `h4`.
  - Help me choose: the example under "Two, crossed, at least one with
    three or more levels" no longer describes timepoints, which
    contradicted an earlier "measured once" answer.
  - The effect section no longer asks "Not sure what number to put
    here?" just below "Don't know what effect to expect?": where the
    smallest-detectable-effect prompt is shown, the list of sources is
    headed "Have an effect in mind? Four ways to a number you can
    defend". Each group's "What these terms mean" disclosure names its
    terms (`terms_summary()`), so two on a screen no longer read as the
    same link.
  - Field prompts (such as the significance level's) are no longer in
    italics, so the power and alpha rows look alike.
  - Searching "I know my analysis": words every analysis shares
    ("power", "G*Power", "analysis") are left out of the match, and a
    search of those alone says what to search for instead; groups whose
    analyses hold every word in their own name are listed first ("Fisher"
    now lists the Fisher exact test before the correlations); the
    moderated regression cards are found by "simple slopes".
