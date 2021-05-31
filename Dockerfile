ARG DOCKER_IMAGE=alpine:latest 
FROM $DOCKER_IMAGE AS toolchain

LABEL author="Bensuperpc <bensuperpc@gmail.com>"
LABEL mantainer="Bensuperpc <bensuperpc@gmail.com>"
# Based on https://github.com/root670/docker-psxsdk and https://github.com/JaCzekanski/psn00bsdk-docker

ARG PSN00BSDK_COMMIT=da79082d2c5e0dcbc899a359f6f49ec8cca90d66
ARG THREADS=12
ARG BINUTILS_VERSION=2.36
ARG GCC_VERSION=11.1.0

ENV PATH $PATH:/opt/psn00bsdk/tools/bin

WORKDIR /build

# Install build dependencies
RUN apk update && apk upgrade && apk add --no-cache \
  bash \
  git \
  cdrkit \
  gcc \
  g++ \
  gmp-dev \
  make \
  mpc1-dev \
  mpfr-dev \
  musl-dev \
  patch \
  wget \
  zlib-dev \
  tinyxml2-dev

# Compile binutils
RUN wget -q http://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VERSION}.tar.xz && \
  tar -xf binutils-${BINUTILS_VERSION}.tar.xz && \
  rm binutils-${BINUTILS_VERSION}.tar.xz && \
  cd binutils-${BINUTILS_VERSION} && \
  mkdir build && \
  cd build && \
  ../configure --prefix=/usr/local/mipsel-unknown-elf --target=mipsel-unknown-elf --with-float=soft --disable-nls && \
  make -j ${THREADS} && \
  make install && \
  cd ../.. && \
  rm -rf binutils-${BINUTILS_VERSION}

# Compile GCC
RUN wget -q http://ftpmirror.gnu.org/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz && \
  tar -xf gcc-${GCC_VERSION}.tar.xz && \
  rm gcc-${GCC_VERSION}.tar.xz && \
  cd gcc-${GCC_VERSION} && \
  mkdir build && \
  cd build && \
  ../configure --prefix=/usr/local/mipsel-unknown-elf --disable-nls --disable-libada --disable-libssp --disable-libquadmath --disable-libstdc++-v3 --target=mipsel-unknown-elf --with-float=soft --enable-languages=c,c++ --with-gnu-as --with-gnu-ld && \
  make -j ${THREADS} && \
  make install-strip && \
  cd ../.. && \
  rm -rf gcc-${GCC_VERSION}

# Modify link script
RUN echo "__CTOR_LIST__ = .; \
___CTOR_LIST__ = .; \
LONG (((__CTOR_END__ - __CTOR_LIST__) / 4) - 2) \
KEEP (*(SORT (.ctors.*))) \
KEEP (*(.ctors)) \
LONG (0x00000000) \
__CTOR_END__ = .; \
. = ALIGN (0x10); \
\
__DTOR_LIST__ = .; \
___DTOR_LIST__ = .; \
LONG (((__DTOR_END__ - __DTOR_LIST__) / 4) - 2) \
KEEP (*(SORT (.dtors.*))) \
KEEP (*(.dtors)) \
LONG (0x00000000) \
__DTOR_END__ = .; \
. = ALIGN (0x10);"  >> patch && \
sed -i -- '/_ftext = \./ r patch' /usr/local/mipsel-unknown-elf/mipsel-unknown-elf/lib/ldscripts/elf32elmip.x && \
rm patch

ENV PATH $PATH:/usr/local/mipsel-unknown-elf/bin

# Compile PSn00bSDK
RUN cd /opt && \
  git clone --depth 1 https://github.com/Lameguy64/PSn00bSDK.git psn00bsdk && \
  cd psn00bsdk && \
#  git reset --hard ${PSN00BSDK_COMMIT} && \
  cd libpsn00b && \
  make -j ${THREADS} && \
  make install && \
  cd ../tools && \
  make -j ${THREADS} && \
  make install

ARG DOCKER_IMAGE=alpine:latest 
FROM $DOCKER_IMAGE AS runtime

ARG VERSION="1.0.0"
ENV VERSION=$VERSION

ENV PATH $PATH:/opt/psn00bsdk/tools/bin:/usr/local/mipsel-unknown-elf/bin
ENV PSN00BSDK /opt/psn00bsdk/
WORKDIR /build
RUN apk add --no-cache make tinyxml2 musl mpc1-dev mpfr-dev
COPY --from=toolchain /usr/local/mipsel-unknown-elf /usr/local/mipsel-unknown-elf
COPY --from=toolchain /opt/psn00bsdk /opt/psn00bsdk
ADD sdk-common.mk /opt/psn00bsdk/sdk-common.mk

ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.schema-version="1.0" \
	  org.label-schema.build-date=$BUILD_DATE \
	  org.label-schema.name="bensuperpc/psn00bsdk" \
	  org.label-schema.description="psn00bsdk in docker" \
	  org.label-schema.version=$VERSION \
	  org.label-schema.vendor="Bensuperpc" \
	  org.label-schema.url="http://bensuperpc.com/" \
	  org.label-schema.vcs-url="https://github.com/Bensuperpc/psn00bsdk-docker" \
	  org.label-schema.vcs-ref=$VCS_REF \
	  org.label-schema.docker.cmd="docker build -t bensuperpc/psn00bsdk -f Dockerfile ."
