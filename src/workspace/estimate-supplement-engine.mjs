const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const norm = value => String(value || '').toLowerCase().replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();
const money = value => new Intl.NumberFormat('en-US',{style:'currency',currency:'USD',maximumFractionDigits:0}).format(Number(value || 0));

const STORE_KEY = 'hamriq_estimate_supplement_engine_v1';
const DEFAULTS = {
  roofSquares: 30,
  wastePct: 12,
  ridgeLf: 120,
  starterLf: 240,
  dripLf: 220,
  iceWaterRolls: 3,
  syntheticRolls: 4,
  vents: 8,
  pipeBoots: 4,
  tearOffPerSq: 65,
  installPerSq: 145,
  shinglePerSq: 125,
  ridgePerLf: 4.5,
  starterPerLf: 2.25,
  dripPerLf: 3.75,
  iceWaterPerRoll: 95,
  syntheticPerRoll: 85,
  ventEach: 38,
  pipeBootEach: 42,
  overheadProfitPct: 20,
  carrierAmount: 0,
  supplementNotes: 'Compare carrier estimate to HAMRIQ draft. Add missing code, accessories, steep/high, waste, metals, permit, detach/reset, and photo-backed collateral items. Human review required before sending.'
};

function loadState(){
  try { return {...DEFAULTS, ...JSON.parse(localStorage.getItem(STORE_KEY) || '{}')}; }
  catch { return {...DEFAULTS}; }
}
function saveState(state){ localStorage.setItem(STORE_KEY, JSON.stringify(state)); }
function calc(state){
  const finalSquares = Number(state.roofSquares || 0) * (1 + Number(state.wastePct || 0)/100);
  const materials = finalSquares*Number(state.shinglePerSq||0) + Number(state.ridgeLf||0)*Number(state.ridgePerLf||0) + Number(state.starterLf||0)*Number(state.starterPerLf||0) + Number(state.dripLf||0)*Number(state.dripPerLf||0) + Number(state.iceWaterRolls||0)*Number(state.iceWaterPerRoll||0) + Number(state.syntheticRolls||0)*Number(state.syntheticPerRoll||0) + Number(state.vents||0)*Number(state.ventEach||0) + Number(state.pipeBoots||0)*Number(state.pipeBootEach||0);
  const labor = Number(state.roofSquares||0)*(Number(state.tearOffPerSq||0)+Number(state.installPerSq||0));
  const subtotal = materials + labor;
  const op = subtotal * Number(state.overheadProfitPct||0)/100;
  const total = subtotal + op;
  const supplement = Math.max(0, total - Number(state.carrierAmount || 0));
  return {finalSquares, materials, labor, subtotal, op, total, supplement};
}
function field(key,label,type='number'){
  return `<label><span>${esc(label)}</span><input data-est-engine-field="${esc(key)}" type="${type}" inputmode="decimal"></label>`;
}
function clickAction(action,id=''){
  const button=[...document.querySelectorAll('[data-action]')].find(el=>el.dataset.action===action&&(id===''||el.dataset.id===id));
  if(!button) return false;
  button.click();
  return true;
}
function openWorkflow(kind){
  const tabs={measurement:'Inspections',scope:'Inspections',estimate:'Sales',gap:'Claims',supplement:'Claims',packet:'Claims',price:'Settings',provider:'Integrations',task:'Today'};
  clickAction('tab',tabs[kind]||'Today');
  setTimeout(()=>clickAction('new',kind),170);
}
function panel(){
  const state=loadState();
  const c=calc(state);
  return `<section id="estimateSupplementEngine" class="card estimate-engine section">
    <div class="estimate-engine-head">
      <div><p class="eyebrow">AUTOMATED ESTIMATE ENGINE</p><h2>Estimate first. Supplement second. Human review always.</h2><p class="muted">This calculator creates a structured draft while HOVER/EagleView/AI/photo integrations are connected.</p></div>
      <div class="estimate-total"><span>Draft total</span><b>${money(c.total)}</b><small>Potential supplement: ${money(c.supplement)}</small></div>
    </div>
    <div class="estimate-engine-grid">
      <article><h3>Measurements</h3>${field('roofSquares','Roof squares')}${field('wastePct','Waste %')}${field('ridgeLf','Ridge LF')}${field('starterLf','Starter LF')}${field('dripLf','Drip edge LF')}${field('iceWaterRolls','Ice/water rolls')}${field('syntheticRolls','Synthetic rolls')}</article>
      <article><h3>Accessories</h3>${field('vents','Vents')}${field('pipeBoots','Pipe boots')}${field('ventEach','Vent $ each')}${field('pipeBootEach','Pipe boot $ each')}${field('ridgePerLf','Ridge $/LF')}${field('starterPerLf','Starter $/LF')}${field('dripPerLf','Drip $/LF')}</article>
      <article><h3>Pricing</h3>${field('shinglePerSq','Shingle $/SQ')}${field('tearOffPerSq','Tear-off labor $/SQ')}${field('installPerSq','Install labor $/SQ')}${field('iceWaterPerRoll','Ice/water $/roll')}${field('syntheticPerRoll','Synthetic $/roll')}${field('overheadProfitPct','O&P %')}${field('carrierAmount','Carrier estimate amount')}</article>
      <article class="estimate-breakdown"><h3>Draft breakdown</h3><p><b>Final SQ with waste</b><span>${c.finalSquares.toFixed(1)}</span></p><p><b>Materials</b><span>${money(c.materials)}</span></p><p><b>Labor</b><span>${money(c.labor)}</span></p><p><b>Subtotal</b><span>${money(c.subtotal)}</span></p><p><b>O&P</b><span>${money(c.op)}</span></p><p><b>Total</b><span>${money(c.total)}</span></p><p><b>Supplement target</b><span>${money(c.supplement)}</span></p></article>
    </div>
    <label class="estimate-notes"><span>Supplement notes / missed items</span><textarea data-est-engine-field="supplementNotes"></textarea></label>
    <div class="estimate-engine-actions">
      <button data-est-action="measurement">Measurement request</button>
      <button data-est-action="scope">Photo-to-scope</button>
      <button data-est-action="estimate">Estimate draft</button>
      <button data-est-action="gap">Carrier gap finder</button>
      <button data-est-action="supplement">Supplement builder</button>
      <button data-est-action="packet">Claim packet</button>
      <button data-est-action="price">Price book</button>
      <button data-est-action="provider">Provider setup</button>
    </div>
  </section>`;
}
function bind(root=document){
  const state=loadState();
  root.querySelectorAll('[data-est-engine-field]').forEach(input=>{
    const key=input.dataset.estEngineField;
    input.value=state[key] ?? '';
    if(input.dataset.bound==='1') return;
    input.dataset.bound='1';
    input.addEventListener('input',()=>{
      const next=loadState();
      next[key]=input.type==='number'?Number(input.value || 0):input.value;
      saveState(next);
      refresh();
    });
  });
  root.querySelectorAll('[data-est-action]').forEach(button=>{
    if(button.dataset.bound==='1') return;
    button.dataset.bound='1';
    button.addEventListener('click',()=>openWorkflow(button.dataset.estAction));
  });
}
function inject(){
  const page=document.querySelector('#workspacePage');
  if(!page || document.querySelector('#estimateSupplementEngine')) return;
  const title=norm(document.querySelector('.page-heading h1')?.textContent || '');
  if(!['today','sales','inspections','claims','reports','approvals'].includes(title)) return;
  page.insertAdjacentHTML('afterbegin',panel());
  bind(page);
}
function refresh(){
  const existing=document.querySelector('#estimateSupplementEngine');
  if(!existing) return;
  existing.outerHTML=panel();
  bind(document);
}
new MutationObserver(inject).observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('DOMContentLoaded',inject);
setInterval(inject,1500);
