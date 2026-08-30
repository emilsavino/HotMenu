#!/bin/bash
set -euo pipefail

VERSION="${1:-}"
BUILD_NUMBER="${2:-}"
DOWNLOAD_URL="${3:-}"
SIGNATURE="${4:-}"
FILE_SIZE="${5:-}"
APPCAST_PATH="${6:-appcast.xml}"

if [ -z "$VERSION" ] || [ -z "$BUILD_NUMBER" ] || [ -z "$DOWNLOAD_URL" ] || [ -z "$SIGNATURE" ] || [ -z "$FILE_SIZE" ]; then
    echo "Usage: $0 <short-version> <build-number> <download-url> <ed-signature> <file-size> [appcast-path]" >&2
    exit 1
fi

if [[ ! "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "Error: build number must be numeric: $BUILD_NUMBER" >&2
    exit 1
fi

if [[ ! "$FILE_SIZE" =~ ^[0-9]+$ ]]; then
    echo "Error: file size must be numeric: $FILE_SIZE" >&2
    exit 1
fi

if [ ! -f "$APPCAST_PATH" ]; then
    echo "Error: appcast not found: $APPCAST_PATH" >&2
    exit 1
fi

xml_escape() {
    printf '%s' "$1" | sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e "s/'/\&apos;/g"
}

VERSION_XML="$(xml_escape "$VERSION")"
DOWNLOAD_URL_XML="$(xml_escape "$DOWNLOAD_URL")"
RELEASE_URL_XML="$(xml_escape "https://github.com/emilsavino/HotMenu/releases/tag/v${VERSION}")"
PUB_DATE="$(date -u '+%a, %d %b %Y %H:%M:%S %z')"

ITEM="        <item>
            <title>HotMenu ${VERSION_XML}</title>
            <link>${RELEASE_URL_XML}</link>
            <sparkle:version>${BUILD_NUMBER}</sparkle:version>
            <sparkle:shortVersionString>${VERSION_XML}</sparkle:shortVersionString>
            <pubDate>${PUB_DATE}</pubDate>
            <enclosure
                url=\"${DOWNLOAD_URL_XML}\"
                sparkle:edSignature=\"${SIGNATURE}\"
                length=\"${FILE_SIZE}\"
                type=\"application/octet-stream\" />
        </item>"

ITEM_PATH="$(mktemp "${TMPDIR:-/tmp}/hotmenu-appcast-item.XXXXXX")"
TEMP_PATH="$(mktemp "${TMPDIR:-/tmp}/hotmenu-appcast.XXXXXX")"
trap 'rm -f "$ITEM_PATH" "$TEMP_PATH"' EXIT
printf '%s\n' "$ITEM" > "$ITEM_PATH"

awk -v item_path="$ITEM_PATH" -v version="$BUILD_NUMBER" '
    function append_item(  line) {
        while ((getline line < item_path) > 0) {
            print line
        }
        close(item_path)
        inserted = 1
    }
    function flush_item(  line_number) {
        for (line_number = 1; line_number <= item_line_count; line_number++) {
            print item_lines[line_number]
        }
    }
    function finish_existing_item() {
        if (!skip_item) {
            flush_item()
        }
        in_item = 0
        skip_item = 0
        item_line_count = 0
        delete item_lines
    }
    {
        if (in_item) {
            item_lines[++item_line_count] = $0
            if (index($0, ">" version "</sparkle:version>")) {
                skip_item = 1
            }
            if ($0 ~ /<\/item>/) {
                finish_existing_item()
            }
            next
        }

        if ($0 ~ /<item([[:space:]>]|$)/) {
            in_item = 1
            item_line_count = 1
            item_lines[1] = $0
            skip_item = index($0, ">" version "</sparkle:version>")
            if ($0 ~ /<\/item>/) {
                finish_existing_item()
            }
            next
        }

        if ($0 ~ /<\/channel>/ && !inserted) {
            append_item()
        }
        print
    }
    END {
        if (!inserted) {
            print "Error: appcast does not contain a closing channel element" > "/dev/stderr"
            exit 3
        }
    }
' "$APPCAST_PATH" > "$TEMP_PATH"

mv "$TEMP_PATH" "$APPCAST_PATH"
trap - EXIT

echo "Added or replaced HotMenu ${VERSION} (build ${BUILD_NUMBER}) in ${APPCAST_PATH}"
