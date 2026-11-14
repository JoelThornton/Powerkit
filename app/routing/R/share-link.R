# Links that carry a saved project, plan or draft (13 November 2026).
#
# "Copy a link" beside each save button puts the same text the save button
# downloads into the link's fragment (the part after "#"), compressed:
#
#   <address>#shared=1.<deflate-raw, base64url>
#
# Browsers never send the fragment to the server, so the host's logs don't
# hold the study, and nothing is stored anywhere: the link is the saved
# file. Opening the link reads the fragment in the browser, unpacks it and
# hands the text to the same reader as "Open a saved or shared project"
# (open_saved_file() in app.R), with the same checks for a file from an
# unknown source. The address bar loses the fragment as soon as it has been
# read, so the study doesn't stay in the tab's history or get carried into
# a page link copied later.
#
# Compression and decompression use the browser's CompressionStream
# ("deflate-raw"), in every current browser; the server never compresses
# or unpacks anything, so R needs no new package.

# What a link can carry, and the save button it stands beside.
share_link_kinds <- c(project = "this project", study_plan = "this study plan",
  guided_plan = "this plan", draft = "these unfinished answers")

# The longest link offered. Current browsers open far longer addresses, but
# some email programs and chat apps break or cut very long links; past this
# the file is the reliable way to share.
share_link_max_chars <- 60000L

# The largest text a link may unpack to (as for a saved file, 5 MB), so a
# crafted link can't make the browser unpack something enormous.
share_link_max_text <- 5e6

# The button, its status line and the box the link is shown in (so it can
# be copied by hand where the clipboard is blocked).
share_link_ui <- function(kind, id = paste0("share_", kind), class = "btn btn-outline-primary") {
  stopifnot(kind %in% names(share_link_kinds))
  span(class = "share-link",
    tags$button(type = "button", id = id, class = paste(class, "share-link-btn"),
      `data-kind` = kind, onclick = "pkShareLink(this)",
      title = sprintf("Copies a link that opens %s on any computer. The link holds your answers itself: nothing is stored by powerkit.", share_link_kinds[[kind]]),
      "Copy a link"),
    tags$span(class = "share-link-status small", role = "status", `aria-live` = "polite"),
    tags$span(class = "share-link-box", hidden = NA,
      tags$label(class = "visually-hidden", `for` = paste0(id, "_box"), "The link"),
      tags$input(type = "text", id = paste0(id, "_box"), class = "form-control form-control-sm", readonly = NA,
        onfocus = "this.select()")))
}

share_link_css <- "
  .share-link { display: inline-flex; flex-wrap: wrap; align-items: center; gap: 0.5rem; }
  .share-link-box { flex-basis: 100%; }
  .share-link-box input { font-family: monospace; font-size: 0.75rem; min-width: 16rem; }
  .share-link-status:empty { display: none; }
"

