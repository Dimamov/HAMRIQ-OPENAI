import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const config = await fetch('./src/lib/config.json').then(r => r.json());
const host = location.hostname.toLowerCase();
const params = new URLSearchParams(location.search);
const isDemoHost = host === 'hamriq.app' || host === 'www.hamriq.app' || params.get('demo') === '1';
const DEMO_USER = 'demo';
const DEMO_PASS = 'HamriqDemo2026!';
const app = document.querySelector('#app');
const esc = v => String(v ?? '').replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));

if (isDemoHost) bootDemo(); else bootLive();

/* ========================= DEMO MODE ========================= */
const demoRoles = ['Management','Sales Rep','Canvasser','Billing','Production','Marketing','Admin'];
let demoRole = localStorage.getItem('hamriq_demo_role') || 'Management';
let demoTab = 'Today';
const demoAuthed = () => localStorage.getItem('hamriq_demo_auth') === 'ok';
const setDemoRole = r => { demoRole = r; localStorage.setItem('hamriq_demo_role', r); demoTab = 'Today'; renderDemo(); };

const demo = {
  customers: [
    {id:1,name:'Bob Smith',city:'Grand Blanc',address:'4128 Maple Ridge Dr, Grand Blanc, MI',phone:'810-555-0184',source:'Door hanger',stage:'Hot lead',priority:'Hot',rep:'Mia Carter',canvasser:'Evan Brooks',carrier:'State Farm',claim:'SF-62491',value:18800,next:'Call homeowner',status:'New storm lead from door hanger scan',color:'red'},
    {id:2,name:'Maria Gonzalez',city:'Clarkston',address:'7651 Sashabaw Rd, Clarkston, MI',phone:'248-555-0199',source:'Referral',stage:'Inspection scheduled',priority:'High',rep:'Noah Reed',canvasser:'—',carrier:'Allstate',claim:'AS-88401',value:24200,next:'Arrive for inspection',status:'Prefers text. Appointment today at 3:30 PM.',color:'blue'},
    {id:3,name:'James Walker',city:'Davison',address:'317 Oak Hill Ct, Davison, MI',phone:'810-555-0112',source:'Storm campaign',stage:'Inspection complete',priority:'Normal',rep:'Mia Carter',canvasser:'Kara Mills',carrier:'Farmers',claim:'FM-11920',value:21750,next:'Send proposal',status:'Photos complete. Gutters and soft metals documented.',color:'yellow'},
    {id:4,name:'Alyssa Chen',city:'Troy',address:'1884 Long Lake Rd, Troy, MI',phone:'248-555-0137',source:'Google Ads',stage:'Auto generated lead',priority:'Low',rep:'Unassigned',canvasser:'—',carrier:'Unknown',claim:'—',value:0,next:'Review online lead',status:'Auto generated, low priority. Needs human review.',color:'gray'},
    {id:5,name:'Robert Keller',city:'Lansing',address:'920 W Willow St, Lansing, MI',phone:'517-555-0166',source:'Past customer',stage:'Proposal sent',priority:'Normal',rep:'Noah Reed',canvasser:'—',carrier:'USAA',claim:'UA-77402',value:31100,next:'Follow up',status:'Proposal opened twice. Waiting on spouse approval.',color:'yellow'},
    {id:6,name:'Diane Harper',city:'Ann Arbor',address:'1409 Geddes Ave, Ann Arbor, MI',phone:'734-555-0171',source:'Website',stage:'Carrier estimate received',priority:'High',rep:'Mia Carter',canvasser:'—',carrier:'Progressive',claim:'PG-55019',value:27600,next:'Review estimate gap',status:'Carrier missing drip edge and several soft metal items.',color:'red'},
    {id:7,name:'Mike O’Connor',city:'Royal Oak',address:'2216 Vinsetta Blvd, Royal Oak, MI',phone:'248-555-0188',source:'Referral',stage:'Contract signed',priority:'Normal',rep:'Noah Reed',canvasser:'—',carrier:'Liberty Mutual',claim:'LM-30012',value:29400,next:'Production handoff',status:'Selections complete. Awaiting material order.',color:'green'},
    {id:8,name:'Patrice Williams',city:'Kalamazoo',address:'510 Westnedge Ave, Kalamazoo, MI',phone:'269-555-0140',source:'Facebook Ads',stage:'In production',priority:'Normal',rep:'Mia Carter',canvasser:'—',carrier:'Travelers',claim:'TV-91302',value:34600,next:'Check production update',status:'Install scheduled Friday. Permit approved.',color:'blue'},
    {id:9,name:'George Patel',city:'Novi',address:'45311 Ten Mile Rd, Novi, MI',phone:'248-555-0125',source:'Door knocking',stage:'Final invoice',priority:'Normal',rep:'Noah Reed',canvasser:'Evan Brooks',carrier:'Nationwide',claim:'NW-81007',value:22100,next:'Collect final balance',status:'Mortgage check pending endorsement.',color:'yellow'},
    {id:10,name:'Erica Daniels',city:'Traverse City',address:'881 Peninsula Dr, Traverse City, MI',phone:'231-555-0105',source:'QR scan',stage:'Completed',priority:'Normal',rep:'Mia Carter',canvasser:'Kara Mills',carrier:'Auto-Owners',claim:'AO-77419',value:38500,next:'Ask for review',status:'Internal rating 5 stars. Ready for public review request.',color:'green'},
    {id:11,name:'Caleb Morgan',city:'Flint',address:'602 Miller Rd, Flint, MI',phone:'810-555-0160',source:'Canvasser',stage:'No answer follow-up',priority:'Warm',rep:'Noah Reed',canvasser:'Evan Brooks',carrier:'Unknown',claim:'—',value:0,next:'Text homeowner',status:'Door hanger placed; no response yet.',color:'gray'},
    {id:12,name:'Lena Rossi',city:'Brighton',address:'3098 Grand River Ave, Brighton, MI',phone:'810-555-0181',source:'Referral',stage:'Supplement drafted',priority:'High',rep:'Mia Carter',canvasser:'—',carrier:'State Farm',claim:'SF-91240',value:26200,next:'Manager review supplement',status:'Supplement draft ready; human review required.',color:'red'}
  ],
  campaigns: [
    {name:'Grand Blanc Hail Door Hangers',type:'Door hanger',area:'Grand Blanc / Flint',cost:1850,leads:41,inspections:17,sold:6,revenue:143200,roi:'Strong',health:'Healthy'},
    {name:'Clarkston Referral Push',type:'Referral',area:'Clarkston / Waterford',cost:450,leads:13,inspections:9,sold:4,revenue:98800,roi:'Excellent',health:'Healthy'},
    {name:'Facebook Storm Lead Test',type:'Facebook Ads',area:'Metro Detroit',cost:1200,leads:57,inspections:8,sold:1,revenue:24200,roi:'Weak',health:'Watch'},
    {name:'Novi QR Yard Sign Test',type:'QR campaign',area:'Novi / Wixom',cost:760,leads:22,inspections:6,sold:2,revenue:51500,roi:'Good',health:'Needs review'}
  ],
  vendors: [
    {name:'Michigan Print Co.',type:'Print shop',score:91,status:'Preferred',issues:1,spend:4120,roi:'Strong'},
    {name:'BluePeak Ads',type:'Digital ads',score:68,status:'Watch list',issues:3,spend:6900,roi:'Mixed'},
    {name:'Northline Signs',type:'Yard signs',score:84,status:'Approved',issues:0,spend:2300,roi:'Good'}
  ],
  production: [
    {job:'Mike O’Connor',city:'Royal Oak',status:'Ready to schedule',crew:'Unassigned',materials:'Order pending',permit:'Not required'},
    {job:'Patrice Williams',city:'Kalamazoo',status:'Scheduled Friday',crew:'Crew B',materials:'Delivered',permit:'Approved'},
    {job:'George Patel',city:'Novi',status:'Completed',crew:'Crew A',materials:'Complete',permit:'Closed'}
  ],
  billing: [
    {customer:'George Patel',type:'Final balance',amount:4200,status:'Mortgage check pending'},
    {customer:'Michigan Print Co.',type:'Marketing invoice',amount:1850,status:'Submitted to billing'},
    {customer:'Patrice Williams',type:'Progress payment',amount:11200,status:'Paid'},
    {customer:'Diane Harper',type:'Deductible',amount:2500,status:'Due at contract'}
  ],
  canvass: [
    {street:'Miller Rd, Flint',knocks:34,contacts:9,doorhangers:21,leads:3,hot:1},
    {street:'Sashabaw Rd, Clarkston',knocks:22,contacts:7,doorhangers:12,leads:4,hot:2},
    {street:'Grand River Ave, Brighton',knocks:28,contacts:6,doorhangers:20,leads:2,hot:0}
  ]
};

