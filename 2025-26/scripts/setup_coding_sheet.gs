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
const DATA_COLS = 5; // riga, id, pagina, media_files, testo
const VALIDATION_SAMPLE_SIZE = 50;
const RANDOM_SEED = 42;

// ---------------------------------------------------------------------------
// Seeded random number generator (simple LCG)
// ---------------------------------------------------------------------------

function seededRandom(seed) {
  let s = seed;
  return function() {
    s = (s * 1664525 + 1013904223) & 0x7fffffff;
    return s / 0x7fffffff;
  };
}

/**
 * Select a random sample of indices (0-based) from a range [0, total).
 * Uses a seeded PRNG for reproducibility across groups.
 */
function selectValidationSample(total, sampleSize, seed) {
  const rng = seededRandom(seed);
  const indices = [];
  for (let i = 0; i < total; i++) indices.push(i);
  // Fisher-Yates shuffle with seeded RNG
  for (let i = indices.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    const tmp = indices[i];
    indices[i] = indices[j];
    indices[j] = tmp;
  }
  return indices.slice(0, sampleSize).sort((a, b) => a - b);
}

// ---------------------------------------------------------------------------
// Build a map of filename → Google Drive view URL from the "media" folder
// ---------------------------------------------------------------------------

/**
 * Finds the "media" folder in the same Drive directory as the active spreadsheet
 * and returns a map of { filename: viewUrl }.
 */
function buildMediaUrlMap() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const ssFile = DriveApp.getFileById(ss.getId());
  const parents = ssFile.getParents();

  if (!parents.hasNext()) {
    Logger.log('Spreadsheet has no parent folder — skipping media links');
    return {};
  }

  const parentFolder = parents.next();
  const mediaFolders = parentFolder.getFoldersByName('media');

  if (!mediaFolders.hasNext()) {
    Logger.log('No "media" folder found in ' + parentFolder.getName() + ' — skipping media links');
    return {};
  }

  const mediaFolder = mediaFolders.next();
  const urlMap = {};
  const files = mediaFolder.getFiles();

  while (files.hasNext()) {
    const file = files.next();
    // Use the standard Drive view URL
    urlMap[file.getName()] = 'https://drive.google.com/file/d/' + file.getId() + '/view';
  }

  Logger.log('Built media URL map with ' + Object.keys(urlMap).length + ' files');
  return urlMap;
}

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

  // Build filename → URL map from the "media" Drive folder
  const mediaUrlMap = buildMediaUrlMap();

  // Hide instructor's pre-classification columns in DATI to prevent bias
  hideClassificationColumns(dataSheet);

  // Read all data once
  const dataHeaders = dataSheet.getRange(1, 1, 1, dataSheet.getLastColumn()).getValues()[0];
  const dataValues = dataSheet.getRange(2, 1, numPosts, dataSheet.getLastColumn()).getValues();

  const idxId = dataHeaders.indexOf('id');
  const idxPageName = dataHeaders.indexOf('post_owner.name');
  const idxMediaFiles = dataHeaders.indexOf('media_files');
  const idxText = dataHeaders.indexOf('text');

  // Build array of [riga, id, pagina, media_files, testo] for all posts
  const allPostData = [];
  for (let r = 0; r < numPosts; r++) {
    allPostData.push([
      String(r + 1).padStart(3, '0'),
      dataValues[r][idxId],
      idxPageName >= 0 ? dataValues[r][idxPageName] : '',
      dataValues[r][idxMediaFiles],
      dataValues[r][idxText],
    ]);
  }

  // Select 50-row validation sample (same for all groups via seed)
  const sampleIndices = selectValidationSample(numPosts, VALIDATION_SAMPLE_SIZE, RANDOM_SEED);
  const sampleData = sampleIndices.map(i => allPostData[i]);

  // Create tabs (delete if they already exist to allow re-running)
  const tabNames = [
    'STEP 1 — Codifica Umana (50)',
    'STEP 1 — Gemini + Decisione',
    'STEP 2 — Codifica Umana (50)',
    'STEP 2 — Gemini + Decisione',
    'CODEBOOK',
    'PROMPT',
    'ISTRUZIONI',
  ];

  tabNames.forEach(name => {
    const existing = ss.getSheetByName(name);
    if (existing) ss.deleteSheet(existing);
  });

  // Build each tab
  const step1Human = createStep1HumanSheet(ss, sampleData, mediaUrlMap);
  const step1Gemini = createStep1GeminiSheet(ss, allPostData, numPosts, mediaUrlMap);
  const step2Human = createStep2HumanSheet(ss);
  const step2Gemini = createStep2GeminiSheet(ss);
  const codebook = createCodebookSheet(ss);
  const prompt = createPromptSheet(ss);
  const instructions = createInstructionsSheet(ss);

  // Reorder tabs: ISTRUZIONI, DATI, S1-Umana, S1-Gemini, S2-Umana, S2-Gemini, CODEBOOK, PROMPT
  ss.setActiveSheet(instructions);
  ss.moveActiveSheet(1);
  ss.setActiveSheet(dataSheet);
  ss.moveActiveSheet(2);
  ss.setActiveSheet(step1Human);
  ss.moveActiveSheet(3);
  ss.setActiveSheet(step1Gemini);
  ss.moveActiveSheet(4);
  ss.setActiveSheet(step2Human);
  ss.moveActiveSheet(5);
  ss.setActiveSheet(step2Gemini);
  ss.moveActiveSheet(6);
  ss.setActiveSheet(codebook);
  ss.moveActiveSheet(7);
  ss.setActiveSheet(prompt);
  ss.moveActiveSheet(8);

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
// STEP 1 — Codifica Umana (50): blind human coding on 50-post sample
// ---------------------------------------------------------------------------

