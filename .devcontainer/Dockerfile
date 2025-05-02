# MULTIARCH
FROM ubuntu:18.04 AS base
# linux/amd64
# FROM ubuntu@sha256:152dc042452c496007f07ca9127571cb9c29697f42acbfad72324b2bb2e43c98 AS base

ARG KERNEL_SRC=/Linux_for_Tegra/source/public
ARG TEGRA_KERNEL_SRC=$KERNEL_SRC/kernel/kernel-4.9

ARG TEGRA_KERNEL_OUT=$KERNEL_SRC/build
ENV TEGRA_KERNEL_OUT=$TEGRA_KERNEL_OUT

ARG KERNEL_MODULES_OUT=$KERNEL_SRC/modules
ENV KERNEL_MODULES_OUT=$KERNEL_MODULES_OUT

# Jetson以外のシステムでクロスコンパイルする場合は、以下の環境変数をエクスポートします:
# GCC 7.3.1 for 64 bit BSP and Kernel:
# https://developer.nvidia.com/embedded/dlc/l4t-gcc-7-3-1-toolchain-64-bit
# ENV LINARO_URL=http://releases.linaro.org/components/toolchain/binaries/7.3-2018.05/aarch64-linux-gnu/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu.tar.xz
# ARG LINARO=gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu
# ARG CROSS_COMPILE=$HOME/l4t-gcc/$LINARO/bin/aarch64-linux-gnu-
# ARG CROSS_COMPILE=/$LINARO/bin/aarch64-linux-gnu-
# ENV CROSS_COMPILE=$CROSS_COMPILE
ARG LOCALVERSION=-tegra
ENV LOCALVERSION=$LOCALVERSION

# RUN wget -O $LINARO.tar.xz $LINARO_URL && \
#     tar -xf $LINARO.tar.xz && \
#     rm -f $LINARO.tar.xz

# Driver Package (BSP) Sources:
# https://developer.download.nvidia.com/embedded/L4T/r32_Release_v7.1/Sources/T210/public_sources.tbz2  # 32.7.1
# https://developer.download.nvidia.com/embedded/L4T/r32_Release_v7.6/sources/T210/public_sources.tbz2  # 32.7.6
ENV PUBLIC_SOURCES_URL=https://developer.download.nvidia.com/embedded/L4T/r32_Release_v7.6/sources/T210/public_sources.tbz2

RUN apt-get update && apt-get -y upgrade && apt-get -y install --no-install-recommends \
    git-core \
    build-essential bc \
    libncurses5 libncurses5-dev sudo vim kmod usbutils \
    git curl wget xxd \
    ca-certificates \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

# FROM base AS builder

# Gets the kernel
RUN wget -O public_sources.tbz2 $PUBLIC_SOURCES_URL && \
    tar -xf public_sources.tbz2 && \
    rm -f public_sources.tbz2

WORKDIR $KERNEL_SRC
RUN tar -xf kernel_src.tbz2

#
# user
#
RUN useradd -m tegra && \
    echo 'tegra ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER tegra

#
# kernel config
#

# WORKDIR $TEGRA_KERNEL_SRC
# RUN make ARCH=arm64 O="$TEGRA_KERNEL_OUT" LOCALVERSION=$LOCALVERSION tegra_defconfig
# RUN make ARCH=arm64 O="$TEGRA_KERNEL_OUT" LOCALVERSION=$LOCALVERSION nconfig

# build out dir
ENV TEGRA_KERNEL_OUT=/home/tegra/kernel_build
WORKDIR $TEGRA_KERNEL_OUT
# KVM, VHOST_NET
COPY ./Kconfig/menuconfig-minimal .config
# KVM, VHOST_NET, IP_SET, ISCSI関連, etc.
# COPY ./Kconfig/menuconfig .config

# kernel sources code dir
WORKDIR $TEGRA_KERNEL_SRC

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["bash", "/docker-entrypoint.sh"]
