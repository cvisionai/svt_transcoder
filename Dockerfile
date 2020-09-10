FROM ubuntu:20.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
            ca-certificates \
            build-essential \
            git cmake nasm mercurial \
            pkg-config && \
    rm -fr /var/lib/apt/lists/*

WORKDIR /work
RUN git clone https://github.com/OpenVisualCloud/SVT-HEVC
RUN git clone https://github.com/OpenVisualCloud/SVT-AV1
RUN git clone --depth=1 https://github.com/FFmpeg/FFmpeg ffmpeg

WORKDIR /work/SVT-HEVC/Build/linux
RUN ./build.sh --prefix /opt/cvision release
WORKDIR /work/SVT-HEVC/Build/linux/Release
RUN make install

WORKDIR /work/SVT-AV1/Build
RUN cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/cvision
RUN make -j8 && make install

WORKDIR /work
RUN git clone https://code.videolan.org/videolan/x264.git
WORKDIR /work/x264
RUN ./configure --prefix=/opt/cvision --enable-shared
RUN make -j8 && make install

WORKDIR /work
RUN hg clone http://hg.videolan.org/x265
WORKDIR /work/x265/linux_build
RUN cmake ../source -DCMAKE_INSTALL_PREFIX=/opt/cvision
RUN make -j8 && make install

COPY files/cvision.conf /etc/ld.so.conf.d
RUN ldconfig

WORKDIR /work/ffmpeg
RUN git config --global user.name DOCKER_BUILD && git config --global user.email info@cvisionai.com
RUN git am ../SVT-HEVC/ffmpeg_plugin/0001-lavc-svt_hevc-add-libsvt-hevc-encoder-wrapper.patch
ENV PKG_CONFIG_PATH=/opt/cvision/lib/pkgconfig
RUN ./configure --prefix=/opt/cvision --enable-libsvthevc --enable-libsvtav1 --enable-gpl --enable-libx264 --enable-libx265
RUN make -j8 && make install


FROM ubuntu:20.04 as encoder
COPY --from=builder /opt/cvision /opt/cvision
COPY files/cvision.conf /etc/ld.so.conf.d
COPY files/test.sh /test.sh
RUN chmod +x /test.sh
ENV PATH="/opt/cvision/bin:${PATH}"
RUN ldconfig


