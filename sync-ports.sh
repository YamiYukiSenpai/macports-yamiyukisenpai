#!/bin/bash
# sync-ports.sh — copy a git-managed MacPorts port tree to a root-owned
# system location, stripping git files, then rebuild the PortIndex.
#
# Usage: sync-ports.sh [-n]      (-n = dry run, show what would change)
# Run as your normal user; it calls sudo only where needed.
# Override paths with PORTS_SRC / PORTS_DEST env vars if you ever need to.

set -euo pipefail

SRC="${PORTS_SRC:-$HOME/Projects/ports}"
DEST="${PORTS_DEST:-/opt/ports}"
PORTINDEX="/opt/local/bin/portindex"

DRY_RUN=""
[[ "${1:-}" == "-n" ]] && DRY_RUN="-n"

# --- sanity checks -------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not with sudo." >&2
    exit 1
fi
if [[ ! -d "$SRC" ]]; then
    echo "Source not found: $SRC" >&2
    exit 1
fi
# --delete would empty DEST if SRC were wrong, so require a real ports tree
if ! find "$SRC" -mindepth 3 -maxdepth 3 -name Portfile -print -quit | grep -q .; then
    echo "No category/port/Portfile found under $SRC — refusing to sync." >&2
    exit 1
fi
case "$DEST" in
    ""|"/"|"/opt"|"/opt/local"|"$HOME") echo "Unsafe destination: $DEST" >&2; exit 1 ;;
esac
if [[ ! -x "$PORTINDEX" ]]; then
    echo "portindex not found at $PORTINDEX" >&2
    exit 1
fi

# --- sync ----------------------------------------------------------------
sudo mkdir -p "$DEST"

# '.git*' covers .git/, .gitignore, .gitattributes, .gitmodules, .github/.
# Excluded files are also protected from --delete on the destination,
# so the PortIndex generated in DEST survives the sync.
sudo rsync -a -v --delete $DRY_RUN \
    --exclude='.git*' \
    --exclude='PortIndex' \
    --exclude='PortIndex.quick' \
    --exclude='.DS_Store' \
    --exclude='work/' \
    "$SRC/" "$DEST/"

if [[ -n "$DRY_RUN" ]]; then
    echo "Dry run complete — nothing changed."
    exit 0
fi

# --- ownership & permissions --------------------------------------------
# root-owned, world-readable so the unprivileged 'macports' build user can read it
sudo chown -R root:wheel "$DEST"
sudo chmod -R u=rwX,go=rX "$DEST"

# --- reindex -------------------------------------------------------------
cd "$DEST"
sudo "$PORTINDEX"

echo "Synced $SRC -> $DEST and rebuilt PortIndex."
