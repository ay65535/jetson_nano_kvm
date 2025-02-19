#!/bin/bash
#
# .SYNOPSYS
#   Activating KVM on Jetson Nano
# .LINK
#   https://github.com/lattice0/jetson_nano_kvm
#

# This is based on https://developer.ridgerun.com/wiki/index.php/Jetson_Nano/Development/Building_the_Kernel_from_Source
# Jetson Nano's original image does not come with KVM enabled, thus we have to recompile the kernel and activate it.
# In this article, we're gonna do everything inside the Nano so we don't have to take out the SD card or flash a new image.
# You might be surprised that recompiling the kernel in the Nano itself takes less than 30 minutes.
# So, put your Nano to work with the latest Ubuntu image provided by Jetson Nano, and then boot it and install the dependencies needed to build the kernel:
# sudo apt update && sudo apt-get install -y build-essential bc git curl wget xxd kmod libssl-dev

# Now, we should get the kernel source at https://developer.nvidia.com/embedded/downloads .
# At the time of writing, (july 15) the latest is https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/sources/t210/public_sources.tbz2 .
# As of today, (june 17, 2023) the latest is https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/sources/t210/public_sources.tbz2 .

# But wait, use the script below to download and unpack everything.

#
# Environments
#

# 現在動いているSDイメージとカーネルのバージョンを確認する
cat /etc/os-release
# =>
# NAME="Ubuntu"
# VERSION="18.04.6 LTS (Bionic Beaver)"
# ID=ubuntu
# ID_LIKE=debian
# PRETTY_NAME="Ubuntu 18.04.6 LTS"
# VERSION_ID="18.04"
# HOME_URL="https://www.ubuntu.com/"
# SUPPORT_URL="https://help.ubuntu.com/"
# BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
# PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
# VERSION_CODENAME=bionic
# UBUNTU_CODENAME=bionic

cat /etc/nv_tegra_release
# => # R32 (release), REVISION: 7.3, GCID: 31982016, BOARD: t210ref, EABI: aarch64, DATE: Tue Nov 22 17:30:08 UTC 2022
cat /proc/version
# => Linux version 4.9.299-tegra (buildbrain@mobile-u64-5333-d8000) (gcc version 7.3.1 20180425 [linaro-7.3-2018.05 revision d29120a424ecfbc167ef90065c0eeb7f91977701] (Linaro GCC 7.3-2018.05) ) #1 SMP PREEMPT Tue Nov 22 09:24:39 PST 2022
# => Linux version 4.9.299-tegra (jetson@jetson-nano) (gcc version 7.5.0 (Ubuntu/Linaro 7.5.0-3ubuntu1~18.04) ) #1 SMP PREEMPT Sat Jun 17 16:52:07 JST 2023
# => Linux version 4.9.299-tegra (codespace@codespaces-600304) (gcc version 7.3.1 20180425 [linaro-7.3-2018.05 revision d29120a424ecfbc167ef90065c0eeb7f91977701] (Linaro GCC 7.3-2018.05) ) #1 SMP PREEMPT Sun Jun 18 04:26:14 UTC 2023
uname -a
# => Linux jetson-nano 4.9.299-tegra #1 SMP PREEMPT Tue Nov 22 09:24:39 PST 2022 aarch64 aarch64 aarch64 GNU/Linux
# => Linux jetson-nano 4.9.299-tegra #1 SMP PREEMPT Sat Jun 17 16:52:07 JST 2023 aarch64 aarch64 aarch64 GNU/Linux
# => Linux jetson-nano 4.9.299-tegra #1 SMP PREEMPT Sun Jun 18 04:26:14 UTC 2023 aarch64 aarch64 aarch64 GNU/Linux

#
# Documents
#

