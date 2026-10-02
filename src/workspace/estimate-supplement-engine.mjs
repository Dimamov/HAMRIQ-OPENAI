import {buildPriceLines,compareCarrier} from './estimate-draft-model.mjs';
const esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const money=v=>new Intl.NumberFormat('en-US',{style:'currency',currency:'USD'}).format(v||0);
const sources=[['roofSquaresWaste','Roof squares + waste'],['roofSquares','Roof squares'],['ridgeLf','Ridge LF'],['starterLf','Starter LF'],['dripLf','Drip edge LF'],['iceWaterRolls','Ice/water rolls'],['syntheticRolls','Synthetic rolls'],['vents','Vents'],['pipeBoots','Pipe boots'],['manual','Manual quantity']];
const drafts=new Map();
const context=()=>window.HAMRIQ_ESTIMATES?.context();
function draft(id){if(!drafts.has(id))drafts.set(id,{measurements:{},items:[],tier:'Good',scope:'',carrier:'',evidence:'',justification:'',source:''});return drafts.get(id);}
function inject(){
 const page=document.querySelector('#workspacePage'),c=context();
 if(!page||!c||document.querySelector('#estimateSupplementEngine'))return;
 const title=document.querySelector('.page-heading h1')?.textContent?.trim();
 if(!['Today','Sales','Inspections','Claims','Reports','Approvals'].includes(title))return;
 const d=draft(c.jobId);
 const box=document.createElement('section');box.id='estimateSupplementEngine';box.className='card estimate-engine section';
 box.innerHTML=`<p class="eyebrow">ESTIMATE + CARRIER COMPARISON</p><h2>Build a reviewed estimate for ${esc(c.jobTitle||'the selected job')}</h2>
 <p class="muted">Enter verified measurements and select company price-book codes. Prices are recalculated on the server when saved. Measurements and carrier amounts are not inferred.</p>
 ${!c.prices.length?'<p class="notice">Add company price-book items in Settings before building an estimate.</p>':''}
 <div class="estimate-engine-grid"><article><h3>Measurements</h3>${sources.filter(([k])=>!['manual','roofSquaresWaste'].includes(k)).map(([k,l])=>`<label><span>${l}</span><input data-measure="${k}" type="number" min="0" step="0.01" value="${esc(d.measurements[k]??'')}"></label>`).join('')}<label><span>Waste %</span><input data-measure="wastePct" type="number" min="0" step="0.01" value="${esc(d.measurements.wastePct??'')}"></label></article>
 <article><h3>Scope and package</h3><label>Package<select data-tier>${['Good','Better','Best'].map(t=>`<option ${d.tier===t?'selected':''}>${t}</option>`).join('')}</select></label><label>Included scope<textarea data-scope rows="5">${esc(d.scope)}</textarea></label><p>No preset scope, measurements, or prices are silently applied.</p></article></div>
 <div data-items></div><button type="button" data-add>Add price-book line</button><p data-preview role="status"></p><button type="button" data-save>Save estimate for manager review</button>
 <hr><h3>Compare a saved estimate with carrier lines</h3><label>Saved estimate<select data-estimate><option value="">Choose saved estimate</option>${c.estimates.map(r=>`<option value="${r.id}" ${d.source===r.id?'selected':''}>${esc(r.payload.tier)} · ${money(r.payload.total)} · v${r.version} · ${esc(r.status)}</option>`).join('')}</select></label>
 <label>Carrier lines: CODE, QUANTITY, UNIT PRICE<textarea data-carrier rows="5" placeholder="Use the carrier's actual line items">${esc(d.carrier)}</textarea></label><button type="button" data-compare>Compare carrier lines</button><div data-comparison></div>
 <label>Evidence / photo references<textarea data-evidence>${esc(d.evidence)}</textarea></label><label>Reason and supporting documentation<textarea data-justification>${esc(d.justification)}</textarea></label><button type="button" data-supplement>Save supplement for manager review</button><p data-status role="status"></p>`;
 page.prepend(box);
 const status=msg=>box.querySelector('[data-status]').textContent=msg;
 const measures=()=>{const m={...d.measurements};m.roofSquaresWaste=Math.round(Number(m.roofSquares||0)*(1+Number(m.wastePct||0)/100)*100)/100;return m;};
 const lines=()=>buildPriceLines(d.items,measures(),c.prices);
 function preview(){try{const l=lines();box.querySelector('[data-preview]').textContent='Preview '+money(l.reduce((s,r)=>s+r.amount,0))+' · '+l.length+' lines. Server recalculates saved pricing.';}catch(e){box.querySelector('[data-preview]').textContent=e.message;}}
 function rows(){const target=box.querySelector('[data-items]');target.innerHTML=d.items.map((i,n)=>`<div class="row section"><label>Price-book code<select data-code="${n}"><option value="">Choose item</option>${c.prices.map(p=>`<option value="${esc(p.code)}" ${p.code===i.code?'selected':''}>${esc(p.code)} · ${esc(p.name)} · ${money(Number(p.price))}/${esc(p.unit)}</option>`).join('')}</select></label><label>Quantity source<select data-source="${n}">${sources.map(([k,l])=>`<option value="${k}" ${k===i.source?'selected':''}>${l}</option>`).join('')}</select></label><label>Manual quantity<input data-quantity="${n}" type="number" min="0" step="0.01" value="${esc(i.quantity??'')}" ${i.source!=='manual'?'disabled':''}></label><button data-remove="${n}" type="button">Remove</button></div>`).join('');
 target.querySelectorAll('[data-code]').forEach(el=>el.onchange=()=>{d.items[el.dataset.code].code=el.value;preview();});
 target.querySelectorAll('[data-source]').forEach(el=>el.onchange=()=>{d.items[el.dataset.source].source=el.value;rows();preview();});
 target.querySelectorAll('[data-quantity]').forEach(el=>el.oninput=()=>{d.items[el.dataset.quantity].quantity=el.value;preview();});
 target.querySelectorAll('[data-remove]').forEach(el=>el.onclick=()=>{d.items.splice(Number(el.dataset.remove),1);rows();preview();});
 }
 box.querySelectorAll('[data-measure]').forEach(el=>el.oninput=()=>{d.measurements[el.dataset.measure]=el.value;preview();});
 for(const [selector,key] of [['[data-tier]','tier'],['[data-scope]','scope'],['[data-carrier]','carrier'],['[data-evidence]','evidence'],['[data-justification]','justification'],['[data-estimate]','source']])box.querySelector(selector).addEventListener('input',e=>{d[key]=e.target.value;box.querySelector('[data-comparison]').textContent='';});
 box.querySelector('[data-add]').onclick=()=>{d.items.push({code:'',source:'manual',quantity:''});rows();};
 async function save(button,fn){button.disabled=true;try{await fn();}catch(e){status(e.message);}finally{button.disabled=false;}}
 box.querySelector('[data-save]').onclick=e=>save(e.target,async()=>{if(!d.scope.trim())throw Error('Enter the reviewed scope.');const l=lines();await window.HAMRIQ_ESTIMATES.save(c.jobId,'estimate',{tier:d.tier,scope:d.scope,lines:l.map(r=>r.code+', '+r.quantity).join('\n'),measurements:measures(),quantity_sources:structuredClone(d.items)});});
 function comparison(){const r=context().estimates.find(r=>r.id===d.source);if(!r?.payload.calculated_lines?.length)throw Error('Choose a saved estimate with calculated lines.');return {record:r,result:compareCarrier(r.payload.calculated_lines,d.carrier)};}
 box.querySelector('[data-compare]').onclick=()=>{try{const {result}=comparison();box.querySelector('[data-comparison]').innerHTML=`<p>Potential additional amount: <b>${money(result.total)}</b>. Human review required; this is not an insurance entitlement.</p><table class="table"><thead><tr><th>Code</th><th>Expected qty / price</th><th>Carrier qty / price</th><th>Potential gap</th></tr></thead><tbody>${result.lines.map(l=>`<tr><td>${esc(l.code)}</td><td>${l.quantity} / ${money(l.unit_price)}</td><td>${l.carrier?l.carrier.quantity+' / '+money(l.carrier.unit_price):'Missing'}</td><td>${money(l.gap)}</td></tr>`).join('')}</tbody></table>${result.unmatched.length?'<p>Unmatched carrier codes require manual mapping: '+esc(result.unmatched.join(', '))+'</p>':''}`;status('Review code mapping, scope, units, and evidence before saving.');}catch(e){status(e.message);}};
 box.querySelector('[data-supplement]').onclick=e=>save(e.target,async()=>{const {record,result}=comparison();if(!d.evidence.trim()||!d.justification.trim())throw Error('Provide evidence and supporting justification.');if(result.unmatched.length)throw Error('Resolve unmatched carrier codes before creating a supplement.');const gaps=result.lines.filter(l=>l.gap>0);if(!gaps.length)throw Error('No positive line-item gaps found.');await window.HAMRIQ_ESTIMATES.save(c.jobId,'supplement',{scope:gaps.map(l=>l.code+' — '+l.name+'; expected '+l.quantity+' at '+money(l.unit_price)+', carrier '+(l.carrier?l.carrier.quantity+' at '+money(l.carrier.unit_price):'missing')+'; potential gap '+money(l.gap)).join('\n'),amount:result.total,evidence:d.evidence,justification:d.justification,source_estimate_id:record.id,source_estimate_version:record.version,comparison:result,carrier_lines:d.carrier});});
 rows();preview();
}
new MutationObserver(inject).observe(document.documentElement,{childList:true,subtree:true});
setInterval(inject,1500);
inject();
