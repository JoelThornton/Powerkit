# Isolated regression server. Never starts a browser or targets production.
Sys.setenv(RENV_ACTIVATE_PROJECT = "FALSE")
shiny::runApp("app/routing", host = "127.0.0.1", port = 8765,
  launch.browser = FALSE)
