#!/usr/bin/env bash
# Sincroniza el CSS y wallpaper de Noctalia:
#   1. public/noctalia.css y public/wallpaper.webp
#   2. commit + push -> GitHub Pages se redeploya
# Solo commitea si los contenidos cambiaron.
set -uo pipefail

REPO="$HOME/Projects/startpage-noctalia-dynamic"
SRC="$HOME/.cache/noctalia/startpage-druxorey.css"
LOG="$HOME/.cache/noctalia/startpage-druxorey-push.log"

log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

if [ ! -f "$SRC" ]; then
  log "aviso: no existe $SRC (¿daemon de Noctalia corriendo?)"
  exit 0
fi

mkdir -p "$REPO/public"

# 1. Copia de CSS
cp "$SRC" "$REPO/public/noctalia.css"
if [ -d "$REPO/dist" ]; then
  cp "$SRC" "$REPO/dist/noctalia.css"
fi

# 2. Copia y optimización del Wallpaper actual
WALLPAPER="${1:-}"
if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
  WALLPAPER=$(noctalia msg wallpaper-get 2>/dev/null || true)
fi

if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
  if command -v magick >/dev/null 2>&1; then
    magick "$WALLPAPER" -resize 1200x\> -quality 85 "$REPO/public/wallpaper.webp" 2>/dev/null || cp "$WALLPAPER" "$REPO/public/wallpaper.webp"
  elif command -v convert >/dev/null 2>&1; then
    convert "$WALLPAPER" -resize 1200x\> -quality 85 "$REPO/public/wallpaper.webp" 2>/dev/null || cp "$WALLPAPER" "$REPO/public/wallpaper.webp"
  else
    cp "$WALLPAPER" "$REPO/public/wallpaper.webp"
  fi

  if [ -d "$REPO/dist" ]; then
    cp "$REPO/public/wallpaper.webp" "$REPO/dist/wallpaper.webp"
  fi
fi

# 3. Commit + push solo si el CSS o el wallpaper cambiaron
cd "$REPO" || exit 0
git add -- public/noctalia.css public/wallpaper.webp
if git diff --cached --quiet -- public/noctalia.css public/wallpaper.webp; then
  exit 0 # sin cambios: nada que subir
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
if git commit -q -m "chore(noctalia): actualizar paleta y wallpaper [auto]" -- public/noctalia.css public/wallpaper.webp; then
  log "commit creado en rama $BRANCH"
  if [ "$BRANCH" = "main" ]; then
    if GIT_TERMINAL_PROMPT=0 timeout 60 git push -q origin main 2>>"$LOG"; then
      log "push ok"
      gh workflow run deploy.yml --repo mikuri12/startpage-noctalia-dynamic --ref main \
        >/dev/null 2>&1 && log "deploy disparado" || log "aviso: no se pudo disparar el deploy"
    else
      log "push fallo (sin red?); el commit queda local"
    fi
  else
    log "rama $BRANCH != main; no se pushea (haz push manual)"
  fi
fi
