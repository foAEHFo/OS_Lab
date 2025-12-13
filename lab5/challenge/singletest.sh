#!/bin/sh

prog=${1:-hello}

if gmake --version > /dev/null 2>&1; then
    make=gmake
else
    make=make
fi

# 编译指定程序
$make build-$prog || exit 1

qemu=$($make --quiet print-qemu)

qemuopts="-machine virt -nographic -bios default \
-device loader,file=bin/ucore.img,addr=0x80200000"

# 使用 timeout 命令 3 秒后强制退出
exec timeout 1s $qemu -nographic $qemuopts
