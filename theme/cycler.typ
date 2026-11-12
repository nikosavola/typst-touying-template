// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Niko Savola, https://github.com/nikosavola/typst-touying-template
// cycler: a Touying theme built around the modified fivethirtyeight matplotlib prop cycle.
#import "@preview/touying:0.7.4": *
#import "@preview/merman:0.3.0"

// Based on matplotlib's fivethirtyeight style:
// https://matplotlib.org/stable/gallery/style_sheets/fivethirtyeight.html
// Slots 3 and 4 (gold e5ae38, green 6d904f) are swapped for a brighter green 68dc9b and yellow ffdf54.
/// The six-color cycle, in matplotlib's `axes.prop_cycle` order.
#let cycle = (
  blue: rgb("#008fd5"),
  red: rgb("#fc4f30"),
  green: rgb("#68dc9b"),
  yellow: rgb("#ffdf54"),
  grey: rgb("#8b8b8b"),
  purple: rgb("#810f7c"),
)

/// Color `n` of the cycle, wrapping around like matplotlib does.
#let cycle-color(n) = cycle.values().at(calc.rem(n, cycle.len()))

/// WCAG relative luminance of a color, 0 for black and 1 for white.
#let luminance(c) = {
  let (r, g, b, _) = c.rgb().components().map(x => x / 100%)
  let lin(v) = if v <= 0.04045 { v / 12.92 } else { calc.pow((v + 0.055) / 1.055, 2.4) }
  0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
}

/// `c` darkened until text in it reads on white at 4.5:1 or better. Yellow and green need far more
/// darkening than blue or red, so a fixed `darken` either washes them out or muddies the rest.
#let ink(c) = {
  let out = c
  while luminance(out) > 0.18 { out = out.darken(8%) }
  out
}

/// A horizontal stripe with one segment per cycle color, for decks that want the full palette.
#let stripe(height: 4pt) = grid(
  columns: (1fr,) * cycle.len(),
  rows: height,
  ..cycle.values().map(c => rect(width: 100%, height: 100%, fill: c, stroke: none)),
)

/// Slightly smaller text, for dense bullets under a figure.
#let small(body) = text(size: 0.8em, body)

/// Grey fine print: sources, caveats, what a plot shows. The grey is darkened with `ink`, since
/// plain `cycle.grey` is too faint for text this small.
#let fine(body) = text(size: 0.62em, fill: ink(cycle.grey), body)

// A length, ratio or relative length, resolved against `full`; none for auto. Needs context.
#let _resolve(x, full) = if x == auto { none } else if type(x) == ratio { x * full } else if (
  type(x) == relative
) { x.ratio * full + x.length.to-absolute() } else { x.to-absolute() }

// The factor that scales a `have`-sized box to the largest size within `width` by `height`,
// either of which may be none for no limit.
#let _contain-factor(have, width, height) = {
  let factors = ((width, have.width), (height, have.height))
    .filter(((limit, n)) => limit != none and n > 0pt)
    .map(((limit, n)) => limit / n)
  if factors.len() == 0 { 1 } else { calc.min(..factors) }
}

/// A centered figure with optional fine print below. `src` is a path string, an `image(...)`, or
/// any content, like a cetz canvas. A string resolves from this file, so give it from the project
/// root, like "/figures/plot.svg"; extra named arguments such as `width` and `alt` go to `image`.
/// For content, `width` and `height` scale it to fit, in place of `scale(85%, reflow: true, ..)`.
/// To fill the rest of a slide, use `fig-fill`.
#let fig(src, caption: none, ..args) = {
  let width = args.named().at("width", default: auto)
  let height = args.named().at("height", default: auto)
  std.align(center, {
    if type(src) == str { image(src, ..args) } else if width == auto and height == auto {
      src
    } else {
      layout(size => scale(
        _contain-factor(measure(src), _resolve(width, size.width), _resolve(height, size.height))
          * 100%,
        reflow: true,
        src,
      ))
    }
    if caption != none { block(above: 0.4em, fine(caption)) }
  })
}

