/**
 * Setup Coding Sheet for AI Slop Project
 *
 * IA Generativa e Media — A.A. 2025/2026
 *
 * HOW TO USE:
 * 1. Open the Google Sheet with the metadata (the one students will copy)
 * 2. Extensions > Apps Script
 * 3. Paste this entire script, replacing any existing code
 * 4. Click Run > setupCodingSheet
 * 5. Authorize when prompted
 *
 * The script will create all the tabs and structure needed for the coding phases.
 * Each group copies the sheet and customizes Step 2 categories.
 */

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

const COLORS = {
  discuiPrimary: '#E06029',   // Orange — Gemini sections
  uniurbBlue: '#294973',      // Blue — Human coding sections
  green: '#2E7D32',           // Green — Final decision sections
  lightOrange: '#FDE8D0',     // Light orange background
  lightBlue: '#D6E4F0',       // Light blue background
  lightGreen: '#D5ECD4',      // Light green background
  headerBg: '#F2F2F2',        // Default header background
  separator: '#E0E0E0',       // Separator column
  white: '#FFFFFF',
};

const BINARY_OPTIONS = ['AI slop', 'Non AI slop', 'Incerto'];
const CERTAINTY_OPTIONS = ['Alta', 'Media', 'Bassa'];
const BINARY_FINAL_OPTIONS = ['AI slop', 'Non AI slop'];

// Placeholder categories — each group replaces these with their own
const THEMATIC_PLACEHOLDER = [
  'Categoria 1',
  'Categoria 2',
  'Categoria 3',
  'Categoria 4',
  'Categoria 5',
  'Altro',
];

const MAX_CODERS = 6;

// ---------------------------------------------------------------------------
// Main setup function
// ---------------------------------------------------------------------------

function setupCodingSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  // Rename first sheet to DATI if it isn't already
  const firstSheet = ss.getSheets()[0];
  if (firstSheet.getName() !== 'DATI') {
    firstSheet.setName('DATI');
  }

  // Get data dimensions from DATI
  const dataSheet = ss.getSheetByName('DATI');
  const lastRow = dataSheet.getLastRow();
  const numPosts = lastRow - 1; // minus header

  // Create tabs (delete if they already exist to allow re-running)
  const tabNames = [
    'STEP 1 — AI Slop o No?',
    'STEP 2 — Classif. Tematica',
    'CODEBOOK',
    'PROMPT',
    'ISTRUZIONI',
  ];

  tabNames.forEach(name => {
    const existing = ss.getSheetByName(name);
    if (existing) ss.deleteSheet(existing);
  });

  // Build each tab
  const step1 = createStep1Sheet(ss, dataSheet, numPosts);
  const step2 = createStep2Sheet(ss, numPosts);
  const codebook = createCodebookSheet(ss);
  const prompt = createPromptSheet(ss);
  const instructions = createInstructionsSheet(ss);

  // Reorder tabs
  ss.setActiveSheet(instructions);
  ss.moveActiveSheet(1);
  ss.setActiveSheet(dataSheet);
  ss.moveActiveSheet(2);
  ss.setActiveSheet(step1);
  ss.moveActiveSheet(3);
  ss.setActiveSheet(step2);
  ss.moveActiveSheet(4);
  ss.setActiveSheet(codebook);
  ss.moveActiveSheet(5);
  ss.setActiveSheet(prompt);
  ss.moveActiveSheet(6);

  // Set ISTRUZIONI as active sheet when opening
  ss.setActiveSheet(instructions);

  SpreadsheetApp.flush();
  Browser.msgBox(
    'Setup completato!',
    'Sono stati creati ' + tabNames.length + ' tab per il coding del progetto.\\n\\n' +
    'Leggete il tab ISTRUZIONI per iniziare.',
    Browser.Buttons.OK
  );
}

// ---------------------------------------------------------------------------
// STEP 1 — Binary classification: AI Slop o No?
// ---------------------------------------------------------------------------

