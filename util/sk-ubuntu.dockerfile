FROM ubuntu:jammy

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    git \
    make \
    openssh-client \
    sudo \
    vim

# Add GitHub to known hosts
RUN mkdir -p /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

RUN curl -LO https://go.dev/dl/go1.24.1.linux-arm64.tar.gz && \
    tar -C /usr/local -xzf go1.24.1.linux-arm64.tar.gz && \
    rm go1.24.1.linux-arm64.tar.gz

RUN echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a /etc/profile

ENV PATH="/usr/local/go/bin:${PATH}"

ARG install_super

# Maybe install as devnull user and then copy to XDG bin directory?
RUN <<EOF
  git clone https://github.com/brimdata/super.git
    cd super
    make clean build install
    cp ./dist/super /usr/local/bin
EOF

# Create a user
RUN adduser --disabled-password --gecos "" devnull && \
    usermod -aG sudo devnull && \
    echo "devnull ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devnull && \
    chmod 0440 /etc/sudoers.d/devnull

# Set the default user
USER devnull

# Set the working directory
WORKDIR /home/devnull

RUN mkdir -p ~/.local/bin/

RUN echo 'export PATH=$PATH:/usr/local/go/bin' | tee -a ~/.bashrc
RUN echo 'export PATH="${XDG_BIN_HOME:-$HOME/.local/bin}:$PATH"' | tee -a ~/.bashrc

ARG install_bat

RUN <<EOF
  sudo apt install -y bat
  mkdir -p ~/.local/bin
  ln -s /usr/bin/batcat ~/.local/bin/bat
EOF

ARG install_glow

RUN <<EOF
  git clone https://github.com/charmbracelet/glow.git
  cd glow
  go build
  cp ./glow ~/.local/bin/
EOF

ARG install_fzf

RUN <<EOF
  # with ubuntu jammy, installs a pre-multi-line version. we want both to test
  sudo apt install -y fzf
EOF

RUN <<EOF
# To update the tagName, use this command locally:
# gh release list --repo junegunn/fzf --json isLatest,name,tagName,isPrerelease |
#   super -z -c "over this
#                | where isPrerelease == false
#                | sort name
#                | tail 1" -
curl -OL https://github.com/junegunn/fzf/releases/download/v0.60.3/fzf-0.60.3-linux_arm64.tar.gz &&
  tar xzvf fzf-0.60.3-linux_arm64.tar.gz &&
  mv fzf fzf-new &&
  cp $(which fzf) ./fzf-old &&
  rm fzf-0.60.3-linux_arm64.tar.gz
EOF

ARG install_zq

RUN <<EOF
export ZED_VERSION=v1.18.0 &&
  export ZED_ARCH=$(sudo dpkg --print-architecture) &&
  echo https://github.com/brimdata/zed/releases/download/$ZED_VERSION/zed-$ZED_VERSION.linux-$ZED_ARCH.tar.gz
  curl -OL https://github.com/brimdata/zed/releases/download/$ZED_VERSION/zed-$ZED_VERSION.linux-$ZED_ARCH.tar.gz &&
  tar xzvf zed-$ZED_VERSION.linux-$ZED_ARCH.tar.gz &&
  sudo mv -v zed /usr/bin/ &&
  sudo mv -v zq /usr/bin/ &&
  rm zed-$ZED_VERSION.linux-$ZED_ARCH.tar.gz
EOF

COPY install-sk.sh /home/devnull/
COPY enabler.sh /home/devnull/
COPY combo-tests.sh /home/devnull/

RUN sudo chown devnull:devnull /home/devnull/*.sh && \
    sudo chmod +x /home/devnull/*.sh

# this doesn't appear to be working currently:
# RUN go install github.com/brimdata/super/cmd/super@main

# Default command to start a bash shell for the user
CMD ["/bin/bash"]
