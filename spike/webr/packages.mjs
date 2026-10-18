// The packages checked in webR: powerkit's foundation packages, what they
// need underneath, and what the app and engine use.
export const packages = [
  // backends and what they run on
  "pwr", "pwrss", "Spower", "SimDesign", "Superpower", "afex", "emmeans", "MASS",
  "InteractionPoweR", "power4mome", "lavaan", "manymome",
  // engine
  "digest", "jsonlite", "jsonvalidate", "V8",
  // app
  "shiny", "bslib", "yaml", "callr", "processx",
  // validation-only
  "simsem", "testthat"
];
export const repos = {
  "repo.r-wasm.org": "https://repo.r-wasm.org/",
  "r-universe (cran)": "https://cran.r-universe.dev/"
};
