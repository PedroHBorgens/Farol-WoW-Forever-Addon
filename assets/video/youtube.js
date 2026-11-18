// Vídeo longo do Farol: render(t) desenha o quadro do instante t (segundos). Cada cena anima com o tempo local
// (lt, a partir do início da cena); a narração da cena começa em lt = 0,5 s. Sem relógio real: o mesmo t dá sempre
// o mesmo quadro.
const $ = id => document.getElementById(id);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const seg = (t, a, b) => clamp((t - a) / (b - a), 0, 1);
const ease = x => x < .5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2;
const vis = (t, a, b, fi = .35, fo = .35) => Math.min(seg(t, a, a + fi), 1 - seg(t, b - fo, b));
function op(el, o) { el.style.opacity = o; el.style.visibility = o <= 0.001 ? 'hidden' : 'visible'; }
function check(id, on) { $(id).textContent = on ? '✓' : ''; }
function hl(el, on) { el.classList.toggle('hl', !!on); }
const items = id => Array.from(document.querySelectorAll('#' + id + ' .bi, #' + id + ' .bx'));
function stagger(id, lt, from, step) {
  items(id).forEach((el, i) => { const k = seg(lt, from + i * step, from + i * step + .35); op(el, k); el.style.transform = `translateY(${(1 - ease(k)) * -10}px)`; });
}
function glow(el, on) { el.style.outline = on ? '2px solid #ffd75a' : 'none'; el.style.borderRadius = '4px'; }
const ON1 = [0, 1, 2, 3, 7, 8, 9];

