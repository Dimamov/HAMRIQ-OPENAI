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

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

async function waitFor(check, timeout = 5000) {
  const started = Date.now();
  while (Date.now() - started < timeout) {
    const result = check();
    if (result) return result;
    await sleep(80);
  }
  return null;
}

function clickWorkspaceAction(action, id = '') {
  const button = [...document.querySelectorAll('[data-action]')].find(candidate => {
    return candidate.dataset.action === action && (id === '' || candidate.dataset.id === id);
  });
  if (!button) return false;
  button.click();
  return true;
}

function openTab(tab) {
  return clickWorkspaceAction('tab', tab);
}

function setField(form, name, value) {
  const field = form.querySelector(`[name="${CSS.escape(name)}"]`);
  if (!field) return false;
  if (field.type === 'checkbox') {
    field.checked = Boolean(value);
  } else if (field.tagName === 'SELECT') {
    const wanted = normalize(value);
    const match = [...field.options].find(option => normalize(option.value) === wanted || normalize(option.textContent) === wanted);
    field.value = match ? match.value : field.options[0]?.value || '';
  } else {
    field.value = value ?? '';
  }
  field.dispatchEvent(new Event('input', { bubbles: true }));
  field.dispatchEvent(new Event('change', { bubbles: true }));
  return true;
}

async function submitCurrentModal() {
  const form = await waitFor(() => document.querySelector('.modal form'));
  if (!form) throw new Error('Hammy could not open the save form.');
  form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
  const submit = form.querySelector('button[type="submit"], .btn.accent');
  submit?.click();
  await sleep(700);
  return true;
}

function todayOffset(days = 0) {
  const date = new Date();
  date.setDate(date.getDate() + days);
  return date.toISOString().slice(0, 10);
}

function extractName(command) {
  const cleaned = command.replace(/["“”]/g, '').trim();
  const direct = cleaned.match(/(?:customer|lead|homeowner)\s+([a-z][a-z'’-]+(?:\s+[a-z][a-z'’-]+){0,3})/i);
  if (direct) return titleCase(direct[1]);
  const beforeVerb = cleaned.match(/^([a-z][a-z'’-]+(?:\s+[a-z][a-z'’-]+){0,3})\s+(?:asked|said|says|called|texted|wants|wanted|needs|need|requested|told|left|came|is|was)\b/i);
  if (beforeVerb) return titleCase(beforeVerb[1]);
  const afterAbout = cleaned.match(/(?:about|for|with)\s+([a-z][a-z'’-]+(?:\s+[a-z][a-z'’-]+){0,2})\b/i);
  if (afterAbout) return titleCase(afterAbout[1]);
  return 'New Hammy Lead';
}

function titleCase(value) {
  return String(value || '')
    .split(/\s+/)
    .filter(Boolean)
    .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}

