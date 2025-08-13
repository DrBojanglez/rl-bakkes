#!/usr/bin/env bash
set -euo pipefail
REV="${1:-}"
[ -n "$REV" ] || { echo "Usage: devtools/tag_rev.sh revX"; exit 64; }
git tag -a "$REV" -m "$REV"
git push origin "$REV"
echo "Tagged and pushed $REV"
