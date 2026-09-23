// A tour of everything the cycler theme does. `just build` in this repo compiles it.
#import "@preview/touying:0.7.4": *
#import "@preview/cetz:0.4.2"
#import "@preview/tiaoma:0.3.0": qrcode
#import "../theme/cycler.typ": *

#set document(
  description: [A tour of the cycler Touying theme from typst-touying-template],
  keywords: ("Typst", "Touying", "slides", "presentation template", "cycler"),
)

#show: cycler-theme.with(
  aspect-ratio: "16-9",
  bibliography: bibliography(title: none, "refs.bib"),
  config-info(
    title: [cycler],
    subtitle: [A Typst slide template with batteries included],
    short-title: [cycler showcase],
    author: [typst-touying-template],
    institution: [github.com/nikosavola/typst-touying-template],
    date: datetime.today(),
  ),
)

#title-slide()

= Basics

== Text

- Bullets, with *highlights* in the primary color
  - Nested bullets get a dash
- `inline code` and #link("https://typst.app")[links]
- Inline math: $e^(i pi) + 1 = 0$

#speaker-note[Speaker notes live next to the slide and never show on it. Touying can put them on a second screen.]

== Step by step

- `#pause` reveals the next item on the next click
#pause
- Like this one
#pause
- The slide counter only advances once per slide, not per reveal

== Two columns

#slide(composer: (1fr, 1fr))[
  Pass `composer: (1fr, 1fr)` to `#slide` and give it one body per column.

  Column widths are any grid track sizes, like `(2fr, 1fr)`.
][
  #table(
    columns: 3,
    align: (left, right, right),
    table.header[*Deck*][*Slides*][*Minutes*],
    [Flash talk], [10], [8],
    [Meetup talk], [20], [20],
    [Lecture], [40], [45],
  )
]

= Components

== Callouts

#slide(composer: (1fr, 1fr))[
  #callout(title: [Note])[`callout()` defaults to the primary blue.]
  #v(0.5em)
  #callout(color: cycle.green, title: [Tip])[Pass any `cycle` color.]
][
  #callout(color: cycle.purple, title: [Aside])[The title is optional.]
  #v(0.5em)
  #callout(color: cycle.red, title: [Warning])[Keep it to one or two lines.]
]

== The color cycle

#let swatch(name, c) = stack(
  spacing: 0.4em,
  rect(width: 100%, height: 2.2em, radius: 2pt, fill: c),
  text(size: 0.7em, weight: "bold", raw("cycle." + name)),
  text(size: 0.6em, fill: cycle.grey, c.to-hex()),
)

#grid(
  columns: (1fr,) * 6,
  column-gutter: 0.8em,
  ..cycle.pairs().map(((name, c)) => swatch(name, c)),
)

#v(1em)

- The same six colors as the matplotlib style's `axes.prop_cycle`
- `cycle-color(n)` wraps around like matplotlib, and `stripe()` draws the whole palette:

#v(0.3em)
#stripe(height: 6pt)

== Plots with cetz

#align(center, cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let (w, h) = (16, 5.5)
  let xs = range(0, 201).map(i => i / 200 * 4 * calc.pi)
  let sx = w / (4 * calc.pi)
  let sy = h / 2.4
  line((0, 0), (w, 0), stroke: 1.2pt + black)
  line((0, 0), (0, h), stroke: 1.2pt + black)
  for (i, (label, f)) in (
    ([$sin x$], x => calc.sin(x)),
    ([$sin x dot e^(-x slash 8)$], x => calc.sin(x) * calc.exp(-x / 8)),
    ([$cos 2x slash 2$], x => calc.cos(2 * x) / 2),
  ).enumerate() {
    let c = cycle-color(i)
    line(..xs.map(x => (x * sx, h / 2 + f(x) * sy)), stroke: 1.8pt + c)
    line((w + 0.4, h - 0.6 - i * 0.7), (w + 1.1, h - 0.6 - i * 0.7), stroke: 1.8pt + c)
    content((w + 1.3, h - 0.6 - i * 0.7), anchor: "west", text(size: 14pt, label))
  }
}))

#align(center, text(
  size: 0.8em,
)[Drawn with cetz, using `cycle-color(0)`, `(1)` and `(2)` like a matplotlib figure.])

== Plots from matplotlib

#slide(composer: (1.6fr, 1fr))[
  #image("plots/resonance.svg", width: 100%)
][
  #set text(size: 0.85em)
  - `theme/cycler.mplstyle` matches the slides: colors, Roboto, Fira Math
  - Save as SVG, then `#image("plots/resonance.svg")`
  - `just plots` reruns every `plots/*.py` with `uv`
]

#speaker-note[The SVG keeps its text as real, selectable text and has a transparent background, so it fits any slide.]

== Tables

#align(center, table(
  columns: 3,
  align: (left, center, left),
  table.header[*Recipe*][*Needs*][*Output*],
  [`just build`], [Typst], [PDF in `build/`],
  [`just preview`], [Typst], [one PNG per slide],
  [`just build-pptx`], [uv], [PPTX, one image per slide],
))

#v(0.5em)

#align(center, text(
  size: 0.8em,
)[Booktabs-style rules come from the theme, so plain `#table` looks like this.])

== Code

```python
from cycler import cycler
import matplotlib.pyplot as plt

# The theme's six colors, as a matplotlib prop cycle
plt.rcParams["axes.prop_cycle"] = cycler(color=[
    "#008fd5", "#fc4f30", "#68dc9b", "#ffdf54", "#8b8b8b", "#810f7c",
])
```

== Math

$
  X(f) = integral_(-infinity)^(infinity) x(t) e^(-i 2 pi f t) dif t
$

#v(0.5em)

$
  mat(1, 2; 3, 4) vec(x, y) = vec(5, 6)
$

== Citations

- Built with Typst @typst and Touying @touying
- Colors borrowed from a matplotlib @hunter2007 style
- Each citation becomes a numbered footnote on its own slide

#speaker-note[Pass `bibliography: bibliography(title: none, "refs.bib")` to the theme, then cite with `@key`.]

== Links and QR codes

#slide(composer: (1.4fr, 1fr))[
  - `tiaoma` draws QR codes as vectors
  - Handy on the last slide, so people can find the repo

  #v(0.4em)
  #text(size: 0.8em, link("https://github.com/nikosavola/typst-touying-template"))
][
  #align(center + horizon, qrcode(
    "https://github.com/nikosavola/typst-touying-template",
    width: 6cm,
  ))
]

#focus-slide[One idea per slide, and *one* highlight.]
