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
- **This week:** preparing the maintainer's talk to PhD students and staff
  in the department (Friday 23 October 2026), on how well psychologists
  understand and carry out power analysis, and where powerkit helps.

## What's next

1. The talk: material and examples for Friday.
2. The judgement session ([`judgement-session.md`](judgement-session.md)):
   it unblocks G4 (the methods paragraph) and the other calls that change
   what users see.
3. A first round of user testing with psychologists
   ([`user-testing.md`](user-testing.md)).
4. Departures 6, 7 and 8 and Known difference 1 on the result screen: in
   review.
5. Later, before release: a short list of published values to transcribe
   first (one or two per design), independent checks for moderated
   mediation and for the Monte Carlo interval with two or more mediators,
   phase 3b (binary X and W), and wiring wave 2 into the app.
