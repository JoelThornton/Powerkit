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
  pre { white-space: pre-wrap; overflow-wrap: anywhere; font-size: 0.8em; line-height: 1.4; background: #f6f6f6; padding: 0.5rem 0.75rem; }
  .pk-doc-footer { margin-top: 2rem; padding-top: 0.5rem; border-top: 1px solid #c8c8c8; font: 0.8rem/1.4 system-ui, sans-serif; color: #555; }
"

# Inside <code> elements only, "&amp;lt;" back to "&lt;".
code_unescape <- function(html) {
  parts <- regmatches(html, gregexpr("(?s)<code[^>]*>.*?</code>", html, perl = TRUE))[[1]]
  if (!length(parts)) return(html)
  fixed <- gsub("&amp;lt;", "&lt;", parts, fixed = TRUE)
  regmatches(html, gregexpr("(?s)<code[^>]*>.*?</code>", html, perl = TRUE)) <- list(fixed)
  html
}

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
  # In code, commonmark escapes the "&" of that "&lt;" again; undo that
  # there, so an R script's "<-" reads as written. It stays escaped.
  body <- code_unescape(body)
  footer <- sprintf("Made with powerkit%s.", if (is.null(version)) "" else paste0(" ", version))
  paste0(
    "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\">",
    "<title>", htmltools::htmlEscape(title), "</title>",
    "<style>", document_css, "</style></head><body>\n",
    body,
    "<p class=\"pk-doc-footer\">", htmltools::htmlEscape(footer), "</p>\n</body></html>\n"
  )
}

# --- Word (.docx) --------------------------------------------------------------
#
# The same Markdown as an editable Word document. A .docx is a zip of a few
# XML files (Office Open XML, ECMA-376); it is written here from
# commonmark's syntax tree with xml2 and zip, two small packages with no
# system libraries, rather than officer, which brings ragg and its graphics
# libraries to every publish. Covers what the documents use: headings,
# paragraphs, lists, bold, italic, code, links and rules. Text is written
# as text (XML-escaped), so nothing typed becomes markup.

docx_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

# The document.xml body and its hyperlink targets, from the Markdown.
docx_body <- function(markdown) {
  tree <- xml2::read_xml(commonmark::markdown_xml(paste(markdown, collapse = "\n"), extensions = TRUE, smart = TRUE))
  xml2::xml_ns_strip(tree)
  links <- character()
  run <- function(text, f) {
    props <- paste(c(if (isTRUE(f$link)) '<w:rStyle w:val="Hyperlink"/>', if (isTRUE(f$bold)) "<w:b/>",
      if (isTRUE(f$italic)) "<w:i/>", if (isTRUE(f$code)) '<w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/>'), collapse = "")
    sprintf('<w:r>%s<w:t xml:space="preserve">%s</w:t></w:r>', if (nzchar(props)) paste0("<w:rPr>", props, "</w:rPr>") else "", docx_escape(text))
  }
  inlines <- function(node, f = list()) {
    parts <- vapply(xml2::xml_children(node), function(k) {
      switch(xml2::xml_name(k),
        text = , html_inline = run(xml2::xml_text(k), f),
        code = run(xml2::xml_text(k), utils::modifyList(f, list(code = TRUE))),
        emph = inlines(k, utils::modifyList(f, list(italic = TRUE))),
        strong = inlines(k, utils::modifyList(f, list(bold = TRUE))),
        softbreak = run(" ", f),
        linebreak = "<w:r><w:br/></w:r>",
        link = {
          links <<- c(links, xml2::xml_attr(k, "destination"))
          sprintf('<w:hyperlink r:id="rIdLink%d">%s</w:hyperlink>', length(links), inlines(k, utils::modifyList(f, list(link = TRUE))))
        },
        inlines(k, f))
    }, "")
    paste(parts, collapse = "")
  }
  para <- function(content, style = NULL) {
    sprintf("<w:p>%s%s</w:p>", if (is.null(style)) "" else sprintf('<w:pPr><w:pStyle w:val="%s"/></w:pPr>', style), content)
  }
  blocks <- function(node, style = NULL) {
    parts <- lapply(xml2::xml_children(node), function(k) {
      switch(xml2::xml_name(k),
        heading = para(inlines(k), paste0("Heading", min(3L, as.integer(xml2::xml_attr(k, "level"))))),
        paragraph = para(inlines(k), style),
        list = {
          ordered <- identical(xml2::xml_attr(k, "type"), "ordered")
          items <- xml2::xml_children(k)
          unlist(lapply(seq_along(items), function(i) {
            marker <- if (ordered) sprintf("%d.\t", i) else "•\t"
            inner <- blocks(items[[i]], "ListParagraph")
            # The marker opens the item's first paragraph.
            inner[1] <- sub('</w:pPr>', paste0('</w:pPr>', run(marker, list())), inner[1], fixed = TRUE)
            inner
          }))
        },
        block_quote = blocks(k, "Quote"),
        # One paragraph, its lines kept apart by line breaks.
        code_block = , html_block = para(paste(vapply(strsplit(sub("\n$", "", xml2::xml_text(k)), "\n", fixed = TRUE)[[1]],
          run, "", list(code = TRUE)), collapse = "<w:r><w:br/></w:r>"), style),
        thematic_break = '<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="A0A0A0"/></w:pBdr></w:pPr></w:p>',
        blocks(k, style))
    })
    unlist(parts)
  }
  list(body = paste(blocks(tree), collapse = ""), links = links)
}

docx_styles <- paste0(
  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
  '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">',
  '<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Georgia" w:hAnsi="Georgia" w:cs="Georgia"/><w:sz w:val="22"/><w:lang w:val="en-GB"/></w:rPr></w:rPrDefault>',
  '<w:pPrDefault><w:pPr><w:spacing w:after="140" w:line="300" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>',
  '<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>',
  '<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/>',
  '<w:pPr><w:keepNext/><w:spacing w:before="0" w:after="240"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="34"/></w:rPr></w:style>',
  '<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/>',
  '<w:pPr><w:keepNext/><w:spacing w:before="320" w:after="120"/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="26"/></w:rPr></w:style>',
  '<w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/>',
  '<w:pPr><w:keepNext/><w:spacing w:before="240" w:after="80"/><w:outlineLvl w:val="2"/></w:pPr><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:b/><w:sz w:val="22"/></w:rPr></w:style>',
  '<w:style w:type="paragraph" w:styleId="ListParagraph"><w:name w:val="List Paragraph"/><w:basedOn w:val="Normal"/><w:qFormat/>',
  '<w:pPr><w:spacing w:after="60"/><w:ind w:left="720" w:hanging="360"/></w:pPr></w:style>',
  '<w:style w:type="paragraph" w:styleId="Quote"><w:name w:val="Quote"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:ind w:left="720"/></w:pPr><w:rPr><w:i/></w:rPr></w:style>',
  '<w:style w:type="paragraph" w:styleId="Footer"><w:name w:val="footer"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="360"/></w:pPr><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:color w:val="555555"/><w:sz w:val="18"/></w:rPr></w:style>',
  '<w:style w:type="character" w:styleId="Hyperlink"><w:name w:val="Hyperlink"/><w:rPr><w:color w:val="0563C1"/><w:u w:val="single"/></w:rPr></w:style>',
  '</w:styles>')

# Writes the Markdown as a Word document at `file`.
docx_document <- function(markdown, file, version = NULL) {
  headings <- markdown[grepl("^#\\s+", markdown)]
  title <- if (length(headings)) sub("^#\\s+", "", headings[1]) else "powerkit document"
  built <- docx_body(markdown)
  footer <- sprintf('<w:p><w:pPr><w:pStyle w:val="Footer"/></w:pPr><w:r><w:t xml:space="preserve">%s</w:t></w:r></w:p>',
    docx_escape(sprintf("Made with powerkit%s.", if (is.null(version)) "" else paste0(" ", version))))
  # A4, margins about 2 cm.
  section <- '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1247" w:bottom="1134" w:left="1247" w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>'
  parts <- list(
    "[Content_Types].xml" = paste0('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
      '<Default Extension="xml" ContentType="application/xml"/>',
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>',
      '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>',
      '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/></Types>'),
    "_rels/.rels" = paste0('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>',
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/></Relationships>'),
    "docProps/core.xml" = paste0('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
      '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/">',
      '<dc:title>', docx_escape(title), '</dc:title></cp:coreProperties>'),
    "word/_rels/document.xml.rels" = paste0('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
      '<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>',
      paste(sprintf('<Relationship Id="rIdLink%d" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="%s" TargetMode="External"/>',
        seq_along(built$links), docx_escape(built$links)), collapse = ""),
      '</Relationships>'),
    "word/styles.xml" = docx_styles,
    "word/document.xml" = paste0('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" ',
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><w:body>',
      built$body, footer, section, '</w:body></w:document>')
  )
  dir <- tempfile("powerkit-docx-")
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  for (name in names(parts)) {
    path <- file.path(dir, name)
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    writeLines(enc2utf8(parts[[name]]), path, useBytes = TRUE)
  }
  out <- normalizePath(file, mustWork = FALSE)
  unlink(out)
  zip::zip(out, files = names(parts), root = dir, mode = "mirror")
  invisible(out)
}

# The button that prints a document: the server builds it when `id` is
# clicked (observe it with send_document()).
print_document_button <- function(id, label, class = "btn btn-outline-primary") {
  tags$button(type = "button", id = paste0(id, "_button"), class = class,
    onclick = sprintf("pkPrintDocument('%s')", id), label)
}

# One document in several formats: the PDF as the main button and, beside
# it, a small menu with the Word and Markdown downloads, so a row of
# downloads shows one button per thing to take away. `pdf`, `docx`, `md`:
# the ids (the PDF's as for print_document_button()). The menu items are
# Shiny download links, so their downloadHandler()s are unchanged.
document_menu <- function(pdf, docx, md, label, name, class = "btn btn-outline-primary") {
  menu <- paste0(pdf, "_formats")
  div(class = "btn-group doc-menu", role = "group", `aria-label` = name,
    print_document_button(pdf, label, class = class),
    tags$button(type = "button", id = menu, class = paste(class, "dropdown-toggle dropdown-toggle-split"),
      `data-bs-toggle` = "dropdown", `aria-expanded` = "false",
      tags$span(class = "visually-hidden", paste("Other formats:", name))),
    tags$ul(class = "dropdown-menu", `aria-labelledby` = menu,
      tags$li(shiny::downloadLink(docx, "Word (.docx)", class = "dropdown-item")),
      tags$li(shiny::downloadLink(md, "Markdown (.md)", class = "dropdown-item"))))
}

# The download ids inside the menus, which the server keeps ready while the
# menu is closed (outputOptions(suspendWhenHidden = FALSE) in app.R).
document_menu_downloads <- c("download_planning_docx", "download_planning_document",
  "ws_download_planning_docx", "ws_download_planning_md", "labs_docx", "labs_download", "rep_docx", "rep_markdown")

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