// Cada cena: anim(lt, dur) e, se tiver cursor, cursor = { path: [[lt, alvo]], clicks: [lt], on: [a, b] }.
const SC = {};
SC.intro = { anim(lt) {
  $('ilogo').style.transform = `scale(${0.6 + 0.4 * ease(seg(lt, 0, 1))})`;
  op($('ilogo'), seg(lt, 0, .8)); op($('ititle'), seg(lt, .6, 1.4)); op($('isub'), seg(lt, 1.2, 2)); op($('isub2'), seg(lt, 2, 2.8));
} };
SC.bar = { anim(lt) {
  stagger('barA', lt, .5, .45);
  items('barA').forEach((el, i) => glow(el, lt > 2 + i * 1.0 && lt < 2.9 + i * 1.0));
} };
SC.tip = { anim(lt) {
  const gold = items('barT')[4]; glow(gold, lt > 1 && lt < 9.5);
  op($('tipS').parentNode, vis(lt, 1.2, 4.3, .25, .2)); op($('tipF').parentNode, vis(lt, 4.3, 99, .2, .01));
  op($('shiftkey'), vis(lt, 3.8, 99, .25, .01));
  $('shiftkey').style.transform = lt > 4.2 ? 'translateY(3px)' : 'none';
}, cursor: { on: [0, 99], path: [[0, [980, 470]], [1, () => items('barT')[4]]], clicks: [] } };
SC.menu = { anim(lt) {
  op($('Mmenu').parentNode, vis(lt, .8, 99, .35, .01));
  $('Mmenu').parentNode.style.transform = `scale(${0.92 + 0.08 * ease(seg(lt, .8, 1.15))})`;
  check('Mm10', lt >= 3.6); check('Mm11', lt >= 4.6);
  [[ 'mx1', 3.6 ], [ 'mx2', 4.6 ]].forEach(([id, w]) => { $(id).style.display = lt >= w ? 'inline-flex' : 'none'; op($(id), seg(lt, w, w + .35)); });
}, cursor: { on: [0, 99], path: [[0, [900, 500]], [.6, () => items('barM')[1]], [3.4, 'Mm10'], [4.4, 'Mm11'], [6.5, [1000, 520]]], clicks: [.7, 3.6, 4.6] } };
SC.order = { anim(lt) {
  // "Ouro" (posição 5) sobe duas vezes: ▲ em 2,4 s e 3,6 s. As linhas deslizam e a barra acompanha.
  let order = [0, 1, 2, 3, 4, 5, 6];
  const moves = [[2.4, 4], [3.6, 3]];
  let anim = null;
  for (const [w, pos] of moves) {
    if (lt >= w) { const tmp = order[pos]; order[pos] = order[pos - 1]; order[pos - 1] = tmp; if (lt < w + .4) anim = { w, pos }; }
  }
  order.forEach((item, rank) => {
    let y = rank * 32;
    if (anim) { const k = ease(seg(lt, anim.w, anim.w + .4)); if (rank === anim.pos - 1) y = (anim.pos - k) * 32; if (rank === anim.pos) y = (anim.pos - 1 + k) * 32; }
    const row = $('or' + item); row.style.top = y + 'px';
    row.querySelector('.onum').textContent = (rank + 1) + '.';
    items('barO')[item].style.order = rank;
  });
  glow(items('barO')[4], lt > 2.3 && lt < 5);
}, cursor: { on: [0, 99], path: [[0, [1000, 500]], [2.2, 'oup4'], [3.4, () => $('or4').querySelector('[id^=oup]')], [5.5, [1050, 520]]], clicks: [2.4, 3.6] } };
SC.progress = { anim(lt) {
  stagger('barP', lt, .3, .3);
  op($('tipP'), seg(lt, 1.2, 1.6));
  items('barP').forEach((el, i) => glow(el, lt > 1.5 + i * 2.2 && lt < 3.5 + i * 2.2));
} };
SC.resets = { anim(lt) {
  op($('tipG'), seg(lt, 3.5, 3.9)); op($('tipR'), seg(lt, .8, 1.2));
  glow(items('barR')[1], lt > .6 && lt < 3.5); glow(items('barR')[0], lt > 3.5);
} };
SC.bars = { anim(lt) {
  const sel = lt < 3.2 ? 1 : lt < 7.2 ? 2 : 3;
  [1, 2, 3].forEach(n => hl($('Bb' + n), sel === n));
  $('Bb2').textContent = lt >= 4.4 ? 'Bar 2' : 'Bar 2 (off)';
  $('Bb3').textContent = lt >= 8.4 ? 'Bar 3' : 'Bar 3 (off)';
  const on = sel === 1 ? ON1.concat([10]) : sel === 2 ? [12, 13, 14, 15] : [4, 5, 6];
  for (let i = 0; i < 16; i++) check('Bm' + i, on.includes(i));
  check('Bshow', sel === 1 || (sel === 2 && lt >= 4.4) || (sel === 3 && lt >= 8.4));
  const b2 = seg(lt, 4.6, 5.2), b3 = seg(lt, 8.6, 9.2);
  op($('bwrap2'), b2); $('barB2').style.transform = `translateY(${(1 - ease(b2)) * -24}px)`;
  op($('bwrap3'), b3); $('bwrap3').style.transform = `translateX(${(1 - ease(b3)) * -40}px)`;
}, cursor: { on: [0, 99], path: [[0, [1000, 500]], [3.0, 'Bb2'], [4.2, 'Bshow'], [7.0, 'Bb3'], [8.2, 'Bshow'], [10.5, [1050, 520]]], clicks: [3.2, 4.4, 7.2, 8.4] } };
SC.appearance = { anim(lt) {
  const scale = lt < 2.0 ? 1 : lt < 2.6 ? 1.1 : lt < 3.2 ? 1.2 : 1.3;
  const bg = lt < 4.4 ? .7 : lt < 5.0 ? .5 : .3;
  const col = lt >= 7.0;
  const b = $('barA2');
  b.style.transform = `scale(${scale})`; b.style.background = `rgba(0,0,0,${bg})`;
  b.style.flexDirection = col ? 'column' : 'row'; b.style.alignItems = col ? 'flex-start' : 'center'; b.style.gap = col ? '5px' : '13px';
  b.parentNode.style.justifyContent = col ? 'flex-start' : 'center'; b.parentNode.style.paddingLeft = col ? '40px' : '0';
  $('vscale').textContent = Math.round(scale * 100) + '%'; $('vbg').textContent = Math.round(bg * 100) + '%';
  hl($('lline'), !col); hl($('lcol'), col); check('acombat', lt >= 9.6);
}, cursor: { on: [0, 99], path: [[0, [1000, 520]], [1.8, 'sp'], [3.4, 'sp'], [4.2, 'bm'], [5.2, 'bm'], [6.8, 'lcol'], [9.4, 'acombat'], [11, [1060, 540]]], clicks: [2.0, 2.6, 3.2, 4.4, 5.0, 7.0, 9.6] } };
function placeDrop(dd, btn) { const r = $(btn).getBoundingClientRect(); dd.style.left = r.left + 'px'; dd.style.top = (r.bottom + 2) + 'px'; }
SC.profiles = { anim(lt) {
  const own = lt >= 3.4, copied = lt >= 8.2;
  $('Pprof').textContent = own ? 'This character ▾' : 'Account ▾';
  placeDrop($('ddprof'), 'Pprof'); placeDrop($('ddcopy'), 'Pcopy');
  op($('ddprof'), vis(lt, 2.0, 3.45, .15, .1)); op($('ddcopy'), vis(lt, 6.6, 8.25, .15, .1));
  $('ddprof1').style.background = lt > 2.9 && lt < 3.45 ? '#ffffff22' : ''; $('ddcopy1').style.background = lt > 7.6 && lt < 8.25 ? '#ffffff22' : '';
  op($('pc1'), seg(lt, 3.5, 3.8)); op($('pc2'), seg(lt, 8.3, 8.6));
  // Mira: relógio, resets e reputação no lugar de FPS e latência
  items('barPF').forEach((el, i) => { const show = copied ? ![0, 1, 6].includes(i) : i < 7; el.style.display = show ? 'inline-flex' : 'none'; });
  const on = copied ? [2, 3, 7, 8, 10, 12, 13] : ON1;
  for (let i = 0; i < 16; i++) check('Pm' + i, on.includes(i));
}, cursor: { on: [0, 99], path: [[0, [1000, 520]], [1.8, 'Pprof'], [3.0, 'ddprof1'], [6.4, 'Pcopy'], [7.8, 'ddcopy1'], [10, [1060, 470]]], clicks: [2.0, 3.4, 6.6, 8.2] } };
SC.goals = { anim(lt) {
  op($('gv').closest('.win').parentNode, seg(lt, .3, .7));
  $('gv').textContent = '500'.slice(0, Math.floor(seg(lt, 1.4, 2.0) * 3 + 1e-6));
  $('lv').textContent = '40'.slice(0, Math.floor(seg(lt, 3.6, 4.0) * 2 + 1e-6));
  op($('gsst'), seg(lt, 2.6, 2.9)); op($('lsst'), seg(lt, 4.6, 4.9));
  const gi = items('barGo')[4];
  op(gi, seg(lt, 2.6, 2.9)); op($('gol'), seg(lt, 4.6, 4.9)); $('gol').style.display = lt >= 4.6 ? 'inline' : 'none';
  glow(gi, lt > 2.6 && lt < 99);
  op($('tipGo'), seg(lt, 6.0, 6.4));
}, cursor: { on: [0, 6], path: [[0, [700, 520]], [1.2, 'gv'], [2.4, 'gs'], [3.4, 'lv'], [4.4, 'ls'], [5.6, [700, 560]]], clicks: [1.3, 2.6, 3.5, 4.6] } };
SC.farm = { anim(lt) {
  op($('fb0').closest('.win').parentNode, seg(lt, .3, .7));
  const added = lt >= 2.6;
  $('fitem').style.display = added ? 'inline-flex' : 'none'; op($('fitem'), seg(lt, 2.6, 3.0));
  glow(items('barF')[4], added);
  op($('fchat'), seg(lt, 2.7, 3.0));
  hl($('fb0'), lt > 2.0 && lt < 3.0);
  const n = 27 + Math.min(6, Math.max(0, Math.floor((lt - 4.5) / 1.1)));
  const txt = n + '/40';
  $('fcnt').textContent = txt; $('ftcnt').textContent = txt;
  op($('tipF2'), seg(lt, 5.2, 5.6));
  $('fpace').innerHTML = n > 27 ? `&nbsp;&nbsp;&nbsp;+${n - 27 + 18} this session (~24/h) · ~${Math.round((40 - n) / 24 * 60)}m left` : '&nbsp;&nbsp;&nbsp;no pace yet this session';
  op($('newbadge2'), seg(lt, .3, .8) * (0.75 + 0.25 * Math.sin(lt * 6)));
}, cursor: { on: [0, 4.5], path: [[0, [700, 560]], [2.4, 'fb0'], [4.2, [700, 600]]], clicks: [2.6] } };
SC.tasks = { anim(lt) {
  op($('tb0').closest('.win').parentNode, seg(lt, .3, .7));
  const done = [true, lt >= 2.6, false, lt >= 4.4];
  done.forEach((d, i) => { check('tb' + i, d); $('tn' + i).className = d ? 'g' : ''; });
  const n = done.filter(Boolean).length;
  $('tkcnt').textContent = n + '/4';
  glow(items('barTk')[3], lt > 2.6 && lt < 99);
}, cursor: { on: [0, 6.5], path: [[0, [1000, 560]], [2.4, 'tb1'], [4.2, 'tb3'], [6, [1000, 600]]], clicks: [2.6, 4.4] } };
SC.runs = { anim(lt) {
  const ri = items('barRn')[4]; op(ri, Math.min(seg(lt, .6, 1.0), 1 - seg(lt, 3.8, 4.2))); glow(ri, lt > .6 && lt < 4);
  op($('rsum'), seg(lt, 4.0, 4.4));
  op($('rwin'), seg(lt, 7.0, 7.4));
  for (let i = 0; i < 4; i++) op($('rr' + i), seg(lt, 7.4 + i * .3, 7.7 + i * .3));
} };
function mmPos(angle) { const a = angle * Math.PI / 180, r = 110 + 14; return [930 + 110 + Math.cos(a) * r - 20, 250 + 110 - Math.sin(a) * r - 20]; }
SC.minimap = { anim(lt) {
  const angle = 215 + 70 * ease(seg(lt, 8.4, 10.2));
  const [x, y] = mmPos(angle); $('mmbtn').style.left = x + 'px'; $('mmbtn').style.top = y + 'px';
  glow($('mmbtn'), lt > 1 && lt < 3.4); $('mmbtn').style.borderRadius = '50%';
  op($('mmtip'), vis(lt, 1.2, 3.6, .25, .25));
  const hidden = lt >= 4.4 && lt < 6.6;
  const bo = hidden ? 1 - seg(lt, 4.4, 4.8) : (lt >= 6.6 ? seg(lt, 6.6, 7.0) : 1);
  op($('mmb1'), bo); op($('mmb2'), bo);
  op($('mmchat'), seg(lt, 4.5, 4.8)); op($('mmc1'), seg(lt, 4.5, 4.8)); op($('mmc2'), seg(lt, 6.7, 7.0));
}, cursor: { on: [0, 11], path: [[0, [700, 560]], [1.0, 'mmbtn'], [8.3, 'mmbtn'], [10.2, () => 'mmbtn'], [11, [800, 600]]], clicks: [4.4, 6.6] } };
SC.alarms = { anim(lt) {
  const p = $('alarmpop'); op(p, vis(lt, 1.6, 5.6, .3, .4));
  p.style.transform = `rotate(${lt > 1.6 && lt < 4 ? Math.sin(lt * 40) * 1.2 * (1 - seg(lt, 3, 4)) : 0}deg)`;
}, cursor: { on: [3.5, 7], path: [[3.5, [1000, 500]], [5.0, 'snooze']], clicks: [5.2] } };
SC.warnings = { anim(lt) { for (let i = 0; i < 6; i++) { const k = seg(lt, .6 + i * 1.35, .95 + i * 1.35); op($('w' + i), k); $('w' + i).style.transform = `translateX(${(1 - ease(k)) * 20}px)`; } } };
SC.loot = { anim(lt) { for (let i = 0; i < 6; i++) op($('l' + i), seg(lt, .5 + i * .35, .8 + i * .35)); } };
SC.summary = { anim(lt) { for (let i = 0; i < 4; i++) op($('s' + i), seg(lt, .6 + i * 1.6, .9 + i * 1.6)); } };
SC.safety = { anim(lt) { for (let i = 0; i < 5; i++) { const k = seg(lt, .5 + i * 1.7, .85 + i * 1.7); op($('pl' + i), k); $('pl' + i).style.transform = `scale(${0.9 + 0.1 * ease(k)})`; } } };
SC.outro = { anim(lt) {} };

