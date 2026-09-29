# Claude Code Plan: Attendance Code Footer System

## Context

The course uses Università di Urbino's "Modulo Rileva Frequenze" (Cineca) for attendance tracking. A teaching assistant (TA) starts each attendance session via delegation, which generates a 5-character alphanumeric code. Students enter this code in the UniUrb Stud app to register their presence.

We want this code to appear automatically on all projected slides. The TA writes the code into a shared Google Sheet; JavaScript on the slides polls the sheet and displays it as a persistent footer.

## Google Sheet Configuration

- **Sheet ID:** `16esB9eA2yhu4AVwvLbjZJq-DClcWVg23aUtwEyax0fA`
- **Fetch URL (cell A1 as CSV):** `https://docs.google.com/spreadsheets/d/16esB9eA2yhu4AVwvLbjZJq-DClcWVg23aUtwEyax0fA/gviz/tq?tqx=out:csv&range=A1`
- **Sharing:** "Anyone with the link" = Viewer; TA invited as Editor
- **Usage:** TA types the 5-character code into cell A1. Clears it when attendance closes.

## Tasks

### 1. Create `_attendance-footer.html` in the project root

This file is included after the body of every reveal.js presentation.

**Behavior:**
- On page load, start polling the Google Sheet URL every 15 seconds
- Append a cache-busting query parameter (`&_=<timestamp>`) to defeat Google's CDN cache
- Google's CSV response wraps values in double quotes (e.g. `"QHFTV"`). Strip quotes and whitespace before using the value.
- If the cleaned response is a non-empty string, display a fixed-position footer on all slides showing: `Codice presenza: XXXXX`
- If the response is empty, whitespace-only, or just `""`, hide the footer
- If the fetch fails (offline, CORS, etc.), silently ignore — do not show errors, keep footer in last known state
- Stop polling when the browser tab is not visible (use `visibilitychange` event); resume when visible again

**Styling:**
- Position: fixed, bottom-right corner, above the reveal.js footer/progress bar
- Font: monospace, bold, ~0.7em
- Colors: DISCUI orange (`#C5612E`) text on semi-transparent white background (`rgba(255,255,255,0.9)`)
- Subtle border-radius (4px), small padding (4px 12px)
- z-index high enough to sit above slide content (z-index: 100)
- Print media query: hide the footer when printing slides

**Code structure:**
```html
<style>
  .attendance-code {
    position: fixed;
    bottom: 8px;
    right: 16px;
    font-size: 0.7em;
    font-weight: bold;
    color: #C5612E;
    background: rgba(255, 255, 255, 0.9);
    padding: 4px 12px;
    border-radius: 4px;
    z-index: 100;
    font-family: monospace;
    display: none; /* hidden by default */
  }
  @media print {
    .attendance-code { display: none !important; }
  }
</style>
<script>
  (function() {
    const SHEET_URL = 'https://docs.google.com/spreadsheets/d/16esB9eA2yhu4AVwvLbjZJq-DClcWVg23aUtwEyax0fA/gviz/tq?tqx=out:csv&range=A1';
    const POLL_INTERVAL = 15000;

    // Create footer element, append to .reveal
    // Poll loop:
    //   fetch(SHEET_URL + '&_=' + Date.now())
    //   parse CSV response: strip quotes, trim
    //   if non-empty -> show footer with code
    //   if empty -> hide footer
    //   on error -> silently ignore
    // visibilitychange -> pause/resume polling
  })();
</script>
```

### 2. Update `_quarto.yml`

Add the include to the existing revealjs format configuration:

```yaml
format:
  revealjs:
    # ... existing options ...
    include-after-body: _attendance-footer.html
```

**Important:** Do NOT overwrite existing `_quarto.yml` settings. Only add the `include-after-body` key. If `include-after-body` already exists, convert it to an array.

### 3. Create `slides/_attendance.qmd` (include partial)

A reusable partial that any session can include with `{{< include _attendance.qmd >}}` to show students how to register attendance. Contains 2 slides:

**Slide 1:** Section divider with `{background-color="#C5612E"}`

```markdown
## Rilevazione presenze {background-color="#C5612E"}
```

**Slide 2:** Step-by-step student instructions

```markdown
## Come registrare la presenza

1. Aprire l'app **UniUrb Stud** (o [uniurb-pwa.app.cineca.it](https://uniurb-pwa.app.cineca.it))
2. Cliccare su **Rilevazione Frequenze** → **Marcatura**
3. Autorizzare la geolocalizzazione (la prima volta)
4. Inserire il **codice** visualizzato in basso a destra su queste slide
5. Verificare nello **Storico presenze**

::: {.callout-warning}
Si ricorda che una falsa attestazione di presenza potrà essere soggetta a provvedimenti.
:::

::: {.notes}
Il codice di rilevamento viene inserito dall'assistente nel foglio Google condiviso
e appare automaticamente in basso a destra su tutte le slide.
La rilevazione termina in automatico alla fine del periodo della lezione,
oppure può essere chiusa manualmente dall'assistente.
:::
```

**Language:** Italian (consistent with CLAUDE.md rules).

### 4. Test the system

After creating the files:

1. Run `quarto render slides/week1-mon-introduction.qmd` (or any existing slide deck) to verify:
   - The HTML output includes the attendance footer script
   - No rendering errors
2. Verify `_attendance-footer.html` is valid HTML (no syntax errors in JS or CSS)
3. Test the polling manually:
   - Open the rendered HTML in a browser
   - Type a test code (e.g. `TEST1`) into cell A1 of the Google Sheet
   - Within ~15 seconds the footer should appear on the slides
   - Clear cell A1 — footer should disappear

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| CREATE | `_attendance-footer.html` | JS polling Google Sheet + CSS footer |
| MODIFY | `_quarto.yml` | Add `include-after-body` |
| CREATE | `slides/_attendance.qmd` | Student instructions partial (2 slides) |

## Edge Cases to Handle

- **Empty cell A1:** footer hidden (default state)
- **CSV quoting:** Google wraps non-empty values in `"..."` — strip them
- **Cell has whitespace/newlines:** trim before checking
- **Network failure:** no error shown, footer stays in last known state (or hidden if never fetched)
- **TA forgets to clear code:** code stays visible — acceptable, low risk
- **Google cache:** cache-busting `&_=timestamp` param ensures fresh data on each poll
- **Multiple tabs open:** each polls independently — fine
- **Slide export to PDF:** footer hidden via print media query
- **CORS:** Google Sheets CSV export supports cross-origin requests — no issues expected
