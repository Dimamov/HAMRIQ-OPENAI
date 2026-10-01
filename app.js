import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const config = await fetch('./src/lib/config.json').then(r => r.json());
const db = createClient(config.supabaseUrl, config.supabasePublishableKey);
const app = document.querySelector('#app');
let profile, company, tab = 'Today';
let data = { jobs: [], contacts: [], routes: [], visits: [], orders: [], reviews: [], production: [] };
const sources = ['Unknown','Referral','Door knocking','Door hanger','Storm lead','Internet','Past customer','Insurance','Other'];
const leadStages = ['First contact','Inspection complete','Contingency signed','Claim filed','Claim approved','Supplement submitted','Build contract signed','Completed','DEAD'];
const allTabs = ['Today','Customers','Jobs','Prospecting','Marketing','Hammy','Routes','Measurements','Pricing','Reviews','Production'];
const repTabs = ['Today','Customers','Jobs','Prospecting','Hammy'];
const esc = v => String(v ?? '').replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
const todayISO = () => new Date().toISOString().slice(0,10);
const stageOf = j => j?.lead_progress_stage || j?.stage || 'First contact';
const role = () => (profile?.role || '').toLowerCase();
const isMgr = () => ['owner','admin','manager'].some(r => role().includes(r));
const visibleTabs = () => isMgr() ? allTabs : repTabs;

async function boot(){
  const { data: { session } } = await db.auth.getSession();
  if (!session) return login();
  const ctx = await db.rpc('workspace_context');
  if (ctx.error || !ctx.data) return login('Your user is not provisioned in HAMRIQ yet.');
  profile = ctx.data.user; company = ctx.data.company;
  await load(); render();
}

async function safeQuery(key, query){
  const res = await query;
  data[key] = res.error ? [] : (res.data || []);
}
async function load(){
  await Promise.all([
    safeQuery('jobs', db.from('jobs').select('id,title,address,stage,assigned_to,contact_id,status_note,created_at,lead_progress_stage,lead_progress_dead_reason,lead_progress_updated_at')),
    safeQuery('contacts', db.from('contacts').select('id,name,phone,email,address,lead_source,assigned_to')),
    safeQuery('routes', db.from('routes').select('*')),
    safeQuery('visits', db.from('prospecting_visits').select('*')),
    safeQuery('orders', db.from('measurement_orders').select('*')),
    safeQuery('reviews', db.from('reviews').select('*')),
    safeQuery('production', db.from('production_plans').select('*'))
  ]);
}

function login(msg=''){
  app.innerHTML = `<div class="login"><div class="card"><div class="brand">HAMRIQ</div><p class="muted">Roofing workflow. All in one place.</p>${msg?`<div class="notice section">${esc(msg)}</div>`:''}<div class="field section"><label>Email</label><input id="email" class="input" type="email" autocomplete="username"></div><div class="field section"><label>Password</label><input id="pw" class="input" type="password" autocomplete="current-password"></div><button class="btn accent big section" id="sign">Sign in</button><p id="err" class="muted"></p></div></div>`;
  document.querySelector('#sign').onclick = async () => {
    const res = await db.auth.signInWithPassword({ email: email.value, password: pw.value });
    if (res.error) err.textContent = res.error.message; else boot();
  };
}

function render(){
  const tabs = visibleTabs();
  if (!tabs.includes(tab)) tab = 'Today';
  app.innerHTML = `<div class="shell"><header class="top"><div class="brand">HAMRIQ <span>${esc(company.name || '')}</span></div><div class="row"><button class="btn accent" id="hammyTop">Hammy</button><span>${esc(profile.display_name)} · ${esc(profile.role)}</span><button class="btn secondary" id="out">Sign out</button></div></header><div class="layout"><nav>${tabs.map(t=>`<button class="${tab===t?'active':''}" data-tab="${t}">${t}</button>`).join('')}</nav><main class="main" id="main"></main></div><div class="bottom-bar">${['Today','Customers','Jobs','Hammy'].map(t=>`<button class="${tab===t?'active':''}" data-tab="${t}">${t}</button>`).join('')}</div><button class="fab" id="hammyFab">Hammy</button></div>`;
  document.querySelectorAll('[data-tab]').forEach(b => b.onclick = () => { tab = b.dataset.tab; render(); });
  document.querySelector('#hammyTop').onclick = openHammyPanel;
  document.querySelector('#hammyFab').onclick = openHammyPanel;
  document.querySelector('#out').onclick = () => db.auth.signOut().then(boot);
  pages[tab](document.querySelector('#main'));
}

