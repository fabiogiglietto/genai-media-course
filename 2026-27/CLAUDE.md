# CLAUDE.md — A.A. 2026/2027

Year-specific instructions. Shared conventions (palette, slide types, text density, speaker notes, DO NOT list) are in the root `CLAUDE.md`: follow both.

**Course:** IA Generativa e Media (Generative AI and the Media), 6 CFU, 36 hours, 18 sessions × 2 h.
**Degrees:** LM-59 R Comunicazione e Pubblicità per le Organizzazioni (main) and LM-92 R CoDiC (shared), first-year MA students.
**Dates:** 7 October – 25 November 2026. Wed and Thu 11:00–13:00, Fri 9:00–11:00. No classes 14–16 October; Thu 22 October is Career Day. 2–7 November is a mid-term test week (lessons continue).
**Moodle:** <https://blended.uniurb.it/moodle/course/view.php?id=29666>
**Official syllabus:** <https://www.uniurb.it/syllabi/270147>

---

## What changed from 2025/26

- The focus is **agentic AI**: agents as tools, as research assistants, and as a source of risk.
- The group project studies **AI-generated authority personas** (fake rabbis, a monk, nuns, grandmothers, doctors) on **Instagram and TikTok** that sell products, in collaboration with Massimo Terenzi (LUISS). Students code only Italian and English content.
- The **LLMs-in-the-loop** method stays, with the validation protocol of Marino & Giglietto (2024).
- Organising idea for modules 1–2: Ferrara's **synthetic reality** (content, identity, interaction, institutions).
- A **detection test with confidence ratings** is given in session 1 and repeated in session 18 (calibration of students' own judgement).

## Learning outcomes (Dublin descriptors, as published)

- **Knowledge and understanding:** principles of generative AI and its media applications; generative models vs. AI agents (goals, tools, planning loops, levels of autonomy, human oversight) and why LLM outputs diverge from human intentions; synthetic reality as layers; synthetic personas and parasocial relations; deceptive information operations and their three dimensions; visual persuasion drivers and trust transfer; recommendation and amplification by platforms, users and LLMs; provenance and disclosure norms (AI Act Art. 50, DSA, C2PA), including the difference between disclosing *what* a system is and *what it is trying to do*.
- **Applying:** recognise likely synthetic content and personas; trace the chain from persona to shop; turn a typology into a codebook; code audience responses; run an LLMs-in-the-loop pipeline with blind human coding, reconciliation and Cohen's kappa; document an evidence chain.
- **Making judgements:** evidence vs. suggestion (candidate vs. proof, observed vs. reconstructed, persona vs. operator); harms (epistemic, economic, social-normative) and where commerce ends and fraud begins; which disclosures protect audiences and who should prevent harm; stereotypes (including antisemitic ones) turned into authority; own detection confidence vs. accuracy; limits of one's cultural knowledge when validating; what to delegate to agents.
- **Communication:** explain technical concepts to non-specialists; structured research report with transparent methods, limits and AI-use declaration; reconcile coding disagreements; visualise evidence; argue at the right level of certainty.
- **Learning skills:** keep up with generative and agentic AI; assess new tools and studies, including their status (peer-reviewed, preprint, policy brief); transfer methods to new contexts.

## Sessions

| # | File | Date | Title | Reading | Type |
|---|------|------|-------|---------|------|
| 1 | `s01-introduzione.qmd` | Wed 7 Oct | Introduzione: la realtà sintetica | ferrara2026 | Lecture + admin |
| 2 | `s02-modelli-agenti.qmd` | Thu 8 Oct | Dai modelli agli agenti | esposito2026 | Lecture |
| 3 | `s03-workshop-agenti.qmd` | Fri 9 Oct | Workshop: lavorare con gli agenti (Gemini, NotebookLM) | — | Workshop + TWIAI |
| 4 | `s04-personaggi-sintetici.qmd` | Wed 21 Oct | Personaggi sintetici e media parasociali | boyd2026 | Lecture + TWIAI |
| 5 | `s05-persuasione.qmd` | Fri 23 Oct | Driver di persuasione e trasferimento di fiducia | giglietto2026seduction | Lecture |
| 6 | `s06-trasparenza-regole.qmd` | Wed 28 Oct | Trasparenza e regole (AI Act art. 50, DSA; dibattito) | rauchfleisch2026, schiffrin2026 | Lecture |
| 7 | — | Thu 29 Oct | Seminario ospite: Massimo Terenzi (no slides) | pilo2026 | Guest |
| 8 | `s08-operazioni-ingannevoli.qmd` | Fri 30 Oct | Operazioni informative ingannevoli, danni, catene di evidenze | marino2026zombie | Lecture + TWIAI |
| 9 | `s09-validazione.qmd` | Wed 4 Nov | Il protocollo di validazione | marino2024 | Workshop |
| 10 | `s10-lancio-progetto.qmd` | Thu 5 Nov | Lancio del progetto | — | Workshop |
| 11 | `s11-codifica-personaggi.qmd` | Fri 6 Nov | Codifica dei personaggi e percorsi profilo → negozio | — | Lab + TWIAI |
| 12 | `s12-codebook-pilota.qmd` | Wed 11 Nov | Codebook, prompt e codifica pilota | — | Lab |
| 13 | `s13-codifica-cieco.qmd` | Thu 12 Nov | Codifica umana in cieco e riconciliazione | — | Lab |
| 14 | `s14-gemini-kappa.qmd` | Fri 13 Nov | Codifica con Gemini, kappa, matrice di confusione | — | Lab + TWIAI |
| 15 | `s15-pubblico-commenti.qmd` | Wed 18 Nov | Il pubblico nei commenti | wack2026 | Lab |
| 16 | `s16-danni-responsabilita.qmd` | Thu 19 Nov | Analisi: danni, responsabilità, matrice affermazioni-evidenze | — | Workshop |
| 17 | `s17-scrittura.qmd` | Fri 20 Nov | Laboratorio di scrittura e consultazioni | — | Workshop + TWIAI |
| 18 | `s18-chiusura.qmd` | Wed 25 Nov | Confronto tra gruppi, post-test, questionario finale | — | Closing |

"This Week in AI" (TWIAI) opens the first session of each calendar week that has a free slot; in session 1 it is skipped for the admin block. Never invent news: leave a commented placeholder for the instructor.

## First-day administrative slides (s01 only)

Il corso in sintesi · Panoramica (6 moduli, 18 incontri, 3 a settimana) · Struttura dei moduli (table) · Valutazione frequentanti (Moodle enrolment by Fri 9 Oct; at least 13 of 18 sessions; group project 75%, max 23,25; participation 10%, max 3,1, about 0,17 per session; oral 15%, max 4,65, discussion of the project) · Non frequentanti (oral 100% on five open-access readings listed in the official syllabus; they do NOT use Moodle) · Rilevazione presenze (include `_attendance.qmd`) · Giustificazioni (forum, within 2 days) · Policy IA generativa (includes agents: allowed with a log of what the agent did and what was checked by hand; forbidden: delegating actions on the studied accounts, coding languages the group cannot validate) · Spazio Moodle · Questionario primo giorno and detection test.

## Readings (bib keys in root `references.bib`)

Required: `ferrara2026`, `esposito2026`, `boyd2026`, `giglietto2026seduction`, `rauchfleisch2026` (preprint), `schiffrin2026` (policy brief), `pilo2026` (journalism), `marino2026zombie`, `marino2024`, `wack2026`.
Recommended (examples): `fattorini2026`, `sbarainifontes2026`, `alizadeh2026`, `orlando2025`, `schroeder2026`, `hackenburg2025`, `hameleers2026`.

Full texts are in the MINE Google Drive folders (not in this repo). Before writing a deck, read the full text of its readings, or a verified digest, and cite page or section in the speaker notes. Notes on content:

- **Wack & Prochaska** is an experiment: credulous / incredulous / mixed comments were written by the researchers. Use their categories for the comment codebook, not their method.
- **Rauchfleisch & Jungherr** tested live chatbot conversations in the UK, not labels in social feeds: say so when applying it to personas.
- **Schiffrin et al.** defines deepfake fraud around real people: invented personas selling legal goods are a grey zone (good for debate).
- **Synthetic seduction** was about Facebook gambling groups; students adapt its seven drivers to personas.
- **Pilo (Facta)**: the rabbi personas sell wealth, "secret knowledge" and inverted antisemitic stereotypes. Content note required; never reproduce the tropes on slides beyond what is needed to analyse them.

## Group project (modules 4–6)

Three research questions, one per dimension of deceptive operations (Marino et al. 2026):
- **RQ1 Fabricated authority (identity, affordances):** how authority is built and turned into a sale; shared commercial infrastructure across markets.
- **RQ2 Persuasion (content):** drivers and values used to transfer trust from persona to offer.
- **RQ3 Audience (participation):** credulous / incredulous / uncertain / AI-aware-but-accepting comments; likely synthetic comments.

Groups: 3 × 3 matrix (strand × persona family: religious; elders; medical/wellness). Validation: pilot until agreement with a "98 = non so" code; blind coding in pairs (one more, one less experienced coder); reconciliation meeting; Gemini on the full corpus with a documented prompt; Cohen's kappa per variable, refine below 0.60.
**Attribution:** from Marino & Giglietto (2024, §3–4) come only expert coders, pilot training, pairs of one more and one less experienced coder coding independently, alignment and concluding meetings to resolve discrepancies, and a 98 level for ambiguous cases. The paper does NOT use Cohen's kappa, a 0.60 threshold or Gemini: those are the course's additions. Never cite `marino2024` for kappa.

Rule for all decks: every claim tied to a reading must be checked against the full text (not the kasten note). Pilo (2026) documents only the rabbi personas; the other persona families come from Massimo Terenzi's research. Ethics: observe and archive only (no following, commenting, messaging, carts or purchases); pseudonymise commenters.

The corpus (Instagram and TikTok posts and comments) is prepared by the instructor. Do not describe its size or content in slides until it exists.
