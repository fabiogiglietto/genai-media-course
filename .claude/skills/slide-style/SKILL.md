---
name: slide-style
description: "Slide types and Quarto syntax, text-density and structure guidelines, and speaker-note requirements for the IA Generativa e Media decks (Quarto reveal.js, DISCUI theme). Load before writing or editing any sNN-*.qmd deck."
---

# Slide style guide (shared by all years)

The colour palette, multi-year rules and the DO NOT list live in the root `CLAUDE.md` and always apply.

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