function createStep1HumanSheet(ss, sampleData, mediaUrlMap) {
  const sheet = ss.insertSheet('STEP 1 — Codifica Umana (50)');
  const numRows = sampleData.length;

  // Columns: riga, id, pagina, media_files, testo | coder_1..6 | note
  const headers = ['riga', 'id', 'pagina', 'media_files', 'testo'];
  for (let i = 1; i <= MAX_CODERS; i++) {
    headers.push('coder_' + i);
  }
  headers.push('note');

  const totalCols = headers.length;

  // Set headers
  const headerRange = sheet.getRange(1, 1, 1, totalCols);
  headerRange.setValues([headers]);
  headerRange.setFontWeight('bold');
  headerRange.setBackground(COLORS.headerBg);
  headerRange.setHorizontalAlignment('center');

  // Color human coder headers blue
  const coderStart = DATA_COLS + 1; // column after data
  for (let c = coderStart; c < coderStart + MAX_CODERS; c++) {
    sheet.getRange(1, c).setBackground(COLORS.uniurbBlue).setFontColor(COLORS.white);
  }

  // Fill data columns
  sheet.getRange(2, 1, numRows, DATA_COLS).setValues(sampleData);

  // Replace media_files with clickable hyperlinks (column 4 = media_files)
  applyMediaLinks(sheet, 2, numRows, 4, mediaUrlMap);

  // Dropdowns for coders
  const binaryRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(BINARY_OPTIONS, true)
    .setAllowInvalid(false)
    .build();

  for (let i = 0; i < MAX_CODERS; i++) {
    sheet.getRange(2, coderStart + i, numRows, 1).setDataValidation(binaryRule);
  }

  // Column widths
  sheet.setColumnWidth(1, 50);   // riga
  sheet.setColumnWidth(2, 140);  // id
  sheet.setColumnWidth(3, 150);  // pagina
  sheet.setColumnWidth(4, 200);  // media_files
  sheet.setColumnWidth(5, 350);  // testo
  for (let i = 0; i < MAX_CODERS; i++) sheet.setColumnWidth(coderStart + i, 120);
  sheet.setColumnWidth(coderStart + MAX_CODERS, 250); // note

  // Freeze header row and data columns
  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(DATA_COLS);

  // Clip text in testo column
  sheet.getRange(2, 5, numRows, 1).setWrapStrategy(SpreadsheetApp.WrapStrategy.CLIP);

  // Tab color: blue
  sheet.setTabColor(COLORS.uniurbBlue);

  return sheet;
}

