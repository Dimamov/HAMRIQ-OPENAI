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

const WORKFLOWS = {
  lead: ['lead', ''],
  note: ['new', 'note'],
  task: ['new', 'task'],
  door: ['new', 'door'],
  route: ['new', 'route'],
  inspection: ['new', 'inspection'],
  scope: ['new', 'scope'],
  measurement: ['new', 'measurement'],
  estimate: ['new', 'estimate'],
  presentation: ['new', 'presentation'],
  claim: ['new', 'claim'],
  adjuster: ['new', 'adjuster'],
  gap: ['new', 'gap'],
  supplement: ['new', 'supplement'],
  message: ['new', 'message'],
  referral: ['new', 'referral'],
  review: ['new', 'review'],
  material: ['new', 'material_order'],
  delivery: ['new', 'delivery'],
  readiness: ['new', 'readiness'],
  warranty: ['new', 'warranty'],
  invoice: ['new', 'invoice'],
  cost: ['new', 'cost'],
  provider: ['new', 'provider'],
  price: ['new', 'price'],
  branding: ['new', 'branding']
};

const TAB_FOR_WORKFLOW = {
  note: 'Customers',
  task: 'Today',
  door: 'Prospecting',
  route: 'Prospecting',
  inspection: 'Inspections',
  scope: 'Inspections',
  measurement: 'Inspections',
  estimate: 'Sales',
  presentation: 'Sales',
  claim: 'Claims',
  adjuster: 'Claims',
  gap: 'Claims',
  supplement: 'Claims',
  message: 'Customers',
  referral: 'Customers',
  review: 'Customers',
  material: 'Production',
  delivery: 'Production',
  readiness: 'Production',
  warranty: 'Production',
  invoice: 'Financials',
  cost: 'Financials',
  provider: 'Integrations',
  price: 'Settings',
  branding: 'Settings'
};

let lastEnhance = '';
let runningAction = false;

function currentTitle() {
  return normalize(document.querySelector('.page-heading h1')?.textContent || '');
}

function currentJobLabel() {
  return document.querySelector('#jobSelect option:checked')?.textContent?.trim() || 'No job selected';
}

function isManagerView() {
  return normalize(document.querySelector('.page-heading .eyebrow')?.textContent || '').includes('owner') ||
    normalize(document.querySelector('.page-heading .eyebrow')?.textContent || '').includes('manager');
}

function findAction(action, id = '') {
  return [...document.querySelectorAll('[data-action]')].find(button => {
    return button.dataset.action === action && (id === '' || button.dataset.id === id);
  });
}

function clickAction(action, id = '') {
  const button = findAction(action, id);
  if (!button) return false;
  button.click();
  return true;
}

function openTab(tab) {
  return clickAction('tab', tab);
}

function executeWorkflow(key) {
  if (runningAction) return;
  runningAction = true;
  const pair = WORKFLOWS[key];
  if (!pair) {
    runningAction = false;
    return;
  }
  const [action, id] = pair;
  if (key !== 'lead' && TAB_FOR_WORKFLOW[key]) openTab(TAB_FOR_WORKFLOW[key]);
  window.setTimeout(() => {
    if (!clickAction(action, id)) {
      const fallback = TAB_FOR_WORKFLOW[key] || 'Today';
      openTab(fallback);
      window.setTimeout(() => clickAction(action, id), 180);
    }
    window.setTimeout(() => { runningAction = false; }, 700);
  }, 160);
}

function countCards() {
  const rows = [...document.querySelectorAll('.record-row')];
  const text = normalize(rows.map(row => row.textContent).join(' '));
  return {
    savedRecords: rows.length,
    approvals: (text.match(/pending approval|draft/g) || []).length,
    risks: (text.match(/deal at risk|urgent|risk/g) || []).length,
    due: (text.match(/next action|follow up|call back/g) || []).length
  };
}

function commandCenterMarkup() {
  const counts = countCards();
  return `<section id="finalCommandCenter" class="final-batch-panel command-center section">
    <div class="final-batch-head">
      <div>
        <p class="eyebrow">FIELD COMMAND CENTER</p>
        <h2>What should happen next?</h2>
        <p class="muted mini">Current job: ${esc(currentJobLabel())}</p>
      </div>
      <span class="final-batch-badge">Mobile ready</span>
    </div>
    <div class="final-batch-metrics">
      <button type="button" data-final-workflow="task"><strong>${counts.due}</strong><span>Follow-ups / next actions</span></button>
      <button type="button" data-final-workflow="note"><strong>${counts.savedRecords}</strong><span>Saved records visible</span></button>
      <button type="button" data-final-workflow="estimate"><strong>${counts.approvals}</strong><span>Drafts / approvals</span></button>
      <button type="button" data-final-workflow="door"><strong>${counts.risks}</strong><span>Risk signals</span></button>
    </div>
    <div class="final-batch-actions">
      <button type="button" data-final-workflow="lead">New lead</button>
      <button type="button" data-final-workflow="task">Next action</button>
      <button type="button" data-final-workflow="door">Door hanger</button>
      <button type="button" data-final-workflow="inspection">Inspection</button>
      <button type="button" data-final-workflow="estimate">Estimate</button>
      <button type="button" data-final-workflow="claim">Claim</button>
      <button type="button" data-final-open="Hammy">Hammy</button>
    </div>
  </section>`;
}

