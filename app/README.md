# app/ — Shiny front end

The app builds design specs and calls the engine; it never computes power
itself (see CLAUDE.md and docs/build-guide.md section 7).

- `routing/`: **the app.** The design finder, an input screen for each
  design powerkit runs, the result screen and its exports. See
  [`routing/README.md`](routing/README.md) and
  [`docs/routing-prototype.md`](../docs/routing-prototype.md).
- `forms/`, `builder/`, `confirm/`, `results/`: empty folders kept from the
  layout in docs/build-guide.md section 3 (design forms, full-model builder,
  confirmation screen, results). The input screens and results so far live
  in `routing/`; the full-model builder and the confirmation screen are
  not built yet.
