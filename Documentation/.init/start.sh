#!/usr/bin/env bash
set -euo pipefail
# Start mkdocs dev server (foreground helper)
WORKSPACE=${WORKSPACE:-"/tmp/kavia/workspace/code-generation/voice-assistant-documentation-236914-236915/Documentation"}
cd "$WORKSPACE"
PYVENV="$WORKSPACE/.venv"
MKDOCS_BIN="$PYVENV/bin/mkdocs"
ADDR=${DEV_ADDR:-0.0.0.0:8000}
# Prefer venv binary when present, otherwise rely on global mkdocs
if [ -x "$MKDOCS_BIN" ]; then
  exec "$MKDOCS_BIN" serve --dev-addr="$ADDR"
else
  exec mkdocs serve --dev-addr="$ADDR"
fi
