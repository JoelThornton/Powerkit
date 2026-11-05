# Scenario metadata is kept in a form value, so project and unfinished-draft
# round trips use the existing snapshot/staleness rules.
read_scenario_library <- function(text, fields = NULL) {
  empty <- list(version = 1L, assumptions = list(), alternatives = list())
  if (blank(text)) return(empty)
  if (nchar(text, type = "bytes") > 1e6) stop("The assumptions/scenarios record is too large.")
  x <- tryCatch(jsonlite::fromJSON(text, simplifyVector = FALSE), error = function(e) NULL)
  if (!is.list(x) || !isTRUE(x$version == 1) || !is.list(x$assumptions) || !is.list(x$alternatives) ||
      length(x$assumptions) > 100 || length(x$alternatives) > 20) stop("The assumptions/scenarios record is not supported. Start a new record or reopen an earlier draft.")
  scalar <- function(v) is.character(v) && length(v) == 1 && !is.na(v) && nchar(v) <= 10000
  allowed <- if (is.null(fields)) NULL else vapply(fields, `[[`, "", "id")
  valid_values <- function(v) is.list(v) && (is.null(allowed) || all(names(v) %in% allowed)) && all(vapply(v, scalar, logical(1)))
  for (a in c(x$assumptions, unlist(lapply(x$alternatives, function(a) a$assumptions %||% list()), recursive = FALSE))) {
    if (!is.list(a) || !scalar(a$field) || !scalar(a$value) || !scalar(a$source) ||
        !isTRUE(a$status %in% c("reported", "derived", "assumed", "unknown")) ||
        (!is.null(allowed) && !a$field %in% allowed) || (identical(a$status, "unknown") && nzchar(a$value)) ||
        (a$status %in% c("reported", "derived") && blank(a$source)))
      stop("An assumption record has an invalid field, status, source or value.")
  }
  for (a in x$alternatives) {
    if (!is.list(a) || !scalar(a$name) || !nzchar(trimws(a$name)) || !valid_values(a$values)) stop("A named alternative has unsupported answers.")
  }
  x
}

assumption_record_lines <- function(values, fields) {
  x <- read_scenario_library(values$scenario_library, fields)
  format_assumption_records(x$assumptions, values, fields)
}

format_assumption_records <- function(records, values, fields) {
  if (!length(records)) return("No individual assumption source/status records were entered. Values remain planning assumptions.")
  vapply(records, function(a) {
    f <- Filter(function(f) identical(f$id, a$field), fields)
    label <- if (length(f)) f[[1]]$label else a$field
    matches <- identical(trimws(a$value), trimws(as.character(values[[a$field]] %||% "")))
    status <- if (matches) a$status else "changed since the source was recorded; source needs review"
    sprintf("- %s: %s. Recorded value: %s. Source/reasoning: %s", label, status,
      if (identical(a$status, "unknown")) "unknown (no number supplied)" else a$value,
      if (blank(a$source)) "not recorded" else a$source)
  }, "")
}

named_alternative_lines <- function(values, fields) {
  x <- read_scenario_library(values$scenario_library, fields)
  if (!length(x$alternatives)) return("No named alternative assumptions were saved.")
  unlist(lapply(x$alternatives, function(a) {
    changed <- names(a$values)[vapply(names(a$values), function(id) !identical(a$values[[id]], as.character(values[[id]] %||% "")), logical(1))]
    changed <- intersect(changed, vapply(fields, `[[`, "", "id"))
    c(paste("Alternative:", a$name), vapply(changed, function(id) {
      f <- Filter(function(f) identical(f$id, id), fields)[[1]]
      paste0("- ", f$label, ": ", a$values[[id]])
    }, ""), format_assumption_records(a$assumptions %||% list(), utils::modifyList(values, a$values), fields))
  }))
}

