const norm = value => String(value || '').toLowerCase().replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

const REMAINING_FEATURES = [
  {group:'Commercial', title:'Commercial workflow', detail:'Commercial lead, roof type, site access, decision maker, scope notes, manager review.', tab:'Sales', actions:[['Commercial opportunity','competitor'],['Site follow-up','task'],['Commercial scope note','note'],['Estimate package','estimate']]},
  {group:'People', title:'People / payroll', detail:'Rep, crew, commission, payroll note, people issue, manager follow-up.', tab:'Financials', actions:[['Commission record','commission'],['People note','note'],['Payroll follow-up','task'],['Job costing','cost']]},
  {group:'Calendar', title:'Calendar / collaboration', detail:'Next action, production schedule, adjuster meeting, job deadlines, shared team notes.', tab:'Today', actions:[['Next action','task'],['Production schedule','schedule'],['Adjuster meeting','adjuster'],['Team note','note']]},
  {group:'Migration', title:'Import / export / backup', detail:'CSV/export hub, migration checklist, data backup status, account recovery notes.', tab:'Reports', actions:[['Export checklist','note'],['Migration task','task'],['Provider setup','provider'],['Reports','tab:Reports']]},
  {group:'Offline', title:'Offline field mode', detail:'Offline-ready checklist for queued notes, photos, inspection path, and sync warnings.', tab:'Inspections', actions:[['Offline inspection note','note'],['Guided inspection','inspection'],['Photo proof checklist','scope'],['Sync follow-up','task']]},
  {group:'AI', title:'AI training / insights', detail:'AI training notice, data-quality checklist, performance-insight placeholder, model/provider setup.', tab:'Reports', actions:[['AI setup','provider'],['Data-quality task','task'],['Performance note','note'],['Reports','tab:Reports']]},
  {group:'Route', title:'Route optimization', detail:'Rep-created route, ordered stops, route optimization placeholder, door-hanger outcomes.', tab:'Prospecting', actions:[['Rep route','route'],['Door hanger','door'],['Neighbor opportunity','neighbor'],['Route optimization note','note']]},
  {group:'Payments', title:'Payments / financing', detail:'Financing/payment setup, HTTPS portal links, invoice aging, payment follow-up.', tab:'Financials', actions:[['Payment setup','provider'],['Invoice / A/R','invoice'],['Payment follow-up','task'],['Customer message','message']]},
  {group:'Suppliers', title:'Supplier ordering', detail:'Supplier setup, material order approval, delivery mismatch warning, readiness.', tab:'Production', actions:[['Supplier setup','provider'],['Material order','material_order'],['Delivery check','delivery'],['Readiness checklist','readiness']]},
  {group:'Reviews', title:'Reviews / referrals / marketing', detail:'Internal rating, public review link, referral ask, campaign ROI, neighbor growth.', tab:'Marketing', actions:[['Review request','review'],['Referral ask','referral'],['Campaign ROI','campaign'],['Neighbor opportunity','neighbor']]},
  {group:'Contracts', title:'Contract / selections handoff', detail:'Product selections, contract review task, legal/scope handoff, manager review.', tab:'Sales', actions:[['Presentation notes','presentation'],['Contract review task','task'],['Scope draft','scope'],['Estimate package','estimate']]},
  {group:'System', title:'System health / backup', detail:'Health endpoint, external connection status, smoke-test checklist, backup notes.', tab:'Reports', actions:[['System-health note','note'],['Provider setup','provider'],['Smoke-test task','task'],['Reports','tab:Reports']]}
];

const TAB_BY_KIND = {competitor:'Sales',task:'Today',note:'Customers',estimate:'Sales',commission:'Financials',cost:'Financials',schedule:'Production',adjuster:'Claims',provider:'Integrations',inspection:'Inspections',scope:'Inspections',route:'Prospecting',door:'Prospecting',neighbor:'Prospecting',invoice:'Financials',message:'Customers',material_order:'Production',delivery:'Production',readiness:'Production',review:'Customers',referral:'Customers',campaign:'Marketing',presentation:'Sales'};

function click(action, id = '') {
  const button = [...document.querySelectorAll('[data-action]')].find(el => el.dataset.action === action && (id === '' || el.dataset.id === id));
  if (!button) return false;
  button.click();
  return true;
}
function run(target) {
  if (target.startsWith('tab:')) return click('tab', target.slice(4));
  click('tab', TAB_BY_KIND[target] || 'Today');
  setTimeout(() => click('new', target), 170);
}
function featureCard(feature) {
  return `<article class="remaining-feature-card"><div><b>${esc(feature.title)}</b><span>${esc(feature.group)}</span></div><p>${esc(feature.detail)}</p><div>${feature.actions.map(([label,target]) => `<button type="button" data-remaining-target="${esc(target)}">${esc(label)}</button>`).join('')}</div></article>`;
}
function panel() {
  return `<section id="remainingFeaturePack" class="card remaining-feature-pack section"><p class="eyebrow">APPROVED REMAINING FEATURES</p><h2>Remaining approved features are anchored.</h2><p class="muted">Provider-backed features show setup paths until credentials/subscriptions are connected. Human approval stays required for approvals, pricing, supplements, payments, contracts, and external sends.</p><div class="remaining-feature-grid">${REMAINING_FEATURES.map(featureCard).join('')}</div></section>`;
}
function bind(root=document) {
  root.querySelectorAll('[data-remaining-target]').forEach(button => {
    if (button.dataset.bound === '1') return;
    button.dataset.bound = '1';
    button.addEventListener('click', () => run(button.dataset.remainingTarget));
  });
}
function inject() {
  const page = document.querySelector('#workspacePage');
  if (!page || document.querySelector('#remainingFeaturePack')) return;
  const title = norm(document.querySelector('.page-heading h1')?.textContent || '');
  if (!['today','reports','settings','integrations'].includes(title)) return;
  page.insertAdjacentHTML(title === 'today' ? 'afterbegin' : 'beforeend', panel());
  bind(page);
}
new MutationObserver(inject).observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('DOMContentLoaded', inject);
setInterval(inject, 1400);
