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

const TABS = [
  'Today',
  'Customers',
  'Sales',
  'Inspections',
  'Claims',
  'Prospecting',
  'Production',
  'Financials',
  'Marketing',
  'Approvals',
  'Reports',
  'Settings',
  'Integrations',
  'Hammy'
];

const FAST_ACTIONS = [
  ['New lead', 'lead', '', 'Lead'],
  ['Follow-up', 'new', 'task', 'Task'],
  ['Note', 'new', 'note', 'Note'],
  ['Door hanger', 'new', 'door', 'Door'],
  ['Inspection', 'new', 'inspection', 'Inspect'],
  ['Estimate', 'new', 'estimate', 'Estimate'],
  ['Supplement', 'new', 'supplement', 'Supp'],
  ['Material order', 'new', 'material_order', 'Material'],
  ['Invoice', 'new', 'invoice', 'Invoice'],
  ['Hammy', 'tab', 'Hammy', 'Hammy']
];

const TAB_HINTS = {
  Today: 'Next actions, overdue follow-ups, and deal risk.',
  Customers: 'Customer file, property memory, portal, messages, reviews.',
  Sales: 'Estimate packages, presentation notes, save desk.',
  Inspections: 'Evidence, scope draft, measurement request.',
  Claims: 'Carrier timeline, adjuster prep, gaps, supplement packets.',
  Prospecting: 'Door hanger, routes, storm campaigns, neighbors.',
  Production: 'Materials, permits, delivery, schedule, readiness, warranty.',
  Financials: 'Job costing, invoices, A/R, commissions.',
  Marketing: 'Campaign ROI and review funnel.',
  Approvals: 'Manager review queue.',
  Reports: 'Performance and CSV export.',
  Settings: 'Price book and company branding.',
  Integrations: 'Provider setup and subscription-required services.',
  Hammy: 'Voice/text action capture.'
};

let lastSignature = '';
let modalSubmitLock = false;
let globalActionLock = false;

function workspace() {
  return document.querySelector('#app .workspace');
}

function headingTitle() {
  return document.querySelector('.page-heading h1')?.textContent?.trim() || '';
}

function selectedJob() {
  const option = document.querySelector('#jobSelect option:checked');
  return option?.textContent?.trim() || 'No selected job';
}

function roleLabel() {
  return document.querySelector('.page-heading .eyebrow')?.textContent?.trim() || 'HAMRIQ workspace';
}

function clickAction(action, id = '') {
  if (globalActionLock) return false;
  const button = [...document.querySelectorAll('[data-action]')].find(candidate => (
    candidate.dataset.action === action && (id === '' || candidate.dataset.id === id)
  ));
  if (!button) return false;
  globalActionLock = true;
  button.click();
  setTimeout(() => { globalActionLock = false; }, 500);
  return true;
}

function openTab(tab) {
  return clickAction('tab', tab);
}

function openFast(action, id) {
  const tabFor = {
    task: 'Today', note: 'Customers', door: 'Prospecting', inspection: 'Inspections',
    estimate: 'Sales', supplement: 'Claims', material_order: 'Production', invoice: 'Financials'
  }[id];
  if (tabFor) openTab(tabFor);
  setTimeout(() => clickAction(action, id), tabFor ? 150 : 0);
}

function completionHeader() {
  return `<section id="completionHeader" class="completion-header" aria-label="HAMRIQ completion status">
    <div>
      <p>FINAL BATCH MODE</p>
      <h2>${esc(headingTitle() || 'HAMRIQ')}</h2>
      <span>${esc(roleLabel())}</span>
    </div>
    <div class="completion-current-job">
      <b>Working on</b>
      <span>${esc(selectedJob())}</span>
    </div>
    <button type="button" data-completion-action="open-more">Open workspace</button>
  </section>`;
}

function fieldDock() {
  return `<div id="completionFieldDock" class="completion-field-dock" aria-label="HAMRIQ fast field actions">
    ${FAST_ACTIONS.slice(0, 6).map(([label, action, id, short]) => `<button type="button" data-completion-action="fast" data-action-key="${esc(action)}" data-action-id="${esc(id)}"><span>${esc(short)}</span><small>${esc(label)}</small></button>`).join('')}
    <button type="button" data-completion-action="open-more"><span>More</span><small>All tools</small></button>
  </div>`;
}

function workspaceSheet() {
  return `<div id="completionWorkspaceSheet" class="completion-sheet" role="dialog" aria-modal="true" aria-label="HAMRIQ workspace menu">
    <div class="completion-sheet-card">
      <header>
        <div>
          <p>HAMRIQ WORKSPACE</p>
          <h2>Everything in one field menu.</h2>
        </div>
        <button type="button" data-completion-action="close">×</button>
      </header>
      <section>
        <h3>Go to</h3>
        <div class="completion-tab-grid">
          ${TABS.map(tab => `<button type="button" data-completion-action="tab" data-tab="${esc(tab)}"><b>${esc(tab)}</b><span>${esc(TAB_HINTS[tab] || '')}</span></button>`).join('')}
        </div>
      </section>
      <section>
        <h3>Fast actions</h3>
        <div class="completion-action-grid">
          ${FAST_ACTIONS.map(([label, action, id]) => `<button type="button" data-completion-action="fast" data-action-key="${esc(action)}" data-action-id="${esc(id)}">${esc(label)}</button>`).join('')}
        </div>
      </section>
    </div>
  </div>`;
}

function openSheet() {
  closeSheet();
  document.body.insertAdjacentHTML('beforeend', workspaceSheet());
  bindCompletion(document.querySelector('#completionWorkspaceSheet'));
}

