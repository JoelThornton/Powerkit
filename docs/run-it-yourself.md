# Run the powerkit prototype on your own computer

*For psychologists trying the prototype. No experience with R, RStudio or
Git is needed. Download and update guidance reviewed: 10 November 2026; installation timing remains an estimate.*

powerkit is a prototype: it helps you find the right power analysis for
your study and, for some designs, calculates it with established R
packages. Its results are not yet fully validated, so please don't use
them for a real study yet. What it does and doesn't do is on its
**About** tab.

You will:

1. install R (free);
2. optionally install RStudio (free; it makes R friendlier);
3. download powerkit;
4. run one line, which installs what powerkit needs and opens it in your
   web browser.

Allow tens of minutes the first time; the time depends on your connection
and whether any packages need compiling. Later starts reuse installed
packages. Everything runs
on your computer. Sending feedback is optional and sends the information
described on the Feedback tab.

These steps are checked automatically on clean Windows and macOS machines
(`.github/workflows/run-it-yourself.yaml`), so if they stop working we
find out.

## 1. Install R

powerkit records the version of R it was tested with: **R 4.5.3**.
Install that version, even if a newer one exists, because the packages
powerkit uses are recorded for it.

**Windows**

1. Download the installer:
   <https://cran.r-project.org/bin/windows/base/old/4.5.3/R-4.5.3-win.exe>
2. Open the downloaded file and click **Next** through the installer,
   keeping every default. If Windows asks "Do you want to allow this app
   to make changes?", click **Yes**.

**macOS**

1. Find out which kind of Mac you have: Apple menu → **About This Mac**.
   If it says *Chip: Apple M1* (or M2, M3, M4 and so on), you have Apple
   silicon. If it says *Processor: … Intel*, you have an Intel Mac.
2. Download the matching installer:
   - Apple silicon:
     <https://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-4.5.3-arm64.pkg>
   - Intel:
     <https://cran.r-project.org/bin/macosx/big-sur-x86_64/base/R-4.5.3-x86_64.pkg>
3. Open the downloaded file and click **Continue** through the installer,
   keeping every default. Enter your Mac password when asked.

You already have a different version of R? You can keep it. Installing
4.5.3 alongside is safest; see "R version" under Troubleshooting.

## 2. Install RStudio (optional)

RStudio is a friendlier window for R. You don't need it, but if you'd
like it, download **RStudio Desktop** (free) from
<https://posit.co/download/rstudio-desktop/> and install it with the
defaults. Install R first.

## 3. Download powerkit

1. Go to <https://github.com/JoelThornton/Powerkit/releases>.
2. Choose a numbered version and download **Source code (zip)**.
   Pre-releases are development prototypes, not scientific approvals.
   Keep the version number. The main-branch ZIP is a development snapshot;
   use it only if you deliberately want unreleased work.
3. Unzip it (a numbered download uses its version in the folder name;
   `Powerkit-main` below is an example folder name):
   - **Windows:** right-click the downloaded `Powerkit-main.zip` →
     **Extract All…** → choose a short location such as
     `C:\powerkit` → **Extract**. Don't run powerkit from inside the zip
     file: Windows lets you look inside a zip without extracting it, but
     powerkit can't run from there.
   - **macOS:** double-click `Powerkit-main.zip` in Downloads. A folder
     called `Powerkit-main` appears. You can move it anywhere, for
     example to Documents.

## 4. Start powerkit

**With RStudio:** open the `Powerkit-main` folder and double-click
`Powerkit.Rproj`. RStudio opens. In the **Console** (the pane with a `>`
prompt), type this and press Enter:

```r
source("run_powerkit.R")
```

**Without RStudio:** open **R** (Windows: from the Start menu, "R 4.5.3";
macOS: from Applications, "R"). In the window with the `>` prompt, type
this and press Enter:

```r
source(file.choose())
```

A file chooser opens. Go to the `Powerkit-main` folder and choose
`run_powerkit.R`.

**Then wait.** The first time, R installs the packages powerkit needs into
a library for this Powerkit folder. renv also uses a shared package cache
so other downloads can reuse installed versions; other projects' libraries
are left alone. You'll see a lot of text scroll past; that's normal. Messages
starting `powerkit:` tell you what it's doing. When it's ready, powerkit
opens in your web browser.

**To stop powerkit:** press **Esc** in the R console (in RStudio, you can
also click the red **Stop** sign at the top of the Console). Closing the
browser tab alone doesn't stop it.

**Next time:** repeat step 4. Installed packages are reused.

**Getting a newer version:** save your draft/project outside the app folder,
stop the app, then run `source(file.choose())` and choose
`check_powerkit_updates.R` from this download. This optional check contacts
GitHub's public release list; it sends no study answers and installs
nothing. Older downloads without that file can use the releases page
directly. Download a chosen numbered ZIP into a **separate folder**,
restart R, and launch that folder's app. Keep the older folder for
reproduction. Reopen a copy of your project and check its version and
assumptions before rerunning: method corrections can change an answer.
An update check failing does not stop offline calculations. The launcher
does not automatically download or replace Powerkit itself.

## Reporting a problem

Every result card in powerkit has a **Something doesn't fit?** link. Open
it, click **Copy the path**, paste it into an email, add a sentence on
what you expected, and send it to whoever asked you to try powerkit.
The Feedback tab previews what will be sent and sends it only when you
click Send. An optional update check contacts GitHub; ordinary local
calculations use your own computer.

