const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const norm = value => String(value || '').toLowerCase().replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();

const MODULES = [
  {
    key:'homeowner-status',
    title:'Homeowner status assistant',
    body:'Explains job stage, claim stage, production status, next step, and who owns the next action.',
    actions:[['Draft homeowner status message','message'],['Create homeowner follow-up','task'],['Open customer portal','portal'],['Claim timeline','claim']]
  },
  {
    key:'ai-receptionist',
    title:'AI receptionist intake',
    body:'24/7 intake path for caller name, phone, address, issue, urgency, source, booking request, and routing note.',
    actions:[['Create intake lead','lead'],['Receptionist call note','note'],['Schedule callback','task'],['Route to manager','risk']]
  },
  {
    key:'knowledge-base',
    title:'Company knowledge base',
    body:'SOP, vendor, install standard, IKO/pricing rules, adjuster language, and company policy lookup path for Hammy.',
    actions:[['Add SOP note','note'],['Provider/vendor setup','provider'],['Pricing rule','price'],['Training task','task']]
  },
  {
    key:'learning-loop',
    title:'Actual vs estimate learning loop',
    body:'Compare estimate, carrier estimate, final invoice, job cost, missed items, margin, and lesson learned.',
    actions:[['Job costing','cost'],['Estimate draft','estimate'],['Carrier gap finder','gap'],['Learning follow-up','task']]
  },
  {
    key:'production-depth',
    title:'Deep production control',
    body:'Subcontractor/crew, materials, delivery mismatch, permit, final photos, warranty, weather, and homeowner update path.',
    actions:[['Crew schedule','schedule'],['Material order','material_order'],['Delivery check','delivery'],['Warranty registration','warranty']]
  }
];

const TAB_BY_KIND = {message:'Customers',task:'Today',portal:'Customers',claim:'Claims',lead:'Today',note:'Customers',risk:'Sales',provider:'Integrations',price:'Settings',cost:'Financials',estimate:'Sales',gap:'Claims',schedule:'Production',material_order:'Production',delivery:'Production',warranty:'Production'};

function clickAction(action, id='') {
  const el = [...document.querySelectorAll('[data-action]')].find(button => button.dataset.action === action && (id === '' || button.dataset.id === id));
  if (!el) return false;
  el.click();
  return true;
}
function run(kind) {
  if (kind === 'lead') return clickAction('lead');
  if (kind === 'portal') return clickAction('tab','Customers') && setTimeout(() => clickAction('portal'),180);
  clickAction('tab', TAB_BY_KIND[kind] || 'Today');
  setTimeout(() => clickAction('new', kind), 180);
}
function card(module) {
  return `<article class="customer-ops-card ${esc(module.key)}"><div><b>${esc(module.title)}</b><span>${esc(module.key.replaceAll('-',' '))}</span></div><p>${esc(module.body)}</p><div class="customer-ops-actions">${module.actions.map(([label,kind])=>`<button type="button" data-customer-ops-kind="${esc(kind)}">${esc(label)}</button>`).join('')}</div></article>`;
}
function html() {
  return `<section id="customerOpsIntelligence" class="card customer-ops section"><p class="eyebrow">CUSTOMER + OPS INTELLIGENCE</p><h2>Recovered high-value workflows are now active paths.</h2><p class="muted">These workflows organize intake, homeowner status, SOP knowledge, estimate learning, and deeper production. Live AI/call/SMS delivery remains gated until provider credentials are connected.</p><div class="customer-ops-grid">${MODULES.map(card).join('')}</div></section>`;
}
function bind(root=document) {
  root.querySelectorAll('[data-customer-ops-kind]').forEach(button => {
    if (button.dataset.bound === '1') return;
    button.dataset.bound = '1';
    button.addEventListener('click', () => run(button.dataset.customerOpsKind));
  });
}
function inject() {
  const page = document.querySelector('#workspacePage');
  if (!page || document.querySelector('#customerOpsIntelligence')) return;
  const heading = norm(document.querySelector('.page-heading h1')?.textContent || '');
  if (!['today','customers','sales','production','reports','hammy'].includes(heading)) return;
  page.insertAdjacentHTML(heading === 'today' ? 'afterbegin' : 'beforeend', html());
  bind(page);
}
new MutationObserver(inject).observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('DOMContentLoaded', inject);
setInterval(inject, 1500);
