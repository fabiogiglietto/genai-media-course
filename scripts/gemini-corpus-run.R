#!/usr/bin/env Rscript
# Run a group's frozen Gemini prompt over its validation sample or whole corpus.
#
#   Rscript scripts/gemini-corpus-run.R G08 prova           # offline: no API call
#   Rscript scripts/gemini-corpus-run.R G08 controllo       # sample B via API, kappa
#   Rscript scripts/gemini-corpus-run.R G08 corpus 25       # first 25 corpus cases
#   Rscript scripts/gemini-corpus-run.R G08 corpus          # whole corpus
#
# Batch API (half price, results within about a day): append -batch to submit
# and -ritira to collect, for either controllo or corpus.
#   Rscript scripts/gemini-corpus-run.R G08 corpus-batch
#   Rscript scripts/gemini-corpus-run.R G08 corpus-ritira
#
# Inputs
#   - data/2026-27/gemini-run/gruppi.csv   gruppo,sheet_id (git-ignored: the
#     sheets are link-shared, so their IDs must never reach the public repo).
#     An optional third column, media_nei_commenti (sì/no), says whether a
#     group that codes comments had the video attached; blank means the default
#   - the group sheet, downloaded as .xlsx through its share link
#   - the frozen prompt: data/2026-27/gemini-run/<gruppo>/prompt.txt if present,
#     otherwise the registro_agente row for gemini_B (or the last row)
#   - media files in MEDIA_DIRS; GEMINI_API_KEY in ~/.Renviron
#
# Outputs, all under data/2026-27/gemini-run/<gruppo>/ (git-ignored)
#   <modo>_risposte.jsonl   one line per case, appended: a rerun resumes
#   <modo>_codifica.csv     one row per case, one column per variable
#   controllo_kappa.csv     API kappa on sample B next to the sheet's kappa
#   corpus_validata.csv     corpus coding, validated variables only

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
  library(tidyr)
  library(stringr)
  library(httr2)
  library(readxl)
  library(jsonlite)
  library(here)
})

# --- Configuration -----------------------------------------------------------

MODEL <- "gemini-4-hydrogen"      # confirm it is the model the groups used
MEDIA_DIRS <- c(                  # local copies of the Drive media folders
  here("data", "2026-27", "tiktok_video"),
  here("data", "2026-27", "instagram_media")
)
LINGUE <- c("it", "en")           # corpus rows coded; NULL keeps every language
MEDIA_NEI_COMMENTI <- FALSE       # default; gruppi.csv can set it per group
SOGLIA_KAPPA <- 0.60
RICHIESTE_AL_MINUTO <- 300
CARICAMENTI_PARALLELI <- 8
RUN_DIR <- here("data", "2026-27", "gemini-run")
API <- "https://generativelanguage.googleapis.com"

# --- Small helpers -----------------------------------------------------------

# Sheets exports 98 as "98.0"; coders and Gemini differ in case, spacing and
# in straight or typographic apostrophes.
norm <- function(x) {
  x <- str_replace_all(str_remove(as.character(x), "\\.0$"), "[\u2018\u2019]", "'")
  str_to_lower(str_squish(x))
}

api_key <- function() {
  key <- Sys.getenv("GEMINI_API_KEY")
  if (!nzchar(key)) stop("GEMINI_API_KEY is not set (add it to ~/.Renviron).")
  key
}

gemini_request <- function(url) {
  request(url) |>
    req_headers(`x-goog-api-key` = api_key(), .redact = "x-goog-api-key") |>
    req_throttle(capacity = RICHIESTE_AL_MINUTO, fill_time_s = 60) |>
    req_retry(
      max_tries = 6,
      # A full file store also answers 429, and waiting does not empty it.
      is_transient = \(resp) resp_status(resp) %in% c(429, 500, 503) &&
        !str_detect(resp_body_string(resp), "file_storage_bytes"),
      backoff = \(i) min(120, 5 * 2^i)
    ) |>
    req_timeout(600)
}

