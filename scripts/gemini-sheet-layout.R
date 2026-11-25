#!/usr/bin/env Rscript
# Build the Google Sheets update that publishes a group's Gemini coding in its
# own sheet. It writes nothing to Google: it produces the batchUpdate requests,
# which are then sent through a Sheets client.
#
#   Rscript scripts/gemini-sheet-layout.R G08 <corpus sheetId> <corpus tab index> \
#       <kappa_gemini tab index> [corpus grid columns = 26] [note for the header]
#
# The three numbers come from the live sheet (spreadsheets.get, sheets.properties).
#
# Layout (approved on G08, 2026-11-25; the same for every group)
#   corpus            keeps its name; to the right of the existing columns,
#                     gemini_stato and one gemini_<variabile> column for every
#                     variable whose chat kappa on sample B is >= SOGLIA_KAPPA
#   analisi           new tab after corpus: provenance, then frequencies per
#                     variable, by platform and by month, all as formulas
#   kappa_gemini_API  new tab after kappa_gemini: the sample-B test repeated
#                     through the API, for every variable of the codebook
#
# Inputs, under data/2026-27/gemini-run/<gruppo>/ (run gemini-corpus-run.R first)
#   foglio.xlsx, corpus_validata.csv, corpus_risposte.jsonl
#   controllo_codifica.csv, plus _*pass*/controllo_codifica.csv for further passes
# Outputs, same folder (git-ignored)
#   foglio_req_corpus.json, foglio_req_tab.json

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
nuovo_foglio <- function(id, titolo, indice, righe) list(addSheet = list(properties = list(
  sheetId = id, title = titolo, index = indice, gridProperties = list(rowCount = righe, columnCount = 10)
)))
valore <- \(v) if_else(v == "98", "98", str_to_sentence(v)) |> replace_na("")

