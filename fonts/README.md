# Fonts

Vendored so decks compile the same everywhere, without depending on what's installed on the machine or CI image. Roboto
and Roboto Mono come from [Google Fonts](https://github.com/google/fonts) as variable fonts, and Fira Math from
[firamath](https://github.com/firamath/firamath) v0.3.4. All are licensed under the SIL Open Font License 1.1, which
allows bundling and redistribution. The license text for each is included here.

| Family      | File                                                    | Used for       |
| ----------- | ------------------------------------------------------- | -------------- |
| Roboto      | `Roboto[wdth,wght].ttf`, `Roboto-Italic[wdth,wght].ttf` | Text, headings |
| Roboto Mono | `RobotoMono[wght].ttf`                                  | Code           |
| Fira Math   | `FiraMath-Regular.otf`                                  | Math           |

Set `math-font` on the theme to use a different one. Pass `--font-path fonts` when compiling; `just build` does this for
you.