cohen_kappa <- function(a, b) {
  a <- norm(a)
  b <- norm(b)
  ok <- !is.na(a) & !is.na(b) & a != "" & b != ""
  a <- a[ok]
  b <- b[ok]
  n <- length(a)
  if (n == 0) return(tibble(casi = 0L, accordo = NA_real_, kappa = NA_real_))
  osservato <- mean(a == b)
  categorie <- union(a, b)
  atteso <- sum(map_dbl(categorie, \(k) mean(a == k) * mean(b == k)))
  tibble(
    casi = n,
    accordo = osservato,
    kappa = if (atteso >= 1) NA_real_ else (osservato - atteso) / (1 - atteso)
  )
}

# --- Group sheet -------------------------------------------------------------

leggi_gruppi <- function() read_csv(file.path(RUN_DIR, "gruppi.csv"), col_types = cols(.default = "c"))

# Whether a group that codes comments had the video attached in its chat test.
media_nei_commenti <- function(gruppo) {
  gruppi <- leggi_gruppi()
  scelta <- if ("media_nei_commenti" %in% names(gruppi)) gruppi$media_nei_commenti[gruppi$gruppo == gruppo] else NA
  if (length(scelta) != 1 || is.na(scelta) || scelta == "") return(MEDIA_NEI_COMMENTI)
  norm(scelta) %in% c("sì", "si", "true", "1")
}

scarica_foglio <- function(gruppo) {
  gruppi <- leggi_gruppi()
  id <- gruppi$sheet_id[gruppi$gruppo == gruppo]
  if (length(id) != 1) stop("Group ", gruppo, " is not in gruppi.csv.")
  dir.create(file.path(RUN_DIR, gruppo), recursive = TRUE, showWarnings = FALSE)
  dest <- file.path(RUN_DIR, gruppo, "foglio.xlsx")
  request(sprintf("https://docs.google.com/spreadsheets/d/%s/export", id)) |>
    req_url_query(format = "xlsx") |>
    req_perform(path = dest)
  dest
}

leggi_tab <- function(xlsx, tab) {
  suppressMessages(read_excel(xlsx, sheet = tab, col_types = "text"))
}

leggi_gruppo <- function(xlsx) {
  codebook <- suppressMessages(
    read_excel(xlsx, sheet = "codebook", range = "A1:O16", col_types = "text")
  ) |>
    filter(!is.na(variabile), str_squish(variabile) != "") |>
    mutate(variabile = str_squish(variabile))
  valori <- codebook |>
    select(variabile, 5:15) |>
    pivot_longer(-variabile, values_to = "valore") |>
    filter(!is.na(valore)) |>
    mutate(valore = norm(valore)) |>
    distinct(variabile, valore)

  gemini_b <- leggi_tab(xlsx, "gemini_B")
  corpus <- leggi_tab(xlsx, "corpus")
  commenti <- "commento" %in% names(corpus)
  list(
    variabili = codebook$variabile,
    valori = valori,
    # Columns A:J of the coding tabs are what the coders, and Gemini, were shown.
    campi = intersect(names(gemini_b)[1:10], names(corpus)),
    col_media = if (commenti) "media_video" else "media",
    commenti = commenti,
    corpus = corpus,
    gemini_b = gemini_b,
    riconciliato_b = leggi_tab(xlsx, "riconciliato_B"),
    registro = leggi_tab(xlsx, "registro_agente"),
    kappa_foglio = kappa_del_foglio(xlsx)
  )
}

# The kappa the group obtained in the chat interface on sample B.
kappa_del_foglio <- function(xlsx) {
  blocco <- suppressMessages(read_excel(
    xlsx, sheet = "kappa_gemini", range = "A4:AJ22",
    col_names = FALSE, col_types = "text"
  ))
  j <- which(unlist(blocco[1, ]) == "gemini_B")
  if (length(j) != 1) stop("kappa_gemini has no gemini_B block.")
  tibble(
    variabile = str_squish(blocco[[1]][-(1:4)]),
    kappa_foglio = suppressWarnings(as.numeric(blocco[[j + 1]][-(1:4)]))
  ) |>
    filter(!is.na(variabile), variabile != "")
}

