const { test, expect } = require('@playwright/test');
async function open(page,id){
 await page.goto('/?card='+id);
 await page.getByRole('button',{name:'Enter your values',exact:false}).click();
}
async function put(page,id,value){
 const e=page.locator('#f_'+id);
 await e.evaluate(x=>{ for(let p=x.parentElement;p;p=p.parentElement) if(p.tagName==='DETAILS')p.open=true; });
 if(await e.evaluate(x=>x.tagName==='SELECT')) await e.selectOption(value); else await e.fill(value);
 await e.blur();
}
test('all-test planning starts with unknown dependence and evidence follows complete inputs',async({page})=>{
 await open(page,'E2');
 await expect(page.locator('#selected_evidence')).not.toContainText('Checks covering my selected settings');
 await put(page,'claim','all'); await put(page,'n_tests','2');
 await expect(page.locator('#f_all_dependence')).toHaveValue('unknown');
 await put(page,'goal','power'); await put(page,'method','student_t');
 await put(page,'alternative','two_sided'); await put(page,'d','0.4');
 await put(page,'n','120'); await put(page,'alpha','0.05');
 await put(page,'just_type','smallest_effect_of_interest'); await put(page,'just_source','Synthetic browser scenario');
 await expect(page.locator('#selected_evidence')).toContainText('Checks covering my selected settings');
  await page.locator('#selected_evidence').getByText('Checks covering my selected settings', { exact: true }).click();
 await expect(page.locator('#selected_evidence')).toContainText('not of every value you could enter');
});
test('interaction sensitivity carries the proposed effect into its simulation form',async({page})=>{
 await open(page,'E9');
 for(const [id,value] of Object.entries({goal:'sensitivity',interaction_metric:'correlation',n:'100',power:'0.8',alpha:'0.05',
 r_X_Y:'0.2',r_W_Y:'0.15',r_XW_Y:'0.1',r_X_W:'0.1',rel_X:'0.8',rel_W:'0.85',
 just_type:'smallest_effect_of_interest',just_source:'Synthetic browser scenario'})) await put(page,id,value);
 await page.locator('#form_check').click();
 await expect(page.locator('#verify_interaction')).toBeVisible();
 await expect(page.locator('.result-headline').first()).toContainText('Formula approximation');
 await page.locator('#verify_interaction').click();
 await expect(page.locator('#f_goal')).toHaveValue('power');
 await expect(page.locator('#f_n')).toHaveValue('100');
 await expect(page.locator('#f_r_XW_Y')).not.toHaveValue('0.1');
 await expect(page.locator('#f_rel_X')).toHaveValue('0.8');
 await expect(page.locator('#f_r_X_W')).toHaveValue('0.1');
 await expect(page.locator('#form_result')).toContainText('not been confirmed by simulation yet');
});

test('corrected mixed ANOVA simulates by default, and the exact dataset warns and offers a matched check',async({page})=>{
 await open(page,'E55');
 for(const [id,value] of Object.entries({goal:'power',n:'60',alpha:'0.05',test_version:'anova_f',
 A_levels:'Therapy, Waiting list',B_levels:'Before, After, Follow-up',metric:'raw',means:'20, 16, 15\n20, 19, 18.5',
 spread:'differ',sds:'6, 6, 6\n6, 6, 6',rs:'0.5, 0.3, 0.4',correction:'GG',effect:'interaction',
 just_type:'smallest_effect_of_interest',just_source:'Synthetic browser scenario'})) await put(page,id,value);
 // Departure 28: a corrected test without sphericity starts at simulation.
 await expect(page.locator('#f_gg_method')).toHaveValue('simulation');
 await put(page,'gg_method','exact');
 await expect(page.locator('.selected-method-warning')).toContainText('applies the sphericity correction approximately');
 await page.locator('#form_check').click();
 await expect(page.locator('#verify_corrected_anova')).toBeVisible();
 await page.locator('#verify_corrected_anova').click();
 await expect(page.locator('#f_gg_method')).toHaveValue('simulation');
 await expect(page.locator('#f_goal')).toHaveValue('power');
 await expect(page.locator('#f_n')).toHaveValue('60');
 await expect(page.locator('#f_correction')).toHaveValue('GG');
});
