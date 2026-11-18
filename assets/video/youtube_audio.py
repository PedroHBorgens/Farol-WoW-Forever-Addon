"""Narração do vídeo longo (YouTube).
  prepare <narração.mp3> <fim1,fim2,...,fim15>  → youtube_timing.json: trecho do áudio de cada cena (cortado nas
      pausas informadas, conferidas frase a frase) e a duração de cada cena (fala + respiro, nunca menos que o mínimo
      da animação). Depois rode youtube.py de novo e grave o vídeo.
  mix <narração.mp3> <vídeo.mp4> <saída.mp4>  → coloca cada trecho no início da sua cena (+0,5 s), volume -16 LUFS.
  piper <voz.onnx> <narração.mp3>  → narração gratuita e local com o Piper (pip install piper-tts; vozes em
      github.com/rhasspy/piper/releases, ex.: voice-en-us-ryan-high.tar.gz): uma cena por vez, pausas fixas entre
      frases (0,45 s) e cenas (1 s), e já grava youtube_timing.json com o trecho exato de cada cena.
  subs [narração.mp3]  → farol-youtube.en.srt e farol-youtube.pt-BR.srt (legendas do YouTube). Com o áudio, cada frase
      começa na pausa certa dentro do trecho da cena; sem ele, o tempo é dividido pelo tamanho das frases.
Precisa de ffmpeg."""
import json, os, re, subprocess, sys
OUT = os.path.dirname(os.path.abspath(__file__))
TIMING = os.path.join(OUT, "youtube_timing.json")
BREATH = 3.9  # segundos de respiro depois da fala em cada cena

def silences(mp3):
    err = subprocess.run(["ffmpeg", "-hide_banner", "-i", mp3, "-af", "silencedetect=noise=-35dB:d=0.2", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    return list(zip([float(x) for x in re.findall(r"silence_start: ([0-9.]+)", err)],
                    [float(x) for x in re.findall(r"silence_end: ([0-9.]+)", err)]))

def prepare(mp3, ends):
    sys.path.insert(0, OUT)
    ns = {"__file__": os.path.join(OUT, "youtube.py")}
    src = open(os.path.join(OUT, "youtube.py"), encoding="utf-8").read().split("timing_path =")[0]
    exec(compile(src, "youtube", "exec"), ns)  # só SCENES e MIN_DUR (não gera a página)
    keys = [sc[0] for sc in ns["SCENES"]]
    sil = silences(mp3)
    assert len(ends) == len(keys) - 1, f"preciso de {len(keys) - 1} fins de trecho"
    after = {round(a, 2): b for a, b in sil}
    starts = [0.0] + [after.get(round(e, 2), e + 0.4) for e in ends]
    last_end = sil[-1][0] if sil else None
    segs = [[round(starts[i], 2), round(ends[i] if i < len(ends) else last_end, 2)] for i in range(len(keys))]
    durs = [round(max(ns["MIN_DUR"][k] + 2, (b - a) + BREATH), 2) for k, (a, b) in zip(keys, segs)]
    json.dump({"audio": os.path.basename(mp3), "segments": segs, "durations": durs, "lead": 0.5}, open(TIMING, "w"), indent=1)
    print(f"{TIMING}: {len(segs)} trechos, vídeo de {sum(durs):.1f} s")

def mix(mp3, video, out):
    timing = json.load(open(TIMING))
    starts, t = [], 0.0
    for d in timing["durations"]:
        starts.append(t); t += d
    parts, labels = [], []
    for i, ((a, b), at) in enumerate(zip(timing["segments"], starts)):
        a, b = max(0, a - 0.05), b + 0.12
        d = b - a
        parts.append(f"[0:a]atrim={a:.2f}:{b:.2f},asetpts=PTS-STARTPTS,afade=t=in:d=0.03,afade=t=out:st={d - 0.08:.2f}:d=0.08,"
                     f"adelay={int((at + timing['lead']) * 1000)}:all=1[s{i}]")
        labels.append(f"[s{i}]")
    fc = ";".join(parts) + ";" + "".join(labels) + f"amix=inputs={len(labels)}:normalize=0,apad,atrim=0:{t:.2f},loudnorm=I=-16:TP=-1.5:LRA=11[out]"
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", mp3, "-i", video, "-filter_complex", fc, "-map", "1:v", "-map", "[out]",
                    "-c:v", "copy", "-c:a", "aac", "-b:a", "160k", "-ar", "48000", "-shortest", "-movflags", "+faststart", out], check=True)
    print("ok", out)

def load_scenes():
    ns = {"__file__": os.path.join(OUT, "youtube.py")}
    src = open(os.path.join(OUT, "youtube.py"), encoding="utf-8").read().split("timing_path =")[0]
    exec(compile(src, "youtube", "exec"), ns)
    return ns

def sentences(text):
    # Divide em frases sem quebrar "3.8" nem "Shift + clique".
    return [p.strip() for p in re.split(r"(?<=[.!?])\s+(?=[A-Z\u00c0-\u00dd])", text.strip()) if p.strip()]

def chunks(text, parts):
    # Divide uma frase em `parts` pedaços de tamanho parecido, cortando em vírgula ou espaço.
    out, rest = [], text
    for left in range(parts, 1, -1):
        target = len(rest) / left
        cut = min((i for i, c in enumerate(rest) if c in ", " and i > 0), key=lambda i: abs(i - target) - (8 if rest[i] == "," else 0))
        out.append(rest[:cut + 1].strip()); rest = rest[cut + 1:].strip()
    return out + [rest]

def wrap(text, width=42):
    # Até duas linhas por legenda.
    if len(text) <= width: return text
    best = min((i for i, c in enumerate(text) if c == " "), key=lambda i: abs(i - len(text) / 2))
    return text[:best] + "\n" + text[best + 1:]

