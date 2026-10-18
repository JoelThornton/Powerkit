# User testing the routing prototype

*Last updated: 18 October 2026 (online link; session script for the four
screens).*

A short, practical plan for testing the prototype with psychologists. The
aim is to find studies the prototype routes wrongly or explains badly, and
to turn each one into a test case ([`test-cases.md`](test-cases.md)). The
maintainer runs the sessions.

**What's being tested:** the prototype online at
<https://joelthornton-powerkit.share.connect.posit.cloud> (no installing; it runs on Posit Connect Cloud). Testers judge
whether they reach the right analysis and understand the screens and the
result, not whether a number is right: results are not yet validated.

## Who to recruit

- **A mix of subfields**, because each brings different designs: for
  example clinical, social, developmental, cognitive, health,
  organisational and educational psychology.
- **A mix of confidence with statistics:**
  - low: uses whatever the supervisor or lab uses;
  - medium: runs their own analyses, has used G\*Power;
  - high: teaches statistics or simulates power.
- **A mix of career stages:** students, postdocs and staff.
- **Each tester brings a real study:** one they're planning, or a recent
  one. Real studies find problems invented ones don't.
- Note the subfield and statistics confidence of each session, with a
  session code instead of a name.

How many sessions to run is the maintainer's call. A useful rule: stop a
round when new sessions mostly repeat problems already logged, fix those,
then run another round.

## Before each session

- Open the prototype at <https://joelthornton-powerkit.share.connect.posit.cloud> at the start screen. Use a fresh browser
  tab per session. The first visit after a quiet spell may take a minute
  to start.
- Have this page, a timer and a notes sheet (below) ready.
- Agree how the session is recorded (notes only, screen recording, audio),
  and get the tester's consent for it. Check whether your institution needs
  ethics approval for usability sessions with colleagues.
- powerkit saves nothing a tester types, but the online version runs on
  Posit's servers, so what is typed passes through them. Ask testers not
  to enter anything identifying. Information otherwise leaves only when
  the tester copies text or downloads a file and gives it to you.

## The 20-minute session

| Time | What happens | What you say (roughly) |
| --- | --- | --- |
| 0–2 min | Welcome and consent | "This is a prototype that helps plan the sample size for a study. We're testing the prototype, not you. Its numbers aren't checked yet, so don't use them for a real study." |
| 2–4 min | Their study | "Describe the study you brought in a couple of sentences: what you compare or relate, who takes part, and how often you measure them." Write it down in their words. |
| 4–5 min | Think-aloud practice | "As you go, please say what you're thinking: what you're looking for, what you expect, anything unclear. If you go quiet, I'll prompt you." |
| 5–7 min | Start screen | "Answer the three questions for your study." Note any question they hesitate over (sample size fixed or not; testing or estimating; one test or several). |
| 7–11 min | Finding the design, their choice of route | "Now find the analysis for your study, however you like." Don't help. If they're stuck for over a minute, ask what they're looking for. |
| 11–13 min | Another route | "Try one of the other ways in" (I know my analysis; Help me choose; Plan my whole study). Faster; note where routes disagree. |
| 13–17 min | Inputs | On the card: "Is this the analysis you'd run?" Then **Enter your values**. Watch the effect size: where they say it comes from, and whether they pick "can't justify one". |
| 17–19 min | Result | "In your own words, what does this result tell you?" Then: "What would you put in your ethics form or preregistration?" (the write-up, if shown). Note whether they keep the "if the true effect is…" condition. |
| 19–20 min | Debrief | "What was the most confusing moment? Would you trust this result? Would you use it instead of what you use now?" Thank them. If anything didn't fit, ask them to open **Something doesn't fit?** and copy the path. |

**During the session:**
- Don't explain the questions or the cards: their confusion is the data.
- If they ask "what does this mean?", ask "what do you think it means?",
  and note the term.
- If they pick "None of these fit / I'm not sure", note where.

## What to record

One sheet per session:

- **Session code, date,** subfield, statistics confidence, career stage.
- **The study,** in their words.
- **For each route:**
  - the end point reached (the E-number shown on the card);
  - the path, from **Something doesn't fit?** (copy it in);
  - whether they agree it's the right analysis.
- **Moments of hesitation:**
  - which question;
  - what they said;
  - roughly how long they paused.
- **Words they didn't understand, or misread.**
- **Where the routes disagreed** for the same study.
- **The effect size:** where they said it came from, and whether they
  could justify one.
- **Their reading of the result,** in their own words (did they keep the
  "if the true effect is…" condition, or read it as a promise?).
- **Quotes** worth keeping (short, without names).
- **For each problem:**
  - one line saying what happened;
  - a severity:
    - would lead to a wrong sample size;
    - would stop them;
    - slowed them down;
    - cosmetic.

## Turning a problem into a test case

The segmented-regression misroute (a trend that changes at a known point,
routed to a t-test) is the model: it is
[TC-001](test-cases.md#tc-001-segmented-regression-routed-to-a-t-test), and
it is now checked in every route by `test-misroutes.R`.

1. **Write the entry.** Copy the template in
   [`test-cases.md`](test-cases.md):
   - the study in the tester's words;
   - what they expected;
   - the copied path;
   - what they got;
   - the kind of problem and its severity.
2. **Reproduce it.** Add the study to
   `app/routing/walkthroughs/scenarios.json`:
   - a two-sentence example, written your own way;
   - the answers in each route;
   - the end point each route reaches now.

   The walkthrough tests then hold the current behaviour.
3. **Decide.**
   - A wording problem can be fixed directly.
   - A wrong end point is a routing decision.
   - If the right card depends on a statistical judgement, add it to
     [`judgement-calls.md`](judgement-calls.md) first, rather than
     choosing.
4. **Fix and test.**
   - Change the route.
   - Update the scenario's end points.
   - Add a test naming the old end point, so the old misroute can't come
     back in any route.
5. **Close.** Fill in "Fixed in" and "Test" in the entry, and re-run the
   walkthroughs ([`walkthroughs.md`](walkthroughs.md)).

## After a round

- Group the problems by question or card; look for the same problem from
  testers in different subfields.
- Count how many studies reached a wrong end point, and in which routes.
- Update [`status.md`](status.md) with what the round found and what was
  fixed.
