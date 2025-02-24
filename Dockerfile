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
RUN git clone --single-branch https://github.com/OpenVisualCloud/SVT-HEVC && \
    cd SVT-HEVC && git checkout ed80959ebb5586aa7763c91a397d44be1798587c && cd -
RUN git clone --depth 1 --branch v2.3.0 https://gitlab.com/AOMediaCodec/SVT-AV1
#RUN git clone --single-branch https://github.com/OpenVisualCloud/SVT-VP9 && \
#    cd SVT-VP9 && git checkout 15bd454 && cd -
RUN git clone --depth 1 --branch n7.1 https://github.com/FFmpeg/FFmpeg ffmpeg

WORKDIR /work/SVT-HEVC/Build/linux
RUN ./build.sh --prefix /opt/cvision release
WORKDIR /work/SVT-HEVC/Build/linux/Release
RUN make install

WORKDIR /work/SVT-AV1/Build
RUN cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/cvision
RUN make -j8 && make install

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

# Apply SVT patches for HEVC
RUN git am ../SVT-HEVC/ffmpeg_plugin/master-0001-lavc-svt_hevc-add-libsvt-hevc-encoder-wrapper.patch

# Add SVTVP9 support
#RUN git am ../SVT-VP9/ffmpeg_plugin/master-0001-Add-ability-for-ffmpeg-to-run-svt-vp9.patch

ENV PKG_CONFIG_PATH=/opt/cvision/lib/pkgconfig
RUN ./configure --prefix=/opt/cvision --enable-libdav1d --enable-libsvthevc --enable-libsvtav1 --enable-libfreetype --enable-libx264 --enable-libx265 --enable-openssl --enable-nonfree --enable-gpl
RUN make -j8 && make install

# Remove static
RUN rm -f /opt/cvision/lib/*.a


WORKDIR /bento4
RUN wget http://zebulon.bok.net/Bento4/binaries/Bento4-SDK-1-6-0-632.x86_64-unknown-linux.zip
COPY files/md5sum_checks.txt /tmp/checks.txt
RUN md5sum --check /tmp/checks.txt
RUN unzip Bento4-SDK-1-6-0-632.x86_64-unknown-linux.zip

FROM ubuntu:24.04 AS encoder
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
            ca-certificates libx265-199 libx264-164 libpng16-16 libfreetype6 libssl3 libdav1d7 && \
    rm -fr /var/lib/apt/lists/*
COPY --from=builder /opt/cvision /opt/cvision
COPY files/cvision.conf /etc/ld.so.conf.d
COPY files/test.sh /test.sh
RUN chmod +x /test.sh

# Install Bento4
COPY --from=builder /bento4/Bento4-SDK-1-6-0-632.x86_64-unknown-linux/bin/mp4dump /opt/cvision/bin
COPY --from=builder /bento4/Bento4-SDK-1-6-0-632.x86_64-unknown-linux/bin/mp4info /opt/cvision/bin

ENV PATH="/opt/cvision/bin:${PATH}"
RUN ldconfig /


