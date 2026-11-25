#!/usr/bin/env Rscript
# Build the Google Sheets update that publishes a group's Gemini coding in its
# own sheet. It writes nothing to Google: it produces the batchUpdate requests,
# which are then sent through a Sheets client.
#
#   Rscript scripts/gemini-sheet-layout.R G08 <corpus sheetId> <corpus tab index> \
#       <kappa_gemini tab index> <registro_agente sheetId> \
#       [corpus grid columns = 26] [note for the header]
#
# The four numbers come from the live sheet (spreadsheets.get, sheets.properties).
#
# Layout (approved on G08, 2026-11-25; the same for every group)
#   corpus            keeps its name; to the right of the existing columns,
#                     gemini_stato and one gemini_<variabile> column for every
#                     variable whose chat kappa on sample B is >= SOGLIA_KAPPA
#   analisi           new tab after corpus: provenance, then one row per
#                     variable and codebook value with its frequency, the same
#                     by platform (when the corpus has one) and by month, all
#                     as formulas
#   kappa_gemini_API  new tab after kappa_gemini: the sample-B test repeated
#                     through the API, for every variable of the codebook
#   registro_agente   one new row with the final prompt sent through the API
#                     and, when it differs from the one the group logged, what
#                     was corrected (see "Prompt corrections" below)
#
# Prompt corrections. Before a group's first API pass its logged prompt is
# checked for obvious mistakes that would break the run without being a coding
# choice: case data pasted after the instructions, no output format, value
# labels that differ from the codebook. Definitions and typos are left alone.
# The corrected text goes in <gruppo>/prompt.txt, which gemini-corpus-run.R
# uses instead of the register, and each change in <gruppo>/prompt_modifiche.txt.
#
# Inputs, under data/2026-27/gemini-run/<gruppo>/ (run gemini-corpus-run.R first)
#   foglio.xlsx, corpus_validata.csv, corpus_risposte.jsonl
#   controllo_codifica.csv, plus _*pass*/controllo_codifica.csv for further passes
# Outputs, same folder (git-ignored)
#   foglio_req_corpus.json, foglio_req_tab.json, foglio_req_registro.json

suppressPackageStartupMessages(library(here))
source(here("scripts", "gemini-corpus-run.R"))   # norm, cohen_kappa, leggi_tab, RUN_DIR, MODEL

ID_ANALISI <- 32000001
ID_KAPPA <- 32000002

lettera <- function(i) {            # 0-based column index -> A1 letter
  s <- ""
  i <- i + 1
  while (i > 0) {
    s <- paste0(LETTERS[(i - 1) %% 26 + 1], s)
    i <- (i - 1) %/% 26
  }
  s
}
incolla <- function(foglio, riga, colonna, righe) list(pasteData = list(
  coordinate = list(sheetId = foglio, rowIndex = riga, columnIndex = colonna),
  data = paste(map_chr(righe, \(r) paste(r, collapse = "\t")), collapse = "\n"),
  delimiter = "\t", type = "PASTE_NORMAL"
))
formato <- function(foglio, r0, r1, c0, c1, formato, campi) list(repeatCell = list(
  range = list(sheetId = foglio, startRowIndex = r0, endRowIndex = r1,
               startColumnIndex = c0, endColumnIndex = c1),
  cell = list(userEnteredFormat = formato), fields = paste0("userEnteredFormat.", campi)
))
grassetto <- \(foglio, r0, r1, c0, c1) formato(foglio, r0, r1, c0, c1, list(textFormat = list(bold = TRUE)), "textFormat.bold")
percento <- \(foglio, r0, r1, c0, c1) formato(foglio, r0, r1, c0, c1, list(numberFormat = list(type = "PERCENT", pattern = "0%")), "numberFormat")
larghezza <- function(foglio, c0, c1, px) list(updateDimensionProperties = list(
  range = list(sheetId = foglio, dimension = "COLUMNS", startIndex = c0, endIndex = c1),
  properties = list(pixelSize = px), fields = "pixelSize"
))
nuovo_foglio <- function(id, titolo, indice, righe, colonne = 10) list(addSheet = list(properties = list(
  sheetId = id, title = titolo, index = indice, gridProperties = list(rowCount = righe, columnCount = colonne)
)))
g_con_media <- \(gruppo, corpus) !"commento" %in% names(corpus) || media_nei_commenti(gruppo)

