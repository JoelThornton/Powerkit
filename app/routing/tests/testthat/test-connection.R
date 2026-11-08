# Keeping the visitor's place and showing that the app is working
# (R/connection.R, 5 November 2026).

test_that("the page arrives with the starting screen and the busy bar, and leaves the host's own lost-connection message alone", {
  html <- as.character(connection_ui())
  expect_match(html, "Starting powerkit", fixed = TRUE)
  expect_match(html, 'id="pk-busy"', fixed = TRUE)
  expect_no_match(html, "pk-lost", fixed = TRUE)
  expect_no_match(connection_css, "shiny-disconnected-overlay", fixed = TRUE)
  expect_match(connection_js, "pk_heartbeat", fixed = TRUE)
  expect_match(connection_js, "visibilitychange", fixed = TRUE)
  app <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(app, "session$allowReconnect(TRUE)", fixed = TRUE)
  expect_match(app, "connection_ui()", fixed = TRUE)
})

test_that("answers saved in the browser come back as a draft the app can reopen", {
  state <- list(route = "choose", endpoint = "E2", came_from = "node", ctx = list(outcome = "score"),
    history = list(), form_k = 2L)
  ids <- vapply(form_fields(form_groups(forms, "E2")), `[[`, "", "id")
  route <- project_route(state, form_examples$E2[intersect(names(form_examples$E2), ids)])
  record <- autosave_record(route)
  text <- as.character(jsonlite::toJSON(record, auto_unbox = TRUE, null = "null"))
  back <- autosave_from_browser(text)
  expect_identical(back$format, "powerkit-draft")
  restored <- restore_draft(back, tree, forms)
  expect_false(is.character(restored))
  expect_identical(restored$endpoint, "E2")
  # Anything else is ignored rather than trusted.
  expect_null(autosave_from_browser("not json"))
  expect_null(autosave_from_browser(as.character(jsonlite::toJSON(list(format = "something else"), auto_unbox = TRUE))))
})

test_that("the About page is fetched in the background once the first screen is up", {
  app <- paste(readLines(test_path("..", "..", "app.R")), collapse = "\n")
  # Kept as finished HTML and written to a file the browser can fetch.
  expect_match(app, 'addResourcePath("about-cache"', fixed = TRUE)
  expect_match(app, "as.character(about_ui(tree, forms))", fixed = TRUE)
  expect_match(app, 'div(id = "about_static")', fixed = TRUE)
  # Built in a separate process started with the app, so building it never
  # holds up anyone's screen; the page waits for it rather than building it
  # again.
  expect_match(app, "callr::r_bg(about_build_worker,", fixed = TRUE)
  expect_match(app, "req(html, cancelOutput = TRUE)", fixed = TRUE)
  expect_false(grepl("about_build_soon", app, fixed = TRUE))
  # The server doesn't send it again once the browser has it.
  expect_match(app, "!isTRUE(isolate(input$about_prefetched))", fixed = TRUE)
  expect_match(connection_js, "about-cache/about.html", fixed = TRUE)
  expect_match(connection_js, "Shiny.setInputValue('about_prefetched', true)", fixed = TRUE)
})

test_that("the keep-open message stops when the page is left alone, unless a calculation runs", {
  # A message sent for ever would keep the app (paid for by the hour)
  # running for as long as a forgotten tab stayed open (6 November 2026).
  expect_match(connection_js, "connected && keepOpen()", fixed = TRUE)
  expect_match(connection_js, "IDLE_MS = 20 * 60 * 1000", fixed = TRUE)
  expect_match(connection_js, "document.visibilityState === 'visible' && now - lastActive < IDLE_MS", fixed = TRUE)
  expect_match(connection_js, "e.message.custom.calc_progress", fixed = TRUE)
  expect_no_match(connection_js, "if (connected) Shiny.setInputValue('pk_heartbeat'", fixed = TRUE)
})

test_that("search engines are sent to the public pages, not to the app", {
  # Each visit to the app's address starts it on a host paid for by the
  # hour, so the pages search engines index live in site/ (GitHub Pages).
  robots <- readLines(file.path(routing_dir, "www", "robots.txt"))
  expect_true("Disallow: /" %in% robots)
  expect_false(any(grepl("^(Allow|Sitemap):", robots)))
  expect_false(file.exists(file.path(routing_dir, "www", "sitemap.xml")))
  expect_false(file.exists(file.path(routing_dir, "www", "guide.html")))
  # The app's footer links to the guide on the public site.
  app <- paste(readLines(file.path(routing_dir, "app.R")), collapse = "\n")
  expect_match(app, 'paste0(site_address, "/guide.html")', fixed = TRUE)

  site <- file.path(repo_dir, "site")
  read_page <- function(page) paste(readLines(file.path(site, page), encoding = "UTF-8"), collapse = "\n")
  sitemap <- read_page("sitemap.xml")
  locs <- regmatches(sitemap, gregexpr("(?<=<loc>)[^<]+", sitemap, perl = TRUE))[[1]]
  expect_setequal(locs, paste0(site_address, c("/", "/guide.html")))
  for (loc in locs) {
    page <- sub(paste0("^", site_address, "/"), "", loc)
    if (!nzchar(page)) page <- "index.html"
    html <- read_page(page)
    expect_match(html, sprintf('<link rel="canonical" href="%s">', loc), fixed = TRUE, label = page)
    # Each page opens the app at its public address.
    expect_match(html, sprintf('href="%s/"', public_address), fixed = TRUE, label = page)
  }
  # Google's ownership check is on the public site too.
  expect_true(file.exists(file.path(site, "google47b320cdc6781b0a.html")))
})

test_that("the online app is published at most daily, not after every merge", {
  workflow <- yaml::read_yaml(file.path(repo_dir, ".github", "workflows", "online-app-manifest.yaml"))
  triggers <- workflow[[which(names(workflow) %in% c("on", "TRUE"))]]
  expect_null(triggers$push)
  expect_match(triggers$schedule[[1]]$cron, "^\\d+ \\d+ \\* \\* \\*$")
  # The manifest check still runs on every pull request.
  expect_true("pull_request" %in% names(triggers))
  steps <- workflow$jobs$manifest$steps
  publish <- Filter(function(s) identical(s$name, "Prepare the checked deployment branch"), steps)[[1]]
  expect_identical(publish$`if`, "steps.decide.outputs.publish == 'true'")
  expect_match(publish$run, "HEAD:connect-cloud", fixed = TRUE)
  decide <- Filter(function(s) identical(s$name, "Decide whether to publish"), steps)[[1]]
  expect_match(decide$run, "git diff --quiet origin/connect-cloud HEAD", fixed = TRUE)
  # A second daily look catches a morning run GitHub skipped, and publishes
  # only when the last publish is more than 20 hours old.
  expect_length(triggers$schedule, 2)
  expect_match(decide$run, "-lt 72000", fixed = TRUE)
})

test_that("the starting screen also goes on a link straight to Labs, where the main screen never draws", {
  expect_match(connection_js, "$(document).on('shiny:idle', function() { if (connected) dropStarting(); });", fixed = TRUE)
  expect_match(connection_js, "if (e.name === 'screen') dropStarting();", fixed = TRUE)
})
