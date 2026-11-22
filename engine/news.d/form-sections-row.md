* App: the input screen has a pinned row of its sections
  (`form_jump_ui()`): "Analysis chosen", then Goal, Study, Effect size
  and Settings, each a link to its section and ticked once none of its
  needed answers is empty (kept by `pkUpdateNeeded()`), then Result,
  ticked and linked once a result is on the page. It replaces the app's
  four-step bar on that screen (`progress-steps at-numbers`/`at-result`).
