# Promo video / Vídeo de divulgação

A 60-second animated **illustration** of Farol (1920×1080, 30 fps, captions in English and Portuguese, no audio):
the info bar, per-item and full (Shift) tooltips, the options menu, **up to 3 bars**, the Appearance window,
alarms, warnings and recent loot, and a closing card ("only reads and shows", unofficial, free on CurseForge).
It uses the same look as the CurseForge images — drawings of the add-on's windows, not in-game footage, with the
"Illustration · Ilustração" label — and generic names (no Blizzard characters, places or items).

Um vídeo animado de 60 segundos do Farol (1920×1080, 30 quadros/s, legendas em inglês e português, sem áudio), no
mesmo estilo das imagens do CurseForge: desenhos das janelas do addon, não gravação do jogo, com o selo
"Illustration · Ilustração" e nomes genéricos (nada de personagens, lugares ou itens da Blizzard).

## Regenerate / Gerar de novo

Requires Python 3, Node.js with Playwright (Chromium) and `ffmpeg`. From the repository root:

```
python3 assets/video/make_video.py              # writes assets/video/video.html
node assets/video/record.js preview 9 30 48     # optional: check frames (preview_9.png ...)
node assets/video/record.js video               # writes assets/video/farol-promo.mp4 (~2 min)
```

- `make_video.py` — the scenes (bars, menu, windows) and the captions (`CAPS`: start, end, EN, PT).
- `timeline.js` — what happens at each second (`render(t)`): items appearing, cursor path (`PATH`), clicks
  (`CLICKS`), bars 2 and 3, scale/background changes. The same `t` always gives the same frame, so the video
  is identical on every run.
- `record.js` — renders every frame with Playwright and pipes it to `ffmpeg` (H.264, `yuv420p`, `+faststart`).

When a window changes in the add-on, update the matching scene here (and the CurseForge image), then regenerate.
Ao mudar uma janela do addon, atualize a cena correspondente aqui (e a imagem do CurseForge) e gere de novo.
The `.html`, `.mp4` and preview files are not versioned / não são versionados.

## YouTube video (~4 min, narrated) / Vídeo do YouTube (~4 min, narrado)

21 scenes, one narration paragraph each (`youtube_script.txt`, generated from `SCENES` in `youtube.py`), with
YouTube subtitles in English and Portuguese (`NARRATION_PT`: one Portuguese sentence for each English one).
The narration audio is not versioned; `youtube_timing.json` keeps where each paragraph is in it and how long each
scene lasts.

Free, local narration with [Piper](https://github.com/rhasspy/piper) (`pip install piper-tts`; voice
`voice-en-us-ryan-high.tar.gz` from the Piper GitHub releases):

```
python3 assets/video/youtube_audio.py piper en-us-ryan-high.onnx narration.mp3   # audio + youtube_timing.json
python3 assets/video/youtube.py                                                 # writes youtube.html
PAGE=youtube.html node assets/video/record.js video youtube-silent.mp4
python3 assets/video/youtube_audio.py mix narration.mp3 youtube-silent.mp4 farol-youtube.mp4
python3 assets/video/youtube_audio.py subs narration.mp3                         # farol-youtube.en.srt / .pt-BR.srt
```

With an audio from another source (e.g. ElevenLabs, one take for the whole script), use
`youtube_audio.py prepare narration.mp3 <end1,...,end20>` (where each paragraph ends) instead of `piper`.
Upload the two `.srt` files on YouTube (Subtitles → Add language → Upload file, "With timing").

21 cenas, um parágrafo de narração cada, com legendas do YouTube em inglês e português. O áudio não é versionado;
`youtube_timing.json` guarda onde está cada parágrafo e a duração de cada cena. Narração gratuita e local com o Piper
(comandos acima); as legendas `.srt` sobem no YouTube em Legendas → Adicionar idioma → Enviar arquivo ("Com tempo").
