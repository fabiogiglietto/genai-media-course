# CLAUDE.md — Multi-year slide repository

Slides for **"IA Generativa e Media"** (Generative AI and the Media), Prof. Fabio Giglietto, DISCUI · Università degli Studi di Urbino Carlo Bo. Quarto reveal.js, DISCUI orange theme, published with GitHub Pages at <https://fabiogiglietto.github.io/genai-media-course/>.

**All slide content (titles, body, speaker notes, captions) MUST be in Italian.** English technical terms are kept in English and italicized on first use. Tool names stay in English.

**Year-specific instructions (dates, sessions, readings, project) live in `<year>/CLAUDE.md`. Always read the current year's file before generating slides.** Current year: **2026-27** → `2026-27/CLAUDE.md`.

---

## Repository layout

```
genai-media-course/
├── CLAUDE.md                 ← this file: shared conventions
├── README.md
├── _quarto.yml               ← shared Quarto config; renders ONLY the current year
├── _extensions/uniurb/       ← shared DISCUI theme (discui.scss)
├── assets/                   ← shared logos
├── R/uniurb_theme.R          ← shared ggplot2 palette/theme
├── references.bib, apa.csl   ← shared bibliography (keys unique across years)
├── shared/_attendance-footer.html  ← attendance-code footer (year-agnostic)
├── index.html                ← landing page: list of academic years
├── 2025-26/                  ← FROZEN past year (sources + CLAUDE.md + index.html)
├── 2026-27/                  ← current year
│   ├── CLAUDE.md             ← year-specific instructions
│   ├── index.html            ← year landing page (list of decks)
│   └── slides/
│       ├── _metadata.yml     ← year footer, theme paths, bibliography
│       ├── _attendance.qmd   ← include partial (attendance instructions)
│       └── sNN-*.qmd         ← one deck per session
└── _output/                  ← rendered site (committed; deployed by GitHub Actions)
    ├── index.html
    ├── 2025-26/…             ← frozen rendered HTML of past years
    ├── 2026-27/…
    └── slides/…              ← redirect stubs for old 2025-26 URLs (do not delete)
```

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

```bash
quarto render 2026-27/slides/s01-introduzione.qmd   # one deck
quarto render                                        # the whole current year
```

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

## Slide Types and Quarto Syntax

### 1. Section Divider (dark orange background)

Marks major sections within a lecture. White text on orange background.

**IMPORTANT:** Use `##` (not `#`) for section dividers to keep all slides at the same level and avoid reveal.js 2D navigation issues (nested sections cause looping within section stacks).

```markdown
## Titolo della Sezione {background-color="#C5612E"}
```

### 2. Content Slide (light background — DEFAULT)

The workhorse slide. Light gray background, dark text, orange headings.

```markdown
## Titolo della Slide

Body text. **Important words** appear in bold (rendered in orange by the theme).

- First point
- Second point
- Third point
```

### 3. Content Slide (dark orange background)

For visual rhythm variation. Use sparingly (1 per every 5–6 light slides).

```markdown
## Titolo su Sfondo Scuro {background-color="#C5612E"}

Text automatically renders white thanks to the CSS theme.
```

### 4. Two Columns

```markdown
## Titolo

::: {.columns}
::: {.column width="50%"}
### Colonna Sinistra

Text or content.
:::

::: {.column width="50%"}
### Colonna Destra

Other content or image.
:::
:::
```

### 5. Image + Text

```markdown
## Titolo

![Didascalia dell'immagine](img/image-name.png){fig-align="center" width="80%"}

Text below the image.
```

### 6. Highlight Box (orange border, white background)

```markdown
::: {.highlight-box}
**Concetto chiave:** Important text to emphasize.
:::
```

### 7. Orange Box (solid orange background)

```markdown
::: {.orange-box}
### Definizione
Text on orange background with white text.
:::
```

### 8. Callouts

```markdown
::: {.callout-note}
## Nota
Supplementary information.
:::

::: {.callout-tip}
## Suggerimento
Practical tip.
:::

::: {.callout-warning}
## Attenzione
Important warning.
:::
```

### 9. Blockquote

```markdown
> "Quoted text from an author."
>
> — Author, Year
```

### 10. Table

