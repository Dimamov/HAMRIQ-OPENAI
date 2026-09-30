import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const config = await fetch('./src/lib/config.json').then(r => r.json());
const db = createClient(config.supabaseUrl, config.supabasePublishableKey);
const app = document.querySelector('#app');
let profile, company, tab = 'Home';
let data = { jobs: [], contacts: [], routes: [], visits: [], orders: [], reviews: [], production: [] };
const tabs = ['Home','Jobs','Contacts','Prospecting','Routes','Measurements','Pricing','Reviews','Production'];
const sources = ['Unknown','Referral','Door knocking','Door hanger','Storm lead','Internet','Past customer','Insurance','Other'];
const esc = v => String(v ?? '').replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));

async function boot(){
  const { data: { session } } = await db.auth.getSession();
  if (!session) return login();
  const ctx = await db.rpc('workspace_context');
  if (ctx.error || !ctx.data) return login('Your user is not provisioned in HAMRIQ yet.');
  profile = ctx.data.user; company = ctx.data.company;
  await load(); render();
}

async function load(){
  const tables = await Promise.all([
    db.from('jobs').select('id,title,address,stage,assigned_to,contact_id,status_note,created_at'),
    db.from('contacts').select('id,name,phone,email,address,lead_source,assigned_to'),
    db.from('routes').select('*'),
    db.from('prospecting_visits').select('*'),
    db.from('measurement_orders').select('*'),
    db.from('reviews').select('*'),
    db.from('production_plans').select('*')
  ]);
  ['jobs','contacts','routes','visits','orders','reviews','production'].forEach((k,i)=>data[k]=tables[i].data || []);
}

function login(msg=''){
  app.innerHTML = `<div class="login"><div class="card"><div class="brand">HAMRIQ</div><p class="muted">Roofing workflow. All in one place.</p>${msg?`<div class="notice">${esc(msg)}</div>`:''}<div class="field"><label>Email</label><input id="email" class="input" type="email"></div><div class="field"><label>Password</label><input id="pw" class="input" type="password"></div><button class="btn accent" id="sign">Sign in</button><p id="err" class="muted"></p></div></div>`;
  document.querySelector('#sign').onclick = async () => {
    const res = await db.auth.signInWithPassword({ email: email.value, password: pw.value });
    if (res.error) err.textContent = res.error.message; else boot();
  };
}

function render(){
  app.innerHTML = `<div class="shell"><header class="top"><div class="brand">HAMRIQ <span>${esc(company.name || '')}</span></div><div class="row"><span>${esc(profile.display_name)} · ${esc(profile.role)}</span><button class="btn secondary" id="out">Sign out</button></div></header><div class="layout"><nav>${tabs.map(t=>`<button class="${tab===t?'active':''}" data-tab="${t}">${t}</button>`).join('')}</nav><main class="main" id="main"></main></div></div>`;
  document.querySelectorAll('[data-tab]').forEach(b => b.onclick = () => { tab = b.dataset.tab; render(); });
  document.querySelector('#out').onclick = () => db.auth.signOut().then(boot);
  pages[tab](document.querySelector('#main'));
}

const pages = {
  Home(el){
    const stages = ['Lead','Measured','Estimated','Contract sent','Signed','Complete'];
    const counts = Object.fromEntries(stages.map(s => [s, data.jobs.filter(j => j.stage === s).length]));
    const done = data.jobs.length ? Math.round((counts.Complete / data.jobs.length) * 100) : 0;
    el.innerHTML = `<div class="row between"><div><h1>Command Center</h1><p class="muted">Every job, every stage, one view.</p></div><button class="btn accent" id="newlead">+ New Lead</button></div><div class="grid cards section">${stages.map(s=>`<div class="card"><div class="muted">${s}</div><div class="metric">${counts[s]}</div></div>`).join('')}</div><div class="card section"><div class="row between"><b>Production progress</b><span>${done}%</span></div><div class="progress section"><i style="width:${done}%"></i></div></div><div class="card section"><b>AI notice</b><p class="muted">${esc(company.ai_training_notice || 'More data offers better HAMRIQ results.')}</p></div>`;
    document.querySelector('#newlead').onclick = leadModal;
  },
  Jobs(el){
    el.innerHTML = `<div class="row between"><div><h1>Jobs</h1><p class="muted">A visible stage/status bar stays attached to every account.</p></div><button class="btn accent" id="new">+ New Lead</button></div>${table(['Customer','Address','Stage','Note'], data.jobs.map(j => { const c = data.contacts.find(x=>x.id===j.contact_id); return [c?.name || j.title, j.address, pill(j.stage), j.status_note || '']; }))}`;
    document.querySelector('#new').onclick = leadModal;
  },
  Contacts(el){
    el.innerHTML = `<h1>Contacts</h1>${table(['Name','Phone','Lead source','Address'], data.contacts.map(c => [c.name, c.phone, pill(c.lead_source || 'Unknown'), c.address]))}`;
  },
  Prospecting(el){
    el.innerHTML = `<div class="row between"><div><h1>Prospecting</h1><p class="muted">Field outcome tracking with DOOR HANGER PLACED.</p></div><button class="btn accent" id="visit">Log Visit</button></div>${table(['Address','Outcome','Door hanger','Note'], data.visits.map(v => [v.address, v.outcome, v.door_hanger_placed ? pill('PLACED') : '', v.note || '']))}`;
    document.querySelector('#visit').onclick = visitModal;
  },
  Routes(el){
    const rows = data.routes.map(r => [r.name, r.route_date, pill(r.status), r.optimization_mode]);
    el.innerHTML = `<div class="row between"><div><h1>Routes</h1><p class="muted">Reps can create routes. Managers can see company routes.</p></div><button class="btn accent" id="route">+ Route</button></div>${table(['Route','Date','Status','Mode'], rows)}`;
    document.querySelector('#route').onclick = routeModal;
  },
  Measurements(el){
    el.innerHTML = `<h1>Measurements</h1><div class="card section"><div class="notice"><b>External provider notice:</b> ${esc(company.additional_measurement_subscription_notice || 'Additional subscription required. Contact HAMRIQ for information.')}</div><p>Provider: <b>${esc(company.measurement_provider || 'HAMRIQ')}</b></p><p class="muted">${company.manager_approve_all_measurements ? 'Manager approve-all is enabled.' : 'Rep orders require manager approval by default.'}</p></div>${table(['Job','Provider','Status','Approved'], data.orders.map(o => [jobName(o.job_id), o.provider, pill(o.status), o.approved_at || '']))}`;
  },
  Pricing(el){
    el.innerHTML = `<h1>Pricing</h1><div class="card section"><h3>Manager-controlled pricing</h3><p>HAMRIQ uses owner/manager price lists. AI does not invent prices.</p><p class="muted">Price-list editing stays protected from reps.</p></div>`;
  },
  Reviews(el){
    el.innerHTML = `<h1>Reviews</h1><div class="card section"><p><b>Approved workflow:</b> internal rating first. If 4–5 stars, send Google/Facebook review links, plus manager-added review sites.</p></div>${table(['Job','Rating','External request'], data.reviews.map(r => [jobName(r.job_id), r.rating ? r.rating + ' ★' : '', pill(r.external_request_status || 'not_requested')]))}`;
  },
  Production(el){
    el.innerHTML = `<h1>Production</h1><p class="muted">Production view begins with signed jobs and production notes.</p>${table(['Job','Stage','Address','Note'], data.jobs.filter(j=>['Signed','Complete'].includes(j.stage)).map(j => [j.title, pill(j.stage), j.address, j.status_note || '']))}`;
  }
};

