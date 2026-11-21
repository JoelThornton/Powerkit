// Checks for the release sweep. Keep the checks independent of Playwright
// so empty documents and incorrect response types can be tested directly.
function downloadLinkProblem(link) {
  if (link.disabled) return null;
  if (!link.href || !/(?:^|\/)download\//.test(link.href)) {
    return 'enabled download has no download URL';
  }
  return null;
}

// The file types powerkit's downloads produce.
const KNOWN_EXTENSIONS = ['r', 'csv', 'docx', 'json', 'md', 'txt', 'zip'];

function downloadResponseProblem(status, body, headers) {
  if (status !== 200) return `HTTP ${status}`;
  if (body.length < 50) return `tiny response (${body.length} bytes)`;
  const disposition = headers['content-disposition'] || '';
  const extension = (disposition.match(/\.([a-z0-9]+)"?(?:;|$)/i) || [])[1]?.toLowerCase();
  const start = body.subarray(0, 4000).toString('utf8');
  if (/^\s*(?:<!doctype html\b|<html\b)|Error in |Traceback/i.test(start)) {
    return 'contains an error page or R error';
  }
  if (!extension) return 'no file name with an extension';
  if (!KNOWN_EXTENSIONS.includes(extension)) return `unexpected file type (.${extension})`;
  if (extension === 'zip' || extension === 'docx') {
    if (!body.subarray(0, 4).equals(Buffer.from([0x50, 0x4b, 0x03, 0x04]))) return 'expected a ZIP archive';
    // A complete archive ends with its central directory's end record
    // (PK 5 6), within the last 22 bytes plus any comment: a cut-off
    // download has the local headers but not this.
    if (!body.subarray(Math.max(0, body.length - 65557)).includes(Buffer.from([0x50, 0x4b, 0x05, 0x06]))) {
      return 'incomplete ZIP archive (no end of central directory)';
    }
    if (extension === 'docx') {
      for (const part of ['[Content_Types].xml', 'word/document.xml']) {
        if (!body.includes(part)) return `missing the Word document part ${part}`;
      }
    }
  } else if (extension === 'json') {
    try {
      const data = JSON.parse(body.toString('utf8'));
      if (!data || typeof data !== 'object' || Array.isArray(data)) return 'expected a JSON object';
    } catch {
      return 'invalid JSON';
    }
  } else if (extension === 'r' && !/^\s*#/.test(start)) {
    return 'expected an R script beginning with a comment';
  } else if (extension === 'md' && !/^\s*#/m.test(start)) {
    return 'expected a Markdown document with a heading';
  } else if (extension === 'csv' && !/^[^\n]*,[^\n]*\n[^\n]*,/.test(start)) {
    return 'expected comma-separated rows';
  } else if (extension === 'txt' && start.trim().split('\n').length < 2) {
    return 'expected a text file of more than one line';
  }
  return null;
}

// The downloads a calculated result always offers, and the printable
// document: missing ones are a problem, not a pass (the sweep only checks
// the links it finds).
const REQUIRED_RESULT_DOWNLOADS = ['download_project', 'download_citations', 'download_planning_docx', 'download_planning_document'];

function missingControlsProblem(linkIds, hasPrint) {
  const missing = REQUIRED_RESULT_DOWNLOADS.filter(id => !linkIds.includes(id));
  if (!hasPrint) missing.push('planning_document_button (print)');
  return missing.length ? `missing expected controls: ${missing.join(', ')}` : null;
}

function printDocumentProblem(document) {
  if (!document) return 'print frame has no document';
  if (!document.heading.trim()) return 'print document has no heading';
  if (document.body.trim().length < 15) return 'print document has no substantial body';
  return null;
}

module.exports = { downloadLinkProblem, downloadResponseProblem, printDocumentProblem, missingControlsProblem, REQUIRED_RESULT_DOWNLOADS };
