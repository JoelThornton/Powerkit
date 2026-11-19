// Checks for the release sweep. Keep the checks independent of Playwright
// so empty documents and incorrect response types can be tested directly.
function downloadLinkProblem(link) {
  if (link.disabled) return null;
  if (!link.href || !/(?:^|\/)download\//.test(link.href)) {
    return 'enabled download has no download URL';
  }
  return null;
}

function downloadResponseProblem(status, body, headers) {
  if (status !== 200) return `HTTP ${status}`;
  if (body.length < 50) return `tiny response (${body.length} bytes)`;
  const disposition = headers['content-disposition'] || '';
  const extension = (disposition.match(/\.([a-z0-9]+)"?(?:;|$)/i) || [])[1]?.toLowerCase();
  const start = body.subarray(0, 4000).toString('utf8');
  if (/^\s*(?:<!doctype html\b|<html\b)|Error in |Traceback/i.test(start)) {
    return 'contains an error page or R error';
  }
  if (extension === 'zip' || extension === 'docx') {
    if (!body.subarray(0, 4).equals(Buffer.from([0x50, 0x4b, 0x03, 0x04]))) return 'expected a ZIP archive';
    if (extension === 'docx' && !body.includes('word/document.xml')) return 'missing the Word document part';
  } else if (extension === 'json') {
    try {
      const data = JSON.parse(body.toString('utf8'));
      if (!data || typeof data !== 'object' || Array.isArray(data)) return 'expected a JSON object';
    } catch {
      return 'invalid JSON';
    }
  } else if (extension === 'r' && !/^\s*#/.test(start)) {
    return 'expected an R script beginning with a comment';
  }
  return null;
}

function printDocumentProblem(document) {
  if (!document) return 'print frame has no document';
  if (!document.heading.trim()) return 'print document has no heading';
  if (document.body.trim().length < 15) return 'print document has no substantial body';
  return null;
}

module.exports = { downloadLinkProblem, downloadResponseProblem, printDocumentProblem };
