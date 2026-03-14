# Week 3 Recap: Bruna Paroni Guest Seminar (March 9–11, 2026)

**Status:** ✅ Completed  
**Sessions:** 3 (Mon–Wed, 6 hours total)  
**Speaker:** Bruna Paroni (PhD candidate, 3rd year; TA for Internet Studies and IA Generativa e Media; supervisor: Prof. Fabio Giglietto)  
**Research focus:** Political communication and polarization, political disinformation and elections, with a focus on the Brazilian context.

---

## Session Overview

### Session 1 — Mon Mar 9: Questionnaire Results + Introduction to the Research

**Questionnaire results (course pre-survey):**

- Students' formation/background was presented
- ChatGPT and Gemini are the most-used models among students
- Frequency and use patterns of generative AI were discussed
- Sentiment toward GenAI was analyzed
- A comparison between American public opinion and UniUrb students was shown
- Perceptions of risks and benefits, impact on human capabilities, and ability to recognize AI-generated content were discussed
- Differences between the CPO (Comunicazione e Pubblicità per le Organizzazioni) and CoDIC (Comunicazione Digitale e Informazione per le Comunità) student cohorts were highlighted

**Research framing:**

- Starting point: over 80,000 news links shared on Facebook during Brazilian elections (2018 and 2022)
- Core research questions: How to isolate political debate in the information flow? How does public opinion orient itself? Which stories dominated the electoral debate?
- Introduction to the question: How to integrate LLMs into academic research?

### Session 2 — Tue Mar 10: LLMs-in-the-loop Methodology (Deep Dive)

This was the core methodological session, based on:

> Marino, G., & Giglietto, F. (2024). Integrating Large Language Models in Political Discourse Studies on Social Media. *Sociologica*, 18(2), 87–107. https://doi.org/10.6092/issn.1971-8853/19524

**Key concept: LLMs-in-the-loop**

AI does not work alone in a vacuum — it is embedded in a process where human oversight is fundamental for:

- **Training:** Teaching the model what is "political" and what is not
- **Validation:** Human control over LLM outputs
- **Traceability:** Every AI decision must be justified and validated by the researcher
- **Hallucination mitigation:** Human supervision prevents the AI from inventing non-existent correlations

**The 4-step pipeline (from raw link to final label):**

1. **Data Collection** — 84,874 article links collected from Facebook (2018 and 2022 election campaigns) via Meta URL Shares Dataset
2. **Binary Classification (supervised)** — Political vs. Non-political. Nearly 5,000 links manually classified by humans. That human work trained the automatic classifier (fine-tuned OpenAI Curie model via API, not chatbot). The definition of "political" was broad: direct political references, "politicizable" topics (protests, reforms, rights), and content with potential social impact on governance and collective norms
3. **Clustering** — Texts grouped by semantic proximity using embeddings (text → numerical vectors capturing semantic meaning; similar texts become nearby vectors). 199 clusters for 2018, 198 for 2022. Trade-off between granularity and interpretability
4. **Labeling** — GPT-4-turbo received a sample of links per cluster and generated short descriptive labels. 397 total clusters labeled in bulk via API. Cost: $30 for mapping ~400 Italian political narratives

**Key distinctions emphasized:**

- **Chatbot vs. API:** API enables scale (84,874 items), reproducibility (same parameters every call), and traceability (all I/O logged). Chatbot cannot do any of this
- **Embeddings explained:** LLMs transform words into coordinates in an n-dimensional space. This transformation is called *embedding*. Text becomes a numerical vector capturing semantic meaning — similar texts become nearby vectors
- **Why fine-tuning?** Fine-tuning allows the LLM to recognize the Italian political context specifically
- **Why Italian experts?** Political classification is an interpretive act — the same immigration story carries different political weight in different contexts

**Validation (two levels):**

*Cluster validation:* Pairs of clusters were analyzed with their labels and a sample of articles each. Similarity scale:

- Level 0 — No relationship: completely different topics
- Level 1 — Broad thematic coherence: same political area, but different actors/events/places
- Level 2 — Same actors or institutions, but different journalistic stories
- Level 3 — Same journalistic story: same actors, events, and narratives about one specific event

If many pairs score level 2–3, the clustering over-fragmented. If most are level 0–1, the clustering worked well.

*Label validation:* Each label assessed on 4 criteria:

- Thematic alignment: does the label cover the main topic?
- Implications: does it suggest coherent connotations?
- Coverage: not too broad, not too narrow?
- Contextual alignment: does it reflect the Italian context?

Scale: ✓ GOOD FIT / ⚠ PARTIAL FIT / ✗ MISFIT

