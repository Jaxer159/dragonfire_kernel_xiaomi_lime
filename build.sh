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

CHATID="-1001798647551"
token=$TELEGRAM_TOKEN
DATE=$(TZ=Asia/Moscow date +"%F")
COMMIT_HEAD=$(git log --oneline -1)
KERVER=$(make kernelversion)
KBUILD_COMPILER_STRING="proton-clang"
CI_BRANCH=$(git rev-parse --abbrev-ref HEAD)

export BOT_MSG_URL="https://api.telegram.org/bot$token/sendMessage"
export BOT_BUILD_URL="https://api.telegram.org/bot$token/sendDocument"

tg_post_msg() {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="-1001798647551" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

tg_post_build() {
	#Post MD5Checksum alongwith for easeness
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	#Show the Checksum alongwith caption
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
	-F chat_id="$2"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$3"  
}

tg_post_msg "<b>🔨 CI Build Triggered</b>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Moscow date)</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0a<b>Branch : </b><code>$CI_BRANCH</code>" "$CHATID"

SECONDS=0

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
    tg_post_msg "<b>❌ Build failed to compile after $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) seconds</b>" "$CHATID"
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
# Sign the zip before sending it to Telegram
KERNEL="Dragonfire"
DEVICE="lime"
VER="1.0"
KERNELNAME="${KERNEL}-${DEVICE}-${VER}"
ZIPNAME="AnyKernel3/${KERNELNAME}.zip"
tg_post_build "$ZIPNAME" "$CHATID" "✅ Build took : $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)"
