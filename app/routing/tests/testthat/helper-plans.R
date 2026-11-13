# A named study plan holding the given analyses, for testing its page
# (plan_page_ui(), R/study-plan.R).
plan_with <- function(entries, name = "Test plan") {
  plan <- new_plan(name)
  for (e in entries) plan <- plan_add_entry(plan, e, allow_duplicate = TRUE)
  plan
}
page_html <- function(entries) as.character(plan_page_ui(plan_with(entries)))
