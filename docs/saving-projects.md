# Saving projects: options

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
user goes, and offers to restore them next time.

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
