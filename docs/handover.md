# Handover

*Updated 8 November 2026, for whoever picks the project up next. The
working rules are in [`CLAUDE.md`](../CLAUDE.md) and only there; this page
says where things live. [`README.md`](README.md) maps every document.*

## Where to start

- [`status.md`](status.md): where the project is now, area by area.
- [`next.md`](next.md): what to do next, in order, each item marked Ready
  or needing a decision, with what waits on the maintainer at the bottom.
- [`adding-a-test.md`](adding-a-test.md): how a power analysis is added,
  start to finish.
- Open pull requests are on GitHub; git history and
  [`engine/NEWS.md`](../engine/NEWS.md) hold everything merged.

## The shape of the app

Four screens ([`decisions.md`](decisions.md), "2026-10-18 · The new
design"): start questions; the question tree and its cards; inputs centred
on the effect size and the user's reasoning; and the result, with a plain
reading, what power can't tell you, and any departures from the usual
tools. Simulated designs give a preview, then a full run or an R script;
plans save as project files. Labs holds the teaching and experimental
tools.

## Where decisions and open questions live

- [`decisions.md`](decisions.md): the maintainer's decisions, dated.
- [`conventions.md`](conventions.md): each backend's conventions and
  powerkit's departures and known differences (numbered there).
- [`judgement-calls.md`](judgement-calls.md): open judgement calls with a
  recommendation each; decided ones move to
  [`archive/judgement-calls-decided.md`](archive/judgement-calls-decided.md).
- [`upstream-questions.md`](upstream-questions.md): faults and questions
  for the packages powerkit calls.
- In the app, "For the maintainer: undecided settings" lists the
  placeholders from `tree.yaml`.

## Branches and tags

Sessions can't delete remote branches or push tags. Merged branches delete
themselves; the one other branch to keep is
`claude/project-thread-uqcark-webr-spike` (the webR trial, linked from
[`hosting-options.md`](hosting-options.md)). `connect-cloud` is written
only by the publishing workflow. Release tags come from
`scripts/tag-releases.sh` ([`repository-protection.md`](repository-protection.md)).
