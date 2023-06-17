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
cat /etc/nv_tegra_release
# => # R32 (release), REVISION: 7.3, GCID: 31982016, BOARD: t210ref, EABI: aarch64, DATE: Tue Nov 22 17:30:08 UTC 2022
cat /proc/version
# =>
# Linux version 4.9.299-tegra (buildbrain@mobile-u64-5333-d8000)
# (gcc version 7.3.1 20180425 [linaro-7.3-2018.05 revision d29120a424ecfbc167ef90065c0eeb7f91977701] (Linaro GCC 7.3-2018.05) )
# #1 SMP PREEMPT Tue Nov 22 09:24:39 PST 2022
uname -a
# => Linux jetson-nano 4.9.299-tegra #1 SMP PREEMPT Tue Nov 22 09:24:39 PST 2022 aarch64 aarch64 aarch64 GNU/Linux

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

#
# Cleanup
#

TARGET=~/Linux_for_Tegra
ls -A "$TARGET"
rm -rf "${TARGET:?}"/source
ls -A "$TARGET"
rm ~/public_sources.tbz2
ls -A ~

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

# wget http://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
# mkdir "$HOME/l4t-gcc"
# cd "$HOME/l4t-gcc" || exit
# tar -xf ../gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz

# 1.Set the shell variable with the command:
#TEGRA_KERNEL_OUT=<outdir>
# Where:
#   <outdir> is the desired destination for the compiled kernel.

# 2.If cross-compiling on a non-Jetson system, export the following environment variables:
#export CROSS_COMPILE=$HOME/l4t-gcc/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-
#export LOCALVERSION=-tegra
# Where:
#   <cross_prefix> is the absolute path of the ARM64 toolchain without the gcc suffix.
#   For example, for the reference ARM64 toolchain, <cross_prefix> is:
#     <toolchain_install_path>/bin/aarch64-linux-gnu-
# See The L4T Toolchain for information on how to download and build the reference toolchains.
# Note: NVIDIA recommends using the Linaro 7.3.1 2018.05 toolchain.

# Gets the kernel
cd ~ || exit
#wget https://developer.download.nvidia.com/embedded/L4T/r32_Release_v7.1/Sources/T210/public_sources.tbz2  # 32.7.1
wget -O public_sources.tbz2 https://developer.nvidia.com/downloads/remack-sdksjetpack-463r32releasev73sourcest210publicsourcestbz2 # 32.7.3
tar -xf public_sources.tbz2

JETSON_NANO_KERNEL_SOURCE=~/Linux_for_Tegra/source/public
ls -A $JETSON_NANO_KERNEL_SOURCE
# mkdir -p $JETSON_NANO_KERNEL_SOURCE/kernel_src
# ls -A $JETSON_NANO_KERNEL_SOURCE/kernel_src
# cd $JETSON_NANO_KERNEL_SOURCE/kernel_src || exit
cd $JETSON_NANO_KERNEL_SOURCE || exit
tar -xf ./kernel_src.tbz2
# =>
# hardware/
# kernel/
# nvbuild.sh
# nvcommon_build.sh

# Applies the new configs to tegra_defconfig so KVM option is enabled
ls -A $JETSON_NANO_KERNEL_SOURCE/kernel/kernel-4.9
cd $JETSON_NANO_KERNEL_SOURCE/kernel/kernel-4.9 || exit
[ -f arch/arm64/configs/tegra_defconfig ] && ! grep 'CONFIG_KVM=y' arch/arm64/configs/tegra_defconfig &&
  echo -e "CONFIG_KVM=y\nCONFIG_VHOST_NET=m" >>arch/arm64/configs/tegra_defconfig

# Compiling the kernel now would already activate KVM, but we would still miss an important feature
# that makes virtualization much faster: the irq chip.
# Without it, virtualization is still possible but an emulated irq chip is much slower.
# On `firecracker` (a virtualization tool written by AWS), it will not work as it requires this.

# What we need to do is specify, in the device tree, the features of the irq chip on the CPU.
# The device tree is a file that contains addresses for all devices on the Jetson Nano chip.

# This must be done by hand. Apply the patch below to the file
# `Linux_for_Tegra/source/public/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-bthrot-cdev.dtsi`.
# Don't use the patch tool as it'll likely not work, just do it by hand:

grep '0x0 0x50042000 0x0 0x0100' -r $JETSON_NANO_KERNEL_SOURCE/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc

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

