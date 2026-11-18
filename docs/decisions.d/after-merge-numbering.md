## 2026-11-18 · Versions are given after a merge, not by each pull request

From 13 November 2026 every pull request ran `scripts/close-batch.R` as
its last commit, so that every change on main had its own number. With
several pull requests open at once, each merge took the number the
others had claimed: each of them then had to merge main, renumber and
run its checks again (up to an hour each time), and the same happened
with the status page's "Last updated" line, the end of this log and the
release inventory, which every pull request rewrote.

Decision: pull requests write only files of their own and the lines
their change is about. After each merge, `.github/workflows/after-merge.yaml`
runs `scripts/after-merge.R` on main: the waiting change notes get the
next version (minor when a merged pull request has the "minor" label,
otherwise patch), the entries waiting in `decisions.d/` are added here,
oldest first, `status.md` gets the date, and the release inventory is
regenerated, in one commit marked `[skip ci]`. The same job tags the
version and publishes its release. Every change on main still gets its
own number; it arrives a minute or two after the merge.

The job pushes to main with the `RELEASE_TOKEN` secret, so the "Require
checked pull requests" ruleset lists the repository admin role as its one
bypass actor (`repository-protection.md`). Everything else still reaches
main only through a pull request with passing checks.

`status.md` was cut from 58 KB to 25 KB at the same time, since every
thread reads it in full: the dated history of each area moved to the end
of `archive/status-history.md`, word for word.