/// `body` with its text shrunk just enough to fit the height the slide has left, in place of
/// hand-tuned `text(size: 0.6em)[..]`. Text never grows, and stops shrinking at `min`. Pass a
/// `height` to fit a fixed box instead, and `align` to place the body in the leftover space. Too
/// full even at `min`, it runs past its box and gets a red badge, or stops the build under
/// `--input overflow=error` like an overflowing slide; only `--input`, not the theme's `overflow`
/// option, turns the badge off. Keep `#pause` outside it, since Touying can't see into a `layout`.
#let fit(body, height: 1fr, min: 50%, align: horizon) = block(width: 100%, height: height, layout(
  size => {
    let scales = range(100, int(min / 1%) - 1, step: -4).map(x => x * 1%)
    let fits(s) = measure(block(width: size.width, text(size: s * 1em, body))).height <= size.height
    let pick = scales.find(fits)
    if pick != none {
      std.align(align, text(size: pick * 1em, body))
    } else {
      let mode = sys.inputs.at("overflow", default: "mark")
      if mode == "error" { panic("a fit block is too full even at its min size") }
      std.align(top, text(size: scales.last() * 1em, body))
      if mode != "none" {
        place(top + right, box(fill: cycle.red, inset: (x: 0.6em, y: 0.35em), radius: 3pt, text(
          size: 12pt,
          weight: "bold",
          fill: white,
        )[Too full to fit]))
      }
    }
  },
))

/// A grey panel of small text under a figure, saying what is plotted. `label` leads in bold;
/// pass `none` to drop it.
#let note(label: [What is plotted.], body) = block(
  width: 100%,
  inset: (x: 0.6em, y: 0.45em),
  radius: 3pt,
  fill: luma(244),
  text(size: 0.68em, if label == none { body } else [*#label* #body]),
)

/// A small color mark that names a plot element in running text, like `#key(cycle.red)[$Q = 30$]`
/// in a `note`. `shape` is "line" for a curve, "dot" for markers or "band" for a shaded region.
#let key(color, shape: "line", body) = {
  assert(shape in ("line", "dot", "band"), message: "key shape must be line, dot or band")
  let mark = if shape == "line" {
    box(width: 1.1em, height: 0.7em, align(horizon, line(length: 100%, stroke: 2.5pt + color)))
  } else if shape == "dot" {
    box(width: 0.7em, height: 0.7em, align(center + horizon, circle(radius: 0.3em, fill: color)))
  } else {
    box(width: 0.9em, height: 0.7em, fill: color.transparentize(45%), radius: 1.5pt)
  }
  box[#mark#h(0.3em)#body]
}

/// A figure as large as the space left below it allows, so no `height` has to be tuned by hand.
/// It fills the rest of its column or slide, keeps its aspect ratio, and stays centered. `src` is a
/// path, given from the project root like in `fig`. `explain` goes in a `note` panel under it and
/// `caption` in fine print. Anything placed after it on the slide gets no room.
#let fig-fill(src, caption: none, explain: none, label: [What is plotted.], gap: 0.5em) = block(
  height: 1fr,
  width: 100%,
  layout(size => {
    let below = {
      if caption != none { block(above: 0.4em, fine(caption)) }
      if explain != none { block(above: gap, note(label: label, explain)) }
    }
    let room = size.height - measure(block(width: size.width, below)).height
    let natural = measure(image(src, width: size.width)).height
    align(center, image(src, height: calc.max(calc.min(natural, room), 0pt)))
    below
  }),
)

