# /// script
# requires-python = ">=3.12"
# dependencies = ["matplotlib>=3.10", "numpy>=2"]
# ///
"""Resonance curves for the showcase deck, drawn in the theme's matplotlib style."""

import logging
from pathlib import Path

from matplotlib import font_manager
import matplotlib.pyplot as plt
import numpy as np

# Fira Math ships Regular only, so bold math just falls back to it; the warning is noise.
logging.getLogger("matplotlib.font_manager").addFilter(
    lambda record: "Failed to find font weight" not in record.msg
)

root = next(p for p in Path(__file__).resolve().parents if (p / "theme" / "cycler.mplstyle").exists())
for pattern in ("*.otf", "*.ttf"):
    for font in (root / "fonts").glob(pattern):
        font_manager.fontManager.addfont(font)
plt.style.use(root / "theme" / "cycler.mplstyle")

f = np.linspace(0.8, 1.2, 1000)
fig, ax = plt.subplots()
for q in (10, 30, 100):
    ax.plot(f, 1 / np.sqrt(1 + (2 * q * (f - 1)) ** 2), label=f"$Q = {q}$")
ax.set_xlabel(r"Frequency $f / f_0$")
ax.set_ylabel(r"$|S_{21}|$")
ax.legend()
fig.savefig(Path(__file__).with_suffix(".svg"), metadata={"Date": None})
