const WORKFLOW_GROUPS = [
  {
    id: 'crm',
    title: 'Core CRM + Hammy',
    detail: 'Customer context, account notes, today view, and Hammy support.',
    openTab: 'Customers',
    actions: [
      ['Open customers', 'tab', 'Customers'],
      ['Create lead', 'lead', ''],
      ['Ask Hammy', 'tab', 'Hammy'],
      ['Add property note', 'new', 'note'],
      ['Add next action', 'new', 'task']
    ]
  },
  {
    id: 'prospecting',
    title: 'Mobile prospecting',
    detail: 'Door knocking, door hangers, route stops, lead source, and quick capture.',
    openTab: 'Prospecting',
    actions: [
      ['Open prospecting', 'tab', 'Prospecting'],
      ['New mobile lead', 'lead', ''],
      ['Door hanger placed', 'new', 'door'],
      ['Create rep route', 'new', 'route'],
      ['Storm campaign', 'new', 'storm']
    ]
  },
  {
    id: 'salesflow',
    title: 'Inspection → estimate → contract',
    detail: 'Move from evidence to scope, Good/Better/Best, selection, and handoff.',
    openTab: 'Inspections',
    actions: [
      ['Guided inspection', 'new', 'inspection'],
      ['Scope draft', 'new', 'scope'],
      ['Measurement request', 'new', 'measurement'],
      ['Estimate package', 'new', 'estimate'],
      ['Presentation notes', 'new', 'presentation']
    ]
  },
  {
    id: 'claims',
    title: 'Claims + supplements',
    detail: 'Claim deadlines, adjuster prep, carrier gaps, supplement drafts, packets.',
    openTab: 'Claims',
    actions: [
      ['Open claims', 'tab', 'Claims'],
      ['Claim timeline', 'new', 'claim'],
      ['Adjuster prep', 'new', 'adjuster'],
      ['Gap finder', 'new', 'gap'],
      ['Supplement draft', 'new', 'supplement']
    ]
  },
  {
    id: 'homeowner',
    title: 'Follow-ups + homeowner experience',
    detail: 'Messages, portal, referral requests, reviews, and visible project status.',
    openTab: 'Customers',
    actions: [
      ['Customer view', 'tab', 'Customers'],
      ['Message draft', 'new', 'message'],
      ['Referral ask', 'new', 'referral'],
      ['Review request', 'new', 'review'],
      ['Customer portal', 'portal', '']
    ]
  },
  {
    id: 'production',
    title: 'Production',
    detail: 'Materials, delivery checks, permits, crews, weather, readiness, warranties.',
    openTab: 'Production',
    actions: [
      ['Open production', 'tab', 'Production'],
      ['Material order', 'new', 'material_order'],
      ['Delivery check', 'new', 'delivery'],
      ['Readiness checklist', 'new', 'readiness'],
      ['Warranty record', 'new', 'warranty']
    ]
  },
  {
    id: 'finance',
    title: 'Finance + marketing',
    detail: 'Job costing, invoices, commissions, campaign ROI, review funnel.',
    openTab: 'Financials',
    actions: [
      ['Open financials', 'tab', 'Financials'],
      ['Job costing', 'new', 'cost'],
      ['Invoice / A/R', 'new', 'invoice'],
      ['Commission', 'new', 'commission'],
      ['Campaign ROI', 'new', 'campaign']
    ]
  },
  {
    id: 'systems',
    title: 'Systems + integrations',
    detail: 'Import/export, offline, providers, AI, measurement services, and setup state.',
    openTab: 'Integrations',
    actions: [
      ['Open integrations', 'tab', 'Integrations'],
      ['Provider setup', 'new', 'provider'],
      ['Company price book', 'new', 'price'],
      ['Company branding', 'new', 'branding'],
      ['Reports', 'tab', 'Reports']
    ]
  }
];

const SELECTOR = '#app .workspace';
let lastSignature = '';

const esc = value => String(value ?? '').replace(/[&<>"']/g, character => ({
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#39;'
}[character]));

function findAction(action, id = '') {
  return [...document.querySelectorAll('[data-action]')].find(button => {
    return button.dataset.action === action && (id === '' || button.dataset.id === id);
  });
}

function runAction(action, id = '') {
  const button = findAction(action, id);
  if (button) {
    button.click();
    return true;
  }
  return false;
}

function openTab(tab) {
  return runAction('tab', tab);
}

function runWorkflow(action, id, group) {
  closePanel();
  if (action === 'new') {
    if (group?.openTab) openTab(group.openTab);
    setTimeout(() => {
      if (!runAction('new', id)) {
        openTab(group?.openTab || 'Today');
        setTimeout(() => runAction('new', id), 100);
      }
    }, 100);
    return;
  }
  if (action === 'portal') {
    if (!runAction('portal')) {
      openTab('Customers');
      setTimeout(() => runAction('portal'), 120);
    }
    return;
  }
  runAction(action, id);
}

