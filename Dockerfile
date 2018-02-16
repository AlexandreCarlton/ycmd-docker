FROM ubuntu:17.10

RUN apt-get update && \
    apt-get install -y \
      cargo \
      cmake \
      default-jdk-headless \
      git \
      golang \
      libclang-dev \
      mono-complete \
      ninja-build \
      node-typescript \
      npm \
      python3-dev

WORKDIR /ycmd
ARG YCMD_REVISION
RUN git clone https://github.com/Valloric/ycmd.git /ycmd \
    && git checkout "${YCMD_REVISION}" \
    && git submodule update --init --recursive

RUN python3 build.py \
      --clang-completer \
      --cs-completer \
      --go-completer \
      --java-completer \
      --js-completer \
      --rust-completer \
      --system-libclang

ENTRYPOINT ["/usr/bin/python3", "/ycmd/ycmd"]
