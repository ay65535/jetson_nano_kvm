### Jetson NanoでのKVMの有効化

これは以下のページを基にしています：https://developer.ridgerun.com/wiki/index.php?title=Jetson_Nano/Development/Building_the_Kernel_from_Source

Jetson Nanoのオリジナルイメージは、KVMが有効化されていません。そのため、カーネルを再コンパイルして有効化する必要があります。この記事では、SDカードを取り出したり新しいイメージを書き込んだりすることなく、すべての作業をNano内で行います。驚くかもしれませんが、Nano自体でのカーネルの再コンパイルは30分以下で完了します。

まず、Jetson Nanoに最新のUbuntuイメージを導入し、起動後、カーネルをビルドするために必要な依存パッケージをインストールします：

```bash
sudo apt update && sudo apt-get install -y build-essential bc git curl wget xxd kmod libssl-dev
```

次に、カーネルソースを[https://developer.nvidia.com/embedded/downloads](https://developer.nvidia.com/embedded/downloads)から取得する必要があります。現時点（7月15日）での最新版は[https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/sources/t210/public_sources.tbz2](https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/sources/t210/public_sources.tbz2)です。ただし、以下のスクリプトを使用してダウンロードと展開を行ってください。

Linuxカーネルには、コンパイル時に有効化するカーネルオプションを指定する設定ファイルがあります。私たちが有効にする必要があるオプションは以下の通りです：

```
CONFIG_KVM=y
CONFIG_VHOST_NET=m
```

解凍すると、`public_sources.tbz2`ファイルは`Linux_for_Tegra`に展開されます。また、`Linux_for_Tegra/source/public/kernel_src.tbz2`も解凍する必要があります。
tegraの設定ファイルは`Linux_for_Tegra/source/public/kernel/kernel-4.9/arch/arm64/configs/tegra_defconfig`にあります。

これらすべてを一度に行いましょう。なお、より新しいカーネルを使用する場合はカーネルバージョンとリンクを変更する必要があり、互換性を考慮して自分のリリースに合ったカーネルを選択すべきです：

```bash
#カーネルの取得/ビルドに必要な依存パッケージをインストール
sudo apt update && sudo apt-get install -y build-essential bc git curl wget xxd kmod libssl-dev

#カーネルの取得
cd ~/
wget https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/sources/t210/public_sources.tbz2
tar -jxvf public_sources.tbz2
JETSON_NANO_KERNEL_SOURCE=~/Linux_for_Tegra/source/public/
tar -jxvf kernel_src.tbz2

# KVMオプションを有効化するために新しい設定をtegra_defconfigに適用
cd ${JETSON_NANO_KERNEL_SOURCE}/kernel/kernel-4.9
echo "CONFIG_KVM=y
CONFIG_VHOST_NET=m" >> arch/arm64/configs/tegra_defconfig
```

この時点でカーネルをコンパイルすればKVMは有効化されますが、仮想化を大幅に高速化する重要な機能がまだ欠けています：それはirqチップです。これがないと仮想化は可能ですが、エミュレートされたirqチップははるかに遅くなります。AWS製の仮想化ツールである`firecracker`では、これが必須となるため、これがないと動作しません。

必要な作業は、デバイスツリーでCPU上のirqチップの機能を指定することです。デバイスツリーは、Jetson Nanoチップ上のすべてのデバイスのアドレスを含むファイルです。

これは手動で行う必要があります。以下のパッチを`Linux_for_Tegra/source/public/kernel_src/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-bthrot-cdev.dtsi`ファイルに適用します。patchツールは使用せず、手動で行ってください：

```
--- a/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-soc-base.dtsi     2020-08-31 08:40:36.602176618 +0800
+++ b/hardware/nvidia/soc/t210/kernel-dts/tegra210-soc/tegra210-soc-base.dtsi     2020-08-31 08:41:45.223679918 +0800
@@ -351,7 +351,10 @@
                #interrupt-cells = <3>;
                interrupt-controller;
                reg = <0x0 0x50041000 0x0 0x1000
-                      0x0 0x50042000 0x0 0x0100>;
+                       0x0 0x50042000 0x0 0x2000
+                       0x0 0x50044000 0x0 0x2000
+                       0x0 0x50046000 0x0 0x2000>;
+               interrupts = <GIC_PPI 9 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_HIGH)>;
                status = "disabled";
        };
```

ご覧の通り、`reg`と`interrupts`を追加しました。これで、カーネルイメージをコンパイルする際に、このdtsiファイルからデバイスツリーファイルもコンパイルされます。

それでは、すべてをコンパイルしましょう：

```bash
JETSON_NANO_KERNEL_SOURCE=~/Linux_for_Tegra/source/public
TEGRA_KERNEL_OUT=$JETSON_NANO_KERNEL_SOURCE/build
KERNEL_MODULES_OUT=$JETSON_NANO_KERNEL_SOURCE/modules
cd $JETSON_NANO_KERNEL_SOURCE
# 設定ファイルを生成（不足している項目は手動でy/nを押してEnterで有効/無効を設定する必要があります）
make -C kernel/kernel-4.9/ ARCH=arm64 O=$TEGRA_KERNEL_OUT LOCALVERSION=-tegra tegra_defconfig
# /boot/Imageに配置するImageを生成
make -C kernel/kernel-4.9/ ARCH=arm64 O=$TEGRA_KERNEL_OUT LOCALVERSION=-tegra -j4 --output-sync=target zImage
# ドライバーを生成（新しいImageでは古いドライバーが動作しないため必要です）
make -C kernel/kernel-4.9/ ARCH=arm64 O=$TEGRA_KERNEL_OUT LOCALVERSION=-tegra -j4 --output-sync=target modules
# 変更したデバイスファイルツリーを生成
make -C kernel/kernel-4.9/ ARCH=arm64 O=$TEGRA_KERNEL_OUT LOCALVERSION=-tegra -j4 --output-sync=target dtbs
# モジュールをビルドフォルダ ~/Linux_for_Tegra/source/public/build にインストール
make -C kernel/kernel-4.9/ ARCH=arm64 O=$TEGRA_KERNEL_OUT LOCALVERSION=-tegra INSTALL_MOD_PATH=$KERNEL_MODULES_OUT modules_install
```

Image、ドライバー、ファイルツリーが揃いましたので、これらを上書きする必要がありますが、その前に変更するフォルダの手動バックアップを作成して、問題が発生した場合に元に戻せるようにしておきます：

```bash
sudo cp /boot /boot_original
sudo cp -r /lib /lib_original
```

```
cd $JETSON_NANO_KERNEL_SOURCE/modules/lib/
sudo cp -r firmware /lib/firmware
sudo cp -r modules /lib/modules
```

これで`rsync`を使用してファイルをシステムのものと同期できます（未テスト、私の場合は`sudo nautilus`を使用して手動で移動しました）。

```bash
rsync -avh firmware /lib/firmware
rsync -avh modules /lib/modules
```

bootフォルダも更新する必要があります：

```bash
cd $JETSON_NANO_KERNEL_SOURCE/build/arc/arm64/
rsync -avh boot /boot
```

dtbファイルはすべてコピーされましたが、実際に使用するのは1つだけです。以下のコマンドを実行して、使用するファイルを確認してください：

```bash
sudo dmesg | grep -i kernel
```

私の場合の出力例：

```
[    0.236710] DTS File Name: /home/lz/Linux_for_Tegra/source/public/kernel/kernel-4.9/arch/arm64/boot/dts/../../../../../../hardware/nvidia/platform/t210/porg/kernel-dts/tegra210-p3448-0000-p3449-0000-a00.dts
```

ちょっと待って、なぜこれがローカルファイルなんでしょう？理由は分かりませんが、これで使用中のファイルが分かります。このファイル名が必要になります。ファイルは既に`/boot`にあります。

`/boot`にすべてのデバイスツリーファイルを置き換えたので、変更したものが既に読み込まれているはずだと思うかもしれません。しかし、私の場合はそうなりませんでした。上記のように、ローカルファイルを読み込んでいることが関係しているかもしれません。この変更方法が分かる方は、issueを開いてください。とりあえず、これを回避するため、`/boot/extlinux/extlinux.conf`でファイルの場所を指定する必要があります。以下の内容から：

```
TIMEOUT 30
DEFAULT primary

MENU TITLE L4T boot options

LABEL primary
      MENU LABEL primary kernel
      LINUX /boot/Image
      INITRD /boot/initrd
      APPEND ${cbootargs} quiet root=/dev/mmcblk0p1 rw rootwait rootfstype=ext4 loglevel=7 console=ttyS0,115200n8 console=tty0 fbcon=map:0 net.ifnames=0

```

以下の内容に変更します：

```
TIMEOUT 30
DEFAULT primary

MENU TITLE L4T boot options

LABEL primary
      MENU LABEL primary kernel
      LINUX /boot/Image
      INITRD /boot/initrd
      FDT /boot/tegra210-p3448-0000-p3449-0000-a00.dtb
      APPEND ${cbootargs} quiet root=/dev/mmcblk0p1 rw rootwait rootfstype=ext4 loglevel=7 console=ttyS0,115200n8 console=tty0 fbcon=map:0 net.ifnames=0

```

つまり、dtbファイルへのパスを追加します。私の場合は、`FDT /boot/tegra210-p3448-0000-p3449-0000-a00.dtb`です。

なお、2つ目のテストプロファイルを追加することもできます。これは、この動画https://www.youtube.com/watch?v=Kwpxhw41W50で示されているように、シリアルデバイスをjetson nanoに接続している場合、起動時に選択できます。起動時に番号を入力することで、2つ目の`LABEL`を選択できます。これは、オリジナルの`Image`を置き換えることなく、異なる`Image`をテストする場合に便利です。

再起動後、`ls /dev | grep kvm`を実行して、`kvm`ファイルが存在することを確認してください。これが動作している証拠です。また、以下のコマンドも実行してください：

```bash
ls  /proc/device-tree/interrupt-controller
 compatible  '#interrupt-cells'   interrupt-controller   interrupt-parent   interrupts   linux,phandle   name   phandle   reg   status
```

以前は存在しなかった`interrupts`ノードが追加されていることが確認できます。これは、irc割り込みの有効化が成功したことを意味します。

これで、qemuやfirecrackerを実行できます。ただし、私はfirecrackerのみでテストを行いました。