function contactFor(job){ return data.contacts.find(c => c.id === job.contact_id) || {}; }
function jobTitle(job){ const c = contactFor(job); return c.name || job.title || 'Customer'; }
function statusColor(stage){ if(stage==='DEAD') return 'red'; if(['First contact','Claim filed','Supplement submitted'].includes(stage)) return 'yellow'; if(['Completed','Build contract signed'].includes(stage)) return 'green'; if(['Inspection complete','Contingency signed','Claim approved'].includes(stage)) return 'blue'; return 'gray'; }
function pill(v){ return `<span class="pill ${statusColor(v)}">${esc(v)}</span>`; }
function nextAction(job){
  const s = stageOf(job);
  if (s === 'First contact') return ['Call homeowner','Confirm contact and schedule inspection.'];
  if (s === 'Inspection complete') return ['Send proposal','Review photos, clean up notes, and send estimate.'];
  if (s === 'Contingency signed') return ['File / check claim','Add carrier and adjuster info.'];
  if (s === 'Claim filed') return ['Confirm adjuster meeting','Set date and attach claim details.'];
  if (s === 'Claim approved') return ['Schedule contract review','Review scope, selections, and signature.'];
  if (s === 'Supplement submitted') return ['Follow up on supplement','Check carrier response and next review date.'];
  if (s === 'Build contract signed') return ['Production handoff','Make sure job is ready for production.'];
  if (s === 'Completed') return ['Ask for review','Run internal rating first.'];
  return ['Review file','Check notes and choose the next step.'];
}
function activityAge(job){
  const d = job.lead_progress_updated_at || job.created_at;
  if (!d) return 'No activity date';
  const days = Math.max(0, Math.floor((Date.now() - new Date(d).getTime()) / 86400000));
  if (days === 0) return 'updated today';
  if (days === 1) return '1 day old';
  return `${days} days old`;
}
function attentionJobs(){ return data.jobs.filter(j => !['Completed','DEAD'].includes(stageOf(j))).slice(0,8); }
function table(headers, rows){ return `<div class="card section"><table class="table"><thead><tr>${headers.map(h=>`<th>${h}</th>`).join('')}</tr></thead><tbody>${rows.length?rows.map(r=>`<tr>${r.map(c=>`<td>${String(c).startsWith('<')?c:esc(c)}</td>`).join('')}</tr>`).join(''):`<tr><td colspan="${headers.length}"><div class="empty">Nothing here yet.</div></td></tr>`}</tbody></table></div>`; }