function createStep1Sheet(ss, dataSheet, numPosts) {
  const sheet = ss.insertSheet('STEP 1 — AI Slop o No?');

  // Column layout (HUMANS FIRST to avoid anchoring bias):
  // A: riga, B: id, C: media_files, D: text
  // E: (separator CODIFICA UMANA)
  // F-K: coder_1..coder_6
  // L: (separator GEMINI)
  // M: gemini_slop, N: gemini_certezza, O: gemini_motivazione
  // P: (separator DECISIONE FINALE)
  // Q: decisione_slop, R: note

  const headers = [
    'riga', 'id', 'media_files', 'testo',
    '',  // separator E — UMANI
  ];

  // Add coder columns first
  for (let i = 1; i <= MAX_CODERS; i++) {
    headers.push('coder_' + i);
  }

  headers.push('');  // separator — GEMINI
  headers.push('gemini_slop');
  headers.push('gemini_certezza');
  headers.push('gemini_motivazione');
  headers.push('');  // separator — FINALE
  headers.push('decisione_finale');
  headers.push('note');

  const totalCols = headers.length;

  // Set headers
  const headerRange = sheet.getRange(1, 1, 1, totalCols);
  headerRange.setValues([headers]);
  headerRange.setFontWeight('bold');
  headerRange.setBackground(COLORS.headerBg);
  headerRange.setHorizontalAlignment('center');

  // Section labels in separator columns
  const sepHuman = 5;    // Column E
  const sepGemini = 5 + MAX_CODERS + 1;  // After coders + 1
  const sepFinal = sepGemini + 4;  // After Gemini's 3 columns + 1

  // Human separator (FIRST)
  sheet.getRange(1, sepHuman).setValue('UMANI')
    .setBackground(COLORS.uniurbBlue)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');
  sheet.setColumnWidth(sepHuman, 30);
  colorColumnRange(sheet, sepHuman, 2, numPosts, COLORS.lightBlue);

  // Human coder columns background
  for (let c = sepHuman + 1; c <= sepHuman + MAX_CODERS; c++) {
    sheet.getRange(1, c).setBackground(COLORS.uniurbBlue).setFontColor(COLORS.white);
  }

  // Gemini separator (SECOND)
  sheet.getRange(1, sepGemini).setValue('GEMINI')
    .setBackground(COLORS.discuiPrimary)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');
  sheet.setColumnWidth(sepGemini, 30);
  colorColumnRange(sheet, sepGemini, 2, numPosts, COLORS.lightOrange);

  // Gemini columns background
  for (let c = sepGemini + 1; c <= sepGemini + 3; c++) {
    sheet.getRange(1, c).setBackground(COLORS.discuiPrimary).setFontColor(COLORS.white);
  }

  // Final decision separator (THIRD)
  sheet.getRange(1, sepFinal).setValue('FINALE')
    .setBackground(COLORS.green)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');
  sheet.setColumnWidth(sepFinal, 30);
  colorColumnRange(sheet, sepFinal, 2, numPosts, COLORS.lightGreen);

  // Final decision columns background
  sheet.getRange(1, sepFinal + 1).setBackground(COLORS.green).setFontColor(COLORS.white);
  sheet.getRange(1, sepFinal + 2).setBackground(COLORS.green).setFontColor(COLORS.white);

  // Pull data from DATI tab
  const dataValues = dataSheet.getRange(2, 1, numPosts, dataSheet.getLastColumn()).getValues();
  const dataHeaders = dataSheet.getRange(1, 1, 1, dataSheet.getLastColumn()).getValues()[0];

  // Find column indices in DATI
  const idxId = dataHeaders.indexOf('id');
  const idxMediaFiles = dataHeaders.indexOf('media_files');
  const idxText = dataHeaders.indexOf('text');

  // Build data for columns A-D
  const rowData = [];
  for (let r = 0; r < numPosts; r++) {
    rowData.push([
      String(r + 1).padStart(3, '0'),
      dataValues[r][idxId],
      dataValues[r][idxMediaFiles],
      dataValues[r][idxText],
    ]);
  }
  sheet.getRange(2, 1, numPosts, 4).setValues(rowData);

  // Data validation: dropdowns
  const binaryRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(BINARY_OPTIONS, true)
    .setAllowInvalid(false)
    .build();

  const certaintyRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(CERTAINTY_OPTIONS, true)
    .setAllowInvalid(false)
    .build();

  const binaryFinalRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(BINARY_FINAL_OPTIONS, true)
    .setAllowInvalid(false)
    .build();

  // Human coders dropdowns (FIRST)
  for (let i = 1; i <= MAX_CODERS; i++) {
    sheet.getRange(2, sepHuman + i, numPosts, 1).setDataValidation(binaryRule);
  }

  // Gemini dropdowns (SECOND)
  sheet.getRange(2, sepGemini + 1, numPosts, 1).setDataValidation(binaryRule);
  sheet.getRange(2, sepGemini + 2, numPosts, 1).setDataValidation(certaintyRule);

  // Final decision dropdown
  sheet.getRange(2, sepFinal + 1, numPosts, 1).setDataValidation(binaryFinalRule);

  // Column widths
  sheet.setColumnWidth(1, 50);   // riga
  sheet.setColumnWidth(2, 140);  // id
  sheet.setColumnWidth(3, 200);  // media_files
  sheet.setColumnWidth(4, 350);  // text
  for (let i = 1; i <= MAX_CODERS; i++) sheet.setColumnWidth(sepHuman + i, 120);
  for (let c = sepGemini + 1; c <= sepGemini + 2; c++) sheet.setColumnWidth(c, 120);
  sheet.setColumnWidth(sepGemini + 3, 250);  // motivazione
  sheet.setColumnWidth(sepFinal + 1, 140);  // decisione
  sheet.setColumnWidth(sepFinal + 2, 250);  // note

  // Freeze header row and data columns
  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(4);

  // Wrap text in column D
  sheet.getRange(2, 4, numPosts, 1).setWrapStrategy(SpreadsheetApp.WrapStrategy.CLIP);

  return sheet;
}

