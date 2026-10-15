# Prototype demo captures

Captured on 2026-10-13 from the prototype app (`app/`) running the bundled
2x2 between example (Superpower vignette crossover: means 1, 0, 0, 1;
SD 2; alpha .05; target power .90), driven by Playwright in headless
Chromium. Prototype: not for use in real studies.

| File | What it shows |
| --- | --- |
| `01-design.png` | Screen 1, design form after "Load example" |
| `02-confirm.png` | Screen 2, interaction plot and the design in plain words |
| `03-results.png` | Screen 3, required total N = 172, power curve, methods paragraph, run record |
| `04-r-script.png` | The downloaded R script, rendered as a page |
| `powerkit-reproduce-example.R` | That script itself (reproduces N = 172 with Superpower alone) |
| `05-how-we-check-this.png` | "How we check this" after re-running the six published benchmarks (all match) |
| `06-error-power-80.png` | Error case: target power entered as 80 (full page) |
| `06b-error-power-80-closeup.png` | The same error, close up |
| `demo-flow.webm` | 30-second recording: load example, confirm, run, results, download script (the red dot is the pointer) |

Each run draws its own seed, so the seed in the recording differs from the
one in the screenshots and script; with the exact method the results are
the same.
