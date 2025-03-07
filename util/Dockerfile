FROM ubuntu:jammy AS base

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    make \
    openssh-client \
    sudo

# Add GitHub to known hosts
RUN mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

RUN curl -LO https://go.dev/dl/go1.24.1.linux-arm64.tar.gz && \
    tar -C /usr/local -xzf go1.24.1.linux-arm64.tar.gz && \
    rm go1.24.1.linux-arm64.tar.gz

RUN echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a /etc/profile

ENV PATH="/usr/local/go/bin:${PATH}"

# Create a user
RUN adduser --disabled-password --gecos "" devnull && \
    usermod -aG sudo devnull

# Set the default user
USER devnull

# Set the working directory
WORKDIR /home/devnull

RUN echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a ~/.bashrc
RUN echo 'export PATH="${XDG_BIN_HOME:-$HOME/.local/bin}:$PATH"' | tee -a ~/.bashrc

FROM base AS super

# this doesn't appear to be working currently:
# RUN go install github.com/brimdata/super/cmd/super@main

# Maybe install as devnull user and then copy to XDG bin directory?
RUN git clone https://github.com/brimdata/super.git && \
      cd super && \
      make clean build install && \
      sudo cp ./dist/super /usr/bin/

FROM base AS zq

RUN sudo bash -c 'export ZED_VERSION=v1.18.0 &&\
  echo https://github.com/brimdata/zed/releases/download/$ZED_VERSION/zed-$ZED_VERSION.linux-arm64.tar.gz\
  curl -OL https://github.com/brimdata/zed/releases/download/$ZED_VERSION/zed-$ZED_VERSION.linux-arm64.tar.gz &&\
  tar xzvf zed-$ZED_VERSION.linux-arm64.tar.gz &&\
  mv -v zed /usr/bin/ &&\
  mv -v zq /usr/bin/ &&\
  rm zed-$ZED_VERSION.linux-arm64.tar.gz'

FROM base AS fzf

RUN sudo apt-get update && sudo apt-get install -y fzf

FROM base AS glow

RUN sudo mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
RUN sudo apt update && sudo apt install -y glow

FROM base AS bat

RUN sudo apt-get update && sudo apt-get install -y bat

FROM base AS final

ARG BRIM_TOOL
ARG READER_PROG

COPY --from=${BRIM_TOOL} /usr/bin /usr/bin
COPY --from=${READER_PROG} /usr/bin /usr/bin

# Default command to start a bash shell for the user
CMD ["/bin/bash"]
