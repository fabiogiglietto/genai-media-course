# CLAUDE.md — Course Slide Generation Instructions

## Project

Generate lecture slides for **"IA Generativa e Media"** (Generative AI and the Media), A.Y. 2025/2026, taught by Prof. Fabio Giglietto at Università degli Studi di Urbino Carlo Bo, DISCUI Department.

Slides are **Quarto reveal.js** format (HTML output) using the DISCUI department orange theme.

**CRITICAL: All slide content (titles, body text, speaker notes, captions) MUST be in Italian.** English technical terms (deepfake, AI slop, prompt engineering, LLMs-in-the-loop) are kept in English and italicized on first use. Tool names (Google Gemini, NotebookLM, Meta Content Library) remain in English.

---

## Learning Objectives & Dublin Descriptors

These are the official syllabus objectives. Slides should progressively build toward these outcomes. Use them to calibrate depth, vocabulary level, and what students should be able to DO after each session.

### Course Aims

The course provides students with essential skills to understand and critically analyze the impact of generative AI on the contemporary media system, focusing on content production, circulation, consumption, and disinformation risks.

### Specific Objectives

1. **Theoretical understanding of generative AI in media**
   - Fundamental concepts of generative AI and its media applications
   - Evolution of hybrid media in the AI era
   - Transformations of contemporary communication practices

2. **Analysis of production, circulation, and consumption processes**
   - Dynamics of AI-generated content creation
   - Diffusion mechanisms on social platforms (Meta and TikTok)
   - How users perceive and interact with AI-generated content
   - Recognizing and assessing disinformation risks

3. **Methodological application skills**
   - Using AI tools for content analysis
   - Applying digital research methodologies through a practical case study
   - Developing collaborative critical analysis of AI-generated content circulation

### Dublin Descriptors (Expected Learning Outcomes)

Use these to ensure slides build the right competencies at the right level.

**Knowledge and Understanding** — Students will be able to:
- Understand fundamental principles of generative AI and its main media applications
- Understand transformations of the contemporary media system in the AI era (hybrid media system)
- Master specialized terminology (generative AI, automated production, digital circulation)
- Distinguish different types of AI-generated content (text, image, audio, video) and their creation processes
- Identify recommendation and amplification algorithm mechanisms on major social platforms

**Applying Knowledge** — Students will be able to:
- Recognize AI-generated content by analyzing technical and stylistic indicators
- Analyze circulation and diffusion of AI-generated content on social platforms (Meta and TikTok)
- Apply digital research methodologies to contemporary media phenomena
- Use AI tools for media content analysis and social media data collection
- Evaluate reliability and veracity of media content in the digital ecosystem
- Contextualize disinformation cases within the hybrid media system framework

**Making Judgments** — Students will be able to:
- Critically evaluate the social and ethical impact of generative AI in communication
- Make independent judgments about risks and opportunities of automated media production
- Reflect on implications of AI-generated content for information quality
- Develop strategies for recognizing and countering AI-based disinformation
- Evaluate effectiveness of different research methodologies for digital media

**Communication Skills** — Students will be able to:
- Communicate complex generative AI concepts to specialist and non-specialist audiences
- Present research findings through structured written reports
- Use technical-scientific language appropriately
- Collaborate effectively in groups on applied research projects
- Summarize and visualize data through effective graphs, tables, and representations
- Argue critical positions supported by empirical evidence and theoretical references

**Learning Skills** — Students will be able to:
- Autonomously acquire new knowledge on generative AI's technological evolution
- Stay updated on digital media landscape transformations
- Apply learned research methodologies to new contexts and emerging issues
- Develop transversal skills for critical analysis of complex communication phenomena
- Integrate theoretical knowledge and practical skills for future professional challenges

### How to Use These in Slide Generation

| Objective Level | How It Maps to Slides |
|---|---|
| Knowledge & Understanding | Week 1–2 lectures: definitions, frameworks, taxonomies |
| Applying Knowledge | Week 1 workshop + Week 4–5 labs: hands-on tool use, data collection, analysis |
| Making Judgments | Discussion prompts, callout boxes with "Da discutere", critical reflection slides |
| Communication Skills | Week 6 writing workshop, paper structure guidance, visualization examples |
| Learning Skills | "This Week in AI" segments, pointers to further reading, self-study prompts |

