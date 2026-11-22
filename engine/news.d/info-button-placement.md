* App: with explanations off, a box's info button is the box's first
  child and floats right, in place of absolute positioning, so the
  question beside it wraps rather than running under it (it overlapped
  the claim question on phones and sat close to neighbouring boxes). The
  note on the chosen test ("About this choice") is now one of the box's
  explanations, opened by its info button. The button counts only notes
  in view, so a box whose notes sit in a hidden choice or a closed fold
  shows none, and it updates as choices and folds change.
* App: the unknown-effect help above the effect size is one line, a
  question and a link ("Find the smallest effect my study could
  detect"), in place of an info button beside a separate "I don't know
  my effect size" button. Its explaining sentence follows the
  explanations switch.
* App: an effect box whose first question is "How you'll give the
  effect" no longer heads itself with the list of forms that question
  offers (`effect_box_legend()`): the heading is "The effect", or the
  part before a colon (the equivalence card's bound and difference).