# https://developer.nvidia.com/jetson-nano-sd-card-image
#   https://developer.download.nvidia.com/embedded/L4T/r32_Release_v7.1/JP_4.6.1_b110_SD_Card/Jeston_Nano/jetson-nano-jp461-sd-card-image.zip
# https://developer.nvidia.com/embedded/jetpack-archive
#   [JetPack 4.6.1]: https://developer.nvidia.com/embedded/jetpack-sdk-461
#     [Jetson Linux R32.7.1]: https://developer.nvidia.com/embedded/linux-tegra-r3271
#       [L4T Driver Package (BSP) Sources]:
#         https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/sources/t210/public_sources.tbz2
#           https://developer.download.nvidia.com/embedded/L4T/r32_Release_v7.1/Sources/T210/public_sources.tbz2
#   [JetPack SDK 4.6.3]: https://developer.nvidia.com/jetpack-sdk-463
#     [Jetson Linux R32.7.3]: https://developer.nvidia.com/embedded/linux-tegra-r3273
#       [Driver Package (BSP) Sources]:
#         https://developer.nvidia.com/downloads/remack-sdksjetpack-463r32releasev73sourcest210publicsourcestbz2
#           https://developer.download.nvidia.com/assets/embedded/secure/tools/files/jetpack-sdks/jetpack-4.6.3/r32_Release_v7.3/sources/T210/public_sources.tbz2
#   [JetPack SDK 4.6.1 & 4.6.3]:
#     [Jetson Linux R32.7.1 & R32.7.3]:
#       [GCC 7.3.1 for 64 bit BSP and Kernel]:
#         https://developer.nvidia.com/embedded/dlc/l4t-gcc-7-3-1-toolchain-64-bit
#           https://developer.download.nvidia.com/assets/embedded/secure/jetson/GCC/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
#       [Sources for the GCC 7.3.1 Tool Chain for 64-bit BSP and Kernel]:
#         https://developer.nvidia.com/gcc-linaro-731-201805-sources
#           https://developer.download.nvidia.com/assets/embedded/secure/jetson/GCC/gcc-linaro-7.3-2018.05.tar.xz
# [Developer Guide]:
#   https://docs.nvidia.com/jetson/archives/l4t-archived/l4t-3271/index.html
#   https://docs.nvidia.com/jetson/archives/l4t-archived/l4t-3273/index.html
#     https://docs.nvidia.com/jetson/archives/l4t-archived/l4t-3273/index.html#page/Tegra%20Linux%20Driver%20Package%20Development%20Guide/kernel_custom.html#
# [Release Notes]:
#   https://docs.nvidia.com/jetson/archives/l4t-archived/l4t-3273/pdf/Jetson_Linux_Release_Notes_R32.7.3_GA.pdf

export TARGET=/workspaces/jetson_nano_kvm
export JETSON_NANO_KERNEL_SOURCE=$TARGET/Linux_for_Tegra/source/public
#export JETSON_NANO_KERNEL_SOURCE=$TARGET/Linux_for_Tegra/source/public/kernel_src

# 1.Set the shell variable with the command:
export TEGRA_KERNEL_OUT=${JETSON_NANO_KERNEL_SOURCE:?}/build
# Where:
#   <outdir> is the desired destination for the compiled kernel.
export KERNEL_MODULES_OUT=${JETSON_NANO_KERNEL_SOURCE:?}/modules

# 2.If cross-compiling on a non-Jetson system, export the following environment variables:
# export CROSS_COMPILE="$TARGET"/l4t-gcc/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
# export LOCALVERSION=-tegra
# Where:
#   <cross_prefix> is the absolute path of the ARM64 toolchain without the gcc suffix.
#   For example, for the reference ARM64 toolchain, <cross_prefix> is:
#     <toolchain_install_path>/bin/aarch64-linux-gnu-
# See The L4T Toolchain for information on how to download and build the reference toolchains.
# Note: NVIDIA recommends using the Linaro 7.3.1 2018.05 toolchain.

#
# Cleanup
#

cd $TARGET || exit
ls -A "$TARGET"
# cp "${TEGRA_KERNEL_OUT:?}"/.config.template $TARGET/
# rm -rf "${JETSON_NANO_KERNEL_SOURCE:?}"
# rm -rf "$TARGET/l4t-gcc"
# rm "$TARGET"/public_sources.tbz2
# rm "$TARGET"/kernel*.tar.gz

# The linux kernel has a config file which dictates which kernel options are enabled in the compilation process.
# What we need to do is enable these options, which are
# CONFIG_KVM=y
# CONFIG_VHOST_NET=m

# When uncompressed, the `public_sources.tbz2` file will appear at `Linux_for_Tegra`.
# We also need to unpack at `Linux_for_Tegra/source/public/kernel_src.tbz2`.
# The config file for tegra is at `Linux_for_Tegra/source/public/kernel/kernel-4.9/arch/arm64/configs/tegra_defconfig`

# So let's do all of this in one shot. Remember that you'd have to change the kernel version and the link if you want newer kernels,
# and you should pick the kernel that matches your release for better compatibility. So:

#
# Installs dependencies for getting/building the kernel
#

