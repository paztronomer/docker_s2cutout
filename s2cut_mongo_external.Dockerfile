# Francisco Paz-Chinchon
#
# S2DES
#

# Note: S2 installation guide recommends ubuntu 14.04 but it creates conflicts
# with cmake/openssl
FROM ubuntu:18.04 as baselayer
MAINTAINER Francisco Paz-Chinchon <francisco.paz.ch@gmail.com>

# ENVS
ENV HOME /root
ENV SHELL /bin/bash
ENV TERM xterm
ENV DEBIAN_FRONTEND noninteractive

# BASICS. Include building packages tools
RUN apt-get update -y && \
    apt-get install -y \
       git curl wget unzip gfortran pkg-config zlibc tmux binutils \
       libgflags-dev libgoogle-glog-dev libgtest-dev libssl-dev \
       swig g++ gcc cmake && \
    apt-get clean && apt-get purge && rm -rf  /var/lib/apt/lists/* /tmp/* /var/tmp/*

# CONDA
RUN curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp /usr/local \
    && rm -rf /tmp/miniconda.sh \
    && conda install -y python=3 \
    && conda update conda \
    && conda clean --all --yes

# S2 GOOGLE
RUN git clone https://github.com/google/s2geometry.git /tmp/s2geometry
RUN mkdir -p /tmp/s2geometry/build \
    && cd /tmp/s2geometry/build \
    && cmake -DWITH_GFLAGS=ON -WITH_GTEST=ON -DGTEST_ROOT=/usr/src/gtest/ \
    -DOPENSSL_INCLUDE_DIR=/usr/local/ssl/ \
    -DCMAKE_INSTALL_PREFIX:PATH=/usr/local/lib/s2 .. \
    && make \
    && make test \
    && make install \
    && make clean

CMD ["sleep", "3600"]




FROM ubuntu:18.04 as small
MAINTAINER Francisco Paz-Chinchon <francisco.paz.ch@gmail.com>

# ENVS
ENV HOME /root
ENV SHELL /bin/bash
ENV TERM xterm
ENV DEBIAN_FRONTEND noninteractive

# BASICS
RUN apt-get update -y && \
    apt-get install -y \
       git curl wget vim unzip gfortran pkg-config zlibc tmux binutils \
       zlib1g zlib1g-dev tmux libopenmpi-dev bzip2 \
       ca-certificates libhdf5-serial-dev hdf5-tools openmpi-bin \
       openmpi-common binutils \
       libgflags-dev libgoogle-glog-dev libgtest-dev libssl-dev \
       swig gcc \
       sudo apt-utils && \
    apt-get clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# CONDA
RUN curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp /usr/local \
    && rm -rf /tmp/miniconda.sh \
    && conda install -y python=3 \
    && conda update conda \
    && conda install jupyter pandas numpy matplotlib seaborn scikit-learn \
    && conda install folium -c conda-forge \
    && conda install healpy -c conda-forge \
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
    && conda clean --all --yes \
    && python -m pip install pymongo

# COPY FROM BASELAYER
COPY --from=baselayer /usr/local/lib/s2/include /usr/local/include
COPY --from=baselayer /usr/local/lib/s2/lib /usr/local/lib

#
#
# MONGODB
# Here get the mongodb to be imported from another container
# https://stackoverflow.com/questions/37450871/how-to-allow-remote-connections-from-mongo-docker-container
# https://hub.docker.com/_/mongo?tab=description
#
#

# CREATE path for MONGODB
RUN mkdir -p /data/db

# LOCAL USER
ENV USER des
ENV HOME /home/des
# RUN useradd --create-home --shell /bin/bash ${USER} --uid 1001

# SUDO for running MONGDB
RUN useradd --create-home --shell /bin/bash ${USER} --uid 1001 \
    && echo "des:des" | chpasswd \
    && adduser ${USER} sudo
WORKDIR ${HOME}
RUN mkdir ${HOME}/s2des
RUN mkdir ${HOME}/s2des/external
RUN chown -R ${USER}:${USER} ${HOME}
USER ${USER}
ENV SHELL /bin/bash
ENV TERM xterm

CMD ["sleep", "3600"]
CMD ["echo", "S2 container"]
