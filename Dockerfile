FROM alpine:3.6

RUN apk --no-cache add \
      build-base \
      cmake \
      clang-dev \
      git \
      python3-dev \
      ninja

WORKDIR /ycmd
ARG YCMD_REVISION
RUN git clone https://github.com/Valloric/ycmd.git /ycmd \
    && git checkout "${YCMD_REVISION}" \
    && git submodule update --init --recursive

RUN python3 build.py \
      --clang-completer \
      --system-libclang

ENTRYPOINT ["/usr/bin/python3", "/ycmd/ycmd"]