function extractAddress(command) {
  const match = command.match(/\b(\d{2,6}\s+[a-z0-9 .'-]+(?:road|rd|street|st|avenue|ave|drive|dr|lane|ln|court|ct|circle|cir|boulevard|blvd|trail|trl|way|place|pl))\b/i);
  return match ? titleCase(match[1]) : 'Address needed';
}

function dueFromCommand(command) {
  const text = normalize(command);
  if (text.includes('today') || text.includes('now') || text.includes('asap') || text.includes('urgent')) return todayOffset(0);
  if (text.includes('tomorrow')) return todayOffset(1);
  if (text.includes('next week')) return todayOffset(7);
  if (text.includes('three days') || text.includes('3 days')) return todayOffset(3);
  return todayOffset(1);
}

function intentFromCommand(command, name) {
  const text = normalize(command);
  if (text.includes('come back') || text.includes('call back') || text.includes('follow up')) return `Follow up with ${name}`;
  if (text.includes('inspection')) return `Schedule inspection for ${name}`;
  if (text.includes('estimate')) return `Prepare estimate for ${name}`;
  if (text.includes('claim')) return `Review claim status for ${name}`;
  return `Review Hammy note for ${name}`;
}

function optionName(option) {
  return normalize((option?.textContent || '').split('·')[0]);
}

function findJobMatch(name) {
  const wanted = normalize(name);
  const pieces = wanted.split(' ').filter(Boolean);
  const select = document.querySelector('#jobSelect');
  if (!select) return { option: null, ambiguous: false };
  const options = [...select.options].map(option => ({
    option,
    fullText: normalize(option.textContent),
    nameText: optionName(option)
  }));
  const exact = options.filter(item => item.nameText === wanted || item.fullText.startsWith(`${wanted} `));
  if (exact.length === 1) return { option: exact[0].option, ambiguous: false };
  if (exact.length > 1) return { option: exact[0].option, ambiguous: true };
  const contains = options.filter(item => item.fullText.includes(wanted) || pieces.every(piece => item.fullText.includes(piece)));
  if (contains.length === 1) return { option: contains[0].option, ambiguous: false };
  if (contains.length > 1) {
    const firstName = contains[0].nameText;
    const allSameName = contains.every(item => item.nameText === firstName);
    return { option: contains[0].option, ambiguous: !allSameName };
  }
  return { option: null, ambiguous: false };
}

async function selectCustomer(name) {
  openTab('Customers');
  await sleep(300);
  const match = findJobMatch(name);
  if (!match.option) return { selected: false, ambiguous: false };
  const select = document.querySelector('#jobSelect');
  select.value = match.option.value;
  select.dispatchEvent(new Event('input', { bubbles: true }));
  select.dispatchEvent(new Event('change', { bubbles: true }));
  clickWorkspaceAction('job', match.option.value);
  await sleep(650);
  return { selected: true, ambiguous: match.ambiguous, label: match.option.textContent.trim() };
}

async function createLead({ name, address }) {
  if (!clickWorkspaceAction('lead')) throw new Error('Hammy could not open New Lead.');
  const form = await waitFor(() => document.querySelector('.modal form'));
  if (!form) throw new Error('Hammy could not open the lead form.');
  setField(form, 'name', name);
  setField(form, 'address', address);
  setField(form, 'phone', '');
  setField(form, 'email', '');
  setField(form, 'source', 'Other');
  form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
  form.querySelector('button[type="submit"], .btn.accent')?.click();
  await waitFor(() => findJobMatch(name).option, 6000);
  await selectCustomer(name);
  return `Created new lead for ${name}.`;
}

async function addRecord(kind, payload) {
  if (!clickWorkspaceAction('new', kind)) {
    openTab(kind === 'task' ? 'Today' : 'Customers');
    await sleep(250);
    if (!clickWorkspaceAction('new', kind)) throw new Error(`Hammy could not open ${kind}.`);
  }
  const form = await waitFor(() => document.querySelector('.modal form'));
  if (!form) throw new Error(`Hammy could not open the ${kind} form.`);
  Object.entries(payload).forEach(([key, value]) => setField(form, key, value));
  await submitCurrentModal();
}

async function runHammyAction(command) {
  const name = extractName(command);
  const address = extractAddress(command);
  const due = dueFromCommand(command);
  const title = intentFromCommand(command, name);
  const match = await selectCustomer(name);
  const steps = [];

  if (!match.selected) {
    steps.push(await createLead({ name, address }));
  } else if (match.ambiguous) {
    steps.push(`Selected the first likely match for ${name}: ${match.label}.`);
  } else {
    steps.push(`Auto-selected existing customer/job for ${name}.`);
  }

  await addRecord('note', { body: `Hammy note: ${command}` });
  steps.push('Saved the note to Property Memory.');

  await addRecord('task', {
    title,
    due,
    priority: normalize(command).includes('urgent') ? 'Urgent' : 'High',
    notes: `Created by Hammy from: ${command}`
  });
  steps.push(`Created next action: ${title} due ${due}.`);

  openTab('Customers');
  await sleep(300);
  await selectCustomer(name);
  return steps;
}

function hammyPanel() {
  return `<section id="hammyActionLayer" class="card hammy-action-layer section">
    <p class="eyebrow">HAMMY ACTION LAYER</p>
    <h2>Talk to Hammy like a rep.</h2>
    <p class="muted">Example: <strong>Bob Smith asked me to come back tomorrow.</strong> Hammy will create or match the lead, save the note, and create the follow-up.</p>
    <textarea id="hammyActionText" class="input" rows="3" placeholder="Say or type what happened with the homeowner..."></textarea>
    <div class="row section">
      <button type="button" class="btn accent" id="hammyDoAction">Do it</button>
      <button type="button" class="btn secondary" id="hammyExampleAction">Use example</button>
    </div>
    <div id="hammyActionResult" class="hammy-action-result" hidden></div>
  </section>`;
}

function enhanceHammy() {
  const heading = document.querySelector('.page-heading h1');
  const page = document.querySelector('#workspacePage');
  if (!heading || !page || normalize(heading.textContent) !== 'hammy') return;
  if (document.querySelector('#hammyActionLayer')) return;
  page.insertAdjacentHTML('afterbegin', hammyPanel());
  const textarea = document.querySelector('#hammyActionText');
  const result = document.querySelector('#hammyActionResult');
  document.querySelector('#hammyExampleAction')?.addEventListener('click', () => {
    textarea.value = 'Bob Smith asked me to come back tomorrow.';
    textarea.focus();
  });
  document.querySelector('#hammyDoAction')?.addEventListener('click', async () => {
    const command = textarea.value.trim();
    if (!command) return;
    result.hidden = false;
    result.className = 'hammy-action-result working';
    result.textContent = 'Hammy is doing it…';
    try {
      const steps = await runHammyAction(command);
      result.className = 'hammy-action-result done';
      result.innerHTML = `<strong>Done.</strong><ul>${steps.map(step => `<li>${esc(step)}</li>`).join('')}</ul>`;
    } catch (error) {
      result.className = 'hammy-action-result error';
      result.textContent = error?.message || 'Hammy could not complete the action.';
    }
  });
}

const observer = new MutationObserver(() => enhanceHammy());
observer.observe(document.documentElement, { childList: true, subtree: true });
window.addEventListener('DOMContentLoaded', enhanceHammy);
setInterval(enhanceHammy, 1000);