**The expertise paradox:** The model correctly identified politician Amedeo Matacena (who was missed by the researchers), demonstrating how LLM-in-the-loop pipelines can augment research capabilities.

**Conclusion:** LLMs enhance the ability to map political discourse on social media at scale, but the human factor remains indispensable at every step.

### Session 3 — Wed Mar 11: In-Class Workshop ("LLMs-in-the-loop in classe")

Students replicated a simplified version of the pipeline in groups using Google Gemini (with "Thinking" mode enabled).

**Workshop Google Sheet:** https://docs.google.com/spreadsheets/d/1hISK_wIKRpUy_E2iwEfVLBSGo3_dW6K_QhCjT7HWYu8/edit?gid=1629854553#gid=1629854553

The sheet contains 4 tabs: `ISTRUZIONI - ATTIVITÀ 1`, `ATTIVITÀ 1`, `ISTRUZIONI - ATTIVITÀ 2`, `ATTIVITÀ 2`.

**Activity 1 — Binary Classification (Human + AI):**

- Groups of 3–6 students, each creating a copy of the sheet
- 20 Italian news headlines from the 2018/2022 electoral period
- Broad concept of "political" adopted (local politics, politically relevant events like a migrant shipwreck, birthday wishes to a politician, economic news)
- Step 1: Individual manual classification as POLITICO / NON POLITICO / N/A (no Google or chatbot allowed)
- Step 2: Group consensus in the `group_agreement` column
- Step 3: Repeat classification with Gemini using a provided prompt (role: Italian political communication research assistant; classify each headline)
- Step 4: Compare group consensus vs. Gemini results; if discrepancies exist, refine the prompt (prompt fine-tuning) using a more structured format with examples and explicit output format
- Step 5: Analyze — What changed? What guided the final decision? Was the group autonomous, or did Gemini influence the process?

**Activity 2 — Clustering + Labeling + Validation:**

- Ask Gemini to group the political headlines into thematic clusters
- For each cluster, ask Gemini for a descriptive label (max 5 words)
- Validate each label using the 4 criteria (thematic alignment, coherence, coverage, context) with the good fit / partial fit / misfit scale
- Reflection: What information was missing for confident validation?

**Discussion prompts used in class:**

- Which was the hardest case to validate?
- When the group disagreed on a headline classification, what guided the final decision?
- Looking at the entire activity: at how many points did the group make a decision vs. Gemini?

---

## Workshop Dataset (20 News Headlines)

The following 20 Italian news headlines were used in Activity 1. Students classified each as POLITICO / NON POLITICO / N/A. The first row was pre-filled as an example (with 3 coders shown: two said "non politico", one said "politico"; group consensus was "non politico").

