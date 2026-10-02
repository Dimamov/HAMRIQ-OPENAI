const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const norm = value => String(value || '').toLowerCase().replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();

const FEATURES = [
  {title:'GPS door-knocking mode', priority:'High', detail:'Use current location/address, edit address, record outcome, create lead only when interested, or set follow-up without forcing a lead.', actions:[['Log door visit','door'],['Create interested lead','lead'],['Set follow-up','task'],['Rep route','route']]},
  {title:'Smart lead routing / inbound inbox', priority:'High', detail:'Manager intake lane for new leads, assign/reassign by area, source, urgency, rep availability, and ownership rules.', actions:[['New lead','lead'],['Routing task','task'],['Manager note','note'],['Campaign/source','campaign']]},
  {title:'24/7 AI receptionist intake', priority:'High', detail:'Capture caller/homeowner details, summarize request, create lead/task, flag FIRE or urgent items for review.', actions:[['Receptionist intake','lead'],['Call summary note','note'],['Urgent follow-up','task'],['Customer message','message']]},
  {title:'Homeowner status assistant', priority:'High', detail:'Explain current job/claim/production stage, next step, due date, and who owns it using visible job records.', actions:[['Homeowner message','message'],['Portal shortcut','portal'],['Status follow-up','task'],['Property note','note']]},
  {title:'Carrier PDF extraction path', priority:'High', detail:'Upload/track carrier estimate PDF, extract line items, compare to HAMRIQ estimate, and route supplement draft for human review.', actions:[['Claim packet','packet'],['Gap finder','gap'],['Supplement draft','supplement'],['Review task','task']]},
  {title:'Xactimate / code matching', priority:'High', detail:'Map scope items to adjuster-ready lines, flag required code/compliance items, and attach photo evidence.', actions:[['Scope draft','scope'],['Estimate package','estimate'],['Supplement builder','supplement'],['Code note','note']]},
  {title:'Storm intelligence scoring', priority:'Medium', detail:'Rank neighborhoods by storm data, date of loss, hail severity, canvassing priority, and campaign performance.', actions:[['Storm campaign','storm'],['Neighbor opportunity','neighbor'],['Route','route'],['Campaign ROI','campaign']]},
  {title:'Neighbor Opportunity Radar', priority:'Medium', detail:'Create nearby opportunity list from active jobs, yard signs, referrals, and storm-hit streets.', actions:[['Neighbor opportunity','neighbor'],['Yard sign','yard'],['Referral ask','referral'],['Route','route']]},
  {title:'Rep digital business card', priority:'Medium', detail:'Shareable rep card/link for quote requests, contact save, referral ask, and review request.', actions:[['Branding setup','branding'],['Referral ask','referral'],['Review request','review'],['Message','message']]},
  {title:'Training / sales coaching assistant', priority:'Medium', detail:'Hail education, objection handling, sales scripts, photo-taking guidance, and scenario coaching.', actions:[['Training note','note'],['Coaching task','task'],['Inspection','inspection'],['Presentation','presentation']]},
  {title:'Actual-vs-estimate learning loop', priority:'High', detail:'Compare estimate to final job cost, detect misses, improve price book/scope accuracy after enough jobs.', actions:[['Estimate','estimate'],['Job costing','cost'],['Price book','price'],['Learning note','note']]},
  {title:'Company knowledge base', priority:'Medium', detail:'Searchable SOPs, pricing rules, vendor notes, install standards, documents, and Hammy-ready internal knowledge.', actions:[['Knowledge note','note'],['Provider setup','provider'],['Price rule','price'],['Training task','task']]}
];

const TAB = {door:'Prospecting',route:'Prospecting',lead:'Today',task:'Today',note:'Customers',campaign:'Marketing',message:'Customers',portal:'Customers',packet:'Claims',gap:'Claims',supplement:'Claims',scope:'Inspections',estimate:'Sales',storm:'Prospecting',neighbor:'Prospecting',yard:'Prospecting',referral:'Customers',branding:'Settings',review:'Customers',inspection:'Inspections',presentation:'Sales',cost:'Financials',price:'Settings',provider:'Integrations'};

function clickAction(action, id=''){
  const button = [...document.querySelectorAll('[data-action]')].find(el => el.dataset.action === action && (id === '' || el.dataset.id === id));
  if (!button) return false;
  button.click();
  return true;
}
function run(kind){
  if (kind === 'lead') return clickAction('lead');
  if (kind === 'portal') return clickAction('tab','Customers') && setTimeout(()=>clickAction('portal'),180);
  clickAction('tab', TAB[kind] || 'Today');
  setTimeout(()=>clickAction('new', kind), 180);
}
function card(feature){
  return `<article class="lost-feature-card ${esc(norm(feature.priority))}"><header><b>${esc(feature.title)}</b><span>${esc(feature.priority)}</span></header><p>${esc(feature.detail)}</p><div>${feature.actions.map(([label,kind])=>`<button type="button" data-lost-feature="${esc(kind)}">${esc(label)}</button>`).join('')}</div></article>`;
}
function panel(){
  return `<section id="lostFeatureRecovery" class="card lost-feature-recovery section"><p class="eyebrow">LOST FEATURE RECOVERY</p><h2>Agreed features brought back into the build list.</h2><p class="muted">Operational anchors first. UI polish later. Estimate and supplement remain the primary money workflow.</p><div class="lost-feature-grid">${FEATURES.map(card).join('')}</div></section>`;
}
function bind(root=document){
  root.querySelectorAll('[data-lost-feature]').forEach(button=>{
    if(button.dataset.bound==='1') return;
    button.dataset.bound='1';
    button.addEventListener('click',()=>run(button.dataset.lostFeature));
  });
}
function inject(){
  const page=document.querySelector('#workspacePage');
  if(!page || document.querySelector('#lostFeatureRecovery')) return;
  const title=norm(document.querySelector('.page-heading h1')?.textContent || '');
  if(!['today','reports','sales','claims','prospecting','settings'].includes(title)) return;
  page.insertAdjacentHTML(title==='reports' ? 'afterbegin' : 'beforeend', panel());
  bind(page);
}
new MutationObserver(inject).observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('DOMContentLoaded', inject);
setInterval(inject, 1500);