/// Numbers kept in a data file, like the results a paper is built from, so the slides never fall
/// out of step with it. `data` is a dictionary such as `json("/paper/numbers.json")` whose values
/// are strings in math syntax ("3.1", "1.2 times 10^3") or plain numbers. Returns a function that
/// gives one value as math by its key, for use inside `$..$`. A missing key stops the build.
/// Don't name the result `v`, which would hide Typst's own `v()` spacing.
#let values(data) = key => {
  assert(key in data, message: "no value named " + repr(key) + " in the data")
  let value = data.at(key)
  eval(if type(value) == str { value } else { str(value) }, mode: "math")
}

/// Labelled rows that set one approach against another, like "usual" practice and "this work".
/// Pass pairs of label and content. The last row is drawn in the primary color, the rest in grey.
#let compare(..rows) = {
  let rows = rows.pos()
  let n = rows.len()
  text(size: 0.75em, grid(
    columns: (auto, 1fr),
    column-gutter: 0.6em,
    row-gutter: 0.5em,
    align: top,
    ..rows
      .enumerate()
      .map(((i, (label, body))) => {
        let last = i == n - 1
        (
          text(weight: "bold", fill: if last { cycle.blue } else { ink(cycle.grey) }, label),
          if last { body } else { text(fill: ink(cycle.grey), body) },
        )
      })
      .flatten(),
  ))
}

/// A big number with a short label under it, for the one result a slide is about. `color` is
/// darkened with `ink`, so any cycle color reads. Put several side by side with `cols`. Math in
/// `value` stays regular weight, since Fira Math has no bold.
#let stat(value, label, color: cycle.blue, size: 2.4em) = block(breakable: false, {
  set par(leading: 0.4em)
  block(below: 0.35em, text(size: size, weight: "black", fill: ink(color), value))
  text(size: 0.75em, fill: rgb("#4d4d4d"), label)
})

/// Steps along a line, each a dot with a title above and a detail below, for a plan or a history.
/// Pass `(title, detail)` pairs, or `(title, detail, color)` to override the cycle color, e.g.
/// `cycle.grey` for steps already done.
#let timeline(..steps) = {
  let steps = steps.pos()
  let n = steps.len()
  let color(i) = steps.at(i).at(2, default: cycle-color(i))
  let track = cycle.grey.lighten(50%)
  grid(
    columns: (1fr,) * n,
    row-gutter: 0.45em,
    align: center + bottom,
    inset: (x: 0.4em),
    ..range(n).map(i => text(size: 0.8em, weight: "bold", fill: ink(color(i)), steps.at(i).at(0))),
    ..range(n).map(i => grid.cell(inset: 0pt, box(width: 100%, height: 0.7em, {
      // The line runs from the first dot to the last, under the dots.
      place(horizon, line(
        start: (if i == 0 { 50% } else { 0% }, 0pt),
        end: (if i == n - 1 { 50% } else { 100% }, 0pt),
        stroke: 2pt + track,
      ))
      std.align(center + horizon, circle(radius: 0.35em, fill: color(i), stroke: 2pt + white))
    }))),
    ..range(n).map(i => grid.cell(align: center + top, text(
      size: 0.7em,
      fill: rgb("#4d4d4d"),
      steps.at(i).at(1),
    ))),
  )
}

/// A tinted box with a colored left rule, for asides and warnings. `icon` is any content, or a
/// short string like "i" or "!" that gets drawn as a round badge, so no icon font is needed.
#let callout(color: cycle.blue, title: none, icon: none, body) = block(
  width: 100%,
  inset: (x: 0.9em, y: 0.7em),
  fill: color.transparentize(88%),
  stroke: (left: 3pt + color),
  {
    let badge = if type(icon) == str {
      circle(radius: 0.6em, fill: ink(color), stroke: none, align(
        center + horizon,
        text(size: 0.8em, weight: "black", fill: white, icon),
      ))
    } else { icon }
    let heading = text(weight: "bold", fill: ink(color), title)
    if badge != none {
      // A grid rather than inline, so the badge centers on the title instead of its baseline.
      block(below: 0.5em, grid(
        columns: 2,
        column-gutter: 0.45em,
        align: horizon,
        badge, heading,
      ))
    } else if title != none {
      block(below: 0.5em, heading)
    }
    body
  },
)

