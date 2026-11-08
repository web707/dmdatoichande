#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
if ! command -v cygpath >/dev/null || ! command -v pwsh >/dev/null; then
    printf '%s\n' 'Run ./dev.sh in Git Bash on Windows with PowerShell 7 (pwsh) on PATH.' >&2
    exit 1
fi

exec pwsh -NoLogo -NoProfile -File "$(cygpath -w scripts/dev.ps1)"