// ---------------------------------------------------------------------------
// STEP 1 — Gemini + Decisione: AI classification of all posts + final decision
// ---------------------------------------------------------------------------

function createStep1GeminiSheet(ss, allPostData, numPosts, mediaUrlMap) {
  const sheet = ss.insertSheet('STEP 1 — Gemini + Decisione');

  // Columns: riga, id, pagina, media_files, testo | gemini_slop, certezza, motivazione | decisione_finale, note
  const headers = [
    'riga', 'id', 'pagina', 'media_files', 'testo',
    '',  // separator GEMINI
    'gemini_slop', 'gemini_certezza', 'gemini_motivazione',
    '',  // separator FINALE
    'decisione_finale', 'note',
  ];

  const totalCols = headers.length;
  const sepGemini = DATA_COLS + 1; // 6
  const sepFinal = sepGemini + 4;  // 10

  // Set headers
  const headerRange = sheet.getRange(1, 1, 1, totalCols);
  headerRange.setValues([headers]);
  headerRange.setFontWeight('bold');
  headerRange.setBackground(COLORS.headerBg);
  headerRange.setHorizontalAlignment('center');

  // Gemini separator
  sheet.getRange(1, sepGemini).setValue('GEMINI')
    .setBackground(COLORS.discuiPrimary)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');
  sheet.setColumnWidth(sepGemini, 30);
  colorColumnRange(sheet, sepGemini, 2, numPosts, COLORS.lightOrange);

  // Gemini column headers
  for (let c = sepGemini + 1; c <= sepGemini + 3; c++) {
    sheet.getRange(1, c).setBackground(COLORS.discuiPrimary).setFontColor(COLORS.white);
  }

  // Final separator
  sheet.getRange(1, sepFinal).setValue('FINALE')
    .setBackground(COLORS.green)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');
  sheet.setColumnWidth(sepFinal, 30);
  colorColumnRange(sheet, sepFinal, 2, numPosts, COLORS.lightGreen);

  // Final column headers
  sheet.getRange(1, sepFinal + 1).setBackground(COLORS.green).setFontColor(COLORS.white);
  sheet.getRange(1, sepFinal + 2).setBackground(COLORS.green).setFontColor(COLORS.white);

  // Fill data columns
  sheet.getRange(2, 1, numPosts, DATA_COLS).setValues(allPostData);

  // Replace media_files with clickable hyperlinks (column 4 = media_files)
  applyMediaLinks(sheet, 2, numPosts, 4, mediaUrlMap);

  // Dropdowns
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

  sheet.getRange(2, sepGemini + 1, numPosts, 1).setDataValidation(binaryRule);
  sheet.getRange(2, sepGemini + 2, numPosts, 1).setDataValidation(certaintyRule);
  sheet.getRange(2, sepFinal + 1, numPosts, 1).setDataValidation(binaryFinalRule);

  // Column widths
  sheet.setColumnWidth(1, 50);   // riga
  sheet.setColumnWidth(2, 140);  // id
  sheet.setColumnWidth(3, 150);  // pagina
  sheet.setColumnWidth(4, 200);  // media_files
  sheet.setColumnWidth(5, 350);  // testo
  sheet.setColumnWidth(sepGemini + 1, 120);  // gemini_slop
  sheet.setColumnWidth(sepGemini + 2, 120);  // certezza
  sheet.setColumnWidth(sepGemini + 3, 250);  // motivazione
  sheet.setColumnWidth(sepFinal + 1, 140);   // decisione
  sheet.setColumnWidth(sepFinal + 2, 250);   // note

  // Freeze header row and data columns
  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(DATA_COLS);

  // Clip text in testo column
  sheet.getRange(2, 5, numPosts, 1).setWrapStrategy(SpreadsheetApp.WrapStrategy.CLIP);

  // Tab color: orange
  sheet.setTabColor(COLORS.discuiPrimary);

  return sheet;
}