---

## Directory Structure

```
genai-media-course/
├── CLAUDE.md                          ← This file
├── course-plan.md                     ← Full course plan
├── _quarto.yml                        ← Shared Quarto config
├── _extensions/
│   └── uniurb/
│       ├── _extension.yml
│       └── discui.scss                ← DISCUI orange theme
├── R/
│   └── uniurb_theme.R                ← Color palettes + ggplot2 theme
├── assets/
│   ├── logo-uniurb-white.svg         ← White logo (dark slides)
│   └── logo-nh-uniurb.svg            ← Color logo (light slides)
├── references.bib                     ← Shared bibliography
├── slides/
│   ├── week1-mon-introduction.qmd
│   ├── week1-tue-hybrid-media.qmd
│   ├── week1-wed-workshop-gemini.qmd
│   ├── week2-mon-content-production.qmd
│   ├── week2-wed-deepfakes-regulation.qmd
│   ├── week4-tue-project-launch.qmd
│   ├── week4-wed-lab-collecting.qmd
│   ├── week5-mon-lab-analysis.qmd
│   ├── week5-tue-validation.qmd
│   ├── week5-wed-consultation.qmd
│   ├── week6-mon-writing-workshop.qmd
│   ├── week6-tue-paper-drafting.qmd
│   └── week6-wed-synthesis.qmd
├── readings/                          ← Article PDFs + supplementary materials
├── img/                               ← Slide images
└── _output/                           ← Rendered HTML
```

---

## Sessions Requiring Slides (13 of 18)

Guest and seminar sessions (week 3 + guest lectures in weeks 2 and 4) do NOT require slides.

| # | File | Title (Italian) | Date | Type |
|---|------|-----------------|------|------|
| 1 | `week1-mon-introduction.qmd` | Introduzione all'IA Generativa | Mon Feb 23 | Lecture |
| 2 | `week1-tue-hybrid-media.qmd` | Il Sistema Mediale Ibrido nell'Era dell'IA | Tue Feb 24 | Lecture |
| 3 | `week1-wed-workshop-gemini.qmd` | Workshop: Google Gemini & NotebookLM | Wed Feb 25 | Workshop + TWIAI |
| 4 | `week2-mon-content-production.qmd` | Produzione di Contenuti con GenAI | Mon Mar 2 | Lecture |
| 5 | `week2-wed-deepfakes-regulation.qmd` | Deepfake, Policy e Regolamentazione | Wed Mar 4 | Lecture + TWIAI |
| 6 | `week4-tue-project-launch.qmd` | Lancio Progetto: Analisi Ricezione AI Slop | Tue Mar 17 | Workshop |
| 7 | `week4-wed-lab-collecting.qmd` | Lab: Raccolta Post e Commenti | Wed Mar 18 | Lab + TWIAI |
| 8 | `week5-mon-lab-analysis.qmd` | Lab: Analisi Contenuti con IA | Mon Mar 23 | Lab |
| 9 | `week5-tue-validation.qmd` | Validazione: Umano vs Macchina | Tue Mar 24 | Workshop |
| 10 | `week5-wed-consultation.qmd` | Consultazione Gruppi e Revisione | Wed Mar 25 | Consultation + TWIAI |
| 11 | `week6-mon-writing-workshop.qmd` | Workshop di Scrittura | Mon Mar 30 | Workshop |
| 12 | `week6-tue-paper-drafting.qmd` | Lavoro di Gruppo: Stesura Paper | Tue Mar 31 | Lab |
| 13 | `week6-wed-synthesis.qmd` | Sintesi del Corso e Consultazioni Finali | Wed Apr 1 | Closing + TWIAI |

---

## YAML Header for Every .qmd File

Every slide file MUST include this header (customize title/subtitle/date per session):