const pages = {
  Today(el){
    const active = data.jobs.filter(j => !['Completed','DEAD'].includes(stageOf(j)));
    const stale = active.filter(j => /days old$/.test(activityAge(j))).length;
    const first = active[0];
    const na = first ? nextAction(first) : ['Create or open a customer','No urgent rep action right now.'];
    el.innerHTML = `<div class="grid two"><div class="card hero"><p class="muted">Rep command center</p><h1>Today</h1><p>No clutter. Just what moves jobs forward.</p><div class="row section"><button class="btn good big" id="startDay">Start My Day</button><button class="btn secondary big" id="addLead">+ New Lead</button></div></div><div class="card"><p class="muted">Top next action</p><h2>${esc(na[0])}</h2><p class="muted">${esc(na[1])}</p><button class="btn accent big" id="openFirst">Open Customer</button></div></div><div class="grid cards section"><div class="card"><div class="muted">Active customers</div><div class="metric">${active.length}</div></div><div class="card"><div class="muted">Need attention</div><div class="metric">${stale}</div></div><div class="card"><div class="muted">Door hangers</div><div class="metric">${data.visits.filter(v=>v.door_hanger_placed).length}</div></div><div class="card"><div class="muted">Open inspections/proposals</div><div class="metric">${active.filter(j=>['First contact','Inspection complete'].includes(stageOf(j))).length}</div></div></div><div class="section row between"><h2>Action cards</h2><button class="btn secondary" id="wrapDay">Wrap up day</button></div><div class="grid cards section">${attentionJobs().map(jobCard).join('') || `<div class="empty">Nothing urgent. Check hot leads or follow-ups.</div>`}</div>`;
    document.querySelector('#addLead').onclick = leadModal;
    document.querySelector('#startDay').onclick = () => toast('Your day is sorted by next action. Start with the first card.');
    document.querySelector('#wrapDay').onclick = wrapUpModal;
    document.querySelector('#openFirst').onclick = () => { tab='Customers'; render(); };
    bindProgressButtons();
  },
  Customers(el){
    el.innerHTML = `<div class="row between"><div><h1>Customers</h1><p class="muted">One-screen files: contact, status, next step, and recent activity.</p></div><button class="btn accent" id="newLead">+ Customer</button></div><div class="grid cards section">${data.jobs.map(customerCard).join('') || `<div class="empty">No customers yet. Create a lead to start.</div>`}</div>`;
    document.querySelector('#newLead').onclick = leadModal;
    bindProgressButtons();
  },
  Jobs(el){
    el.innerHTML = `<div class="row between"><div><h1>Jobs</h1><p class="muted">Simple status system. Main action first, details later.</p></div><button class="btn accent" id="new">+ New Lead</button></div>${table(['Customer','Address','Stage','Age','Main action'], data.jobs.map(j => [jobTitle(j), j.address || '', pill(stageOf(j)), activityAge(j), `<button class="btn secondary" data-progress="${j.id}">${esc(nextAction(j)[0])}</button>`]))}`;
    document.querySelector('#new').onclick = leadModal;
    bindProgressButtons();
  },
  Prospecting(el){
    el.innerHTML = `<div class="row between"><div><h1>Prospecting</h1><p class="muted">Fast door-knocking updates. No reports to fill out.</p></div><button class="btn accent" id="visit">Log Visit</button></div>${table(['Address','Outcome','Door hanger','Note'], data.visits.map(v => [v.address, v.outcome, v.door_hanger_placed ? pill('PLACED') : '', v.note || '']))}`;
    document.querySelector('#visit').onclick = visitModal;
  },
  Marketing(el){
    el.innerHTML = `<h1>Marketing View</h1><p class="muted">Separate manager view for campaign, QR, source, vendor, budget and ROI data.</p><div class="grid cards section"><div class="card"><h3>Campaigns</h3><p class="muted">Create, clone, archive, review, and compare campaigns.</p></div><div class="card"><h3>QR scan master list</h3><p class="muted">Track scans without automatic notifications.</p></div><div class="card"><h3>Marketing Review</h3><p class="muted">Date range + all/individual campaigns + AI summary + full KPI snapshot.</p><button class="btn accent section" onclick="alert('Marketing Review UI placeholder ready for backend wiring.')">Marketing Review</button></div><div class="card"><h3>Vendors</h3><p class="muted">Vendor score, issues, invoices, contracts, and do-not-use status.</p></div></div>`;
  },
  Hammy(el){
    el.innerHTML = `<h1>Hammy</h1><p class="muted">Command Hammy is for voice/actions. Help lives inside the same Hammy panel as “What am I looking at?”</p><div class="card section"><button class="btn accent big" id="holdSpeak">Hold to speak</button><button class="btn secondary big section" id="explain">What am I looking at?</button><button class="btn secondary big section" id="next">What should I do next?</button><p class="muted section" id="hammyStatus">Hold to speak, or ask for a plain explanation.</p></div>`;
    document.querySelector('#explain').onclick = () => showHammyAnswer(screenSummary());
    document.querySelector('#next').onclick = () => showHammyAnswer(nextSummary());
    document.querySelector('#holdSpeak').onpointerdown = () => hammyStatus.textContent = 'Listening... release to send.';
    document.querySelector('#holdSpeak').onpointerup = () => hammyStatus.textContent = 'Voice request captured. Voice processing hooks are ready for connection.';
  },
  Routes(el){ const rows=data.routes.map(r=>[r.name,r.route_date,pill(r.status||'draft'),r.optimization_mode||'shortest_time']); el.innerHTML=`<div class="row between"><div><h1>Routes</h1><p class="muted">Reps can create routes; managers see company routes.</p></div><button class="btn accent" id="route">+ Route</button></div>${table(['Route','Date','Status','Mode'],rows)}`; document.querySelector('#route').onclick=routeModal; },
  Measurements(el){ el.innerHTML = `<h1>Measurements</h1><div class="card section"><div class="notice"><b>External provider notice:</b> ${esc(company.additional_measurement_subscription_notice || 'Additional subscription required. Contact HAMRIQ for information.')}</div><p>Provider: <b>${esc(company.measurement_provider || 'HAMRIQ')}</b></p><p class="muted">${company.manager_approve_all_measurements ? 'Manager approve-all is enabled.' : 'Rep orders require manager approval by default.'}</p></div>${table(['Job','Provider','Status','Approved'], data.orders.map(o => [jobName(o.job_id), o.provider, pill(o.status), o.approved_at || '']))}`; },
  Pricing(el){ el.innerHTML = `<h1>Pricing</h1><div class="card section"><h3>Manager-controlled pricing</h3><p>HAMRIQ uses owner/manager price lists. AI does not invent prices.</p><p class="muted">Price-list editing stays protected from reps.</p></div>`; },
  Reviews(el){ el.innerHTML = `<h1>Reviews</h1><div class="card section"><p><b>Workflow:</b> internal rating first. If 4–5 stars, send public review links.</p></div>${table(['Job','Rating','External request'], data.reviews.map(r => [jobName(r.job_id), r.rating ? r.rating + ' ★' : '', pill(r.external_request_status || 'not_requested')]))}`; },
  Production(el){ el.innerHTML = `<h1>Production</h1><p class="muted">Manager production view. Reps only see production updates relevant to their jobs.</p>${table(['Job','Progress','Address','Note'], data.jobs.filter(j=>['Build contract signed','Completed'].includes(stageOf(j))).map(j => [j.title, pill(stageOf(j)), j.address, j.status_note || '']))}`; }
};