/// merman settings that draw Mermaid diagrams in the cycle colors instead of Mermaid's default purple.
#let mermaid-profile = merman.mermaid-profile(
  theme-name: "base",
  background: "transparent",
  theme: (
    primaryColor: cycle.blue.lighten(88%).to-hex(),
    primaryBorderColor: cycle.blue.to-hex(),
    primaryTextColor: "#1a1a1a",
    secondaryColor: cycle.red.lighten(85%).to-hex(),
    tertiaryColor: cycle.green.lighten(80%).to-hex(),
    lineColor: "#4d4d4d",
    // Sequence diagrams and pie charts don't derive these from the ones above.
    actorBkg: cycle.blue.lighten(88%).to-hex(),
    actorBorder: cycle.blue.to-hex(),
    actorLineColor: "#8b8b8b",
    signalColor: "#4d4d4d",
    noteBkgColor: cycle.yellow.lighten(70%).to-hex(),
    noteBorderColor: cycle.yellow.darken(20%).to-hex(),
    pieStrokeColor: "#ffffff",
    pieOuterStrokeColor: "#ffffff",
    ..cycle.values().enumerate().map(((i, c)) => ("pie" + str(i + 1), c.to-hex())).to-dict(),
  ),
)

/// A Mermaid diagram in the deck's colors and font. `mermaid` code blocks render the same way.
#let mermaid(source, ..args) = merman.mermaid(
  source,
  profile: mermaid-profile,
  document-context: true,
  ..args,
)

/// Marks the first page of a slide. A page without one holds content that spilled over from the
/// slide before it, which Touying puts on an extra page instead of cutting it off.
#let slide-start = [#metadata("cycler-slide") <cycler-slide>]

// Pages that start no slide, i.e. overflow pages. Needs context.
#let overflow-pages() = {
  let starts = query(<cycler-slide>).map(m => m.location().page())
  range(1, here().page() + 1).filter(p => p not in starts)
}

#let overflow-badge = place(top + center, dy: 1em, box(
  fill: cycle.red,
  inset: (x: 0.6em, y: 0.35em),
  radius: 3pt,
  text(size: 12pt, weight: "bold", fill: white)[Overflow: this continues the slide before],
))

/// `body` at the largest of a few text sizes, 100% down to 60%, that keeps it within `height`
/// at the available width, bottom-aligned in a box of that height.
#let _shrink-to-height(body, height) = layout(size => {
  let scales = (100%, 92%, 85%, 78%, 72%, 66%, 60%)
  let fits(s) = measure(block(width: size.width, text(size: s * 1em, body))).height <= height
  let pick = scales.find(fits)
  box(height: height, std.align(bottom, text(
    size: (if pick == none { scales.last() } else { pick }) * 1em,
    body,
  )))
})

/// `body` at the largest of a few text sizes, 100% down to 60%, that wraps to at most `lines`
/// lines at the available width.
#let _shrink-to-lines(body, lines) = layout(size => {
  let scales = (100%, 92%, 85%, 78%, 72%, 66%, 60%)
  let fits(s) = {
    let limit = measure(text(size: s * 1em, (([Ag],) * lines).join(linebreak()))).height
    (
      measure(block(width: size.width, text(size: s * 1em, body))).height
        <= limit + 0.2 * s * 1em.to-absolute()
    )
  }
  let pick = scales.find(fits)
  text(size: (if pick == none { scales.last() } else { pick }) * 1em, body)
})

