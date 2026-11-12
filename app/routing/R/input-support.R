# Route people to existing, supported translations; never impute an input.
input_support_ui <- function(form, fields) {
  ids <- vapply(fields, `[[`, "", "id")
  has <- function(id) id %in% ids
  tags$details(class = "input-support mb-3",
    tags$summary("I have published results, raw scores, or missing information"),
    if (has("metric") || has("effect_units")) p("For means and SDs in the original measure, choose the raw-score option in the effect/units selector below. Use SDs, not standard errors or variances. Keep means and SDs in the same measure units."),
    if (has("conv_from")) p("For a published t, F or another effect size, use the question below the effect size that asks whether you have it in another form. Only the conversions supported by this analysis are offered. Use the original study's degrees of freedom and group sizes, not your planned sample size. An F statistic loses the direction of an effect; check the original contrast before choosing a one-sided decision."),
    if (has("conv_from")) published_import_ui(),
    if (has("eta_source")) p("A published repeated-measures effect and an effect derived from population means use different conventions. Select the source that matches your information; do not copy partial eta-squared from a different design."),
    if (has("raw_r") && identical(form$base$template, "paired_t")) p("For paired scores, the correlation must describe the two measurements on the same people. Marginal means and SDs alone do not identify the SD of changes. If you have the SD of changes, use the change-score option; otherwise save a draft or compare explicitly labelled correlation assumptions."),
    if (any(grepl("^(p_|r_)", ids))) p("Regression and mediation need the stated model's component coefficients and correlations. A total indirect effect, an unadjusted correlation, or a p-value alone does not identify the full population. Keep raw versus standardised units and binary-variable coding consistent."),
    p("If an input is missing, open its 'What this means and where to find it' help. You can record it as unknown under assumptions/sources and save an unfinished draft. Named alternatives can compare defensible assumptions; they do not establish which assumption is true."),
    if (has("just_type") && has("goal") && isTRUE(form$base$design == "basic_test")) p("If you cannot justify an effect but know your available sample size, choose the smallest effect you could detect under 'Your goal'. This describes sensitivity at that budget; it does not choose a meaningful effect for you."),
    p("An unsupported published summary cannot always be converted uniquely. Keep the draft and seek the matching model output or data. Do not put zero, a conventional 'medium' effect, or a package default in a box simply to obtain an answer."))
}

published_import_ui <- function() {
  tagList(textInput("reported_statistic", "Paste a reported t or F statistic (optional)",
      value = "", placeholder = "t(58) = 2.5 or F(1, 58) = 6.25"),
    tags$button(type = "button", class = "btn btn-outline-primary mt-2", onclick = "pkImportStatistic()", "Use this reported statistic"),
    p(id = "reported_statistic_message", role = "status"),
    p("This fills existing fields; the engine performs the conversion. Only the stated statistic and whole-number degrees of freedom are read. A p-value alone is insufficient. Add the paper/source, adjustment, and both original group sizes if unequal."),
    tags$script(HTML(reported_statistic_js)))
}

reported_statistic_js <- r"---(
window.pkImportStatistic = function(){
 var get=function(id){return document.getElementById(id);};
 var say=function(t){get('reported_statistic_message').textContent=t;};
 var text=get('reported_statistic').value.trim().replace(/\u2212/g,'-');
 var m=text.match(/^([tF])\s*\(\s*([+-]?[0-9]*[.]?[0-9]+(?:e[+-]?[0-9]+)?)\s*(?:,\s*([+-]?[0-9]*[.]?[0-9]+(?:e[+-]?[0-9]+)?)\s*)?\)\s*=\s*([+-]?[0-9]*[.]?[0-9]+(?:e[+-]?[0-9]+)?)\s*$/i);
 if(!m){say('Use t(df) = value or F(df1, df2) = value, without extra text. A p-value alone cannot identify this conversion. No answers were changed.');return;}
 var type=m[1].toLowerCase()==='t'?'t':'F',first=Number(m[2]),second=m[3]===undefined?null:Number(m[3]),value=Number(m[4]);
 var df=type==='t'?first:second,select=get('f_conv_from');
 if((type==='t'&&second!==null)||(type==='F'&&second===null)||!Number.isInteger(first)||first<1||!Number.isInteger(df)||df<1||!Number.isFinite(value)||(type==='F'&&value<0)){
  say('This route needs positive whole-number degrees of freedom and a finite statistic (F cannot be negative). Fractional Welch/corrected df must not be rounded to force a conversion. No answers were changed.');return;}
 if(!select||!Array.from(select.options).some(function(o){return o.value===type;})){say('That statistic is not supported by this analysis. No answers were changed.');return;}
 if(type==='F'&&!get('f_conv_df1')&&first!==1){say('This conversion supports only one numerator degree of freedom for F. No answers were changed.');return;}
 var changes={conv_from:type,conv_value:String(value),conv_df:String(df)};
 if(type==='F'&&get('f_conv_df1'))changes.conv_df1=String(first);
 [['effect_units','standardised'],['metric','eta_squared'],['eta_source','published']].forEach(function(pair){
  var el=get('f_'+pair[0]);if(el&&el.tagName==='SELECT'&&Array.from(el.options).some(function(o){return o.value===pair[1];}))changes[pair[0]]=pair[1];});
 if(Object.keys(changes).some(function(id){return !get('f_'+id);})){say('Matching fields are unavailable on this screen. No answers were changed.');return;}
 Object.keys(changes).forEach(function(id){var el=get('f_'+id);el.value=changes[id];el.dispatchEvent(new Event('change',{bubbles:true}));});
 say('Conversion fields filled. Check the original study, group sizes, source and adjustment before calculating.'+(type==='F'?' F does not supply an effect direction; check the original contrast before a one-sided decision.':''));
};
)---"
