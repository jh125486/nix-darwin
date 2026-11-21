// Usage: NODE_PATH=<dir containing node_modules/playwright> node verify.js <url> <outdir>
// Screenshots every slide at 1280x720 and reports overflow and stray markup.
const { chromium } = require('playwright');
const [url, out] = process.argv.slice(2);
if (!url || !out) { console.error('usage: verify.js <url> <outdir>'); process.exit(2); }
require('fs').mkdirSync(out, { recursive: true });
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1280, height: 720 } });
  await p.goto(url, { waitUntil: 'networkidle' });
  await p.waitForTimeout(800);
  const n = await p.$$eval('article', a => a.length);
  for (let i = 1; i <= n; i++) {
    if (i > 1) await p.keyboard.press('ArrowRight');
    await p.waitForTimeout(500);
    const file = `${out}/slide_${String(i).padStart(2, '0')}.png`;
    await p.screenshot({ path: file });
    const info = await p.evaluate(i => {
      const a = document.querySelectorAll('article')[i - 1];
      const r = a.getBoundingClientRect();
      let bottom = 0;
      a.querySelectorAll('*').forEach(e => {
        if (e.closest('.pagenumber')) return; // fixed-position slide number, not content
        const er = e.getBoundingClientRect();
        if (er.height > 0) bottom = Math.max(bottom, er.bottom);
      });
      const h = a.querySelector('h2,h3,h1');
      // literal markup left in rendered text (code blocks legitimately contain _ and *)
      const stray = (a.innerText.match(/.{0,25}[*_].{0,25}/g) || []);
      return { title: h ? h.innerText.slice(0, 40) : '', bottom: Math.round(bottom - r.top), height: a.offsetHeight, stray };
    }, i);
    const flag = info.bottom > info.height - 20 ? ' TIGHT/OVERFLOW' : '';
    console.log(`${i} ${info.title} bottom=${info.bottom}/${info.height}${flag}${info.stray.length ? ' STRAY: ' + info.stray.join(' | ') : ''}`);
  }
  await b.close();
})();
