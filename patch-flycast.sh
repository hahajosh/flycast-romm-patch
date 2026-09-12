#!/bin/sh

ASSETS_DIR="/var/www/html/assets"
SCRIPT_DIR="/romm/dev/flycast"

# --------------------------------------------------
# Update _EJS_CORES_MAP in index.ts (actually updates the js output file)
# --------------------------------------------------

# Find the index-*.js file
JS_FILE=$(find "$ASSETS_DIR" -maxdepth 1 -type f -name 'index-*.js' | head -n 1)

if [ -z "$JS_FILE" ]; then
    echo "ERROR: Could not find index-*.js in $ASSETS_DIR"
    exit 1
fi

echo "Found JS file: $JS_FILE"

python3 - "$JS_FILE" <<'PY'
import sys
from pathlib import Path

js_file = Path(sys.argv[1])

target = 'zxs:[`fuse`]'
inject = 'dc:["flycast"],'

content = js_file.read_text()

# Already injected
if inject in content:
    print("Flycast entry already exists. Nothing to do.")
    sys.exit(0)

# Target not found
if target not in content:
    print(f"ERROR: Could not find {target}")
    sys.exit(1)

# Replace only the first occurrence
modified = content.replace(target, inject + target, 1)

# Verify replacement
if modified == content:
    print("ERROR: File was not modified")
    sys.exit(1)

if inject + target not in modified:
    print("ERROR: Injection verification failed")
    sys.exit(1)

# Write the modified file
js_file.write_text(modified)

print(f"Successfully injected Flycast into {js_file}")
PY

# Preserve Python's exit code
if [ $? -ne 0 ]; then
    echo "ERROR: Flycast injection failed"
    exit 1
fi

# -------------------------------------------------- 
# Inject WebGL compatibility patch to EJS loader.js
# --------------------------------------------------

LOADER_JS="$ASSETS_DIR/emulatorjs/data/loader.js"
WEBGL_PATCH="$SCRIPT_DIR/flycast-webgl.js"

if [ ! -f "$LOADER_JS" ]; then
    echo "ERROR: Could not find $LOADER_JS"
    exit 1
fi

if [ ! -f "$WEBGL_PATCH" ]; then
    echo "ERROR: Could not find $WEBGL_PATCH"
    exit 1
fi

echo "Injecting WebGL patch from $WEBGL_PATCH..."

python3 - "$LOADER_JS" "$WEBGL_PATCH" <<'PY'
import sys
from pathlib import Path

loader = Path(sys.argv[1])
patch_file = Path(sys.argv[2])

content = loader.read_text(encoding="utf-8")
patch = patch_file.read_text(encoding="utf-8")

# Prevent duplicate injection
marker = "!FLYCAST PATCH!"

if marker in content:
    print("WebGL patch already exists. Nothing to do.")
    sys.exit(0)

# Prepend patch to loader.js
loader.write_text(
    patch.rstrip() + "\n\n" + content,
    encoding="utf-8"
)

print(f"Successfully injected {patch_file} into {loader}")
PY

if [ $? -ne 0 ]; then
    echo "ERROR: WebGL patch injection failed"
    exit 1
fi

# --------------------------------------------------
# Copy Flycast WASM data
# --------------------------------------------------

WASM_DATA="$SCRIPT_DIR/flycast-wasm.data"
WASM_DEST="$ASSETS_DIR/emulatorjs/data/cores/flycast-wasm.data"

if [ ! -f "$WASM_DATA" ]; then
    echo "ERROR: Could not find $WASM_DATA"
    exit 1
fi

echo "Copying flycast-wasm.data..."

if ! cp "$WASM_DATA" "$WASM_DEST"; then
    echo "ERROR: Failed to copy flycast-wasm.data"
    exit 1
fi

echo "Successfully copied flycast-wasm.data"

WASM_LEGACY_DATA="$SCRIPT_DIR/flycast-legacy-wasm.data"
WASM_LEGACY_DEST="$ASSETS_DIR/emulatorjs/data/cores/flycast-legacy-wasm.data"

if [ -f "$WASM_LEGACY_DATA" ]; then
    echo "Copying flycast-legacy-wasm.data..."

    if ! cp "$WASM_LEGACY_DATA" "$WASM_LEGACY_DEST"; then
        echo "ERROR: Failed to copy flycast-legacy-wasm.data"
        exit 1
    fi

    echo "Successfully copied flycast-legacy-wasm.data"
fi

# --------------------------------------------------
# Copy Flycast report
# --------------------------------------------------

FLYCAST_JSON="$SCRIPT_DIR/flycast.json"
JSON_DEST="$ASSETS_DIR/emulatorjs/data/cores/reports/flycast.json"

if [ ! -f "$FLYCAST_JSON" ]; then
    echo "ERROR: Could not find $FLYCAST_JSON"
    exit 1
fi

echo "Copying flycast.json..."

if ! cp "$FLYCAST_JSON" "$JSON_DEST"; then
    echo "ERROR: Failed to copy flycast.json"
    exit 1
fi

echo "Successfully copied flycast.json"

echo "Flycast setup completed successfully."