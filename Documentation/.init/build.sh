#!/usr/bin/env bash
set -euo pipefail
# CI-safe mkdocs build producing site/
WORKSPACE=${WORKSPACE:-"/tmp/kavia/workspace/code-generation/voice-assistant-documentation-236914-236915/Documentation"}
cd "$WORKSPACE"
PYVENV="$WORKSPACE/.venv"
SITE_DIR="$WORKSPACE/site"
# Ensure workspace exists
[ -d "$WORKSPACE" ] || { echo "workspace missing: $WORKSPACE" >&2; exit 2; }
# Run venv mkdocs if present, otherwise use system mkdocs (image provides mkdocs)
if [ -x "${PYVENV}/bin/mkdocs" ]; then
  "${PYVENV}/bin/mkdocs" build --clean --site-dir "$SITE_DIR" --quiet
else
  mkdocs build --clean --site-dir "$SITE_DIR" --quiet
fi
# Verify artifact
if [ ! -d "$SITE_DIR" ]; then
  echo "mkdocs build failed: site/ missing" >&2
  exit 9
fi
ls -la "$SITE_DIR" | head -n 20 || true
