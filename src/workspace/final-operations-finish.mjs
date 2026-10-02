const normalize = value => String(value || '')
  .toLowerCase()
  .replace(/[^a-z0-9\s]/g, ' ')
  .replace(/\s+/g, ' ')
  .trim();

const esc = value => String(value ?? '').replace(/[&<>"']/g, character => ({
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;'
}[character]));

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
let formLock = false;
let lastSignature = '';

function actionButton(action, id = '') {
  return [...document.querySelectorAll('[data-action]')].find(button => {
    return button.dataset.action === action && (id === '' || button.dataset.id === id);
  });
}

function clickAction(action, id = '') {
  const button = actionButton(action, id);
  if (!button) return false;
  button.click();
  return true;
}

function currentTabTitle() {
  return document.querySelector('.page-heading h1')?.textContent?.trim() || '';
}

function currentJob() {
  const selected = document.querySelector('#jobSelect option:checked');
  return selected?.textContent?.trim() || 'No active job';
}

function installGlobalSubmitGuard() {
  if (window.__hamriqSubmitGuardInstalled) return;
  window.__hamriqSubmitGuardInstalled = true;
  document.addEventListener('submit', event => {
    const form = event.target;
    if (!form?.closest?.('.modal')) return;
    if (formLock) {
      event.preventDefault();
      event.stopImmediatePropagation();
      return false;
    }
    formLock = true;
    const submitters = form.querySelectorAll('button[type="submit"], .btn.accent');
    submitters.forEach(button => {
      button.dataset.originalText = button.textContent;
      button.disabled = true;
      button.textContent = 'Saving…';
    });
    setTimeout(() => {
      formLock = false;
      submitters.forEach(button => {
        button.disabled = false;
        if (button.dataset.originalText) button.textContent = button.dataset.originalText;
      });
    }, 1800);
  }, true);
}

function installOfflineStatus() {
  if (document.querySelector('#hamriqConnectionStatus')) return;
  const status = document.createElement('div');
  status.id = 'hamriqConnectionStatus';
  status.className = navigator.onLine ? 'hamriq-net online' : 'hamriq-net offline';
  status.textContent = navigator.onLine ? 'Online' : 'Offline — changes may not save until connected';
  document.body.appendChild(status);
  const update = () => {
    status.className = navigator.onLine ? 'hamriq-net online' : 'hamriq-net offline';
    status.textContent = navigator.onLine ? 'Online' : 'Offline — changes may not save until connected';
  };
  window.addEventListener('online', update);
  window.addEventListener('offline', update);
}

function runShortcut(kind) {
  const tabByKind = {
    lead: 'Today', note: 'Customers', task: 'Today', door: 'Prospecting', route: 'Prospecting',
    inspection: 'Inspections', scope: 'Inspections', measurement: 'Inspections', estimate: 'Sales', presentation: 'Sales',
    claim: 'Claims', adjuster: 'Claims', gap: 'Claims', supplement: 'Claims', packet: 'Claims',
    message: 'Customers', referral: 'Customers', review: 'Customers', material_order: 'Production', delivery: 'Production',
    permit: 'Production', schedule: 'Production', readiness: 'Production', warranty: 'Production', cost: 'Financials',
    invoice: 'Financials', commission: 'Financials', campaign: 'Marketing', provider: 'Integrations', price: 'Settings', branding: 'Settings'
  };
  if (kind === 'hammy') return clickAction('tab', 'Hammy');
  if (kind === 'portal') return clickAction('tab', 'Customers') && setTimeout(() => clickAction('portal'), 200);
  if (kind === 'approvals') return clickAction('tab', 'Approvals');
  if (kind === 'reports') return clickAction('tab', 'Reports');
  if (kind === 'lead') return clickAction('lead');
  if (tabByKind[kind]) clickAction('tab', tabByKind[kind]);
  setTimeout(() => clickAction('new', kind), 160);
}