compare_named_alternatives <- function(forms, ep_id, fields, values) {
  library <- read_scenario_library(values$scenario_library, fields)
  if (length(library$alternatives) < 2 || length(library$alternatives) > 5)
    stop("Save between two and five alternatives for a comparison.")
  validate <- engine_function("validate_spec")
  simulates <- engine_function("runs_simulation")
  prepared <- lapply(library$alternatives, function(a) {
    v <- utils::modifyList(values, a$values)
    problems <- form_problems(fields, v)
    if (length(problems)) stop(paste(a$name, paste(problems, collapse = " "), sep = ": "))
    spec <- suppressWarnings(validate(build_spec(forms, ep_id, fields, v)))
    if (!spec$goal$type %in% c("power", "sample_size")) stop("Formula comparisons currently support power at a fixed N and sample size for a target power. Load other goals and calculate them separately.")
    if (suppressWarnings(simulates(spec))) stop("At least one alternative needs simulation. Load and calculate these separately; comparison does not start long simulations automatically.")
    list(name = a$name, spec = spec)
  })
  # Prepare every spec before running any. Only existing engine formulas run.
  run <- engine_function("run_spec")
  do.call(rbind, lapply(prepared, function(a) {
    r <- suppressWarnings(run(a$spec))
    value <- if (identical(r$goal_type, "sample_size")) r$n_required$n else if (identical(r$goal_type, "precision")) r$precision$width else r$curve$power[1]
    unit <- engine_function("sample_structure")(a$spec)$unit
    data.frame(alternative = a$name,
      goal = if (identical(r$goal_type, "power")) sprintf("Power at N = %s %s", a$spec$goal$n, unit) else sprintf("Sample size for %s%% power", 100 * a$spec$goal$power),
      value = signif(value, 5), units = if (identical(r$goal_type, "power")) "probability (0 to 1)" else unit,
      note = "Conditional on this alternative's assumptions; sources are not certified by the app.", stringsAsFactors = FALSE)
  }))
}

scenario_library_ui <- function(f, value) {
  fields <- f$scenario_fields
  candidates <- Filter(function(x) x$type %in% c("number", "numbers", "table") &&
    !x$id %in% c("seed", "nrep", "guess") && !is.null(x$path), fields)
  tagList(
    div(style = "display:none", textAreaInput("f_scenario_library", "Assumptions and named alternatives", value = value)),
    p("Record where an input comes from, then save named alternatives such as lower correlation, larger SD or unequal allocation. These records are your assessment; the app cannot verify a source. Unknown means no number, rather than zero."),
    tags$label(`for` = "scenario_field", "Input to document"),
    tags$select(id = "scenario_field", class = "form-control", lapply(candidates, function(x) tags$option(value = x$id, x$label))),
    tags$label(`for` = "scenario_status", "How is the value known?"),
    tags$select(id = "scenario_status", class = "form-control", lapply(c("reported", "derived", "assumed", "unknown"), function(x) tags$option(value = x, x))),
    tags$label(`for` = "scenario_source", "Source, derivation or reason for the assumption"),
    tags$textarea(id = "scenario_source", class = "form-control", rows = 2),
    tags$button(type = "button", class = "btn btn-outline-secondary mt-2", onclick = "pkScenarioRecord()", "Record input status/source"),
    tags$label(`for` = "scenario_name", "Name for an alternative set of answers"),
    tags$input(id = "scenario_name", class = "form-control", maxlength = 120),
    tags$button(type = "button", class = "btn btn-outline-secondary mt-2", onclick = "pkScenarioSave()", "Save these answers as a named alternative"),
    tags$button(type = "button", class = "btn btn-outline-secondary mt-2", onclick = "pkScenarioShow()", "Show saved alternatives and sources"),
    actionButton("scenario_compare", "Compare saved alternatives by formula", class = "btn btn-outline-secondary mt-2"),
    p(id = "scenario_message", role = "status", `aria-live` = "polite"), tags$div(id = "scenario_list"), uiOutput("scenario_comparison"),
    p(class = "small", "Alternatives stay on this input screen and are saved with its draft/project file. Save a file before leaving. Loading an alternative edits the form and makes an existing result stale; calculate again before saving its result. Formula comparisons exclude simulations and do not choose your assumptions for you."),
    tags$script(HTML(scenario_js)))
}

