# Links that carry a saved analysis, plan or draft (13 November 2026).
#
# One Share button in the top bar (share_page_ui(), 16 November 2026)
# shares whatever is open: on a result, the analysis with its result; on
# an input screen, the answers so far; on a study plan, the plan; anywhere
# else, the page's address. Each screen that can be shared marks it with
# share_link_ui(kind), a hidden marker the button looks for; there are no
# separate "Copy a link" buttons, so there is one way to share.
#
# The link puts the same text the save button downloads into the link's
# fragment (the part after "#"), compressed:
#
#   <address>#shared=1.<deflate-raw, base64url>
#
# Browsers never send the fragment to the server, so the host's logs don't
# hold the study, and nothing is stored anywhere: the link is the saved
# file. Opening the link reads the fragment in the browser, unpacks it and
# hands the text to the same reader as "Open a saved file"
# (open_saved_file() in app.R), with the same checks for a file from an
# unknown source. The address bar loses the fragment as soon as it has been
# read, so the study doesn't stay in the tab's history or get carried into
# a page link copied later.
#
# Compression and decompression use the browser's CompressionStream
# ("deflate-raw"), in every current browser; the server never compresses
# or unpacks anything, so R needs no new package.

# What a link can carry: the Share button's tooltip, and what its panel
# says the link opens.
share_link_kinds <- c(project = "this analysis", study_plan = "this study plan",
  guided_plan = "this study plan", draft = "your answers so far")
share_link_titles <- c(project = "Share this analysis", study_plan = "Share this study plan",
  guided_plan = "Share this study plan", draft = "Share your answers so far", page = "Share this page")
share_link_what <- c(
  project = "A link that opens this analysis, with its answers and result, on any computer.",
  study_plan = "A link that opens this study plan, with every analysis in it, on any computer.",
  guided_plan = "A link that opens this study plan, with the study's variables and analyses, on any computer.",
  draft = "A link that opens your answers so far on any computer, to carry on from there.",
  page = "A link to this page. There is nothing of yours on it to share.")

# The longest link offered. Current browsers open far longer addresses, but
# some email programs and chat apps break or cut very long links; past this
# the file is the reliable way to share.
share_link_max_chars <- 60000L

# The largest text a link may unpack to (as for a saved file, 5 MB), so a
# crafted link can't make the browser unpack something enormous.
share_link_max_text <- 5e6

# The marker that says this screen can be shared as `kind`. The Share
# button picks the first visible, enabled marker, in the order of
# share_link_kinds. A marker the page disables (class "disabled", as the
# result's is while the answers differ from the result) is passed over.
share_link_ui <- function(kind, id = paste0("share_", kind)) {
  stopifnot(kind %in% names(share_link_kinds))
  tags$span(id = id, class = "share-target", `data-kind` = kind, hidden = NA)
}

# The top bar's Share button and its panel: what the link opens, a status
# line, and the box the link is shown in (so it can be copied by hand
# where the clipboard is blocked).
share_page_ui <- function() {
  div(class = "share-page",
    tags$button(type = "button", id = "share_button", class = "btn btn-sm share-page-btn",
      onclick = "pkShare(this)", `data-public` = public_address,
      title = share_link_titles[["page"]], `aria-controls` = "share_panel", `aria-expanded` = "false",
      tags$svg(class = "share-icon", `aria-hidden` = "true", viewBox = "0 0 20 20", width = "16", height = "16",
        tags$path(d = "M10 2.5v10M6 6.2l4-3.7 4 3.7M4 10.5v6h12v-6", fill = "none", stroke = "currentColor",
          `stroke-width` = "1.8", `stroke-linecap` = "round", `stroke-linejoin` = "round")),
      "Share"),
    div(id = "share_panel", class = "share-panel", hidden = NA, role = "dialog", `aria-label` = "Share",
      p(class = "share-panel-what"),
      p(class = "share-panel-note small", "The link holds your answers itself: Powerkit stores nothing. Anyone with the link can open it."),
      tags$span(class = "share-link-status small", role = "status", `aria-live` = "polite"),
      tags$span(class = "share-link-box", hidden = NA,
        tags$label(class = "visually-hidden", `for` = "share_box", "The link"),
        tags$input(type = "text", id = "share_box", class = "form-control form-control-sm", readonly = NA,
          onfocus = "this.select()")),
      tags$button(type = "button", class = "btn btn-link btn-sm share-panel-close", onclick = "pkShareClose()", "Close")))
}

