// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Niko Savola, https://github.com/nikosavola/typst-touying-template
// cycler: a Touying theme built around the modified fivethirtyeight matplotlib prop cycle.
#import "@preview/touying:0.7.4": *
#import "@preview/merman:0.3.0"

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

/// A horizontal stripe with one segment per cycle color, for decks that want the full palette.
#let stripe(height: 4pt) = grid(
  columns: (1fr,) * cycle.len(),
  rows: height,
  ..cycle.values().map(c => rect(width: 100%, height: 100%, fill: c, stroke: none)),
)

/// A tinted box with a colored left rule, for asides and warnings. `icon` is any content, or a
/// short string like "i" or "!" that gets drawn as a round badge, so no icon font is needed.
#let callout(color: cycle.blue, title: none, icon: none, body) = block(
  width: 100%,
  inset: (x: 0.9em, y: 0.7em),
  fill: color.transparentize(88%),
  stroke: (left: 3pt + color),
  {
    let badge = if type(icon) == str {
      circle(radius: 0.6em, fill: color.darken(15%), stroke: none, align(
        center + horizon,
        text(size: 0.8em, weight: "black", fill: white, icon),
      ))
    } else { icon }
    let heading = text(weight: "bold", fill: color.darken(25%), title)
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
    pad(x: 2em, top: 1.1em, {
      set text(fill: self.colors.neutral-darkest, weight: "bold", size: 1.25em)
      components.left-and-right(
        if title != auto {
          utils.fit-to-width(grow: false, 100%, title)
        } else {
          utils.call-or-display(self, self.store.header)
        },
        text(
          size: 0.55em,
          weight: "regular",
          fill: self.colors.neutral,
          utils.call-or-display(self, self.store.header-right),
        ),
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
    set std.align(horizon)
    set text(fill: self.colors.neutral-darkest)
    if info.logo != none {
      place(top + right, info.logo)
    }
    block(width: 85%, text(size: 2em, weight: "bold", info.title))
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
  touying-slide(self: self, config: config, std.align(bottom + left, block(
    width: 100%,
    inset: (x: 2em, y: 1.2em),
    fill: gradient.linear(black.transparentize(100%), black.transparentize(40%), angle: 90deg),
    text(fill: white, size: 1.3em, weight: "bold", body),
  )))
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
  touying-slide(self: self, config: config, std.align(align, body))
})

/// The cycler theme.
///
/// - font (str, array): body and heading font. Try "Libertinus Serif" for a serif look.
/// - mono-font (str, array): font for code.
/// - math-font (str, array): font for equations.
/// - footer (content, function): left footer text. Defaults to the short title, else the title.
/// - progress-bar (bool): draw a thin progress bar along the bottom edge.
/// - bibliography (bibliography, none): e.g. `bibliography(title: none, "refs.bib")`. Citations then
///   show as numbered footnotes on their slide, and `magic.bibliography()` lists them all.
#let cycler-theme(
  aspect-ratio: "16-9",
  align: horizon,
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
  bibliography: none,
  ..args,
  body,
) = {
  set text(size: 20pt, font: font)
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
    typography: (font: font, size: 18pt),
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
