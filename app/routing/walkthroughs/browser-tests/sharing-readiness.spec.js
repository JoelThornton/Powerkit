const { test, expect } = require('@playwright/test');
async function open(page,id){ await page.goto('/?card='+id); await page.getByRole('button',{name:'Enter your values',exact:false}).click(); }
async function put(page,id,value){
 const e=page.locator('#f_'+id);
 await e.evaluate(x=>{for(let p=x.parentElement;p;p=p.parentElement)if(p.tagName==='DETAILS')p.open=true;});
 if(await e.evaluate(x=>x.tagName==='SELECT'))await e.selectOption(value);else await e.fill(value);
 await e.blur();
}
test('binary-predictor mediation warns before inputs and tracks the chosen method',async({page})=>{
 await open(page,'E17');
 await expect(page.locator('#selected_evidence .planning-critical')).toContainText('test too liberal');
 await expect(page.locator('#selected_evidence')).not.toContainText('Checks covering my selected settings');
 await page.locator('#explanations_on').uncheck();
 await expect(page.locator('#selected_evidence .planning-critical')).toBeVisible();
 await put(page,'method','ols_percentile_bootstrap');
 await expect(page.locator('#selected_evidence .planning-critical')).toContainText('not a calibration estimate for the selected bootstrap');
 await expect(page.locator('#selected_evidence .planning-critical')).not.toContainText('test too liberal');
 await put(page,'x_type','continuous');
 await expect(page.locator('#selected_evidence .planning-critical')).toHaveCount(0);
});
test('unknown paired correlation has an existing route that needs no correlation',async({page})=>{
 await page.setViewportSize({width:390,height:844});
 await open(page,'E3');
 await put(page,'effect_units','raw');
 await expect(page.locator('#f_raw_r')).toHaveValue('');
 await expect(page.locator('#f_raw_r_help')).toContainText('zero is an assumption');
 await put(page,'raw_sd_kind','difference');
 await expect(page.locator('#f_raw_r')).toBeHidden();
 await expect(page.locator('#f_raw_sd_difference')).toBeVisible();
 expect(await page.evaluate(()=>document.documentElement.scrollWidth-window.innerWidth)).toBeLessThanOrEqual(1);
});
test('power shortcut is explicit and regression explains its initially hidden inputs',async({page})=>{
 await open(page,'E2');
 await expect(page.locator('#f_power')).toHaveValue('');
 await put(page,'goal','sample_size');
 await expect(page.locator('#f_power_help')).toContainText('chance your test comes out significant');
 await page.locator('#f_power_usual').click();
 await expect(page.locator('#f_power')).toHaveValue('0.8');
 await open(page,'E24');
 await expect(page.locator('.effect-waits')).toBeVisible();
 await expect(page.locator('.effect-waits')).toContainText('Choose');
 await put(page,'question','r2_increase');
 await expect(page.locator('.effect-waits')).toBeHidden();
 await expect(page.locator('#f_r2_full')).toBeVisible();
});