sudo apt update && sudo apt-get install -y build-essential bc git curl wget xxd kmod libssl-dev

#
# クロスコンパイル時にのみ必要？
#

# #wget -O $TARGET/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz http://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
# wget -O $TARGET/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz https://developer.nvidia.com/embedded/dlc/l4t-gcc-7-3-1-toolchain-64-bit

# mkdir "$TARGET/l4t-gcc"
# cd "$TARGET/l4t-gcc" || exit
# tar -xf $TARGET/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz

# Gets the kernel
#wget https://developer.download.nvidia.com/embedded/L4T/r32_Release_v7.1/Sources/T210/public_sources.tbz2  # 32.7.1
wget -O "$TARGET"/public_sources.tbz2 https://developer.nvidia.com/downloads/remack-sdksjetpack-463r32releasev73sourcest210publicsourcestbz2 # 32.7.3
cd "$TARGET" || exit
tar -xf "$TARGET"/public_sources.tbz2

ls -AF $JETSON_NANO_KERNEL_SOURCE
cd $JETSON_NANO_KERNEL_SOURCE || exit
ls -lAF $JETSON_NANO_KERNEL_SOURCE/kernel_src.tbz2
tar -xf $JETSON_NANO_KERNEL_SOURCE/kernel_src.tbz2
# =>
# hardware/
# kernel/
# nvbuild.sh
# nvcommon_build.sh

# Applies the new configs to tegra_defconfig so KVM option is enabled
ls -AF $JETSON_NANO_KERNEL_SOURCE/kernel/kernel-4.9
cd $JETSON_NANO_KERNEL_SOURCE/kernel/kernel-4.9 || exit

# Compiling the kernel now would already activate KVM, but we would still miss an important feature
# that makes virtualization much faster: the irq chip.
# Without it, virtualization is still possible but an emulated irq chip is much slower.
# On `firecracker` (a virtualization tool written by AWS), it will not work as it requires this.

# What we need to do is specify, in the device tree, the features of the irq chip on the CPU.
# The device tree is a file that contains addresses for all devices on the Jetson Nano chip.

# This must be done by hand. Apply the patch below to the file
# `Linux_for_Tegra/source/public/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-bthrot-cdev.dtsi`.
# Don't use the patch tool as it'll likely not work, just do it by hand:

grep -A5 '0x0 0x50041000 0x0 0x1000' -r $JETSON_NANO_KERNEL_SOURCE/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc

# cp $JETSON_NANO_KERNEL_SOURCE/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-soc-base.dtsi{,.orig}
sed -i.orig -e 's/0x0 0x50042000 0x0 0x0100>;/0x0 0x50042000 0x0 0x2000\n\t\t       0x0 0x50044000 0x0 0x2000\n\t\t       0x0 0x50046000 0x0 0x2000>;\n\t\tinterrupts = <GIC_PPI 9 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_HIGH)>;/' \
  $JETSON_NANO_KERNEL_SOURCE/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-soc-base.dtsi
# Restore:
#   mv $JETSON_NANO_KERNEL_SOURCE/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-soc-base.dtsi{.orig,}

diff -u $JETSON_NANO_KERNEL_SOURCE/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-soc-base.dtsi{.orig,}
# --- a/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-soc-base.dtsi.orig     2023-06-17 16:22:40.227646924 +0900
# +++ b/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-soc-base.dtsi          2023-06-17 16:24:40.669522766 +0900
# @@ -351,7 +351,10 @@
#                 #interrupt-cells = <3>;
#                 interrupt-controller;
#                 reg = <0x0 0x50041000 0x0 0x1000
# -                      0x0 0x50042000 0x0 0x0100>;
# +                      0x0 0x50042000 0x0 0x2000
# +                      0x0 0x50044000 0x0 0x2000
# +                      0x0 0x50046000 0x0 0x2000>;
# +               interrupts = <GIC_PPI 9 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_HIGH)>;
#                 status = "disabled";
#         };

# as you see, we added more `reg` and `interrupts`. Now, when we compile the kernel image,
# we'll also compile device tree files from this `dsti` file.

# https://zenn.dev/tetsu_koba/articles/7d49c86da7a4b0

# Now we should compile everything:
cd $JETSON_NANO_KERNEL_SOURCE || exit
# Generates the config file (you should manually enable/disable some missing by pressing y/n and enter)
make -C kernel/kernel-4.9/ ARCH=arm64 O="${TEGRA_KERNEL_OUT:?}" LOCALVERSION=-tegra tegra_defconfig
cp "${TEGRA_KERNEL_OUT:?}"/.config{,.orig}
#cp "${TARGET:?}"/.config.template "${TEGRA_KERNEL_OUT:?}"/

