## 2026-11-21 · The online app: published weekly to stay within the free plan

Posit Connect Cloud's free plan (20 usage credits a month) is now
enforced: at the limit the account, and the online app with it, is paused
until the monthly reset. By 21 November 2026 the app had used 16 of the
month's credits (from 18 November), with eight publishes in four days,
five of them started by hand after merges.

- **Publishing:** the `online-app-manifest` workflow's schedule publishes
  once a week (Mondays, 04:23 UTC, with the 16:23 second look) instead of
  every day. A publish by hand ("Run workflow") is the maintainer's, for
  an urgent fix; pull requests and sessions don't start one after a merge
  (`CLAUDE.md`).
- **Keep-open message:** sent while the page is in view and has been used
  in the last 10 minutes (20 before), or while a calculation runs, so a
  tab left open stops holding the app up sooner. Answers on an input
  screen still come back from the browser's copy after a reconnect.
- **Not decided here:** the plan or the host. These changes slow the use
  of credits but cannot make the rest of the month's last through
  testing (`hosting-options.md`, "The free plan's limit").