| # | Headline (alltext) |
|---|---|
| 1 | Coronavirus, nuovo focolaio a Ostia: chiuso il terzo ristorante in pochi giorni. Un altro ristorante chiuso per Covid a Ostia. L'ultimo in ordine di tempo è Michelino Fish all'Infernetto dopo che una cameriera è stata trovata positiva al test del... |
| 2 | Le combinazioni alimentari che curano il corpo e la mente. Ecco le combinazioni alimentari dai potenti effetti terapeutici per la nostra salute. Un mix di benedici capaci di curare mente e corpo. Provare per credere |
| 3 | Nuovo film Pio e Amedeo, riprese nel foggiano. Si cercano comparse. Si intitolerà "Belli ciao" il prossimo film di Gennaro Nunziante, che vedrà come protagonisti Pio & Amedeo. |
| 4 | Misterioso monolite trovato nello Utah \| Passione Astronomia. L'equipaggio di un elicottero ha scoperto un misterioso monolite di metallo nel profondo del deserto dello Utah. Un tributo a "2001: Odissea nello spazio"? |
| 5 | Milano, confermato il licenziamento della mamma dipendente dell'Ikea con un figlio disabile a casa. Marica Ricutti, separata con due figli, di cui uno disabile, fu licenziata dal negozio di Corsico del colosso svedese per il mancato rispetto dei turni di lavoro. Il giudice del lavoro: «I fatti consentono il provvedimento disciplinare espulsivo» |
| 6 | Dal 6 aprile apriremo a pranzo e a cena. Non abbiamo più nulla da perdere: il grido del Mio Italia - Secolo d'Italia. Dal 6 aprile apriremo a pranzo e a cena: il grido dei ristoratori del Mio Italia. Bianchini e Parisella: neanche con Draghi si vede luce |
| 7 | E' italiano l'inventore del metodo: con soli 2 litri di benzina l'auto fa 100Km. E' stato il Tg regionale della lombardia a divulgare questo sistema che permette di fare 100 km con soli 2 litri di carburante. Un sistema semplicemente banale. Ma è possibile che nessun produttore di automobili ci abbia mai pensato prima? Il metodo consiste semplicemente nello spostare la trazio... |
| 8 | Il messaggero on TikTok. #pasqualepaki4 #novax #nogreenpass |
| 9 | Melanzane sarde: al forno e senza bisogno di grigliarle prima!. Le melanzane sarde sono un piatto facilissimo da realizzare, pronto in pochi passaggi. Sfiziose e gustosissime, cuociono direttamente in forno senza... |
| 10 | Daniele De Martino - Se ti ho vicino - Official Video 2020. Daniele De Martino - Se ti ho vicino - Official Video 2020 ▶ Seguimi su Instagram... ▶ Seguimi su Tik Tok... |
| 11 | Proroghe abilitazioni alla guida: Motorizzazione accoglie i suggerimenti Unasca. Prorogati per i 90 giorni successivi alla dichiarazione di cessazione di stato di emergenza nazionale i documenti in scadenza tra il 31 gennaio e il 31 luglio 2020. È la novità compresa nella Circolare 12058 firmata giovedì 30 aprile dal neo Direttore generale della Motorizzazione Civile Alessand... |
| 12 | Dopo l'unita' d'Italia il Piemonte chiuse tutte le scuole del sud per renderlo schiavo e colonizzato!. Nel 1734 il Sud andò a Carlo III di Borbone che, avendo in dote 28 milioni di ducati, pensò bene ricomporre lo Stato attraverso la cultura. Nacque così il '700 napoletano. La scuola fu l'istituzio… |
| 13 | Domani consegna a Speranza delle firme per le cure domiciliari - RomaDailyNews. Domani consegna a Speranza delle firme per le cure domiciliari - L'Unione per le Cure, i Diritti e le Libertà, associazione di cittadini a sostegno della... |
| 14 | Giorgia Meloni meglio di Almirante, sfonda il 10% nei sondaggi e si trasferisce nel suo ufficio. ... |
| 15 | Immagine: Giorgio Napolitano fascista \| profumo di donna. Trovato su Google da cordialdo.wordpress.com |
| 16 | TANGENTI SULLA TAV, ARRESTATI FIGLI DI POLITICI E DI ALTI PAPAVERI. ECCO CHI SONO I PARASSITI DI QUESTO STATO INFAME E PARASSITA - News24H. TANGENTI SULLA TAV, ARRESTATI FIGLI DI POLITICI E DI ALTI PAPAVERI. ECCO CHI SONO I PARASSITI DI QUESTO STATO INFAME E PARASSITA Spiccano due nomi illustri nell'inchiesta della Procura di Roma su appalti e... |
| 17 | Colleferro, i fratelli Bianchi respingono le accuse: «Willy? Non lo abbiamo toccato» - Open. I due davanti al gip: «Siamo dispiaciuti e distrutti perché accusati di un omicidio che non abbiamo commesso». Escluso al momento il movente razziale e politico |
| 18 | Il Vaticano fa l'elemosina agli occupanti abusivi. Purtroppo non aveva bevuto, il cardinale Krajewski. «Non l'ho fatto perché sono ubriaco», ha garantito l'elemosiniere del Papa dopo avere personalmente tolto i sigilli ai contatori della luce di un palazzo occupato del centro di Roma. Dunque non aveva l'attenuante alcolica, dunque era... |
| 19 | Obbligo green pass a scuola, la protesta dei dirigenti scolastici: "Altro aggravio di lavoro. Non siamo capri espiatori e nemmeno un'autorità sanitaria" - Orizzonte Scuola Notizie. L'estensione del green pass obbligatorio a scuola, per il personale scolastico, come dispone l'ultimo decreto legge del Governo, riserva un "regalo indesiderato" per i dirigenti scolastici, ovvero la responsabilità del controllo della certificazione verde. |
| 20 | Zombie, la cover di Miley Cyrus è stupenda. I Cranberries: "Avrebbe colpito Dolores". La cantante si è esibita al Whiskey A Go Go di Los Angeles nell'ambito del festival #SaveOurStages, dove ha eseguito un'apprezzatissima cover di Zombie, storico brano dei Cranberries del 1994... |
| 21 | Конвоїри викинули тіло письменниці Старицької-Черняхівської в степах Казахстану - Українці всього світу. (Ukrainian-language article — used as N/A test case) |

**Spreadsheet columns for Activity 1:** `alltext`, `<nome coder 1>` through `<nome coder 6>`, `consenso_gruppo`, `gemini`, `decisione finale`, `note`

