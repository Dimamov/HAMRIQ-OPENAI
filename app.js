const app = document.querySelector('#app');
const host = location.hostname.toLowerCase();
const params = new URLSearchParams(location.search);
const esc = v => String(v ?? '').replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
const today = new Date().toLocaleDateString('en-US', { month:'short', day:'numeric' });

window.addEventListener('error', e => {
  if (!app?.innerHTML) app.innerHTML = `<div class="login"><div class="card"><div class="brand">HAMRIQ</div><p class="notice">App load error: ${esc(e.message)}</p></div></div>`;
});

const DEMO_USER = 'demo';
const DEMO_PASS = 'HamriqDemo2026!';
const demoRoles = ['Management','Sales Rep','Canvasser','Billing','Production','Marketing','Admin'];
let demoRole = localStorage.getItem('hamriq_demo_role') || 'Management';
let demoTab = 'Today';

const demo = {
  customers: [
    {name:'Bob Smith', city:'Grand Blanc', address:'4128 Maple Ridge Dr, Grand Blanc, MI', phone:'810-555-0184', stage:'Hot lead', source:'Door hanger', priority:'Hot', rep:'Mia Carter', carrier:'State Farm', claim:'SF-62491', value:18800, next:'Call homeowner', status:'New storm lead. Door hanger scan came in this morning.', color:'red'},
    {name:'Maria Gonzalez', city:'Clarkston', address:'7651 Sashabaw Rd, Clarkston, MI', phone:'248-555-0199', stage:'Inspection scheduled', source:'Referral', priority:'High', rep:'Noah Reed', carrier:'Allstate', claim:'AS-88401', value:24200, next:'Arrive for inspection', status:'Prefers text. Appointment today at 3:30 PM.', color:'blue'},
    {name:'James Walker', city:'Davison', address:'317 Oak Hill Ct, Davison, MI', phone:'810-555-0112', stage:'Inspection complete', source:'Storm campaign', priority:'Normal', rep:'Mia Carter', carrier:'Farmers', claim:'FM-11920', value:21750, next:'Send proposal', status:'Photos complete. Gutters and soft metals documented.', color:'yellow'},
    {name:'Linda Patel', city:'Troy', address:'2440 Somerset Blvd, Troy, MI', phone:'248-555-0144', stage:'Proposal sent', source:'Internet', priority:'Normal', rep:'Ava Stone', carrier:'Liberty Mutual', claim:'LM-55218', value:26300, next:'Follow up', status:'Proposal opened twice. Needs spouse approval.', color:'yellow'},
    {name:'Eric Johnson', city:'Lansing', address:'981 Waverly Rd, Lansing, MI', phone:'517-555-0182', stage:'Carrier estimate received', source:'Past customer', priority:'High', rep:'Noah Reed', carrier:'USAA', claim:'US-99210', value:31900, next:'Review supplement', status:'Carrier estimate appears short on ridge cap and valley metal.', color:'red'},
    {name:'Angela Brooks', city:'Ann Arbor', address:'1287 Stadium View, Ann Arbor, MI', phone:'734-555-0128', stage:'Contract signed', source:'Referral', priority:'Normal', rep:'Ava Stone', carrier:'Progressive', claim:'PR-39019', value:34750, next:'Production handoff', status:'Selections complete. Waiting on material delivery date.', color:'green'},
    {name:'The Miller Family', city:'Traverse City', address:'55 Peninsula Dr, Traverse City, MI', phone:'231-555-0150', stage:'In production', source:'Storm lead', priority:'Normal', rep:'Mia Carter', carrier:'Auto-Owners', claim:'AO-77310', value:40200, next:'Confirm install photos', status:'Crew scheduled. Permit approved.', color:'blue'},
    {name:'Nancy Wilson', city:'Royal Oak', address:'602 Lincoln Ave, Royal Oak, MI', phone:'248-555-0170', stage:'Completed', source:'Referral', priority:'Low', rep:'Noah Reed', carrier:'State Farm', claim:'SF-10298', value:19600, next:'Request internal rating', status:'Final photos complete. Balance collected.', color:'green'}
  ],
  canvass: [ ['Fenton storm route','18 doors','5 warm','2 hot','3 door hangers'], ['Grand Blanc west','24 doors','8 warm','1 urgent','9 door hangers'], ['Davison north','15 doors','3 warm','0 urgent','6 door hangers'] ],
  marketing: [ ['Grand Blanc Hail QR','$1,250','38 leads','9 inspections','Healthy'], ['Clarkston Facebook Ads','$680','22 leads','4 inspections','Needs review'], ['Davison Door Hangers','$420','17 leads','5 inspections','Strong'] ],
  billing: [ ['Angela Brooks','$34,750','$17,375','Deposit paid'], ['The Miller Family','$40,200','$20,100','Progress payment due'], ['Nancy Wilson','$19,600','$0','Paid in full'] ],
  production: [ ['Angela Brooks','Ready to schedule','Selections complete','Green'], ['The Miller Family','Crew scheduled','Permit approved','Blue'], ['Eric Johnson','Hold','Supplement review needed','Red'] ]
};