If powerkit won't start, copy the last 20 or so lines of text in the R
console and send those instead.

## Troubleshooting

**"cannot open file 'run_powerkit.R': No such file or directory"**
R isn't looking in the powerkit folder. In RStudio, make sure you opened
`Powerkit.Rproj` (the folder name appears at the top right of RStudio).
Otherwise use `source(file.choose())` and pick the file. On Windows,
check you extracted the zip (step 3) rather than opening it.

**"this doesn't look like the powerkit folder"**
You chose a `run_powerkit.R` that isn't inside the unzipped
`Powerkit-main` folder, or the zip wasn't fully extracted. Extract it
again and choose the file inside the new folder.

**"powerkit needs R 4.4 or later" / "powerkit records R 4.5.3 and you have …"**
Install R 4.5.3 (step 1). In RStudio, choose it under *Tools → Global
Options → General → R version* (Windows) and restart RStudio; on macOS,
installing 4.5.3 makes it the version R and RStudio use. Then start
again.

**Downloads fail ("Recv failure: Connection was reset", "cannot open URL", "failed to download", "timeout")**
The local launcher uses `cloud.r-project.org` for recorded CRAN package
versions. Interrupted files are retried before a source-code fallback. If needed,
setup tries R's built-in downloader, then the
server recorded in the download's lockfile. Setting up renv itself also
has connection recovery. Attempts are bounded; compiler errors stop rather
than endlessly retrying. Downloaded archives and installed packages are
reused where available. The lockfile and recorded versions are unchanged,
and HTTPS certificate checks stay enabled.

For an **older download** without automatic recovery, restart R, then run:

```r
Sys.setenv(
  RENV_DOWNLOAD_METHOD = "libcurl",
  RENV_CONFIG_REPOS_OVERRIDE = "https://cloud.r-project.org"
)
options(timeout = 300, renv.config.ppm.enabled = FALSE)
source(file.choose())  # choose run_powerkit.R
```

These settings last for that R session. Do not disable certificate checking
or delete the lockfile to work around a failed download. University and
hospital networks may need IT to allow CRAN and Posit's package servers;
a mirror cannot fix every proxy or firewall. If all attempts fail, copy
the final error and package name. Restart R before trying again.

**"installing packages failed" mentioning a compiler, `make`, `gcc`,
`Rtools` or `xcrun`**
A package had to be built from source code, which needs extra tools.
First check the R version and the preceding download messages: a failed
binary download can cause a source fallback even on the right R version.
Try the connection recovery above first. Some recorded versions may still
need compilation when a compatible binary is unavailable:
- **Windows:** install **Rtools45** from
  <https://cran.r-project.org/bin/windows/Rtools/rtools45/rtools.html>,
  keeping the defaults, then start again.
- **macOS:** follow CRAN's instructions for the tools at
  <https://cran.r-project.org/bin/macosx/tools/>, then start again.

**Windows: errors about long file paths, or OneDrive**
Move the `Powerkit-main` folder somewhere short and not synced by
OneDrive, such as `C:\powerkit\Powerkit-main`, and start again.

**The browser doesn't open**
Look in the R console for a line like
`Listening on http://127.0.0.1:1234` and paste that address into your
browser.

**It's been running for a long time with no new text**
The first install can sit on one package for several minutes. If there
has been no new text for 15 minutes, press Esc and run step 4 again.

**macOS: "R.app is damaged" or "can't be opened"**
You may have the installer for the other kind of Mac (step 1). Download
the matching one and install it.

**Anything else**
Copy the last 20 or so lines of the R console and send them to whoever
asked you to try powerkit.

## What the one line does

`run_powerkit.R`:

1. checks it's in the powerkit folder and that R is 4.4 or later
   (powerkit records 4.5.3);
2. starts renv, which keeps powerkit's packages in their own library
   inside the folder, and installs the versions recorded in `renv.lock`
   if any are missing (`renv::restore()`);
3. installs powerkit's engine (the `engine/` folder) into that library
   if it's missing or has changed;
4. opens the app (`app/routing/`) in your browser.

It installs nothing outside the powerkit folder, apart from renv's
shared cache of downloaded packages in your user folder.

## Engine versus complete app

The planned CRAN package is the calculation engine; installing it alone
does not install this interface. The full repository download includes
the interface and recorded dependencies. A standalone desktop installer
and a browser-only computation version have not been built. The local
launcher still restores the full locked environment, including packages
not needed by every analysis. Setup needs internet; offline installation
and identical results with arbitrary newer backends are not promised.

## Recorded installation checks

On 10 November 2026, a Windows R 4.5.3 probe reproduced an SSL connection
error on a Posit binary redirect. Both affected package versions were
available from the public CRAN mirror. An isolated renv 1.0.3 restore then
recovered actual TLS failures and installed binary GPArotation 2026.8-2,
plyr 1.8.9 and Rcpp 1.1.2 with source compilation disabled; the lockfile
hash was unchanged. This is a three-package recovery check, not a clean
installation benchmark for the entire app. Full Windows/macOS launch and
repeat-start checks remain the pull request gate. Per-file retries retain
renv 1.0.3's normal archive checks through its existing download override
([pinned source](https://github.com/rstudio/renv/blob/v1.0.3/R/download.R)).
Recheck this hook when upgrading renv.