function completionPanel() {
  return `<section id="hamriqCompletionPanel" class="card hamriq-completion section">
    <div class="hamriq-completion-head">
      <div>
        <p class="eyebrow">FINAL OPERATING LAYER</p>
        <h2>Finish every roofing workflow from one place.</h2>
        <p class="muted">Current job: <strong>${esc(currentJob())}</strong></p>
      </div>
      <button type="button" class="btn secondary" data-finish-action="export-page">Export visible page</button>
    </div>
    <div class="hamriq-finish-grid">
      <article>
        <h3>Sales flow</h3>
        <button data-finish-action="lead">New lead</button>
        <button data-finish-action="task">Follow-up</button>
        <button data-finish-action="inspection">Inspection</button>
        <button data-finish-action="scope">Scope draft</button>
        <button data-finish-action="measurement">Measurement request</button>
        <button data-finish-action="estimate">Estimate package</button>
        <button data-finish-action="presentation">Presentation notes</button>
      </article>
      <article>
        <h3>Insurance flow</h3>
        <button data-finish-action="claim">Claim timeline</button>
        <button data-finish-action="adjuster">Adjuster prep</button>
        <button data-finish-action="gap">Carrier gap finder</button>
        <button data-finish-action="supplement">Supplement draft</button>
        <button data-finish-action="packet">Claim packet</button>
      </article>
      <article>
        <h3>Homeowner flow</h3>
        <button data-finish-action="note">Property note</button>
        <button data-finish-action="message">Message draft</button>
        <button data-finish-action="referral">Referral ask</button>
        <button data-finish-action="review">Review request</button>
        <button data-finish-action="portal">Portal link</button>
      </article>
      <article>
        <h3>Production flow</h3>
        <button data-finish-action="material_order">Material order</button>
        <button data-finish-action="delivery">Delivery check</button>
        <button data-finish-action="permit">Permit</button>
        <button data-finish-action="schedule">Crew schedule</button>
        <button data-finish-action="readiness">Readiness</button>
        <button data-finish-action="warranty">Warranty</button>
      </article>
      <article>
        <h3>Manager flow</h3>
        <button data-finish-action="approvals">Approval Center</button>
        <button data-finish-action="cost">Job costing</button>
        <button data-finish-action="invoice">Invoice / A/R</button>
        <button data-finish-action="commission">Commission</button>
        <button data-finish-action="campaign">Campaign ROI</button>
        <button data-finish-action="reports">Reports</button>
      </article>
      <article>
        <h3>System setup</h3>
        <button data-finish-action="provider">Provider setup</button>
        <button data-finish-action="price">Price book</button>
        <button data-finish-action="branding">Branding</button>
        <button data-finish-action="hammy">Hammy</button>
      </article>
    </div>
  </section>`;
}

function qaPanel() {
  const checks = [
    ['Lead capture', 'Create lead, lead source, assignment'],
    ['Hammy action', 'Match/create customer, one note, one follow-up'],
    ['Inspection', 'Checklist, scope draft, measurement request'],
    ['Sales', 'Good/Better/Best estimate and presentation notes'],
    ['Claims', 'Claim timeline, gap finder, supplement draft, packet'],
    ['Homeowner', 'Message, referral, review, portal'],
    ['Production', 'Material, delivery, readiness, warranty'],
    ['Manager', 'Approvals, financials, reports, provider setup']
  ];
  return `<section id="hamriqQaPanel" class="card hamriq-qa section">
    <p class="eyebrow">ONE-DEPLOY QA CHECKLIST</p>
    <h2>Run this once after the final deployment.</h2>
    <div class="hamriq-qa-grid">
      ${checks.map(([title, body]) => `<label><input type="checkbox"> <span><b>${esc(title)}</b><small>${esc(body)}</small></span></label>`).join('')}
    </div>
    <p class="muted mini">This checklist is local to the browser. It is for the final smoke test after deployment.</p>
  </section>`;
}

function exportVisiblePage() {
  const payload = {
    exported_at: new Date().toISOString(),
    page: currentTabTitle(),
    active_job: currentJob(),
    visible_text: document.querySelector('#workspacePage')?.innerText?.slice(0, 20000) || ''
  };
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `hamriq-${normalize(payload.page || 'workspace') || 'workspace'}-${Date.now()}.json`;
  document.body.appendChild(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 5000);
}

function bindFinishPanel(container = document) {
  container.querySelectorAll('[data-finish-action]').forEach(button => {
    if (button.dataset.bound === '1') return;
    button.dataset.bound = '1';
    button.addEventListener('click', () => {
      const action = button.dataset.finishAction;
      if (action === 'export-page') return exportVisiblePage();
      runShortcut(action);
    });
  });
}

function injectPanels() {
  const workspace = document.querySelector('#app .workspace');
  const page = document.querySelector('#workspacePage');
  if (!workspace || !page) return;
  const signature = `${currentTabTitle()}|${currentJob()}`;
  if (signature === lastSignature && document.querySelector('#hamriqCompletionPanel')) return;
  lastSignature = signature;

  const title = normalize(currentTabTitle());
  if (!document.querySelector('#hamriqCompletionPanel') && ['today', 'customers', 'reports'].includes(title)) {
    page.insertAdjacentHTML('afterbegin', completionPanel());
  }
  if (!document.querySelector('#hamriqQaPanel') && ['reports', 'today'].includes(title)) {
    page.insertAdjacentHTML('beforeend', qaPanel());
  }
  bindFinishPanel(page);
}

function enhance() {
  installGlobalSubmitGuard();
  installOfflineStatus();
  injectPanels();
}

const observer = new MutationObserver(() => enhance());
observer.observe(document.documentElement, { childList: true, subtree: true });
window.addEventListener('DOMContentLoaded', enhance);
setInterval(enhance, 1200);
