FROM ubuntu:22.04

RUN apt -y update && \
    apt -y install build-essential wget pkg-config

RUN wget -P /tmp "https://dl.google.com/go/go1.23.2.linux-amd64.tar.gz"
RUN tar -C /usr/local -xzf "/tmp/go1.23.2.linux-amd64.tar.gz"
RUN rm "/tmp/go1.23.2.linux-amd64.tar.gz"

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.61.0

WORKDIR /ffmpeg
RUN wget -P /tmp https://ffmpeg.org/releases/ffmpeg-7.0.tar.xz
RUN tar xf /tmp/ffmpeg-7.0.tar.xz
RUN rm /tmp/ffmpeg-7.0.tar.xz
WORKDIR /ffmpeg/build
RUN ../ffmpeg-7.0/configure \
                    --disable-autodetect \
                    --disable-all \
                    --disable-asm \
                    --disable-debug \
                    --disable-network \
                    --disable-runtime-cpudetect \
                    --disable-stripping \
                    --disable-optimizations \
                    --disable-version-tracking \
                    --prefix=/usr/local \
                    --enable-avcodec \
                    --enable-avdevice \
                    --enable-avfilter \
                    --enable-avformat \
                    --enable-swscale
RUN make -j8 install

ADD . /build
WORKDIR /build

RUN PKG_CONFIG_PATH=/usr/local/lib/pkgconfig go build ./... && echo "BUID SUCCESS"

RUN PKG_CNFIG_PATH=/usr/local/lib/pkgconfig golangci-lint run --enable-only=typecheck ./... && echo "LINT SUCCESS"
