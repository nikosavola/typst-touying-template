# Default to listing available recipes
[private]
default:
    @just --list

# A generated project builds main.typ; the template repo itself builds its demo deck.
DECK := env("DECK", if path_exists("main.typ") == "true" { "main.typ" } else { "example/showcase.typ" })
BUILD_DIR := "build"
DECK_NAME := file_stem(DECK)
SITE_PDF := env("SITE_PDF", DECK_NAME + ".pdf")
# PDF/A-2b is built on PDF 1.7: embedded fonts, XMP metadata, archivable.
PDF_STANDARD := env("PDF_STANDARD", "1.7,a-2b")
VERAPDF := "verapdf/cli@sha256:d5ee329657cf9bc4b2400392dd54c7d0a0ce9980ff6fa2da5590eebeec007cdb"
SITE_TITLE := env("SITE_TITLE", DECK_NAME)
# Typst only reads files under the root. Set ROOT=.. or higher when the deck sits inside a bigger
# project and shows figures or data from it, then give those paths from that root ("/paper/fig.svg").
ROOT := env("ROOT", ".")
# `just publish` copies the checked PDF here, e.g. a synced Drive or Dropbox folder, under PUBLISH_NAME.
PUBLISH_DIR := env("PUBLISH_DIR", "")
PUBLISH_NAME := env("PUBLISH_NAME", DECK_NAME + ".pdf")
FMT_PATHS := "theme " + DECK + if path_exists("example") == "true" { " example" } else { "" }

# Keep in sync with the typstyle hook's args in .pre-commit-config.yaml.
LINE_WIDTH := "100"

# `just` runs recipes from the justfile's directory, so the default root and `--font-path fonts` always resolve.

# --- Build ---

# Compile the deck to build/
[group('build')]
build:
    mkdir -p {{ BUILD_DIR }}
    typst compile --root {{ ROOT }} --font-path fonts --pdf-standard {{ PDF_STANDARD }} {{ DECK }} {{ BUILD_DIR }}/{{ DECK_NAME }}.pdf

# Recompile the deck on every save
[group('build')]
watch:
    mkdir -p {{ BUILD_DIR }}
    typst watch --root {{ ROOT }} --font-path fonts --pdf-standard {{ PDF_STANDARD }} {{ DECK }} {{ BUILD_DIR }}/{{ DECK_NAME }}.pdf

# Render every slide to a PNG in build/ for a quick visual check
[group('build')]
preview: build
    typst compile --root {{ ROOT }} --font-path fonts {{ DECK }} {{ BUILD_DIR }}/preview-{0p}.png --format png --ppi 150

# Fail if any slide's content spills onto an extra page
[group('build')]
check-overflow:
    mkdir -p {{ BUILD_DIR }}
    typst compile --root {{ ROOT }} --font-path fonts --input overflow=error {{ DECK }} {{ BUILD_DIR }}/{{ DECK_NAME }}.pdf

# Validate the PDF against PDF/A-2b with veraPDF (needs Docker)
[group('build')]
check-pdf: build
    docker run --rm -v "$PWD/{{ BUILD_DIR }}":/data {{ VERAPDF }} --flavour 2b --format text /data/{{ DECK_NAME }}.pdf

# Check overflow and PDF/A, then copy the PDF to PUBLISH_DIR, replacing the copy there
[group('build')]
publish: _publish-dir check-overflow check-pdf
    mkdir -p "{{ PUBLISH_DIR }}"
    cp {{ BUILD_DIR }}/{{ DECK_NAME }}.pdf "{{ PUBLISH_DIR }}/{{ PUBLISH_NAME }}"

[private]
_publish-dir:
    @test -n "{{ PUBLISH_DIR }}" || { echo "Set PUBLISH_DIR to the folder to copy the PDF to"; exit 1; }

