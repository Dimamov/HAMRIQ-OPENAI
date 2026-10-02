const normalize = value => String(value || '').toLowerCase().replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();
const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

const APPROVED_FEATURES = [
  ['lead_source_creation','Lead source at creation','Rep marks source when a lead is created.','Core CRM','ready'],
  ['door_hanger_outcome','Door hanger outcome','Prospecting visit supports Door Hanger Placed.','Prospecting','ready'],
  ['rep_routes','Rep-created routes','Reps can create routes and stops.','Prospecting','ready'],
  ['storm_data_integrations','Storm data integrations','HailTrace/Hail Recon setup slot with subscription notice.','Integrations','setup-required'],
  ['ai_performance_insights','AI performance insights','Requires company training/data; improves with more data.','Reports','training-required'],
  ['measurement_provider_fallback','Measurement fallback','Internal first; EagleView/Hover fallback with manager approval.','Inspections','setup-required'],
  ['manager_pricing','Manager pricing','Managers control price book; reps cannot change master pricing.','Settings','ready'],
  ['review_funnel','Review funnel','Internal 4–5 star path to public review links.','Customers','ready'],
  ['approval_center','Approval Center','Central approval queue for measurement, estimates, supplements, materials, AI drafts.','Approvals','ready'],
  ['production_control','Production Control','Materials, delivery, permits, crews, weather, readiness, warranty.','Production','ready'],
  ['billing_finance','Billing + finance','Job costing, invoices, aging, commissions, ROI.','Financials','ready'],
  ['photo_ai_workflow','Photo AI workflow','Photo proof path; AI reports clear hail/collateral signs only after connection.','Inspections','setup-required'],
  ['hammy_voice_capture','Hammy voice/action capture','Typed/voice-like action capture creates/selects customer, note, follow-up.','Hammy','ready'],
  ['commercial_workflow','Commercial workflow','Commercial inspection/production placeholders and manager review path.','Sales','ready'],
  ['people_payroll','People/payroll','People/payroll management placeholder for managers.','Financials','ready'],
  ['collaboration_calendar','Collaboration/calendar','Next actions and schedule records anchor calendar workflow.','Today','ready'],
  ['marketing_growth','Marketing growth','Campaign ROI, review funnel, referrals, neighbor opportunities.','Marketing','ready'],
  ['backup_system_health','Backup/system health','Health endpoint, export visible page, smoke-test checklist.','Reports','ready']
];

const QUICK_ACTIONS = {
  'Core CRM':['lead','note','task','message'],
  'Prospecting':['door','route','neighbor','yard'],
  'Inspections':['inspection','scope','measurement'],
  'Claims':['claim','gap','supplement','packet'],
  'Production':['material_order','delivery','permit','schedule','readiness','warranty'],
  'Financials':['cost','invoice','commission'],
  'Marketing':['campaign','referral','review'],
  'Settings':['price','branding','provider']
};

const TAB = {lead:'Today',note:'Customers',task:'Today',message:'Customers',door:'Prospecting',route:'Prospecting',neighbor:'Prospecting',yard:'Prospecting',inspection:'Inspections',scope:'Inspections',measurement:'Inspections',claim:'Claims',gap:'Claims',supplement:'Claims',packet:'Claims',material_order:'Production',delivery:'Production',permit:'Production',schedule:'Production',readiness:'Production',warranty:'Production',cost:'Financials',invoice:'Financials',commission:'Financials',campaign:'Marketing',referral:'Customers',review:'Customers',price:'Settings',branding:'Settings',provider:'Integrations'};

function clickAction(action, id = '') {
  const button = [...document.querySelectorAll('[data-action]')].find(el => el.dataset.action === action && (id === '' || el.dataset.id === id));
  if (!button) return false;
  button.click();
  return true;
}
function runKind(kind) {
  if (kind === 'lead') return clickAction('lead');
  clickAction('tab', TAB[kind] || 'Today');
  setTimeout(() => clickAction('new', kind), 160);
}
function statusPill(status) {
  const label = status === 'ready' ? 'Ready' : status === 'setup-required' ? 'Setup required' : 'Training required';
  return `<span class="approved-status ${esc(status)}">${esc(label)}</span>`;
}
function panel() {
  const groups = APPROVED_FEATURES.reduce((map, item) => {
    (map[item[3]] ||= []).push(item);
    return map;
  }, {});
  return `<section id="approvedCompletionMatrix" class="card approved-completion section">
    <p class="eyebrow">APPROVED FEATURE MATRIX</p>
    <h2>Approved features are now anchored in the app.</h2>
    <p class="muted">External services still require provider credentials/subscriptions. Consequential actions remain human-reviewed.</p>
    <div class="approved-completion-grid">
      ${Object.entries(groups).map(([group, items]) => `<article>
        <h3>${esc(group)}</h3>
        ${items.map(([key,title,desc,,status]) => `<div class="approved-item"><div><b>${esc(title)}</b><small>${esc(desc)}</small></div>${statusPill(status)}</div>`).join('')}
        <div class="approved-actions">${(QUICK_ACTIONS[group] || []).map(kind => `<button data-approved-kind="${esc(kind)}">${esc(kind.replaceAll('_',' '))}</button>`).join('')}</div>
      </article>`).join('')}
    </div>
  </section>`;
}
function bind(root=document) {
  root.querySelectorAll('[data-approved-kind]').forEach(button => {
    if (button.dataset.bound === '1') return;
    button.dataset.bound = '1';
    button.addEventListener('click', () => runKind(button.dataset.approvedKind));
  });
}
function inject() {
  const page = document.querySelector('#workspacePage');
  if (!page || document.querySelector('#approvedCompletionMatrix')) return;
  const title = normalize(document.querySelector('.page-heading h1')?.textContent || '');
  if (!['today','reports','settings','integrations'].includes(title)) return;
  page.insertAdjacentHTML(title === 'reports' ? 'afterbegin' : 'beforeend', panel());
  bind(page);
}
const observer = new MutationObserver(inject);
observer.observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('DOMContentLoaded',inject);
setInterval(inject,1400);
