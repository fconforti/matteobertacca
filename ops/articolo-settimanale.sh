#!/usr/bin/env bash
# Articolo della settimana: lancia Claude in modalità headless con ops/articolo-settimanale.md,
# controlla che abbia toccato solo i file previsti, rifà la build, poi commit e push (il push avvia il deploy).
# Lo lancia il timer systemd matteobertacca-articolo.timer (vedi ops/systemd/); a mano: ops/articolo-settimanale.sh [--prova]
set -euo pipefail
PROVA=0; [[ "${1:-}" == "--prova" ]] && PROVA=1   # --prova: tutto tranne commit e push

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
export TZ=Europe/Rome
export COVER_DIR="$ROOT/ops/logs/unsplash"
STAMP="$(date +%F)"
LOG_DIR="$ROOT/ops/logs"; mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/articolo-$STAMP.log"
log() { printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$LOG" >&2; }

# Segreti (GH_TOKEN, UNSPLASH_ACCESS_KEY): sotto systemd arrivano da EnvironmentFile, a mano da direnv.
[[ -n "${UNSPLASH_ACCESS_KEY:-}" ]] || { log "UNSPLASH_ACCESS_KEY mancante"; exit 1; }

if [[ -n "$(git status --porcelain)" ]]; then
  log "la copia di lavoro non è pulita: non parto"; git status --short >>"$LOG"; exit 1
fi
git pull --rebase --quiet

PROMPT="Oggi è $(date +%F) ($(LC_TIME=it_IT.UTF-8 date +%A 2>/dev/null || date +%A)). Repository: $ROOT."$'\n\n'"$(cat ops/articolo-settimanale.md)"
ALLOWED='Read,Glob,Grep,Write(src/content/articoli/**),Edit(src/content/articoli/**),Write(ops/argomenti.md),Edit(ops/argomenti.md),Edit(scripts/covers.json),Bash(node scripts/unsplash.mjs:*),Bash(npm run build),Bash(ls:*)'

log "avvio claude"
set +e
# acceptEdits: le scritture dentro il repo passano senza prompt (il 2026-11-13 una regola Write(...) è stata
# negata senza motivo chiaro). Il controllo dopo il run scarta comunque ogni file fuori da quelli previsti.
claude -p "$PROMPT" \
  --permission-mode acceptEdits \
  --allowedTools "$ALLOWED" \
  --disallowedTools 'Bash(git:*),WebFetch,WebSearch' \
  --max-turns 60 \
  --output-format json \
  > "$LOG_DIR/articolo-$STAMP.json" 2>>"$LOG"
rc=$?
set -e
REPORT="$(node -e 'try{console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).result??"")}catch{}' "$LOG_DIR/articolo-$STAMP.json")"
printf '%s\n' "$REPORT" >>"$LOG"
log "claude è uscito con $rc"

abort() { log "$1: annullo le modifiche"; git status --short >>"$LOG"; git reset -q --hard; git clean -fdq -- src scripts ops/argomenti.md; exit 1; }

[[ $rc -eq 0 ]] || abort "claude non è andato a buon fine"
grep -q '^ERRORE:' <<<"$REPORT" && abort "claude ha segnalato un errore"
SLUG="$(sed -n 's/^SLUG: *//p' <<<"$REPORT" | head -1)"
[[ -n "$SLUG" && -f "src/content/articoli/$SLUG.md" && -f "src/content/articoli/covers/$SLUG.jpg" ]] || abort "articolo o copertina mancanti"

# Solo i file previsti.
while read -r path; do
  case "$path" in
    "src/content/articoli/$SLUG.md"|"src/content/articoli/covers/$SLUG.jpg"|scripts/covers.json|ops/argomenti.md) ;;
    *) abort "file non previsto modificato: $path" ;;
  esac
done < <(git status --porcelain --untracked-files=all | cut -c4-)
grep -q "^cover:" "src/content/articoli/$SLUG.md" || abort "manca la copertina nel frontmatter"

npm run build >>"$LOG" 2>&1 || abort "build fallita"

if [[ $PROVA -eq 1 ]]; then log "prova: $SLUG pronto, niente commit"; exit 0; fi

TITLE="$(sed -n 's/^TITOLO: *//p' <<<"$REPORT" | head -1)"
git add "src/content/articoli/$SLUG.md" "src/content/articoli/covers/$SLUG.jpg" scripts/covers.json ops/argomenti.md
git -c core.hooksPath=/dev/null commit -q -m "Nuovo articolo: ${TITLE:-$SLUG}" -m "$REPORT" \
  -m "Co-Authored-By: Claude <noreply@anthropic.com>"
git push -q
log "pubblicato $SLUG"
