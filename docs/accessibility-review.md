# Accessibility verification scope

The pinned browser suite checks WCAG A/AA machine rules with axe-core,
keyboard routing/focus, error announcements and document overflow at 1100,
375 and 320 CSS pixels. The latter is the reflow width corresponding to a
1280-pixel viewport at 400% zoom; it is not a native browser-zoom test.
One desktop flow also doubles the root text size. Screens include start,
analysis card, input form, validation errors and a real calculated result
with its exploration data table. JSON rule reports and failure traces are
retained by CI. This is not a certification of WCAG compliance.

Findings addressed in this batch:

- Darker small card labels address the observed contrast failure.
- Text-only download buttons remove invalid labelled decorative-icon markup
  produced by the locked Shiny version. Existing button labels remain intact.
- Collapsible summaries have at least 24-pixel target height.
- Exploration/scenario charts have meaningful alternative text and equivalent
  data tables, explicitly labelled with sample units and percent power.
  Tables use the same cached engine points as the plots, with no extra power
  calls; missing points read “Not calculated”, rather than zero.

The automated accessibility-tree snapshots check semantics exposed to assistive
technology. They do not establish how a person experiences NVDA, JAWS or
VoiceOver. Real screen-reader speech/navigation, native zoom, high contrast,
touch interaction and the remaining specialist/Labs routes still require
manual verification. Record browser/OS/assistive-technology versions and
observations before marking the complete accessibility audit finished.
