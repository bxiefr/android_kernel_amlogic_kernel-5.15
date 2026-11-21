# Linux 5.15 + vendored common_drivers for Xiaomi TV Box S (2nd gen) "jaws"

Base: LineageOS/android_kernel_amlogic_kernel-5.15 (lineage-24.0, Linux 5.15.223)
Vendored: LineageOS/android_kernel_amlogic_common_drivers (lineage-24.0, 9844f71)
          copied to ./common_drivers (no history; the old /common_drivers/ .gitignore rule was removed)

Why: the top-level Makefile expects `common_drivers` next to / inside the kernel tree
(`dtstree = common_drivers/arch/arm64/boot/dts/`). Without it `make dtbs` fails with
`No rule to make target '../common_drivers/arch/arm64/boot/dts//Makefile'`.

Build: `./build_jaws.sh [config|dtb|image|modules|all]` (needs clang/LLVM, flex, bison, etc.)
It repeats the fragment merge from LineageOS/android_kernel_xiaomi_jaws-build (build.config.jaws).

NOT included / not covered (separate LineageOS repos, see device/amlogic/ne-common lineage.dependencies):
  gpu-modules (Mali), media-modules, bt-modules, mtk-drivers/mt7663u, and boot/vendor_boot packing.
Status: config merge and dts include resolution were checked; a full kernel build and an actual boot on
hardware have NOT been tested.
