* The local launcher (`run_powerkit.R`, `scripts/local-setup.R`) no longer
  needs compilers on Windows or macOS. CRAN keeps binaries of only each
  package's newest version, so recorded versions with a newer CRAN release
  (Hmisc 5.3-0 among twelve compiled packages, since 15 November 2026) fell
  back to source and needed Xcode, gfortran or Rtools. For each such
  package the launcher reads CRAN's release dates, picks as few weekdays as
  cover every recorded version while it was CRAN's newest, and adds Posit
  Package Manager's dated CRAN snapshots for those days as extra
  repositories. renv 1.0.3 still installs exactly the versions in
  `renv.lock`, preferring CRAN where CRAN has them; Linux is unchanged, and
  if CRAN can't be read the launcher carries on as before.
* The `run-it-yourself` check switches every compiler off
  (`R_MAKEVARS_USER`) on its clean Windows and macOS machines, so a
  package that would need compiling fails the check as it would fail a
  tester, and it lists any package installed from source.
