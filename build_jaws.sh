#!/usr/bin/env bash
# Build helper for Xiaomi TV Box S (2nd gen) "jaws" (Amlogic S905X4 / SC2) on this
# self-contained tree: Linux 5.15 (android14 GKI base) + vendored common_drivers/.
#
# It reproduces the config merge done by LineageOS' android_kernel_xiaomi_jaws-build
# (build.config.jaws) without needing Bazel/Kleaf or a full `repo sync`.
#
# NOT covered: GPU (Mali), media/codec, Wi-Fi/BT vendor modules, boot/vendor_boot
# image packing. Those live in other repos (see README_JAWS.md).
#
# Usage: ./build_jaws.sh [config|dtb|image|modules|all]   (default: all)
#   env: OUT=out  JOBS=$(nproc)  LLVM=1
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

STEP="${1:-all}"
OUT="${OUT:-out}"
JOBS="${JOBS:-$(nproc)}"
DEFCONFIG=amlogic_gki_defconfig
CFG=arch/arm64/configs
CD=common_drivers/arch/arm64/configs

export ARCH=arm64
export LLVM="${LLVM:-1}"
export COMMON_DRIVERS_DIR=common_drivers
export DTC_INCLUDE="$PWD/common_drivers/include"

if [ -e ../common_drivers ]; then
  echo "WARNING: ../common_drivers exists; the top Makefile would symlink it into this" >&2
  echo "         tree. Remove it so the vendored ./common_drivers is the one used." >&2
fi

do_config() {
  # Same fragment list/order as build.config.jaws (pre_defconfig_cmds).
  KCONFIG_CONFIG="$CFG/$DEFCONFIG" scripts/kconfig/merge_config.sh -m -r \
    "$CFG/gki_defconfig" \
    "$CD/amlogic_gki.fragment" \
    "$CD/amlogic_gki.10" \
    "$CD/amlogic_gki.debug" \
    "$CD/amlogic_upgrade_u.defconfig" \
    "$CD/amlogic_common.defconfig" \
    "$CD/amlogic_ne.fragment"
  make O="$OUT" "$DEFCONFIG"
  rm -f "$CFG/$DEFCONFIG"   # post_defconfig_cmds in build.config.jaws
}

case "$STEP" in
  config)  do_config ;;
  dtb)     [ -f "$OUT/.config" ] || do_config
           make -j"$JOBS" O="$OUT" amlogic/sc2_s905x4_jaws.dtb ;;
  image)   [ -f "$OUT/.config" ] || do_config
           make -j"$JOBS" O="$OUT" Image ;;
  modules) [ -f "$OUT/.config" ] || do_config
           make -j"$JOBS" O="$OUT" modules ;;
  all)     do_config
           make -j"$JOBS" O="$OUT" Image dtbs modules ;;
  *) echo "usage: $0 [config|dtb|image|modules|all]" >&2; exit 2 ;;
esac

echo "Done. Outputs under $OUT/arch/arm64/boot/"