# コンフィグをカスタマイズ
make -C kernel/kernel-4.9/ ARCH=arm64 O="${TEGRA_KERNEL_OUT:?}" menuconfig

# Symbol: KVM [=n]
#   │ Type  : boolean
#   │ Prompt: Kernel-based Virtual Machine (KVM) support
#   │   Location:
#   │ (1) -> Virtualization (VIRTUALIZATION [=y])
#   │   Defined at arch/arm64/kvm/Kconfig:22
#   │   Depends on: VIRTUALIZATION [=y] && OF [=y]
#   │   Selects: MMU_NOTIFIER [=y] && PREEMPT_NOTIFIERS [=n] && ANON_INODES [=y] && HAVE_KVM_CPU_RELAX_INTERCEPT [=n] && HAVE_KVM_ARCH_TLB_FLUSH_ALL [=n] && KVM_MMIO [=n] && KVM_ARM_HOST [ │

# Symbol: VHOST_NET [=n]
#   │ Type  : tristate
#   │ Prompt: Host kernel accelerator for virtio net
#   │   Location:
#   │ (1) -> Virtualization (VIRTUALIZATION [=y])
#   │   Defined at drivers/vhost/Kconfig:1
#   │   Depends on: VIRTUALIZATION [=y] && NET [=y] && EVENTFD [=y] && (TUN [=y] || !TUN [=y]) && (MACVTAP [=m] || !MACVTAP [=m])
#   │   Selects: VHOST [=n]

# Symbol: VHOST_VSOCK [=n]
#   │ Type  : tristate
#   │ Prompt: vhost virtio-vsock driver
#   │   Location:
#   │ (1) -> Virtualization (VIRTUALIZATION [=y])
#   │   Defined at drivers/vhost/Kconfig:22
#   │   Depends on: VIRTUALIZATION [=y] && VSOCKETS [=n] && EVENTFD [=y]
#   │   Selects: VIRTIO_VSOCKETS_COMMON [=n] && VHOST [=n]

# Symbol: VSOCKETS [=n]
#   │ Type  : tristate
#   │ Prompt: Virtual Socket protocol
#   │   Location:
#   │     -> Networking support (NET [=y])
#   │ (1)   -> Networking options
#   │   Defined at net/vmw_vsock/Kconfig:5
#   │   Depends on: NET [=y]

# Symbol: MACVTAP [=m]
#   │ Type  : tristate
#   │ Prompt: MAC-VLAN based tap driver
#   │   Location:
#   │     -> Device Drivers
#   │       -> Network device support (NETDEVICES [=y])
#   │         -> Network core driver support (NET_CORE [=y])
#   │ (1)       -> MAC-VLAN support (MACVLAN [=m])
#   │   Defined at drivers/net/Kconfig:134
#   │   Depends on: NETDEVICES [=y] && NET_CORE [=y] && MACVLAN [=m] && INET [=y]

# [ -f arch/arm64/configs/tegra_defconfig ] && ! grep 'CONFIG_KVM=y' $JETSON_NANO_KERNEL_SOURCE/kernel/kernel-4.9/arch/arm64/configs/tegra_defconfig &&
#   echo -e "CONFIG_KVM=y\nCONFIG_VHOST_NET=m\nCONFIG_VHOST_VSOCK=m" >>$JETSON_NANO_KERNEL_SOURCE/kernel/kernel-4.9/arch/arm64/configs/tegra_defconfig

# Generates the Image that we're gonna place on /boot/Image
make -C kernel/kernel-4.9/ ARCH=arm64 O="${TEGRA_KERNEL_OUT:?}" LOCALVERSION=-tegra -j"$(nproc)" --output-sync=target zImage
# Generates the drivers. This is needed because the old driver will not work with our new Image
make -C kernel/kernel-4.9/ ARCH=arm64 O="${TEGRA_KERNEL_OUT:?}" LOCALVERSION=-tegra -j"$(nproc)" --output-sync=target modules
# Generates our modified device file trees
make -C kernel/kernel-4.9/ ARCH=arm64 O="${TEGRA_KERNEL_OUT:?}" LOCALVERSION=-tegra -j"$(nproc)" --output-sync=target dtbs
# Installs the modules on the build folder $TARGET/Linux_for_Tegra/source/public/build
make -C kernel/kernel-4.9/ ARCH=arm64 O="${TEGRA_KERNEL_OUT:?}" LOCALVERSION=-tegra INSTALL_MOD_PATH="${KERNEL_MODULES_OUT:?}" modules_install

