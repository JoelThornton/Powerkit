# Main, releases and automatic publishing

Main originally allowed unguarded updates, and the manifest workflow wrote
directly to main. Requiring PRs/checks while retaining that write would break
publishing. Do not add an app bypass simply to work around that conflict.

## Migration order

1. An active main rule can immediately restrict deletions and force pushes,
   with no bypass actors. This does not block normal merges or publishing.
2. Merge the publishing change after its CI and branch-preparation tests pass.
   The manifest workflow then prepares `connect-cloud` (at its next daily
   run, or at once with "Run workflow" on main): exactly the selected
   main tree apart from its generated manifest, with the engine pinned to that
   main commit. Its push is fast-forward only. Stale main jobs refuse to publish.
3. Verify the first successful publishing run and the deployment branch's
   manifest/source pin. In Posit Connect Cloud's GitHub source settings, select
   branch `connect-cloud`, retaining `app/routing` and the existing app entry
   point. Redeploy and check the app/version. This is a one-time hosting change;
   no new credentials or app permissions are required.
4. Add an active main ruleset requiring a pull request and these existing,
   always-created aggregate checks: `engine-review-gate` and
   `app-review-gate`, plus the always-created PR check `manifest`. They explicitly reject dependency failures/cancellations
   and skips caused by failed prerequisites. An engine skip is accepted only
   when the successful change detector explicitly found no engine changes.
   Pin checks to the GitHub Actions source when available. For one maintainer,
   require zero additional approvals; do not require self-approval. Require
   conversation resolution. Leave no bypass actors. Do not require linear
   history: the repository uses merge commits. Require the branch to be up to
   date if the maintainer accepts rerunning checks after concurrent merges.
5. The manifest check runs on every PR so it can safely be required. Keep
   checking conditional Windows/macOS setup jobs when they run. Do not make
   their path-filtered absent checks mandatory: that would block
   documentation-only PRs.
6. Add a tag ruleset for release tags `v*`, blocking updates and deletions.
   Restrict tag creation to the maintainer if desired. A release still needs
   explicit review of the high-replication validation summary: skipped,
   unpublished benchmarks and not-run cases are not passes. Ordinary CI is
   insufficient evidence for a scientifically validated release.

## Checks before a release

Every version is tagged automatically, but a release that researchers are
pointed to (a talk, a paper, leaving prototype) gets three checks first,
each run from the repository root with the engine installed. None is in
CI: together they take several hours.

- **The full validation run** (`scripts/run-validation.R`), recorded in
  `validation-log.md`.
- **Property checks over every example spec**
  (`Rscript scripts/release-checks/property-checks.R`, about two hours
  on four cores, most of it the mediation designs; each design stops
  after 30 minutes): each design's example runs and records its provenance;
  the recommended n reaches the target power and, by formula, one fewer
  doesn't; power grows with n; the same seed gives the same answer; and
  with no effect, power is about alpha. It lists every design with a
  problem and exits with status 1 if there is one.
- **Every card in a browser**
  (`app/routing/walkthroughs/every-card.js`, about an hour): write the
  card list with `Rscript app/routing/walkthroughs/every-card-list.R
  cards.json`, start the app with `Rscript
  app/routing/walkthroughs/browser-server.R`, then run `node
  app/routing/walkthroughs/every-card.js cards.json every-card.json` (and
  again with `power` as a third argument for the power goal). It fills
  each card's example values from the app suite, calculates, and fetches
  every download and the printable document, and lists every card that
  shows R error text, NA or NaN, a blank output, a failed download or a
  browser console error. Set `PW_CHROMIUM` to a Chromium executable if
  Playwright can't find one.

A problem in any of them is fixed, or recorded in `next.md`, before the
release.

Settings are not activated by this document. Record their live ruleset IDs
and enforcement state only after confirming them in GitHub. The deployment
branch must not receive the main PR/check rule: only the publishing workflow
updates it, and the script refuses any source difference outside the manifest.

## Recovery

If main advances during manifest generation, publish the newer run rather
than overriding it. An unexpected merge/source conflict fails before pushing.
Never force-push the deployment branch. If a check name changes, update the
required-check rule in the same reviewed maintenance step. A failed deployment
does not justify bypassing scientific validation or weakening main's checks.

## Observed configuration

Checked through the GitHub API on 7 November 2026. Three rulesets are
active, none with bypass actors:

- **Protect main history** (26634634, 5 November 2026): blocks deletion
  and force pushes on main.
- **Require checked pull requests** (26659017, 5 November 2026): main
  takes changes only through a pull request (no approvals required,
  conversations resolved) whose `engine-review-gate`, `app-review-gate`
  and `manifest` checks, from GitHub Actions, pass on an up-to-date
  branch.
- **Protect release tags** (26659045, 5 November 2026): tags matching
  `v*` can't be updated or deleted.

Publishing goes through `connect-cloud` (step 3), which the manifest
workflow updated on 7 November 2026. Release tags are created by
`.github/workflows/release-tags.yaml` (`scripts/tag-releases.sh`): each
finished version is tagged at main's last commit carrying it, with its
`engine/NEWS.md` section as the release notes.
The workflow pushes with the `RELEASE_TOKEN` secret (a fine-grained
token for this repository with Contents and Workflows write), because
GitHub refuses a tag from the workflow's own token when the tagged
commit's workflow files differ from main's.

The feedback database (Supabase) was checked in its dashboard on
7 November 2026: the `powerkit_feedback` table has row-level security on,
no policies and its Data API access off, so the app's public key can call
`send_powerkit_feedback()` but can't read messages.
