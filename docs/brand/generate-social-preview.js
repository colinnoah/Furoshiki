const fs = require('fs');
function seigaiha({x0, y0, x1, y1, R, fill, stroke, sw, so}) {
  let out = ''; const rings = [1, 0.74, 0.48, 0.22]; let row = 0;
  for (let y = y0; y <= y1 + R; y += R / 2, row++) {
    const off = row % 2 ? R : 0;
    for (let x = x0 - 2 * R + off; x <= x1 + 2 * R; x += 2 * R) {
      out += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${R}" fill="${fill}"/>`;
      for (const k of rings) out += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(R * k - sw / 2).toFixed(1)}" fill="none" stroke="${stroke}" stroke-opacity="${so}" stroke-width="${sw}"/>`;
    }
  }
  return out;
}
const mark = fs.readFileSync('mark-color.svg', 'utf8').replace('<svg ', '<svg class="mark" ');
const waves = seigaiha({x0: 0, y0: 470, x1: 1280, y1: 640, R: 52, fill: '#141a52', stroke: '#4b5bc4', sw: 5, so: 0.5});
const html = `<!doctype html><html><head><meta charset="utf-8"><style>
html,body{margin:0;width:1280px;height:640px;overflow:hidden}
.card{position:relative;width:1280px;height:640px;background:linear-gradient(160deg,#2e3f96 0%,#1b2266 55%,#10133b 100%);font-family:'Inter Display','Inter',sans-serif;color:#fff}
.glow{position:absolute;inset:0;background:radial-gradient(circle at 27% 45%,rgba(255,138,94,.30),rgba(106,124,255,.06) 40%,transparent 62%)}
.waves{position:absolute;left:0;top:0;opacity:.55}
.mark{position:absolute;left:70px;top:150px;width:520px;height:auto;filter:drop-shadow(0 18px 22px rgba(5,7,34,.55))}
.text{position:absolute;left:640px;top:142px;width:580px}
.kana{font-family:'IPAGothic',sans-serif;font-size:30px;letter-spacing:.32em;color:#ff9a72;margin-bottom:6px}
h1{margin:0;font-size:112px;font-weight:800;letter-spacing:-.035em;line-height:1}
.tag{margin-top:22px;font-size:34px;font-weight:500;line-height:1.25;color:#e6e9ff}
.feat{margin-top:26px;font-family:'Inter',sans-serif;font-size:21px;line-height:1.55;color:#b8c0f2;text-shadow:0 1px 8px rgba(10,12,40,.9)}
.meta{position:absolute;left:640px;bottom:58px;font-family:'Inter',sans-serif;font-size:19px;font-weight:600;color:#fff;display:flex;gap:10px}
.pill{padding:7px 15px;border-radius:999px;background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.18)}
.pill.hot{background:#e8452f;border-color:#ff7b50}
</style></head><body><div class="card">
<svg class="waves" width="1280" height="640" viewBox="0 0 1280 640">${waves}</svg>
<div class="glow"></div>
${mark}
<div class="text">
<div class="kana">風呂敷</div>
<h1>Furoshiki</h1>
<div class="tag">Everything your Mac needs,<br>wrapped in one cloth.</div>
<div class="feat">Volume mixer · System monitor · App switcher<br>Window layouts · Clipboard history · Screenshots<br>Screen recording · Dock previews · and more</div>
</div>
<div class="meta"><span class="pill hot">Free &amp; open source</span><span class="pill">macOS 14+</span><span class="pill">Apple Silicon</span></div>
</div></body></html>`;
fs.writeFileSync('social-preview.html', html);