// ---------------------------------------------------------------------------
// STEP 2 — Codifica Umana (50): blind human thematic coding on 50-post sample
// ---------------------------------------------------------------------------

function createStep2HumanSheet(ss) {
  const sheet = ss.insertSheet('STEP 2 — Codifica Umana (50)');

  // Columns: riga, id, pagina, media_files, testo | coder_1..6 | note
  const headers = ['riga', 'id', 'pagina', 'media_files', 'testo'];
  for (let i = 1; i <= MAX_CODERS; i++) {
    headers.push('coder_' + i);
  }
  headers.push('note');

  const totalCols = headers.length;

  // Set headers
  const headerRange = sheet.getRange(1, 1, 1, totalCols);
  headerRange.setValues([headers]);
  headerRange.setFontWeight('bold');
  headerRange.setBackground(COLORS.headerBg);
  headerRange.setHorizontalAlignment('center');

  // Color human coder headers blue
  const coderStart = DATA_COLS + 1;
  for (let c = coderStart; c < coderStart + MAX_CODERS; c++) {
    sheet.getRange(1, c).setBackground(COLORS.uniurbBlue).setFontColor(COLORS.white);
  }

  // Placeholder note in row 2
  sheet.getRange(2, 1).setValue('Dopo lo Step 1: selezionate 50 post "AI slop" dal tab "STEP 1 — Gemini + Decisione" e copiate qui le colonne A-E');
  sheet.getRange(2, 1, 1, DATA_COLS).mergeAcross()
    .setFontStyle('italic')
    .setFontColor('#999999');

  // Dropdown with placeholder categories (groups will customize)
  const thematicRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(THEMATIC_PLACEHOLDER, true)
    .setAllowInvalid(true)  // Allow invalid so groups can change categories
    .build();

  // Apply to rows 3-52 (50 rows, leaving row 2 for the instruction note)
  const maxRows = VALIDATION_SAMPLE_SIZE;
  for (let i = 0; i < MAX_CODERS; i++) {
    sheet.getRange(3, coderStart + i, maxRows, 1).setDataValidation(thematicRule);
  }

  // Column widths
  sheet.setColumnWidth(1, 50);
  sheet.setColumnWidth(2, 140);
  sheet.setColumnWidth(3, 150);
  sheet.setColumnWidth(4, 200);
  sheet.setColumnWidth(5, 350);
  for (let i = 0; i < MAX_CODERS; i++) sheet.setColumnWidth(coderStart + i, 140);
  sheet.setColumnWidth(coderStart + MAX_CODERS, 250); // note

  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(DATA_COLS);

  // Tab color: blue
  sheet.setTabColor(COLORS.uniurbBlue);

  return sheet;
}

// ---------------------------------------------------------------------------
// STEP 2 — Gemini + Decisione: AI thematic classification + final decision
// ---------------------------------------------------------------------------

