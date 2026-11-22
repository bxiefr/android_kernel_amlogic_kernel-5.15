#!/usr/bin/env bash
# Out-of-tree vendor modules for jaws (Amlogic S905X4), built with plain make (no Bazel).
#   gpu    -> vendor/amlogic/gpu-modules/bifrost  (Mali-G31 "dvalin", driver r47p0)  => mali_kbase.ko
#   media  -> vendor/amlogic/media-modules        (video decoders/encoders, firmware)
#   bt     -> vendor/amlogic/bt-modules/mtk       (MediaTek USB Bluetooth)  => btmtk_usb.ko
#   wifi   -> vendor/amlogic/mtk-drivers/mt7663u  (MT7663U USB Wi-Fi)       => wlan_mt7663_usb(.ko/_prealloc.ko)
# Requires an already built kernel in $OUT (needs $OUT/Module.symvers from `make modules`).
# Usage: ./build_ext_modules.sh [gpu] [media] [bt] [wifi]     (default: gpu media bt wifi)
#   env: OUT=out  JOBS=$(nproc)  DEST=$OUT/../extmod_out  (+ any CC/LLVM/CROSS_COMPILE you build the kernel with)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
KS="$PWD"
OUT="$(realpath "${OUT:-out}")"
JOBS="${JOBS:-$(nproc)}"
DEST="${DEST:-$OUT/../extmod_out}"
GPU_DRV_VERSION="${GPU_DRV_VERSION:-r47p0}"
[ $# -gt 0 ] || set -- gpu media bt wifi

export ARCH=arm64 COMMON_DRIVERS_DIR=common_drivers KCONFIG_EXT_PREFIX=common_drivers/
export DTC_INCLUDE="$KS/common_drivers/include"
[ -f "$OUT/Module.symvers" ] || { echo "HATA: $OUT/Module.symvers yok - once kernel + modules derlenmeli" >&2; exit 1; }
[ -n "${CC:-}${LLVM:-}" ] || export LLVM=1

# Vendor Makefile'lari KBUILD_EXTRA_SYMBOLS'u sabit olarak $KS/common_drivers/Module.symvers'e yonlendiriyor
# (Kleaf'ta common_drivers ayri derlendigi icin orada duruyor). Burada common_drivers cekirdegin icinde
# derleniyor; semboller zaten $OUT/Module.symvers'te ve kbuild onu kendisi okuyor. O yolu out/'a
# baglamak "exported twice" modpost hatasi verir, bu yuzden bos dosya birakiyoruz (uyariyi susturur).
rm -f "$KS/common_drivers/Module.symvers"; : > "$KS/common_drivers/Module.symvers"

mkdir -p "$DEST/modules"
for t in "$@"; do
  case "$t" in
    gpu)   dir=vendor/amlogic/gpu-modules/bifrost
           make -C "$dir" -j"$JOBS" KERNEL_SRC="$KS" O="$OUT" M="$dir" INCLUDE="$KS/include" \
                GPU_DRV_VERSION="$GPU_DRV_VERSION" GPU_LOW_MEM=0 \
                modules ;;
    media) dir=vendor/amlogic/media-modules
           make -C "$dir" -j"$JOBS" KERNEL_SRC="$KS" O="$OUT" M="$dir" INCLUDE="$KS/include" \
                modules ;;
    bt)    dir=vendor/amlogic/bt-modules/mtk
           make -C "$dir" -j"$JOBS" KERNEL_SRC="$KS" O="$OUT" M="$dir" modules ;;
    wifi)  dir=vendor/amlogic/mtk-drivers/mt7663u/wlan_driver
           make -C "$dir" -j"$JOBS" KERNEL_SRC="$KS" O="$OUT" M="$dir" modules ;;
    *) echo "bilinmeyen hedef: $t (gpu|media|bt|wifi)" >&2; exit 2 ;;
  esac
  n=0
  while IFS= read -r ko; do cp -f "$ko" "$DEST/modules/"; n=$((n+1)); done \
    < <(find "$OUT/$dir" "$dir" -name '*.ko' -type f 2>/dev/null)
  echo "[$t] $n .ko kopyalandi -> $DEST/modules"
  [ "$n" -gt 0 ] || { echo "HATA: $t hic .ko uretmedi" >&2; exit 1; }
done
# media firmware (stok vendor_lib/firmware/video'ya gider)
case " $* " in *" media "*) mkdir -p "$DEST/firmware/video"; cp -r vendor/amlogic/media-modules/firmware/. "$DEST/firmware/video/" ;; esac
case " $* " in *" wifi "*) mkdir -p "$DEST/firmware/wifi"; cp -r vendor/amlogic/mtk-drivers/mt7663u/firmware/. "$DEST/firmware/wifi/" ;; esac
ls -la "$DEST/modules" | head -80
