const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const norm = value => String(value || '').toLowerCase().replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();

const FEATURES = [
  {
    title: 'GPS Knock Mode',
    badge: 'Field',
    body: 'Door outcome flow: GPS/address capture, interested/not interested/do-not-follow-up, door hanger placed, and follow-up date path.',
    actions: [['Log door visit','door'], ['Create lead','lead'], ['Follow-up task','task'], ['Route','route']]
  },
  {
    title: 'Lead Routing Inbox',
    badge: 'Manager',
    body: 'Manager triage path for inbound leads: assign, reassign, mark source/urgency, and keep reps limited to their own work.',
    actions: [['New lead','lead'], ['Assign follow-up','task'], ['Lead source campaign','campaign'], ['Manager review','risk']]
  },
  {
    title: 'Neighbor Radar',
    badge: 'Growth',
    body: 'Turns one damaged home into nearby opportunities: neighbors, yard signs, referrals, and street-level canvassing notes.',
    actions: [['Neighbor opportunity','neighbor'], ['Yard sign','yard'], ['Referral ask','referral'], ['Rep route','route']]
  },
  {
    title: 'Rep Digital Business Card',
    badge: 'Sales',
    body: 'Shareable rep card placeholder: rep identity, phone, review/referral link, quote request path, and homeowner save/contact notes.',
    actions: [['Business card note','note'], ['Homeowner message','message'], ['Referral ask','referral'], ['Review request','review']]
  },
  {
    title: 'Sales Training Coach',
    badge: 'Coach',
    body: 'Scenario coaching for objections, hail education, insurance explanation, door pitch, and kitchen-table presentation notes.',
    actions: [['Objection note','note'], ['Presentation notes','presentation'], ['Training task','task'], ['At-risk save desk','risk']]
  }
];

const TAB = {door:'Prospecting',lead:'Today',task:'Today',route:'Prospecting',campaign:'Marketing',risk:'Sales',neighbor:'Prospecting',yard:'Prospecting',referral:'Customers',note:'Customers',message:'Customers',review:'Customers',presentation:'Sales'};

function clickAction(action, id = '') {
  const el = [...document.querySelectorAll('[data-action]')].find(button => button.dataset.action === action && (id === '' || button.dataset.id === id));
  if (!el) return false;
  el.click();
  return true;
}
function launch(kind) {
  if (kind === 'lead') return clickAction('lead');
  clickAction('tab', TAB[kind] || 'Today');
  setTimeout(() => clickAction('new', kind), 180);
}
function card(feature) {
  return `<article class="field-intel-card"><div><b>${esc(feature.title)}</b><span>${esc(feature.badge)}</span></div><p>${esc(feature.body)}</p><div class="field-intel-actions">${feature.actions.map(([label,kind]) => `<button type="button" data-field-intel-kind="${esc(kind)}">${esc(label)}</button>`).join('')}</div></article>`;
}
function panel() {
  return `<section id="fieldSalesIntelligence" class="card field-intel section"><p class="eyebrow">FIELD SALES INTELLIGENCE</p><h2>Recovered day-one sales tools are back in the build.</h2><p class="muted">These workflows keep prospecting, routing, neighbor growth, rep identity, and sales coaching connected to the main CRM.</p><div class="field-intel-grid">${FEATURES.map(card).join('')}</div></section>`;
}
function bind(root=document) {
  root.querySelectorAll('[data-field-intel-kind]').forEach(button => {
    if (button.dataset.bound === '1') return;
    button.dataset.bound = '1';
    button.addEventListener('click', () => launch(button.dataset.fieldIntelKind));
  });
}
function inject() {
  const page = document.querySelector('#workspacePage');
  if (!page || document.querySelector('#fieldSalesIntelligence')) return;
  const title = norm(document.querySelector('.page-heading h1')?.textContent || '');
  if (!['today','prospecting','sales','marketing','customers','reports'].includes(title)) return;
  page.insertAdjacentHTML(['today','prospecting'].includes(title) ? 'afterbegin' : 'beforeend', panel());
  bind(page);
}
new MutationObserver(inject).observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('DOMContentLoaded', inject);
setInterval(inject, 1600);
