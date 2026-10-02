const esc = value => String(value ?? '').replace(/[&<>"']/g, character => ({
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;'
}[character]));

const normalize = value => String(value || '')
  .toLowerCase()
  .replace(/[^a-z0-9\s]/g, ' ')
  .replace(/\s+/g, ' ')
  .trim();

const PACKS = [
  {
    group: 'Sales engine',
    items: [
      ['lead', 'Lead source capture', 'Required lead source at creation; rep-owned leads stay assigned to creator.'],
      ['task', '3-day carrier follow-up', 'Create follow-up after initial task completion or claim activity.'],
      ['estimate', 'Good / Better / Best', 'Packages route through manager pricing and approval.'],
      ['presentation', 'Product selection handoff', 'Record homeowner selection, questions, and contract-review next action.'],
      ['message', 'Homeowner communication history', 'Text/email/call notes stored against the job timeline.'],
      ['review', 'Review funnel', 'Internal rating first; 4–5 stars can move to public review link.']
    ]
  },
  {
    group: 'Prospecting',
    items: [
      ['door', 'Door hanger placed', 'Rep can record Door Hanger Placed and canvassing outcome.'],
      ['route', 'Rep-created routes', 'Rep can create route/stops; manager can review activity.'],
      ['storm', 'Storm Mode', 'Campaign area, loss date, severity, and team instructions.'],
      ['neighbor', 'Neighbor radar', 'Neighbor opportunities captured manually until geospatial layer is connected.'],
      ['yard', 'Yard sign tracking', 'Placement date/location/referrals tracked.']
    ]
  },
  {
    group: 'Inspection + measurement',
    items: [
      ['inspection', 'Guided inspection', 'Structure/elevation checklist with collateral and soft-metal proof.'],
      ['scope', 'Scope draft', 'Human-reviewed scope draft with evidence references.'],
      ['measurement', 'Native / EagleView / Hover fallback', 'Internal first; external order path needs provider setup and manager approval.'],
      ['provider', 'Photo AI setup', 'AI photo analysis requires server key/model and never fabricates results.'],
      ['task', 'Carrier PDF extraction pending', 'Track PDF extraction work until parser is connected.']
    ]
  },
  {
    group: 'Claims + supplement',
    items: [
      ['claim', 'Claim timeline', 'Milestones, due dates, and auto-chaser follow-ups.'],
      ['adjuster', 'Adjuster meeting prep', 'Questions, disputed items, and evidence checklist.'],
      ['gap', 'Carrier estimate gap finder', 'Compares expected lines to carrier lines.'],
      ['supplement', 'Supplement builder', 'Drafts evidence-backed supplement for human review.'],
      ['packet', 'Claim packet', 'Manifest of reviewed content and evidence references.'],
      ['depreciation', 'Depreciation recovery', 'Recoverable depreciation amount, deadline, and requirements.']
    ]
  },
  {
    group: 'Production',
    items: [
      ['material_order', 'Material orders', 'Supplier/product/color/quantity with approval workflow.'],
      ['delivery', 'Delivery mismatch check', 'Compare delivered materials to order.'],
      ['permit', 'Permit status', 'Municipality, status, deadline, and requirements.'],
      ['schedule', 'Crew scheduling', 'Crew start/end with conflict warnings.'],
      ['weather', 'Weather holds', 'Weather-risk hold record.'],
      ['readiness', 'Readiness checklist', 'Contract, materials, permit, crew, access, weather.'],
      ['warranty', 'Warranty registration', 'Manufacturer, registration reference, deadline, status.']
    ]
  },
  {
    group: 'Finance + management',
    items: [
      ['cost', 'Job costing', 'Materials, labor, other cost, revenue, and profit.'],
      ['invoice', 'Invoices / A/R aging', 'Invoice amount, paid amount, due date, and aging.'],
      ['commission', 'Commission tracking', 'Rep, basis, rate, and paid/earned status.'],
      ['campaign', 'Campaign ROI', 'Campaign spend, dates, and lead source notes.'],
      ['price', 'Manager price book', 'Managers control pricing; reps cannot edit master pricing.'],
      ['provider', 'QuickBooks / supplier / SMS / financing', 'Connection slots with subscription and credential notices.']
    ]
  },
  {
    group: 'Systems',
    items: [
      ['provider', 'External integrations', 'Provider setup state, account reference, and secure URL only.'],
      ['task', 'Import/export', 'Track migration/export request and backup workflow.'],
      ['task', 'Offline sync pending', 'Track offline sync as a required system task.'],
      ['task', 'Granular roles pending', 'Track custom role provisioning beyond owner/manager/rep.'],
      ['task', 'Commercial workflow', 'Track commercial-specific scope/production requirements.'],
      ['task', 'People/payroll', 'Track people/payroll setup and manager workflow.']
    ]
  }
];

