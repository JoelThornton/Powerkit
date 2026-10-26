# Run the powerkit prototype on your own computer

*For psychologists trying the prototype. No experience with R, RStudio or
Git is needed. Last checked: 18 October 2026.*

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

The first time takes about 20 to 40 minutes, most of it waiting while
packages download. After that it opens in under a minute. Everything runs
on your computer; nothing you type is sent anywhere.

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

1. Go to <https://github.com/JoelThornton/Powerkit>.
2. Click the green **Code** button, then **Download ZIP**. (You don't need
   a GitHub account.)
3. Unzip it:
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
a folder inside `Powerkit-main` (it doesn't change anything else on your
computer). You'll see a lot of text scroll past; that's normal. Messages
starting `powerkit:` tell you what it's doing. When it's ready, powerkit
opens in your web browser.

**To stop powerkit:** press **Esc** in the R console (in RStudio, you can
also click the red **Stop** sign at the top of the Console). Closing the
browser tab alone doesn't stop it.

**Next time:** repeat step 4. It opens in under a minute.

**Getting a newer version:** download the ZIP again (step 3) and use the
new folder. The first start installs anything that changed.

## Reporting a problem

Every result card in powerkit has a **Something doesn't fit?** link. Open
it, click **Copy the path**, paste it into an email, add a sentence on
what you expected, and send it to whoever asked you to try powerkit.
Nothing is sent from the app itself.

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

**Downloads fail ("cannot open URL", "failed to download", "timeout")**
powerkit downloads packages from the internet the first time. University
and hospital networks sometimes block this. Try again on a home network
or a phone hotspot, or ask IT whether R can reach
`packagemanager.posit.co` and `cran.r-project.org`. Running
`run_powerkit.R` again carries on where it stopped.

**"installing packages failed" mentioning a compiler, `make`, `gcc`,
`Rtools` or `xcrun`**
A package had to be built from source code, which needs extra tools.
This usually means R isn't version 4.5.3; installing 4.5.3 (step 1)
normally fixes it. If it doesn't:
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