```yaml
---
title: "Titolo della Lezione"
subtitle: "IA Generativa e Media — Settimana N"
author: "Fabio Giglietto"
institute: "DISCUI · Università degli Studi di Urbino Carlo Bo"
date: "23 Febbraio 2026"
date-format: "D MMMM YYYY"
format:
  revealjs:
    theme: [default, ../_extensions/uniurb/discui.scss]
    logo: ../assets/logo-uniurb-white.svg
    footer: "IA Generativa e Media · A.A. 2025/2026"
    slide-number: c/t
    transition: fade
    width: 1920
    height: 1080
    margin: 0.08
    center: false
    hash: true
    controls: true
    progress: true
execute:
  echo: true
  warning: false
  message: false
  fig-width: 10
  fig-height: 6
  fig-dpi: 150
knitr:
  opts_chunk:
    dev: "ragg_png"
lang: it
bibliography: ../references.bib
csl: ../apa.csl
---
```

---

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

For ggplot2 charts, use `source("../R/uniurb_theme.R")` with `uniurb_dept_palette("discui")` and `theme_uniurb()`.

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

![Didascalia dell'immagine](../img/image-name.png){fig-align="center" width="80%"}

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

source("../R/uniurb_theme.R")

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
3. **Struttura delle 6 settimane** — weekly focus overview table
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

## Bibliography

### Citing in Slides

Use author-date format on slides:

```markdown
(Vaccari & Chadwick, 2020)
```

For formal citations with `references.bib`, use Quarto syntax:

```markdown
Come dimostrato da @vaccari2020, i deepfake...
```

### BibTeX Keys

#### Core readings (PDFs in `readings/`)

| Key | Article |
|-----|---------|
| `vaccari2020` | Vaccari & Chadwick (2020) — Deepfakes and political trust |
| `chadwick2011` | Chadwick (2011) — The Hybrid Media System |
| `gilardi2025` | Gilardi et al. (2025) — Willingness to read AI-generated news |
| `mattis2025` | Mattis & de Vreese (2025) — GenAI's impact on journalism and disinformation |
| `munoriyarwa2025` | Munoriyarwa & de-Lima-Santos (2025) — GenAI and the future of news |
| `ferrara2026` | Ferrara (2026) — The Generative AI Paradox: trust erosion and epistemic security |
| `dubey2026` | Dubey et al. (2026) — Trust in balanced news chatbots and conspiracy beliefs |
| `gillespie2026` | Gillespie et al. (2026) — AI red-teaming as a sociotechnical problem |
| `hameleers2026` | Hameleers & van der Meer (2026) — Visual disinformation: AI-generated vs video-based |
| `pewresearch2025` | Pew Research Center (2025) — How Americans View AI and Its Impact |
| `schroeder2026` | Schroeder et al. (2026) — How malicious AI swarms can threaten democracy |
| `hackenburg2025` | Hackenburg et al. (2025) — Levers of political persuasion with conversational AI |
| `czarnek2025` | Czarnek et al. (2025) — Addressing climate change skepticism with human-AI dialogues |
| `cosenza2025` | Cosenza (2025) — Esercizi di Intelligenza Aumentata (practical AI exercises guide) |

#### Referenced in course plan (PDFs NOT yet in `readings/`)

| Key | Article |
|-----|---------|
| `morosoli2025` | Morosoli et al. (2025) — Attitudes toward GenAI in journalism |
| `giglietto2020` | Giglietto et al. (2020) — Coordinated manipulation in Italian elections |
| `marino2024` | Marino & Giglietto (2024) — LLMs-in-the-loop pipeline |
| `terenzi2025` | Terenzi & Giglietto (2025) — AI Slop and synthetic virality |

### Readings Mapped to Sessions

| Session | Primary Readings |
|---------|-----------------|
| Week 1 Mon — Introduction | pewresearch2025, ferrara2026, hackenburg2025, overview of all articles |
| Week 1 Tue — Hybrid Media System | chadwick2011, mattis2025, munoriyarwa2025 |
| Week 1 Wed — Workshop: Gemini & NotebookLM | cosenza2025 (practical exercises, prompt design) |
| Week 2 Mon — Content Production | gilardi2025, mattis2025, munoriyarwa2025, morosoli2025* |
| Week 2 Wed — Deepfakes & Regulation | vaccari2020, hameleers2026, schroeder2026, hackenburg2025, czarnek2025, EU AI Act, EU Code of Practice |
| Week 4 Tue — Project Launch | terenzi2025*, marino2024* |
| Week 5 Mon — Analysis Lab | marino2024* (methodology), cosenza2025 (practical prompt strategies) |
| Week 5 Tue — Validation | marino2024* (validation) |
| Week 6 Wed — Synthesis | ferrara2026, gillespie2026, schroeder2026, hackenburg2025 |

*\* PDF not yet in `readings/` — BibTeX entry exists in `references.bib` but content cannot be used for slide generation until the PDF is added.*

#### Cross-cutting readings (relevant across multiple sessions)

| Reading | Relevant Sessions |
|---------|-------------------|
| `ferrara2026` | Introduction, Deepfakes & Regulation, Synthesis (trust erosion, synthetic realities) |
| `gillespie2026` | Deepfakes & Regulation, Synthesis (AI safety, sociotechnical governance) |
| `dubey2026` | Content Production, Synthesis (AI chatbots, trust, conspiracy beliefs) |
| `pewresearch2025` | Introduction, Content Production (public attitudes toward AI) |
| `hackenburg2025` | Introduction, Deepfakes & Regulation, Synthesis (AI persuasion mechanisms, accuracy trade-offs) |
| `czarnek2025` | Deepfakes & Regulation, Synthesis (LLM-based persuasion on climate, personalized fact-checking) |
| `cosenza2025` | Workshop Gemini, Lab Analysis (practical AI exercises, prompt design rules) |

---

## Session Content Summary

Always consult `course-plan.md` for full details. Below is a concise summary of key topics per session.

### Week 1: Generative AI Fundamentals

**Mon Feb 23 — Introduction to Generative AI**
- Course overview, rules, assessment
- Definitions: generative AI, LLM, diffusion models
- Historical evolution: from early algorithms to modern LLMs
- Technology overview: GPT, DALL-E, Midjourney, Stable Diffusion, Gemini
- Introduction to the hybrid media system concept
- References: pewresearch2025 (public attitudes), ferrara2026 (GenAI Paradox overview), hackenburg2025 (AI persuasion levers)

**Tue Feb 24 — The Hybrid Media System in the AI Era**
- From broadcasting to hybrid media: platforms, algorithms, automation
- Chadwick's framework: the hybrid media system
- Transformations in journalism and communication professions
- References: chadwick2011, mattis2025, munoriyarwa2025

**Wed Feb 25 — Workshop: Google Gemini & NotebookLM**
- TWIAI (10 min)
- Access via @uniurb.it account
- Gemini: text generation, multimodal, Nano Banana
- NotebookLM: document analysis, audio overviews, citations
- Exercise: create a notebook with course readings
- Long context window (1M tokens) for datasets
- Reference: cosenza2025 (practical AI exercises, prompt design rules)

### Week 2: Production, Disinformation & Regulation

**Mon Mar 2 — Content Production with GenAI**
- Content creation workflows with Gemini
- Prompt engineering fundamentals
- Evaluation criteria for AI-generated content
- References: gilardi2025 (public perception of AI news quality), mattis2025 (journalism workflows), morosoli2025* (attitudes and resistance)

**Wed Mar 4 — Deepfakes, Policies & Regulation**
- TWIAI (10 min)
- Deepfake technologies: creation, spread, detection
- Vaccari & Chadwick (2020): impact on political trust
- EU Code of Practice on Disinformation (2022 version)
- EU AI Act: overview and key provisions
- Platform policies: Meta, TikTok on synthetic media
- References: vaccari2020, hameleers2026 (visual disinformation effects), schroeder2026 (AI swarms threat), hackenburg2025 (AI persuasion mechanisms), czarnek2025 (LLM persuasion on climate beliefs)

### Week 4: Project Launch & Data Collection

**Tue Mar 17 — Project Launch**
- Briefing: analyzing AI-generated content and comment reception
- Group formation (4–6 students)
- Meta Content Library and NotebookLM for organizing sources
- Research question development
- References: terenzi2025, marino2024

**Wed Mar 18 — Lab: Collecting Posts & Comments**
- Hands-on data collection: AI-generated posts AND user comments/reactions
- Gemini for initial screening and classification
- Building analysis datasets

### Week 5: Analysis & Validation

**Mon Mar 23 — Lab: AI-Assisted Content Analysis**
- Gemini for analyzing datasets of posts and images
- Automated visual content classification
- Prompt strategies for consistent coding
- Long context management in Gemini

**Tue Mar 24 — Validation: Human vs Machine**
- LLMs-in-the-loop methodology (Marino & Giglietto, 2024)
- Designing human validation protocols
- Inter-coder reliability with AI
- Comparing AI classifications with human judgment

**Wed Mar 25 — Group Consultation**
- TWIAI (10 min)
- Individual group consultations
- Methodological and theoretical review
- Troubleshooting and refining approaches

### Week 6: Writing & Synthesis

**Mon Mar 30 — Writing Workshop**
- Structuring the final research paper
- NotebookLM for synthesizing findings and literature
- Academic writing with AI assistance

**Tue Mar 31 — Group Work: Paper Drafting**
- In-class collaborative writing session
- Peer review and feedback
- Final methodology and theory review

**Wed Apr 1 — Course Synthesis & Final Consultations**
- TWIAI (10 min)
- Collective discussion on main findings
- Methodological reflections
- Future perspectives for GenAI in media
- Final project guidance
- References: ferrara2026 (GenAI Paradox, epistemic security), gillespie2026 (AI safety governance), schroeder2026 (democratic threats), hackenburg2025 (persuasion-accuracy trade-off)

---

## Group Project: Details for Slides

The group project is central in weeks 4–6. Slides must guide students through:

### Assessment
- **Group project:** 75% (max 23.25 points)
- **Participation:** 10% (max 3.1 points)
- **Oral exam:** 15% (max 4.65 points)

### Timeline
- Week 4: Terenzi seminar → group formation → data collection
- Week 5: Analysis with Gemini → human validation → consultations
- Week 6: Writing → peer review → submission (2 weeks before June exam)

### LLMs-in-the-loop Methodology
This is the central methodological framework. Slides must explain:
1. Definition of an LLMs-in-the-loop pipeline
2. Systematic prompting for content analysis
3. Validation through parallel human coding
4. Computing inter-coder reliability (AI as "coder")
5. Iteration and pipeline refinement

---

## Generation Workflow

### FUNDAMENTAL RULE: Read ALL materials before generating any slides.

Before generating the FIRST `.qmd` file, you MUST read EVERY PDF in the `readings/` folder. Not just those explicitly mapped to the current session — ALL of them. The folder may contain supplementary materials beyond the 5 required readings. These enrich the slides with concepts, data, and perspectives the instructor considers relevant even if they are not directly cited in the course plan.

```bash
# Step 0: ALWAYS do this first
ls readings/
# Then read every PDF present
```

After reading all materials, retain them as a knowledge base for ALL sessions. Concepts, data, and frameworks from any reading may be relevant to any session — use your judgment to make cross-cutting connections.

### For each session:

1. **Verify** you have already read all PDFs in `readings/` (if this is the first session you generate, read them now)
2. **Read the session description** in `course-plan.md` for structure and objectives
3. **Identify relevant content** from all PDFs read. Look for:
   - Key concepts, definitions, and theoretical frameworks relevant to the session
   - Empirical data, findings, and citable statistics
   - Figures, tables, or conceptual diagrams reproducible in slides
   - Brief significant author quotes (for slides)
   - Limitations and open questions (useful for discussion prompts)
   - Cross-cutting connections with other materials
4. **Generate** the `.qmd` file following the standard structure, integrating content from the readings
5. **Verify** slide count (see ranges by session type)
6. **Check** that bibliographic references are correct and match the PDFs read
7. **Render** with `quarto render slides/filename.qmd`

### Course Readings (PDFs in `readings/`)

| BibTeX Key | PDF filename in `readings/` |
|------------|----------------------------|
| `vaccari2020` | `vaccari-chadwick-2020-deepfakes-and-disinformation-exploring-the-impact-of-synthetic-political-video-on-deception.pdf` |
| `chadwick2011` | `Andrew_Chadwick_Hybrid_Media_System_ECPR_August_9th_2011.pdf` |
| `gilardi2025` | `2409.03500v3.pdf` |
| `mattis2025` | `25448-PROOF-2.Mattis.4-ID25448.GenAI.IJoC-Article.10-29-25.dor.FINAL-paginated.pdf` |
| `munoriyarwa2025` | `Generative AI and the Future of News  Examining AI s Agency  Power  and Authority.pdf` |
| `ferrara2026` | `Emilio 2026 - The Generative AI Paradox - GenAI and the erosion of trust, the corrosion of information verification, and the demise of truth.pdf` |
| `dubey2026` | `Dubey et al. 2026 - Investigating perceived trust and utility of balanced news chatbots among individuals with varying conspiracy beliefs.pdf` |
| `gillespie2026` | `Gillespie et al. 2026 - AI red-teaming is a sociotechnical problem.pdf` |
| `hameleers2026` | `Hameleers and van der Meer 2026 - Beyond textual disinformation - Compar ... nerated and video-based visual disinformation across different issues.pdf` |
| `pewresearch2025` | `PS_2025.9.15_AI-and-its-impact_report.pdf` |
| `schroeder2026` | `Schroeder et al. 2026 - How malicious AI swarms can threaten democracy.pdf` |
| `hackenburg2025` | `science.aea3884.pdf` |
| `czarnek2025` | `climate change AI dialogues.pdf` |
| `cosenza2025` | `EserciziIA-CopiaStampa.pdf` |

### Referenced Readings (NOT yet in `readings/`)

These readings are referenced in the course plan and have BibTeX entries in `references.bib`, but their PDFs have not been added to `readings/` yet. Do NOT use their content for slide generation until the instructor provides the PDFs.

| BibTeX Key | Article |
|------------|---------|
| `morosoli2025` | Morosoli et al. (2025) — Attitudes toward GenAI in journalism |
| `giglietto2020` | Giglietto et al. (2020) — Coordinated manipulation in Italian elections |
| `marino2024` | Marino & Giglietto (2024) — LLMs-in-the-loop pipeline |
| `terenzi2025` | Terenzi & Giglietto (2025) — AI Slop and synthetic virality |

### How to Map PDF Content to Slide Elements

| Content Type | Slide Element |
|-------------|---------------|
| Theoretical frameworks | Content slides with diagrams or highlight boxes |
| Empirical results | Tables, large stat callouts, R charts with `theme_uniurb()` |
| Definitions | `.orange-box` or `.highlight-box` |
| Author quotes | Blockquote with attribution |
| Methodology | Step-by-step numbered list or flow diagram |
| Open questions | `.callout-note` with "Da discutere" in lab/workshop sessions |
| Extended detail | Speaker notes (expand on concepts from the PDFs here) |

### Useful Commands

```bash
# Render a single presentation
quarto render slides/week1-mon-introduction.qmd

# Render all presentations
quarto render

# Live preview
quarto preview slides/week1-mon-introduction.qmd

# Check which PDFs are available
ls -la readings/
```

---

## DO NOT

1. **DO NOT** generate all 13 sessions at once. Proceed one at a time.
2. **DO NOT** use colors outside the DISCUI palette.
3. **DO NOT** create slides with more than 8 lines of text.
4. **DO NOT** skip speaker notes.
5. **DO NOT** use emoji in slide body (only in the closing slide for contact info).
6. **DO NOT** invent content not present in the course plan or readings.
7. **DO NOT** insert placeholder images (`![](placeholder.png)`). If an image is needed, describe it in an HTML comment and leave the space.
8. **DO NOT** use `{.section-slide}` — use `{background-color="#C5612E"}` instead.
9. **DO NOT** write slide content in English (except technical terms). All output is Italian.
10. **DO NOT** create text-wall slides. One concept per slide.
11. **DO NOT** use `#` (h1) for section dividers — always use `##` (h2) to keep all slides flat and avoid reveal.js 2D navigation/looping issues.
12. **DO NOT** present data, quotes, frameworks, or findings from readings without a visible `[@bibtexkey]` citation on the slide. Every slide that uses content from a reading MUST include at least one Quarto citation (e.g., `[@ferrara2026]`) in the visible body text — not only in speaker notes. This ensures proper attribution and populates the References slide.