prompt_finale <- function(gruppo, registro) {
  file_locale <- file.path(RUN_DIR, gruppo, "prompt.txt")
  if (file.exists(file_locale)) return(read_file(file_locale))
  registro <- filter(registro, !is.na(`prompt (testo completo o link)`))
  if (nrow(registro) == 0) stop("registro_agente holds no prompt for ", gruppo, ".")
  test <- filter(registro, foglio == "gemini_B")
  if (nrow(test) == 0) warning("No gemini_B row in registro_agente: using the last prompt logged, not a tested one.")
  riga <- if (nrow(test) > 0) slice_tail(test, n = 1) else slice_tail(registro, n = 1)
  prompt <- riga$`prompt (testo completo o link)`
  if (str_detect(prompt, "^\\s*https?://\\S+\\s*$")) {
    stop("The register holds a link, not the prompt text: save the text in ", file_locale)
  }
  message("Prompt: registro_agente, foglio ", riga$foglio,
          ", versione ", norm(riga$`versione del prompt`))
  prompt
}

# --- Gemini API --------------------------------------------------------------

trova_media <- function(nome) {
  if (is.na(nome) || nome == "") return(NA_character_)
  percorsi <- file.path(MEDIA_DIRS, nome)
  percorsi[file.exists(percorsi)][1]
}

# Uploads `percorsi` in parallel and returns file, uri, mime for every file the
# API holds. The API deletes files after 48 hours, so older uploads are redone.
carica_tutti <- function(percorsi, registro_file, eta_max_ore = 46) {
  percorsi <- unique(percorsi)
  noti <- if (file.exists(registro_file)) {
    read_csv(registro_file, col_types = "cccT")
  } else {
    tibble(file = character(), uri = character(), mime = character(), caricato = as.POSIXct(character()))
  }
  validi <- noti |>
    filter(caricato > Sys.time() - eta_max_ore * 3600) |>
    slice_tail(n = 1, by = file)
  mancanti <- percorsi[!basename(percorsi) %in% validi$file]
  if (length(mancanti) > 0) message("Uploading ", length(mancanti), " files...")
  in_parallelo <- \(richieste) req_perform_parallel(
    richieste, max_active = CARICAMENTI_PARALLELI, on_error = "continue", progress = FALSE
  )
  riuscita <- \(risposte) map_lgl(risposte, \(r) inherits(r, "httr2_response"))

  # Blocks of 50, so an interrupted run keeps what it has already uploaded.
  n_persi <- 0
  for (blocco in split(mancanti, ceiling(seq_along(mancanti) / 50))) {
    blocco_iniziale <- blocco
    avvii <- in_parallelo(map(blocco, richiesta_avvio))
    blocco <- blocco[riuscita(avvii)]
    invii <- in_parallelo(map2(blocco, avvii[riuscita(avvii)], richiesta_invio))
    file_api <- map(invii[riuscita(invii)], \(r) resp_body_json(r)$file)
    # Video is usable only once the API has finished processing it. The status
    # request of some files fails every time: after three failures, or fifteen
    # minutes in the block, a file is given up, or the loop would never end.
    errori <- integer(length(file_api))
    scadenza <- Sys.time() + 15 * 60
    repeat {
      in_corso <- which(map_chr(file_api, "state") == "PROCESSING")
      if (length(in_corso) == 0) break
      Sys.sleep(5)
      stati <- in_parallelo(map(file_api[in_corso], \(f) {
        # A status answer is a few bytes: one that takes a minute is not coming.
        gemini_request(paste0(API, "/v1beta/", f$name)) |> req_retry(max_tries = 2) |> req_timeout(60)
      }))
      file_api[in_corso[riuscita(stati)]] <- map(stati[riuscita(stati)], resp_body_json)
      falliti <- in_corso[!riuscita(stati)]
      errori[falliti] <- errori[falliti] + 1
      persi <- if (Sys.time() > scadenza) in_corso else falliti[errori[falliti] >= 3]
      for (i in persi) file_api[[i]]$state <- "FAILED"
    }
    attivi <- keep(file_api, \(f) identical(f$state, "ACTIVE"))
    persi <- setdiff(basename(blocco_iniziale), map_chr(attivi, "displayName"))
    if (length(persi) > 0) {
      message("  not usable (upload or processing failed): ", paste(persi, collapse = ", "))
      n_persi <- n_persi + length(persi)
    }
    nuovi <- tibble(
      file = map_chr(attivi, "displayName"),
      uri = map_chr(attivi, "uri"),
      mime = map_chr(attivi, "mimeType"),
      caricato = Sys.time()
    )
    write_csv(nuovi, registro_file, append = file.exists(registro_file))
    validi <- bind_rows(validi, nuovi)
    message("  ", nrow(validi), " files available")
    # A few unusable files only leave their cases out; many mean the API is
    # refusing uploads (a quota, an outage), and nothing should run on a remnant.
    if (n_persi > max(5, 0.05 * length(mancanti))) {
      stop(n_persi, " of ", length(mancanti), " files could not be uploaded: stopping. A rerun resumes.")
    }
  }
  select(validi, file, uri, mime)
}

