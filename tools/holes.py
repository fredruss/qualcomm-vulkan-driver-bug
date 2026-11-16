# holes.py VIDEO: counts the frames where the clear colour (neutral grey) shows in the lower half of the picture,
# where only grass, ground and characters should be. Needs no static camera and no neighbour frames.
import subprocess, sys, numpy as np

W, H = 772, 360
MIN_PIXELS = 5000  # above the frame's usual grey (the skeletons), about 4 % of the lower half

ffmpeg = subprocess.Popen(
    ["ffmpeg", "-v", "error", "-nostdin", "-i", sys.argv[1], "-vf", f"scale={W}:{H}",
     "-fps_mode", "passthrough", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], stdout=subprocess.PIPE)
counts = []
while frame := ffmpeg.stdout.read(W * H * 3):
    if len(frame) < W * H * 3:
        break
    r, g, b = np.frombuffer(frame, np.uint8).reshape(H, W, 3)[H // 2:].astype(int).transpose(2, 0, 1)
    counts.append(int(((abs(r - g) < 8) & (abs(g - b) < 8) & (r > 60) & (r < 130)).sum()))

counts = np.array(counts)
holes = np.nonzero(counts > np.median(counts) + MIN_PIXELS)[0]
print(f"frames {len(counts)}, hole frames {len(holes)} ({100 * len(holes) / len(counts):.2f} %)")
print("first:", " ".join(map(str, holes[:20])))