function center(target) {
  if (typeof target === 'function') target = target();
  if (Array.isArray(target)) return target;
  const el = typeof target === 'string' ? $(target) : target;
  const r = el.getBoundingClientRect();
  return [r.left + r.width / 2, r.top + r.height / 2];
}
function cursorAt(path, lt) {
  let pos = center(path[0][1]);
  for (let i = 1; i < path.length; i++) {
    const [arrive, target] = path[i];
    const start = Math.max(path[i - 1][0], arrive - 0.7);
    if (lt >= arrive) { pos = center(target); continue; }
    if (lt > start) {
      const from = center(path[i - 1][1]), to = center(target), k = ease(seg(lt, start, arrive));
      pos = [from[0] + (to[0] - from[0]) * k, from[1] + (to[1] - from[1]) * k];
    }
    break;
  }
  return pos;
}

function render(t) {
  let cursorShown = false;
  SCENES.forEach(s => {
    const el = $('sc_' + s.key), lt = t - s.start;
    const o = Math.min(seg(t, s.start - .3, s.start + .3), 1 - seg(t, s.start + s.dur - .3, s.start + s.dur + .3));
    const first = s.start === 0, last = s.start + s.dur >= TOTAL - .01;
    op(el, first ? Math.min(1 - seg(t, s.dur - .3, s.dur + .3), 1) : last ? seg(t, s.start - .3, s.start + .3) : o);
    if (el.style.visibility === 'hidden') return;
    SC[s.key].anim(lt, s.dur);
    const c = SC[s.key].cursor;
    if (c && t >= s.start && t < s.start + s.dur) {
      const [cx, cy] = cursorAt(c.path, lt);
      const cv = vis(lt, c.on[0], Math.min(c.on[1], s.dur), .3, .3);
      op($('cursor'), cv); $('cursor').style.left = (cx - 2) + 'px'; $('cursor').style.top = (cy - 2) + 'px';
      let ring = 0, rk = 0;
      for (const w of c.clicks) if (lt >= w && lt < w + .4) { rk = seg(lt, w, w + .4); ring = 1 - rk; }
      op($('ring'), ring * cv); $('ring').style.left = (cx - 22) + 'px'; $('ring').style.top = (cy - 22) + 'px';
      $('ring').style.transform = `scale(${0.4 + rk})`;
      cursorShown = true;
    }
  });
  if (!cursorShown) { op($('cursor'), 0); op($('ring'), 0); }
  op($('brand'), seg(t, SCENES[0].dur - .3, SCENES[0].dur + .3) * (1 - seg(t, TOTAL - 10, TOTAL - 9.4)));
}
window.render = render;
window.DURATION = TOTAL;
render(0);
