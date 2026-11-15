"""Narração do vídeo longo (YouTube).
  prepare <narração.mp3> <fim1,fim2,...,fim15>  → youtube_timing.json: trecho do áudio de cada cena (cortado nas
      pausas informadas, conferidas frase a frase) e a duração de cada cena (fala + respiro, nunca menos que o mínimo
      da animação). Depois rode youtube.py de novo e grave o vídeo.
  mix <narração.mp3> <vídeo.mp4> <saída.mp4>  → coloca cada trecho no início da sua cena (+0,5 s), volume -16 LUFS.
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
    keys = [k for k, _, _, _ in ns["SCENES"]]
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

if __name__ == "__main__":
    if sys.argv[1] == "prepare":
        prepare(sys.argv[2], [float(x) for x in sys.argv[3].split(",")])
    elif sys.argv[1] == "mix":
        mix(sys.argv[2], sys.argv[3], sys.argv[4])
