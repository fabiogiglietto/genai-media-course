#!/bin/bash
# ============================================
# Setup script per genai-media-course
# Eseguire nella directory radice del progetto
# ============================================

echo "📁 Creazione struttura directory..."

mkdir -p _extensions/uniurb
mkdir -p R
mkdir -p assets
mkdir -p slides
mkdir -p readings
mkdir -p img
mkdir -p _output

echo "📋 Struttura creata:"
echo ""
echo "genai-media-course/"
echo "├── CLAUDE.md"
echo "├── course-plan.md"
echo "├── _quarto.yml"
echo "├── _extensions/uniurb/"
echo "│   ├── _extension.yml"
echo "│   └── discui.scss"
echo "├── R/"
echo "│   └── uniurb_theme.R"
echo "├── assets/"
echo "│   ├── logo-uniurb-white.svg   ← DA AGGIUNGERE"
echo "│   └── logo-nh-uniurb.svg      ← DA AGGIUNGERE"
echo "├── slides/                      ← File .qmd generati qui"
echo "├── readings/                    ← PDF articoli qui"
echo "├── img/                         ← Immagini per le slide"
echo "└── _output/                     ← HTML renderizzato"
echo ""

# Verifiche
echo "🔍 Verifiche..."

if command -v quarto &> /dev/null; then
    echo "✅ Quarto installato: $(quarto --version)"
else
    echo "❌ Quarto non trovato. Installare da https://quarto.org"
fi

if command -v R &> /dev/null; then
    echo "✅ R installato: $(R --version | head -1)"
else
    echo "❌ R non trovato."
fi

if [ -f "_extensions/uniurb/discui.scss" ]; then
    echo "✅ Tema DISCUI presente"
else
    echo "❌ discui.scss mancante in _extensions/uniurb/"
fi

if [ -f "assets/logo-uniurb-white.svg" ]; then
    echo "✅ Logo bianco presente"
else
    echo "⚠️  Logo bianco mancante in assets/ — serve per le slide scure"
    echo "   Puoi creare una versione bianca del logo con:"
    echo "   sed 's/fill=\"[^\"]*\"/fill=\"white\"/g' logo-nh-uniurb.svg > assets/logo-uniurb-white.svg"
fi

echo ""
echo "✨ Setup completato. Ora puoi generare le slide con Claude Code."
echo "   Leggi CLAUDE.md per le istruzioni."