// ---------------------------------------------------------------------------
// STEP 2 — Thematic classification (AI slop only)
// ---------------------------------------------------------------------------

function createStep2Sheet(ss, numPosts) {
  const sheet = ss.insertSheet('STEP 2 — Classif. Tematica');

  // Same layout as Step 1: HUMANS FIRST, then Gemini, then Final
  const headers = [
    'riga', 'id', 'media_files', 'testo',
    '',  // separator UMANI
  ];

  for (let i = 1; i <= MAX_CODERS; i++) {
    headers.push('coder_' + i);
  }

  headers.push('');  // separator GEMINI
  headers.push('gemini_categoria');
  headers.push('gemini_certezza');
  headers.push('gemini_motivazione');
  headers.push('');  // separator FINALE
  headers.push('decisione_finale');
  headers.push('note');

  const totalCols = headers.length;

  // Set headers
  const headerRange = sheet.getRange(1, 1, 1, totalCols);
  headerRange.setValues([headers]);
  headerRange.setFontWeight('bold');
  headerRange.setBackground(COLORS.headerBg);
  headerRange.setHorizontalAlignment('center');

  const sepHuman = 5;
  const sepGemini = 5 + MAX_CODERS + 1;
  const sepFinal = sepGemini + 4;

  // Human separator (FIRST)
  sheet.getRange(1, sepHuman).setValue('UMANI\n(50)')
    .setBackground(COLORS.uniurbBlue)
    .setFontColor(COLORS.white)
    .setFontWeight('bold')
    .setWrapStrategy(SpreadsheetApp.WrapStrategy.WRAP);
  sheet.setColumnWidth(sepHuman, 40);

  for (let c = sepHuman + 1; c <= sepHuman + MAX_CODERS; c++) {
    sheet.getRange(1, c).setBackground(COLORS.uniurbBlue).setFontColor(COLORS.white);
  }

  // Gemini separator (SECOND)
  sheet.getRange(1, sepGemini).setValue('GEMINI')
    .setBackground(COLORS.discuiPrimary)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');
  sheet.setColumnWidth(sepGemini, 30);

  for (let c = sepGemini + 1; c <= sepGemini + 3; c++) {
    sheet.getRange(1, c).setBackground(COLORS.discuiPrimary).setFontColor(COLORS.white);
  }

  // Final decision separator (THIRD)
  sheet.getRange(1, sepFinal).setValue('FINALE')
    .setBackground(COLORS.green)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');
  sheet.setColumnWidth(sepFinal, 30);

  sheet.getRange(1, sepFinal + 1).setBackground(COLORS.green).setFontColor(COLORS.white);
  sheet.getRange(1, sepFinal + 2).setBackground(COLORS.green).setFontColor(COLORS.white);

  // Placeholder note in row 2
  sheet.getRange(2, 1).setValue('Copiate qui solo le righe classificate come "AI slop" nello Step 1');
  sheet.getRange(2, 1, 1, 4).mergeAcross()
    .setFontStyle('italic')
    .setFontColor('#999999');

  // Dropdown with placeholder categories (groups will customize)
  const thematicRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(THEMATIC_PLACEHOLDER, true)
    .setAllowInvalid(true)  // Allow invalid so groups can change categories
    .build();

  const certaintyRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(CERTAINTY_OPTIONS, true)
    .setAllowInvalid(false)
    .build();

  // Apply to 500 rows (more than enough) starting from row 3
  const maxRows = 500;

  // Human coders (FIRST)
  for (let i = 1; i <= MAX_CODERS; i++) {
    sheet.getRange(3, sepHuman + i, maxRows, 1).setDataValidation(thematicRule);
  }

  // Gemini (SECOND)
  sheet.getRange(3, sepGemini + 1, maxRows, 1).setDataValidation(thematicRule);
  sheet.getRange(3, sepGemini + 2, maxRows, 1).setDataValidation(certaintyRule);

  // Final decision
  sheet.getRange(3, sepFinal + 1, maxRows, 1).setDataValidation(thematicRule);

  // Column widths
  sheet.setColumnWidth(1, 50);
  sheet.setColumnWidth(2, 140);
  sheet.setColumnWidth(3, 200);
  sheet.setColumnWidth(4, 350);
  for (let i = 1; i <= MAX_CODERS; i++) sheet.setColumnWidth(sepHuman + i, 140);
  for (let c = sepGemini + 1; c <= sepGemini + 2; c++) sheet.setColumnWidth(c, 140);
  sheet.setColumnWidth(sepGemini + 3, 250);
  sheet.setColumnWidth(sepFinal + 1, 140);
  sheet.setColumnWidth(sepFinal + 2, 250);

  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(4);

  return sheet;
}

