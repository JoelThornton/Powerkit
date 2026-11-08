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

## Visual style for contributors

Each screen was once styled on its own, which is where most of the
differences between pages came from. New and changed screens follow this
(decided 7 November 2026); the values live in `app/routing/app.R`'s `:root`
block and `chart_colours` in `R/results.R`.

**Colours** (contrast against white, WCAG AA needs 4.5:1 for body text and
3:1 for large text, borders and chart marks):

| Use | Colour | Contrast |
| --- | --- | ---: |
| Headings and key numbers (`--pk-navy`) | #14284B | 14.6:1 |
| Links, primary buttons, accents (`--pk-blue`) | #0A5A8C | 7.4:1 |
| Secondary text (`ink` in charts) | #4A5568 | 7.5:1 |
| Muted labels | #5D6875 | 5.7:1 |
| Chart grey | #6B7280 | 4.8:1 |
| Chart red (Type I error, a warning) | #B2182B | 6.9:1 |
| Chart amber | #B45309 | 5.0:1 |
| Border amber (`--pk-amber`), borders only | #B97A00 | 3.6:1 |

`--pk-amber` is too light for text; use chart amber or navy for words.
Colour never carries meaning alone: a line also differs in dash or a
shape, and a status also has a word.

**Headings:** one `h1` (the app's name); a screen's title is an `h2`;
sections are `h3`, and their parts `h4`. Where a title must look smaller,
keep the level and add a size class (`h2(class = "h3")`, as Labs tools
do) rather than skipping a level.

**Buttons:** `btn-primary` for the one next step on a screen (Calculate,
Run, Plan this study); `btn-outline-primary` for other actions;
`btn-outline-secondary` for going back or leaving; `btn-link` for an
action inside text. A destructive action (delete a saved answer) is
`btn-outline-danger` and asks first. Targets are at least 44 by 44 CSS
pixels on touch screens and 24 elsewhere.

**Charts:** every chart starts with `chart_start()`, draws its axes with
`chart_axes()` and its key below the plot with `chart_key()`
(`R/results.R`), at `res = 96`, with alternative text and a data table
holding the same numbers.

**Inputs:** number boxes are at most 16rem wide; a field's hint sits under
its label, not in the placeholder.
