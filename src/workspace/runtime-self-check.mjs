const ASSETS = [
  'app.js',
  'styles.css',
  'src/workspace/mobile-consolidated-flows.mjs',
  'src/workspace/hammy-action-layer.mjs',
  'src/workspace/final-workflow-batch.mjs',
  'src/workspace/final-operations-finish.mjs',
  'src/workspace/inspection-photo-finish.mjs',
  'src/workspace/approved-features-completion.mjs',
  'src/workspace/approved-functionality-pack.mjs',
  'src/workspace/approved-remaining-pack.mjs',
  'src/workspace/provider-adapters.mjs',
  'src/workspace/estimate-supplement-priority.mjs',
  'src/workspace/estimate-supplement-engine.mjs',
  'src/workspace/field-sales-intelligence.mjs',
  'src/workspace/customer-ops-intelligence.mjs',
  'src/workspace/completeness-dashboard.mjs',
  'src/workspace/lost-feature-recovery.mjs',
  'src/workspace/fire-urgency.mjs',
  'src/workspace/completion-polish.mjs'
];

const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const norm = value => String(value || '').toLowerCase().replace(/[^a-z0-9\s]/g,' ').replace(/\s+/g,' ').trim();
let checked = false;

async function checkAsset(path) {
  try {
    const response = await fetch(`${path}?selfcheck=${Date.now()}`, { method:'HEAD', cache:'no-store' });
    return [path, response.ok ? 'ok' : `missing ${response.status}`];
  } catch (error) {
    return [path, 'check failed'];
  }
}

async function runCheck() {
  if (checked) return;
  checked = true;
  const results = await Promise.all(ASSETS.map(checkAsset));
  window.HAMRIQ_SELF_CHECK = { checked_at:new Date().toISOString(), results };
  const bad = results.filter(([,status]) => status !== 'ok');
  const target = document.querySelector('#hamriqRuntimeSelfCheck');
  if (target) {
    target.innerHTML = `<b>${bad.length ? 'Load issues found' : 'All expected assets reachable'}</b><small>${results.length - bad.length}/${results.length} OK</small>${bad.length ? `<ul>${bad.map(([path,status]) => `<li>${esc(path)} — ${esc(status)}</li>`).join('')}</ul>` : ''}`;
    target.classList.toggle('bad', !!bad.length);
  }
}

function inject() {
  const page = document.querySelector('#workspacePage');
  if (!page || document.querySelector('#hamriqRuntimeSelfCheck')) return;
  const title = norm(document.querySelector('.page-heading h1')?.textContent || '');
  if (!['reports','settings','integrations'].includes(title)) return;
  page.insertAdjacentHTML('beforeend', `<section id="hamriqRuntimeSelfCheck" class="card runtime-self-check section"><b>Checking app assets…</b><small>Verifying loaded modules after deployment.</small></section>`);
  runCheck();
}

new MutationObserver(inject).observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('DOMContentLoaded', inject);
setInterval(inject, 1800);
