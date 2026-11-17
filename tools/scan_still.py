# scan_still.py VIDEO OUT: per frame m: n = pixels that differ from both neighbours (>18) while the neighbours agree (<8),
# still = mean|c-a| (camera motion measure). Blips in a still view: small 'still', n > 0.
import subprocess, sys, numpy as np

src, out = sys.argv[1:3]
W, H = 772, 360

p = subprocess.Popen(["ffmpeg", "-v", "fatal", "-nostdin", "-i", src, "-vf", f"scale={W}:{H}", "-fps_mode", "passthrough",
                      "-f", "rawvideo", "-pix_fmt", "gray", "-"], stdout=subprocess.PIPE)
a = m = None
i = 0
with open(out, "w") as o:
    while len(b := p.stdout.read(W * H)) == W * H:
        c = np.frombuffer(b, np.uint8).astype(np.int16).reshape(H, W)
        if a is not None:
            mask = (np.abs(m - a) > 18) & (np.abs(m - c) > 18) & (np.abs(c - a) < 8)
            n = int(mask.sum())
            still = float(np.abs(c - a).mean())
            bb = ""
            if n:
                ys, xs = np.nonzero(mask)
                bb = f"{xs.min()} {ys.min()} {xs.max()} {ys.max()}"
            o.write(f"{i - 1} {n} {still:.2f} {bb}\n")
        a, m = m, c
        i += 1
if p.wait() or i == 0:
    sys.exit(f"ffmpeg could not decode {src}")