# Now that we have our Image, the drivers and the file trees, we should override them,
# but before, make a manual backup of folders we're gonna change so you can rollback if something goes wrong.
[ ! -d /boot.orig ] && sudo rsync -navh --delete /boot/ /boot.orig
[ ! -d /lib.orig ] && sudo rsync -navh --delete /lib/ /lib.orig

# Reset
sudo rsync -avh --delete /lib.orig/ /lib
sudo rsync -avh --delete /boot.orig/ /boot

cd "${KERNEL_MODULES_OUT:?}"/lib/ || exit
ls -lAF /lib/firmware
ls -lAF "${KERNEL_MODULES_OUT:?}"/lib/firmware
rsync -n -rltDv "${KERNEL_MODULES_OUT:?}"/lib/firmware/ /lib/firmware
sudo rsync -rltDv "${KERNEL_MODULES_OUT:?}"/lib/firmware/ /lib/firmware
ls -lAF /lib/modules/4.9.299-tegra
ls -lAF "${KERNEL_MODULES_OUT:?}"/lib/modules/4.9.299-tegra
rsync -n -rltDv "${KERNEL_MODULES_OUT:?}"/lib/modules/ /lib/modules
sudo rsync -rltDv "${KERNEL_MODULES_OUT:?}"/lib/modules/ /lib/modules

# Now we must also update the boot folder:
cd "${TEGRA_KERNEL_OUT:?}"/arch/arm64/ || exit
ls -lAF /boot
ls -lAF "${TEGRA_KERNEL_OUT:?}"/arch/arm64/boot
rsync -nrltDv "${TEGRA_KERNEL_OUT:?}"/arch/arm64/boot/ /boot
sudo rsync -rltDv "${TEGRA_KERNEL_OUT:?}"/arch/arm64/boot/ /boot

# -a, --auto-compress
# -z, --gzip
# -h, --dereference
# -f, --file=ARCHIVE
# rm -rf "${TARGET:?}"/kernel-*.tar.gz

rm -v "${TARGET:?}"/kernel*.tar.gz

# tar -acf "${TARGET:?}"/kernel-4.9.299-tegra-boot-lib.tar.gz -C "${TEGRA_KERNEL_OUT:?}"/arch/arm64 boot  -C "${KERNEL_MODULES_OUT:?}" lib

cd "${TARGET:?}" || exit
tar -acf "${TARGET:?}"/kernel-4.9.299-tegra.tar.gz "${TEGRA_KERNEL_OUT:?}" ${JETSON_NANO_KERNEL_SOURCE:?}/kernel/kernel-4.9 "${KERNEL_MODULES_OUT:?}"/lib

find /lib/firmware /lib/modules /boot ! -user root

# Notice that we copied all of the dtb files, there are many for different models, but just one that we should use. Run
sudo dmesg | grep -i kernel | grep DTS
# to discover yours. Example of mine:
# =>
# [    0.207623] DTS File Name: /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/boot/dts/../../../../../../hardware/nvidia/platform/t210/porg/kernel-dts/tegra210-p3448-0000-p3449-0000-a02.dts
# [    0.412171] DTS File Name: /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/boot/dts/../../../../../../hardware/nvidia/platform/t210/porg/kernel-dts/tegra210-p3448-0000-p3449-0000-a02.dts
# =>
# [    0.232381] DTS File Name: /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/boot/dts/../../../../../../hardware/nvidia/platform/t210/porg/kernel-dts/tegra210-p3448-0000-p3449-0000-a02.dts
# [    0.440429] DTS File Name: /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/boot/dts/../../../../../../hardware/nvidia/platform/t210/porg/kernel-dts/tegra210-p3448-0000-p3449-0000-a02.dts
# =>
# [    0.231954] DTS File Name: /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/boot/dts/../../../../../../hardware/nvidia/platform/t210/porg/kernel-dts/tegra210-p3448-0000-p3449-0000-a02.dts
# [    0.444484] DTS File Name: /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/boot/dts/../../../../../../hardware/nvidia/platform/t210/porg/kernel-dts/tegra210-p3448-0000-p3449-0000-a02.dts

