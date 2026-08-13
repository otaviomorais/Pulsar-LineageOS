#!/usr/bin/env bash
# Applies Pulsar-LineageOS patches on a synced LineageOS tree.
set -euo pipefail

ROM_DIR="${1:-$HOME/lineage-lindroid}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

apply_patch() {
    local repo="$1"
    local patch="$2"
    cd "$ROM_DIR/$repo"
    if git apply --check "$patch" 2>/dev/null; then
        echo "==> [OK] aplicando $patch"
        git am --3way "$patch"
    elif git apply --check -R "$patch" 2>/dev/null; then
        echo "==> [SKIP] ja aplicado: $patch"
    else
        echo "==> [ERRO] nao aplicou: $patch" >&2
        return 1
    fi
}

apply_patch frameworks/native "$ROOT/patches/frameworks_native/0001-inputflinger-allow-disable-input-via-idc.patch"
apply_patch frameworks/base "$ROOT/patches/frameworks_base/0001-ignore-null-uevent-name-extcon-wiredaccessory.patch"
apply_patch device/xiaomi/alioth "$ROOT/patches/device_xiaomi_alioth/0001-alioth-inherit-lindroid.patch"

# FCM fix (LinDroid pinned message): remove "# CONFIG_SYSVIPC is not set"
# so the kernel config passes the FCM requirement check.
find "$ROM_DIR/kernel/xiaomi/sm8250/kernel/configs" -name 'android-base.config' 2>/dev/null | while read -r f; do
    if grep -q '^# CONFIG_SYSVIPC is not set' "$f"; then
        sed -i '/^# CONFIG_SYSVIPC is not set/d' "$f"
        echo "==> FCM fix em $f"
    fi
done

echo "Patches aplicados com sucesso."
