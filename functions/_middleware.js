const landingHtml = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <meta name="theme-color" content="#0b1220" />
  <title>HAMRIQ</title>
  <style>
    *{box-sizing:border-box}html,body{margin:0;min-height:100%;font-family:Inter,system-ui,-apple-system,Segoe UI,sans-serif;background:#eef3f8;color:#0f172a}.landing{min-height:100vh;padding:42px max(24px,env(safe-area-inset-left)) 80px;max-width:1100px;margin:0 auto}.brand{font-weight:950;letter-spacing:.05em;font-size:34px}.big{font-size:42px}.eyebrow{font-weight:900;letter-spacing:.08em;margin:34px 0 18px}.landing h1{font-size:58px;line-height:.98;letter-spacing:-.06em;margin:0 0 26px}.lead{font-size:24px;line-height:1.35;font-weight:650;max-width:900px}.row{display:flex;gap:14px;align-items:center;flex-wrap:wrap}.section{margin-top:24px}.btn{display:inline-flex;text-decoration:none;border:0;border-radius:16px;padding:15px 20px;background:#0f172a;color:#fff;font-weight:900}.btn.accent{background:#2563eb}.btn.secondary{background:#e2e8f0;color:#0f172a}.grid{display:grid;gap:18px}.cards{grid-template-columns:repeat(auto-fit,minmax(220px,1fr))}.card{background:white;border:1px solid #dbe3ee;border-radius:22px;padding:22px;box-shadow:0 9px 30px #0f172a0d}.card h3{font-size:28px;margin:0 0 18px}.muted{color:#64748b;font-size:22px;font-weight:700;line-height:1.2}@media(max-width:700px){.landing{padding:28px 18px 60px}.brand{font-size:30px}.big{font-size:36px}.landing h1{font-size:42px}.lead{font-size:20px}.row{display:grid}.btn{justify-content:center}.cards{grid-template-columns:1fr}.card h3{font-size:24px}.muted{font-size:19px}}
  </style>
</head>
<body>
  <main class="landing">
    <div class="brand big">HAMRIQ</div>
    <p class="eyebrow">ROOFING. SIMPLIFIED.</p>
    <h1>Roofing workflow,<br>all in one place.</h1>
    <p class="lead">A mobile-first roofing CRM for sales reps, managers, production, billing, canvassing, and marketing.</p>
    <div class="row section">
      <a class="btn accent" href="https://hamriq.app">Open demo</a>
      <a class="btn secondary" href="https://dev.hamriq.app">Development login</a>
    </div>
    <div class="grid cards section">
      <div class="card"><h3>Rep simple</h3><p class="muted">Today screen, next action, fast updates, and Hammy help.</p></div>
      <div class="card"><h3>Manager complete</h3><p class="muted">Pipeline, approvals, production, billing, marketing, and reporting.</p></div>
      <div class="card"><h3>AI ready</h3><p class="muted">Designed for photo analysis, summaries, cleanup, and workflow assistance.</p></div>
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
