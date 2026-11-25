# CLAUDE.md — Multi-year slide repository

Slides for **"IA Generativa e Media"** (Generative AI and the Media), Prof. Fabio Giglietto, DISCUI · Università degli Studi di Urbino Carlo Bo. Quarto reveal.js, DISCUI orange theme, published with GitHub Pages at <https://fabiogiglietto.github.io/genai-media-course/>.

**All slide content (titles, body, speaker notes, captions) MUST be in Italian.** English technical terms are kept in English and italicized on first use. Tool names stay in English.

**Year-specific instructions (dates, sessions, readings, project) live in `<year>/CLAUDE.md`. Always read the current year's file before generating slides.** Current year: **2026-27** → `2026-27/CLAUDE.md`.

---

## Rules for multiple years

1. **Never re-render or edit a past year.** Its rendered HTML in `_output/<year>/` is the published record, and some decks need R. `_quarto.yml` → `project.render` lists only the current year.
2. **Do not delete** `_output/slides/*` (redirects that keep 2025-26 Moodle links working).
3. Deck filenames: `sNN-short-title.qmd` (session number, two digits), so the URL is stable: `/<year>/slides/sNN-….html`.
4. BibTeX keys are shared across years: add new entries at the end of `references.bib`, never rename existing keys.
5. After adding or renaming a deck, update `<year>/index.html`.

## Starting a new academic year

1. Create `<YYYY-YY>/` with `CLAUDE.md`, `index.html`, `slides/_metadata.yml` (copy from the previous year; change footer text and paths if needed).
2. In `_quarto.yml`, point `project.render` and `resources` at the new year only.
3. Add the year to the root `index.html` (mark the previous year as past).
4. Render, commit `_output/`, push to `main` (GitHub Actions publishes `_output/`).

## Rendering

The attendance code appears in the footer when the teaching assistant writes it in cell A1 of the shared Google Sheet (see `shared/_attendance-footer.html`).

---

## Style guide (shared by all years)

## DISCUI Color Palette

ALWAYS use these colors. Do not invent variants.

| Role | HEX | SCSS Variable | Usage |
|------|-----|---------------|-------|
| **Primary** | `#E06029` | `$discui-primary` | Headings, borders, markers, badges |
| **Medium** | `#F68B5F` | `$discui-medium` | Secondary text, hover states |
| **Coral** | `#F56D65` | `$discui-coral` | Accents, alerts |
| **Light** | `#F2A7A0` | `$discui-light` | Alternating table backgrounds, borders |
| **Background** | `#F2F2F2` | `$discui-bg` | Light slide background |
| **Dark background** | `#C5612E` | `$discui-warm-bg` | Dark slides (section dividers, title) |
| **Ateneo Blue** | `#294973` | `$uniurb-blue-dark` | University header, institutional accents |

For ggplot2 charts, use `source("../../R/uniurb_theme.R")` with `uniurb_dept_palette("discui")` and `theme_uniurb()`.

---

## Slide syntax, density and speaker notes

**Before writing or editing any deck, load the `slide-style` skill** (`.claude/skills/slide-style/SKILL.md`): slide types and their Quarto syntax, content guidelines, speaker-note requirements.

---

## DO NOT

1. **DO NOT** generate a whole year at once. Proceed one at a time.
2. **DO NOT** use colors outside the DISCUI palette.
3. **DO NOT** create slides with more than 8 lines of text.
4. **DO NOT** skip speaker notes.
5. **DO NOT** use emoji in slide body (only in the closing slide for contact info).
6. **DO NOT** invent content not present in the year CLAUDE.md, syllabus or readings.
7. **DO NOT** insert placeholder images (`![](placeholder.png)`). If an image is needed, describe it in an HTML comment and leave the space.
8. **DO NOT** use `{.section-slide}` — use `{background-color="#C5612E"}` instead.
9. **DO NOT** write slide content in English (except technical terms). All output is Italian.
10. **DO NOT** create text-wall slides. One concept per slide.
11. **DO NOT** use `#` (h1) for section dividers — always use `##` (h2) to keep all slides flat and avoid reveal.js 2D navigation/looping issues.
12. **DO NOT** present data, quotes, frameworks, or findings from readings without a visible `[@bibtexkey]` citation on the slide. Every slide that uses content from a reading MUST include at least one Quarto citation (e.g., `[@ferrara2026]`) in the visible body text — not only in speaker notes. This ensures proper attribution and populates the References slide.

