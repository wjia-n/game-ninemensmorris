#!/usr/bin/env python3
"""Nine Men's Morris audio — pure synthesis, ancient carved-stone identity.

Bronze tablets clink, stone tokens tok against sandstone, bone discs rattle
softly. Ambient music: low stone-drone with slow bronze-bell arpeggios,
museum-gallery reverence. 44.1kHz mono 16-bit WAV. No external assets.
"""
import math
import os
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   'assets', 'sounds')
os.makedirs(OUT, exist_ok=True)

rng = np.random.default_rng(1212)


def save(name, sig, gain=0.8):
    sig = np.clip(sig, -1, 1)
    sig = (sig * gain * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(sig.tobytes())
    print('wrote', name, f'{len(sig) / SR:.2f}s')


def adsr(n, a, d, s_level, r):
    e = np.ones(n)
    na = max(1, int(a * SR))
    nd = max(1, int(d * SR))
    nr = max(1, int(r * SR))
    e[:na] = np.linspace(0, 1, na)
    e[na:na + nd] = np.linspace(1, s_level, nd)
    e[n - nr:] *= np.linspace(1, 0, nr)
    return e


def tone(freq, dur, peak=0.7, attack=0.005, decay=None, sustain=0.6,
         release=None, harmonics=(1.0, 0.35, 0.12)):
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = np.zeros(n)
    for i, h in enumerate(harmonics):
        sig += h * np.sin(2 * math.pi * freq * (i + 1) * t)
    d = decay if decay is not None else max(0.01, dur * 0.2)
    r = release if release is not None else max(0.01, dur * 0.3)
    sig *= adsr(n, attack, d, sustain, r) * peak
    return sig


def metallic(freq, dur, peak=0.7):
    """Inharmonic bronze partials with fast attack and long metallic ring."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    partials = (1.0, 2.76, 5.40, 8.93)  # bar-like inharmonic series
    amps = (1.0, 0.45, 0.22, 0.10)
    sig = np.zeros(n)
    for k, (p, a) in enumerate(zip(partials, amps)):
        sig += a * np.sin(2 * math.pi * freq * p * t) * np.exp(-t * (3 + k * 4))
    snap = rng.standard_normal(n) * np.exp(-t * 400) * 0.4
    return (sig + snap) * peak


def stone_knock(freq, dur=0.13, peak=0.85, grit=0.5):
    """Low stone body + gritty contact snap."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    body = np.sin(2 * math.pi * freq * t) * np.exp(-t * 30)
    grit_n = rng.standard_normal(n) * np.exp(-t * 200) * grit
    return (body + grit_n) * peak


def seq(notes, note_dur, gap=0.0, peak=0.6, metallic_=False):
    total = int((note_dur + gap) * len(notes) * SR) + SR // 2
    sig = np.zeros(total)
    for i, f in enumerate(notes):
        t = metallic(f, note_dur, peak) if metallic_ else tone(f, note_dur, peak)
        s = int(i * (note_dur + gap) * SR)
        sig[s:s + len(t)] += t
    return sig


# --- UI / interaction -------------------------------------------------------
# click: bronze tablet press — bright clink with stone body
n = int(0.09 * SR)
t = np.arange(n) / SR
click = (metallic(2100, 0.09, 0.55)[:n]
         + stone_knock(220, 0.09, 0.35)[:n])
save('click.wav', click)

# select: light stone tap when lifting a token
save('select.wav', stone_knock(640, 0.10, 0.6, grit=0.35))

# place: stone token set onto sandstone — solid tok, slight grit tail
_p1 = stone_knock(180, 0.16, 0.95, grit=0.45)
_p2 = stone_knock(120, 0.22, 0.5, grit=0.3)
_n = max(len(_p1), len(_p2))
place = np.pad(_p1, (0, _n - len(_p1))) + np.pad(_p2, (0, _n - len(_p2)))
save('place.wav', place)

# move: bronze token sliding a short line — metallic scrape tick
n = int(0.14 * SR)
t = np.arange(n) / SR
scrape = (np.sin(2 * math.pi * 900 * t + 6 * np.sin(2 * math.pi * 60 * t))
          * np.exp(-t * 26) * 0.5)
move = scrape + stone_knock(300, 0.14, 0.4, grit=0.25)
save('move.wav', move)

# capture: bronze clink + stone grind of removal
cap = metallic(1450, 0.28, 0.8) + stone_knock(140, 0.28, 0.6, grit=0.6)
save('capture.wav', cap)

# mill: a mill is formed — triple bronze bell, reverent
save('mill.wav', seq([1046.5, 1318.5, 1568.0], 0.32, 0.06, peak=0.6,
                     metallic_=True))

# invalid: dull stone thud
save('invalid.wav', stone_knock(95, 0.20, 0.85, grit=0.25))

# fly: token lifted and set across the board — airy bronze shimmer
n = int(0.35 * SR)
t = np.arange(n) / SR
_shimmer = metallic(880, 0.3, 0.4)
_shimmer = np.pad(_shimmer, (0, n - len(_shimmer)))
fly = (np.sin(2 * math.pi * (1200 + 900 * t / n) * t) * np.exp(-t * 6) * 0.35
       + _shimmer)
save('fly.wav', fly)

# undo: soft backward stone tick
save('undo.wav', stone_knock(420, 0.12, 0.6, grit=0.3))

# --- Game events ------------------------------------------------------------
# game_start: solemn opening — deep stone drum + single bronze bell
_d1 = stone_knock(90, 0.5, 1.0, grit=0.4)
_d2 = metallic(660, 0.8, 0.55)
_n = max(len(_d1), len(_d2)) + int(0.3 * SR)
start = np.pad(_d1, (0, _n - len(_d1)))
_at = int(0.25 * SR)
start[_at:_at + len(_d2)] += _d2
save('game_start.wav', start)

# win: bronze fanfare — rising, triumphant, temple-like
save('win.wav', seq([392.0, 523.25, 659.25, 783.99, 1046.5, 1318.5],
                    0.22, 0.04, peak=0.62, metallic_=True))

# lose: somber descending phrase
save('lose.wav', seq([440.0, 392.0, 329.63, 261.63], 0.34, 0.06, peak=0.5))

# draw: neutral resolve — two balanced bells
save('draw.wav', seq([523.25, 523.25], 0.3, 0.18, peak=0.55, metallic_=True))


# --- Music loops ------------------------------------------------------------
def bell_chord(freqs, dur, peak=0.30):
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = np.zeros(n)
    for f in freqs:
        sig += (np.sin(2 * math.pi * f * t)
                + 0.45 * np.sin(2 * math.pi * f * 2.76 * t) * np.exp(-t * 1.2)
                + 0.18 * np.sin(2 * math.pi * f * 5.4 * t) * np.exp(-t * 2.0))
    sig /= max(1, len(freqs))
    a = int(0.5 * SR)
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    e[-a:] = np.linspace(1, 0, a)
    return sig * e * peak * 3.2


def drone(freq, dur, peak=0.16):
    """Deep stone drone bed."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    sig = (np.sin(2 * math.pi * freq * t)
           + 0.5 * np.sin(2 * math.pi * freq * 1.5 * t + 0.6)
           + 0.25 * np.sin(2 * math.pi * freq * 2.02 * t))
    a = int(0.8 * SR)
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    e[-a:] = np.linspace(1, 0, a)
    return sig * e * peak


def music_loop(chords, bar, name, drone_note):
    sig = np.concatenate([bell_chord(c, bar) for c in chords])
    sig += drone(drone_note, len(sig) / SR)
    xf = int(0.6 * SR)  # loop-safe crossfade
    sig[:xf] = sig[:xf] * np.linspace(0, 1, xf) + sig[-xf:] * np.linspace(1, 0, xf)
    save(name, sig, gain=0.9)


# Menu: slow, reverent — D minor-ish ancient voicings
music_loop(
    [[293.66, 349.23, 440.0], [261.63, 329.63, 392.0],
     [220.0, 261.63, 329.63], [293.66, 349.23, 440.0]],
    3.2, 'music_menu.wav', 73.42)

# Game: a touch more motion, still subdued
music_loop(
    [[220.0, 261.63, 329.63], [174.61, 220.0, 293.66],
     [196.0, 246.94, 293.66], [146.83, 174.61, 293.66],
     [220.0, 261.63, 329.63], [196.0, 246.94, 392.0]],
    2.6, 'music_game.wav', 65.41)

print('done ->', OUT)
