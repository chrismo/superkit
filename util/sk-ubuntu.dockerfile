FROM ubuntu:jammy

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    make \
    openssh-client

# Add GitHub to known hosts
RUN mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

RUN curl -LO https://go.dev/dl/go1.24.1.linux-arm64.tar.gz && \
    tar -C /usr/local -xzf go1.24.1.linux-arm64.tar.gz && \
    rm go1.24.1.linux-arm64.tar.gz

RUN echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a /etc/profile

ENV PATH="/usr/local/go/bin:${PATH}"

# Maybe install as devnull user and then copy to XDG bin directory?
RUN git clone https://github.com/brimdata/super.git && \
      cd super && \
      make clean build install && \
      cp ./dist/super /usr/local/bin

# Create a user
RUN adduser --disabled-password --gecos "" devnull

# Set the default user
USER devnull

# Set the working directory
WORKDIR /home/devnull

RUN echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a ~/.bashrc
RUN echo 'export PATH="${XDG_BIN_HOME:-$HOME/.local/bin}:$PATH"' | tee -a ~/.bashrc

# this doesn't appear to be working currently:
# RUN go install github.com/brimdata/super/cmd/super@main

# Default command to start a bash shell for the user
CMD ["/bin/bash"]
