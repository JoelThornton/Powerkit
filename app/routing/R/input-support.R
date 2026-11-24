# Route people to existing, supported translations; never impute an input.
# A fold in the effect section (23 November 2026), not at the top of the
# screen: it is about the effect's numbers, and the conversion question
# and the "don't know what effect to expect" line now say the rest.
input_support_ui <- function(form, fields) {
  ids <- vapply(fields, `[[`, "", "id")
  has <- function(id) id %in% ids
  tags$details(class = "input-support mb-3",
    tags$summary("If your numbers are published another way, or missing"),
    if (has("metric") || has("effect_units")) p("Have means and SDs in the measure's own units? Choose that option under \u201cHow you'll give the effect\u201d. Use SDs, not standard errors or variances, and keep means and SDs in the same units."),
    if (has("conv_from")) p("Have a t or F statistic, or another effect size? Choose it in the question below the effect size. Use the published study's degrees of freedom and group sizes, not your planned sample size. An F statistic doesn't give the effect's direction: check the original contrast before choosing a one-sided test."),
    if (has("eta_source")) p("A published repeated-measures effect and an effect worked out from population means use different conventions. Choose the source that matches your numbers; don't copy partial eta-squared from a different design."),
    if (has("raw_r") && identical(form$base$template, "paired_t")) p("For paired scores, the correlation must be between the two measurements on the same people. Means and SDs at each time alone don't give the SD of changes. If you have the SD of changes, use the change-score option; otherwise save a draft, or compare named alternatives with different correlations."),
    if (any(grepl("^(p_|r_)", ids))) p("Regression and mediation need each coefficient or correlation in the model. A total indirect effect, an unadjusted correlation or a p-value alone doesn't give them. Keep raw and standardised units, and how yes/no variables are coded, the same throughout."),
    p("Missing a number? Open its info button for where to find it. You can record it as unknown under \u201cAssumptions, sources and named alternatives\u201d and save an unfinished draft. Named alternatives compare defensible values; they don't show which one is right."),
    p("A published summary cannot always be converted uniquely into what this screen needs: keep the draft and look for the matching model output or data. If you use a rule-of-thumb effect meanwhile, choose \u201cA convention or rule of thumb\u201d as its source, so the write-up says where the number came from. Zero or a package's default is not an effect to plan for."))
}

published_import_ui <- function() {
  tagList(textInput("reported_statistic", "Or paste it as the paper reports it (optional)", width = "100%",
      value = "", placeholder = "t(58) = 2.5 or F(1, 58) = 6.25"),
    tags$button(type = "button", class = "btn btn-outline-primary mt-2", onclick = "pkImportStatistic()", "Use this reported statistic"),
    p(id = "reported_statistic_message", role = "status"),
    p(class = "small text-muted", "Fills the boxes below from text such as t(58) = 2.5. A p-value alone isn't enough. Add the source, and both group sizes if they were unequal."),
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