**Note on the dataset:** The headlines are a carefully curated mix including clearly political items (e.g., #14 Meloni, #16 TAV corruption), clearly non-political items (e.g., #9 recipe, #10 music video), ambiguous/borderline cases (e.g., #1 Covid restaurant closure, #5 Ikea firing of disabled worker's mother, #8 #novax #nogreenpass TikTok), and a foreign-language item (#21, Ukrainian) that should be classified as N/A. This mix forces students to operationalize the broad definition of "political" and confront boundary cases where group members will disagree.

### Activity 2 — Clustering + Labeling + Validation (Instructions)

> **Instructions (from sheet "ISTRUZIONI - ATTIVITÀ 2"):**
>
> - Export the "ATTIVITÀ 1" sheet as .csv. Upload to Gemini with "Thinking" mode and ask the chatbot to group the political news by semantic proximity. Example prompt:
>
> *"Sei un assistente di ricerca specializzato in comunicazione politica italiana. Ti darò una lista (file in .csv) di notizie politiche del periodo elettorale 2018 e 2022. Raggruppale in cluster tematici. Per ciascun cluster, assegna un'etichetta di massimo 5 parole. Restituisci tutto in una tabella riportando anche il testo originale della colonna 'alltext'."*
>
> - Paste results in the "ATTIVITÀ 2" sheet under `label_gemini (max 5 parole)`. Do you agree? Is it correct?
>
> - Validate the labels using the 4 criteria: thematic alignment, implications, coverage, contextual alignment.
>
> - Group discussion: Keep the labels or refine the model further?

**Spreadsheet columns for Activity 2:** `alltext`, `label (max 5 parole)`, `validazione_label_gruppo`, `note`

---

## Relevance to Upcoming Weeks

### Week 4 (Mar 16–18): Terenzi Seminar + Project Launch

The Paroni seminar established the **methodological foundation** that students will apply directly:

- **Mon Mar 16:** Terenzi seminar on AI Slop & Synthetic Virality uses similar analytical frameworks but applied to Italian Facebook communities and AI-generated images rather than political news
- **Tue Mar 17 — Project Launch:** Students form groups and develop research questions. The LLMs-in-the-loop pipeline from the Paroni seminar is the **core methodology** for the group project (analyzing AI Slop reception). Groups will apply the same 4-step pipeline (collection → classification → clustering → labeling) plus validation
- **Wed Mar 18 — Lab:** Data collection begins. Students use Meta Content Library or TikTok Research API, applying the data collection principles discussed in Paroni's Step 1

### Week 5 (Mar 23–25): Analysis & Validation

- **Mon Mar 23:** AI-assisted content analysis using Gemini mirrors the workshop activity from Paroni's Session 3 but at larger scale with real project data
- **Tue Mar 24:** Validation session directly applies the validation framework (cluster coherence levels 0–3, label fit criteria) taught by Paroni. Inter-coder reliability with AI as "coder" operationalizes the chatbot-vs-API distinction
- **Wed Mar 25:** Group consultations can reference the Paroni pipeline as the shared methodological vocabulary

### Key Methodological Bridges

| Paroni Seminar Concept | Project Application (Weeks 4–6) |
|---|---|
| Binary classification (political/non-political) | Classification of posts as AI-generated / not AI-generated |
| Broad definition of "political" | Broad definition of "AI Slop" (engagement bait, synthetic images, etc.) |
| Fine-tuned model via API | Gemini API prompting with structured prompts |
| Embedding-based clustering | Gemini-assisted thematic grouping of posts/comments |
| Cluster validation (levels 0–3) | Validating AI-identified content categories |
| Label validation (4 criteria + 3-point scale) | Validating AI-generated thematic labels |
| Human-in-the-loop at every step | Parallel human coding for inter-coder reliability |
| Chatbot vs. API distinction | Students use Gemini (chatbot) but understand API advantages |
| The expertise paradox | AI may catch patterns humans miss — and vice versa |

---

## Materials

- **Slides:** `seminario_Bruna_Paroni_LLMs-in-the-loop.pptx` (59 slides)
- **Workshop sheet:** [Google Sheet](https://docs.google.com/spreadsheets/d/1hISK_wIKRpUy_E2iwEfVLBSGo3_dW6K_QhCjT7HWYu8/edit?gid=1629854553#gid=1629854553) — also available as `genai_dataset.xlsx` (4 tabs: instructions + data for Activity 1 and Activity 2)
- **Reference paper:** Marino, G., & Giglietto, F. (2024). Integrating Large Language Models in Political Discourse Studies on Social Media. *Sociologica*, 18(2), 87–107. https://doi.org/10.6092/issn.1971-8853/19524
