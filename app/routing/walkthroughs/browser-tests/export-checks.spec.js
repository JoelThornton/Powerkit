const { test, expect } = require('@playwright/test');
const { downloadLinkProblem, downloadResponseProblem, printDocumentProblem, missingControlsProblem, REQUIRED_RESULT_DOWNLOADS } = require('../export-checks');

test('the release sweep rejects missing and empty print documents', () => {
  expect(printDocumentProblem(null)).toContain('no document');
  expect(printDocumentProblem({ heading: '', body: 'Made with Powerkit' })).toContain('no heading');
  expect(printDocumentProblem({ heading: 'Power analysis', body: '' })).toContain('no substantial body');
  expect(printDocumentProblem({ heading: 'Power analysis', body: 'The planned sample has 84 participants.' })).toBeNull();
});

test('the release sweep checks enabled links and verifies downloaded formats', () => {
  expect(downloadLinkProblem({ href: '', disabled: false })).toContain('no download URL');
  expect(downloadLinkProblem({ href: '', disabled: true })).toBeNull();
  expect(downloadLinkProblem({ href: 'session/example/download/download_bundle?w=1', disabled: false })).toBeNull();
  const headers = { 'content-disposition': 'attachment; filename="planning.docx"' };
  expect(downloadResponseProblem(200, Buffer.alloc(80), headers)).toContain('ZIP archive');
  const zipStart = Buffer.from([0x50, 0x4b, 0x03, 0x04]);
  const zipEnd = Buffer.concat([Buffer.from([0x50, 0x4b, 0x05, 0x06]), Buffer.alloc(18)]);
  const body = Buffer.concat([zipStart, Buffer.alloc(80), Buffer.from('[Content_Types].xml word/document.xml'), zipEnd]);
  expect(downloadResponseProblem(200, body, headers)).toBeNull();
  // A cut-off Word file: the parts but no end of the archive.
  const cut = Buffer.concat([zipStart, Buffer.alloc(80), Buffer.from('[Content_Types].xml word/document.xml')]);
  expect(downloadResponseProblem(200, cut, headers)).toContain('incomplete ZIP');
  // A Word file without its content types part.
  const partial = Buffer.concat([zipStart, Buffer.alloc(80), Buffer.from('word/document.xml'), zipEnd]);
  expect(downloadResponseProblem(200, partial, headers)).toContain('[Content_Types].xml');
  // Plain text where a file of a known kind is expected, or with no file name.
  const text = Buffer.from('Some plain text that is long enough to pass the size check but is not a file of any kind.');
  expect(downloadResponseProblem(200, text, {})).toContain('no file name');
  expect(downloadResponseProblem(200, text, { 'content-disposition': 'attachment; filename="plan.md"' })).toContain('Markdown');
  expect(downloadResponseProblem(200, text, { 'content-disposition': 'attachment; filename="data.csv"' })).toContain('comma-separated');
  expect(downloadResponseProblem(200, text, { 'content-disposition': 'attachment; filename="file.bin"' })).toContain('unexpected file type');
  expect(downloadResponseProblem(200, Buffer.from('# Plan\n\nThe planned sample has 84 participants in two groups.'),
    { 'content-disposition': 'attachment; filename="plan.md"' })).toBeNull();
  const invalid = Buffer.from('<!DOCTYPE html><html><head><title>Unexpected error</title></head></html>');
  expect(downloadResponseProblem(200, invalid, headers)).toContain('error page');
});

test('the release sweep fails a result whose expected downloads or print button are missing', () => {
  expect(missingControlsProblem(REQUIRED_RESULT_DOWNLOADS, true)).toBeNull();
  expect(missingControlsProblem(REQUIRED_RESULT_DOWNLOADS.slice(1), true)).toContain('download_project');
  expect(missingControlsProblem(REQUIRED_RESULT_DOWNLOADS, false)).toContain('print');
  expect(missingControlsProblem([], false)).toContain('download_citations');
});
