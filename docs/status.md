# Project status

*Last updated: 18 October 2026. This page says where the project is now
and what comes next; keep it short and replace old entries rather than
adding to them. History is in git, [`engine/NEWS.md`](../engine/NEWS.md)
and [`archive/status-history.md`](archive/status-history.md) (everything
up to 18 October 2026).*

powerkit is in development and **not ready for use**: results are not yet
fully validated. Validation runs are recorded in
[`validation-log.md`](validation-log.md). For the working rules, see
[`handover.md`](handover.md) and `CLAUDE.md`.

## Where things are

- **Engine** (`engine/`): designs E1–E14 run through `run_spec()`. Their
  validation so far is mostly agreement with the package each one calls,
  plus Type I error; independent checks exist for the basic tests (the
  maintainer's G\*Power screenshots) and simple, parallel and serial
  mediation (pwrss and simsem). Published values are still to be
  transcribed (`TODO_PUBLISHED_VALUE` placeholders). Wave 2 (one-way
  ANOVA, R², one proportion, McNemar, Welch by formula) runs in the engine
  and matches G\*Power, but isn't in the app yet.
- **App** (`app/routing/`): the question tree, cards and input screens for
  every end point. E1–E9 calculate in the app; E10–E14 give a rough
  preview, then a full run in the app or an R script. Results can be saved
  as a project file and reopened. The "About this prototype" tab and the
  run-it-yourself guide ([`run-it-yourself.md`](run-it-yourself.md)) let
  colleagues run it on their own computers.
- **Open PRs:** see [`handover.md`](handover.md).

## Priorities (the maintainer, 18 October 2026)

- **Usefulness before validation.** powerkit won't be released for a
  while. What matters now is that it is useful, logical and helpful for
  psychologists and solves the problems they have with power analysis.
  Validation and checks come afterwards, before release.
- **The new design** (four screens: start questions, design finder, inputs
  centred on the effect size, result with a plain reading and write-up) is
  in the app: screens A, C and D and the departures on the result screen
  were merged on 18 October 2026. The write-up is still to come.

## What's next

1. Docs: record the design decisions and close the judgement calls they
   settle (G9, most of B10, G8, part of B6/G7). In review.
2. The minimal write-up and methods paragraph: needs a minimal G4
   decision.
3. The "does this still apply?" flag on the effect-size source when the
   effect size is changed; the smallest detectable effect for E5–E9 in the
   app.
4. Then user testing ([`user-testing.md`](user-testing.md)); later, before
   release, published values, independent checks, phase 3b and wave 2 in
   the app.
