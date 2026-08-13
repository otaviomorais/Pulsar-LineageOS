#!/usr/bin/env bash
# Full LineageOS 22.1 + LinDroid build for POCO F3 / alioth (sm8250)
#
# Requirements (x86_64 host):
#   - ~120 GB free disk, 16 GB+ RAM, 8+ cores (recommended)
#   - repo, git, python3, openjdk, build-essential, etc.
#     (see https://wiki.lineageos.org/requirements)
#
# Usage:
#   ./build.sh [ROM_DIR]          # ROM_DIR default: ~/lineage-lindroid
set -euo pipefail

ROM_DIR="${1:-$HOME/lineage-lindroid}"
BRANCH="${LINEAGE_BRANCH:-lineage-22.1}"
JOBS="${JOBS:-$(nproc)}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v repo >/dev/null || { echo "Faltando 'repo'. Instale com: apt install repo (ou https://gerrit.googlesource.com/git-repo)" >&2; exit 1; }

if [ ! -d "$ROM_DIR/.repo" ]; then
    mkdir -p "$ROM_DIR"
    cd "$ROM_DIR"
    repo init -u https://github.com/LineageOS/android.git -b "$BRANCH" --depth=1
fi

mkdir -p "$ROM_DIR/.repo/local_manifests"
cp "$ROOT/local_manifests/pulsar_lindroid.xml" "$ROM_DIR/.repo/local_manifests/"

cd "$ROM_DIR"
repo sync -c -j"$JOBS" --force-sync --no-tags

"$ROOT/scripts/apply-patches.sh" "$ROM_DIR"

. build/envsetup.sh
breakfast alioth
brunch alioth
