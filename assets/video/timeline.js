// Animação do vídeo do Farol: render(t) desenha o quadro do instante t (segundos). Sem relógio real:
// o mesmo t sempre dá o mesmo quadro (gravação quadro a quadro, sem travadas).
const $ = id => document.getElementById(id);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
const seg = (t, a, b) => clamp((t - a) / (b - a), 0, 1);
const ease = x => x < .5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2;
const vis = (t, a, b, fi = .4, fo = .4) => Math.min(seg(t, a, a + fi), 1 - seg(t, b - fo, b));
function op(el, o) { el.style.opacity = o; el.style.visibility = o <= 0.001 ? 'hidden' : 'visible'; }
function check(id, on) { $(id).textContent = on ? '✓' : ''; }
function hl(id, on) { $(id).classList.toggle('hl', !!on); }

const BAR1_ON = [0, 1, 2, 3, 7, 8, 9];
const BAR2_ON = [12, 13, 14, 15];
const BAR3_ON = [4, 5, 6];
const DUR = 60;

// Cursor: [chegada, alvo]. Alvo = id do elemento (centro) ou [x, y]. Cliques: [instante, botão].
const PATH = [[12.0, [980, 470]], [13.2, 'goldItem'], [19.2, 'goldItem'], [19.7, 'latItem'],
  [22.6, 'm10'], [23.6, 'm11'], [27.0, 'b2'], [28.4, 'mshow'], [31.0, 'b3'], [32.4, 'mshow'], [36.1, 'mclose'],
  [38.5, 'sp'], [40.6, 'sp'], [41.1, 'bm'], [43.0, [1000, 520]]];
const CLICKS = [19.8, 22.8, 23.8, 27.3, 28.6, 31.3, 32.6, 36.3, 38.8, 39.4, 40.0, 41.3, 41.9];
const CURSOR_ON = [12.0, 43.6];

function center(target) {
  if (Array.isArray(target)) return target;
  const r = $(target).getBoundingClientRect();
  return [r.left + r.width / 2, r.top + r.height / 2];
}
function cursorAt(t) {
  let pos = center(PATH[0][1]);
  for (let i = 1; i < PATH.length; i++) {
    const [arrive, target] = PATH[i];
    const start = Math.max(PATH[i - 1][0], arrive - 0.7);
    if (t >= arrive) { pos = center(target); continue; }
    if (t > start) {
      const from = center(PATH[i - 1][1]), to = center(target), k = ease(seg(t, start, arrive));
      pos = [from[0] + (to[0] - from[0]) * k, from[1] + (to[1] - from[1]) * k];
    }
    break;
  }
  return pos;
}