# Wait, wtf? Why this is a local file? I don't know what's happening, but this should show you which one is being used.
# You're gonna need its name. The file is already at `/boot`.
# You might wonder that since we replaced all the device tree files on `/boot`, then it should load the modified one already.
# Somehow, in my case, it didn't. I think it has to do with the fact that it's loading a local one like shown above.
# If you know how to change this, open an issue please. Anyways, to bypass this, we have to inform the `/boot/extlinux/extlinux.conf` where to locate our file. Change from
# TIMEOUT 30
# DEFAULT primary
#
# MENU TITLE L4T boot options
#
# LABEL primary
#       MENU LABEL primary kernel
#       LINUX /boot/Image
#       INITRD /boot/initrd
#       APPEND ${cbootargs} quiet root=/dev/mmcblk0p1 rw rootwait rootfstype=ext4 console=ttyS0,115200n8 console=tty0 fbcon=map:0 net.ifnames=0

ls -laF /boot/tegra210-p3448-0000-p3449-0000-a02.dt*
grep tegra210-p3448-0000-p3449-0000-a02 /boot/extlinux/extlinux.conf
# to
# TIMEOUT 30
# DEFAULT primary
#
# MENU TITLE L4T boot options
#
# LABEL primary
#       MENU LABEL primary kernel
#       LINUX /boot/Image
#       INITRD /boot/initrd
#       FDT /boot/tegra210-p3448-0000-p3449-0000-a02.dtb
#       APPEND ${cbootargs} quiet root=/dev/mmcblk0p1 rw rootwait rootfstype=ext4 console=ttyS0,115200n8 console=tty0 fbcon=map:0 net.ifnames=0 
#
# LABEL backup
#       MENU LABEL backup kernel
#       LINUX /boot.orig/Image
#       INITRD /boot.orig/initrd
#       APPEND ${cbootargs}

# that is, add the path to your dtb file. In my case, `FDT /boot/tegra210-p3448-0000-p3449-0000-a00.dtb`.

# Note that you can add a second testing profile, which can be selected at boot time if you have a serial device to plug into the jetson nano like in this video https://www.youtube.com/watch?v=Kwpxhw41W50. When you boot you can select your second `LABEL` by typing its number. This is useful if you want to test different `Image`s without substituting the original one like we did.

# Now reboot, and then run:
ls /dev | grep -E '^vhost|kvm|vsock'
# =>
# kvm
# vhost-net
# vhost-vsock
# vsock
# to confirm if the `kvm` file exists. This means it's working. You should also run

ls /proc/device-tree/interrupt-controller
# Doc:
# => compatible '#interrupt-cells' interrupt-controller interrupt-parent interrupts linux,phandle name phandle reg status
# Before:
# => compatible  '#interrupt-cells'   interrupt-controller   interrupt-parent   linux,phandle   name   phandle   reg   status
# After:
# => compatible  '#interrupt-cells'   interrupt-controller   interrupt-parent   linux,phandle   name   phandle   reg   status
# => compatible  '#interrupt-cells'   interrupt-controller   interrupt-parent   linux,phandle   name   phandle   reg   status
# => compatible  '#interrupt-cells'   interrupt-controller   interrupt-parent   linux,phandle   name   phandle   reg   status
# and see that the node `interrupts`, which didn't exist before, was added. This means the irc interrupt activation worked.

sudo dmesg | grep -i interrupt
# After:
# => [    0.000000] /interrupt-controller@60004000: 192 interrupts forwarded to /interrupt-controller
# => [    0.000000] /interrupt-controller@60004000: 192 interrupts forwarded to /interrupt-controller
# => [    0.000000] /interrupt-controller@60004000: 192 interrupts forwarded to /interrupt-controller

sudo dmesg | grep -iE 'vhost|vsock|kvm|virt'

# You can run qemu/firecracker now. I only tested with firecracker though.

lsmod | grep -E 'vhost|vsock|kvm|virt'
# =>
# vhost_net              15023  0
# vhost                  52361  1 vhost_net
# macvtap                21473  1 vhost_net
# =>
# vhost_net              15023  0
# vhost                  52361  1 vhost_net
# macvtap                21473  1 vhost_net
# =>
# vhost_vsock            13434  0
# vmw_vsock_virtio_transport_common    30778  1 vhost_vsock
# vsock                  36419  2 vhost_vsock,vmw_vsock_virtio_transport_common
# vhost_net              15023  0
# vhost                  52489  2 vhost_vsock,vhost_net
# macvtap                21537  1 vhost_net

cat /etc/modules
# =>
# vhost_net