function route(){
  if (host === 'hamriq.com' || host === 'www.hamriq.com') return renderLanding();
  if (host === 'hamriq.app' || host === 'www.hamriq.app' || host.endsWith('.pages.dev') || params.get('demo') === '1') return bootDemo();
  if (host === 'dev.hamriq.app') return bootDev();
  return renderLanding();
}

function renderLanding(){
  app.innerHTML = `<div class="landing"><div class="brand big">HAMRIQ</div><p class="eyebrow">ROOFING. SIMPLIFIED.</p><h1>Roofing workflow,<br>all in one place.</h1><p class="lead">A mobile-first roofing CRM for sales reps, managers, production, billing, canvassing, and marketing.</p><div class="row section"><a class="btn accent" href="https://hamriq.app">Open demo</a><a class="btn secondary" href="https://dev.hamriq.app">Development login</a></div><div class="grid cards section"><div class="card"><h3>Rep simple</h3><p class="muted">Today screen, next action, fast updates, and Hammy help.</p></div><div class="card"><h3>Manager complete</h3><p class="muted">Pipeline, approvals, production, billing, marketing, and reporting.</p></div><div class="card"><h3>AI ready</h3><p class="muted">Designed for photo analysis, summaries, cleanup, and workflow assistance.</p></div></div></div>`;
}

function demoAuthed(){ return localStorage.getItem('hamriq_demo_auth') === 'ok'; }
async function bootDemo(){ if (!demoAuthed()) return renderDemoLogin(); try { const {startDemo}=await import("./src/workspace/workspace.mjs?v=20261002-mobile-home-v5"); await startDemo(demo.customers); } catch(e) { app.innerHTML=`<div class="login"><div class="card"><h1>Workspace could not load</h1><p>${esc(e.message)}</p></div></div>`; } }
function renderDemoLogin(msg=''){
  const savedUser = localStorage.getItem('hamriq_demo_saved_user') || DEMO_USER;
  app.innerHTML = `<div class="login"><div class="card"><div class="brand">HAMRIQ</div><p class="muted">Demo Mode · fake Michigan data only</p>${msg?`<div class="notice section">${esc(msg)}</div>`:''}<div class="field section"><label>Username</label><input id="du" class="input" value="${esc(savedUser)}" autocomplete="username"></div><div class="field section"><label>Password</label><input id="dp" class="input" type="password" autocomplete="current-password"></div><label class="row section mini"><input id="remember" type="checkbox" checked> Save login on this device</label><button class="btn accent big section" id="loginBtn">Enter Demo</button><p class="muted mini section">No real customer data is stored in this demo.</p></div></div>`;
  document.querySelector('#loginBtn').onclick = () => {
    if (du.value.trim() === DEMO_USER && dp.value === DEMO_PASS) {
      localStorage.setItem('hamriq_demo_auth','ok');
      if (remember.checked) localStorage.setItem('hamriq_demo_saved_user', du.value.trim());
      bootDemo();
    } else renderDemoLogin('Wrong demo login. Use username demo and the demo password.');
  };
}

