* App only, no engine change. Three findings from the 15 November 2026
  completeness review, on cards added in this round:
  - P-01: on the online app (`powerkit.local` not set), the engine's
    message for a missing optional backend no longer tells the person to
    run `install.packages()`, which nobody visiting can do there. It says
    the analysis isn't available on the online app right now and asks for
    a note through Feedback (`online_package_message()` in
    `app/routing/R/forms.R`, called by `plain_engine_message()`). A local
    copy keeps the install advice.
  - P-03: the E32 card named another card by its internal code. It now
    names the card ("Mediation when a mediator isn't a score"), and a test
    refuses an internal code in any card's text.
  - P-21: the hints under a card's name came from its `doc_name`, which a
    card with a `technical_name` never shows. E75 explained "ordinal
    outcome", and E18 "omnibus test", above names that don't contain those
    words. The hints now come from the name the card shows
    (`technical_name()`); the backend line's hints leave out the same terms.
