const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));

let pendingSelect = null;
let previousValue = '';

function isUrgencySelect(select) {
  if (!select || select.tagName !== 'SELECT') return false;
  const label = select.closest('label')?.textContent || '';
  const name = select.name || '';
  const options = [...select.options].map(option => option.value || option.textContent);
  return options.includes('FIRE') && /priority|urgency/i.test(`${label} ${name}`);
}

function closeFireModal(confirm) {
  const modal = document.querySelector('#fireUrgencyConfirm');
  if (modal) modal.remove();
  if (!pendingSelect) return;
  if (!confirm) pendingSelect.value = previousValue || 'Urgent';
  pendingSelect.classList.toggle('fire-selected', confirm && pendingSelect.value === 'FIRE');
  pendingSelect.dispatchEvent(new Event('fire-urgency-reviewed', { bubbles: true }));
  pendingSelect = null;
  previousValue = '';
}

function showFireConfirm(select, oldValue) {
  pendingSelect = select;
  previousValue = oldValue || 'Urgent';
  document.querySelector('#fireUrgencyConfirm')?.remove();
  document.body.insertAdjacentHTML('beforeend', `<div id="fireUrgencyConfirm" class="fire-modal-backdrop" role="dialog" aria-modal="true">
    <div class="fire-modal">
      <div class="fire-icon">🔥</div>
      <h2>Are you sure it’s THAT urgent?</h2>
      <p>FIRE tasks should be reserved for true stop-everything issues that need immediate rep or management attention.</p>
      <div class="fire-actions">
        <button type="button" data-fire-confirm="no">Not that urgent</button>
        <button type="button" data-fire-confirm="yes">Yes — mark FIRE</button>
      </div>
    </div>
  </div>`);
}

function installFireSelectGuards(root = document) {
  root.querySelectorAll('select').forEach(select => {
    if (!isUrgencySelect(select) || select.dataset.fireGuard === '1') return;
    select.dataset.fireGuard = '1';
    select.dataset.previousValue = select.value || '';
    select.addEventListener('focus', () => { select.dataset.previousValue = select.value || ''; });
    select.addEventListener('pointerdown', () => { select.dataset.previousValue = select.value || ''; });
    select.addEventListener('change', () => {
      const oldValue = select.dataset.previousValue || '';
      if (select.value === 'FIRE') showFireConfirm(select, oldValue);
      else select.classList.remove('fire-selected');
      select.dataset.previousValue = select.value || '';
    });
  });
}

function installFireButtons() {
  document.addEventListener('click', event => {
    const button = event.target.closest?.('[data-fire-confirm]');
    if (!button) return;
    closeFireModal(button.dataset.fireConfirm === 'yes');
  });
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape' && document.querySelector('#fireUrgencyConfirm')) closeFireModal(false);
  });
}

function addFutureFireAnchor() {
  window.HAMRIQ_FIRE_ROADMAP = {
    saved: true,
    label: 'PUT OUT FIRES',
    visual: 'fire extinguisher button',
    source: 'Tasks or risk records marked FIRE',
    status: 'roadmap anchor saved for next UI build'
  };
}

function enhance() {
  installFireSelectGuards();
  addFutureFireAnchor();
}

installFireButtons();
new MutationObserver(enhance).observe(document.documentElement, { childList: true, subtree: true });
window.addEventListener('DOMContentLoaded', enhance);
setInterval(enhance, 1500);
