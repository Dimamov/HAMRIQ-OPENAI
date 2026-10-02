const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const norm = value => String(value || '').toLowerCase().replace(/[^a-z0-9\s]/g,' ').replace(/\s+/g,' ').trim();

const AREAS = [
  ['Money workflow','Automated estimate, price book, supplement, claim packet','active'],
  ['Field sales','GPS knock mode, route, neighbor radar, rep card, coaching','active'],
  ['Customer ops','Homeowner status, AI receptionist intake, messages, reviews','active'],
  ['Production','Materials, delivery, permits, crews, weather, readiness, warranty','active'],
  ['Management','Approvals, finance, commissions, reports, lead routing','active'],
  ['Integrations','EagleView, Hover, HailTrace, Hail Recon, QuickBooks, SMS, payments, AI','setup'],
  ['Learning loop','Actual vs estimate tracking and data quality checklist','active'],
  ['Safety gates','Human review for pricing, supplements, contracts, external sends','active']
];

const ROADMAP = [
  'Connect provider credentials/subscriptions for live external actions.',
  'Replace setup-gated adapters with live API calls one provider at a time.',
  'Train AI photo/scope review on company-approved examples before auto-suggesting damage patterns.',
  'Build PUT OUT FIRES fire-extinguisher button using FIRE urgency task filter.',
  'Turn exported estimate/supplement calculations into branded PDF output.'
];

function card() {
  return `<section id="hamriqCompletenessDashboard" class="card completeness-dashboard section">
    <p class="eyebrow">COMPLETION DASHBOARD</p>
    <h2>Approved app build status</h2>
    <p class="muted">This keeps the big feature set visible so it does not get lost again after migrations or loader changes.</p>
    <div class="completeness-grid">
      ${AREAS.map(([title, detail, status]) => `<article class="${esc(status)}"><div><b>${esc(title)}</b><span>${status === 'setup' ? 'SETUP GATED' : 'ACTIVE'}</span></div><p>${esc(detail)}</p></article>`).join('')}
    </div>
    <details class="completeness-roadmap"><summary>Known next-depth work</summary><ul>${ROADMAP.map(item => `<li>${esc(item)}</li>`).join('')}</ul></details>
  </section>`;
}

function inject() {
  const page = document.querySelector('#workspacePage');
  if (!page || document.querySelector('#hamriqCompletenessDashboard')) return;
  const title = norm(document.querySelector('.page-heading h1')?.textContent || '');
  if (!['today','reports','settings','integrations','approvals'].includes(title)) return;
  page.insertAdjacentHTML(title === 'reports' ? 'afterbegin' : 'beforeend', card());
}

new MutationObserver(inject).observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('DOMContentLoaded', inject);
setInterval(inject, 1600);
