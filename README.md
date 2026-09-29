# IA Generativa e Media

Slide del corso **IA Generativa e Media** (6 CFU, 36 ore), Prof. Fabio Giglietto, DISCUI · Università degli Studi di Urbino Carlo Bo.

Le slide sono online: **[fabiogiglietto.github.io/genai-media-course](https://fabiogiglietto.github.io/genai-media-course/)**

## Anni accademici

| A.A. | Periodo | Slide | Scheda |
|------|---------|-------|--------|
| **2026/2027** (in corso) | 7 ottobre – 25 novembre 2026 | [2026-27](https://fabiogiglietto.github.io/genai-media-course/2026-27/) | [Scheda insegnamento](https://www.uniurb.it/syllabi/270147) |
| 2025/2026 | 23 febbraio – 1 aprile 2026 | [2025-26](https://fabiogiglietto.github.io/genai-media-course/2025-26/) | [Scheda insegnamento](https://www.uniurb.it/insegnamenti-e-programmi/267958) |

## Struttura del repository

- `2026-27/`, `2025-26/`: sorgenti e istruzioni di ciascun anno (`<anno>/CLAUDE.md`)
- `_extensions/uniurb/`, `assets/`, `R/`, `references.bib`, `apa.csl`, `shared/`: risorse comuni a tutti gli anni
- `_output/`: sito generato, pubblicato su GitHub Pages
- `_output/slides/`: reindirizzamenti dai vecchi indirizzi 2025/26 (da non cancellare)

Si genera solo l'anno in corso; gli anni passati restano congelati. Le regole complete sono in [`CLAUDE.md`](CLAUDE.md).

```bash
quarto render   # genera l'anno in corso in _output/<anno>/
```

Realizzate con [Quarto](https://quarto.org/) reveal.js e tema DISCUI.

## Licenza

I contenuti delle slide sono rilasciati sotto licenza [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).