function jobCard(j){ const c=contactFor(j), a=nextAction(j); return `<div class="quick-card"><div class="row between"><strong>${esc(jobTitle(j))}</strong>${pill(stageOf(j))}</div><p class="muted mini">${esc(j.address || c.address || '')}</p><p><b>${esc(a[0])}</b><br><span class="muted">${esc(a[1])}</span></p><div class="row"><button class="btn accent" data-progress="${j.id}">Update Status</button><button class="btn ghost" onclick="alert('Add Update: voice note, photo, task, appointment, message, or status change.')">Add Update</button></div></div>`; }
function customerCard(j){ const c=contactFor(j), a=nextAction(j); return `<div class="card"><div class="row between"><h3>${esc(jobTitle(j))}</h3>${pill(stageOf(j))}</div><p class="muted">${esc(j.address || c.address || 'No address')}</p><div class="stack section"><div><b>Next:</b> ${esc(a[0])}<br><span class="muted">${esc(a[1])}</span></div><div><b>Contact:</b> ${esc(c.phone || 'No phone')} ${c.email ? ' · '+esc(c.email) : ''}</div><div><b>Last activity:</b> ${esc(activityAge(j))}</div></div><div class="row section"><button class="btn accent" data-progress="${j.id}">Update Status</button><button class="btn secondary" onclick="alert('Customer summary: current situation, last contact, waiting reason, and next action.')">Summarize</button></div></div>`; }
function bindProgressButtons(){ document.querySelectorAll('[data-progress]').forEach(b => b.onclick = () => progressModal(data.jobs.find(j => j.id === b.dataset.progress))); }
function jobName(id){ return data.jobs.find(j=>j.id===id)?.title || id || ''; }

