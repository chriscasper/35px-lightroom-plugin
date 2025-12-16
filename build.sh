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
zip -r "$OUTPUT_DIR/$OUTPUT_FILE" \
    "$PLUGIN_FOLDER" \
    "LICENSE" \
    "README.md" \
    "CHANGELOG.md" \
    "API.md" \
    "CONTRIBUTING.md" \
    -x "*.DS_Store" \
    -x "*__MACOSX*" \
    -x "*.git*" \
    -x "*.log" \
    -x "*.tmp" \
    -x "dist/*"

echo ""
echo "✅ Build complete!"
echo "   Output: $OUTPUT_DIR/$OUTPUT_FILE"
echo "   Version: v${VERSION}"
echo ""
echo "Package contents:"
echo "  - ${PLUGIN_FOLDER}/ (plugin)"
echo "  - README.md (user guide)"
echo "  - CHANGELOG.md (version history)"
echo "  - API.md (API reference)"
echo "  - CONTRIBUTING.md (for contributors)"
echo "  - LICENSE (MIT)"
echo ""
echo "To release:"
echo "1. Test the plugin in Lightroom"
echo "2. Create a GitHub release (tag: v${VERSION})"
echo "3. Upload $OUTPUT_DIR/$OUTPUT_FILE"
echo "4. Update download links in documentation"
echo ""