# Optional PPTX export, one full-slide image per slide (not editable text)
[group('build')]
build-pptx:
    mkdir -p {{ BUILD_DIR }}
    uvx touying@0.14.4 compile --root {{ ROOT }} --font-paths fonts --format pptx --ppi 200 --output {{ BUILD_DIR }}/{{ DECK_NAME }}.pptx {{ DECK }}

# Build the PDF plus an index.html that shows it, for GitHub Pages
[group('build')]
site: build
    mkdir -p {{ BUILD_DIR }}/site
    cp {{ BUILD_DIR }}/{{ DECK_NAME }}.pdf {{ BUILD_DIR }}/site/{{ SITE_PDF }}
    printf '%s\n' '<!doctype html>' '<meta charset="utf-8">' \
        '<meta name="viewport" content="width=device-width, initial-scale=1">' \
        '<title>{{ SITE_TITLE }}</title>' \
        '<style>html,body{margin:0;height:100%}object{display:block;width:100%;height:100%}</style>' \
        '<object data="{{ SITE_PDF }}" type="application/pdf">' \
        '<p><a href="{{ SITE_PDF }}">Open the slides (PDF)</a></p>' \
        '</object>' > {{ BUILD_DIR }}/site/index.html

# Regenerate matplotlib figures by running every plots/*.py script with uv
[group('build')]
plots:
    #!/usr/bin/env sh
    set -eu
    for script in plots/*.py example/plots/*.py; do
        [ -e "$script" ] || continue
        uv run --script "$script"
    done

# Re-export the README slide images in example/images/ as vector SVGs (needs pdftocairo from poppler)
[group('build')]
readme-images: build
    #!/usr/bin/env sh
    set -eu
    # name:page in the showcase deck; update when slides move
    for spec in title:1 columns:9 callouts:11 colors:12 plot:14 matplotlib:15 mermaid:17 citations:30; do
        out="example/images/${spec%%:*}.svg"
        pdftocairo -svg -f "${spec#*:}" -l "${spec#*:}" {{ BUILD_DIR }}/{{ DECK_NAME }}.pdf "$out"
        # cairo leaves a sliver at the page edge, which shows as a line on dark pages
        # -i.bak works with both GNU and BSD sed
        sed -i.bak 's|</defs>|</defs><rect width="100%" height="100%" fill="#fff"/>|' "$out" && rm "$out.bak"
    done

# Remove build artifacts
[confirm]
[group('build')]
clean:
    rm -rf {{ BUILD_DIR }}

# --- Lint & format ---

# Reformat all Typst sources in place
[group('lint')]
format:
    typstyle -i --line-width {{ LINE_WIDTH }} {{ FMT_PATHS }}

# Check formatting without modifying files
[group('lint')]
format-check:
    typstyle --check --line-width {{ LINE_WIDTH }} {{ FMT_PATHS }}

# Run pre-commit hooks against all files
[group('lint')]
pre-commit:
    prek run -a

# --- Setup ---

# Install pre-commit hooks
[group('setup')]
pre-commit-install:
    prek install

# Add (or init) the Typst/Touying agent skills as git submodules under .agents/
[group('setup')]
agent-skills:
    #!/usr/bin/env sh
    set -eu
    sub() {
        if git ls-files --stage -- "$2" | grep -q '^160000'; then
            git submodule update --init "$2"
        else
            # GitHub's "Use this template" keeps .gitmodules but drops the gitlinks.
            rmdir "$2" 2>/dev/null || true
            git submodule add --force "$1" "$2"
        fi
    }
    sub https://github.com/apcamargo/typst-skills .agents/vendor/typst-skills
    sub https://github.com/touying-typ/seaslides .agents/vendor/seaslides
    mkdir -p .agents/skills .claude
    ln -sfn ../vendor/typst-skills/typst-author .agents/skills/typst-author
    ln -sfn ../vendor/typst-skills/touying-author .agents/skills/touying-author
    ln -sfn ../vendor/seaslides/skills/seaslides-typst-slides-skill .agents/skills/seaslides-typst-slides-skill
    ln -sfn ../.agents/skills .claude/skills