# Now we should compile everything:
TEGRA_KERNEL_OUT=$JETSON_NANO_KERNEL_SOURCE/build
KERNEL_MODULES_OUT=$JETSON_NANO_KERNEL_SOURCE/modules
cd $JETSON_NANO_KERNEL_SOURCE || exit
# Generates the config file (you should manually enable/disable some missing by pressing y/n and enter)
make -C kernel/kernel-4.9/ ARCH=arm64 O=${TEGRA_KERNEL_OUT:?} LOCALVERSION=-tegra tegra_defconfig
# Generates the Image that we're gonna place on /boot/Image
make -C kernel/kernel-4.9/ ARCH=arm64 O=${TEGRA_KERNEL_OUT:?} LOCALVERSION=-tegra -j4 --output-sync=target zImage
# Generates the drivers. This is needed because the old driver will not work with our new Image
make -C kernel/kernel-4.9/ ARCH=arm64 O=${TEGRA_KERNEL_OUT:?} LOCALVERSION=-tegra -j4 --output-sync=target modules
# Generates our modified device file trees
make -C kernel/kernel-4.9/ ARCH=arm64 O=${TEGRA_KERNEL_OUT:?} LOCALVERSION=-tegra -j4 --output-sync=target dtbs
# Installs the modules on the build folder ~/Linux_for_Tegra/source/public/build
make -C kernel/kernel-4.9/ ARCH=arm64 O=${TEGRA_KERNEL_OUT:?} LOCALVERSION=-tegra INSTALL_MOD_PATH=${KERNEL_MODULES_OUT:?} modules_install

# Now that we have our Image, the drivers and the file trees, we should override them,
# but before, make a manual backup of folders we're gonna change so you can rollback if something goes wrong.
sudo cp -r /boot /boot.orig
sudo cp -r /lib /lib.orig

cd $JETSON_NANO_KERNEL_SOURCE/modules/lib/ || exit
ls -la /lib/firmware
ls -la ./firmware
rsync -n -rltDv ./firmware/ /lib/firmware
sudo rsync -rltDv ./firmware/ /lib/firmware
ls -la /lib/modules
ls -la ./modules
rsync -n -rltDv ./modules/ /lib/modules
sudo rsync -rltDv ./modules/ /lib/modules

# Now we must also update the boot folder:
cd $JETSON_NANO_KERNEL_SOURCE/build/arch/arm64/ || exit
ls -la /boot
ls -la ./boot
rsync -nrltDv ./boot/ /boot
sudo rsync -rltDv ./boot/ /boot

# Notice that we copied all of the dtb files, there are many for different models, but just one that we should use. Run
sudo dmesg | grep -i kernel | grep DTS
# to discover yours. Example of mine:
# => [    0.207623] DTS File Name: /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/boot/dts/../../../../../../hardware/nvidia/platform/t210/porg/kernel-dts/tegra210-p3448-0000-p3449-0000-a02.dts
# => [    0.412171] DTS File Name: /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/boot/dts/../../../../../../hardware/nvidia/platform/t210/porg/kernel-dts/tegra210-p3448-0000-p3449-0000-a02.dts

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
#       APPEND ${cbootargs} quiet root=/dev/mmcblk0p1 rw rootwait rootfstype=ext4 loglevel=7 console=ttyS0,115200n8 console=tty0 fbcon=map:0 net.ifnames=0

code /boot/extlinux/extlinux.conf
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
#       FDT /boot/tegra210-p3448-0000-p3449-0000-a00.dtb
#       APPEND ${cbootargs} quiet root=/dev/mmcblk0p1 rw rootwait rootfstype=ext4 loglevel=7 console=ttyS0,115200n8 console=tty0 fbcon=map:0 net.ifnames=0

# that is, add the path to your dtb file. In my case, `FDT /boot/tegra210-p3448-0000-p3449-0000-a00.dtb`.

# Note that you can add a second testing profile, which can be selected at boot time if you have a serial device to plug into the jetson nano like in this video https://www.youtube.com/watch?v=Kwpxhw41W50. When you boot you can select your second `LABEL` by typing its number. This is useful if you want to test different `Image`s without substituting the original one like we did.

# Now reboot, and then run:
ls /dev | grep kvm
# to confirm if the `kvm` file exists. This means it's working. You should also run

ls /proc/device-tree/interrupt-controller
# Doc:
# => compatible '#interrupt-cells' interrupt-controller interrupt-parent interrupts linux,phandle name phandle reg status
# Before:
# => compatible  '#interrupt-cells'   interrupt-controller   interrupt-parent   linux,phandle   name   phandle   reg   status
# After:
# => compatible  '#interrupt-cells'   interrupt-controller   interrupt-parent   linux,phandle   name   phandle   reg   status
# and see that the node `interrupts`, which didn't exist before, was added. This means the irc interrupt activation worked.

sudo dmesg | grep -i interrupts
# After:
# => [    0.000000] /interrupt-controller@60004000: 192 interrupts forwarded to /interrupt-controller

# You can run qemu/firecracker now. I only tested with firecracker though.
