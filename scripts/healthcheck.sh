#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:8080}"

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is not installed." >&2
    exit 1
fi

if HTTP_CODE=$(curl -sS -o /dev/null \
    -w '%{http_code}' --max-time 5 "$URL"); then
    if [ "$HTTP_CODE" = "200" ]; then
        echo "Health check passed: $URL returned HTTP 200"
        exit 0
    fi

    echo "ERROR: $URL returned HTTP $HTTP_CODE; expected 200." >&2
    exit 1
else
    echo "ERROR: Could not reach $URL." >&2
    exit 1
fi
