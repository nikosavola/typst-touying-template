// A tour of everything the cycler theme does. `just build` in this repo compiles it.
#import "@preview/touying:0.7.4": *
#import "@preview/cetz:0.4.2"
#import "@preview/tiaoma:0.3.0": qrcode
#import "../theme/cycler.typ": *

#set document(
  description: [A tour of the cycler Touying theme from typst-touying-template],
  keywords: ("Typst", "Touying", "slides", "presentation template", "cycler"),
)

// A placeholder logo: swap in `image("logo.svg", height: 1.5em)`.
#let logo = grid(
  columns: 3,
  gutter: 2pt,
  ..cycle.values().map(c => rect(width: 0.55em, height: 0.55em, radius: 1pt, fill: c)),
)

#show: cycler-theme.with(
  aspect-ratio: "16-9",
  bibliography: bibliography(title: none, "refs.bib"),
  config-info(
    title: [cycler],
    subtitle: [A Typst slide template with batteries included],
    short-title: [cycler showcase],
    author: [Ada Lovelace],
    institution: [Analytical Engine Society],
    date: datetime.today(),
    logo: logo,
  ),
)

#title-slide()

== Outline <touying:hidden>

#align(horizon, block(width: 70%, section-outline()))

= Basics

== Text

- Bullets, with *highlights* in the primary color
  - Nested bullets get a dash
- `inline code` and #link("https://typst.app")[links]
- Inline math: $e^(i pi) + 1 = 0$
- `#speaker-note[...]` holds notes that never show on the slide

#speaker-note[Like this one. Set `config-common(show-notes-on-second-screen: right)` to get them next to each slide, for pdfpc or a presenter view.]

== Typography and quotes

#slide(composer: (1fr, 1fr))[
  === A level 3 heading
  Body text in Roboto, with *bold*, _italic_ and `code`.

  #small[`small[...]` for dense bullets under a figure.] \
  #fine[`fine[...]` for sources and caveats.]
][
  #quote(block: true, attribution: [Ada Lovelace])[
    The Analytical Engine weaves algebraical patterns just as the Jacquard loom weaves flowers // codespell:ignore
    and leaves.
  ]
]

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
  #callout(title: [Note], icon: "i")[`callout()` defaults to the primary blue.]
  #v(0.5em)
  #callout(color: cycle.green, title: [Tip], icon: "?")[Pass any `cycle` color.]
][
  #callout(color: cycle.purple, title: [Aside])[The title and `icon` are optional.]
  #v(0.5em)
  #callout(color: cycle.red, title: [Warning], icon: "!")[Keep it to one or two lines.]
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

= Figures

== Plots with cetz

#fig(width: 85%, cetz.canvas(length: 1cm, {
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
)[Drawn with cetz in `cycle-color(0)`, `(1)` and `(2)`, and scaled to 85% of the width by `fig(canvas, width: 85%)`.])

== Plots from matplotlib

#slide(composer: (1.6fr, 1fr))[
  #fig(
    "/example/plots/resonance.svg",
    width: 100%,
    alt: "Resonance curves of |S21| against frequency for Q of 10, 30 and 100",
    caption: [`fig(path, caption: ...)` centers it.],
  )
][
  #set text(size: 0.85em)
  - `theme/cycler.mplstyle` matches the slides: colors, Roboto, Fira Math
  - Save as SVG, then `#fig("/plots/resonance.svg", alt: "...")`
  - `just plots` reruns every `plots/*.py` with `uv`
]

#speaker-note[The SVG keeps its text as real, selectable text and has a transparent background, so it fits any slide.]

== Long slide titles shrink and wrap to fit the header, so a research deck can state its result as the title

#slide(composer: (1.6fr, 1fr))[
  #fig-fill(
    "/example/plots/resonance.svg",
    explain: [Transmission of a resonator against frequency, for #key(cycle.blue)[$Q = 10$], #key(cycle.red)[$Q = 30$] and #key(cycle.green)[$Q = 100$]. `fig-fill` sizes the plot to the room left above this `note`, and `key` marks each color.],
  )
][
  #compare(
    ([Usual], [Quote $Q$ from the width at half power.]),
    ([Here], [Fit the whole line shape, so the tails count too.]),
  )
  #v(0.6em)
  #small[
    - `compare` takes label and content pairs
    - The last row is highlighted
  ]
]

== Diagrams from Mermaid

#slide(composer: (1fr, 1.3fr))[
  ```text
  flowchart LR
    P[plots/*.py] --> S[SVG]
    S --> M[main.typ]
    M --> T{typst}
    T --> PDF
    T --> Pages
  ```
  #text(
    size: 0.8em,
  )[Put it in a `mermaid` code block, or pass it to `mermaid("...")`. Either way it renders in the theme's colors and font.]
][
  ```mermaid
  flowchart LR
    P[plots/*.py] --> S[SVG]
    S --> M[main.typ]
    M --> T{typst}
    T --> PDF
    T --> Pages
  ```
]

#speaker-note[merman renders Mermaid inside Typst itself, so there's no browser or Node.js in the build.]

== A full-bleed image

#image-slide(image("media/aurora.jpg"))[
  `image-slide(image("photo.jpg"))[...]` #h(1fr) #text(size: 0.5em, weight: "regular")[Photo: Vincent Guth, CC0]
]

= Code and data

== Tables

#align(center, table(
  columns: 3,
  align: (left, center, right),
  table.header[*Recipe*][*Needs*][*Output*],
  [`just build`], [Typst], [PDF in `build/`],
  [`just preview`], [Typst], [one PNG per slide],
  [`just build-pptx`], [uv], [PPTX, one image per slide],
))

