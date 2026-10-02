const normalize = value => String(value || '')
  .toLowerCase()
  .replace(/[^a-z0-9\s]/g, ' ')
  .replace(/\s+/g, ' ')
  .trim();

const esc = value => String(value ?? '').replace(/[&<>"']/g, character => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
}[character]));

const PHOTO_STEPS = [
  ['front-wide', 'Front wide shot', 'Full front elevation before details.'],
  ['front-details', 'Front details', 'Gutters, downspouts, window wraps, fascia, soft metals.'],
  ['left-wide', 'Left side wide shot', 'Full left elevation and slope context.'],
  ['left-details', 'Left details', 'Collateral, splatter, metals, wraps, AC components.'],
  ['right-wide', 'Right side wide shot', 'Full right elevation and slope context.'],
  ['right-details', 'Right details', 'Collateral, splatter, metals, wraps, AC components.'],
  ['rear-wide', 'Rear wide shot', 'Full rear elevation and roofline context.'],
  ['rear-details', 'Rear details', 'Gutters, screens, soft metals, collateral damage.'],
  ['roof-overview', 'Roof overview', 'Roof planes/slopes, vents, ridges, hips, valleys where visible.'],
  ['features', 'Roof features', 'Cornice returns, dead valleys, step flashing, chimneys, skylights, satellite mounts.']
];

function clickAction(action, id = '') {
  const button = [...document.querySelectorAll('[data-action]')].find(candidate => {
    return candidate.dataset.action === action && (id === '' || candidate.dataset.id === id);
  });
  if (!button) return false;
  button.click();
  return true;
}

function currentTitle() {
  return normalize(document.querySelector('.page-heading h1')?.textContent || '');
}

function storageKey() {
  const job = document.querySelector('#jobSelect')?.value || 'no-job';
  return `hamriq-photo-steps:${job}`;
}

function loadState() {
  try { return JSON.parse(localStorage.getItem(storageKey()) || '{}'); }
  catch { return {}; }
}

function saveState(state) {
  localStorage.setItem(storageKey(), JSON.stringify(state));
}

function panel() {
  const state = loadState();
  const done = PHOTO_STEPS.filter(([id]) => state[id]).length;
  return `<section id="inspectionPhotoFinish" class="card inspection-photo-finish section">
    <div class="inspection-photo-head">
      <div>
        <p class="eyebrow">FIELD PHOTO FLOW</p>
        <h2>Walk the property once. Capture everything.</h2>
        <p class="muted">${done}/${PHOTO_STEPS.length} photo checkpoints marked for this job on this device.</p>
      </div>
      <div class="row">
        <button class="btn accent" data-photo-action="inspection">Open guided inspection</button>
        <button class="btn secondary" data-photo-action="scope">Build scope draft</button>
      </div>
    </div>
    <div class="inspection-photo-progress"><i style="width:${Math.round(done / PHOTO_STEPS.length * 100)}%"></i></div>
    <div class="inspection-photo-grid">
      ${PHOTO_STEPS.map(([id, title, detail]) => `<label class="${state[id] ? 'done' : ''}">
        <input type="checkbox" data-photo-step="${esc(id)}" ${state[id] ? 'checked' : ''}>
        <span><b>${esc(title)}</b><small>${esc(detail)}</small></span>
      </label>`).join('')}
    </div>
    <div class="inspection-photo-note">
      <strong>AI photo analysis rule:</strong> when photo AI is connected, HAMRIQ should report clear signs of hail/collateral damage only. It should not waste reps’ time describing the whole photo.
    </div>
  </section>`;
}

function bind(container = document) {
  container.querySelectorAll('[data-photo-step]').forEach(input => {
    if (input.dataset.bound === '1') return;
    input.dataset.bound = '1';
    input.addEventListener('change', () => {
      const state = loadState();
      state[input.dataset.photoStep] = input.checked;
      saveState(state);
      document.querySelector('#inspectionPhotoFinish')?.remove();
      inject();
    });
  });
  container.querySelectorAll('[data-photo-action]').forEach(button => {
    if (button.dataset.bound === '1') return;
    button.dataset.bound = '1';
    button.addEventListener('click', () => {
      if (button.dataset.photoAction === 'inspection') {
        clickAction('tab', 'Inspections');
        setTimeout(() => clickAction('new', 'inspection'), 180);
      }
      if (button.dataset.photoAction === 'scope') {
        clickAction('tab', 'Inspections');
        setTimeout(() => clickAction('new', 'scope'), 180);
      }
    });
  });
}

function inject() {
  const page = document.querySelector('#workspacePage');
  if (!page) return;
  const title = currentTitle();
  if (!['inspections', 'customers', 'today'].includes(title)) return;
  if (document.querySelector('#inspectionPhotoFinish')) return;
  page.insertAdjacentHTML(title === 'inspections' ? 'afterbegin' : 'beforeend', panel());
  bind(page);
}

const observer = new MutationObserver(() => inject());
observer.observe(document.documentElement, { childList: true, subtree: true });
window.addEventListener('DOMContentLoaded', inject);
setInterval(inject, 1300);
