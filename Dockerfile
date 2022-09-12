FROM ubuntu:20.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "v0.0.8-force"
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
            ca-certificates \
            build-essential \
            git cmake nasm mercurial \
            pkg-config openssl libssl-dev \
            libx265-dev libx264-dev libpng-dev libfreetype6-dev libaom-dev &&\
    rm -fr /var/lib/apt/lists/*

WORKDIR /work
RUN git clone https://github.com/OpenVisualCloud/SVT-HEVC
RUN git clone https://gitlab.com/AOMediaCodec/SVT-AV1.git
RUN git clone https://github.com/OpenVisualCloud/SVT-VP9
RUN git clone --depth=1 https://github.com/FFmpeg/FFmpeg ffmpeg

WORKDIR /work/SVT-HEVC/Build/linux
RUN ./build.sh --prefix /opt/cvision release
WORKDIR /work/SVT-HEVC/Build/linux/Release
RUN make install

WORKDIR /work/SVT-AV1/Build
RUN cmake .. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/cvision
RUN make -j8 && make install

WORKDIR /work/SVT-VP9/Build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/cvision
RUN make -j8 && make install

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

# Apply SVT patches for HEVC and AV1
RUN git am ../SVT-HEVC/ffmpeg_plugin/master-0001-lavc-svt_hevc-add-libsvt-hevc-encoder-wrapper.patch

# Add SVTVP9 support
COPY files/master-0001-Add-ability-for-ffmpeg-to-run-svt-vp9.patch /work/master-0001-Add-ability-for-ffmpeg-to-run-svt-vp9.patch
RUN patch -p1 < ../SVT-VP9/ffmpeg_plugin/master-0001-Add-ability-for-ffmpeg-to-run-svt-vp9.patch

ENV PKG_CONFIG_PATH=/opt/cvision/lib/pkgconfig
RUN ./configure --prefix=/opt/cvision --enable-libsvthevc --enable-libsvtav1 --enable-libsvtvp9 --enable-libfreetype --enable-libx264 --enable-libx265 --enable-libaom --enable-openssl --enable-nonfree --enable-gpl
RUN make -j8 && make install

# Remove static
RUN rm -f /opt/cvision/lib/*.a


FROM ubuntu:20.04 as encoder
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
            libx265-179 libx264-155 libpng16-16 libfreetype6 libaom0 libssl1.1 && \
    rm -fr /var/lib/apt/lists/*
COPY --from=builder /opt/cvision /opt/cvision
COPY files/cvision.conf /etc/ld.so.conf.d
COPY files/test.sh /test.sh
RUN chmod +x /test.sh
ENV PATH="/opt/cvision/bin:${PATH}"
RUN ldconfig /


