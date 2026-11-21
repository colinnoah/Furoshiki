const fs = require('fs');
function seigaiha({x0, y0, x1, y1, R, fill, stroke, sw, so}) {
  let out = '';
  const rings = [1, 0.74, 0.48, 0.22];
  let row = 0;
  for (let y = y0; y <= y1 + R; y += R / 2, row++) {
    const off = row % 2 ? R : 0;
    for (let x = x0 - 2 * R + off; x <= x1 + 2 * R; x += 2 * R) {
      out += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${R}" fill="${fill}"/>`;
      for (const k of rings) out += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(R * k - sw / 2).toFixed(1)}" fill="none" stroke="${stroke}" stroke-opacity="${so}" stroke-width="${sw}"/>`;
    }
  }
  return out;
}
const body = "M206 146 C 150 160, 110 212, 112 262 C 114 304, 150 320, 206 322 L 434 322 C 490 320, 526 304, 528 262 C 530 212, 490 160, 434 146 C 396 138, 360 136, 320 136 C 280 136, 244 138, 206 146 Z";
const earL = "M304 120 C 250 56, 150 6, 44 10 C 18 12, 14 30, 34 44 C 104 92, 178 138, 296 150 Z";
const earR = "M336 120 C 390 56, 490 6, 596 10 C 622 12, 626 30, 606 44 C 536 92, 462 138, 344 150 Z";
const S = 1.14, TX = 512 - 320 * S, TY = 548 - 170 * S;
const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="0.3" y2="1"><stop offset="0" stop-color="#2e3f96"/><stop offset="0.55" stop-color="#1b2266"/><stop offset="1" stop-color="#10133b"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.47" r="0.5"><stop offset="0" stop-color="#ff8a5e" stop-opacity="0.28"/><stop offset="0.6" stop-color="#6a7cff" stop-opacity="0.08"/><stop offset="1" stop-color="#6a7cff" stop-opacity="0"/></radialGradient>
  <linearGradient id="cloth" gradientUnits="userSpaceOnUse" x1="0" y1="136" x2="60" y2="322"><stop offset="0" stop-color="#ff7b50"/><stop offset="0.55" stop-color="#e8452f"/><stop offset="1" stop-color="#b3261d"/></linearGradient>
  <linearGradient id="ear" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ff8f62"/><stop offset="1" stop-color="#d93d29"/></linearGradient>
  <radialGradient id="knot" cx="0.42" cy="0.35" r="0.7"><stop offset="0" stop-color="#ffa27a"/><stop offset="1" stop-color="#d33a27"/></radialGradient>
  <clipPath id="squircle"><rect x="100" y="100" width="824" height="824" rx="186"/></clipPath>
  <clipPath id="bodyclip"><path d="${body}"/></clipPath>
  <filter id="shadow" x="-20%" y="-30%" width="140%" height="170%"><feDropShadow dx="0" dy="14" stdDeviation="14" flood-color="#050722" flood-opacity="0.55"/></filter>
  <filter id="iconshadow" x="-10%" y="-10%" width="120%" height="125%"><feDropShadow dx="0" dy="12" stdDeviation="14" flood-color="#000" flood-opacity="0.3"/></filter>
  <linearGradient id="sheen" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0.16"/><stop offset="0.5" stop-color="#fff" stop-opacity="0"/></linearGradient>
</defs>
<g filter="url(#iconshadow)"><rect x="100" y="100" width="824" height="824" rx="186" fill="url(#bg)"/></g>
<g clip-path="url(#squircle)">
  <g opacity="0.55">${seigaiha({x0:100,y0:640,x1:924,y1:924,R:56,fill:'#141a52',stroke:'#4b5bc4',sw:5,so:0.55})}</g>
  <rect x="100" y="100" width="824" height="824" fill="url(#glow)"/>
  <rect x="100" y="100" width="824" height="824" rx="186" fill="url(#sheen)"/>
</g>
<rect x="101.5" y="101.5" width="821" height="821" rx="185" fill="none" stroke="#fff" stroke-opacity="0.12" stroke-width="3"/>
<g transform="translate(${TX.toFixed(1)} ${TY.toFixed(1)}) scale(${S})" filter="url(#shadow)">
  <path fill="url(#ear)" d="${earL}"/><path fill="url(#ear)" d="${earR}"/>
  <path fill="#7d160f" opacity="0.22" d="M296 150 C 200 140, 120 100, 50 46 C 140 92, 210 124, 300 130 Z"/>
  <path fill="#7d160f" opacity="0.22" d="M344 150 C 440 140, 520 100, 590 46 C 500 92, 430 124, 340 130 Z"/>
  <path fill="#fff" opacity="0.25" d="M290 112 C 230 60, 150 22, 60 20 C 150 34, 230 70, 294 120 Z"/>
  <path fill="#fff" opacity="0.25" d="M350 112 C 410 60, 490 22, 580 20 C 490 34, 410 70, 346 120 Z"/>
  <g clip-path="url(#bodyclip)">
    ${seigaiha({x0:100,y0:120,x1:540,y1:330,R:30,fill:'url(#cloth)',stroke:'#ffd9c7',sw:3.2,so:0.38})}
    <path d="M100 340 L 540 340 L 540 262 C 440 314, 200 314, 100 262 Z" fill="#5c0f0a" opacity="0.22"/>
    <g fill="none" stroke-linecap="round">
      <path d="M296 168 C 258 218, 212 262, 150 300" stroke="#6e130d" stroke-opacity="0.55" stroke-width="10"/>
      <path d="M344 168 C 382 218, 428 262, 490 300" stroke="#6e130d" stroke-opacity="0.55" stroke-width="10"/>
      <path d="M289 164 C 251 214, 205 258, 143 296" stroke="#fff" stroke-opacity="0.4" stroke-width="4"/>
      <path d="M351 164 C 389 214, 435 258, 497 296" stroke="#fff" stroke-opacity="0.4" stroke-width="4"/>
    </g>
  </g>
  <ellipse cx="320" cy="128" rx="52" ry="36" fill="#6e130d" opacity="0.35"/>
  <ellipse cx="320" cy="124" rx="46" ry="32" fill="url(#knot)"/>
  <path d="M290 120 C 296 104, 312 98, 326 98" fill="none" stroke="#fff" stroke-opacity="0.55" stroke-width="5" stroke-linecap="round"/>
</g>
</svg>`;
fs.writeFileSync('appicon.svg', svg);
// Colored standalone mark (README logo, Icon Composer layer): same bundle, no tile.
const g = svg.match(/<g transform="translate[^"]*" filter="url\(#shadow\)">([\s\S]*?)\n<\/g>\n<\/svg>/)[1];
const defs = svg.match(/<defs>([\s\S]*?)<\/defs>/)[1]
  .split('\n').filter(l => /id="(cloth|ear|knot|bodyclip)"/.test(l)).join('\n');
const markColor = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 324" width="640" height="324">
<title>Furoshiki</title>
<defs>
${defs}
</defs>
${g}
</svg>`;
fs.writeFileSync('mark-color.svg', markColor);