# The Files API upload is resumable: one request opens it, a second sends the bytes.
richiesta_avvio <- function(percorso, mime = mime::guess_type(percorso)) {
  gemini_request(paste0(API, "/upload/v1beta/files")) |>
    req_headers(
      `X-Goog-Upload-Protocol` = "resumable",
      `X-Goog-Upload-Command` = "start",
      `X-Goog-Upload-Header-Content-Length` = file.size(percorso),
      `X-Goog-Upload-Header-Content-Type` = mime
    ) |>
    req_body_json(list(file = list(display_name = basename(percorso))))
}

richiesta_invio <- function(percorso, avvio, mime = mime::guess_type(percorso)) {
  gemini_request(resp_header(avvio, "x-goog-upload-url")) |>
    req_headers(`X-Goog-Upload-Offset` = 0, `X-Goog-Upload-Command` = "upload, finalize") |>
    req_body_file(percorso, type = mime)
}

testo_del_caso <- function(caso, campi) {
  valori <- map_chr(campi, \(campo) replace_na(as.character(caso[[campo]]), ""))
  paste0(campi, ": ", valori, collapse = "\n")
}

# The same request body serves the interactive call and a Batch API line.
# No temperature: current Gemini models ignore the sampling parameters.
corpo_richiesta <- function(prompt, testo, uri = NA, mime = NA) {
  parti <- list(list(text = testo))
  if (!is.na(uri)) parti <- c(list(list(fileData = list(fileUri = uri, mimeType = mime))), parti)
  list(
    systemInstruction = list(parts = list(list(text = prompt))),
    contents = list(list(role = "user", parts = parti))
  )
}

# A blocked prompt comes back with no candidates.
estrai_risposta <- function(risposta) {
  candidato <- risposta$candidates[[1]]
  list(
    testo = paste(map_chr(candidato$content$parts %||% list(), \(p) p$text %||% ""), collapse = ""),
    fine = candidato$finishReason %||% NA_character_,
    blocco = risposta$promptFeedback$blockReason %||% NA_character_,
    token = risposta$usageMetadata$totalTokenCount %||% NA_integer_
  )
}

# The prompts ask for a table: one row per case, variables in codebook order,
# case code last; some add a notes column before the case code. Returns one
# value per variable, or NULL when off format.
leggi_risposta <- function(testo, id_caso, variabili) {
  righe <- str_split_1(testo, "\n")
  riga <- righe[str_detect(righe, fixed(id_caso))]
  if (length(riga) == 0) return(NULL)
  riga <- riga[length(riga)]
  tabella <- str_detect(riga, fixed("|"))
  celle <- str_squish(str_remove_all(str_split_1(riga, if (tabella) "\\|" else "\t"), "[*`]"))
  fine <- match(id_caso, celle)
  if (is.na(fine)) return(NULL)
  celle <- celle[seq_len(fine - 1)]
  # A Markdown row opens with a border, which splits into an empty first cell.
  if (tabella && length(celle) > 0 && celle[1] == "") celle <- celle[-1]
  n <- length(variabili)
  if (!length(celle) %in% c(n, n + 1)) return(NULL)
  set_names(norm(celle[seq_len(n)]), variabili)
}

