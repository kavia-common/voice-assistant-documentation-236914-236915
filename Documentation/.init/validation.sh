#!/usr/bin/env bash
set -euo pipefail
# validation - build, start server, smoke test, and cleanly stop
WORKSPACE=${WORKSPACE:-"/tmp/kavia/workspace/code-generation/voice-assistant-documentation-236914-236915/Documentation"}
cd "$WORKSPACE"
PYVENV="$WORKSPACE/.venv"
if [ -x "$PYVENV/bin/mkdocs" ]; then MKDOCS_BIN="$PYVENV/bin/mkdocs"; else MKDOCS_BIN="mkdocs"; fi
SITE_DIR="$WORKSPACE/site"
LOG=/tmp/mkdocs-serve.log
ADDR=127.0.0.1:8000

# build (CI-safe)
"$MKDOCS_BIN" build --clean --site-dir "$SITE_DIR" --quiet
[ -d "$SITE_DIR" ] || { echo "mkdocs build failed" >&2; exit 10; }

# start server in its own process group: prefer setsid, fallback to nohup
rm -f "$LOG" || true
if command -v setsid >/dev/null 2>&1; then
  setsid "$MKDOCS_BIN" serve --dev-addr=$ADDR >"$LOG" 2>&1 & PID=$!
else
  nohup "$MKDOCS_BIN" serve --dev-addr=$ADDR >"$LOG" 2>&1 & PID=$!
fi
sleep 0.5

# verify process exists
if ! ps -p "$PID" >/dev/null 2>&1; then echo "server process not running" >&2; kill -- -$PID >/dev/null 2>&1 || true; exit 11; fi

# confirm the listening port is owned by a process and that cmdline references mkdocs or python
owner_ok=0
if command -v ss >/dev/null 2>&1; then
  ss -ltnp 2>/dev/null | grep -E ":8000\\s" >/dev/null 2>&1 && owner_ok=1 || true
else
  netstat -ltnp 2>/dev/null | grep -E ":8000\\s" >/dev/null 2>&1 && owner_ok=1 || true
fi
cmdline=$(ps -p "$PID" -o args= 2>/dev/null || true)
if [[ "$cmdline" =~ mkdocs ]] || [[ "$owner_ok" -eq 1 ]]; then :; else echo "server running but owner/cmdline not matching mkdocs" >&2; fi

# wait for HTTP up to ~15s with backoff
timeout=15
elapsed=0
interval=0.5
while (( $(awk 'BEGIN{print ('"$elapsed"' < '"$timeout"')}') )); do
  code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/ || true)
  if [ "$code" = "200" ] || [ "$code" = "301" ] || [ "$code" = "302" ]; then echo "server-ok"; break; fi
  sleep "$interval"
  elapsed=$(awk "BEGIN{printf %.2f, $elapsed + $interval}")
  interval=$(awk "BEGIN{printf %.2f, $interval * 1.5}")
done
if (( $(awk 'BEGIN{print ('"$elapsed"' >= '"$timeout"')}') )); then echo "server did not respond after ${timeout}s" >&2; kill -- -$PID >/dev/null 2>&1 || true; exit 12; fi

# cleanup: kill whole process group
kill -- -$PID >/dev/null 2>&1 || true
sleep 1

# Evidence
ls -la "$SITE_DIR" | head -n 20 || true
head -n 200 "$LOG" || true