scenario_js <- "
(function(){
 var get=function(id){return document.getElementById(id);};
 var message=function(t){get('scenario_message').textContent=t;};
 var read=function(){var t=get('f_scenario_library').value;var x=t?JSON.parse(t):{version:1,assumptions:[],alternatives:[]};if(x.version!==1||!Array.isArray(x.assumptions)||!Array.isArray(x.alternatives))throw Error('Unsupported scenario record');return x;};
 var write=function(x){get('f_scenario_library').value=JSON.stringify(x);get('f_scenario_library').dispatchEvent(new Event('change',{bubbles:true}));};
 var answers=function(){var v={};document.querySelectorAll('#screen .form-field input[id^=f_],#screen .form-field select[id^=f_],#screen .form-field textarea[id^=f_]').forEach(function(el){if(el.id!=='f_scenario_library')v[el.id.slice(2)]=el.value;});return v;};
 window.pkScenarioRecord=function(){try{var x=read(),id=get('scenario_field').value,el=get('f_'+id),status=get('scenario_status').value,source=get('scenario_source').value;if(!el)throw Error('Choose an input available on this screen.');if((status==='reported'||status==='derived')&&!source.trim())throw Error('Give the source or derivation for this status.');if(status==='unknown'){el.value='';el.dispatchEvent(new Event('change',{bubbles:true}));}x.assumptions=x.assumptions.filter(function(a){return a.field!==id;});x.assumptions.push({field:id,status:status,value:el.value,source:source});if(x.assumptions.length>100)throw Error('Keep at most 100 input records.');write(x);message('Recorded. Save a draft or project file to keep it.');}catch(e){message(e.message);}};
 window.pkScenarioSave=function(){try{var x=read(),name=get('scenario_name').value.trim();if(!name)throw Error('Give the alternative a name.');if(x.alternatives.some(function(a){return a.name===name;}))throw Error('That name is already saved; choose another or delete the old alternative.');if(x.alternatives.length>=20)throw Error('Keep at most 20 alternatives.');x.alternatives.push({name:name,values:answers(),assumptions:JSON.parse(JSON.stringify(x.assumptions))});write(x);window.pkScenarioShow();message('Alternative saved in these answers. Save a draft or project file before leaving.');}catch(e){message(e.message);}};
 window.pkScenarioShow=function(){try{var x=read(),out=get('scenario_list');out.replaceChildren();x.assumptions.forEach(function(a){var p=document.createElement('p');p.textContent=a.field+': '+a.status+'; '+(a.status==='unknown'?'no number':a.value)+'; '+a.source;out.appendChild(p);});x.alternatives.forEach(function(a,i){var row=document.createElement('p'),name=document.createElement('strong');name.textContent=a.name+' ';row.appendChild(name);var load=document.createElement('button');load.type='button';load.className='btn btn-sm btn-outline-primary';load.textContent='Load answers';load.onclick=function(){var ids=Object.keys(a.values);if(ids.some(function(id){return !get('f_'+id);})){message('This alternative needs fields absent from this screen. Restore its matching design/mediator count first. No answers were changed.');return;}ids.forEach(function(id){var el=get('f_'+id);el.value=a.values[id];el.dispatchEvent(new Event('change',{bubbles:true}));});var latest=read();latest.assumptions=a.assumptions||[];write(latest);message('Answers loaded. Recalculate; the old result is not current.');};row.appendChild(load);var del=document.createElement('button');del.type='button';del.className='btn btn-sm btn-outline-secondary';del.textContent='Delete alternative';del.onclick=function(){var latest=read();latest.alternatives.splice(i,1);write(latest);window.pkScenarioShow();};row.appendChild(del);out.appendChild(row);});}catch(e){message('Cannot read saved alternatives: '+e.message);}};
})();
"