function bootDemo(){
  if (!demoAuthed()) return renderDemoLogin();
  renderDemo();
}
function renderDemoLogin(msg=''){
  app.innerHTML = `<div class="login"><div class="card hero"><div class="brand">HAMRIQ</div><h1>Demo Login</h1><p class="muted">Protected demo mode. Fake data only.</p>${msg?`<div class="notice">${esc(msg)}</div>`:''}<div class="field section"><label>Username</label><input id="du" class="input" autocomplete="username"></div><div class="field section"><label>Password</label><input id="dp" class="input" type="password" autocomplete="current-password"></div><button class="btn accent big section" id="ds">Sign in</button><p class="muted mini section">Use the shared demo login. Real customer data is not stored here.</p></div></div>`;
  document.querySelector('#ds').onclick = () => {
    if (du.value.trim() === DEMO_USER && dp.value === DEMO_PASS) { localStorage.setItem('hamriq_demo_auth','ok'); bootDemo(); }
    else renderDemoLogin('Wrong username or password.');
  };
}
function roleTabs(){
  const base = ['Today','Customers','Hammy'];
  const map = {
    'Management':['Today','Customers','Pipeline','Marketing','Production','Billing','Reports','Hammy'],
    'Sales Rep':['Today','Customers','Pipeline','Inspection','Estimates','Hammy'],
    'Canvasser':['Today','Prospecting','Door Hangers','Customers','Hammy'],
    'Billing':['Today','Billing','Customers','Marketing Spend','Hammy'],
    'Production':['Today','Production','Customers','Materials','Hammy'],
    'Marketing':['Today','Marketing','Campaigns','Vendors','Online Leads','Hammy'],
    'Admin':['Today','Customers','Marketing','Production','Billing','Permissions','Reports','Hammy']
  };
  return map[demoRole] || base;
}
function renderDemo(){
  if (!roleTabs().includes(demoTab)) demoTab = 'Today';
  app.innerHTML = `<div class="shell demo-shell"><header class="top demo-top"><div><div class="brand">HAMRIQ <span>DEMO</span></div><div class="mini muted">Fake Michigan records · ${esc(demoRole)} view</div></div><div class="row"><select id="roleSwitch" class="input role-select">${demoRoles.map(r=>`<option ${r===demoRole?'selected':''}>${r}</option>`).join('')}</select><button class="btn secondary" id="demoOut">Lock</button></div></header><div class="demo-banner">Demo Mode — fake functional app. No messages, orders, payments, or external actions are sent.</div><div class="layout"><nav>${roleTabs().map(t=>`<button class="${demoTab===t?'active':''}" data-tab="${t}">${t}</button>`).join('')}</nav><main class="main" id="main"></main></div><div class="bottom-bar">${['Today','Customers','Marketing','Hammy'].map(t=>`<button class="${demoTab===t?'active':''}" data-tab="${t}">${t}</button>`).join('')}</div><button class="fab" id="hammyFab">Hammy</button></div>`;
  document.querySelector('#roleSwitch').onchange = e => setDemoRole(e.target.value);
  document.querySelector('#demoOut').onclick = () => { localStorage.removeItem('hamriq_demo_auth'); renderDemoLogin(); };
  document.querySelectorAll('[data-tab]').forEach(b => b.onclick = () => { demoTab = b.dataset.tab; renderDemo(); });
  document.querySelector('#hammyFab').onclick = () => demoHammy();
  renderDemoPage(document.querySelector('#main'));
}
function renderDemoPage(el){
  const page = demoTab;
  if (page === 'Today') return demoToday(el);
  if (page === 'Customers') return demoCustomers(el);
  if (['Pipeline','Inspection','Estimates'].includes(page)) return demoPipeline(el);
  if (['Prospecting','Door Hangers'].includes(page)) return demoProspecting(el);
  if (['Marketing','Campaigns','Online Leads'].includes(page)) return demoMarketing(el);
  if (page === 'Vendors') return demoVendors(el);
  if (page === 'Production' || page === 'Materials') return demoProduction(el);
  if (page === 'Billing' || page === 'Marketing Spend') return demoBilling(el);
  if (page === 'Reports') return demoReports(el);
  if (page === 'Permissions') return demoPermissions(el);
  if (page === 'Hammy') return demoHammyPage(el);
  demoToday(el);
}
function demoToday(el){
  const attention = demo.customers.filter(c => ['Hot lead','Carrier estimate received','Supplement drafted','Auto generated lead','Proposal sent'].includes(c.stage));
  const roleText = {
    'Management':'Company overview, approvals, stuck jobs, marketing, billing, and production snapshots.',
    'Sales Rep':'Your follow-ups, inspections, proposals, and customers that need action.',
    'Canvasser':'Today’s canvassing routes, door hangers, hot leads, and street results.',
    'Billing':'Invoices, balances, marketing spend, deductibles, mortgage checks, and payment exceptions.',
    'Production':'Signed jobs, schedule, crews, material status, permits, and customer updates.',
    'Marketing':'Campaign performance, QR scans, vendors, online leads, spend, and ROI.',
    'Admin':'Company-wide demo of roles, permissions, dashboards, and controls.'
  }[demoRole];
  el.innerHTML = `<div class="card hero"><div class="row between"><div><h1>${esc(demoRole)} Today</h1><p class="muted">${esc(roleText)}</p></div><button class="btn good" onclick="alert('Demo action only. No real activity is sent.')">Start My Day</button></div></div><div class="grid cards section"><div class="card"><div class="muted">Active customers</div><div class="metric">${demo.customers.length}</div></div><div class="card"><div class="muted">Needs attention</div><div class="metric">${attention.length}</div></div><div class="card"><div class="muted">Revenue shown</div><div class="metric">$${Math.round(demo.customers.reduce((s,c)=>s+c.value,0)/1000)}k</div></div><div class="card"><div class="muted">Michigan markets</div><div class="metric">${new Set(demo.customers.map(c=>c.city)).size}</div></div></div><div class="grid two section"><div class="card"><h2>Next actions</h2><div class="stack section">${attention.slice(0,6).map(c=>demoActionCard(c)).join('')}</div></div><div class="card"><h2>Role snapshot</h2>${roleSnapshot()}</div></div>`;
}
function demoActionCard(c){ return `<div class="quick-card"><div class="row between"><strong>${esc(c.name)}</strong>${pill(c.stage,c.color)}</div><p class="muted mini">${esc(c.address)}</p><p><b>${esc(c.next)}</b><br><span class="muted">${esc(c.status)}</span></p><div class="row"><button class="btn accent" onclick="alert('Demo: opened ${esc(c.name)}')">Open</button><button class="btn ghost" onclick="alert('Demo: status update saved locally only')">Update</button></div></div>`; }
function roleSnapshot(){
  if (demoRole === 'Marketing') return demo.campaigns.map(c=>`<div class="quick-card"><b>${esc(c.name)}</b><p class="muted">${esc(c.type)} · ${esc(c.area)}</p>${pill(c.health,c.health==='Healthy'?'green':'yellow')} ${pill(c.roi,c.roi==='Weak'?'red':'green')}</div>`).join('');
  if (demoRole === 'Billing') return demo.billing.map(b=>`<div class="quick-card"><b>${esc(b.customer)}</b><p class="muted">${esc(b.type)} · $${b.amount.toLocaleString()}</p>${pill(b.status,b.status.includes('Paid')?'green':'yellow')}</div>`).join('');
  if (demoRole === 'Production') return demo.production.map(p=>`<div class="quick-card"><b>${esc(p.job)}</b><p class="muted">${esc(p.city)} · ${esc(p.crew)}</p>${pill(p.status,p.status.includes('Completed')?'green':'blue')}</div>`).join('');
  if (demoRole === 'Canvasser') return demo.canvass.map(r=>`<div class="quick-card"><b>${esc(r.street)}</b><p class="muted">${r.knocks} knocks · ${r.doorhangers} hangers · ${r.leads} leads</p>${pill(`${r.hot} hot`,r.hot?'red':'gray')}</div>`).join('');
  return `<ul class="screen-steps"><li>Hot leads and overdue follow-ups are surfaced first.</li><li>Every customer has a clear next action.</li><li>Managers see marketing, billing, production, and approval snapshots.</li><li>Reps see only simplified field workflow.</li></ul>`;
}
function demoCustomers(el){
  el.innerHTML = `<div class="row between"><div><h1>Customers</h1><p class="muted">One-screen customer files across Michigan.</p></div><button class="btn accent" onclick="alert('Demo: create lead opens minimal fields only')">+ Demo Lead</button></div><div class="grid cards section">${demo.customers.map(c=>`<div class="card"><div class="row between"><h3>${esc(c.name)}</h3>${pill(c.priority,c.priority==='Hot'?'red':c.priority==='High'?'yellow':'gray')}</div><p class="muted">${esc(c.address)}</p><div class="stack section"><div><b>Stage:</b> ${esc(c.stage)}</div><div><b>Next:</b> ${esc(c.next)}</div><div><b>Rep:</b> ${esc(c.rep)}</div><div><b>Source:</b> ${esc(c.source)}</div><div><b>Claim:</b> ${esc(c.carrier)} · ${esc(c.claim)}</div></div><button class="btn accent section" onclick="alert('Demo customer file: ${esc(c.status)}')">Open file</button></div>`).join('')}</div>`;
}
function demoPipeline(el){
  el.innerHTML = `<h1>${esc(demoTab)}</h1><p class="muted">Stage-based workflow with next actions and fewer fields.</p>${table(['Customer','City','Stage','Next action','Value'], demo.customers.map(c=>[c.name,c.city,pill(c.stage,c.color),c.next,c.value?`$${c.value.toLocaleString()}`:'—']))}`;
}
function demoProspecting(el){
  el.innerHTML = `<div class="row between"><div><h1>${esc(demoTab)}</h1><p class="muted">Canvasser view with door hanger tracking and simple outcomes.</p></div><button class="btn accent" onclick="alert('Demo: visit logged')">Log Visit</button></div>${table(['Street','Knocks','Contacts','Door hangers','Leads','Hot'], demo.canvass.map(r=>[r.street,r.knocks,r.contacts,r.doorhangers,r.leads,r.hot]))}`;
}
function demoMarketing(el){
  el.innerHTML = `<div class="row between"><div><h1>Marketing View</h1><p class="muted">Campaigns, QR scans, online leads, cost, ROI, vendors, and AI review.</p></div><button class="btn accent" onclick="alert('Demo: AI Marketing Review generated')">Marketing Review</button></div><div class="grid cards section">${demo.campaigns.map(c=>`<div class="card"><div class="row between"><h3>${esc(c.name)}</h3>${pill(c.health,c.health==='Healthy'?'green':'yellow')}</div><p class="muted">${esc(c.type)} · ${esc(c.area)}</p><div class="grid cards section"><div><b>${c.leads}</b><br><span class="muted mini">leads</span></div><div><b>${c.inspections}</b><br><span class="muted mini">inspections</span></div><div><b>${c.sold}</b><br><span class="muted mini">sold</span></div><div><b>$${Math.round(c.revenue/1000)}k</b><br><span class="muted mini">revenue</span></div></div><p><b>Cost:</b> $${c.cost.toLocaleString()} · <b>ROI:</b> ${esc(c.roi)}</p></div>`).join('')}</div>`;
}
function demoVendors(el){ el.innerHTML = `<h1>Marketing Vendors</h1><p class="muted">Vendor profiles, issue logs, score, spend, and approval status.</p>${table(['Vendor','Type','Score','Status','Issues','Spend','ROI'], demo.vendors.map(v=>[v.name,v.type,pill(v.score,v.score>85?'green':v.score>75?'yellow':'red'),pill(v.status,v.status==='Preferred'?'green':v.status==='Watch list'?'yellow':'blue'),v.issues,`$${v.spend.toLocaleString()}`,v.roi]))}`; }
function demoProduction(el){ el.innerHTML = `<h1>Production</h1><p class="muted">Production gets signed jobs, crew/material/permit status, and customer updates.</p>${table(['Job','City','Status','Crew','Materials','Permit'], demo.production.map(p=>[p.job,p.city,pill(p.status,p.status.includes('Completed')?'green':'blue'),p.crew,p.materials,p.permit]))}`; }
function demoBilling(el){ el.innerHTML = `<h1>Billing</h1><p class="muted">Billing sees payment-related items without needing full production or marketing control.</p>${table(['Customer/Vendor','Type','Amount','Status'], demo.billing.map(b=>[b.customer,b.type,`$${b.amount.toLocaleString()}`,pill(b.status,b.status==='Paid'?'green':'yellow')]))}`; }
function demoReports(el){ el.innerHTML = `<h1>Reports</h1><div class="grid cards section"><div class="card"><h3>Sales</h3><p>$${demo.customers.reduce((s,c)=>s+c.value,0).toLocaleString()} pipeline shown.</p></div><div class="card"><h3>Marketing</h3><p>${demo.campaigns.reduce((s,c)=>s+c.leads,0)} demo leads across campaigns.</p></div><div class="card"><h3>Production</h3><p>${demo.production.length} jobs in production stages.</p></div><div class="card"><h3>Billing</h3><p>${demo.billing.length} payment/spend records.</p></div></div>`; }
function demoPermissions(el){ el.innerHTML = `<h1>Permissions</h1><div class="card section"><p>Admin controls what each role can access. Marketing does not automatically access billing, production, contracts, commissions, or full admin controls.</p><ul class="screen-steps"><li>Management: broad company view.</li><li>Sales Rep: assigned customers and field workflow.</li><li>Canvasser: prospecting only.</li><li>Billing: money and invoice workflows.</li><li>Production: production workflow.</li><li>Marketing: marketing view only unless admin grants more.</li></ul></div>`; }
function demoHammyPage(el){ el.innerHTML = `<h1>Hammy</h1><div class="card section"><button class="btn accent big" onclick="alert('Demo voice captured. No real voice processing sent.')">Hold to speak</button><button class="btn secondary big section" onclick="demoHammy()">What am I looking at?</button><button class="btn secondary big section" onclick="alert('Next: work the first card on Today, then make sure the file has a next step.')">What should I do next?</button></div>`; }
function demoHammy(){ modal('Hammy Help', `<p>You are viewing the <b>${esc(demoRole)}</b> demo version of HAMRIQ on the <b>${esc(demoTab)}</b> screen.</p><p>This screen is designed to show the user what needs attention first, with fewer choices and larger buttons.</p><div class="notice section"><b>Need more help?</b><ol class="screen-steps"><li>Start on Today.</li><li>Open the first action card.</li><li>Use the big main button.</li><li>Add a note if something changed.</li><li>Make sure every active customer has a next step.</li></ol></div>`); }
function table(headers, rows){ return `<div class="card section"><table class="table"><thead><tr>${headers.map(h=>`<th>${h}</th>`).join('')}</tr></thead><tbody>${rows.map(r=>`<tr>${r.map(c=>`<td>${String(c).startsWith('<span')?c:esc(c)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`; }
function pill(v,color='gray'){ return `<span class="pill ${esc(color)}">${esc(v)}</span>`; }
function modal(title, body){ const w=document.createElement('div'); w.className='modal'; w.innerHTML=`<div><div class="row between"><h2>${esc(title)}</h2><button class="btn secondary" id="x">Close</button></div>${body}</div>`; document.body.append(w); w.querySelector('#x').onclick=()=>w.remove(); }

/* ========================= LIVE / DEV MODE ========================= */
async function bootLive(){
  const db = createClient(config.supabaseUrl, config.supabasePublishableKey);
  let profile, company, tab = 'Today';
  let data = { jobs: [], contacts: [], routes: [], visits: [], orders: [], reviews: [], production: [] };
  const sources = ['Unknown','Referral','Door knocking','Door hanger','Storm lead','Internet','Past customer','Insurance','Other'];
  const leadStages = ['First contact','Inspection complete','Contingency signed','Claim filed','Claim approved','Supplement submitted','Build contract signed','Completed','DEAD'];
  const allTabs = ['Today','Customers','Jobs','Prospecting','Marketing','Hammy','Routes','Measurements','Pricing','Reviews','Production'];
  const repTabs = ['Today','Customers','Jobs','Prospecting','Hammy'];
  const role = () => (profile?.role || '').toLowerCase();
  const isMgr = () => ['owner','admin','manager'].some(r => role().includes(r));
  const tabs = () => isMgr() ? allTabs : repTabs;
  const stageOf = j => j?.lead_progress_stage || j?.stage || 'First contact';
  const jobTitle = j => data.contacts.find(c=>c.id===j.contact_id)?.name || j.title || 'Customer';
  const contactFor = j => data.contacts.find(c=>c.id===j.contact_id) || {};
  const nextAction = j => {
    const s = stageOf(j);
    if (s === 'First contact') return ['Call homeowner','Confirm interest and schedule inspection.'];
    if (s === 'Inspection complete') return ['Send proposal','Photos are done. Move the file toward estimate/proposal.'];
    if (s === 'Claim filed') return ['Check insurance status','Ask whether they heard from carrier.'];
    if (s === 'Claim approved') return ['Review carrier estimate','Look for missing or underpaid items.'];
    if (s === 'Supplement submitted') return ['Follow up on supplement','Check adjuster response and next meeting.'];
    if (s === 'Build contract signed') return ['Production handoff','Confirm selections and schedule.'];
    if (s === 'Completed') return ['Ask for review','Close out and request review if rating is strong.'];
    if (s === 'DEAD') return ['No action','Lost/dead file.'];
    return ['Update status','Keep the file moving.'];
  };
  async function init(){
    const { data: { session } } = await db.auth.getSession();
    if (!session) return login();
    const ctx = await db.rpc('workspace_context');
    if (ctx.error || !ctx.data) return login('Your user is not provisioned in HAMRIQ yet.');
    profile = ctx.data.user; company = ctx.data.company;
    await load(); render();
  }
  async function safe(k,q){ const r=await q; data[k]=r.error?[]:(r.data||[]); }
  async function load(){
    await Promise.all([
      safe('jobs', db.from('jobs').select('id,title,address,stage,assigned_to,contact_id,status_note,created_at,lead_progress_stage,lead_progress_dead_reason,lead_progress_updated_at')),
      safe('contacts', db.from('contacts').select('id,name,phone,email,address,lead_source,assigned_to')),
      safe('routes', db.from('routes').select('*')),
      safe('visits', db.from('prospecting_visits').select('*')),
      safe('orders', db.from('measurement_orders').select('*')),
      safe('reviews', db.from('reviews').select('*')),
      safe('production', db.from('production_plans').select('*'))
    ]);
  }
  function login(msg=''){
    app.innerHTML = `<div class="login"><div class="card"><div class="brand">HAMRIQ</div><p class="muted">Development app. Login required.</p>${msg?`<div class="notice">${esc(msg)}</div>`:''}<div class="field section"><label>Email</label><input id="email" class="input" type="email"></div><div class="field section"><label>Password</label><input id="pw" class="input" type="password"></div><button class="btn accent big section" id="sign">Sign in</button><p id="err" class="muted"></p></div></div>`;
    document.querySelector('#sign').onclick = async () => { const res = await db.auth.signInWithPassword({ email: email.value, password: pw.value }); if (res.error) err.textContent = res.error.message; else init(); };
  }
  function render(){
    app.innerHTML = `<div class="shell"><header class="top"><div class="brand">HAMRIQ <span>${esc(company.name || '')}</span></div><div class="row"><span>${esc(profile.display_name)} · ${esc(profile.role)}</span><button class="btn secondary" id="out">Sign out</button></div></header><div class="layout"><nav>${tabs().map(t=>`<button class="${tab===t?'active':''}" data-tab="${t}">${t}</button>`).join('')}</nav><main class="main" id="main"></main></div><div class="bottom-bar">${['Today','Customers','Prospecting','Hammy'].map(t=>`<button class="${tab===t?'active':''}" data-tab="${t}">${t}</button>`).join('')}</div><button class="fab" id="hammyFab">Hammy</button></div>`;
    document.querySelectorAll('[data-tab]').forEach(b=>b.onclick=()=>{tab=b.dataset.tab;render();});
    document.querySelector('#out').onclick=()=>db.auth.signOut().then(init);
    document.querySelector('#hammyFab').onclick=()=>hammy();
    page(document.querySelector('#main'));
  }
  function page(el){
    if(tab==='Today'){ const jobs=data.jobs.filter(j=>stageOf(j)!=='Completed'&&stageOf(j)!=='DEAD'); el.innerHTML=`<div class="card hero"><h1>Today</h1><p class="muted">Start here. HAMRIQ shows the work that needs action now.</p></div><div class="grid cards section"><div class="card"><div class="muted">Active</div><div class="metric">${jobs.length}</div></div><div class="card"><div class="muted">Follow-ups</div><div class="metric">${jobs.slice(0,5).length}</div></div><div class="card"><div class="muted">Customers</div><div class="metric">${data.contacts.length}</div></div></div><div class="card section"><h2>Next actions</h2><div class="stack section">${jobs.slice(0,8).map(jobCard).join('')||'<div class="empty">No urgent work. Create a lead or check customers.</div>'}</div></div>`; bind(); return; }
    if(tab==='Customers'||tab==='Jobs'){ el.innerHTML=`<div class="row between"><div><h1>${tab}</h1><p class="muted">Simple customer cards with one next action.</p></div><button class="btn accent" id="newLead">+ New Lead</button></div><div class="grid cards section">${data.jobs.map(customerCard).join('')||'<div class="empty">No customers yet.</div>'}</div>`; document.querySelector('#newLead').onclick=leadModal; bind(); return; }
    if(tab==='Prospecting'){ el.innerHTML=`<h1>Prospecting</h1><p class="muted">Door hanger and visit tracking.</p><button class="btn accent" onclick="alert('Visit modal coming next')">Log Visit</button>${table(['Address','Outcome','Door hanger'],data.visits.map(v=>[v.address,v.outcome,v.door_hanger_placed?'Placed':'—']))}`; return; }
    if(tab==='Marketing'){ el.innerHTML=`<h1>Marketing View</h1><div class="card section"><p>Marketing dashboard foundation: campaigns, QR scans, source ROI, vendors, online leads, and AI review.</p></div>`; return; }
    if(tab==='Production'){ el.innerHTML=`<h1>Production</h1>${table(['Job','Progress','Address'], data.jobs.filter(j=>['Build contract signed','Completed'].includes(stageOf(j))).map(j=>[jobTitle(j),pill(stageOf(j)),j.address]))}`; return; }
    if(tab==='Hammy'){ el.innerHTML=`<h1>Hammy</h1><div class="card section"><button class="btn accent big">Hold to speak</button><button class="btn secondary big section" onclick="alert('This screen explains what you are looking at and the next action.')">What am I looking at?</button></div>`; return; }
    el.innerHTML=`<h1>${esc(tab)}</h1><div class="card section"><p>This view is connected to the approved backend foundation.</p></div>`;
  }
  function jobCard(j){ const a=nextAction(j); return `<div class="quick-card"><div class="row between"><strong>${esc(jobTitle(j))}</strong>${pill(stageOf(j))}</div><p class="muted mini">${esc(j.address||'')}</p><p><b>${esc(a[0])}</b><br><span class="muted">${esc(a[1])}</span></p><button class="btn accent" data-progress="${j.id}">Update Status</button></div>`; }
  function customerCard(j){ const c=contactFor(j), a=nextAction(j); return `<div class="card"><div class="row between"><h3>${esc(jobTitle(j))}</h3>${pill(stageOf(j))}</div><p class="muted">${esc(j.address||c.address||'')}</p><p><b>Next:</b> ${esc(a[0])}</p><p><b>Contact:</b> ${esc(c.phone||'No phone')}</p><button class="btn accent" data-progress="${j.id}">Update Status</button></div>`; }
  function bind(){ document.querySelectorAll('[data-progress]').forEach(b=>b.onclick=()=>progressModal(data.jobs.find(j=>j.id===b.dataset.progress))); }
  function progressModal(job){ modal('Update Status', `<p><b>${esc(jobTitle(job))}</b></p><div class="field"><label>Status</label><select id="stage" class="input">${leadStages.map(s=>`<option ${s===stageOf(job)?'selected':''}>${s}</option>`).join('')}</select></div><div class="field section"><label>Note</label><textarea id="comment" class="input"></textarea></div><button class="btn accent big section" id="save">Save</button>`); document.querySelector('#save').onclick=async()=>{ const r=await db.rpc('progress_lead_stage',{p_job_id:job.id,p_stage:stage.value,p_comment:comment.value}); if(r.error) return alert(r.error.message); await load(); document.querySelector('.modal').remove(); render(); }; }
  function leadModal(){ modal('Create Lead', `<div class="form"><div class="field"><label>Name</label><input id="n" class="input"></div><div class="field"><label>Phone</label><input id="p" class="input"></div><div class="field"><label>Address</label><input id="a" class="input"></div><div class="field"><label>Lead source</label><select id="s" class="input">${sources.map(x=>`<option>${x}</option>`).join('')}</select></div></div><button class="btn accent big section" id="save">Create Lead</button>`); document.querySelector('#save').onclick=async()=>{ const c=await db.from('contacts').insert({company_id:company.id,name:n.value,phone:p.value,address:a.value,lead_source:s.value,assigned_to:profile.id,created_by:profile.id}).select('id').single(); if(c.error)return alert(c.error.message); const j=await db.from('jobs').insert({company_id:company.id,contact_id:c.data.id,title:n.value+' Roof',address:a.value,assigned_to:profile.id,created_by:profile.id}); if(j.error)return alert(j.error.message); await load(); document.querySelector('.modal').remove(); render(); }; }
  function hammy(){ modal('Hammy', `<p>You are on the ${esc(tab)} screen. Use the biggest action button first. If a customer is active, make sure there is always a next step.</p>`); }
  function table(headers, rows){ return `<div class="card section"><table class="table"><thead><tr>${headers.map(h=>`<th>${h}</th>`).join('')}</tr></thead><tbody>${rows.map(r=>`<tr>${r.map(c=>`<td>${String(c).startsWith('<span')?c:esc(c)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`; }
  function pill(v,color='gray'){ return `<span class="pill ${esc(color)}">${esc(v)}</span>`; }
  function modal(title, body){ const w=document.createElement('div'); w.className='modal'; w.innerHTML=`<div><div class="row between"><h2>${esc(title)}</h2><button class="btn secondary" id="x">Close</button></div>${body}</div>`; document.body.append(w); w.querySelector('#x').onclick=()=>w.remove(); }
  init();
}