// ---------------------------------------------------------------------------
// CODEBOOK tab
// ---------------------------------------------------------------------------

function createCodebookSheet(ss) {
  const sheet = ss.insertSheet('CODEBOOK');

  const headers = [
    'Categoria',
    'Definizione operativa',
    'Esempi tipici',
    'Casi limite / regole',
    'Note dal pilot',
  ];

  const headerRange = sheet.getRange(1, 1, 1, headers.length);
  headerRange.setValues([headers]);
  headerRange.setFontWeight('bold');
  headerRange.setBackground(COLORS.discuiPrimary);
  headerRange.setFontColor(COLORS.white);

  // Pre-fill with placeholder categories
  const placeholders = THEMATIC_PLACEHOLDER.map(cat => [
    cat,
    'Definire qui...',
    'Elencare 2-3 esempi...',
    'Regole per i casi ambigui...',
    '',
  ]);
  sheet.getRange(2, 1, placeholders.length, 5).setValues(placeholders)
    .setFontColor('#999999')
    .setFontStyle('italic');

  // Add binary classification section at top
  sheet.insertRowBefore(1);
  sheet.getRange(1, 1, 1, 5).mergeAcross()
    .setValue('STEP 1 — Definizione di "AI slop" per la classificazione binaria')
    .setBackground(COLORS.uniurbBlue)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');

  sheet.insertRowAfter(1);
  sheet.getRange(2, 1).setValue('AI slop');
  sheet.getRange(2, 2).setValue('Contenuto multimediale (immagine o video) generato da intelligenza artificiale, tipicamente diffuso come engagement bait...');
  sheet.getRange(2, 3).setValue('Immagini iperrealiste di bambini, animali antropomorfizzati, paesaggi impossibili...');
  sheet.getRange(2, 4).setValue('Se il contenuto sembra autentico ma lo stile è ambiguo → classificare come "Incerto" nello Step 1...');
  sheet.getRange(2, 1, 1, 5).setFontStyle('normal').setFontColor('#000000');

  sheet.insertRowAfter(2);
  sheet.getRange(3, 1).setValue('Non AI slop');
  sheet.getRange(3, 2).setValue('Contenuto autentico: foto reali, meme tradizionali, screenshot, video registrati...');
  sheet.getRange(3, 1, 1, 5).setFontStyle('normal').setFontColor('#000000');

  sheet.insertRowAfter(3);
  // Blank row as separator

  sheet.insertRowAfter(4);
  sheet.getRange(5, 1, 1, 5).mergeAcross()
    .setValue('STEP 2 — Categorie tematiche (personalizzare per il vostro gruppo)')
    .setBackground(COLORS.discuiPrimary)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');

  // Column widths
  sheet.setColumnWidth(1, 150);
  sheet.setColumnWidth(2, 300);
  sheet.setColumnWidth(3, 300);
  sheet.setColumnWidth(4, 300);
  sheet.setColumnWidth(5, 200);

  // Wrap text
  sheet.getRange(1, 1, 20, 5).setWrapStrategy(SpreadsheetApp.WrapStrategy.WRAP);

  return sheet;
}