function groupCard(group) {
  return `<article class="mobile-flow-card" data-flow-card="${esc(group.id)}">
    <div class="mobile-flow-card-head">
      <span>${esc(group.title)}</span>
      <button type="button" data-mobile-action="open-tab" data-tab="${esc(group.openTab)}">Open</button>
    </div>
    <p>${esc(group.detail)}</p>
    <div class="mobile-flow-actions">
      ${group.actions.map(([label, action, id]) => `<button type="button" data-mobile-action="workflow" data-flow="${esc(group.id)}" data-action-key="${esc(action)}" data-action-id="${esc(id)}">${esc(label)}</button>`).join('')}
    </div>
  </article>`;
}

function ribbon() {
  return `<section id="mobileFlowRibbon" class="mobile-flow-ribbon" aria-label="Consolidated workflow launcher">
    <div class="mobile-flow-ribbon-title">
      <strong>Consolidated workflow</strong>
      <span>Tap a lane. Add the record. Keep moving.</span>
    </div>
    <div class="mobile-flow-ribbon-scroll">
      ${WORKFLOW_GROUPS.map(group => `<button type="button" data-mobile-action="jump-flow" data-flow="${esc(group.id)}"><b>${esc(group.title)}</b><span>${esc(group.detail)}</span></button>`).join('')}
    </div>
  </section>`;
}

function panel() {
  return `<div id="mobileFlowPanel" class="mobile-flow-panel" role="dialog" aria-modal="true" aria-label="HAMRIQ workflow launcher">
    <div class="mobile-flow-sheet">
      <div class="mobile-flow-sheet-head">
        <div>
          <p>HAMRIQ MOBILE</p>
          <h2>Everything you approved, grouped into working lanes.</h2>
        </div>
        <button type="button" class="mobile-flow-close" data-mobile-action="close">×</button>
      </div>
      <div class="mobile-flow-grid">
        ${WORKFLOW_GROUPS.map(groupCard).join('')}
      </div>
    </div>
  </div>`;
}

function installButton() {
  if (document.querySelector('#mobileFlowButton')) return;
  const button = document.createElement('button');
  button.id = 'mobileFlowButton';
  button.className = 'mobile-flow-button';
  button.type = 'button';
  button.textContent = 'Workflow';
  button.addEventListener('click', openPanel);
  document.body.appendChild(button);
}

function injectRibbon() {
  const workspace = document.querySelector(SELECTOR);
  const heading = document.querySelector('.page-heading');
  if (!workspace || !heading) return;
  if (!document.querySelector('#mobileFlowRibbon')) {
    heading.insertAdjacentHTML('afterend', ribbon());
  }
}

function openPanel() {
  closePanel();
  document.body.insertAdjacentHTML('beforeend', panel());
  bindPanel(document.querySelector('#mobileFlowPanel'));
}

function closePanel() {
  document.querySelector('#mobileFlowPanel')?.remove();
}

function bindPanel(container = document) {
  container.querySelectorAll('[data-mobile-action]').forEach(button => {
    if (button.dataset.bound === '1') return;
    button.dataset.bound = '1';
    button.addEventListener('click', () => {
      const action = button.dataset.mobileAction;
      if (action === 'close') return closePanel();
      if (action === 'open-tab') {
        closePanel();
        return openTab(button.dataset.tab);
      }
      if (action === 'jump-flow') {
        const group = WORKFLOW_GROUPS.find(item => item.id === button.dataset.flow);
        openPanel();
        requestAnimationFrame(() => {
          document.querySelector(`[data-flow-card="${group?.id}"]`)?.scrollIntoView({ block: 'center', behavior: 'smooth' });
        });
        return;
      }
      if (action === 'workflow') {
        const group = WORKFLOW_GROUPS.find(item => item.id === button.dataset.flow);
        runWorkflow(button.dataset.actionKey, button.dataset.actionId, group);
      }
    });
  });
}

function enhance() {
  const workspace = document.querySelector(SELECTOR);
  if (!workspace) return;
  const signature = `${location.host}:${document.querySelector('.page-heading h1')?.textContent || ''}:${document.querySelector('#jobSelect')?.value || ''}`;
  if (signature === lastSignature && document.querySelector('#mobileFlowRibbon')) return;
  lastSignature = signature;
  installButton();
  injectRibbon();
  bindPanel(document);
}

const observer = new MutationObserver(() => enhance());
observer.observe(document.documentElement, { childList: true, subtree: true });
window.addEventListener('hashchange', enhance);
window.addEventListener('DOMContentLoaded', enhance);
setInterval(enhance, 1200);
