FROM ubuntu:jammy

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Create a user
RUN adduser --disabled-password --gecos "" devnull

# Set the default user
USER devnull

# Set the working directory
WORKDIR /home/devnull

# Default command to start a bash shell for the user
CMD ["/bin/bash"]
