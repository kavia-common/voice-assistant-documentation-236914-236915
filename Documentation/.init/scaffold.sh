#!/usr/bin/env bash
set -euo pipefail
# Scaffolding for mkdocs in the authoritative workspace
WORKSPACE=${WORKSPACE:-"/tmp/kavia/workspace/code-generation/voice-assistant-documentation-236914-236915/Documentation"}
cd "$WORKSPACE"
mkdir -p docs assets/images
# example pages (create only if missing)
[ -f docs/index.md ] || cat > docs/index.md <<'MD'
# Project Documentation

Welcome to the documentation site.

* [Getting Started](getting-started.md)
* [Architecture](architecture.md)
MD
[ -f docs/getting-started.md ] || cat > docs/getting-started.md <<'MD'
# Getting Started

Steps to run docs locally:

```bash
# from project root
./start.sh
```
MD
[ -f docs/architecture.md ] || cat > docs/architecture.md <<'MD'
# Architecture

Static MkDocs site; mkdocs-material theme is optional and applied only when enabled.
MD
# write default mkdocs.yml only if missing (do not clobber user edits)
if [ ! -f mkdocs.yml ]; then
  cat > mkdocs.yml <<'YML'
site_name: Voice Assistant Documentation
nav:
  - Home: index.md
  - Getting Started: getting-started.md
  - Architecture: architecture.md
YML
  echo "# scaffold-created" > .mkdocs_scaffold_marker
fi
# material variant (kept separate, opt-in)
cat > mkdocs.material.yml <<'YML'
site_name: Voice Assistant Documentation
nav:
  - Home: index.md
  - Getting Started: getting-started.md
  - Architecture: architecture.md
theme:
  name: material
YML
# start helper
cat > start.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WORKSPACE=${WORKSPACE:-"/tmp/kavia/workspace/code-generation/voice-assistant-documentation-236914-236915/Documentation"}
cd "$WORKSPACE"
PYVENV="$WORKSPACE/.venv"
MKDOCS_BIN="$PYVENV/bin/mkdocs"
ADDR=${DEV_ADDR:-0.0.0.0:8000}
if [ -x "$MKDOCS_BIN" ]; then
  exec "$MKDOCS_BIN" serve --dev-addr=$ADDR
else
  exec mkdocs serve --dev-addr=$ADDR
fi
SH
chmod +x start.sh
# build helper
cat > build.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WORKSPACE=${WORKSPACE:-"/tmp/kavia/workspace/code-generation/voice-assistant-documentation-236914-236915/Documentation"}
cd "$WORKSPACE"
PYVENV="$WORKSPACE/.venv"
MKDOCS_BIN="$PYVENV/bin/mkdocs"
if [ -x "$MKDOCS_BIN" ]; then
  "$MKDOCS_BIN" build --clean --site-dir "$WORKSPACE/site"
else
  mkdocs build --clean --site-dir "$WORKSPACE/site"
fi
SH
chmod +x build.sh