def stamp(t):
    ms = int(round(t * 1000)); h, ms = divmod(ms, 3600000); m, ms = divmod(ms, 60000); sec, ms = divmod(ms, 1000)
    return f"{h:02d}:{m:02d}:{sec:02d},{ms:03d}"

def subs(mp3=None):
    ns = load_scenes()
    scenes, pt = ns["SCENES"], ns["NARRATION_PT"]
    timing = json.load(open(TIMING)) if os.path.exists(TIMING) else None
    if timing and len(timing["durations"]) != len(scenes): timing = None
    if timing:
        durs, segs, lead = timing["durations"], timing["segments"], timing["lead"]
    else:
        durs = [max(ns["MIN_DUR"][sc[0]], len(sc[1].split()) / 2.5 + 2) for sc in scenes]
        segs, lead = None, 0.5
    sil = silences(mp3) if (mp3 and segs) else []
    cues = {"en": [], "pt": []}
    t0 = 0.0
    for i, sc in enumerate(scenes):
        key, en_text = sc[0], sc[1]
        en, ptx = sentences(en_text), sentences(pt[key])
        assert len(en) == len(ptx), f"{key}: {len(en)} frases em inglês e {len(ptx)} em português"
        if segs:
            a, b = segs[i]
        else:
            a, b = 0.0, len(en_text.split()) / 2.6
        # Início de cada frase: pausas dentro do trecho (se o número bater) ou divisão pelo tamanho.
        inner = [(x, y) for x, y in sil if a + 0.2 < x < b - 0.2 and y - x >= 0.25]
        if len(inner) >= len(en) - 1 and len(en) > 1:
            inner = sorted(sorted(inner, key=lambda p: p[0] - p[1])[:len(en) - 1])
            bounds = [a] + [y for _, y in inner]; ends = [x for x, _ in inner] + [b]
        else:
            total = sum(len(x) for x in en); bounds, ends, pos = [], [], a
            for x in en:
                d = (b - a) * len(x) / total; bounds.append(pos); ends.append(pos + d); pos += d
        start = t0 + lead - a
        for s_en, s_pt, sa, sb in zip(en, ptx, bounds, ends):
            parts = max(1, -(-max(len(s_en), len(s_pt)) // 84))
            pe, pp = chunks(s_en, parts) if parts > 1 else [s_en], chunks(s_pt, parts) if parts > 1 else [s_pt]
            total = sum(len(x) for x in pe); pos = sa
            for ce, cp in zip(pe, pp):
                d = (sb - sa) * len(ce) / total
                cues["en"].append((start + pos, start + pos + d + 0.25, wrap(ce)))
                cues["pt"].append((start + pos, start + pos + d + 0.25, wrap(cp)))
                pos += d
        t0 += durs[i]
    for lang in cues:  # cada legenda termina antes da próxima começar
        c = cues[lang]
        for n in range(len(c) - 1):
            if c[n][1] > c[n + 1][0] - 0.05: c[n] = (c[n][0], c[n + 1][0] - 0.05, c[n][2])
    for lang, name in (("en", "farol-youtube.en.srt"), ("pt", "farol-youtube.pt-BR.srt")):
        lines = []
        for n, (a, b, text) in enumerate(cues[lang], 1):
            lines.append(f"{n}\n{stamp(a)} --> {stamp(b)}\n{text}\n")
        open(os.path.join(OUT, name), "w", encoding="utf-8").write("\n".join(lines))
        print("ok", name, len(cues[lang]), "legendas")

def piper(model, mp3):
    import io, wave
    from piper import PiperVoice, SynthesisConfig
    ns = load_scenes()
    voice = PiperVoice.load(model)
    cfg = SynthesisConfig(length_scale=1.06, noise_scale=0.6, noise_w_scale=0.7)
    rate = voice.config.sample_rate
    pcm, segs = bytearray(), []
    silence = lambda sec: b"\0\0" * int(rate * sec)
    def say(text):
        buf = io.BytesIO()
        with wave.open(buf, "wb") as w: voice.synthesize_wav(text, w, syn_config=cfg)
        buf.seek(0)
        with wave.open(buf) as r: return r.readframes(r.getnframes())
    for i, sc in enumerate(ns["SCENES"]):
        if i: pcm += silence(1.0)
        start = len(pcm) / 2 / rate
        for j, sentence in enumerate(sentences(sc[1])):
            if j: pcm += silence(0.45)
            pcm += say(sentence)
        segs.append([round(start, 2), round(len(pcm) / 2 / rate, 2)])
    pcm += silence(0.5)
    wav = mp3.rsplit(".", 1)[0] + ".wav"
    with wave.open(wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate); w.writeframes(bytes(pcm))
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", wav, "-c:a", "libmp3lame", "-b:a", "192k", mp3], check=True)
    durs = [round(max(ns["MIN_DUR"][sc[0]] + 2, (b - a) + BREATH), 2) for sc, (a, b) in zip(ns["SCENES"], segs)]
    json.dump({"audio": os.path.basename(mp3), "voice": os.path.basename(model), "segments": segs, "durations": durs, "lead": 0.5},
              open(TIMING, "w"), indent=1)
    print(f"{mp3}: {len(segs)} trechos; vídeo de {sum(durs):.1f} s")

if __name__ == "__main__":
    if sys.argv[1] == "prepare":
        prepare(sys.argv[2], [float(x) for x in sys.argv[3].split(",")])
    elif sys.argv[1] == "piper":
        piper(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "subs":
        subs(sys.argv[2] if len(sys.argv) > 2 else None)
    elif sys.argv[1] == "mix":
        mix(sys.argv[2], sys.argv[3], sys.argv[4])
