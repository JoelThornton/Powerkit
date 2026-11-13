# Saving projects: options

## Current draft recovery

The input screen's **Save unfinished draft** downloads a `.powerkit.json`
file containing partial editable answers and a saved time. No calculation
or effect-size justification is required. From the start screen, open it
under **Open a saved or shared project**. Blanks are retained;
the app clears any previous calculation and identifies the reopened work
as an unvalidated draft. Check the answers before calculating or saving a
validated project. A draft is not evidence a reviewer can check as a result.

This is explicit file-based recovery: download a draft, or copy a link
to it (below), before closing or leaving an unfinished form. Project files with calculated results retain
their separate validation and provenance rules.

## Keeping a result: the result screen (13 November 2026)

The result screen separates the files that reopen in powerkit from the
documents made from a result (`R/keep-result.R`). Before, six equal
buttons sat at the foot of a long page, with Save project styled like
Citations, so a visitor could download the planning PDF, think the work
was saved, and lose it.

- **Keep this result**, at the foot of the answer card: Save project file
  (the screen's primary button), Copy a link and Add to my study plan.
  A status reads "Not saved yet" and changes once one of them is used;
  a result reopened from a file starts as kept.
- **Documents for your study**, in "Write it up and save it": the
  planning document, R script, citations and **Download everything
  (.zip)**, said plainly not to reopen in powerkit. The zip holds the
  project file, the planning document (Markdown and Word), the R script,
  the citations, the simulated data set where there is one, and a README
  naming each file. The project file is written first with no fallback and the finished zip is checked for it, so the download fails rather than give a zip that can't be reopened. **Open a saved or shared project** accepts the zip
  and opens the one `.powerkit.json` inside it, extracted under its own
  name into a temporary folder.
- **Safety nets.** The last current result is kept in the browser's
  local storage (key `powerkit-last-result`, up to 1.5 MB) beside the
  autosaved draft; the "Continue your plan?" offer brings the result back
  when its answers match the draft's, and says it was kept in this
  browser only. The browser asks before leaving a result that hasn't been
  kept, while the app is connected.
- After Calculate, the input screen's draft row (Save unfinished draft
  and its Copy a link) is hidden while the result matches the answers, so
  the page has one Save and one Copy a link; it returns when an answer
  changes.

## Share links (13 November 2026)

**Copy a link**, beside every save button (Save project, Save study plan,
Save this plan and Save unfinished draft), makes a link that carries the
same text the button downloads. The text is compressed in the browser
(CompressionStream, `deflate-raw`, then base64url) and put in the link's
fragment: `<address>#shared=1.<data>`. Browsers do not send the fragment
to the server, so the study never appears in the host's request logs,
and powerkit stores nothing: the link is the file. Opening the link
unpacks it in the browser, removes it from the address bar and hands the
text to the same reader and checks as **Open a saved or shared project**
(`R/share-link.R`, `open_saved_file()` in `app.R`).

- **Size.** A two-group t-test project makes a link of about 4,400
  characters, a one-analysis study plan about 4,600 (measured 13 November
  2026). Links over 60,000 characters are refused with a message to save
  the file, as some email and chat apps break very long links;
  unpacking stops at 5 MB.
- **Privacy.** Anyone with the link can open the plan, as with the
  file; the About page and each save area say so.
- **Online app.** The public address frames the app (Connect Cloud).
  Query strings reach the app through the frame (`?page=`, `?card=`);
  whether the fragment does too could not be checked from the
  environment this was built in. If it doesn't, links open the start
  screen on the public address and work on the app's own address and on
  local installations; the fix would be to read the plan from the query
  string instead, at the cost of the host's logs seeing it.

