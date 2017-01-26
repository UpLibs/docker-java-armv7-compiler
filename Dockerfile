FROM thewtex/cross-compiler-linux-armv7

RUN apt-get update && apt-get install -y --no-install-recommends \
		bzip2 \
		unzip \
		xz-utils \
		tar \
		gzip \
		nano \
	&& rm -rf /var/lib/apt/lists/*

RUN echo 'deb http://deb.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list

# Default to UTF-8 file.encoding 
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64

ENV JAVA_VERSION 8u111
ENV JAVA_DEBIAN_VERSION 8u111-b14-2~bpo8+1

# see https://bugs.debian.org/775775
# and https://github.com/docker-library/java/issues/19#issuecomment-70546872
ENV CA_CERTIFICATES_JAVA_VERSION 20140324

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		openjdk-8-jdk="$JAVA_DEBIAN_VERSION" \
		ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
	&& rm -rf /var/lib/apt/lists/* \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

# see CA_CERTIFICATES_JAVA_VERSION notes above
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

# Compile cURL for ARMv7
cd /tmp
wget http://curl.haxx.se/download/curl-7.37.1.tar.gz -O curl.tar.gz
tar xzf curl.tar.gz
cd curl-7.37.1/

export CROSS_COMPILER=arm-linux-gnueabihf
export AR=${CROSS_COMPILER}-ar
export AS=${CROSS_COMPILER}-as
export LD=${CROSS_COMPILER}-ld
export RANLIB=${CROSS_COMPILER}-ranlib
export CC=${CROSS_COMPILER}-gcc
export CPP=${CROSS_COMPILER}-cpp-4.9
export NM=${CROSS_COMPILER}-nm
export ROOTDIR="${PWD}"

mkdir -p ${ROOTDIR}/build/prefix
mkdir -p ${ROOTDIR}/build/exec-prefix

./configure \
    --target=arm-linux \
    --host=arm-linux \
    --build=i586-pc-linux-gnu \
	--prefix=${ROOTDIR}/build/prefix \
    --exec-prefix=${ROOTDIR}/build/exec-prefix

make && make install
cp -avr build/prefix/include/curl/ /usr/include/arm-linux-gnueabihf/
cp -a build/exec-prefix/lib/. /usr/lib/gcc/arm-linux-gnueabihf/4.9/