* `scripts/close-batch.R` keeps `whats-new.yaml` newest first when it
  files the waiting Updates entries: a note dated earlier than one already
  on the list (its pull request merged later) now goes below it rather
  than on top, which had put the list out of date order and failed
  `test-whats-new.R` on main. The list was re-sorted once with the same
  function.