function render(t) {
  // Abertura
  const io = vis(t, 0, 5.3, .01, .6);
  op($('intro'), io);
  $('ilogo').style.transform = `scale(${0.6 + 0.4 * ease(seg(t, 0, 1))})`;
  op($('ilogo'), seg(t, 0, .8)); op($('ititle'), seg(t, .6, 1.4)); op($('isub'), seg(t, 1.2, 2));
  op($('brand'), seg(t, 5, 5.6) * (1 - seg(t, 51.5, 52)));

  // Fundo escurece as barras durante as janelas de alarme/avisos/saques
  const dim = 1 - 0.7 * seg(t, 44, 44.6);
  const barsOut = 1 - seg(t, 51.5, 52.1);

  // Barra 1: itens entram um a um; Reputação e Profissões entram quando marcadas no menu
  op($('bar1wrap'), seg(t, 5, 5.3) * dim * barsOut);
  document.querySelectorAll('#bar1 .bi').forEach((el, i) => {
    const k = seg(t, 5.3 + i * .25, 5.65 + i * .25);
    op(el, k); el.style.transform = `translateY(${(1 - ease(k)) * -10}px)`;
  });
  const bx = document.querySelectorAll('#bar1 .bx');
  [22.8, 23.8].forEach((when, i) => {
    bx[i].style.display = t >= when ? 'inline-flex' : 'none';
    op(bx[i], seg(t, when, when + .35));
  });
  const goldOn = t >= 13.2 && t < 19.3;
  $('goldItem').style.outline = goldOn ? '2px solid #ffd75a' : 'none';
  $('goldItem').style.borderRadius = '4px';

  // Tooltips
  op($('tip1w'), vis(t, 13.5, 16.7, .3, .2));
  op($('tip2w'), vis(t, 16.7, 19.3, .2, .3));
  op($('shift'), vis(t, 16.2, 19.3, .25, .3));
  $('shift').style.transform = t > 16.6 && t < 19.0 ? 'translateY(3px)' : 'none';
  $('shift').style.boxShadow = t > 16.6 && t < 19.0 ? '0 0 0 #888,0 4px 12px #000a' : '';

  // Menu (clique direito)
  const mo = vis(t, 20.0, 36.9, .35, .35);
  op($('menuw'), mo);
  $('menuw').style.transform = `scale(${0.92 + 0.08 * ease(seg(t, 20, 20.35))})`;
  const sel = t < 27.3 ? 1 : t < 31.3 ? 2 : 3;
  hl('b1', sel === 1); hl('b2', sel === 2); hl('b3', sel === 3);
  $('b2').textContent = t >= 28.6 ? 'Bar 2' : 'Bar 2 (off)';
  $('b3').textContent = t >= 32.6 ? 'Bar 3' : 'Bar 3 (off)';
  const onSet = sel === 1 ? BAR1_ON.concat(t >= 22.8 ? [10] : [], t >= 23.8 ? [11] : []) : sel === 2 ? BAR2_ON : BAR3_ON;
  for (let i = 0; i < 16; i++) check('m' + i, onSet.includes(i));
  check('mshow', sel === 1 || (sel === 2 && t >= 28.6) || (sel === 3 && t >= 32.6));
  const pulse = 0.75 + 0.25 * Math.sin(t * 6);
  op($('newbadge'), seg(t, 25.8, 26.3) * pulse);

  // Barra 2 (desce) e barra 3 (coluna, entra pela esquerda)
  const b2 = seg(t, 28.8, 29.4);
  op($('bar2wrap'), b2 * dim * barsOut);
  const scale = t < 38.8 ? 1 : t < 39.4 ? 1.1 : t < 40.0 ? 1.2 : 1.3;
  const bg = t < 41.3 ? 0.7 : t < 41.9 ? 0.5 : 0.3;
  $('bar2').style.transform = `translateY(${(1 - ease(b2)) * -24}px) scale(${scale})`;
  $('bar2').style.background = `rgba(0,0,0,${bg})`;
  $('vscale').textContent = Math.round(scale * 100) + '%';
  $('vbg').textContent = Math.round(bg * 100) + '%';
  const b3 = seg(t, 32.8, 33.4);
  op($('bar3'), b3 * dim * barsOut);
  $('bar3').style.transform = `translateX(${(1 - ease(b3)) * -40}px)`;

  // Aparência da barra 2
  op($('appw'), vis(t, 37.0, 43.8, .35, .35));

  // Alarme, saques e avisos
  op($('alarmw'), vis(t, 44.3, 51.6, .35, .4));
  op($('lootw'), vis(t, 45.2, 51.6, .35, .4));
  op($('warnw'), vis(t, 46.3, 51.6, .35, .4));
  $('alarmw').style.transform = `rotate(${t > 44.3 && t < 47 ? Math.sin(t * 40) * 1.2 * (1 - seg(t, 45.5, 47)) : 0}deg)`;

  // Final
  op($('outro'), vis(t, 52.0, DUR + 1, .6, .01));

  // Legendas
  CAPS.forEach(([a, b], i) => op($('cap' + i), vis(t, a, b, .35, .35)));

  // Cursor e clique
  const cv = vis(t, CURSOR_ON[0], CURSOR_ON[1], .3, .3);
  const [cx, cy] = cursorAt(t);
  op($('cursor'), cv);
  $('cursor').style.left = (cx - 2) + 'px'; $('cursor').style.top = (cy - 2) + 'px';
  let ring = 0, rk = 0;
  for (const c of CLICKS) if (t >= c && t < c + .4) { rk = seg(t, c, c + .4); ring = 1 - rk; }
  op($('ring'), ring * cv);
  $('ring').style.left = (cx - 22) + 'px'; $('ring').style.top = (cy - 22) + 'px';
  $('ring').style.transform = `scale(${0.4 + rk})`;
}
window.render = render;
window.DURATION = DUR;
// Ids auxiliares para o cursor
document.querySelectorAll('#bar1 .bi')[4].id = 'goldItem';
document.querySelectorAll('#bar1 .bi')[1].id = 'latItem';
document.querySelector('#menu .x').id = 'mclose';
render(0);