**Ruled out for now (13 November 2026).** Accounts with stored projects
(option (e) below) need a server-side database, an email service and the
UK GDPR duties of a controller; the paid database plan alone is a
monthly cost the project can't carry, and a free plan would still bring
the legal duties and upkeep. Saving to the user's own OSF project was
considered and dropped: OSF stops new projects from 16 November 2026
and makes existing ones read-only on 19 February 2027, keeping
registrations and preprints ([COS, "OSF is
Changing"](https://www.cos.io/osf-changes), via search, 13 November 2026). Share links give the main
gain of accounts, a plan on any computer, without either.

## Historical saving-model decision

*18 October 2026.* **Decided and built:** option (a), a project file the
user saves and reopens (PR #52, merged 18 October 2026; `decisions.md`).
The rest of this page is the options as they were written before that
decision, kept for the reasoning (judgement call E6 in
[`judgement-calls.md`](judgement-calls.md)).

**About the facts below.** Hosting prices are from
[`hosting-options.md`](hosting-options.md), which marks every figure as a
search result to check. The UK GDPR notes are general information drawn
from what each option stores, not legal advice; the university's data
protection officer is the person to confirm them.

## What a saved project would hold

Whatever the option, a project is the same few things:

- the route taken (the card reached and the answers that led there);
- the inputs on the form (the design spec, including its effect-size
  justification);
- the seed;
- the results, if calculated (power, N, the power curve, recruitment);
- the powerkit version, R version and backend package versions, and the
  spec hash (as every result already records).

The design spec is already a JSON file with a schema
(`engine/inst/schema/design.schema.json`), and every result already
records its seed, versions and spec hash. So most of a project file
exists; the new parts are the route and a wrapper.

## The options

### (a) A project file the user saves and loads

A "Save project" button downloads one file (for example
`my-study.powerkit.json`); "Open project" reads it back and restores the
route, the inputs and the results.

- **For users.** They keep their own work, can email it to a co-author or
  supervisor, attach it to a preregistration, and reopen it later. A
  file from an older powerkit version can be reopened with a note that
  the versions differ, and recalculated.
- **Privacy and UK GDPR.** The file stays with the user; the app stores
  nothing. A study design is not usually personal data, though the file
  could hold names if a user types them into a label. Nothing new for
  the host to manage.
- **Cost.** None to run.
- **Maintenance.** Low to medium: the file format needs a version number,
  and future versions must read old files (or say plainly that they
  can't).
- **With each hosting option.** Works the same everywhere: run it
  yourself, shinyapps.io, Connect, a university server, a container
  service, webR/Shinylive (downloads and uploads work in the browser), and
  a desktop bundle.

### (b) Autosave in the browser's storage

The app saves the current answers in the browser (local storage) as the
user goes, and offers to restore them next time, on the plan tab's first screen ("Continue my plan", "Not now", or "Discard my draft", the only choice that deletes it; since 7 November 2026).

- **For users.** Nothing to remember to do; a closed tab or crash loses
  nothing. But it lives in one browser on one computer, can be cleared
  by the browser, and is lost in private windows.
- **Privacy and UK GDPR.** The data stays on the user's device. Storing
  information on a user's device is covered by the Privacy and
  Electronic Communications Regulations (PECR) as well as UK GDPR; storage
  the user needs for a feature they asked for is usually treated as
  "strictly necessary", but whether autosave counts needs checking
  (unsourced).
- **Cost.** None.
- **Maintenance.** Low, but a Shiny app needs a small piece of JavaScript
  or a package to reach browser storage (shinyStorePlus and similar
  exist; not checked).
- **With each hosting option.** Works with every hosted option and with
  webR. On a desktop bundle it depends on the embedded browser keeping
  its storage. For "run it yourself" the browser storage is tied to the
  address and port, so it is kept only if the port stays the same.

### (c) Share links that carry the inputs in the address

*Built on 13 November 2026 in the fragment (above), which avoids the
log exposure and length limit described here for Shiny's query-string
bookmarking.*

The app's address encodes the inputs, so copying the link shares the
design. Shiny supports this with `enableBookmarking(store = "url")`; its
help page notes "Some browsers have a length limit for URLs of about 2000
characters" (opened 18 October 2026).

- **For users.** One link to send a colleague, or to put in a paper's
  supplementary material, that reopens the same inputs. Results are
  recalculated on opening (the link holds inputs, not results). Long
  designs make long links (see the length limit above).
- **Privacy and UK GDPR.** The inputs travel in the link, so they appear
  in browser history, in the host's request logs and anywhere the link is
  pasted. Nothing is stored by the app itself.
- **Cost.** None.
- **Maintenance.** Low to medium: Shiny's bookmarking is built in, but the
  app's state (routes, forms) must be restorable, and links must keep
  working across versions.
- **With each hosting option.** Needs a fixed public address, so it suits
  shinyapps.io, Connect, a university server, a container service and
  webR/Shinylive. It means little for "run it yourself" or a desktop app
  (the link points to the user's own computer).

### (d) Private result links for background jobs

For long simulations: the app hands the job to a worker, gives the user a
private link, and the user returns to collect the result.

- **For users.** No need to keep the page open for 15 minutes; results
  can be collected later or on another device.
- **Privacy and UK GDPR.** The host stores the inputs and results for a
  while, so it needs a retention period, a way to delete them, and a
  privacy notice. Anyone with the link can see the result unless links
  are also protected.
- **Cost.** A worker process and a store (a database or files), running
  whenever jobs exist; more than hosting the app alone.
- **Maintenance.** Medium to high: a job queue, a worker, clean-up of old
  results, monitoring.
- **With each hosting option.** Needs a server: a container service,
  Connect or a university server can run workers; shinyapps.io is less
  suited (no separate worker processes, as far as found). Not possible in
  webR (no server), and not needed on a desktop app or "run it yourself"
  (the user's own computer runs the job).

### (e) User accounts with stored projects (for example Supabase)

Users sign in, and their projects are kept on the server.

- **For users.** Projects on any computer, a list of past analyses, and
  sharing with named collaborators. A sign-in step before using the app,
  unless sign-in is only needed to save.
- **Privacy and UK GDPR.** Personal data (at least email addresses) and
  the users' projects are stored, so the host is a controller: a privacy
  notice, a lawful basis, retention and deletion, subject access requests,
  security, and a transfer assessment if the data is held outside the UK.
- **Cost.** Supabase's free tier pauses after a week of inactivity; paid
  plans from $25 a month (search result; see `hosting-options.md`), plus
  the app's hosting.
- **Maintenance.** High: accounts, password resets or sign-in links,
  security updates, backups, and the GDPR duties above.
- **With each hosting option.** Works with any hosted option (the app
  talks to the database over the internet). Possible from webR in
  principle, since the browser can call Supabase directly, though not
  tested. Not useful for "run it yourself" or a desktop app unless they
  also sign in.

## Side by side

| | For users | Stored where | GDPR weight | Cost | Upkeep |
| --- | --- | --- | --- | --- | --- |
| (a) Project file | keep, send, reopen | user's computer | lowest | none | low to medium |
| (b) Browser autosave | nothing lost by accident | user's browser | low (PECR to check) | none | low |
| (c) Share links | one link to share inputs | in the link | low to medium (logs) | none | low to medium |
| (d) Private result links | collect long results later | host | medium | worker and store | medium to high |
| (e) Accounts | projects anywhere | host | highest | database plan | high |

| | Run it yourself | shinyapps.io | Connect | University server | Container | webR | Desktop |
| --- | --- | --- | --- | --- | --- | --- | --- |
| (a) | yes | yes | yes | yes | yes | yes | yes |
| (b) | partly | yes | yes | yes | yes | yes | partly |
| (c) | little use | yes | yes | yes | yes | yes | little use |
| (d) | not needed | less suited | yes | yes | yes | no | not needed |
| (e) | little use | yes | yes | yes | yes | untested | little use |

These options can be combined; (a) is a prerequisite for none of the
others, but its file format could be the format the others store.

## Study plans (design, 13 November 2026)

This replaces the single study plan described in earlier versions of this
page. It is the design three pull requests build; once each lands, this
section says what exists.

### What exists now

Part 1 (named plans, their page, and reopening) is built:

- `R/study-plans.R` holds the plans (`state$plans`, by id) and their
  rules; `R/study-plan.R` draws a plan's page (`plan_page_ui()`) and the
  bar under a result (`study_plan_bar_ui()`).
- The engine's plan file carries `id`, `name`, `description` and, per
  analysis, `plan_role` and `plan_note` (`write_study_plan()`,
  `read_study_plan()`), at format version 1.
- The browser keeps `powerkit-study-plan:<id>` per plan (the plan file's
  text with when it changed and was saved; a plan with no analyses keeps
  its name and description without a file) and the index
  `powerkit-study-plans` (`R/connection.R`). A copy over the 3 MB budget
  or refused by the browser is not written, and the plan's page says to
  save it.
- The Study plans page is the tab "Study plans", hidden from the tab row.

Parts 2 (the overview and Download everything) and 3 (Plan my whole study
joins a plan) are still to build, as described below.

### Why

A study plan is where a researcher keeps the analyses one study rests on.
Until now it was one unnamed list, shown as a screen inside "Plan a power
analysis", so it read as part of the start page. An analysis opened from a
saved plan could not be opened again, the plan could not be downloaded
with its documents, a researcher with several studies (a thesis, a
programme of grants) had to keep one plan at a time, and "Plan my whole
study" kept its own plan in a separate file. Queue item 21 (the
replication plan) is to be built "as the study plan works", so the
study plan's shape is also the replication plan's starting point.

### Goals

- Several named study plans, each with a description, kept in the
  browser and saved as a file or a link that opens in any browser.
- A page of its own for the plans, reached from "Study plans" in the top
  bar on every screen, with its own address (`?page=plans`).
- A page for each plan: its name, description, overview and analyses.
  Every analysis opens again on its card with its answers and saved
  result.
- "Download everything" for a plan: one zip with the plan file, a
  study-wide planning document, the references and each analysis's own
  files.
- "Plan my whole study" starts a study plan and is kept inside it.

### Non-goals

- Accounts or any storage on powerkit's side (option (e) above stays
  rejected: powerkit stores nothing).
- Syncing plans between browsers. The file and the link carry a plan
  from one browser to another; the user moves it.
- New statistics. The plan reports what each card calculated, the
  largest comparable sample size and joint power where the engine
  already offers it (`joint_power()`, PUMP). Nothing in the plan
  computes power: the engine's functions do (non-negotiable: the app
  never computes power).
- Unfinished drafts as plan entries. A plan holds calculated analyses;
  a draft stays a draft file.
- The replication plan (queue item 21). It is built on this later.

### Anti-goals (a failure even if it works)

- A plan, or an analysis in it, is lost without the user asking:
  migration, opening a file, a full browser store or a removed plan.
- A plan opened from a file silently overwrites one in the browser.
- A saved result is shown as current when its answers have changed, or
  an old result is presented as recalculated.
- A plan file saved by this version refuses to open in the version
  before it, or a file saved before it refuses to open in this one.
- The plans page reads as a dashboard that computes something new: the
  overview only restates the cards' results.

### Approaches considered

1. **Plans kept in the browser, each saved as its own file and link
   (chosen).** Matches how projects, drafts and the single plan already
   work, keeps "powerkit stores nothing", and lets one study be sent to a
   supervisor on its own.
2. **Accounts with plans stored by powerkit.** Plans on every device
   without carrying files, but logins, holding researchers' studies, a
   database cost and data-protection duties (see option (e)). Rejected.
3. **One file holding every plan.** Simplest to save, but a single study
   can't be shared alone, and one broken plan breaks them all. Rejected.

### What the user sees

**Top bar.** "Study plans" is always shown (today the chip appears only
once a plan has an analysis), with the number of plans when there are
any: "Study plans (2)". It opens the plans page from any screen; the
screen they were on stays in the back-button history.

**The plans page** (`?page=plans`), a page of its own in the layout of
About and Updates, not a screen of the plan tab:

```
 Study plans                       [+ New study plan] [Open a saved plan]
 Kept in this browser only. Save each plan to your computer to keep it.

 Thesis study 2: attention training
   3 analyses · largest N = 128 · Not saved to a file since changes
 Pilot: replication of X
   1 analysis · Saved to a file 12 Nov 2026
 Remove every plan from this browser
```

- A plan opens by its name. With no plans: one paragraph on what a plan
  is and the two ways to start one (a new plan, or "Plan my whole
  study"), and "Open a saved plan".
- "Open a saved plan" uses the same reader as "Open a saved or shared
  project" (`open_saved_file()`), so the same file, zip or link works
  in both places.
- "Remove every plan from this browser" (for shared computers) asks
  first and names any plan not saved to a file.

**A plan's page:**

```
 < All study plans
 Thesis study 2: attention training            [Rename]
 Description: Does a 4-week attention training improve ... (edit)

 Overview
   Largest comparable requirement: N = 128 (Primary: training vs control)
   3 analyses: 1 primary, 1 secondary, 1 manipulation check
   Joint power: [the existing PUMP panel, where offered]
   Whole-study simulation: 74% that every primary analysis succeeds
     (from "Plan my whole study", 13 Nov) [Open the guided plan]

 Analyses
   1. Training vs control (two-group t-test)       N = 128   Primary
      Note: ...                         [Open] [Role ▾] [Note] [Remove]
   2. ...

 [Add an analysis] [Save plan] [Copy a link] [Download everything (.zip)]
 Not saved to a file since your last change.
 Delete this plan
```

- **Name.** A new plan is named "Study plan, 13 Nov 2026" until
  renamed; names are up to 120 characters, plain text, escaped
  wherever shown. Two plans may share a name: each has its own id.
- **Description.** Free text, optional, up to 2,000 characters, shown
  on the plan page and at the top of the study-wide document.
- **Roles.** Each analysis is Primary, Secondary or Check (manipulation
  or quality check); the default is Primary for the first analysis and
  Secondary for the rest, or the role "Plan my whole study" gave it.
  Roles only label and group; the largest comparable N is over every
  analysis, as now.
- **Notes.** Free text per analysis, up to 1,000 characters.
- **Open** opens the analysis on its card's input screen with its saved
  answers and its saved result, as a project file opens today
  (`restore_from_project()`, `open_in_app()`), marked "From your plan
  Thesis study 2". If the answers are changed and calculated again,
  "Keep this result" offers **Update it in the plan** (replace this
  analysis, keeping its role and note) and **Add it as a new analysis**;
  until one is pressed the plan keeps the old result. An analysis saved
  by an older powerkit opens with its saved result and the version that
  made it, never recalculated silently.
- **Save status.** "Saved to a file" or "Copied as a link" with the
  time, or "Not saved to a file since your last change". Any change
  (rename, role, note, add, update, remove) marks it unsaved.
- **Delete this plan** asks first, and says when it has not been saved
  to a file.

**Adding from a result.** "Add to my study plan" (in "Keep this result")
adds to the current plan: the plan last opened, or the only plan. With no
plan it makes one ("Study plan, <date>") and says so, with a Rename link.
With two or more plans, a small choice beside the button names the
current plan and lists the others and "A new plan". Adding the same
result to the same plan twice is refused with "Already in this plan"
(the result's spec hash, as now).

**Plan my whole study.** Starting the guided route makes a new plan,
named "Whole-study plan, <date>", and makes it current, unless the user
started from a plan's "Add an analysis", in which case it fills that plan.
The guided plan's own record (the answers, analyses ticked, claim,
values, results and whole-study simulation inputs, as "Save this plan"
writes today) is kept inside the study plan. Each analysis calculated
from the guided plan joins that plan as now (`plan_upsert()`), with the
role the guided plan gave it (primary or not). The plan page shows the
last whole-study simulation's result, its date and "Open the guided
plan", which restores the guided screens from the record. "Save this
plan" on the guided screens saves the whole study plan. A guided-plan file
saved before this change still opens: as a new study plan holding that
guided plan.

**Download everything (.zip)** for a plan:

```
powerkit-<plan-name>-everything.zip
  README.txt                       what each file is
  <plan-name>.powerkit.json        opens the whole plan again
  study-plan.md, study-plan.docx   the study-wide planning document
  references.txt                   every analysis's references, merged
  analyses/01-<card-name>/         each analysis's "Download everything":
     project file, planning document, R script, citations,
     simulated data (where there is one)
  whole-study/                     where the plan has a guided plan with
     a simulation result: its planning document and R script
```

- The plan file is written first and checked for in the finished zip,
  as for a single result (`write_bundle()`); each analysis's files reuse
  `write_bundle()` on its saved spec, result and route, so nothing is
  recalculated. A document that can't be made is skipped and the README
  says so.
- The **study-wide planning document** has the plan's name and
  description; a table of analyses (name, role, N needed, unit,
  target power or precision, backend); the largest comparable N and
  what it does and doesn't establish (the plan page's wording); joint
  power or the whole-study simulation where there is one, marked
  experimental as on its own document; each analysis's methods
  paragraph as its card writes it; and the references, de-duplicated,
  taken only from each result's citations (non-negotiable: citations
  come from refs.bib or a package's citation()).
- **Open a saved plan** and **Open a saved or shared project** accept
  this zip and open the plan file in it (today's zip reader looks for a
  project file; it learns to prefer the plan file).

### Encouraging a saved file

The browser's copy is a safety net, not the place a plan is kept: Safari
deletes a site's stored data after 7 days without a visit, a private
window loses it when closed, and cleaning tools, another browser or
another computer don't have it. So the app keeps asking for a file
without getting in the way:

- **Save status everywhere it matters.** Each plan on the plans page and
  its own page says "Saved to a file <time>" or "Only in this browser:
  save it to your computer" (a warning style, not an error). The top-bar
  button carries a small marker, with a text alternative, when any plan
  has changes not saved to a file.
- **At the moments work is added.** Adding an analysis, updating one,
  or a whole-study simulation finishing says "Added to <plan>. It is
  only in this browser until you save it" with **Save plan** beside it.
- **On the plans page**, one short line under the heading says why: the
  browser's copy can be cleared without warning; a saved file or a link
  keeps the plan.
- **Durable storage where the browser offers it.** The app asks the
  browser to keep its storage (`navigator.storage.persist()`), which
  stops eviction under storage pressure in browsers that grant it; it
  is not relied on.
- **Saving in one press.** Save plan is a primary button on the plan
  page whenever the plan has unsaved changes, and "Download everything"
  holds the plan file, so either counts as saved. "Copy a link" counts
  as saved too, with its own wording ("Copied as a link <time>").

### Storage, files and links

- **In the browser.** Each plan is stored under its own key
  (`powerkit-study-plan:<id>`, the plan file's text) with an index
  (`powerkit-study-plans`: ids, names, times, which is current), so a
  failed write loses at most that plan's latest change. Plans share a
  budget of 3 MB (one calculated analysis is about 28 KB; the last
  result and the draft keep their own 1.5 MB and small allowances). A
  plan that can't be stored is kept for the session and the plan page
  says "This plan is too large to keep in this browser: save it to your
  computer" instead of failing quietly.
- **Migration.** On first load, a plan under the old key
  `powerkit-study-plan` becomes a plan named "My study plan" and is the
  current plan; the old key is removed only after the new one is
  written.
- **The file** keeps format `powerkit-study-plan` and format_version 1,
  adding optional fields: `id`, `name`, `description`, `saved`
  (already there), `guided` (the guided-plan record) and, for each
  analysis, `role` and `note`. Older powerkit ignores fields it doesn't
  know, so files saved now still open there (without the new parts);
  the engine's `write_study_plan()` and `read_study_plan()` gain the
  fields. If `read_project()` turns out not to ignore extra keys inside
  an analysis, role and note go in a plan-level list instead, so the
  older version still opens the file (tested either way).
- **Opening a plan** (file, zip or link) always adds it to the browser's
  plans and opens its page. If a plan with the same id is already there
  and differs, the opened one is kept as well, named "<name> (opened
  13 Nov 2026)", and a message says both are kept; identical content
  just opens the existing plan. Nothing is overwritten.
- **Links.** "Copy a link" on a plan page carries that plan, as today;
  plans over the 60,000-character limit say to save the file.
- **The address.** `?page=plans` opens the plans page; a plan itself is
  not in the address (it lives in one browser), so a link to a plan is
  always "Copy a link".

### Where the code goes

- `app/routing/R/study-plan.R` keeps the plan's entries and pages, and
  grows into `R/study-plans.R` for the list, storage index and current
  plan, so `app.R`'s server only wires inputs to these functions (the
  growth rule in CLAUDE.md: move this screen's code out of `app.R`
  while touching it).
- The browser storage script moves from `R/connection.R`'s single key
  to the index and per-plan keys.
- Engine: `write_study_plan()`, `read_study_plan()` (new fields), with
  roxygen and tests; no statistical change.

### Delivery: three pull requests

1. **Named plans, their page, and reopening.** The plans page and
   address, the top bar, several named plans with descriptions, roles
   and notes, the current plan and the choice when adding, opening an
   analysis again with Update or Add as new, storage, migration and the
   file's new fields.
2. **The overview and Download everything.** The overview block, the
   study-wide planning document and the plan zip, and the zip reader.
3. **Plan my whole study joins a plan.** Starting the guided route makes
   or fills a plan, the guided record inside the plan file, roles from
   the guided plan, the simulation result on the plan page, and old
   guided-plan files opening as plans.

Each lands with its tests (app unit tests and the planning browser
test), its Updates entry and its version (patch for 2 and 3, minor for
the first), and updates this section.

### Calls made in writing this up

- **Not a sixth tab.** The plans page is a tab hidden from the tab row
  (phones fit five tabs on one row), reached by the top-bar button and
  `?page=plans`, and it has a place in the back-button history like any
  other screen.
- **No empty plans from wandering.** "+ New study plan" makes a plan at
  once (the user asked for it). "Plan my whole study" makes its plan
  only when the guided route first reaches its list of analyses, so
  starting it and turning back leaves nothing behind.
- **Update it in the plan** is offered only on the card the analysis was
  opened on; moving to another card turns the result into an ordinary
  one, which "Add to my study plan" adds as a new analysis.
- **No leaving warning for plans**, which would fire on every reload;
  the nudges below do that job instead. The existing warning for an
  unkept result stays.
- **Roles change no number.** Primary, Secondary and Check label and
  group analyses and order the document; the overview's largest N is
  over every analysis, as now, and joint power is offered on the same
  terms as now.

### Left to the builder

- Exact wording on the pages, within the plain-English rules.
- The layout of the choice when adding with several plans (a select or
  a menu), keeping it keyboard- and screen-reader-usable
  (`walkthroughs/accessibility.js`).
- How the plans page reuses the About and Updates tab layout.