#let slide(
  title: auto,
  align: auto,
  config: (:),
  repeat: auto,
  setting: body => body,
  composer: auto,
  ..bodies,
) = touying-slide-wrapper(self => {
  if align != auto {
    self.store.align = align
  }
  let header(self) = {
    set std.align(top)
    pad(x: 2em, top: 0.25em, {
      set text(fill: self.colors.neutral-darkest, weight: "bold", size: 1.25em)
      set par(leading: 0.4em)
      // A one-line title sits where it always has. A long one shrinks and wraps upwards into the
      // top padding instead of running into the slide body.
      let lift = 0.68em
      grid(
        columns: (1fr, auto),
        column-gutter: 1em,
        context _shrink-to-height(
          if title != auto { title } else { utils.call-or-display(self, self.store.header) },
          lift.to-absolute() + measure[Ag].height,
        ),
        pad(top: lift, text(
          size: 0.55em,
          weight: "regular",
          fill: self.colors.neutral,
          utils.call-or-display(self, self.store.header-right),
        )),
      )
      v(-0.5em)
      box(width: 2.5em, height: 3pt, fill: self.colors.primary)
    })
  }
  let footer(self) = {
    set std.align(bottom)
    set text(size: 0.6em, fill: self.colors.neutral)
    pad(x: 2em, bottom: 0.8em, components.left-and-right(
      utils.call-or-display(self, self.store.footer),
      utils.call-or-display(self, self.store.footer-right),
    ))
    if self.store.progress-bar {
      place(bottom, components.progress-bar(
        height: 3pt,
        self.colors.primary,
        self.colors.neutral-lighter,
      ))
    }
  }
  self = utils.merge-dicts(
    self,
    config-page(fill: self.colors.neutral-lightest, header: header, footer: footer),
  )
  let new-setting = body => {
    show: std.align.with(self.store.align)
    set text(fill: self.colors.neutral-darkest)
    show: setting
    slide-start
    body
  }
  touying-slide(
    self: self,
    config: config,
    repeat: repeat,
    setting: new-setting,
    composer: composer,
    ..bodies,
  )
})

/// Title slide, filled from `config-info`. Named arguments override the info fields.
#let title-slide(config: (:), extra: none, ..args) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config-common(freeze-slide-counter: true),
    config-page(fill: self.colors.neutral-lightest, margin: (x: 3em, y: 2.5em)),
    config,
  )
  let info = self.info + args.named()
  let body = {
    slide-start
    set std.align(horizon)
    set text(fill: self.colors.neutral-darkest)
    if info.logo != none {
      place(top + right, info.logo)
    }
    // Shrunk past three lines, so a full-sentence title still leaves room for the rest.
    block(width: 85%, text(size: 2em, weight: "bold", _shrink-to-lines(info.title, 3)))
    if info.subtitle != none {
      block(above: 0.6em, text(size: 1.1em, fill: self.colors.neutral-dark, info.subtitle))
    }
    v(0.8em)
    block(width: 100%, height: 4pt, fill: self.colors.primary)
    v(0.8em)
    set text(size: 0.8em, fill: self.colors.neutral-dark)
    if info.author != none {
      block(spacing: 0.6em, text(weight: "medium", info.author))
    }
    if info.institution != none {
      block(spacing: 0.6em, info.institution)
    }
    if info.date != none {
      block(spacing: 0.6em, utils.display-info-date(self))
    }
    if extra != none {
      block(spacing: 0.6em, extra)
    }
  }
  touying-slide(self: self, body)
})

/// Section divider with a large section number that steps through the cycle.
#let new-section-slide(config: (:), level: 1, body) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config-page(fill: self.colors.neutral-lightest, margin: (x: 3em)),
  )
  let slide-body = {
    slide-start
    set std.align(horizon)
    // Touying's own heading counter isn't stepped yet at this point, so count instead.
    context {
      let n = query(heading.where(level: 1).before(here())).len()
      let color = cycle-color(n - 1)
      text(size: 3.5em, weight: "black", fill: color, str(n))
      v(-0.8em)
      text(
        size: 1.8em,
        weight: "bold",
        fill: self.colors.neutral-darkest,
        utils.display-current-heading(level: level, numbered: false),
      )
      v(0.4em)
      block(width: 40%, height: 4pt, fill: color)
    }
    text(fill: self.colors.neutral-dark, body)
  }
  touying-slide(self: self, config: config, slide-body)
})