function createStep2GeminiSheet(ss) {
  const sheet = ss.insertSheet('STEP 2 — Gemini + Decisione');

  // Columns: riga, id, pagina, media_files, testo | gemini_cat, certezza, motivazione | decisione_finale, note
  const headers = [
    'riga', 'id', 'pagina', 'media_files', 'testo',
    '',  // separator GEMINI
    'gemini_categoria', 'gemini_certezza', 'gemini_motivazione',
    '',  // separator FINALE
    'decisione_finale', 'note',
  ];

  const totalCols = headers.length;
  const sepGemini = DATA_COLS + 1; // 6
  const sepFinal = sepGemini + 4;  // 10

  // Set headers
  const headerRange = sheet.getRange(1, 1, 1, totalCols);
  headerRange.setValues([headers]);
  headerRange.setFontWeight('bold');
  headerRange.setBackground(COLORS.headerBg);
  headerRange.setHorizontalAlignment('center');

  // Gemini separator
  sheet.getRange(1, sepGemini).setValue('GEMINI')
    .setBackground(COLORS.discuiPrimary)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');
  sheet.setColumnWidth(sepGemini, 30);

  for (let c = sepGemini + 1; c <= sepGemini + 3; c++) {
    sheet.getRange(1, c).setBackground(COLORS.discuiPrimary).setFontColor(COLORS.white);
  }

  // Final separator
  sheet.getRange(1, sepFinal).setValue('FINALE')
    .setBackground(COLORS.green)
    .setFontColor(COLORS.white)
    .setFontWeight('bold');
  sheet.setColumnWidth(sepFinal, 30);

  sheet.getRange(1, sepFinal + 1).setBackground(COLORS.green).setFontColor(COLORS.white);
  sheet.getRange(1, sepFinal + 2).setBackground(COLORS.green).setFontColor(COLORS.white);

  // Placeholder note in row 2
  sheet.getRange(2, 1).setValue('Copiate qui TUTTE le righe con decisione_finale = "AI slop" dal tab "STEP 1 — Gemini + Decisione" (colonne A-E)');
  sheet.getRange(2, 1, 1, DATA_COLS).mergeAcross()
    .setFontStyle('italic')
    .setFontColor('#999999');

  // Dropdowns
  const thematicRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(THEMATIC_PLACEHOLDER, true)
    .setAllowInvalid(true)
    .build();

  const certaintyRule = SpreadsheetApp.newDataValidation()
    .requireValueInList(CERTAINTY_OPTIONS, true)
    .setAllowInvalid(false)
    .build();

  // Apply to 500 rows (more than enough for AI slop subset) starting from row 3
  const maxRows = 500;
  sheet.getRange(3, sepGemini + 1, maxRows, 1).setDataValidation(thematicRule);
  sheet.getRange(3, sepGemini + 2, maxRows, 1).setDataValidation(certaintyRule);
  sheet.getRange(3, sepFinal + 1, maxRows, 1).setDataValidation(thematicRule);

  // Column widths
  sheet.setColumnWidth(1, 50);
  sheet.setColumnWidth(2, 140);
  sheet.setColumnWidth(3, 150);
  sheet.setColumnWidth(4, 200);
  sheet.setColumnWidth(5, 350);
  sheet.setColumnWidth(sepGemini + 1, 140);  // gemini_categoria
  sheet.setColumnWidth(sepGemini + 2, 120);  // certezza
  sheet.setColumnWidth(sepGemini + 3, 250);  // motivazione
  sheet.setColumnWidth(sepFinal + 1, 140);   // decisione
  sheet.setColumnWidth(sepFinal + 2, 250);   // note

  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(DATA_COLS);

  // Tab color: orange
  sheet.setTabColor(COLORS.discuiPrimary);

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
    ['', 'Rinominate le colonne "coder_1"..."coder_6" con i nomi dei membri del gruppo nei tab di CODIFICA UMANA (Step 1 e Step 2).'],
    ['', ''],
    ['2. TAB "DATI"', 'Contiene i metadati dei 420 post e le metriche di engagement. NON MODIFICARE.'],
    ['', 'Usatelo come riferimento per esplorare il dataset e le metriche di engagement. Alcune colonne (slop_score, slop_category, is_slop) sono nascoste per evitare bias.'],
    ['', ''],
    ['3. STEP 1: CLASSIFICAZIONE BINARIA (AI slop o no?)', ''],
    ['', ''],
    ['   Tab "STEP 1 — Codifica Umana (50)"', 'Contiene un campione casuale di 50 post (pre-selezionato con seed fisso, identico per tutti i gruppi — permette il confronto inter-gruppo).'],
    ['', 'Ogni membro classifica INDIPENDENTEMENTE tutti i 50 post: AI slop, Non AI slop, o Incerto.'],
    ['', 'REGOLA FONDAMENTALE: aprite SOLO questo tab durante la codifica umana. NON guardate il tab Gemini.'],
    ['', ''],
    ['   Tab "STEP 1 — Gemini + Decisione"', 'Contiene tutti i 420 post. Classificateli con Gemini usando il vostro prompt.'],
    ['', 'La colonna "decisione_finale" serve per registrare la classificazione definitiva dopo il confronto con i risultati umani.'],
    ['', ''],
    ['4. STEP 2: CLASSIFICAZIONE TEMATICA (solo post AI slop)', ''],
    ['', ''],
    ['   Tab "STEP 2 — Codifica Umana (50)"', 'Dopo lo Step 1, selezionate 50 post classificati come "AI slop" nel tab "STEP 1 — Gemini + Decisione" e copiate qui le colonne A-E.'],
    ['', 'Ogni membro classifica INDIPENDENTEMENTE usando le categorie del vostro CODEBOOK.'],
    ['', 'PRIMA di iniziare: aggiornate i menu a tendina con le VOSTRE categorie (Dati > Convalida dati).'],
    ['', ''],
    ['   Tab "STEP 2 — Gemini + Decisione"', 'Copiate qui TUTTE le righe con decisione_finale = "AI slop" dal tab "STEP 1 — Gemini + Decisione" (colonne A-E).'],
    ['', 'Classificatele con Gemini usando il vostro prompt tematico.'],
    ['', 'La colonna "decisione_finale" serve per la classificazione definitiva.'],
    ['', ''],
    ['5. TAB "CODEBOOK"', 'Documentate il vostro schema di classificazione con definizioni, esempi e regole.'],
    ['', 'Compilate ENTRAMBE le sezioni: Step 1 (definizione di AI slop) e Step 2 (le vostre categorie tematiche).'],
    ['', 'Il codebook deve essere identico per Gemini e per i codificatori umani.'],
    ['', ''],
    ['6. TAB "PROMPT"', 'Salvate TUTTE le versioni dei prompt usati con Gemini, sia per Step 1 sia per Step 2.'],
    ['', 'Le versioni precedenti servono per la sezione Metodo della relazione: documentate cosa avete cambiato e perche.'],
    ['', ''],
    ['STRUTTURA DEI TAB', ''],
    ['', ''],
    ['', 'Tab blu (Codifica Umana): contengono SOLO colonne per i codificatori umani. Nessuna colonna Gemini. Nessuna possibilita di ancoraggio.'],
    ['', 'Tab arancioni (Gemini + Decisione): contengono SOLO colonne per Gemini e la decisione finale. Nessuna colonna umana.'],
    ['', 'Questa separazione fisica garantisce che i codificatori umani non possano vedere i risultati di Gemini durante la codifica.'],
    ['', ''],
    ['FASI DI LAVORO', ''],
    ['', ''],
    ['Sett. 4 Mar 17', 'Lancio progetto: esplorazione dataset, formazione gruppi, scelta angolo di classificazione per Step 2.'],
    ['Sett. 4 Mer 18', 'Lab — Prompt design + pilot: scrivete e testate i prompt (Step 1 e Step 2) su 10-15 post. Raffinate. Documentate nel CODEBOOK e PROMPT. Obiettivo: 30-50 post classificati.'],
    ['Sett. 5 Mar 24', 'Lab — Codifica umana Step 1: ogni membro apre "STEP 1 — Codifica Umana (50)" e classifica i 50 post senza Gemini. Poi Gemini classifica tutti i 420 post in "STEP 1 — Gemini + Decisione".'],
    ['Sett. 5 Mer 25', 'Validazione: confronto umani vs Gemini per Step 1 (kappa). Poi copiate 50 post AI slop in "STEP 2 — Codifica Umana (50)" e codificate. Gemini in "STEP 2 — Gemini + Decisione". Se kappa < 0.60: raffinare e ripetere.'],
    ['Sett. 6 Lun 30', 'Consultazione + analisi engagement: collegate le categorie validate (Step 2) alle metriche di engagement nel tab DATI.'],
    ['Sett. 6 Mar 31', 'Workshop di scrittura: struttura della relazione, distribuzione del lavoro nel gruppo.'],
    ['Sett. 6 Mer 1 Apr', 'Lavoro di gruppo in aula: stesura collaborativa della relazione.'],
    ['Sett. 7 Lun 13 Apr', 'Sintesi del corso: confronto inter-gruppo (stessi dati, schemi diversi) + consultazioni finali.'],
    ['', ''],
    ['REGOLE D\'ORO', ''],
    ['', '1. SEPARAZIONE FISICA: la codifica umana avviene nei tab blu (Codifica Umana). Non aprite MAI i tab arancioni (Gemini) prima di aver completato la codifica umana del rispettivo step.'],
    ['', '2. Durante la codifica umana: ogni membro lavora SENZA consultare Gemini e SENZA discutere con gli altri.'],
    ['', '3. Il codebook e il prompt devono essere IDENTICI per Gemini e per gli umani — altrimenti il confronto non ha senso.'],
    ['', '4. Documentate TUTTO: ogni versione del prompt, ogni decisione sul codebook, ogni caso ambiguo. Servira per la relazione.'],
    ['', '5. Il campione di 50 post nello Step 1 e pre-selezionato con un seed fisso: tutti i gruppi validano gli STESSI 50 post, rendendo possibile il confronto inter-gruppo.'],
  ];

  sheet.getRange(1, 1, instructions.length, 2).setValues(instructions);

  // Format title
  sheet.getRange(1, 1, 1, 2).mergeAcross()
    .setFontSize(16)
    .setFontWeight('bold')
    .setBackground(COLORS.discuiPrimary)
    .setFontColor(COLORS.white);

  sheet.getRange(3, 1, 2, 2).setFontStyle('italic').setFontColor('#666666');

  // Format section headers (merged, bold, larger font, gray background)
  // Row 6: COME USARE, 14: STEP 1, 23: STEP 2, 40: STRUTTURA DEI TAB, 46: FASI DI LAVORO, 57: REGOLE D'ORO
  const sectionRows = [6, 14, 23, 40, 46, 57];
  sectionRows.forEach(row => {
    if (row <= instructions.length) {
      sheet.getRange(row, 1, 1, 2).mergeAcross()
        .setFontWeight('bold')
        .setFontSize(12)
        .setBackground(COLORS.headerBg);
    }
  });

  // Format sub-section labels (indented tab names)
  // Row 16: S1 Umana, 20: S1 Gemini, 25: S2 Umana, 29: S2 Gemini
  const subSectionRows = [16, 20, 25, 29];
  subSectionRows.forEach(row => {
    if (row <= instructions.length) {
      sheet.getRange(row, 1).setFontWeight('bold');
    }
  });

  // Format step labels (1. PREPARAZIONE, 2. TAB DATI, 5. CODEBOOK, 6. PROMPT)
  const stepRows = [8, 11, 33, 37];
  stepRows.forEach(row => {
    if (row <= instructions.length) {
      sheet.getRange(row, 1).setFontWeight('bold');
    }
  });

  // Format timeline dates (rows 48-55: Sett. 4 through Sett. 7)
  for (let r = 48; r <= 55; r++) {
    if (r <= instructions.length) {
      sheet.getRange(r, 1).setFontWeight('bold');
    }
  }

  // Golden rules header
  if (instructions.length >= 57) {
    sheet.getRange(57, 1).setFontWeight('bold').setFontColor(COLORS.discuiPrimary);
  }

  // Tab structure explanation: color the blue/orange labels
  if (instructions.length >= 43) {
    sheet.getRange(42, 2).setFontColor(COLORS.uniurbBlue).setFontWeight('bold');
    sheet.getRange(43, 2).setFontColor(COLORS.discuiPrimary).setFontWeight('bold');
  }

  // Column widths
  sheet.setColumnWidth(1, 280);
  sheet.setColumnWidth(2, 700);

  // Wrap text
  sheet.getRange(1, 1, instructions.length, 2).setWrapStrategy(SpreadsheetApp.WrapStrategy.WRAP);

  // Hide gridlines for a cleaner look
  sheet.setHiddenGridlines(true);

  return sheet;
}

