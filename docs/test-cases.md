# Test cases from user testing

*Last updated: 17 October 2026.*

Each problem a tester finds becomes one entry here, and then a test, so it
can't come back unnoticed. How sessions are run, and how a problem gets
here, is in [`user-testing.md`](user-testing.md).

**How an entry becomes a test:**
1. **Record:** write the entry from the tester's own words and the path
   they copied from **Something doesn't fit?** on the card they reached.
2. **Reproduce:** add the study to
   [`app/routing/walkthroughs/scenarios.json`](../app/routing/walkthroughs/scenarios.json)
   with the answers given and the end point reached **now**.
   `test-walkthroughs.R` then checks that it still reaches that end point.
3. **Decide:** a wrong end point is a routing question for the maintainer;
   if it needs a statistical judgement, it goes into
   [`judgement-calls.md`](judgement-calls.md) first.
4. **Fix and test:** once decided, change the route, update `reaches` in
   `scenarios.json`, and add a test that names the old end point (as in
   `test-misroutes.R`), so the fix is checked in every route.
5. **Close:** fill in "Fixed in" and "Test" below, and re-run the
   walkthroughs.

## Template

Copy this block for a new entry. Number entries in order (TC-002,
TC-003, ...).

```markdown
### TC-000. Short name of the problem

- **Reported:** date; session code (no names); the tester's subfield and
  confidence with statistics (low, medium or high).
- **The study, in the tester's words:** one or two sentences.
- **What they expected:** the analysis or card they expected, in their words.
- **Path taken:** paste the text from "Something doesn't fit?".
- **What they got:** the end point reached, and why it's wrong or
  confusing.
- **Kind:** misroute (wrong end point) / confusing wording / missing design
  / other.
- **Severity:** would lead to a wrong sample size / would stop them /
  slowed them down / cosmetic.
- **In other routes:** what the other two routes give for the same study.
- **Decision needed:** none / routing / judgement call (link to
  `judgement-calls.md`).
- **Scenario:** the id added to `scenarios.json`.
- **Fixed in:** PR link, or "open".
- **Test:** the test file and name that checks the fix.
```

## Entries

### TC-001. Segmented regression routed to a t-test

- **Reported:** before the routing audit (fixed in PR #18, 16 October
  2026). The tester's details weren't recorded; this entry is written
  from the audit.
- **The study** (the walkthroughs' example for this design): "A school
  introduced a phone ban last September, and we have its average
  wellbeing score for every month in the two years before and the year
  after. We want to know whether the trend in wellbeing changed when the
  ban started."
- **What they expected:** a segmented regression (interrupted time
  series): a change in level or slope at a known point.
- **Path taken** (before the fix; [`routing-audit.md`](routing-audit.md),
  "The two segmented regression paths"):
  - path 1: A difference between groups or conditions → A score or scale →
    The same people in every condition → One → Two, with the same people in
    both (or one group measured twice);
  - path 2: A difference between groups or conditions → A score or scale →
    Different people in each group or condition → One → Two, with different
    people in each.
- **What they got:**
  - path 1: **E3, paired t-test**;
  - path 2: **E2, independent t-test**, with the periods before and after
    the breakpoint treated as two groups;
  - a correlation path reached **E4** (time as the other variable).

  A t-test compares average levels, not whether a trend changes; a
  correlation can't show a change in slope.
- **Kind:** misroute.
- **Severity:** would lead to a wrong sample size.
- **In other routes:** the guided route reached E2 as well.
- **Decision needed:** routing (made: screening questions first in every
  route, and a card for this design, E45).
- **Scenario:** `segmented` in `scenarios.json` (choose, known and guided
  answers all reach E45).
- **Fixed in:** PR #18 (screening questions S1–S4 and T1; card E45). The
  card's wording was updated in PRs #24 and #25.
- **Test:** `test-misroutes.R`, "segmented regression no longer reaches a
  t-test or a correlation, in any route"; `test-walkthroughs.R` (the
  `segmented` scenario).
- **Still open:** someone with this design who answers S3 "Twice" still
  reaches the before/after tests (open question 16, screening wording;
  [`judgement-calls.md`](judgement-calls.md), C1).