/// The deck's sections as numbered, linked rows in their cycle colors, like the section slides.
#let section-outline() = context {
  let sections = query(heading.where(level: 1))
  grid(
    columns: (auto, 1fr, auto),
    column-gutter: 0.9em,
    inset: (y: 0.35em),
    align: (right + horizon, left + horizon, right + horizon),
    ..sections
      .enumerate()
      .map(((i, h)) => {
        let c = cycle-color(i)
        (
          text(size: 1.7em, weight: "black", fill: c, str(i + 1)),
          link(h.location(), text(size: 1.3em, weight: "bold", fill: rgb("#1a1a1a"), h.body)),
          text(size: 0.8em, fill: cycle.grey, str(
            utils.slide-counter.at(h.location()).first() + 1,
          )),
          grid.hline(stroke: 0.5pt + rgb("#e6e6e6")),
        )
      })
      .flatten(),
  )
}

/// Full-bleed image slide, e.g. `image-slide(image("photo.jpg"))[Caption]`. The body sits at the
/// bottom left in white on a dark scrim, so it reads on any photo.
#let image-slide(config: (:), img, body) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config-page(
      fill: self.colors.neutral-darkest,
      margin: 0em,
      header: none,
      footer: none,
      background: block(width: 100%, height: 100%, clip: true, {
        set image(width: 100%, height: 100%, fit: "cover")
        img
      }),
    ),
  )
  touying-slide(
    self: self,
    config: config,
    slide-start
      + std.align(bottom + left, block(
        width: 100%,
        inset: (x: 2em, y: 1.2em),
        fill: gradient.linear(black.transparentize(100%), black.transparentize(40%), angle: 90deg),
        text(fill: white, size: 1.3em, weight: "bold", body),
      )),
  )
})

/// Full-bleed primary-colored slide for a single message. Bold text turns yellow.
#let focus-slide(config: (:), align: horizon + center, body) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config-common(freeze-slide-counter: true),
    config-page(fill: self.colors.primary, margin: 2em),
    // Alerts use the primary color, which would vanish on this background.
    config-colors(primary: cycle.yellow),
  )
  set text(fill: white, size: 1.6em, weight: "bold")
  touying-slide(self: self, config: config, slide-start + std.align(align, body))
})

