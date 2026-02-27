#!/usr/bin/env bash
set -euo pipefail
WORKSPACE=${WORKSPACE:-"/tmp/kavia/workspace/code-generation/voice-assistant-documentation-236914-236915/Documentation"}
cd "$WORKSPACE"
# optional markdownlint via npx (non-fatal)
if command -v npm >/dev/null 2>&1; then
  npx -y markdownlint-cli@0.32.0 docs || true
fi
imgs=()
# prefer PCRE grep if available, fallback to safe shell parsing
if grep -P "" -V >/dev/null 2>&1; then
  mapfile -t inline < <(grep -rhoP "!\[[^\]]*\]\(\K[^)]+" docs || true)
  mapfile -t ref < <(grep -rhoP "^\s*\[[^]]+\]:\s*\K\S+" docs || true)
  imgs=("${inline[@]}" "${ref[@]}")
else
  mapfile -t lines < <(grep -rhoE "!\[[^\]]*\]\([^)]+\)|^\s*\[[^]]+\]:\s*\S+" docs || true)
  for l in "${lines[@]:-}"; do
    if [[ "$l" =~ \!\[[^\]]*\]\(([^)]+)\) ]]; then
      imgs+=("${BASH_REMATCH[1]}")
    elif [[ "$l" =~ ^[[:space:]]*\[[^]]+\]:[[:space:]]*(\S+) ]]; then
      imgs+=("${BASH_REMATCH[1]}")
    fi
  done
fi
missing=0
for img in "${imgs[@]:-}"; do
  [ -z "$img" ] && continue
  case "$img" in
    http* ) continue ;;
    /* ) resolved=$(realpath -m "$img") ;;
    * ) resolved=$(realpath -m "$WORKSPACE/$img") ;;
  esac
  if [ ! -e "$resolved" ]; then
    echo "missing image: $img -> $resolved" >&2
    missing=1
    continue
  fi
  # if the original reference was relative, ensure it resolves inside WORKSPACE
  if [[ "$resolved" != "$WORKSPACE"* ]]; then
    if [[ "$img" != /* ]]; then
      echo "image outside workspace: $img -> $resolved" >&2
      missing=1
    fi
  fi
done
if [ "$missing" -ne 0 ]; then
  echo "Image checks failed" >&2
  exit 8
fi
# success marker
mkdir -p docs
echo "ok" > docs/.test-ok