#v(0.5em)

#align(center, text(
  size: 0.8em,
)[Booktabs-style rules come from the theme, so plain `#table` looks like this. Columns align left, center and right.])

== Code and its output

#slide(composer: (1.2fr, 1fr))[
  ```typ
  #callout(
    color: cycle.green,
    title: [Tip],
    icon: "i",
  )[Pass any `cycle` color.]
  ```
  #text(size: 0.8em)[Raw blocks get syntax highlighting for any language Typst knows.]
][
  #v(1fr)
  #callout(color: cycle.green, title: [Tip], icon: "i")[Pass any `cycle` color.]
  #v(1fr)
]

== Numbers from a data file

#let num = values(json("/example/data/results.json"))

#slide(composer: (1fr, 1fr))[
  The fit gives $Q = #num("q_fit") plus.minus #num("q_err")$ at $f_0 = #num("f0_ghz")$ GHz, from $#num("n_points")$ points.

  #v(0.6em)
  #small[
    - A script writes the numbers once, to `data/results.json`
    - The slides and a paper read the same file, so they always agree
    - A missing key stops the build instead of showing a stale number
  ]
][
  ```typ
  #let num = values(
    json("/data/results.json"),
  )
  $Q = #num("q_fit")$
  ```
]

== Math

#slide(composer: (1fr, 1fr))[
  $ X(f) = integral_(-infinity)^(infinity) x(t) e^(-i 2 pi f t) dif t $
  #v(0.5em)
  $ mat(1, 2; 3, 4) vec(x, y) = vec(5, 6) $
][
  #set text(size: 0.9em)
  Heisenberg equation of motion
  $ dif / (dif t) A_H (t) = i / ℏ [H, A_H (t)] + ((partial A) / (partial t))_H $
  and the uncertainty it leads to
  $ sigma_x sigma_p >= ℏ / 2 $
]

== Quantum field theory

#set math.equation(numbering: "(1)")

The generating functional of $phi^4$ theory,
$
  Z[J] = integral cal(D) phi exp(
    i integral dif^4 x [1 / 2 partial_mu phi partial^mu phi - 1 / 2 m^2 phi^2 - lambda / 4! phi^4 + J phi]
  ),
$
and the Standard Model Lagrangian, with $D_mu = partial_mu - i g_s G_mu^a T^a - i g W_mu^b tau^b / 2 - i g' Y B_mu$,
$
  cal(L)_"SM" = & - 1 / 4 F_(mu nu)^a F^(a mu nu) + i macron(psi) gamma^mu D_mu psi \
  & quad + (D_mu Phi)^dagger (D^mu Phi) - mu^2 Phi^dagger Phi - lambda (Phi^dagger Phi)^2 \
  & quad - (y_(i j) macron(psi)_(L i) Phi psi_(R j) + "h.c.") .
$

#set math.equation(numbering: none)

= Research talks

== Dense text fits the space it is given

#slide(align: top, composer: (1fr, 1fr))[
  #fig-fill("/example/plots/resonance.svg", alt: "Resonance curves for Q of 10, 30 and 100")
][
  #fit[
    - `fit[...]` shrinks the text inside it just enough to fit the height the slide has left,
      instead of a hand-tuned `text(size: 0.6em)`
    - It never grows text, and it stops at `min: 50%`, so a slide that is far too full still
      shows that it is
    - Math scales with it: $Q^(-1) = Q_"i"^(-1) + Q_"c"^(-1)$
    - Give it `height:` to fill a fixed box instead, or `align: top` to pin the text up
    - Here the figure on the left takes the column height with `fig-fill`, and these
      bullets take whatever size fits next to it. Add a bullet and they shrink, remove one and they
      grow back to full size
    - This slide has one bullet too many for full size, so the text here is a little smaller than
      on the other slides
  ]
]

== Big numbers

#cols(
  stat[1842][Menabrea's paper on the engine],
  stat(color: cycle.red)[1843][the translation, with notes],
  stat(color: cycle.green)[7][notes, A to G, longer than the paper],
)

#v(1.2em)

- `stat(value, label, color:)` for the one result a slide is about
- `cols(..)` from Touying sets any blocks side by side in equal columns, or pass `columns: (2fr, 1fr)`

== A plan

#timeline(
  ([Outline], [done], cycle.grey),
  ([Draft the slides], [this week]),
  ([Rehearse], [twice, with a timer]),
  ([Give the talk], [at the society]),
)

#v(1.5em)

- `timeline((title, detail), ..)` draws the steps on a line in the cycle colors
- A third entry sets the color, like `cycle.grey` for steps that are done
- Plain Typst, so it needs no cetz canvas and no `scale` to fit

= Wrap-up

== Citations

- Built with Typst @typst and Touying @touying
- Colors borrowed from a matplotlib @hunter2007 style
- Each citation becomes a numbered footnote on its own slide

#speaker-note[Pass `bibliography: bibliography(title: none, "refs.bib")` to the theme, then cite with `@key`.]

== Get the template

#slide(composer: (1.4fr, 1fr))[
  - `uvx copier copy gh:nikosavola/typst-touying-template my-talk`
  - The QR code is drawn as vectors by `tiaoma`

  #v(0.6em)
  #link(
    "https://github.com/nikosavola/typst-touying-template",
  )[github.com/nikosavola/typst-touying-template]
][
  #align(center + horizon, qrcode(
    "https://github.com/nikosavola/typst-touying-template",
    width: 6cm,
  ))
]

#focus-slide[One idea per slide, and *one* highlight.]
