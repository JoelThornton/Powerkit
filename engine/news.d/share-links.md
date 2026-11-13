* App: "Copy a link" beside each save button (project, study plan, the
  whole-study plan and unfinished drafts) puts the same text the button
  downloads, compressed with the browser's CompressionStream
  (deflate-raw, base64url), into the link's fragment (`#shared=1.`).
  Browsers don't send the fragment to the server, so nothing about the
  study reaches the host's logs or any store. Opening the link unpacks it
  in the browser, clears it from the address bar and passes the text to
  the same reader and checks as "Open a saved or shared project"
  (`open_saved_file()` in app.R, `R/share-link.R`). Links over 60,000
  characters are refused in favour of the file; unpacking stops at 5 MB.
  No engine change.