// ---------------------------------------------------------------------------
// Utility: hide instructor's pre-classification columns in DATI
// ---------------------------------------------------------------------------

/**
 * Hides columns that contain the instructor's ground-truth classifications
 * (slop_score, slop_category, is_slop) to prevent biasing student coders.
 */
function hideClassificationColumns(dataSheet) {
  const headers = dataSheet.getRange(1, 1, 1, dataSheet.getLastColumn()).getValues()[0];
  const columnsToHide = ['slop_score', 'slop_category', 'is_slop'];

  columnsToHide.forEach(colName => {
    const idx = headers.indexOf(colName);
    if (idx >= 0) {
      dataSheet.hideColumns(idx + 1); // 1-based
    }
  });
}

// ---------------------------------------------------------------------------
// Utility: color a column range
// ---------------------------------------------------------------------------

function colorColumnRange(sheet, col, startRow, numRows, color) {
  if (numRows > 0) {
    sheet.getRange(startRow, col, numRows, 1).setBackground(color);
  }
}

// ---------------------------------------------------------------------------
// Utility: replace media_files cell values with HYPERLINK formulas
// ---------------------------------------------------------------------------

/**
 * For each cell in the media_files column, if the filename exists in the
 * mediaUrlMap, replace the plain text with a RichTextValue containing a
 * clickable link. This avoids HYPERLINK formulas and works in batch.
 *
 * Handles comma-separated filenames: each filename becomes a separate link
 * within the same cell, separated by ", ".
 *
 * @param {Sheet} sheet - The sheet to modify
 * @param {number} startRow - First data row (1-based)
 * @param {number} numRows - Number of data rows
 * @param {number} col - Column number of media_files (1-based)
 * @param {Object} mediaUrlMap - { filename: driveViewUrl }
 */