costruisci <- function(gruppo, id_corpus, indice_corpus, indice_kappa, id_registro, colonne_griglia = 26, nota = "") {
  dir_gruppo <- file.path(RUN_DIR, gruppo)
  xlsx <- file.path(dir_gruppo, "foglio.xlsx")
  corpus <- leggi_tab(xlsx, "corpus") |> mutate(riga = row_number())
  validata <- read_csv(file.path(dir_gruppo, "corpus_validata.csv"), col_types = cols(.default = "c"))
  variabili <- setdiff(names(validata), c("caso", "stato"))
  k <- length(variabili)
  if (k == 0) stop("No validated variable for ", gruppo, ": nothing to publish.")
  if (any(str_detect(names(corpus), "^gemini_"))) stop("corpus already has gemini_ columns.")

  # Codebook labels as the group wrote them: the sheet shows these, not the
  # lower-case form the answers are compared in.
  etichette <- suppressMessages(read_excel(xlsx, sheet = "codebook", range = "A1:O16", col_types = "text")) |>
    filter(!is.na(variabile), str_squish(variabile) != "") |>
    mutate(variabile = str_squish(variabile)) |>
    select(variabile, 5:15) |>
    pivot_longer(-variabile, values_to = "etichetta") |>
    filter(!is.na(etichetta)) |>
    transmute(variabile, chiave = norm(etichetta), etichetta = str_squish(str_remove(etichetta, "\\.0$"))) |>
    distinct(variabile, chiave, .keep_all = TRUE) |>
    filter(variabile %in% variabili)
  ambigue <- filter(etichette, str_detect(etichetta, "^[=+<>]|^\\d+\\s*[-/.:]\\s*\\d+"))
  if (nrow(ambigue) > 0) stop("Sheets would read these labels as dates or formulas: ", paste(ambigue$etichetta, collapse = ", "))
  etichetta <- function(v, x) {     # coded value -> codebook label; values outside the codebook stay as coded
    e <- filter(etichette, variabile == v)
    replace_na(coalesce(e$etichetta[match(x, e$chiave)], x), "")
  }

  # ---- corpus: gemini_stato and the validated variables
  c0 <- ncol(corpus) - 1                       # 0-based index of the first new column
  codificati <- inner_join(select(corpus, caso, riga), validata, by = "caso") |> arrange(riga)
  if (nrow(codificati) != nrow(validata)) stop("Some coded cases are not in the corpus tab.")
  blocchi <- split(codificati, cumsum(c(1, diff(codificati$riga) != 1)))
  req_corpus <- c(
    list(
      list(appendDimension = list(sheetId = id_corpus, dimension = "COLUMNS",
                                  length = max(1, c0 + 1 + k - colonne_griglia))),
      incolla(id_corpus, 0, c0, list(c("gemini_stato", paste0("gemini_", variabili)))),
      formato(id_corpus, 0, 1, c0, c0 + 1 + k,
              list(textFormat = list(bold = TRUE),
                   backgroundColorStyle = list(rgbColor = list(red = 0.949, green = 0.655, blue = 0.627))),
              "textFormat.bold,userEnteredFormat.backgroundColorStyle")
    ),
    map(blocchi, \(b) incolla(id_corpus, b$riga[1], c0, pmap(
      c(list(b$stato), map(variabili, \(v) etichetta(v, b[[v]]))), c
    ))) |> unname()
  )

  # ---- analisi: one row per variable and codebook value. Every data row holds
  # the same formula: it finds its corpus column from the name in A and counts
  # the value in B, so a group can add rows of its own.
  ultima <- nrow(corpus) + 1
  col <- \(nome) lettera(match(nome, names(corpus)) - 1)
  stato <- lettera(c0)
  piattaforme <- if ("piattaforma" %in% names(corpus)) sort(unique(na.omit(corpus$piattaforma)), decreasing = TRUE) else character()
  n_p <- length(piattaforme)
  mesi <- sort(unique(str_sub(corpus$data[corpus$caso %in% validata$caso], 1, 7)))
  n_mesi <- 12 * (as.integer(str_sub(max(mesi), 1, 4)) - as.integer(str_sub(min(mesi), 1, 4))) +
    as.integer(str_sub(max(mesi), 6, 7)) - as.integer(str_sub(min(mesi), 6, 7)) + 1
  risposte <- leggi_risposte(file.path(dir_gruppo, "corpus_risposte.jsonl"))
  registro <- leggi_tab(xlsx, "registro_agente") |> filter(!is.na(`prompt (testo completo o link)`))
  riga_prompt <- slice_tail(if (any(registro$foglio == "gemini_B")) filter(registro, foglio == "gemini_B") else registro, n = 1)
  corretto <- file.exists(file.path(dir_gruppo, "prompt.txt"))
  versione <- paste0("versione ", replace_na(norm(riga_prompt$`versione del prompt`), "non indicata"),
                     if (corretto) " con correzioni" else "")
  prompt <- paste0("registro_agente, foglio ", riga_prompt$foglio, ", ", versione,
                   if (corretto) " (testo finale nell'ultima riga di registro_agente)" else "")

  FUORI <- "(fuori codebook)"
  voci <- map(variabili, \(v) filter(etichette, variabile == v)$etichetta)
  righe_1 <- unlist(map2(variabili, voci, \(v, e) map(c(e, FUORI), \(x) c(v, x))), recursive = FALSE)
  righe_v <- unlist(map2(variabili, voci, \(v, e) map(e, \(x) c(v, x))), recursive = FALSE)
  n_1 <- length(righe_1)
  n_v <- length(righe_v)
  r1 <- 15                                     # first data row of each table, 1-based
  r2 <- r1 + n_1 + 4                           # blank, title, header, "casi codificati"
  r3 <- if (n_p > 0) r2 + n_v + 4 else r2
  S <- sprintf("corpus!$%s$2:$%s$%d", stato, stato, ultima)
  colonna <- \(r) sprintf('INDEX(corpus!$A$2:$%s$%d,0,MATCH("gemini_"&$A%d,corpus!$1:$1,0))', lettera(c0 + k), ultima, r)
  con_formule <- \(righe, formule) imap(righe, \(x, i) if (i == 1) c(x, formule) else x)
  P <- \(p) sprintf('corpus!$%s$2:$%s$%d,"%s"', col("piattaforma"), col("piattaforma"), ultima, p)
  mese_ok <- sprintf('(TEXT(corpus!$%s$2:$%s$%d,"yyyy-mm")=C$%d)*(%s="ok")', col("data"), col("data"), ultima, r3 - 2, S)
  A <- c(
    list("Analisi descrittiva della codifica Gemini sul corpus", nota, "",
         c("Modello", paste(MODEL, "(via API, un caso per richiesta)")),
         c("Prompt", prompt),
         c("Data della codifica", str_sub(max(map_chr(risposte, "ora")), 1, 10)),
         c("Casi nel corpus", "=COUNTA(corpus!A2:A)"),
         c("Casi codificati (gemini_stato = ok)", sprintf('=COUNTIF(corpus!%s2:%s,"ok")', stato, stato)),
         c("Casi con risposta non valida", sprintf("=COUNTA(corpus!%s2:%s)-B8", stato, stato)),
         c("Casi non codificati (altra lingua o senza file)", sprintf("=B7-COUNTA(corpus!%s2:%s)", stato, stato)),
         c("Variabili riportate", "Quelle con kappa >= 0,60 sul campione B nella codifica in chat (foglio kappa_gemini). La replica della prova via API è nel foglio kappa_gemini_API."),
         "", "1. Frequenze per variabile", c("variabile", "valore", "casi", "% dei casi codificati")),
    con_formule(righe_1, c(sprintf('=COUNTIFS(%s,"ok",%s,$B%d)', S, colonna(r1), r1),
                           sprintf('=IF($B$8=0,"",C%d/$B$8)', r1))),
    if (n_p > 0) c(
      list("", "2. Per piattaforma",
           c("variabile", "valore", unlist(map(piattaforme, \(p) paste0(p, c(": casi", ": % dei codificati"))))),
           c("casi codificati", "", unlist(map(piattaforme, \(p) c(sprintf('=COUNTIFS(%s,%s,"ok")', P(p), S), ""))))),
      con_formule(righe_v, unlist(imap(piattaforme, \(p, j) {
        n <- lettera(2 * j)
        c(sprintf('=COUNTIFS(%s,%s,"ok",%s,$B%d)', P(p), S, colonna(r2), r2),
          sprintf('=IF(%s$%d=0,"",%s%d/%s$%d)', n, r2 - 1, n, r2, n, r2 - 1))
      })))
    ),
    list("", paste0(if (n_p > 0) "3" else "2", ". Per mese: numero di casi"),
         c("variabile", "valore", sprintf('=TEXT(EDATE(DATE(%s,%d,1),COLUMN()-3),"yyyy-mm")',
                                          str_sub(min(mesi), 1, 4), as.integer(str_sub(min(mesi), 6, 7)))),
         c("casi codificati", "", sprintf("=SUMPRODUCT(%s)", mese_ok))),
    con_formule(righe_v, sprintf('=SUMPRODUCT(%s*(%s&""=$B%d&""))', mese_ok, colonna(r3), r3))
  )
  riempi <- function(r0, r1, c0, c1, R0, R1, C0, C1) list(copyPaste = list(   # 0-based, end exclusive
    source = list(sheetId = ID_ANALISI, startRowIndex = r0, endRowIndex = r1, startColumnIndex = c0, endColumnIndex = c1),
    destination = list(sheetId = ID_ANALISI, startRowIndex = R0, endRowIndex = R1, startColumnIndex = C0, endColumnIndex = C1),
    pasteType = "PASTE_NORMAL"
  ))
  fine_var <- r1 - 1 + cumsum(lengths(voci) + 1)          # row of each variable's "(fuori codebook)"
  n_col <- max(10, n_mesi + 3, 2 * n_p + 3)
  req_tab <- c(
    list(nuovo_foglio(ID_ANALISI, "analisi", indice_corpus + 1, r3 + n_v + 20, n_col),
         incolla(ID_ANALISI, 0, 0, A),
         riempi(r1 - 1, r1, 2, 4, r1, r1 - 1 + n_1, 2, 4)),
    map2(fine_var, lengths(voci), \(r, n) incolla(ID_ANALISI, r - 1, 2, list(sprintf("=$B$8-SUM(C%d:C%d)", r - n, r - 1)))),
    if (n_p > 0 && n_v > 1) list(riempi(r2 - 1, r2, 2, 2 + 2 * n_p, r2, r2 - 1 + n_v, 2, 2 + 2 * n_p)),
    if (n_v > 1) list(riempi(r3 - 1, r3, 2, 3, r3, r3 - 1 + n_v, 2, 3)),
    if (n_mesi > 1) list(riempi(r3 - 3, r3 - 1 + n_v, 2, 3, r3 - 3, r3 - 1 + n_v, 3, 2 + n_mesi)),
    list(grassetto(ID_ANALISI, 0, 2, 0, 1), grassetto(ID_ANALISI, 3, 11, 0, 1),
         grassetto(ID_ANALISI, r1 - 3, r1 - 1, 0, n_col), grassetto(ID_ANALISI, r3 - 4, r3 - 2, 0, n_col),
         percento(ID_ANALISI, r1 - 1, r1 - 1 + n_1, 3, 4)),
    if (n_p > 0) c(list(grassetto(ID_ANALISI, r2 - 4, r2 - 2, 0, n_col)),
                   map(seq_len(n_p), \(j) percento(ID_ANALISI, r2 - 1, r2 - 1 + n_v, 2 * j + 1, 2 * j + 2))),
    list(larghezza(ID_ANALISI, 0, 1, 330), larghezza(ID_ANALISI, 1, 2, 220), larghezza(ID_ANALISI, 2, n_col, 120))
  )

  # ---- kappa_gemini_API: every pass of sample B through the API
  umano <- leggi_tab(xlsx, "riconciliato_B")
  kappa_chat <- kappa_del_foglio(xlsx)
  file_passaggi <- c(sort(Sys.glob(file.path(dir_gruppo, "_*pass*", "controllo_codifica.csv"))),
                     file.path(dir_gruppo, "controllo_codifica.csv"))
  passaggi <- map(file_passaggi[file.exists(file_passaggi)], \(f) read_csv(f, col_types = cols(.default = "c")))
  if (length(passaggi) == 0) stop("No controllo_codifica.csv for ", gruppo, ": run controllo first.")
  tutte <- setdiff(names(passaggi[[1]]), c("caso", "stato"))
  num <- \(x) if_else(is.na(x), "n.c.", as.character(round(x, 2)))
  esito <- \(x) if (anyNA(x)) "n.c." else if (all(x >= SOGLIA_KAPPA)) "sì" else "no"
  righe_kappa <- map(tutte, \(v) {
    uniti <- map(passaggi, \(p) inner_join(select(p, caso, api = all_of(v)),
                                           select(umano, caso, umano = all_of(v)), by = "caso") |> arrange(caso))
    stat <- map_dfr(uniti, \(u) cohen_kappa(u$umano, u$api))
    stessi <- sum(!is.na(reduce(map(uniti, "api"), \(a, b) if_else(a == b, a, NA_character_))))
    chat <- kappa_chat$kappa_foglio[kappa_chat$variabile == v]
    c(v, num(chat), num(stat$kappa), num(mean(stat$accordo)), stessi, esito(chat), esito(stat$kappa))
  })
  n_p <- length(passaggi)
  date <- map_chr(leggi_risposte(file.path(dir_gruppo, "controllo_risposte.jsonl")), "ora")
  K <- c(
    list("Replica via API della prova sul campione B",
         sprintf("Stesso prompt (%s), stessi %d casi e stesso confronto con riconciliato_B della prova in chat. %d passaggi indipendenti (ultimo: %s) con %s via API, un caso per richiesta con il file allegato.",
                 prompt, nrow(passaggi[[1]]), n_p, str_sub(max(date), 1, 10), MODEL),
         "",
         c("variabile", "kappa in chat (kappa_gemini)", paste("kappa API, passaggio", seq_len(n_p)),
           sprintf("accordo API-umano (media dei %d passaggi)", n_p),
           sprintf("casi con lo stesso valore in tutti i passaggi (su %d)", nrow(passaggi[[1]])),
           "supera 0,60 in chat", "supera 0,60 via API in tutti i passaggi")),
    righe_kappa,
    list("", "n.c. = kappa non calcolabile: tutti i casi hanno lo stesso valore.",
         "Nel foglio corpus sono riportate le variabili che superano 0,60 nella prova in chat (colonna B). Le colonne dei passaggi API mostrano quanto quel risultato regge quando lo stesso prompt passa dall'API.")
  )
  req_tab <- c(req_tab, list(
    nuovo_foglio(ID_KAPPA, "kappa_gemini_API", indice_kappa + 2, length(K) + 10),   # +1 for analisi
    incolla(ID_KAPPA, 0, 0, K),
    grassetto(ID_KAPPA, 0, 1, 0, 1),
    formato(ID_KAPPA, 3, 4, 0, 10, list(textFormat = list(bold = TRUE), wrapStrategy = "WRAP"),
            "textFormat.bold,userEnteredFormat.wrapStrategy"),
    formato(ID_KAPPA, 4, 4 + length(tutte), 1, 3 + n_p,
            list(numberFormat = list(type = "NUMBER", pattern = "0.00")), "numberFormat"),
    larghezza(ID_KAPPA, 0, 10, 170)
  ))

  # ---- registro_agente: the final prompt, as sent through the API
  file_modifiche <- file.path(dir_gruppo, "prompt_modifiche.txt")
  if (corretto && !file.exists(file_modifiche)) stop("prompt.txt without prompt_modifiche.txt for ", gruppo, ".")
  stati <- map_chr(risposte, "stato")
  riga <- c(
    data = format(as.Date(max(map_chr(risposte, "ora"))), "%d/%m/%Y"),
    foglio = "API: campione B e corpus",
    modello = MODEL,
    impostazioni = paste0("API, un caso per richiesta, ", if (g_con_media(gruppo, corpus)) "con" else "senza", " il file allegato"),
    `versione del prompt` = versione,
    `prompt (testo completo o link)` = if (corretto) read_file(file.path(dir_gruppo, "prompt.txt")) else riga_prompt$`prompt (testo completo o link)`,
    `numero di casi` = as.character(length(stati)),
    `risposte mancanti` = as.character(sum(stati == "bloccato")),
    `risposte fuori formato` = as.character(sum(stati == "fuori formato")),
    `che cosa è cambiato nel prompt` = if (corretto) str_trim(read_file(file_modifiche)) else "Nessuna modifica rispetto al prompt registrato dal gruppo.",
    `perché` = if (corretto) "Correzione di errori evidenti prima del passaggio via API. Definizioni e valori delle variabili non sono stati toccati." else ""
  )
  mancanti <- setdiff(names(riga), names(registro))
  if (length(mancanti) > 0) stop("registro_agente lacks the columns: ", paste(mancanti, collapse = ", "))
  req_registro <- list(list(appendCells = list(
    sheetId = id_registro, fields = "userEnteredValue",
    rows = list(list(values = map(names(registro), \(n) list(userEnteredValue = list(stringValue = unname(replace_na(riga[n], "")))))))
  )))
  write(toJSON(req_registro, auto_unbox = TRUE), file.path(dir_gruppo, "foglio_req_registro.json"))

  write(toJSON(req_corpus, auto_unbox = TRUE), file.path(dir_gruppo, "foglio_req_corpus.json"))
  write(toJSON(req_tab, auto_unbox = TRUE), file.path(dir_gruppo, "foglio_req_tab.json"))
  message(gruppo, ": ", nrow(codificati), " coded rows in ", length(blocchi), " blocks, ", k,
          " variables (", paste(variabili, collapse = ", "), "), ", n_p, " API passes of sample B, ",
          n_mesi, " months.")
  invisible(list(corpus = req_corpus, tab = req_tab))
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 5) stop("Usage: gemini-sheet-layout.R <gruppo> <corpus sheetId> <corpus index> <kappa_gemini index> <registro_agente sheetId> [grid columns] [note]")
  costruisci(args[1], as.numeric(args[2]), as.numeric(args[3]), as.numeric(args[4]), as.numeric(args[5]),
             if (length(args) >= 6) as.numeric(args[6]) else 26,
             if (length(args) >= 7) args[7] else "")
}
