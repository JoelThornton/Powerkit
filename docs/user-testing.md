# User testing the routing prototype

*Last updated: 17 October 2026.*

A short, practical plan for testing the prototype with psychologists. The
aim is to find studies the prototype routes wrongly or explains badly, and
to turn each one into a test case ([`test-cases.md`](test-cases.md)). The
maintainer runs the sessions.

**What's being tested:** the routing prototype only (how to run it:
[`routing-prototype.md`](routing-prototype.md)). It calculates nothing, so
testers judge whether they reach the right analysis and understand the
card, not whether a number is right.

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

- Run the prototype ([`routing-prototype.md`](routing-prototype.md)) and
  open it at the start screen. Use a fresh browser tab per session.
- Have this page, a timer and a notes sheet (below) ready.
- Agree how the session is recorded (notes only, screen recording, audio),
  and get the tester's consent for it. Check whether your institution needs
  ethics approval for usability sessions with colleagues.
- Nothing typed in the prototype is sent anywhere or saved. The only way
  information leaves it is when the tester copies text and gives it to you.

## The 20-minute session

| Time | What happens | What you say (roughly) |
| --- | --- | --- |
| 0–2 min | Welcome and consent | "This is a prototype that suggests which power analysis a study needs. We're testing the prototype, not you. It doesn't calculate anything yet." |
| 2–4 min | Their study | "Describe the study you brought in a couple of sentences: what you compare or relate, who takes part, and how often you measure them." Write it down in their words. |
| 4–5 min | Think-aloud practice | "As you go, please say what you're thinking: what you're looking for, what you expect, anything unclear. If you go quiet, I'll prompt you." |
| 5–11 min | Route 1, their choice | "Start however you like and find the analysis for your study." Don't help. If they're stuck for over a minute, ask what they're looking for. |
| 11–16 min | Routes 2 and 3 | "Now try it the other ways": the routes they didn't choose (I know my analysis; Help me choose; Plan my whole study). Faster; note where routes disagree. |
| 16–18 min | The end card | "Is this the analysis you'd run? Is anything on the card unclear?" If it's one of E1–E14, ask them to try **Enter your values**. If anything doesn't fit, ask them to open **Something doesn't fit?**, copy the path and add what they expected. |
| 18–20 min | Debrief | "What was the most confusing moment? Was there a question you weren't sure how to answer? Would you trust where it sent you?" Thank them. |

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