function modal(title, body, onReady=()=>{}){ const wrap=document.createElement('div'); wrap.className='modal'; wrap.innerHTML=`<div><div class="row between"><h2>${title}</h2><button class="btn secondary" id="close">Close</button></div>${body}</div>`; document.body.append(wrap); wrap.querySelector('#close').onclick=()=>wrap.remove(); onReady(wrap); }
function toast(msg){ modal('HAMRIQ', `<p>${esc(msg)}</p>`, w=>setTimeout(()=>w.remove(),1600)); }
function progressModal(job){
  const current = stageOf(job);
  modal('Update Status', `<p><b>${esc(jobTitle(job))}</b></p><div class="field"><label>Status</label><select id="stage" class="input">${leadStages.map(s=>`<option ${s===current?'selected':''}>${s}</option>`).join('')}</select></div><div class="field section"><label>Note / reason</label><textarea id="comment" class="input" placeholder="Example: No answer, estimate sent, waiting on insurance, needs spouse approval.">${esc(job.lead_progress_dead_reason || '')}</textarea></div><button class="btn accent big section" id="save">Save Status</button>`, w=>{
    w.querySelector('#save').onclick = async () => {
      const stage=w.querySelector('#stage').value, comment=w.querySelector('#comment').value.trim();
      if(stage==='DEAD' && !comment) return alert('Dead/lost requires a reason.');
      const res = await db.rpc('progress_lead_stage', { p_job_id: job.id, p_stage: stage, p_comment: comment });
      if(res.error) return alert(res.error.message);
      w.remove(); await load(); render();
    };
  });
}
function leadModal(){
  modal('Create Lead', `<div class="form"><div class="field"><label>Name</label><input id="n" class="input"></div><div class="field"><label>Phone</label><input id="p" class="input"></div><div class="field"><label>Address</label><input id="a" class="input"></div><div class="field"><label>Lead source</label><select id="s" class="input">${sources.map(x=>`<option>${x}</option>`).join('')}</select></div></div><p class="muted section">Only the basics first. Clean up later.</p><button class="btn accent big section" id="save">Create Lead</button>`, w=>{
    w.querySelector('#save').onclick = async () => {
      const contact = await db.from('contacts').insert({ company_id: company.id, name:n.value, phone:p.value, address:a.value, lead_source:s.value, assigned_to:profile.id, created_by:profile.id }).select('id').single();
      if(contact.error) return alert(contact.error.message);
      const job = await db.from('jobs').insert({ company_id:company.id, contact_id:contact.data.id, title:n.value + ' Roof', address:a.value, assigned_to:profile.id, created_by:profile.id });
      if(job.error) return alert(job.error.message);
      w.remove(); await load(); tab='Customers'; render();
    };
  });
}
function visitModal(){
  modal('Log Visit', `<div class="form"><div class="field"><label>Address</label><input id="a" class="input"></div><div class="field"><label>Outcome</label><select id="o" class="input"><option>No response</option><option>Not interested</option><option>Do not follow up</option><option>Set for follow-up</option><option>Interested</option><option>Door hanger placed</option></select></div></div><label class="section"><input id="d" type="checkbox"> DOOR HANGER PLACED</label><div class="field section"><label>Note</label><textarea id="note" class="input"></textarea></div><button class="btn accent big section" id="save">Save Visit</button>`, w=>{
    w.querySelector('#save').onclick = async () => { const res=await db.from('prospecting_visits').insert({ request_id:crypto.randomUUID(), company_id:company.id, assigned_to:profile.id, address:a.value, outcome:o.value, door_hanger_placed:d.checked || o.value==='Door hanger placed', note:note.value }); if(res.error) return alert(res.error.message); w.remove(); await load(); render(); };
  });
}
function routeModal(){ modal('Create Route', `<div class="form"><div class="field"><label>Name</label><input id="n" class="input" value="My Route"></div><div class="field"><label>Date</label><input id="d" class="input" type="date" value="${todayISO()}"></div><div class="field"><label>Optimization</label><select id="m" class="input"><option value="shortest_time">Shortest drive time</option><option value="shortest_distance">Shortest distance</option></select></div></div><button class="btn accent big section" id="save">Create Route</button>`, w=>{ w.querySelector('#save').onclick=async()=>{const res=await db.from('routes').insert({company_id:company.id,name:n.value,route_date:d.value,assigned_to:profile.id,optimization_mode:m.value,created_by:profile.id}); if(res.error) return alert(res.error.message); w.remove(); await load(); render();};}); }
function wrapUpModal(){ modal('Wrap Up Your Day', `<ul class="screen-steps"><li>Finish unsaved notes.</li><li>Log outcomes for completed appointments.</li><li>Make sure every active customer has a next step.</li><li>Check photos are synced.</li><li>Snooze or reschedule anything that cannot happen today.</li></ul>`); }
function screenSummary(){ return `You are on the ${tab} screen. HAMRIQ keeps this screen focused on the next useful action instead of showing every possible setting. Use the main button first, then details only when needed.`; }
function nextSummary(){ const j=attentionJobs()[0]; if(!j) return 'No urgent customer is waiting. Create a lead, check follow-ups, or review recent customers.'; const a=nextAction(j); return `Start with ${jobTitle(j)}. Recommended action: ${a[0]}. ${a[1]}`; }
function showHammyAnswer(text){ modal('Hammy', `<p>${esc(text)}</p><div class="notice section"><b>Need more help?</b><ol class="screen-steps"><li>Look for the big main button.</li><li>Complete the first required action.</li><li>Add a note if something changed.</li><li>Make sure there is a next step.</li></ol></div>`); }
function openHammyPanel(){ modal('Hammy', `<div class="grid cards"><button class="btn accent big" id="voice">Hold to speak</button><button class="btn secondary big" id="look">What am I looking at?</button><button class="btn secondary big" id="next">What should I do next?</button><button class="btn secondary big" id="steps">Show app steps</button></div><p class="muted section" id="hm">Command Hammy is for actions. Help is a plain-language explainer inside this panel.</p>`, w=>{ w.querySelector('#voice').onpointerdown=()=>hm.textContent='Listening... release to send.'; w.querySelector('#voice').onpointerup=()=>hm.textContent='Voice request captured. Voice processing hooks are ready.'; w.querySelector('#look').onclick=()=>showHammyAnswer(screenSummary()); w.querySelector('#next').onclick=()=>showHammyAnswer(nextSummary()); w.querySelector('#steps').onclick=()=>showHammyAnswer('App steps: open Today, pick the first action card, complete the main action, add update, then make sure the customer has a next step.'); }); }

boot();
