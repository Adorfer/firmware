# Bauumgebung fuer Gluon 2023.2 / OpenWrt 23.05.
#
# Warum ueberhaupt: 23.05 ist gegen GCC 12/13 entstanden. Auf einem heutigen
# Host - Ubuntu 26.04 bringt GCC 15 - bricht der Bau in den Host-Werkzeugen ab,
# weil seit GCC 14 mehrere Warnungen Fehler sind. Betroffen sind
# squashfs3-lzma, elfutils und das Host-Perl 5.28.1; letzteres war auch mit
# -Wno-incompatible-pointer-types und -fno-builtin nicht dazu zu bewegen
# (sdbm.c deklariert malloc und free noch in K&R-Form).
#
# Bookworm bringt GCC 12 mit und damit genau die Ära, fuer die 23.05 gedacht
# ist.
#
# Abgeleitet von gluon/contrib/docker/Dockerfile, mit einer Auslassung: der
# editorconfig-checker wird dort von einer GitHub-Release-URL geholt, die es
# nicht mehr gibt (404). Er gehoert zu Gluons eigenem Lint und wird zum Bauen
# nicht gebraucht.
#
# Bauen und benutzen: siehe contrib/docker/bauen.sh daneben.

FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    file \
    git \
    python3 \
    python3-distutils \
    build-essential \
    gawk \
    unzip \
    libncurses5-dev \
    zlib1g-dev \
    libssl-dev \
    libelf-dev \
    wget \
    rsync \
    time \
    qemu-utils \
    ecdsautils \
    lua5.1 \
    lua-check \
    shellcheck \
    libnss-unknown \
    openssh-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