function table(headers, rows){ return `<div class="card section"><table class="table"><thead><tr>${headers.map(h=>`<th>${h}</th>`).join('')}</tr></thead><tbody>${rows.map(r=>`<tr>${r.map(c=>`<td>${typeof c === 'string' && c.startsWith('<span') ? c : esc(c)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`; }
function pill(v){ return `<span class="pill">${esc(v)}</span>`; }
function jobName(id){ return data.jobs.find(j=>j.id===id)?.title || id || ''; }
function modal(title, body, onSave){
  const wrap = document.createElement('div'); wrap.className='modal';
  wrap.innerHTML = `<div><div class="row between"><h2>${title}</h2><button class="btn secondary" id="close">Close</button></div>${body}</div>`;
  document.body.append(wrap); wrap.querySelector('#close').onclick=()=>wrap.remove(); onSave(wrap);
}
function leadModal(){
  modal('Create Lead', `<div class="form"><div class="field"><label>Name</label><input id="n" class="input"></div><div class="field"><label>Phone</label><input id="p" class="input"></div><div class="field"><label>Address</label><input id="a" class="input"></div><div class="field"><label>Lead source</label><select id="s" class="input">${sources.map(x=>`<option>${x}</option>`).join('')}</select></div></div><button class="btn accent section" id="save">Create</button>`, w => {
    w.querySelector('#save').onclick = async () => {
      const contact = await db.from('contacts').insert({ company_id: company.id, name:n.value, phone:p.value, address:a.value, lead_source:s.value, assigned_to:profile.id, created_by:profile.id }).select('id').single();
      if (contact.error) return alert(contact.error.message);
      const job = await db.from('jobs').insert({ company_id:company.id, contact_id:contact.data.id, title:n.value + ' Roof', address:a.value, assigned_to:profile.id, created_by:profile.id });
      if (job.error) return alert(job.error.message);
      w.remove(); await load(); render();
    };
  });
}
function visitModal(){
  modal('Log Prospecting Visit', `<div class="form"><div class="field"><label>Address</label><input id="a" class="input"></div><div class="field"><label>Outcome</label><select id="o" class="input"><option>No response</option><option>Not interested</option><option>Do not follow up</option><option>Set for follow-up</option><option>Interested</option></select></div></div><label class="section"><input id="d" type="checkbox"> DOOR HANGER PLACED</label><div class="field section"><label>Note</label><textarea id="note" class="input"></textarea></div><button class="btn accent section" id="save">Save</button>`, w => {
    w.querySelector('#save').onclick = async () => {
      const res = await db.from('prospecting_visits').insert({ request_id:crypto.randomUUID(), company_id:company.id, assigned_to:profile.id, address:a.value, outcome:o.value, door_hanger_placed:d.checked, note:note.value });
      if (res.error) return alert(res.error.message);
      w.remove(); await load(); render();
    };
  });
}
function routeModal(){
  modal('Create Route', `<div class="form"><div class="field"><label>Name</label><input id="n" class="input" value="My Route"></div><div class="field"><label>Date</label><input id="d" class="input" type="date"></div><div class="field"><label>Optimization</label><select id="m" class="input"><option value="shortest_time">Shortest drive time</option><option value="shortest_distance">Shortest distance</option></select></div></div><button class="btn accent section" id="save">Create route</button>`, w => {
    w.querySelector('#save').onclick = async () => {
      const res = await db.from('routes').insert({ company_id:company.id, name:n.value, route_date:d.value, assigned_to:profile.id, optimization_mode:m.value, created_by:profile.id });
      if (res.error) return alert(res.error.message);
      w.remove(); await load(); render();
    };
  });
}

boot();