# One record per line; a missing file means nothing has been coded yet.
leggi_risposte <- function(file) {
  if (!file.exists(file)) return(list())
  map(read_lines(file), \(riga) fromJSON(riga, simplifyVector = FALSE))
}

# Parses one answer and appends it to the group's answer file.
registra <- function(id_caso, r, variabili, file_risposte, via) {
  valori <- leggi_risposta(r$testo, id_caso, variabili)
  stato <- if (!is.null(valori)) "ok" else if (!is.na(r$blocco)) "bloccato" else "fuori formato"
  riga <- c(
    list(caso = id_caso, modello = MODEL, via = via, ora = format(Sys.time())),
    r, list(stato = stato, valori = as.list(valori))
  )
  write(toJSON(riga, auto_unbox = TRUE, null = "null"), file_risposte, append = TRUE)
}

# --- Run ---------------------------------------------------------------------

MODI <- c("prova", "controllo", "corpus",
          "controllo-batch", "corpus-batch", "controllo-ritira", "corpus-ritira")

esegui <- function(gruppo, modo = MODI, max_casi = Inf) {
  modo <- match.arg(modo)
  azione <- str_extract(modo, "batch|ritira") |> replace_na("subito")
  modo <- str_remove(modo, "-.*")
  g <- leggi_gruppo(scarica_foglio(gruppo))
  dir_gruppo <- file.path(RUN_DIR, gruppo)
  file_risposte <- file.path(dir_gruppo, paste0(modo, "_risposte.jsonl"))
  if (azione == "ritira") {
    if (ritira_batch(modo, g$variabili, dir_gruppo, file_risposte)) riepiloga(gruppo, modo, g)
    return(invisible())
  }
  prompt <- prompt_finale(gruppo, g$registro)

  casi <- if (modo == "corpus") g$corpus else g$gemini_b
  casi <- filter(casi, !is.na(caso))
  if (modo == "corpus" && !is.null(LINGUE)) casi <- filter(casi, lingua %in% LINGUE)
  con_media <- !g$commenti || media_nei_commenti(gruppo)
  if (g$commenti) message("Comments are coded ", if (con_media) "with" else "without", " the video attached.")
  if (con_media) {
    casi <- mutate(casi, percorso = map_chr(.data[[g$col_media]], trova_media))
    message(sum(is.na(casi$percorso)), " of ", nrow(casi),
            " cases have no media file on disk and are skipped.")
    # The validation samples only hold cases with a media file.
    casi <- filter(casi, !is.na(percorso))
  }
  casi <- slice_head(casi, n = min(max_casi, nrow(casi)))
  message(gruppo, " / ", modo, ": ", nrow(casi), " cases, ",
          length(g$variabili), " variables, model ", MODEL)

  if (nrow(casi) == 0) stop("No cases to code: check MEDIA_DIRS and LINGUE.")

  if (modo == "prova") {
    message("\n--- prompt ---\n", str_trunc(prompt, 600),
            "\n\n--- first case ---\n", testo_del_caso(casi[1, ], g$campi))
    return(invisible(casi))
  }

  fatti <- map_chr(leggi_risposte(file_risposte), "caso")
  da_fare <- filter(casi, !caso %in% fatti) |> mutate(uri = NA_character_, mime = NA_character_)
  message(length(fatti), " already done, ", nrow(da_fare), " to do.")
  if (nrow(da_fare) == 0) return(riepiloga(gruppo, modo, g))
  if (con_media) {
    # A batch may wait a day in the queue: its files must be fresh.
    caricati <- carica_tutti(da_fare$percorso, file.path(dir_gruppo, "caricati.csv"),
                             eta_max_ore = if (azione == "batch") 6 else 46)
    da_fare <- da_fare |>
      select(-uri, -mime) |>
      mutate(file = basename(percorso)) |>
      inner_join(caricati, by = "file")
  }
  da_fare$testo <- map_chr(seq_len(nrow(da_fare)), \(i) testo_del_caso(da_fare[i, ], g$campi))

  if (azione == "batch") return(invia_batch(gruppo, modo, prompt, da_fare, dir_gruppo))

  for (i in seq_len(nrow(da_fare))) {
    caso <- da_fare[i, ]
    # Errors are not written, so a rerun retries them.
    tryCatch({
      risposta <- gemini_request(sprintf("%s/v1beta/models/%s:generateContent", API, MODEL)) |>
        req_body_json(corpo_richiesta(prompt, caso$testo, caso$uri, caso$mime)) |>
        req_perform() |>
        resp_body_json()
      registra(caso$caso, estrai_risposta(risposta), g$variabili, file_risposte, "subito")
    }, error = \(e) message(caso$caso, ": ", conditionMessage(e)))
    if (i %% 25 == 0) message(i, " / ", nrow(da_fare))
  }

  riepiloga(gruppo, modo, g)
}

