#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2018 Raphiel Rollerscaperers (raphielscape)
# Copyright (C) 2018 Rama Bondan Prakoso (rama982)
# Android Kernel Build Script

#Package
sudo apt install bc bash git-core gnupg build-essential \
    zip curl make automake autogen autoconf autotools-dev libtool shtool python \
    m4 gcc libtool zlib1g-dev flex bison libssl-dev

# Toolchain
if [ ! -d stock ]; then
git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9 -b android-11.0.0_r48 --depth=1 stock
fi
if [ ! -d stock_32 ]; then
git clone https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9 -b android-11.0.0_r48 --depth=1 stock_32
fi

# AnyKernel3
if [ ! -d AnyKernel3 ]; then
git clone https://github.com/Jaxer159/AnyKernel3 -b dragonfire_lime AnyKernel3
fi

# Clang
if [ ! -d ~/toolchains/proton-clang ]; then
git clone https://github.com/kdrag0n/proton-clang ~/toolchains/proton-clang --depth=1
fi
if [ ! -d ~/toolchains/gcc64 ]; then
git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 ~/toolchains/gcc64
fi

# Libufdt
if [ ! -d libufdt ]; then
    wget https://android.googlesource.com/platform/system/libufdt/+archive/refs/tags/android-11.0.0_r48/utils.tar.gz
    mkdir -p libufdt
    tar xvzf utils.tar.gz -C libufdt
    rm utils.tar.gz
fi

#BUILD KERNEL

# Main environtment
KERNEL_DIR=$PWD
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
TC_DIR="$HOME/toolchains/proton-clang"
ZIP_DIR=$KERNEL_DIR/AnyKernel3
CONFIG=vendor/dragonfire_defconfig

# Export
export ARCH=arm64
export PATH="$TC_DIR/bin:$PATH"
#export CROSS_COMPILE=$HOME/toolchains/gcc64/bin/aarch64-linux-androidkernel-
export KBUILD_BUILD_USER=jaxer159
export KBUILD_BUILD_HOST=Dragonfire-build

if [[ $1 == "-c" || $1 == "--clean" ]]; then
if [  -d "./out/" ]; then
echo -e " "
        rm -rf ./out/
fi
echo -e "\nFull cleaning was succesfully!\n"
fi

if [[ $1 == "-r" || $1 == "--regen" ]]; then
        make O=out ARCH=arm64 $CONFIG savedefconfig
	      cp out/defconfig arch/arm64/configs/$CONFIG
echo -e "\nRegened defconfig succesfully!\n"
make mrproper
echo -e "\nCleaning was succesfully!\n"
exit 1
fi

# Main Staff
gcc_prefix64="aarch64-linux-gnu-"
gcc_prefix32="arm-linux-gnueabi-"
CROSS_COMPILE="aarch64-linux-gnu-"
CROSS_COMPILE_ARM32="arm-linux-gnueabi-"

# Build start
make O=out ARCH=arm64 $CONFIG
make	-j`nproc --all` O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip TARGET_PRODUCT=bengal CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- Image.gz-dtb dtbo.img

if ! [ -a $KERN_IMG ]; then
    echo -e "\nKernel Compilation failed! Fix the errors!\n"
fi

cd $ZIP_DIR
make clean &>/dev/null
cd ..

OUTDIR="$KERNEL_DIR/out"
cd libufdt/src && python2 mkdtboimg.py create $OUTDIR/arch/arm64/boot/dtbo.img $OUTDIR/arch/arm64/boot/dts/vendor/qcom/*.dtbo

echo -e "\nDone moving modules\n"
cd $ZIP_DIR
cp $KERN_IMG zImage
cp $OUTDIR/arch/arm64/boot/dtbo.img $ZIP_DIR
make normal &>/dev/null
echo -e "\n(i)          Completed build $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !\n"
echo -e "\n             Flashable zip generated under $ZIP_DIR.\n"
cd ..
# Build end