share_link_js <- sprintf("
(function() {
  var PREFIX = 'shared=1.', MAX_CHARS = %d, MAX_TEXT = %d;
  function toBase64Url(bytes) {
    var s = '', chunk = 0x8000;
    for (var i = 0; i < bytes.length; i += chunk) s += String.fromCharCode.apply(null, bytes.subarray(i, i + chunk));
    return btoa(s).replace(/\\+/g, '-').replace(/\\//g, '_').replace(/=+$/, '');
  }
  function fromBase64Url(text) {
    var s = text.replace(/-/g, '+').replace(/_/g, '/');
    while (s.length %% 4) s += '=';
    var bin = atob(s), bytes = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return bytes;
  }
  async function readAll(stream, limit) {
    var reader = stream.getReader(), parts = [], size = 0;
    for (;;) {
      var r = await reader.read();
      if (r.done) break;
      size += r.value.length;
      if (size > limit) { try { reader.cancel(); } catch (e) {} throw new Error('too large'); }
      parts.push(r.value);
    }
    var out = new Uint8Array(size), at = 0;
    parts.forEach(function(p) { out.set(p, at); at += p.length; });
    return out;
  }
  async function pack(text) {
    var stream = new Blob([new TextEncoder().encode(text)]).stream().pipeThrough(new CompressionStream('deflate-raw'));
    return toBase64Url(await readAll(stream, Infinity));
  }
  async function unpack(data) {
    var stream = new Blob([fromBase64Url(data)]).stream().pipeThrough(new DecompressionStream('deflate-raw'));
    return new TextDecoder().decode(await readAll(stream, MAX_TEXT));
  }
  window.pkSharePack = pack;
  window.pkShareUnpack = unpack;
  // The address a link opens: the public address inside Connect Cloud's
  // frame (as Copy page link does), else this page's address.
  function base() {
    var framed = false; try { framed = window.self !== window.top; } catch (e) { framed = true; }
    var btn = document.querySelector('.share-page-btn[data-public]');
    if (framed && btn) return btn.getAttribute('data-public') + '/';
    return window.location.origin + window.location.pathname;
  }
  var pending = null;
  window.pkShareLink = function(btn) {
    if (btn.disabled || btn.classList.contains('disabled')) return;
    var box = btn.parentNode.querySelector('.share-link-status');
    if (!window.CompressionStream) {
      if (box) box.textContent = 'This browser can\\'t make links. Save the file instead, or use a current version of Chrome, Edge, Firefox or Safari.';
      return;
    }
    pending = btn;
    if (box) box.textContent = 'Making the link\\u2026';
    Shiny.setInputValue('share_link_request', {kind: btn.getAttribute('data-kind'), at: Date.now()}, {priority: 'event'});
  };
  Shiny.addCustomMessageHandler('pk_share_link', async function(m) {
    var btn = pending; pending = null;
    if (!btn) return;
    var wrap = btn.parentNode, status = wrap.querySelector('.share-link-status'),
      holder = wrap.querySelector('.share-link-box'), input = holder && holder.querySelector('input');
    var say = function(t) { if (status) status.textContent = t; };
    if (m.problem) { say(m.problem); if (holder) holder.hidden = true; return; }
    var link;
    try { link = base() + '#' + PREFIX + await pack(m.text); } catch (e) { say('The link couldn\\'t be made. Save the file instead.'); return; }
    if (link.length > MAX_CHARS) {
      say('This is too large for a link that email and chat apps keep intact. Save the file and send that instead.');
      if (holder) holder.hidden = true;
      return;
    }
    if (input) { input.value = link; holder.hidden = false; }
    pkCopyText(link, status, 'Couldn\\'t copy automatically. Select the link in the box and copy it.');
    $(document).trigger('pk:share-link', [btn.getAttribute('data-kind')]);
    // Only now is the link made: a study plan counts as kept from here.
    Shiny.setInputValue('share_link_made', {kind: btn.getAttribute('data-kind'), at: Date.now()}, {priority: 'event'});
  });
  // Opening a link: read the fragment once the app is connected, take it
  // out of the address bar, and hand the text to the server.
  var opened = false;
  $(document).on('shiny:connected', async function() {
    if (opened) return;
    var hash = window.location.hash.replace(/^#/, '');
    if (hash.indexOf(PREFIX) !== 0) return;
    opened = true;
    try { history.replaceState(history.state, '', window.location.pathname + window.location.search); } catch (e) {}
    var text = null;
    try { text = await unpack(hash.slice(PREFIX.length)); } catch (e) { text = null; }
    Shiny.setInputValue('pk_shared_link', {text: text || '', at: Date.now()}, {priority: 'event'});
  });
})();
", share_link_max_chars, as.integer(share_link_max_text))

# The text a link carries, from a writer that saves to a file (the draft
# and guided-plan writers), or a plain-English problem.
share_text_from_file <- function(write) {
  path <- tempfile(fileext = ".powerkit.json")
  on.exit(unlink(path))
  ok <- tryCatch({ write(path); TRUE }, error = function(e) FALSE)
  if (!ok || !file.exists(path)) return(list(problem = "The link couldn't be made. Save the file instead."))
  list(text = paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
}

# A link the browser unpacked, as a file the "Open" reader takes, or NULL
# when it couldn't be unpacked or is too large.
shared_link_file <- function(text) {
  if (!is.character(text) || length(text) != 1 || !nzchar(text) || nchar(text, type = "bytes") > share_link_max_text) return(NULL)
  path <- tempfile(fileext = ".powerkit.json")
  writeLines(enc2utf8(text), path, useBytes = TRUE)
  path
}

shared_link_problem <- "This link couldn't be opened. It may have been cut short when it was copied: ask for the link again, or for the saved file."