// ---------------------------------------------------------------------------
// PROMPT tab
// ---------------------------------------------------------------------------

function createPromptSheet(ss) {
  const sheet = ss.insertSheet('PROMPT');

  // Section: Step 1 prompt
  sheet.getRange(1, 1, 1, 2).mergeAcross()
    .setValue('PROMPT STEP 1 — Classificazione binaria (AI slop / Non AI slop)')
    .setBackground(COLORS.uniurbBlue)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');

  sheet.getRange(2, 1).setValue('Versione');
  sheet.getRange(2, 2).setValue('Testo del prompt');
  sheet.getRange(2, 1, 1, 2).setFontWeight('bold').setBackground(COLORS.headerBg);

  sheet.getRange(3, 1).setValue('v1 (iniziale)');
  sheet.getRange(3, 2).setValue('Incollare qui il primo prompt usato per la classificazione binaria...');
  sheet.getRange(3, 2).setFontColor('#999999').setFontStyle('italic');

  sheet.getRange(4, 1).setValue('v2 (dopo pilot)');
  sheet.getRange(5, 1).setValue('v_finale');

  // Blank row
  sheet.getRange(7, 1, 1, 2).mergeAcross()
    .setValue('PROMPT STEP 2 — Classificazione tematica')
    .setBackground(COLORS.discuiPrimary)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');

  sheet.getRange(8, 1).setValue('Versione');
  sheet.getRange(8, 2).setValue('Testo del prompt');
  sheet.getRange(8, 1, 1, 2).setFontWeight('bold').setBackground(COLORS.headerBg);

  sheet.getRange(9, 1).setValue('v1 (iniziale)');
  sheet.getRange(9, 2).setValue('Incollare qui il primo prompt usato per la classificazione tematica...');
  sheet.getRange(9, 2).setFontColor('#999999').setFontStyle('italic');

  sheet.getRange(10, 1).setValue('v2 (dopo pilot)');
  sheet.getRange(11, 1).setValue('v_finale');

  // Column widths
  sheet.setColumnWidth(1, 150);
  sheet.setColumnWidth(2, 800);

  // Wrap text
  sheet.getRange(1, 1, 15, 2).setWrapStrategy(SpreadsheetApp.WrapStrategy.WRAP);

  return sheet;
}

