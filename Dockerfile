# FROM ubuntu:devel
#
# RUN apt-get update && \
#     apt-get install -y \
#       git cmake pkg-config build-essential unzip && \
#     rm -rf /var/lib/apt/lists/*
#
# RUN git clone https://github.com/neovim/neovim /tmp/neovim
#
# WORKDIR /tmp/neovim
#
# ENV CMAKE_BUILD_TYPE=Release
# ENV CMAKE_INSTALL_PREFIX=/opt/nvim
#
# RUN make
# RUN make install


FROM ubuntu:20.04 AS base
MAINTAINER lambdalisue <lambdalisue@hashnote.net>

ARG NEOVIM_PREFIX=/opt/neovim
ARG NEOVIM_VERSION=nightly

ENV NEOVIM_PREFIX=$NEOVIM_PREFIX

ENV PATH=${NEOVIM_PREFIX}/bin:$PATH

FROM base AS neovim

ENV TZ=Europe/Berlin

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
 && apt-get install -y \
    curl \
    ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip


RUN echo "${NEOVIM_VERSION}" \
 && curl -SL https://github.com/neovim/neovim/archive/${NEOVIM_VERSION}.tar.gz | tar -xz

RUN cd $(find . -name 'neovim-*' -type d | head -1) \
 && make \
    CMAKE_BUILD_TYPE=RelWithDebInfo \
    CMAKE_EXTRA_FLAGS="-DENABLE_JEMALLOC=OFF -DCMAKE_INSTALL_PREFIX=${NEOVIM_PREFIX}" \
 && make install

RUN curl -L https://github.com/nvim-lua/plenary.nvim/tarball/master | tar xz

ENV PACK="/root/.local/share/nvim/site/pack"
RUN mkdir -p $PACK/plenary/start \
  && mv $(find . -name 'nvim-lua-plenary.nvim-*' -type d | head -1) $PACK/plenary/start/nvim-lua-plenary.nvim

FROM base

RUN apt-get update && \
    apt-get install -y \
      git && \
    rm -rf /var/lib/apt/lists/*

COPY --from=neovim ${NEOVIM_PREFIX} ${NEOVIM_PREFIX}
COPY --from=neovim ${PACK} ${PACK}

ENV PLENARY="/root/.local/share/nvim/site/pack/plenary/start/nvim-lua-plenary.nvim"

# ENTRYPOINT "${NEOVIM_PREFIX}/bin/nvim"
# CMD ["${NEOVIM_PREFIX}/bin/nvim", "--headless", "--noplugin", "-u", "${PLENARY}/scripts/minimal.vim", "-c" "PlenaryBustedDirectory tests {minimal_init = '${PLENARY}/tests/minimal_init.vim'}"]

WORKDIR /run
CMD ${NEOVIM_PREFIX}/bin/nvim --headless --noplugin -u ${PLENARY}/scripts/minimal.vim -c "PlenaryBustedDirectory . {minimal_init = '${PLENARY}/tests/minimal_init.vim'}"