function customerActionMarkup() {
  return `<section id="finalCustomerActions" class="final-batch-panel customer-actions section">
    <div class="final-batch-head compact-head">
      <div>
        <p class="eyebrow">ONE-HANDED CUSTOMER CONTROLS</p>
        <h2>${esc(currentJobLabel().split('·')[0] || 'Current customer')}</h2>
      </div>
    </div>
    <div class="final-batch-actions customer-grid">
      <button type="button" data-final-workflow="note">Property note</button>
      <button type="button" data-final-workflow="task">Follow-up</button>
      <button type="button" data-final-workflow="message">Message</button>
      <button type="button" data-final-workflow="inspection">Inspection</button>
      <button type="button" data-final-workflow="estimate">Estimate</button>
      <button type="button" data-final-workflow="claim">Claim</button>
      <button type="button" data-final-workflow="supplement">Supplement</button>
      <button type="button" data-final-workflow="material">Production</button>
      <button type="button" data-final-workflow="invoice">Invoice</button>
    </div>
  </section>`;
}

function managerHubMarkup() {
  return `<section id="finalManagerHub" class="final-batch-panel manager-hub section">
    <div class="final-batch-head">
      <div>
        <p class="eyebrow">MANAGER ACTION HUB</p>
        <h2>Approvals, production, billing, and integrations.</h2>
        <p class="muted mini">Use this as the clean command surface while backend records stay tied to the job history.</p>
      </div>
      <span class="final-batch-badge">Manager</span>
    </div>
    <div class="final-batch-actions manager-grid">
      <button type="button" data-final-open="Approvals">Approval Center</button>
      <button type="button" data-final-workflow="measurement">Measurement approval</button>
      <button type="button" data-final-workflow="estimate">Estimate review</button>
      <button type="button" data-final-workflow="supplement">Supplement review</button>
      <button type="button" data-final-workflow="material">Material order</button>
      <button type="button" data-final-workflow="readiness">Readiness</button>
      <button type="button" data-final-workflow="cost">Job costing</button>
      <button type="button" data-final-workflow="invoice">Invoice / A/R</button>
      <button type="button" data-final-workflow="provider">Provider setup</button>
      <button type="button" data-final-open="Reports">Reports</button>
    </div>
  </section>`;
}

function approvalRailMarkup() {
  return `<section id="finalApprovalRail" class="final-batch-panel approval-rail section">
    <p class="eyebrow">APPROVAL SHORTCUTS</p>
    <h2>Review the exact thing before it leaves the company.</h2>
    <div class="final-batch-actions manager-grid">
      <button type="button" data-final-workflow="measurement">Measurement request</button>
      <button type="button" data-final-workflow="estimate">Estimate package</button>
      <button type="button" data-final-workflow="supplement">Supplement draft</button>
      <button type="button" data-final-workflow="material">Material order</button>
      <button type="button" data-final-workflow="message">AI / message draft</button>
      <button type="button" data-final-workflow="provider">Integration setup</button>
    </div>
  </section>`;
}

function installFieldDock() {
  if (document.querySelector('#finalFieldDock')) return;
  document.body.insertAdjacentHTML('beforeend', `<div id="finalFieldDock" class="final-field-dock" aria-label="Fast field actions">
    <button type="button" data-final-workflow="lead">Lead</button>
    <button type="button" data-final-workflow="note">Note</button>
    <button type="button" data-final-workflow="task">Follow-up</button>
    <button type="button" data-final-open="Hammy">Hammy</button>
  </div>`);
}

function injectPanels() {
  const workspacePage = document.querySelector('#workspacePage');
  const heading = document.querySelector('.page-heading');
  if (!workspacePage || !heading) return;
  const title = currentTitle();

  if (!document.querySelector('#finalCommandCenter') && (title === 'today' || title === 'customers')) {
    heading.insertAdjacentHTML('afterend', commandCenterMarkup());
  }

  if (!document.querySelector('#finalCustomerActions') && title === 'customers') {
    const detail = document.querySelector('.job-detail') || workspacePage;
    detail.insertAdjacentHTML('afterbegin', customerActionMarkup());
  }

  if (!document.querySelector('#finalManagerHub') && isManagerView() && ['today', 'customers', 'approvals'].includes(title)) {
    const anchor = document.querySelector('#finalCommandCenter') || heading;
    anchor.insertAdjacentHTML('afterend', managerHubMarkup());
  }

  if (!document.querySelector('#finalApprovalRail') && title === 'approvals') {
    workspacePage.insertAdjacentHTML('afterbegin', approvalRailMarkup());
  }
}

function bindActions(scope = document) {
  scope.querySelectorAll('[data-final-workflow]').forEach(button => {
    if (button.dataset.finalBound === '1') return;
    button.dataset.finalBound = '1';
    button.addEventListener('click', () => executeWorkflow(button.dataset.finalWorkflow));
  });

  scope.querySelectorAll('[data-final-open]').forEach(button => {
    if (button.dataset.finalBound === '1') return;
    button.dataset.finalBound = '1';
    button.addEventListener('click', () => openTab(button.dataset.finalOpen));
  });
}

function removeDuplicateInjectedPanels() {
  const seen = new Set();
  ['finalCommandCenter', 'finalCustomerActions', 'finalManagerHub', 'finalApprovalRail'].forEach(id => {
    document.querySelectorAll(`#${id}`).forEach(element => {
      if (seen.has(id)) element.remove();
      seen.add(id);
    });
  });
}

function enhance() {
  if (!document.querySelector('#app .workspace')) return;
  const signature = `${currentTitle()}|${currentJobLabel()}|${document.querySelectorAll('.record-row').length}`;
  installFieldDock();
  injectPanels();
  removeDuplicateInjectedPanels();
  bindActions(document);
  lastEnhance = signature;
}

const observer = new MutationObserver(() => {
  window.requestAnimationFrame(enhance);
});
observer.observe(document.documentElement, { childList: true, subtree: true });
window.addEventListener('DOMContentLoaded', enhance);
window.addEventListener('hashchange', enhance);
window.setInterval(enhance, 1200);