// ---------------------------------------------------------------------------
// ISTRUZIONI tab
// ---------------------------------------------------------------------------

function createInstructionsSheet(ss) {
  const sheet = ss.insertSheet('ISTRUZIONI');

  const instructions = [
    ['ISTRUZIONI PER IL CODING DEL PROGETTO', ''],
    ['', ''],
    ['IA Generativa e Media — A.A. 2025/2026', ''],
    ['Prof. Fabio Giglietto · DISCUI · Universita degli Studi di Urbino Carlo Bo', ''],
    ['', ''],
    ['COME USARE QUESTO FOGLIO', ''],
    ['', ''],
    ['1. PREPARAZIONE', 'Il responsabile del gruppo copia questo foglio e lo condivide con i membri del gruppo (modalita MODIFICA) e con fabio.giglietto@uniurb.it e bruna.almeidaparoni@uniurb.it (modalita COMMENTO).'],
    ['', 'Rinominate le colonne "coder_1"..."coder_6" con i nomi dei membri del gruppo in TUTTI i tab.'],
    ['', ''],
    ['2. TAB "DATI"', 'Contiene i metadati dei 420 post e le metriche di engagement. NON MODIFICARE.'],
    ['', 'Usatelo come riferimento per esplorare il dataset e le metriche di engagement.'],
    ['', ''],
    ['3. TAB "STEP 1"', 'Classificazione BINARIA di tutti i 420 post: AI slop oppure no?'],
    ['', 'Le colonne A-D (riga, id, file, testo) sono gia precompilate dal tab DATI.'],
    ['', '(a) UMANI PRIMA (colonne blu): ogni membro classifica indipendentemente un CAMPIONE DI 50 POST. Niente Gemini, niente discussione. Questo DEVE avvenire prima di vedere i risultati di Gemini.'],
    ['', '(b) GEMINI DOPO (colonne arancioni): classificate tutti i 420 post con Gemini usando il vostro prompt.'],
    ['', '(c) FINALE (colonne verdi): confrontate umani vs Gemini, calcolate il kappa, registrate la decisione finale.'],
    ['', ''],
    ['4. TAB "STEP 2"', 'Classificazione TEMATICA: solo per i post classificati come "AI slop" nello Step 1.'],
    ['', 'Copiate qui SOLO le righe classificate come "AI slop" nello Step 1 (colonne A-D).'],
    ['', 'PRIMA di iniziare: aggiornate i menu a tendina con le VOSTRE categorie (Dati > Convalida dati).'],
    ['', '(a) UMANI PRIMA: ogni membro classifica indipendentemente un CAMPIONE DI 50 POST AI slop. Senza Gemini.'],
    ['', '(b) GEMINI DOPO: classificate tutti i post AI slop con il vostro prompt tematico.'],
    ['', '(c) FINALE: confronto, kappa, decisione finale.'],
    ['', ''],
    ['5. TAB "CODEBOOK"', 'Documentate il vostro schema di classificazione con definizioni, esempi e regole.'],
    ['', 'Compilate ENTRAMBE le sezioni: Step 1 (definizione di AI slop) e Step 2 (le vostre categorie tematiche).'],
    ['', 'Il codebook deve essere identico per Gemini e per i codificatori umani.'],
    ['', ''],
    ['6. TAB "PROMPT"', 'Salvate TUTTE le versioni dei prompt usati con Gemini, sia per Step 1 sia per Step 2.'],
    ['', 'Le versioni precedenti servono per la sezione Metodo della relazione: documentate cosa avete cambiato e perche.'],
    ['', ''],
    ['FASI DI LAVORO', ''],
    ['', ''],
    ['Sett. 4 Mar 17', 'Lancio progetto: esplorazione dataset, formazione gruppi, scelta angolo di classificazione per Step 2.'],
    ['Sett. 4 Mer 18', 'Lab — Prompt design + pilot: scrivete e testate i prompt (Step 1 e Step 2) su 10-15 post. Raffinate. Documentate nel CODEBOOK e PROMPT. Obiettivo: 30-50 post classificati.'],
    ['Sett. 5 Lun 23', 'Lab — Codifica umana PRIMA: ogni membro classifica indipendentemente 50 post (Step 1) senza Gemini. Poi classificazione Gemini di tutti i 420 post (Step 1). Infine Step 2 (Gemini) solo sui post AI slop.'],
    ['Sett. 5 Mar 24', 'Validazione: codifica umana di 50 post per Step 2 (senza Gemini). Poi confronto umani vs Gemini per Step 1 e Step 2: matrice di confusione, Cohen\'s kappa. Se kappa < 0.60: raffinare e ripetere.'],
    ['Sett. 5 Mer 25', 'Consultazione + analisi engagement: collegate le categorie validate (Step 2) alle metriche di engagement nel tab DATI. Quali categorie generano piu reazioni, condivisioni, visualizzazioni?'],
    ['Sett. 6 Lun 30', 'Workshop di scrittura: struttura della relazione, distribuzione del lavoro nel gruppo.'],
    ['Sett. 6 Mar 31', 'Lavoro di gruppo in aula: stesura collaborativa della relazione.'],
    ['Sett. 6 Mer 1 Apr', 'Sintesi del corso: confronto inter-gruppo (stessi dati, schemi diversi) + consultazioni finali.'],
    ['', ''],
    ['REGOLE D\'ORO', ''],
    ['', '1. UMANI PRIMA, GEMINI DOPO: la codifica umana (colonne blu) deve avvenire PRIMA di quella con Gemini (colonne arancioni). Altrimenti i codificatori umani saranno influenzati (bias di ancoraggio).'],
    ['', '2. Durante la codifica umana: ogni membro lavora SENZA consultare Gemini e SENZA discutere con gli altri.'],
    ['', '3. Il codebook e il prompt devono essere IDENTICI per Gemini e per gli umani — altrimenti il confronto non ha senso.'],
    ['', '4. Documentate TUTTO: ogni versione del prompt, ogni decisione sul codebook, ogni caso ambiguo. Servira per la relazione.'],
  ];

  sheet.getRange(1, 1, instructions.length, 2).setValues(instructions);

  // Format title
  sheet.getRange(1, 1, 1, 2).mergeAcross()
    .setFontSize(16)
    .setFontWeight('bold')
    .setBackground(COLORS.discuiPrimary)
    .setFontColor(COLORS.white);

  sheet.getRange(3, 1, 2, 2).setFontStyle('italic').setFontColor('#666666');

  // Format section headers
  const sectionRows = [6, 35, 47];
  sectionRows.forEach(row => {
    sheet.getRange(row, 1, 1, 2).mergeAcross()
      .setFontWeight('bold')
      .setFontSize(12)
      .setBackground(COLORS.headerBg);
  });

  // Format step labels (1. PREPARAZIONE, 2. TAB DATI, etc.)
  const stepRows = [8, 11, 14, 21, 28, 32];
  stepRows.forEach(row => {
    sheet.getRange(row, 1).setFontWeight('bold');
  });

  // Format timeline dates
  for (let r = 37; r <= 44; r++) {
    sheet.getRange(r, 1).setFontWeight('bold');
  }

  // Golden rules
  sheet.getRange(47, 1).setFontWeight('bold').setFontColor(COLORS.discuiPrimary);

  // Column widths
  sheet.setColumnWidth(1, 250);
  sheet.setColumnWidth(2, 700);

  // Wrap text
  sheet.getRange(1, 1, instructions.length, 2).setWrapStrategy(SpreadsheetApp.WrapStrategy.WRAP);

  // Hide gridlines for a cleaner look
  sheet.setHiddenGridlines(true);

  return sheet;
}

// ---------------------------------------------------------------------------
// Utility: color a column range
// ---------------------------------------------------------------------------

function colorColumnRange(sheet, col, startRow, numRows, color) {
  if (numRows > 0) {
    sheet.getRange(startRow, col, numRows, 1).setBackground(color);
  }
}
