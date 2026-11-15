// Grava o vídeo de divulgação a partir de video.html (gere antes com make_video.py).
//   node assets/video/record.js preview 9 30 48       -> preview_<t>.png (quadros de conferência, 1280×720)
//   node assets/video/record.js video [saida.mp4] [fps] [escala]
//        padrão: assets/video/farol-promo.mp4, 30 fps, escala 1.5 (= 1920×1080). Precisa de ffmpeg.
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const path = require('path');
(async () => {
  const mode = process.argv[2];
  const browser = await chromium.launch();
  const scale = mode === 'video' ? Number(process.argv[5] || 1.5) : 1;
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: scale });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  await page.goto('file://' + path.join(__dirname, process.env.PAGE || 'video.html')); // PAGE=youtube.html para o vídeo longo
  await page.evaluate(() => document.fonts.ready);
  if (mode === 'preview') {
    for (const t of process.argv.slice(3)) {
      await page.evaluate(x => window.render(x), Number(t));
      await page.screenshot({ path: path.join(__dirname, `preview_${t}.png`) });
    }
  } else {
    const out = process.argv[3] || path.join(__dirname, 'farol-promo.mp4'), fps = Number(process.argv[4] || 30);
    const dur = await page.evaluate(() => window.DURATION);
    const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(fps), '-c:v', 'mjpeg', '-i', '-',
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out], { stdio: ['pipe', 'inherit', 'inherit'] });
    const n = Math.round(dur * fps);
    for (let i = 0; i < n; i++) {
      await page.evaluate(x => window.render(x), i / fps);
      const buf = await page.screenshot({ type: 'jpeg', quality: 95 });
      if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
      if (i % 300 === 0) console.log('frame', i, '/', n);
    }
    ff.stdin.end();
    await new Promise(r => ff.on('close', r));
  }
  if (errors.length) console.log('PAGE ERRORS:', errors);
  await browser.close();
})();