const TAB_BY_KIND = {
  lead: 'Today', task: 'Today', note: 'Customers', message: 'Customers', review: 'Customers', referral: 'Customers',
  door: 'Prospecting', route: 'Prospecting', storm: 'Prospecting', neighbor: 'Prospecting', yard: 'Prospecting', campaign: 'Marketing',
  inspection: 'Inspections', scope: 'Inspections', measurement: 'Inspections',
  claim: 'Claims', adjuster: 'Claims', gap: 'Claims', supplement: 'Claims', packet: 'Claims', depreciation: 'Claims',
  estimate: 'Sales', presentation: 'Sales',
  material_order: 'Production', delivery: 'Production', permit: 'Production', schedule: 'Production', weather: 'Production', readiness: 'Production', warranty: 'Production',
  cost: 'Financials', invoice: 'Financials', commission: 'Financials', price: 'Settings', branding: 'Settings', provider: 'Integrations'
};

function clickAction(action, id = '') {
  const element = [...document.querySelectorAll('[data-action]')].find(button => button.dataset.action === action && (id === '' || button.dataset.id === id));
  if (!element) return false;
  element.click();
  return true;
}

function launch(kind) {
  if (kind === 'lead') return clickAction('lead');
  clickAction('tab', TAB_BY_KIND[kind] || 'Today');
  setTimeout(() => clickAction('new', kind), 180);
}

function html() {
  return `<section id="approvedFunctionalityPack" class="card approved-functionality section">
    <p class="eyebrow">APPROVED FUNCTIONALITY PACK</p>
    <h2>All approved feature areas are functionally anchored.</h2>
    <p class="muted">Provider-backed features open setup/approval workflows until real subscriptions, credentials, or APIs are connected.</p>
    <div class="approved-pack-grid">
      ${PACKS.map(pack => `<article class="approved-pack-card">
        <h3>${esc(pack.group)}</h3>
        ${pack.items.map(([kind, title, description]) => `<button type="button" data-approved-pack-kind="${esc(kind)}">
          <span><b>${esc(title)}</b><small>${esc(description)}</small></span><em>${esc((TAB_BY_KIND[kind] || 'Today'))}</em>
        </button>`).join('')}
      </article>`).join('')}
    </div>
  </section>`;
}

function bind(root = document) {
  root.querySelectorAll('[data-approved-pack-kind]').forEach(button => {
    if (button.dataset.bound === '1') return;
    button.dataset.bound = '1';
    button.addEventListener('click', () => launch(button.dataset.approvedPackKind));
  });
}

function inject() {
  const page = document.querySelector('#workspacePage');
  const heading = normalize(document.querySelector('.page-heading h1')?.textContent || '');
  if (!page || document.querySelector('#approvedFunctionalityPack')) return;
  if (!['today','reports','integrations','settings','approvals'].includes(heading)) return;
  page.insertAdjacentHTML(heading === 'reports' ? 'afterbegin' : 'beforeend', html());
  bind(page);
}

const observer = new MutationObserver(inject);
observer.observe(document.documentElement, { childList: true, subtree: true });
window.addEventListener('DOMContentLoaded', inject);
setInterval(inject, 1600);