costruisci <- function(gruppo, id_corpus, indice_corpus, indice_kappa, colonne_griglia = 26, nota = "") {
  dir_gruppo <- file.path(RUN_DIR, gruppo)
  xlsx <- file.path(dir_gruppo, "foglio.xlsx")
  corpus <- leggi_tab(xlsx, "corpus") |> mutate(riga = row_number())
  validata <- read_csv(file.path(dir_gruppo, "corpus_validata.csv"), col_types = cols(.default = "c"))
  variabili <- setdiff(names(validata), c("caso", "stato"))
  k <- length(variabili)
  if (k == 0) stop("No validated variable for ", gruppo, ": nothing to publish.")
  if (any(str_detect(names(corpus), "^gemini_"))) stop("corpus already has gemini_ columns.")

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
      c(list(b$stato), map(variabili, \(v) valore(b[[v]]))), c
    ))) |> unname()
  )

  # ---- analisi
  ultima <- nrow(corpus) + 1
  col <- \(nome) lettera(match(nome, names(corpus)) - 1)
  stato <- lettera(c0)
  L <- map_chr(seq_len(k), \(i) lettera(c0 + i))
  piattaforme <- sort(unique(na.omit(corpus$piattaforma)), decreasing = TRUE)
  mesi <- sort(unique(str_sub(corpus$data[corpus$caso %in% validata$caso], 1, 7)))
  n_mesi <- 12 * (as.integer(str_sub(max(mesi), 1, 4)) - as.integer(str_sub(min(mesi), 1, 4))) +
    as.integer(str_sub(max(mesi), 6, 7)) - as.integer(str_sub(min(mesi), 6, 7)) + 1
  risposte <- leggi_risposte(file.path(dir_gruppo, "corpus_risposte.jsonl"))
  registro <- leggi_tab(xlsx, "registro_agente") |> filter(!is.na(`prompt (testo completo o link)`))
  riga_prompt <- slice_tail(if (any(registro$foglio == "gemini_B")) filter(registro, foglio == "gemini_B") else registro, n = 1)
  prompt <- if (file.exists(file.path(dir_gruppo, "prompt.txt"))) "prompt.txt consegnato dal gruppo" else
    paste0("registro_agente, foglio ", riga_prompt$foglio, ", versione ", norm(riga_prompt$`versione del prompt`))
  S <- sprintf("corpus!$%s$2:$%s", stato, stato)
  conta <- \(l, v) sprintf('=COUNTIFS(%s,"ok",corpus!%s$2:%s,%s)', S, l, l, v)
  r1 <- 14                                     # rows are 1-based from here on
  r2 <- 17 + k
  r3 <- 20 + 2 * k
  intervallo <- \(l) sprintf("corpus!%s$2:%s$%d", l, l, ultima)
  mese <- sprintf('(TEXT(corpus!$%s$2:$%s$%d,"yyyy-mm")=$A%d)*(corpus!$%s$2:$%s$%d="ok")',
                  col("data"), col("data"), ultima, r3 + 1, stato, stato, ultima)
  A <- c(
    list("Analisi descrittiva della codifica Gemini sul corpus", nota, "",
         c("Modello", paste(MODEL, "(via API, un caso per richiesta con il file allegato)")),
         c("Prompt", prompt),
         c("Data della codifica", str_sub(max(map_chr(risposte, "ora")), 1, 10)),
         c("Casi nel corpus", "=COUNTA(corpus!A2:A)"),
         c("Casi codificati (gemini_stato = ok)", sprintf('=COUNTIF(corpus!%s2:%s,"ok")', stato, stato)),
         c("Casi con risposta non valida", sprintf("=COUNTA(corpus!%s2:%s)-B8", stato, stato)),
         c("Casi non codificati (altra lingua o senza file)", sprintf("=B7-COUNTA(corpus!%s2:%s)", stato, stato)),
         c("Variabili riportate", "Quelle con kappa >= 0,60 sul campione B nella codifica in chat (foglio kappa_gemini). La replica della prova via API è nel foglio kappa_gemini_API."),
         "", "1. Frequenze per variabile",
         c("variabile", "Presente", "Assente", "98", "totale", "% Presente", "% Assente", "% 98")),
    map(seq_len(k), \(i) {
      r <- r1 + i
      c(variabili[i], conta(L[i], '"Presente"'), conta(L[i], '"Assente"'), conta(L[i], "98"),
        sprintf("=SUM(B%d:D%d)", r, r), sprintf('=IF(E%d=0,"",%s%d/E%d)', r, c("B", "C", "D"), r, r))
    }),
    list("", "2. Per piattaforma: casi con valore Presente",
         c("variabile", unlist(map(piattaforme, \(p) paste0(p, c(": codificati", ": Presente", ": %")))))),
    map(seq_len(k), \(i) {
      r <- r2 + i
      c(variabili[i], unlist(imap(piattaforme, \(p, j) {
        P <- sprintf('corpus!$%s$2:$%s,"%s"', col("piattaforma"), col("piattaforma"), p)
        n <- lettera(3 * j - 2)
        c(sprintf('=COUNTIFS(%s,%s,"ok")', P, S),
          sprintf('=COUNTIFS(%s,%s,"ok",corpus!%s$2:%s,"Presente")', P, S, L[i], L[i]),
          sprintf('=IF(%s%d=0,"",%s%d/%s%d)', n, r, lettera(3 * j - 1), r, n, r))
      })))
    }),
    list("", "3. Per mese: casi con valore Presente", c("mese", "codificati", variabili),
         c(sprintf('=TEXT(EDATE(DATE(%s,%d,1),ROW()-%d),"yyyy-mm")', str_sub(min(mesi), 1, 4),
                   as.integer(str_sub(min(mesi), 6, 7)), r3 + 1),
           sprintf("=SUMPRODUCT(%s)", mese),
           map_chr(L, \(l) sprintf('=SUMPRODUCT(%s*(%s="Presente"))', mese, intervallo(l)))))
  )
  req_tab <- c(
    list(nuovo_foglio(ID_ANALISI, "analisi", indice_corpus + 1, r3 + n_mesi + 20),
         incolla(ID_ANALISI, 0, 0, A)),
    if (n_mesi > 1) list(list(copyPaste = list(
      source = list(sheetId = ID_ANALISI, startRowIndex = r3, endRowIndex = r3 + 1,
                    startColumnIndex = 0, endColumnIndex = k + 2),
      destination = list(sheetId = ID_ANALISI, startRowIndex = r3 + 1, endRowIndex = r3 + n_mesi,
                         startColumnIndex = 0, endColumnIndex = k + 2),
      pasteType = "PASTE_NORMAL"
    ))),
    list(grassetto(ID_ANALISI, 0, 2, 0, 1), grassetto(ID_ANALISI, 3, 11, 0, 1),
         grassetto(ID_ANALISI, r1 - 2, r1, 0, 10), grassetto(ID_ANALISI, r2 - 2, r2, 0, 10),
         grassetto(ID_ANALISI, r3 - 2, r3, 0, 10), percento(ID_ANALISI, r1, r1 + k, 5, 8)),
    map(seq_along(piattaforme), \(j) percento(ID_ANALISI, r2, r2 + k, 3 * j, 3 * j + 1)),
    list(larghezza(ID_ANALISI, 0, 1, 330), larghezza(ID_ANALISI, 1, 10, 150))
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

  write(toJSON(req_corpus, auto_unbox = TRUE), file.path(dir_gruppo, "foglio_req_corpus.json"))
  write(toJSON(req_tab, auto_unbox = TRUE), file.path(dir_gruppo, "foglio_req_tab.json"))
  message(gruppo, ": ", nrow(codificati), " coded rows in ", length(blocchi), " blocks, ", k,
          " variables (", paste(variabili, collapse = ", "), "), ", n_p, " API passes of sample B, ",
          n_mesi, " months.")
  invisible(list(corpus = req_corpus, tab = req_tab))
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 4) stop("Usage: gemini-sheet-layout.R <gruppo> <corpus sheetId> <corpus index> <kappa_gemini index> [grid columns] [note]")
  costruisci(args[1], as.numeric(args[2]), as.numeric(args[3]), as.numeric(args[4]),
             if (length(args) >= 5) as.numeric(args[5]) else 26,
             if (length(args) >= 6) args[6] else "")
}
