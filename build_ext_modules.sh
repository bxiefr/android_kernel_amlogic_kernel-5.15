#!/usr/bin/env bash
# Out-of-tree vendor modules for jaws (Amlogic S905X4), built with plain make (no Bazel).
#   gpu    -> vendor/amlogic/gpu-modules/bifrost  (Mali-G31 "dvalin", driver r47p0)  => mali_kbase.ko
#   media  -> vendor/amlogic/media-modules        (video decoders/encoders, firmware)
# Requires an already built kernel in $OUT (needs $OUT/Module.symvers from `make modules`).
# Usage: ./build_ext_modules.sh [gpu] [media]     (default: gpu media)
#   env: OUT=out  JOBS=$(nproc)  DEST=$OUT/../extmod_out  (+ any CC/LLVM/CROSS_COMPILE you build the kernel with)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
KS="$PWD"
OUT="$(realpath "${OUT:-out}")"
JOBS="${JOBS:-$(nproc)}"
DEST="${DEST:-$OUT/../extmod_out}"
GPU_DRV_VERSION="${GPU_DRV_VERSION:-r47p0}"
[ $# -gt 0 ] || set -- gpu media

export ARCH=arm64 COMMON_DRIVERS_DIR=common_drivers KCONFIG_EXT_PREFIX=common_drivers/
export DTC_INCLUDE="$KS/common_drivers/include"
[ -f "$OUT/Module.symvers" ] || { echo "HATA: $OUT/Module.symvers yok - once kernel + modules derlenmeli" >&2; exit 1; }
[ -n "${CC:-}${LLVM:-}" ] || export LLVM=1

mkdir -p "$DEST/modules"
for t in "$@"; do
  case "$t" in
    gpu)   dir=vendor/amlogic/gpu-modules/bifrost
           make -C "$dir" -j"$JOBS" KERNEL_SRC="$KS" O="$OUT" M="$dir" INCLUDE="$KS/include" \
                GPU_DRV_VERSION="$GPU_DRV_VERSION" GPU_LOW_MEM=0 \
                KBUILD_EXTRA_SYMBOLS="$OUT/Module.symvers" modules ;;
    media) dir=vendor/amlogic/media-modules
           make -C "$dir" -j"$JOBS" KERNEL_SRC="$KS" O="$OUT" M="$dir" INCLUDE="$KS/include" \
                KBUILD_EXTRA_SYMBOLS="$OUT/Module.symvers" modules ;;
    *) echo "bilinmeyen hedef: $t (gpu|media)" >&2; exit 2 ;;
  esac
  n=0
  while IFS= read -r ko; do cp -f "$ko" "$DEST/modules/"; n=$((n+1)); done \
    < <(find "$dir" -name '*.ko' -type f)
  echo "[$t] $n .ko kopyalandi -> $DEST/modules"
  [ "$n" -gt 0 ] || { echo "HATA: $t hic .ko uretmedi" >&2; exit 1; }
done
# media firmware (stok vendor_lib/firmware/video'ya gider)
case " $* " in *" media "*) mkdir -p "$DEST/firmware/video"; cp -r vendor/amlogic/media-modules/firmware/. "$DEST/firmware/video/" ;; esac
ls -la "$DEST/modules" | head -80
