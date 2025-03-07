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
  sudo apt install -y fzf
EOF

ARG install_zq

COPY install-sk.sh /home/devnull/

# TODO: simpler to just install everything then gimme options to kill some for
# now until I can figure out conditional docker-ing better. Currently running up
# against caching weirdness.

RUN cat > remove-glow.sh <<EOF
  rm ~/.local/bin/glow
EOF

RUN cat > remove-bat.sh <<EOF
  rm ~/.local/bin/bat
EOF

RUN cat > remove-fzf.sh <<EOF
  sudo rm $(which fzf)
EOF

RUN sudo chown devnull:devnull /home/devnull/*.sh && \
    sudo chmod +x /home/devnull/*.sh

# this doesn't appear to be working currently:
# RUN go install github.com/brimdata/super/cmd/super@main

# Default command to start a bash shell for the user
CMD ["/bin/bash"]