function applyMediaLinks(sheet, startRow, numRows, col, mediaUrlMap) {
  if (!mediaUrlMap || Object.keys(mediaUrlMap).length === 0) return;

  const range = sheet.getRange(startRow, col, numRows, 1);
  const values = range.getValues();
  const richTextValues = [];

  for (let r = 0; r < values.length; r++) {
    const raw = String(values[r][0]).trim();
    if (!raw) {
      richTextValues.push(SpreadsheetApp.newRichTextValue().setText(raw).build());
      continue;
    }

    const filenames = raw.split(',').map(f => f.trim()).filter(f => f);
    const separator = ', ';

    // Build the full display text first
    const displayText = filenames.join(separator);
    const builder = SpreadsheetApp.newRichTextValue().setText(displayText);

    // Add link to each filename segment
    let offset = 0;
    for (let i = 0; i < filenames.length; i++) {
      const fn = filenames[i];
      const url = mediaUrlMap[fn];
      if (url) {
        builder.setLinkUrl(offset, offset + fn.length, url);
      }
      offset += fn.length;
      if (i < filenames.length - 1) {
        offset += separator.length;
      }
    }

    richTextValues.push(builder.build());
  }

  // Apply all RichTextValues in batch (one column)
  const richTextRange = richTextValues.map(rtv => [rtv]);
  range.setRichTextValues(richTextRange);
}
