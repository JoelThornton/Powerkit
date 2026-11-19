const { test, expect } = require('@playwright/test');
const { downloadLinkProblem, downloadResponseProblem, printDocumentProblem } = require('../export-checks');

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
  const body = Buffer.concat([Buffer.from([0x50, 0x4b, 0x03, 0x04]), Buffer.alloc(80), Buffer.from('word/document.xml')]);
  expect(downloadResponseProblem(200, body, headers)).toBeNull();
  const invalid = Buffer.from('<!DOCTYPE html><html><head><title>Unexpected error</title></head></html>');
  expect(downloadResponseProblem(200, invalid, headers)).toContain('error page');
});
