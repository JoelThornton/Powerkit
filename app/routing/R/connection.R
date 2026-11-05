# Keeping the visitor's place and showing that the app is working
# (5 November 2026).
#
# * A visit after a quiet spell waits while the server starts a new R
#   process; the page shows "Starting powerkit" until the app answers,
#   instead of a blank page.
# * While the app is busy (a calculation, a new screen, the About tab being
#   built) a bar at the top of the page says so.
# * The connection drops after a while away from the page (the server ends
#   idle sessions), and the app's state goes with it. Shiny tries to
#   reconnect to the same session while its process is still running
#   (session$allowReconnect()); and on an input screen the answers are
#   saved in this browser (localStorage, never sent anywhere else), in the
#   same draft format as "Save a draft" (R/drafts.R), so a new session
#   offers to continue where the visitor left off.

autosave_key <- "powerkit-autosave"

# The draft record for the browser: the same as write_draft() writes.
autosave_record <- function(route) {
  route$form_values <- lapply(route$form_values, function(x) {
    if (is.null(x) || !length(x) || anyNA(x)) "" else as.character(x)
  })
  list(format = "powerkit-draft", version = 1L,
    saved_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC"), route = route)
}

# A record the browser sent back, read as a draft (NULL if it isn't one).
autosave_from_browser <- function(text) {
  if (!is.character(text) || length(text) != 1 || nchar(text) > 5e6) return(NULL)
  record <- tryCatch(jsonlite::fromJSON(text, simplifyVector = FALSE), error = function(e) NULL)
  if (!is.list(record) || !identical(record$format, "powerkit-draft")) NULL else record
}

connection_css <- "
  #pk-starting { position: fixed; inset: 0; z-index: 2000; background: #f7f8fa; display: flex; align-items: center; justify-content: center; }
  #pk-starting .pk-starting-box { max-width: 28rem; padding: 1.5rem; text-align: center; color: #17283d; }
  .pk-spinner { width: 2.25rem; height: 2.25rem; border: 4px solid #cfd8e3; border-top-color: #0a5a8c; border-radius: 50%;
    animation: pk-spin 0.9s linear infinite; margin: 0 auto 1rem; }
  .pk-spinner-small { display: inline-block; width: 1rem; height: 1rem; border-width: 3px; margin: 0 0.5rem 0 0; vertical-align: -0.15rem; }
  @keyframes pk-spin { to { transform: rotate(360deg); } }
  @media (prefers-reduced-motion: reduce) { .pk-spinner { animation-duration: 3s; } }
  #pk-busy { position: fixed; top: 0; left: 0; right: 0; z-index: 1500; display: none; }
  #pk-busy .pk-busy-bar { height: 4px; background: linear-gradient(90deg, #0a5a8c 0%, #5cc8ff 50%, #0a5a8c 100%); background-size: 200% 100%;
    animation: pk-busy-move 1.2s linear infinite; }
  #pk-busy .pk-busy-label { position: absolute; top: 6px; right: 12px; background: #0a5a8c; color: #fff; font-size: 0.8rem; padding: 0.15rem 0.6rem; border-radius: 6px; }
  @keyframes pk-busy-move { to { background-position: -200% 0; } }
  html.pk-busy-shown #pk-busy { display: block; }
  #pk-lost { position: fixed; left: 50%; bottom: 1.5rem; transform: translateX(-50%); z-index: 2100; display: none; max-width: 34rem; width: calc(100% - 2rem);
    background: #fff5df; border: 1px solid #a15b00; border-radius: 10px; padding: 0.9rem 1.1rem; color: #17283d; box-shadow: 0 4px 18px rgba(0,0,0,0.15); }
  html.pk-lost-shown #pk-lost { display: block; }
  #shiny-disconnected-overlay { display: none !important; }
  .about-loading { color: #3d4852; }
"

connection_js <- "
(function() {
  var KEY = 'powerkit-autosave';
  var busyTimer = null;
  // The busy bar: shown when Shiny has been busy for a moment, so quick
  // clicks don't flash it.
  $(document).on('shiny:busy', function() {
    clearTimeout(busyTimer);
    busyTimer = setTimeout(function() { document.documentElement.classList.add('pk-busy-shown'); }, 250);
  });
  $(document).on('shiny:idle', function() {
    clearTimeout(busyTimer);
    document.documentElement.classList.remove('pk-busy-shown');
  });
  // The starting screen goes once the first screen has arrived.
  $(document).on('shiny:value', function(e) {
    if (e.name === 'screen') { var s = document.getElementById('pk-starting'); if (s) s.remove(); }
    if (e.name === 'about_page') { $('.about-loading').remove(); }
  });
  $(document).on('shiny:connected', function() {
    document.documentElement.classList.remove('pk-lost-shown');
    var saved = null;
    try { saved = window.localStorage.getItem(KEY); } catch (e) {}
    if (saved) Shiny.setInputValue('pk_saved_draft', saved, {priority: 'event'});
  });
  $(document).on('shiny:disconnected', function() {
    document.documentElement.classList.add('pk-lost-shown');
    var s = document.getElementById('pk-starting'); if (s) s.remove();
  });
  Shiny.addCustomMessageHandler('pk_autosave', function(text) {
    try { if (text) window.localStorage.setItem(KEY, text); else window.localStorage.removeItem(KEY); } catch (e) {}
  });
})();
"

# The starting screen, the busy bar and the connection-lost message, in the
# page as it arrives (before the app has answered).
connection_ui <- function() {
  tagList(
    div(id = "pk-starting", role = "status", `aria-live` = "polite",
      div(class = "pk-starting-box",
        div(class = "pk-spinner", `aria-hidden` = "true"),
        tags$p(tags$strong("Starting powerkit…")),
        tags$p(class = "small text-muted", "After a quiet spell the server needs a little while to wake up, up to a minute. The page will appear by itself."))),
    div(id = "pk-busy", role = "status", `aria-live` = "polite",
      div(class = "pk-busy-bar"), tags$span(class = "pk-busy-label", "Working…")),
    div(id = "pk-lost", role = "alert",
      tags$p(tags$strong("The connection to powerkit was lost."),
        " This happens after a while away from the page. Reload to carry on: answers you had typed on an input screen are kept in this browser, and powerkit will offer to bring them back."),
      tags$button(type = "button", class = "btn btn-primary btn-sm", onclick = "window.location.reload()", "Reload"))
  )
}
