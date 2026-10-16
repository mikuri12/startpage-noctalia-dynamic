#!/usr/bin/env bash
# Sincroniza el CSS de Noctalia generado por el template:
#   1. public/noctalia.css -> commit + push -> GitHub Pages se redeploya
# Solo commitea si el contenido cambió; nunca commitea otra cosa del repo.
set -uo pipefail

REPO="$HOME/Projects/startpage-noctalia-dynamic"
SRC="$HOME/.cache/noctalia/startpage-druxorey.css"
LOG="$HOME/.cache/noctalia/startpage-druxorey-push.log"

log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

if [ ! -f "$SRC" ]; then
  log "aviso: no existe $SRC (¿daemon de Noctalia corriendo?)"
  exit 0
fi

# 1. Copias locales (dist si existe, public para el build de Vite)
mkdir -p "$REPO/public"
cp "$SRC" "$REPO/public/noctalia.css"
if [ -d "$REPO/dist" ]; then
  cp "$SRC" "$REPO/dist/noctalia.css"
fi

# 2. Commit + push solo si el archivo cambió
cd "$REPO" || exit 0
git add -- public/noctalia.css
if git diff --cached --quiet -- public/noctalia.css; then
  exit 0 # sin cambios: nada que subir
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
if git commit -q -m "chore(noctalia): actualizar paleta generada [auto]" -- public/noctalia.css; then
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
