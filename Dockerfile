FROM ubuntu:24.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
            ca-certificates \
            build-essential \
            git cmake nasm mercurial \
            pkg-config openssl libssl-dev \
            libx265-dev libx264-dev libpng-dev libfreetype6-dev libdav1d-dev wget unzip &&\
    rm -fr /var/lib/apt/lists/*

WORKDIR /work

# Get architecture for conditional compilation
ARG TARGETARCH

# Clone repositories
RUN git clone --depth 1 --branch v3.1.2 https://gitlab.com/AOMediaCodec/SVT-AV1
RUN git clone --depth 1 --branch n8.0 https://github.com/FFmpeg/FFmpeg ffmpeg

WORKDIR /work/SVT-AV1/Build
# Disable interprocedural optimization (LTO) to avoid GCC 13 jobserver / LTO ICEs on some platforms.
# Allow configurable parallelism.
ARG MAKE_JOBS=8
ENV MAKE_JOBS=${MAKE_JOBS}
RUN cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/cvision -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF
RUN make -j"${MAKE_JOBS}" && make install

#WORKDIR /work/SVT-VP9/Build
#RUN cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/cvision
#RUN make -j8 && make install

#WORKDIR /work
#RUN git clone https://code.videolan.org/videolan/x264.git
#WORKDIR /work/x264
#RUN ./configure --prefix=/opt/cvision --enable-shared
#RUN make -j8 && make install

#WORKDIR /work
#RUN hg clone http://hg.videolan.org/x265
#WORKDIR /work/x265/linux_build
#RUN cmake ../source -DCMAKE_INSTALL_PREFIX=/opt/cvision
#RUN make -j8 && make install

COPY files/cvision.conf /etc/ld.so.conf.d
RUN ldconfig

WORKDIR /work/ffmpeg

# Setup a temporary username for git am to run
RUN git config --global user.name DOCKER_BUILD && git config --global user.email info@cvisionai.com

# SVT-VP9 support (commented out)
#RUN git am ../SVT-VP9/ffmpeg_plugin/master-0001-Add-ability-for-ffmpeg-to-run-svt-vp9.patch

ENV PKG_CONFIG_PATH=/opt/cvision/lib/pkgconfig
RUN ./configure --prefix=/opt/cvision --enable-libdav1d --enable-libsvtav1 --enable-libfreetype --enable-libx264 --enable-libx265 --enable-openssl --enable-nonfree --enable-gpl
RUN make -j"${MAKE_JOBS}" && make install

# Remove static
RUN rm -f /opt/cvision/lib/*.a

# Install Bento4 based on architecture
WORKDIR /bento4
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        wget http://zebulon.bok.net/Bento4/binaries/Bento4-SDK-1-6-0-632.x86_64-unknown-linux.zip && \
        unzip Bento4-SDK-1-6-0-632.x86_64-unknown-linux.zip && \
        cp Bento4-SDK-1-6-0-632.x86_64-unknown-linux/bin/mp4dump /opt/cvision/bin && \
        cp Bento4-SDK-1-6-0-632.x86_64-unknown-linux/bin/mp4info /opt/cvision/bin; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        wget https://github.com/AmanoTeam/Bento4-Builds/releases/download/0.1/aarch64-unknown-linux-gnu.tar.xz && \
        tar -xf aarch64-unknown-linux-gnu.tar.xz && \
        cp aarch64-unknown-linux-gnu/bin/mp4dump /opt/cvision/bin && \
        cp aarch64-unknown-linux-gnu/bin/mp4info /opt/cvision/bin; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi

FROM ubuntu:24.04 AS encoder
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
            ca-certificates libx265-199 libx264-164 libpng16-16 libfreetype6 libssl3 xz-utils libdav1d7 && \
    rm -fr /var/lib/apt/lists/*
COPY --from=builder /opt/cvision /opt/cvision
COPY files/cvision.conf /etc/ld.so.conf.d
COPY files/test.sh /test.sh
RUN chmod +x /test.sh


ENV PATH="/opt/cvision/bin:${PATH}"
RUN ldconfig /


