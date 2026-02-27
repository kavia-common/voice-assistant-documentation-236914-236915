#!/usr/bin/env bash
set -euo pipefail
# dependencies - install mkdocs and optional material into venv
WORKSPACE=${WORKSPACE:-"/tmp/kavia/workspace/code-generation/voice-assistant-documentation-236914-236915/Documentation"}
cd "$WORKSPACE"
PYVENV="$WORKSPACE/.venv"
MKDOCS_VERSION=${MKDOCS_VERSION:-""}
ENABLE_MATERIAL=${ENABLE_MATERIAL:-"0"}
# prefer venv python/pip when available
if [ -x "$PYVENV/bin/python" ]; then
  VENV_PY="$PYVENV/bin/python"
  VENV_PIP="$PYVENV/bin/pip"
else
  VENV_PY=""
  VENV_PIP=""
fi
# if venv present, ensure mkdocs is installed there
if [ -n "$VENV_PIP" ]; then
  if ! "$VENV_PY" -c "import mkdocs" >/dev/null 2>&1; then
    if [ -n "$MKDOCS_VERSION" ]; then
      "$VENV_PIP" install --quiet "mkdocs==$MKDOCS_VERSION" || { echo "failed to install mkdocs==$MKDOCS_VERSION into venv" >&2; exit 6; }
    else
      "$VENV_PIP" install --quiet mkdocs || { echo "failed to install mkdocs into venv" >&2; exit 6; }
    fi
  fi
  # optionally install mkdocs-material when explicitly requested
  if [ "$ENABLE_MATERIAL" = "1" ]; then
    if ! "$VENV_PY" -c "import mkdocs_material" >/dev/null 2>&1; then
      "$VENV_PIP" install --quiet mkdocs-material || echo "warning: mkdocs-material not installed into venv; material config will be skipped"
    fi
  fi
  # enable material config only when explicitly requested and mkdocs-material is importable
  if [ "$ENABLE_MATERIAL" = "1" ] && "$VENV_PY" -c "import mkdocs_material" >/dev/null 2>&1; then
    # only overwrite mkdocs.yml if scaffold created it (marker) or ENABLE_MATERIAL_FORCE=1
    if [ -f .mkdocs_scaffold_marker ] || [ "${ENABLE_MATERIAL_FORCE:-0}" = "1" ]; then
      if [ -f mkdocs.material.yml ]; then
        cp -f mkdocs.material.yml mkdocs.yml
      else
        echo "warning: mkdocs.material.yml not found; skipping copy" >&2
      fi
    fi
  fi
else
  # no venv: rely on global mkdocs shipped in image
  if ! python3 -c "import mkdocs" >/dev/null 2>&1; then
    echo "mkdocs not found globally and no venv available" >&2
    exit 7
  fi
fi
# create minimal package.json for optional markdownlint usage if npm present
if command -v npm >/dev/null 2>&1; then
  [ -f package.json ] || printf '{"name":"docs","devDependencies":{}}' > package.json
fi
# print explicit versions
if [ -n "$VENV_PY" ]; then
  "$VENV_PY" -c "import mkdocs; print('venv-mkdocs', mkdocs.__version__)" || true
else
  python3 -c "import mkdocs; print('global-mkdocs', mkdocs.__version__)" || true
fi
