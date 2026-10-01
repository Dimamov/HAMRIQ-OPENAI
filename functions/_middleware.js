const landingHtml = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <meta name="theme-color" content="#07111f" />
  <title>HAMRIQ</title>
  <style>
    :root{--ink:#0b1220;--muted:#64748b;--blue:#2563eb;--soft:#eef3f8;--line:#dbe3ee;--card:#ffffff;--shadow:0 24px 70px rgba(15,23,42,.14)}
    *{box-sizing:border-box}
    html,body{margin:0;min-height:100%;font-family:Inter,system-ui,-apple-system,Segoe UI,sans-serif;background:radial-gradient(circle at 82% 10%,#dbeafe 0,#eef3f8 34%,#eef3f8 100%);color:var(--ink)}
    body{overflow-x:hidden}
    .page{min-height:100vh;padding:22px max(18px,env(safe-area-inset-left)) 48px;position:relative}
    .wrap{max-width:1160px;margin:0 auto}
    .nav{display:flex;align-items:center;justify-content:space-between;gap:18px;margin-bottom:34px}
    .logo{font-weight:1000;letter-spacing:.075em;font-size:34px;line-height:1}.tag{font-size:12px;font-weight:900;letter-spacing:.16em;color:var(--muted);margin-top:8px}.navlinks{display:none}
    .hero{display:grid;grid-template-columns:minmax(0,1.04fr) minmax(330px,.78fr);gap:34px;align-items:center}
    .eyebrow{display:inline-flex;align-items:center;gap:8px;font-weight:1000;letter-spacing:.13em;font-size:13px;background:white;border:1px solid var(--line);border-radius:999px;padding:9px 12px;color:#1d4ed8;box-shadow:0 8px 24px rgba(15,23,42,.08)}
    h1{font-size:clamp(48px,7.2vw,86px);line-height:.9;letter-spacing:-.075em;margin:20px 0 18px;max-width:850px}.lead{font-size:clamp(20px,2.5vw,30px);font-weight:780;line-height:1.2;max-width:780px;margin:0;color:#111827}.sublead{font-size:17px;line-height:1.55;color:var(--muted);font-weight:650;max-width:690px;margin:18px 0 0}
    .proof{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-top:30px;max-width:780px}.proof div{background:rgba(255,255,255,.78);border:1px solid var(--line);border-radius:18px;padding:14px}.proof b{display:block;font-size:24px}.proof span{display:block;color:var(--muted);font-weight:800;font-size:13px;margin-top:4px}
    .phone{position:relative;justify-self:center;width:min(360px,100%);aspect-ratio:9/18.3;border-radius:42px;background:#07111f;padding:13px;box-shadow:var(--shadow);border:1px solid rgba(15,23,42,.28)}.phone:before{content:"";position:absolute;top:11px;left:50%;transform:translateX(-50%);width:34%;height:25px;border-radius:0 0 16px 16px;background:#07111f;z-index:2}.screen{height:100%;border-radius:32px;background:linear-gradient(180deg,#f8fafc,#eef3f8);overflow:hidden;padding:24px 16px 16px}.miniLogo{font-weight:1000;letter-spacing:.06em;font-size:20px;margin-bottom:16px}.today{background:#07111f;color:white;border-radius:24px;padding:18px;margin-bottom:14px}.today small{color:#bfdbfe;font-weight:800}.today strong{display:block;font-size:30px;line-height:1;margin-top:8px}.task{background:white;border:1px solid var(--line);border-radius:20px;padding:14px;margin-top:12px}.task b{display:block}.task p{margin:6px 0 0;color:var(--muted);font-weight:700;font-size:13px}.bluebar{height:9px;border-radius:99px;background:#dbeafe;margin-top:12px;overflow:hidden}.bluebar i{display:block;height:100%;width:66%;background:var(--blue)}
    .cards{display:grid;grid-template-columns:repeat(3,1fr);gap:18px;margin-top:46px}.card{background:rgba(255,255,255,.86);border:1px solid var(--line);border-radius:28px;padding:24px;box-shadow:0 14px 42px rgba(15,23,42,.08)}.card h3{font-size:27px;letter-spacing:-.035em;margin:0 0 14px}.card p{font-size:18px;line-height:1.32;color:var(--muted);font-weight:750;margin:0}
    .bottomCta{margin:46px auto 0;max-width:820px;background:rgba(255,255,255,.88);border:1px solid var(--line);border-radius:30px;padding:24px;box-shadow:0 18px 50px rgba(15,23,42,.09);text-align:center}.bottomCta h2{font-size:28px;letter-spacing:-.04em;margin:0 0 8px}.bottomCta p{margin:0;color:var(--muted);font-weight:750}.actions{display:grid;grid-template-columns:1fr 1fr;gap:14px;margin-top:20px}.btn{display:inline-flex;align-items:center;justify-content:center;min-height:58px;border-radius:18px;padding:0 24px;text-decoration:none;font-weight:1000;box-shadow:0 14px 36px rgba(37,99,235,.24)}.btn.primary{background:var(--blue);color:white}.btn.secondary{background:#e2e8f0;color:var(--ink);box-shadow:none}.locknote{font-size:13px;color:var(--muted);font-weight:850;margin-top:12px}.footer{margin-top:28px;color:var(--muted);font-size:13px;font-weight:750;text-align:center}
    @media(max-width:860px){.page{padding:20px 16px 42px}.nav{margin-bottom:24px}.logo{font-size:30px}.tag{font-size:10px}.hero{grid-template-columns:1fr;gap:28px}.eyebrow{font-size:11px}.lead{font-size:23px}.sublead{font-size:16px}.proof{grid-template-columns:1fr 1fr}.phone{display:none}.cards{grid-template-columns:1fr;margin-top:28px}.card{border-radius:24px;padding:22px}.card h3{font-size:27px}.card p{font-size:18px}.actions{grid-template-columns:1fr}.bottomCta{border-radius:24px;padding:20px}}
    @media(max-width:430px){h1{font-size:47px}.lead{font-size:21px}.proof{grid-template-columns:1fr}.logo{font-size:29px}.page{padding-left:18px;padding-right:18px}}
  </style>
</head>
<body>
  <main class="page">
    <div class="wrap">
      <header class="nav">
        <div><div class="logo">HAMRIQ</div><div class="tag">ROOFING. SIMPLIFIED.</div></div>
      </header>
      <section class="hero">
        <div>
          <div class="eyebrow">MOBILE-FIRST ROOFING CRM</div>
          <h1>Roofing workflow,<br>all in one place.</h1>
          <p class="lead">Built for reps in the field and managers who need the whole operation under control.</p>
          <p class="sublead">CRM, canvassing, inspections, production, billing, marketing, reporting, and Hammy AI help — designed to keep every roofing job moving.</p>
          <div class="proof"><div><b>Fast</b><span>field updates</span></div><div><b>Simple</b><span>rep workflow</span></div><div><b>Complete</b><span>manager view</span></div></div>
        </div>
        <aside class="phone" aria-label="HAMRIQ app preview">
          <div class="screen">
            <div class="miniLogo">HAMRIQ</div>
            <div class="today"><small>Today</small><strong>7 actions</strong><small>3 hot leads · 2 inspections</small></div>
            <div class="task"><b>Bob Smith</b><p>Hot lead · Call homeowner</p><div class="bluebar"><i></i></div></div>
            <div class="task"><b>James Walker</b><p>Inspection complete · Send proposal</p><div class="bluebar"><i style="width:82%"></i></div></div>
            <div class="task"><b>Hammy</b><p>Ask what to do next.</p><div class="bluebar"><i style="width:45%"></i></div></div>
          </div>
        </aside>
      </section>
      <section class="cards">
        <div class="card"><h3>Rep simple</h3><p>Today screen, next action, fast notes, and fewer taps in the field.</p></div>
        <div class="card"><h3>Manager complete</h3><p>Pipeline, approvals, production, billing, marketing, and reporting.</p></div>
        <div class="card"><h3>AI ready</h3><p>Designed for photo analysis, summaries, file cleanup, and workflow assistance.</p></div>
      </section>
      <section class="bottomCta">
        <h2>Access HAMRIQ</h2>
        <p>Demo and development areas are protected and require login credentials.</p>
        <div class="actions">
          <a class="btn primary" href="https://hamriq.app">Open demo</a>
          <a class="btn secondary" href="https://dev.hamriq.app">Development login</a>
        </div>
        <div class="locknote">Protected access only · no public app data exposed</div>
      </section>
      <div class="footer">HAMRIQ · Roofing workflow, simplified.</div>
    </div>
  </main>
</body>
</html>`;

export async function onRequest(context) {
  const host = new URL(context.request.url).hostname.toLowerCase();

  if (host === 'hamriq.com' || host === 'www.hamriq.com') {
    return new Response(landingHtml, {
      headers: {
        'content-type': 'text/html; charset=utf-8',
        'cache-control': 'no-store, no-cache, must-revalidate, max-age=0',
        'pragma': 'no-cache',
        'expires': '0'
      }
    });
  }

  return context.next();
}