# --- Batch API ---------------------------------------------------------------

# Creating a batch is not idempotent, so a pending job blocks a second one.
invia_batch <- function(gruppo, modo, prompt, da_fare, dir_gruppo) {
  file_job <- file.path(dir_gruppo, paste0(modo, "_batch.json"))
  if (file.exists(file_job)) {
    stop("A batch is already pending for ", gruppo, " ", modo, ": collect it with ", modo, "-ritira.")
  }
  file_input <- file.path(dir_gruppo, paste0(modo, "_batch_input.jsonl"))
  righe <- pmap_chr(
    list(da_fare$caso, da_fare$testo, da_fare$uri, da_fare$mime),
    \(caso, testo, uri, mime) toJSON(
      list(key = caso, request = corpo_richiesta(prompt, testo, uri, mime)),
      auto_unbox = TRUE
    )
  )
  write_lines(righe, file_input)

  avvio <- req_perform(richiesta_avvio(file_input, "application/jsonl"))
  input <- req_perform(richiesta_invio(file_input, avvio, "application/jsonl")) |> resp_body_json()
  job <- gemini_request(sprintf("%s/v1beta/models/%s:batchGenerateContent", API, MODEL)) |>
    req_body_json(list(batch = list(
      display_name = paste(gruppo, modo, format(Sys.time(), "%Y-%m-%d %H:%M")),
      input_config = list(file_name = input$file$name)
    ))) |>
    req_perform() |>
    resp_body_json()
  write_json(list(name = job$name, inviato = format(Sys.time()), casi = nrow(da_fare)),
             file_job, auto_unbox = TRUE)
  message("Batch submitted: ", job$name, " (", nrow(da_fare), " cases). Collect it with ",
          gruppo, " ", modo, "-ritira.")
  invisible(job$name)
}