function tabsForRole(role){
  if (role === 'Sales Rep') return ['Today','Customers','Inspections','Proposals','Commissions','Hammy'];
  if (role === 'Canvasser') return ['Today','Canvassing','Hot Leads','Door Hangers','Hammy'];
  if (role === 'Billing') return ['Today','Billing','Payments','Invoices','Hammy'];
  if (role === 'Production') return ['Today','Production','Schedule','Materials','Permits','Hammy'];
  if (role === 'Marketing') return ['Today','Marketing','Campaigns','Online Leads','Vendors','Hammy'];
  if (role === 'Admin') return ['Today','Users','Permissions','Settings','Audit','Hammy'];
  return ['Today','Customers','Pipeline','Marketing','Billing','Production','Reports','Hammy'];
}
function renderDemo(){
  const tabs = tabsForRole(demoRole); if (!tabs.includes(demoTab)) demoTab = 'Today';
  app.innerHTML = `<div class="shell"><header class="top"><div><div class="brand">HAMRIQ <span>DEMO</span></div><div class="mini muted">Fake data · ${today}</div></div><div class="row"><select id="roleSwitch" class="input" style="width:auto">${demoRoles.map(r=>`<option ${r===demoRole?'selected':''}>${r}</option>`).join('')}</select><button class="btn secondary" id="logout">Log out</button></div></header><div class="layout"><nav>${tabs.map(t=>`<button class="${demoTab===t?'active':''}" data-tab="${t}">${t}</button>`).join('')}</nav><main class="main"><div class="notice"><b>Demo Mode:</b> You are viewing ${esc(demoRole)}. Actions are simulated and will not send messages, create orders, or change real data.</div><div id="demoPage" class="section"></div></main></div><div class="bottom-bar">${['Today','Customers','Hammy','More'].map(t=>`<button class="${demoTab===t?'active':''}" data-tab="${t}">${t}</button>`).join('')}</div><button class="fab" id="hammyFab">Hammy</button></div>`;
  document.querySelector('#roleSwitch').onchange = e => { demoRole = e.target.value; localStorage.setItem('hamriq_demo_role', demoRole); demoTab = 'Today'; renderDemo(); };
  document.querySelector('#logout').onclick = () => { localStorage.removeItem('hamriq_demo_auth'); renderDemoLogin(); };
  document.querySelectorAll('[data-tab]').forEach(b => b.onclick = () => { demoTab = b.dataset.tab === 'More' ? tabs[1] : b.dataset.tab; renderDemo(); });
  document.querySelector('#hammyFab').onclick = () => modal('Hammy', '<p>What should I do next?</p><ol class="screen-steps"><li>Start on Today.</li><li>Open the first red or yellow card.</li><li>Use the main action button.</li><li>Make sure every active customer has a next step.</li></ol>');
  renderDemoPage(document.querySelector('#demoPage'));
}
function renderDemoPage(el){
  const title = `<div class="row between"><div><h1>${esc(demoTab)}</h1><p class="muted">${esc(demoRole)} view</p></div><button class="btn accent" onclick="alert('Demo action only')">Main Action</button></div>`;
  if (demoTab === 'Today') return el.innerHTML = title + todayView();
  if (['Customers','Pipeline','Hot Leads','Inspections','Proposals'].includes(demoTab)) return el.innerHTML = title + customerGrid();
  if (['Canvassing','Door Hangers'].includes(demoTab)) return el.innerHTML = title + simpleTable(['Route','Doors','Warm','Hot/Urgent','Door hangers'], demo.canvass);
  if (['Marketing','Campaigns','Online Leads','Vendors'].includes(demoTab)) return el.innerHTML = title + simpleTable(['Campaign','Spend','Leads','Inspections','Health'], demo.marketing);
  if (['Billing','Payments','Invoices'].includes(demoTab)) return el.innerHTML = title + simpleTable(['Customer','Contract','Balance','Status'], demo.billing);
  if (['Production','Schedule','Materials','Permits'].includes(demoTab)) return el.innerHTML = title + simpleTable(['Job','Stage','Note','Status'], demo.production);
  if (['Users','Permissions','Settings','Audit','Reports','Commissions'].includes(demoTab)) return el.innerHTML = title + `<div class="grid cards section"><div class="card"><div class="muted">Active users</div><div class="metric">12</div></div><div class="card"><div class="muted">Open approvals</div><div class="metric">7</div></div><div class="card"><div class="muted">Stuck jobs</div><div class="metric">3</div></div></div>`;
  if (demoTab === 'Hammy') return el.innerHTML = title + `<div class="card section"><button class="btn accent big">Hold to speak</button><button class="btn secondary big section">What am I looking at?</button><button class="btn secondary big section">What should I do next?</button><p class="muted section">Hammy explains the screen and suggests the next step.</p></div>`;
  el.innerHTML = title + '<div class="empty">Demo screen ready.</div>';
}
function todayView(){
  const red = demo.customers.filter(c=>c.color==='red').length, yellow = demo.customers.filter(c=>c.color==='yellow').length;
  return `<div class="grid cards section"><div class="card hero"><div class="muted">Needs attention</div><div class="metric">${red + yellow}</div></div><div class="card"><div class="muted">Active customers</div><div class="metric">${demo.customers.length}</div></div><div class="card"><div class="muted">Hot leads</div><div class="metric">2</div></div><div class="card"><div class="muted">Signed jobs</div><div class="metric">2</div></div></div><div class="grid two section"><div>${demo.customers.slice(0,4).map(actionCard).join('')}</div><div class="card"><h3>Start My Day</h3><ol class="screen-steps"><li>Call hot leads first.</li><li>Finish scheduled inspections.</li><li>Send proposals with complete photos.</li><li>Wrap up with no customer missing a next step.</li></ol></div></div>`;
}
function customerGrid(){ return `<div class="grid cards section">${demo.customers.map(customerCard).join('')}</div>`; }
function actionCard(c){ return `<div class="quick-card section"><div class="row between"><strong>${esc(c.name)}</strong>${pill(c.priority,c.color)}</div><p class="muted mini">${esc(c.city)} · ${esc(c.stage)}</p><p><b>${esc(c.next)}</b><br><span class="muted">${esc(c.status)}</span></p><button class="btn accent" onclick="alert('Demo action only')">${esc(c.next)}</button></div>`; }
function customerCard(c){ return `<div class="card"><div class="row between"><h3>${esc(c.name)}</h3>${pill(c.stage,c.color)}</div><p class="muted">${esc(c.address)}</p><p><b>Phone:</b> ${esc(c.phone)}<br><b>Carrier:</b> ${esc(c.carrier)} · ${esc(c.claim)}<br><b>Rep:</b> ${esc(c.rep)}<br><b>Value:</b> $${c.value.toLocaleString()}</p><div class="notice"><b>Next:</b> ${esc(c.next)}<br>${esc(c.status)}</div></div>`; }
function simpleTable(headers, rows){ return `<div class="card section"><table class="table"><thead><tr>${headers.map(h=>`<th>${esc(h)}</th>`).join('')}</tr></thead><tbody>${rows.map(r=>`<tr>${r.map(x=>`<td>${esc(x)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`; }
function pill(text,color='gray'){ return `<span class="pill ${color}">${esc(text)}</span>`; }
function modal(title, body){ const w=document.createElement('div'); w.className='modal'; w.innerHTML=`<div><div class="row between"><h2>${esc(title)}</h2><button class="btn secondary" id="x">Close</button></div>${body}</div>`; document.body.append(w); w.querySelector('#x').onclick=()=>w.remove(); }

async function bootDev(){
  try {
    const config = await fetch('./src/lib/config.json').then(r => r.json()).catch(() => ({}));
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2.117.2');
    const db = createClient(config.supabaseUrl, config.supabasePublishableKey);
    const {startLive,startPortal}=await import('./src/workspace/workspace.mjs?v=20261002-mobile-home-v5');
    if (params.get('portal')) return startPortal(db,params.get('portal'));
    const { data: { session } } = await db.auth.getSession();
    if (!session) return liveLogin(db);
    await startLive(db);
  } catch (e) { app.innerHTML = `<div class="login"><div class="card"><div class="brand">HAMRIQ</div><p class="notice">Development login could not load. ${esc(e.message)}</p></div></div>`; }
}
function liveLogin(db){
  app.innerHTML = `<div class="login"><div class="card"><div class="brand">HAMRIQ</div><p class="muted">Development login</p><div class="field section"><label>Email</label><input id="email" class="input" type="email"></div><div class="field section"><label>Password</label><input id="pw" class="input" type="password"></div><button class="btn accent big section" id="sign">Sign in</button><p id="err" class="muted section"></p></div></div>`;
  document.querySelector('#sign').onclick = async () => { const res = await db.auth.signInWithPassword({ email: email.value, password: pw.value }); if(res.error) err.textContent=res.error.message; else bootDev(); };
}

route();
