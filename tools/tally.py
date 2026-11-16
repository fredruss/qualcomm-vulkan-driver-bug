# tally.py SCAN_FILE: counts the fault frames in a scan_still.py output (static camera only).
# small = 300 < n < 20000 (n < 600 is the noise class), giant = n >= 20000, in frames with still < 1.5.
import sys
still = small = real = giant = 0
for line in open(sys.argv[1]):
    f = line.split()
    n, s = int(f[1]), float(f[2])
    if s >= 1.5: continue
    still += 1
    if n >= 20000: giant += 1; print("giant", f[0], n)
    elif n > 300:
        small += 1
        if n > 600: real += 1; print("small", f[0], n)
print(f"still frames {still}, small {small} ({real} with n > 600), giant {giant}")