# Returns TRUE once the answers have been collected.
ritira_batch <- function(modo, variabili, dir_gruppo, file_risposte) {
  file_job <- file.path(dir_gruppo, paste0(modo, "_batch.json"))
  if (!file.exists(file_job)) stop("No pending batch for ", modo, ".")
  job <- read_json(file_job)
  chiudi <- \(esito) file.rename(file_job, sub("\\.json$", format(Sys.time(), "_%Y%m%d-%H%M_"), file_job) |> paste0(esito, ".json"))
  j <- gemini_request(paste0(API, "/v1beta/", job$name)) |> req_perform() |> resp_body_json()
  # The guide and the API reference place these fields differently.
  stato <- j$metadata$state %||% j$state %||% "?"
  message("Batch ", job$name, " submitted ", job$inviato, ": ", stato)
  # States arrive as BATCH_STATE_* (the guide calls them JOB_STATE_*).
  if (str_detect(stato, "FAILED|CANCELLED|EXPIRED")) {
    chiudi("fallito")
    stop("The batch did not complete (", stato, "): submit it again.")
  }
  if (!str_detect(stato, "SUCCEEDED")) return(FALSE)

  file_esito <- j$response$responsesFile %||% j$response$output$responsesFile %||%
    j$metadata$output$responsesFile %||% j$dest$fileName %||% j$metadata$dest$fileName
  if (is.null(file_esito)) stop("No results file in the batch response: inspect ", job$name)
  file_output <- file.path(dir_gruppo, paste0(modo, "_batch_output.jsonl"))
  gemini_request(sprintf("%s/download/v1beta/%s:download", API, file_esito)) |>
    req_url_query(alt = "media") |>
    req_perform(path = file_output)

  fatti <- map_chr(leggi_risposte(file_risposte), "caso")
  errori <- 0
  for (riga in read_lines(file_output)) {
    esito <- fromJSON(riga, simplifyVector = FALSE)
    if (esito$key %in% fatti) next
    # A failed line is left out, so the next run picks the case up again.
    if (is.null(esito$response)) {
      errori <- errori + 1
      next
    }
    registra(esito$key, estrai_risposta(esito$response), variabili, file_risposte, "batch")
  }
  if (errori > 0) message(errori, " cases failed in the batch and are still to do.")
  chiudi("ritirato")
  TRUE
}

riepiloga <- function(gruppo, modo, g) {
  dir_gruppo <- file.path(RUN_DIR, gruppo)
  risposte <- leggi_risposte(file.path(dir_gruppo, paste0(modo, "_risposte.jsonl")))
  vuota <- as_tibble(set_names(rep(list(character()), length(g$variabili)), g$variabili))
  codifica <- map_dfr(risposte, \(r) tibble(caso = r$caso, stato = r$stato, !!!r$valori)) |>
    bind_rows(vuota) |>
    select(caso, stato, all_of(g$variabili))
  write_csv(codifica, file.path(dir_gruppo, paste0(modo, "_codifica.csv")))

  print(count(codifica, stato))
  message("Tokens used: ", sum(map_dbl(risposte, \(r) r$token %||% 0)))
  fuori <- codifica |>
    pivot_longer(-c(caso, stato), names_to = "variabile", values_to = "valore") |>
    filter(!is.na(valore)) |>
    anti_join(g$valori, by = c("variabile", "valore"))
  if (nrow(fuori) > 0) {
    message("Values outside the codebook:")
    print(count(fuori, variabile, valore, sort = TRUE))
  }

  if (modo == "controllo") {
    confronto <- map_dfr(g$variabili, \(v) {
      uniti <- inner_join(
        select(codifica, caso, api = all_of(v)),
        select(g$riconciliato_b, caso, umano = all_of(v)),
        by = "caso"
      )
      bind_cols(variabile = v, cohen_kappa(uniti$umano, uniti$api))
    }) |>
      left_join(g$kappa_foglio, by = "variabile") |>
      rename(kappa_api = kappa)
    write_csv(confronto, file.path(dir_gruppo, "controllo_kappa.csv"))
    print(confronto, n = Inf)
  }

  if (modo == "corpus") {
    validate <- g$kappa_foglio |>
      filter(!is.na(kappa_foglio), kappa_foglio >= SOGLIA_KAPPA) |>
      pull(variabile)
    message("Validated variables (kappa on sample B >= ", SOGLIA_KAPPA, "): ",
            if (length(validate)) paste(validate, collapse = ", ") else "none")
    write_csv(select(codifica, caso, stato, any_of(validate)),
              file.path(dir_gruppo, "corpus_validata.csv"))
  }
  invisible(codifica)
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 2) stop("Usage: gemini-corpus-run.R <gruppo> <", paste(MODI, collapse = "|"), "> [max casi]")
  esegui(args[1], args[2], if (length(args) >= 3) as.numeric(args[3]) else Inf)
}
