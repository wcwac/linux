#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
set -eux

case "$1" in
build)
	export ARCH="$2"
	export CROSS_COMPILE="$3-"

	nproc && grep Mem /proc/meminfo && df -hT .
	apk add build-base bison findutils flex gmp-dev mpc1-dev mpfr-dev openssl-dev perl "gcc-$3"

	# Workaround problem with faccessat2() on Drone CI
	wget https://gist.githubusercontent.com/TravMurav/36c83efbc188115aa9b0fc7f4afba63e/raw/faccessat.c -P /opt
	gcc -O2 -shared -o /opt/faccessat.so /opt/faccessat.c
	export LD_PRELOAD=/opt/faccessat.so

	make msm8916_defconfig
	make KCFLAGS="-Wall -Werror" -j$(nproc)
	;;
check)
	apk add git perl
	git format-patch origin/$DRONE_TARGET_BRANCH
	scripts/checkpatch.pl --strict --color=always *.patch || :
	! scripts/checkpatch.pl --strict --color=always --terse --show-types *.patch \
		| grep -Ff .drone-checkpatch.txt
	;;
*)
	exit 1
	;;
esac