/// The cycler theme.
///
/// - text-size (length): base text size. Everything else is in em, so it scales with it.
/// - font (str, array): body and heading font. Try "Libertinus Serif" for a serif look.
/// - mono-font (str, array): font for code.
/// - math-font (str, array): font for equations.
/// - footer (content, function): left footer text. Defaults to the short title, else the title.
/// - progress-bar (bool): draw a thin progress bar along the bottom edge.
/// - overflow (str): what to do with a slide whose content spills onto an extra page. "mark" puts
///   a red badge on the spilled page, "error" stops the build and names the pages, "none" does
///   nothing. `--input overflow=error` overrides it, which `just check` uses.
/// - bibliography (bibliography, none): e.g. `bibliography(title: none, "refs.bib")`. Citations then
///   show as numbered footnotes on their slide, and `magic.bibliography()` lists them all.
#let cycler-theme(
  aspect-ratio: "16-9",
  align: horizon,
  text-size: 20pt,
  font: "Roboto",
  mono-font: "Roboto Mono",
  math-font: "Fira Math",
  header: self => utils.display-current-heading(depth: self.slide-level),
  header-right: self => utils.display-current-heading(level: 1),
  footer: self => if self.info.short-title == auto { self.info.title } else {
    self.info.short-title
  },
  footer-right: context utils.slide-counter.display() + " / " + utils.last-slide-number,
  progress-bar: true,
  overflow: "mark",
  bibliography: none,
  ..args,
  body,
) = {
  let overflow = sys.inputs.at("overflow", default: overflow)
  assert(overflow in ("mark", "error", "none"), message: "overflow must be mark, error or none")
  set text(size: text-size, font: font)
  set strong(delta: 200)
  // Drawn, so the marker never depends on a glyph the font may lack.
  set list(marker: (box(width: 0.3em, height: 0.3em, baseline: -0.15em, fill: cycle.blue), [–]))
  show raw: set text(font: mono-font)
  show math.equation: set text(font: math-font)
  show raw.where(block: true): set text(size: 0.8em)
  show raw.where(block: true): block.with(
    width: 100%,
    inset: (x: 1em, y: 0.7em),
    radius: 2pt,
    fill: rgb("#f4f5f6"),
    stroke: (left: 3pt + cycle.grey.lighten(40%)),
  )
  // After the raw-block styling, so a mermaid fence becomes a diagram rather than a code panel.
  // Explicit typography, since the fence's own context carries the mono font.
  show raw.where(lang: "mermaid", block: true): merman.show-mermaid-blocks(
    profile: mermaid-profile,
    typography: (font: font, size: 0.9 * text-size),
  )
  show link: set text(fill: cycle.blue)
  // Level 1 and 2 headings become sections and slide titles, so level 3 is the in-slide heading.
  show heading.where(level: 3): set text(size: 1.1em, fill: cycle.blue)
  show heading.where(level: 3): set block(above: 0.6em, below: 0.5em)
  show quote.where(block: true): it => block(
    width: 100%,
    inset: (left: 1em, y: 0.3em),
    stroke: (left: 3pt + cycle.blue),
    {
      text(size: 1.15em, style: "italic", it.body)
      if it.attribution != none {
        block(above: 0.7em, text(size: 0.8em, fill: rgb("#4d4d4d"), [--- ] + it.attribution))
      }
    },
  )
  set footnote.entry(
    separator: line(length: 25%, stroke: 0.5pt + cycle.grey),
    gap: 0.25em,
    clearance: 0.6em,
  )
  show footnote.entry: set text(size: 0.55em, fill: rgb("#4d4d4d"))
  // Booktabs-style rules, like the axes lines in the matplotlib style.
  set table(stroke: (x, y) => (
    top: if y == 0 { 1.2pt } else if y == 1 { 0.6pt } else { 0pt },
    bottom: 1.2pt,
  ))

  show: touying-slides.with(
    config-page(
      ..utils.page-args-from-aspect-ratio(aspect-ratio),
      header-ascent: 0%,
      footer-descent: 0%,
      margin: (top: 3.6em, bottom: 2.2em, x: 2em),
      // Checked per page, since content after the body would add a page of its own.
      foreground: if overflow != "none" {
        context if here().page() in overflow-pages() {
          if overflow == "error" {
            panic("the slide before page " + str(here().page()) + " overflows onto it")
          }
          overflow-badge
        }
      },
    ),
    config-common(
      slide-fn: slide,
      new-section-slide-fn: new-section-slide,
      show-bibliography-as-footnote: bibliography,
    ),
    config-methods(alert: utils.alert-with-primary-color),
    config-colors(
      primary: cycle.blue,
      secondary: cycle.red,
      tertiary: cycle.green,
      neutral: rgb("#8b8b8b"),
      neutral-lighter: rgb("#e6e6e6"),
      neutral-lightest: rgb("#ffffff"),
      neutral-dark: rgb("#4d4d4d"),
      neutral-darkest: rgb("#1a1a1a"),
    ),
    config-store(
      align: align,
      header: header,
      header-right: header-right,
      footer: footer,
      footer-right: footer-right,
      progress-bar: progress-bar,
    ),
    ..args,
  )

  body
}
