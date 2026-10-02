const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const norm = value => String(value || '').toLowerCase().replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();

const ADAPTERS = [
  {key:'measurement', title:'Measurement providers', providers:['Native HAMRIQ','EagleView','Hover'], action:'measurement', tab:'Inspections', needs:['provider account','manager approval','order callback/import']},
  {key:'storm', title:'Storm data', providers:['HailTrace','Hail Recon'], action:'storm', tab:'Prospecting', needs:['subscription','API/import path','campaign mapping']},
  {key:'accounting', title:'Accounting sync', providers:['QuickBooks'], action:'provider', tab:'Integrations', needs:['OAuth app','chart/account mapping','sync log']},
  {key:'supplier', title:'Supplier ordering', providers:['ABC Supply','SRS','Beacon','Other supplier'], action:'material_order', tab:'Production', needs:['supplier account','order submit adapter','delivery confirmation']},
  {key:'messages', title:'SMS / email delivery', providers:['Twilio','SendGrid','Postmark','Other'], action:'message', tab:'Customers', needs:['sender verification','template approval','delivery log']},
  {key:'payments', title:'Payments / financing', providers:['Stripe','Financing portal','Payment portal'], action:'invoice', tab:'Financials', needs:['merchant account','secure link','payment status webhook']},
  {key:'ai', title:'AI analysis', providers:['OpenAI'], action:'provider', tab:'Integrations', needs:['server key','model setting','review queue']},
  {key:'route', title:'Route optimization', providers:['Mapbox','Google Maps','Manual route'], action:'route', tab:'Prospecting', needs:['geocoder','optimizer','ordered stop save']},
  {key:'pdf', title:'Carrier PDF extraction', providers:['Document parser'], action:'packet', tab:'Claims', needs:['upload parser','line-item extraction','human review']},
  {key:'backup', title:'Backup / export', providers:['CSV export','JSON page export','Database backup'], action:'task', tab:'Reports', needs:['backup schedule','restore plan','admin audit']}
];

function clickAction(action, id = '') {
  const button = [...document.querySelectorAll('[data-action]')].find(el => el.dataset.action === action && (id === '' || el.dataset.id === id));
  if (!button) return false;
  button.click();
  return true;
}

function launch(adapter) {
  clickAction('tab', adapter.tab);
  setTimeout(() => clickAction(adapter.action === 'provider' ? 'new' : 'new', adapter.action), 180);
}

function card(adapter) {
  return `<article class="provider-adapter-card"><div><b>${esc(adapter.title)}</b><span>${esc(adapter.providers.join(' / '))}</span></div><ul>${adapter.needs.map(item => `<li>${esc(item)}</li>`).join('')}</ul><button type="button" data-provider-adapter="${esc(adapter.key)}">Open setup/action</button></article>`;
}

function panel() {
  return `<section id="providerAdapterHub" class="card provider-adapter-hub section"><p class="eyebrow">CONNECTION-READY ADAPTERS</p><h2>External services are ready to connect without faking live integrations.</h2><p class="muted">Each provider-backed feature now has a real setup/action path. Live ordering, sync, send, payment, routing, parsing, or AI execution starts only after credentials/subscriptions are connected.</p><div class="provider-adapter-grid">${ADAPTERS.map(card).join('')}</div></section>`;
}

function bind(root=document) {
  root.querySelectorAll('[data-provider-adapter]').forEach(button => {
    if (button.dataset.bound === '1') return;
    button.dataset.bound = '1';
    button.addEventListener('click', () => {
      const adapter = ADAPTERS.find(item => item.key === button.dataset.providerAdapter);
      if (adapter) launch(adapter);
    });
  });
}

function inject() {
  const page = document.querySelector('#workspacePage');
  if (!page || document.querySelector('#providerAdapterHub')) return;
  const title = norm(document.querySelector('.page-heading h1')?.textContent || '');
  if (!['integrations','reports','settings'].includes(title)) return;
  page.insertAdjacentHTML('afterbegin', panel());
  bind(page);
}

new MutationObserver(inject).observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('DOMContentLoaded', inject);
setInterval(inject, 1500);
