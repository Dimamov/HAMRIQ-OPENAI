const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const norm = value => String(value || '').toLowerCase().replace(/[^a-z0-9\s]/g,' ').replace(/\s+/g,' ').trim();

const STEPS = [
  {title:'1. Gather measurement', detail:'Use native HAMRIQ first, then EagleView/Hover fallback if manager approves.', actions:[['Measurement request','measurement'],['Provider setup','provider']]},
  {title:'2. Photo-to-scope proof', detail:'Collect front/left/right/rear proof, collateral, soft metals, gutters, cornice returns, and missing-photo notes.', actions:[['Guided inspection','inspection'],['Scope draft','scope']]},
  {title:'3. Automated estimate draft', detail:'Build Good/Better/Best packages from measurements, price book, selected products, labor, waste, and required accessories.', actions:[['Good/Better/Best estimate','estimate'],['Price book','price']]},
  {title:'4. Human review', detail:'Rep/manager reviews scope, price, exclusions, product selections, and contract handoff before homeowner presentation.', actions:[['Approval Center','tab:Approvals'],['Presentation notes','presentation']]},
  {title:'5. Carrier estimate intake', detail:'Upload/record carrier estimate, claim number, adjuster, next response due, and carrier line items.', actions:[['Claim timeline','claim'],['Carrier gap finder','gap']]},
  {title:'6. Supplement builder', detail:'Compare HAMRIQ scope to carrier scope, find missing or underpaid items, create evidence-backed supplement draft.', actions:[['Supplement draft','supplement'],['Claim packet','packet']]},
  {title:'7. Send after approval', detail:'Nothing is sent automatically. Reviewed supplement/packet moves to homeowner/adjuster communication after approval.', actions:[['Homeowner message','message'],['Follow-up task','task']]}
];

const TAB_BY_KIND = {measurement:'Inspections',provider:'Integrations',inspection:'Inspections',scope:'Inspections',estimate:'Sales',price:'Settings',presentation:'Sales',claim:'Claims',gap:'Claims',supplement:'Claims',packet:'Claims',message:'Customers',task:'Today'};

function clickAction(action, id='') {
  const button = [...document.querySelectorAll('[data-action]')].find(el => el.dataset.action === action && (id === '' || el.dataset.id === id));
  if (!button) return false;
  button.click();
  return true;
}

function run(target) {
  if (target.startsWith('tab:')) return clickAction('tab', target.slice(4));
  clickAction('tab', TAB_BY_KIND[target] || 'Today');
  setTimeout(() => clickAction('new', target), 180);
}

function stepCard(step) {
  return `<article class="estimate-supp-step"><h3>${esc(step.title)}</h3><p>${esc(step.detail)}</p><div>${step.actions.map(([label,target]) => `<button type="button" data-est-supp-action="${esc(target)}">${esc(label)}</button>`).join('')}</div></article>`;
}

function panel() {
  return `<section id="estimateSupplementPriority" class="card estimate-supp-priority section">
    <div class="estimate-supp-head">
      <div>
        <p class="eyebrow">PRIMARY MONEY WORKFLOW</p>
        <h2>Automated estimate + supplement process</h2>
        <p class="muted">This is now the priority path: measurement → photo proof → estimate draft → human review → carrier comparison → supplement draft → approval/send.</p>
      </div>
      <div class="estimate-supp-badge">PRIORITY #1</div>
    </div>
    <div class="estimate-supp-grid">${STEPS.map(stepCard).join('')}</div>
  </section>`;
}

function bind(root=document) {
  root.querySelectorAll('[data-est-supp-action]').forEach(button => {
    if (button.dataset.bound === '1') return;
    button.dataset.bound = '1';
    button.addEventListener('click', () => run(button.dataset.estSuppAction));
  });
}

function inject() {
  const page = document.querySelector('#workspacePage');
  if (!page || document.querySelector('#estimateSupplementPriority')) return;
  const title = norm(document.querySelector('.page-heading h1')?.textContent || '');
  if (!['today','sales','inspections','claims','reports','approvals'].includes(title)) return;
  page.insertAdjacentHTML('afterbegin', panel());
  bind(page);
}

new MutationObserver(inject).observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('DOMContentLoaded', inject);
setInterval(inject, 1300);