share_link_css <- "
  .share-page { position: relative; }
  .share-page-btn .share-icon { margin-right: 0.3rem; vertical-align: -0.15em; }
  .share-panel { position: absolute; right: 0; top: calc(100% + 0.4rem); z-index: 1060; width: min(24rem, calc(100vw - 2rem));
    background: #fff; color: #1d2733; border: 1px solid var(--pk-line, #d8dee6); border-radius: 10px;
    box-shadow: 0 8px 24px rgba(0,0,0,.18); padding: 0.8rem 0.9rem; display: flex; flex-direction: column; gap: 0.45rem; }
  .share-panel[hidden] { display: none; }
  .share-panel p { margin: 0; }
  .share-panel-what { font-weight: 600; }
  .share-panel-note { color: #44505e; }
  .share-panel .share-link-status { color: #1d2733; }
  .share-link-box input { font-family: monospace; font-size: 0.75rem; }
  .share-link-status:empty { display: none; }
  .share-panel-close { align-self: flex-end; padding: 0; }
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
  // frame, else this page's address.
  function base() {
    var framed = false; try { framed = window.self !== window.top; } catch (e) { framed = true; }
    var btn = document.getElementById('share_button');
    if (framed && btn && btn.getAttribute('data-public')) return btn.getAttribute('data-public') + '/';
    return window.location.origin + window.location.pathname;
  }
  // A link to the page itself: its ?page=, Tools tool or card.
  function pageLink() {
    var page = window.pkPage || 'plan';
    var params = new URLSearchParams();
    if (page !== 'plan') params.set('page', page);
    if (page === 'labs' && window.pkLabsTool) params.set('tool', window.pkLabsTool);
    if (page === 'plan' && window.pkCard) params.set('card', window.pkCard);
    return base() + (params.toString() ? '?' + params.toString() : '');
  }
  window.pkPageLink = pageLink;
  var TITLES = %s, WHAT = %s, ORDER = %s;
  function shown(el) {
    var pane = el.closest('.tab-pane');
    if (pane && !pane.classList.contains('active')) return false;
    for (var p = el.parentElement; p && p !== document.body; p = p.parentElement) {
      if (p.hidden || window.getComputedStyle(p).display === 'none') return false;
    }
    return true;
  }
  // What the Share button shares now: the first visible, enabled marker.
  function target() {
    for (var i = 0; i < ORDER.length; i++) {
      var els = document.querySelectorAll('.share-target[data-kind=\"' + ORDER[i] + '\"]');
      for (var j = 0; j < els.length; j++) {
        if (!els[j].classList.contains('disabled') && shown(els[j])) return els[j];
      }
    }
    return null;
  }
  window.pkShareTarget = target;
  function panelParts() {
    var panel = document.getElementById('share_panel');
    if (!panel) return {};
    var holder = panel.querySelector('.share-link-box');
    return { panel: panel, what: panel.querySelector('.share-panel-what'), note: panel.querySelector('.share-panel-note'),
      status: panel.querySelector('.share-link-status'), holder: holder, input: holder && holder.querySelector('input') };
  }
  function label() {
    var btn = document.getElementById('share_button'); if (!btn) return;
    var t = target(), kind = t ? t.getAttribute('data-kind') : 'page';
    btn.title = TITLES[kind];
    btn.setAttribute('aria-label', TITLES[kind]);
  }
  document.addEventListener('mouseover', function(e) { if (e.target.closest && e.target.closest('#share_button')) label(); });
  document.addEventListener('focusin', function(e) { if (e.target && e.target.id === 'share_button') label(); });
  window.pkShareClose = function() {
    var q = panelParts(); if (!q.panel) return;
    q.panel.hidden = true;
    var btn = document.getElementById('share_button'); if (btn) btn.setAttribute('aria-expanded', 'false');
  };
  document.addEventListener('keydown', function(e) { if (e.key === 'Escape') window.pkShareClose(); });
  document.addEventListener('click', function(e) {
    var q = panelParts();
    if (!q.panel || q.panel.hidden || !e.target.closest) return;
    if (!e.target.closest('#share_panel') && !e.target.closest('#share_button')) window.pkShareClose();
  });
  var pending = null;
  window.pkShare = function(btn) {
    var q = panelParts(); if (!q.panel) return;
    var t = target(), kind = t ? t.getAttribute('data-kind') : 'page';
    label();
    q.panel.hidden = false; btn.setAttribute('aria-expanded', 'true');
    q.what.textContent = WHAT[kind];
    q.note.hidden = kind === 'page';
    q.status.textContent = ''; q.holder.hidden = true; q.input.value = '';
    if (!t) {
      var link = pageLink();
      q.input.value = link; q.holder.hidden = false;
      pkCopyText(link, q.status, 'Couldn\\'t copy automatically. Select the link in the box and copy it.');
      return;
    }
    if (!window.CompressionStream) {
      q.status.textContent = 'This browser can\\'t make links. Save the file instead, or use a current version of Chrome, Edge, Firefox or Safari.';
      return;
    }
    pending = kind;
    q.status.textContent = 'Making the link\\u2026';
    Shiny.setInputValue('share_link_request', {kind: kind, at: Date.now()}, {priority: 'event'});
  };
  Shiny.addCustomMessageHandler('pk_share_link', async function(m) {
    var kind = pending; pending = null;
    if (!kind) return;
    var q = panelParts(); if (!q.panel) return;
    var say = function(t) { q.status.textContent = t; };
    if (m.problem) { say(m.problem); q.holder.hidden = true; return; }
    var link;
    try { link = base() + '#' + PREFIX + await pack(m.text); } catch (e) { say('The link couldn\\'t be made. Save the file instead.'); return; }
    if (link.length > MAX_CHARS) {
      say('This is too large for a link that email and chat apps keep intact. Save the file and send that instead.');
      q.holder.hidden = true;
      return;
    }
    q.input.value = link; q.holder.hidden = false;
    pkCopyText(link, q.status, 'Couldn\\'t copy automatically. Select the link in the box and copy it.');
    $(document).trigger('pk:share-link', [kind]);
    // Only now is the link made: a study plan counts as kept from here.
    Shiny.setInputValue('share_link_made', {kind: kind, at: Date.now()}, {priority: 'event'});
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
", share_link_max_chars, as.integer(share_link_max_text),
  jsonlite::toJSON(as.list(share_link_titles), auto_unbox = TRUE),
  jsonlite::toJSON(as.list(share_link_what), auto_unbox = TRUE),
  jsonlite::toJSON(names(share_link_kinds)))

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
