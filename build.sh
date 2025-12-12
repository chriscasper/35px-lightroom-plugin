#!/bin/bash
#
# 35px Lightroom Plugin Build Script
# Creates a distributable ZIP file for release
#

set -e

# Configuration
PLUGIN_NAME="35px"
PLUGIN_FOLDER="35px.lrplugin"
VERSION=$(grep -o 'major = [0-9]*' "$PLUGIN_FOLDER/Info.lua" | grep -o '[0-9]*').$(grep -o 'minor = [0-9]*' "$PLUGIN_FOLDER/Info.lua" | grep -o '[0-9]*').$(grep -o 'revision = [0-9]*' "$PLUGIN_FOLDER/Info.lua" | grep -o '[0-9]*')

# Output
OUTPUT_DIR="dist"
OUTPUT_FILE="${PLUGIN_NAME}-lightroom-plugin-v${VERSION}.zip"

echo "Building ${PLUGIN_NAME} Lightroom Plugin v${VERSION}..."

# Create dist directory
mkdir -p "$OUTPUT_DIR"

# Remove old build if exists
rm -f "$OUTPUT_DIR/$OUTPUT_FILE"

# Create ZIP (excluding any hidden files, .DS_Store, etc.)
zip -r "$OUTPUT_DIR/$OUTPUT_FILE" "$PLUGIN_FOLDER" "LICENSE" \
    -x "*.DS_Store" \
    -x "*__MACOSX*" \
    -x "*.git*"

echo ""
echo "✅ Build complete!"
echo "   Output: $OUTPUT_DIR/$OUTPUT_FILE"
echo ""
echo "To release:"
echo "1. Create a GitHub release"
echo "2. Upload $OUTPUT_DIR/$OUTPUT_FILE"
echo "3. Update download links in documentation"