function closeSheet() {
  document.querySelector('#completionWorkspaceSheet')?.remove();
}

function installHeader() {
  const main = document.querySelector('.main');
  const heading = document.querySelector('.page-heading');
  if (!main || !heading) return;
  const old = document.querySelector('#completionHeader');
  const signature = JSON.stringify([headingTitle(), roleLabel(), selectedJob()]);
  if (old?.dataset.contextSignature === signature) return;
  if (old) old.remove();
  heading.insertAdjacentHTML('beforebegin', completionHeader());
  document.querySelector('#completionHeader').dataset.contextSignature = signature;
}

function installDock() {
  if (document.querySelector('#completionFieldDock')) return;
  document.body.insertAdjacentHTML('beforeend', fieldDock());
}

function makeMoreButtonUseful() {
  document.querySelectorAll('[data-action="more"]').forEach(button => {
    if (button.dataset.completionBound === '1') return;
    button.dataset.completionBound = '1';
    button.addEventListener('click', event => {
      event.preventDefault();
      event.stopPropagation();
      openSheet();
    }, true);
  });
}

function guardModalSubmits() {
  document.querySelectorAll('.modal form').forEach(form => {
    if (form.dataset.completionGuarded === '1') return;
    form.dataset.completionGuarded = '1';
    form.addEventListener('submit', event => {
      if (modalSubmitLock) {
        event.preventDefault();
        event.stopPropagation();
        return false;
      }
      modalSubmitLock = true;
      const submit = form.querySelector('button[type="submit"], .btn.accent');
      if (submit) {
        submit.dataset.originalText = submit.textContent;
        submit.textContent = 'Saving…';
        submit.disabled = true;
      }
      setTimeout(() => { modalSubmitLock = false; }, 1200);
    }, true);
  });
}

function enhanceApprovalPage() {
  if (normalize(headingTitle()) !== 'approvals') return;
  const page = document.querySelector('#workspacePage');
  if (!page || document.querySelector('#completionApprovalBoost')) return;
  page.insertAdjacentHTML('afterbegin', `<section id="completionApprovalBoost" class="completion-boost card section">
    <p class="eyebrow">MANAGER ACTION HUB</p>
    <h2>Review queue shortcuts</h2>
    <p class="muted">Jump straight to the records managers approve most: measurements, estimates, supplements, material orders, messages, invoices, and provider setup.</p>
    <div class="completion-action-grid">
      ${[
        ['Measurement approval', 'new', 'measurement'],
        ['Estimate review', 'new', 'estimate'],
        ['Supplement review', 'new', 'supplement'],
        ['Material order', 'new', 'material_order'],
        ['Message draft', 'new', 'message'],
        ['Invoice / A/R', 'new', 'invoice'],
        ['Provider setup', 'new', 'provider'],
        ['Reports', 'tab', 'Reports']
      ].map(([label, action, id]) => `<button type="button" data-completion-action="fast" data-action-key="${esc(action)}" data-action-id="${esc(id)}">${esc(label)}</button>`).join('')}
    </div>
  </section>`);
}

function enhanceCustomerPage() {
  if (normalize(headingTitle()) !== 'customers') return;
  const page = document.querySelector('#workspacePage');
  if (!page || document.querySelector('#completionCustomerBoost')) return;
  page.insertAdjacentHTML('afterbegin', `<section id="completionCustomerBoost" class="completion-boost card section">
    <p class="eyebrow">CUSTOMER COMMANDS</p>
    <h2>Work the selected customer fast.</h2>
    <p class="muted">Every button writes to the current job timeline or opens the correct workflow.</p>
    <div class="completion-action-grid">
      ${[
        ['Property note', 'new', 'note'],
        ['Follow-up', 'new', 'task'],
        ['Homeowner message', 'new', 'message'],
        ['Guided inspection', 'new', 'inspection'],
        ['Estimate package', 'new', 'estimate'],
        ['Claim timeline', 'new', 'claim'],
        ['Supplement draft', 'new', 'supplement'],
        ['Review request', 'new', 'review']
      ].map(([label, action, id]) => `<button type="button" data-completion-action="fast" data-action-key="${esc(action)}" data-action-id="${esc(id)}">${esc(label)}</button>`).join('')}
    </div>
  </section>`);
}

function bindCompletion(container = document) {
  container.querySelectorAll('[data-completion-action]').forEach(button => {
    if (button.dataset.completionBound === '1') return;
    button.dataset.completionBound = '1';
    button.addEventListener('click', event => {
      const action = button.dataset.completionAction;
      if (action === 'close') return closeSheet();
      if (action === 'open-more') return openSheet();
      if (action === 'tab') {
        closeSheet();
        return openTab(button.dataset.tab);
      }
      if (action === 'fast') {
        closeSheet();
        return openFast(button.dataset.actionKey, button.dataset.actionId);
      }
    });
  });
}

function enhance() {
  if (!workspace()) return;
  const signature = `${headingTitle()}::${selectedJob()}::${document.querySelectorAll('.modal form').length}`;
  installHeader();
  installDock();
  makeMoreButtonUseful();
  guardModalSubmits();
  enhanceApprovalPage();
  enhanceCustomerPage();
  bindCompletion(document);
  lastSignature = signature;
}

const observer = new MutationObserver(enhance);
observer.observe(document.documentElement, { childList: true, subtree: true });
window.addEventListener('DOMContentLoaded', enhance);
window.addEventListener('hashchange', enhance);
setInterval(enhance, 1200);
