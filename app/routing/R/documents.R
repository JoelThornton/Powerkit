# Documents to save as PDF (6 November 2026).
#
# The pre-replication notes (Labs) and the study-planning document are
# written as Markdown. Downloading that file is kept for people who want to
# edit it, but most researchers want a finished document. Printing the app
# page gave a picture of powerkit's screens instead. So the Markdown is
# typeset here as a standalone page (its own fonts, margins and page size)
# and the browser prints that page alone, where "Save as PDF" gives a clean
# PDF. No PDF engine runs on the server: LaTeX or a headless browser would
# make every publish slower and every export cost hosting time.
#
# Every "<" in the Markdown is escaped before commonmark converts it, so
# text a user typed can't add markup or scripts to the document.

document_css <- "
  @page { size: A4; margin: 2cm 2.2cm; }
  html { color: #1b1b1b; background: #fff; }
  body { font: 11pt/1.55 Georgia, 'Times New Roman', serif; max-width: 42rem; margin: 2rem auto; padding: 0 1.25rem; }
  h1 { font: 600 1.6rem/1.25 system-ui, sans-serif; margin: 0 0 1rem; }
  h2 { font: 600 1.15rem/1.3 system-ui, sans-serif; margin: 1.6rem 0 0.5rem; break-after: avoid; }
  h3 { font: 600 1rem/1.3 system-ui, sans-serif; margin: 1.2rem 0 0.4rem; break-after: avoid; }
  p, li { orphans: 3; widows: 3; }
  table { border-collapse: collapse; margin: 0.75rem 0; font-size: 0.95em; }
  th, td { border: 1px solid #c8c8c8; padding: 0.3rem 0.5rem; text-align: left; vertical-align: top; }
  code { font-size: 0.92em; }
  .pk-doc-footer { margin-top: 2rem; padding-top: 0.5rem; border-top: 1px solid #c8c8c8; font: 0.8rem/1.4 system-ui, sans-serif; color: #555; }
"

# The page for one document. `markdown`: its lines, the first a "# " title.
printable_document <- function(markdown, version = NULL) {
  text <- paste(markdown, collapse = "\n")
  headings <- markdown[grepl("^#\\s+", markdown)]
  title <- if (length(headings)) sub("^#\\s+", "", headings[1]) else "powerkit document"
  # Every "<" is escaped first, so the page shows what was typed
  # ("p < .05", or "<b>") as text and nothing typed can become markup;
  # only Markdown's own links, <https://...>, are left to become links.
  body <- commonmark::markdown_html(gsub("<(?!https?://[^<>[:space:]]+>)", "&lt;", text, perl = TRUE),
    extensions = TRUE, smart = TRUE)
  footer <- sprintf("Made with powerkit%s.", if (is.null(version)) "" else paste0(" ", version))
  paste0(
    "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\">",
    "<title>", htmltools::htmlEscape(title), "</title>",
    "<style>", document_css, "</style></head><body>\n",
    body,
    "<p class=\"pk-doc-footer\">", htmltools::htmlEscape(footer), "</p>\n</body></html>\n"
  )
}

# The button that prints a document: the server builds it when `id` is
# clicked (observe it with send_document()).
print_document_button <- function(id, label, class = "btn btn-outline-primary") {
  tags$button(type = "button", id = paste0(id, "_button"), class = class,
    onclick = sprintf("pkPrintDocument('%s')", id), label)
}

# Sends a built document to the browser, which prints it from a hidden
# frame; or a plain-English reason if it can't be built.
send_document <- function(session, build) {
  html <- tryCatch(build(), error = function(e) NULL)
  if (is.null(html)) {
    session$sendCustomMessage("pk_document", list(error = "The document couldn't be made. Recalculate, then try again."))
  } else {
    session$sendCustomMessage("pk_document", list(html = html))
  }
}

# The document goes into a hidden frame and is printed from there, so only
# the document is printed. (The app runs inside its host's frame, where a
# new window may be blocked; printing is allowed, as the old button showed.)
documents_js <- "
(function() {
  var pending = null;
  window.pkPrintDocument = function(id) {
    pending = id;
    var b = document.getElementById(id + '_button');
    if (b) { b.disabled = true; b.dataset.label = b.textContent; b.textContent = 'Preparing…'; }
    Shiny.setInputValue(id, Date.now(), {priority: 'event'});
  };
  function reset() {
    if (!pending) return;
    var b = document.getElementById(pending + '_button');
    if (b) { b.disabled = false; if (b.dataset.label) b.textContent = b.dataset.label; }
    pending = null;
  }
  Shiny.addCustomMessageHandler('pk_document', function(m) {
    reset();
    if (m.error) { window.alert(m.error); return; }
    var old = document.getElementById('pk-print-frame'); if (old) old.remove();
    var f = document.createElement('iframe');
    f.id = 'pk-print-frame'; f.title = 'Document to print';
    f.setAttribute('aria-hidden', 'true');
    f.style.cssText = 'position:fixed;right:0;bottom:0;width:0;height:0;border:0;visibility:hidden';
    document.body.appendChild(f);
    var d = f.contentWindow.document;
    d.open(); d.write(m.html); d.close();
    setTimeout(function() { f.contentWindow.focus(); f.contentWindow.print(); }, 250);
  });
})();
"
