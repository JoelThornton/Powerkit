* Long runs can carry on in a study plan. A run on an input screen that
  has gone on for ten seconds offers "Keep it running in my study plan":
  the run moves to the current plan (or a new one), the person can use
  the rest of the app, the plan's page shows it with an estimated
  progress bar and a Stop button, and the result is added to the plan
  when it finishes (`kept_run_moved_ui()`, `plan_running_ui()`, the
  `kept` runs in app.R's server). Runs still end with the browser tab,
  and the screens say so; the connection is kept open while one reports
  progress (`kept_progress`, R/connection.R).
* `simulated_version_times` (forms.yaml) gives the one-way repeated-measures, mixed and
  two-factor within cards their measured times, so the simulated
  corrected F test (Departure 28) shows its usual wait and a progress bar.