```markdown
| Colonna 1 | Colonna 2 | Colonna 3 |
|-----------|-----------|-----------|
| Dato A    | Dato B    | Dato C    |
```

### 11. "This Week in AI" Badge

For Wednesday sessions that include the TWIAI segment:

```markdown
## [This Week in AI]{.twiai-badge}

### Headline

Brief description of a recent development in generative AI.

::: {.callout-note}
## Da discutere
What are the implications for the media system?
:::
```

### 12. R Code Chunk

```markdown
## Esempio di Analisi

​```{r}
#| label: example-analysis
#| echo: true
#| eval: true
#| fig-width: 12
#| fig-height: 6

source("../../R/uniurb_theme.R")

library(ggplot2)

ggplot(data, aes(x = variable, y = value)) +
  geom_col(fill = uniurb_colors$blue_dark) +
  theme_uniurb() +
  labs(title = "Titolo del Grafico")
​```
```

### 13. Closing Slide

```markdown
## Grazie! {background-color="#C5612E"}

**Prossima lezione:** [title and date]

📧 fabio.giglietto@uniurb.it

🌐 blended.uniurb.it
```

---

## Content Guidelines

### Text Density

- **Maximum 6–8 lines of text** per content slide.
- **One concept per slide.** As stated in the official DISCUI template guidelines.
- Keywords go in **bold**.
- Use short, punchy sentences. Slides are NOT a textbook.
- Slides support the oral explanation — they should not be self-contained.

### Slide Count per Session

- **Theory lectures (2 hours):** 25–35 slides
- **Workshops/Labs:** 15–25 slides (more time for hands-on activities)
- **Consultations:** 10–15 slides (roadmap + checklists)

### Typical Session Structure

1. **Title slide** (auto-generated from YAML)
2. **[TWIAI]** if Wednesday: 2–3 "This Week in AI" slides
3. **Lecture roadmap** (agenda/objectives): 1 slide
4. **Section 1** (section divider + 5–8 content slides)
5. **Section 2** (section divider + 5–8 content slides)
6. **[Section 3]** if needed
7. **Summary / Key takeaways:** 1–2 slides
8. **Next steps / Assignments:** 1 slide
9. **Closing slide**

### First-Day Introductory Slides (week1-mon only)

The first session (`week1-mon-introduction.qmd`) includes an expanded administrative section after the roadmap, following the instructor's standard introductory template (see `TMP.pdf` for reference). This section contains the following slides in order:

1. **Il corso in sintesi** — basic info table (name, instructor, dates, times, platform)
2. **Panoramica del corso** — meetings per week, total hours, Part I / Part II structure
3. **Struttura delle 7 settimane** — weekly focus overview table
4. **Modalità di valutazione per frequentanti** — numbered list: enrollment deadline, ¾ attendance threshold, group project 75%, participation 10%, oral exam 15%, non-attending students policy
5. **Rilevazione delle presenze** — attendance code + geolocation requirement
6. **Policy per giustificare le assenze** — each session's point value, justified absences policy, 2-day posting deadline on blended forum
7. **Policy per Generative AI** — allowed uses (brainstorming, critique), forbidden uses (substitutive generation), mandatory disclosure
8. **Spazio blended** — link/QR to Moodle space (placeholder for instructor to add)
9. **Attività interattiva** — feedback form on blended (placeholder for instructor to add)

These administrative slides are specific to the first day and should NOT be repeated in other sessions.

### Visual Variation

To avoid monotony, alternate layouts:

- NEVER use more than 3 text-only slides in a row
- Insert an image, table, diagram, or box every 3–4 slides
- Alternate light and dark slides (roughly 5:1 ratio light:dark)
- Use two-column layout for comparisons or text+image
- `.highlight-box` and `.orange-box` break visual rhythm

---

## Speaker Notes

Add speaker notes to every significant slide:

```markdown
## Titolo della Slide

Visible content.

::: {.notes}
Speaker notes: full talking points, additional references,
questions to pose to students, transition to next slide.
:::
```

Speaker notes should include:
- Extended discussion points
- References to specific readings (pages, chapters)
- Questions to pose to the class
- Additional examples not shown on the slide
- Transitions to the next slide


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

