#!/bin/bash
set -euo pipefail

cat <<EOF
LINARO_URL         : $LINARO_URL
CROSS_COMPILE      : $CROSS_COMPILE
LOCALVERSION       : $LOCALVERSION
PUBLIC_SOURCES_URL : $PUBLIC_SOURCES_URL
TEGRA_KERNEL_OUT   : $TEGRA_KERNEL_OUT
KERNEL_MODULES_OUT : $KERNEL_MODULES_OUT
EOF

cd /Linux_for_Tegra/source/public/kernel/kernel-4.9

#
# patch
#
# Apply patch only if --patch or -p option is specified
if [[ "$*" == *"--patch"* ]] || [[ "$*" == *"-p"* ]]; then
  echo "Applying kernel patch..."
  sed -i -e 's/0x0 0x50042000 0x0 0x0100>;/0x0 0x50042000 0x0 0x2000\n\t\t       0x0 0x50044000 0x0 0x2000\n\t\t       0x0 0x50046000 0x0 0x2000>;\n\t\tinterrupts = <GIC_PPI 9 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_HIGH)>;/' \
    /Linux_for_Tegra/source/public/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-soc-base.dtsi
  echo "Patch applied successfully."
else
  echo "Skipping patch application. Use --patch or -p option to apply patch."
fi

# オリジナルの引数から--patchと-pを除去した配列を作成
filtered_args=()
for arg in "$@"; do
  if [[ "$arg" != "--patch" && "$arg" != "-p" ]]; then
    filtered_args+=("$arg")
  fi
done

if [ ${#filtered_args[@]} -eq 0 ]; then
  echo "No build target specified. Using default '-j<n+1>'"
  make ARCH=arm64 O="$TEGRA_KERNEL_OUT" -j$(($(nproc) + 1))
else
  echo "Running make with provided arguments: ${filtered_args[*]}"
  make ARCH=arm64 O="$TEGRA_KERNEL_OUT" "${filtered_args[@]}"
fi

# コンテナを実行し続けるために待機
exec sleep infinity
