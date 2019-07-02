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
    && pip install pyyaml

# COPY FROM BASELAYER
COPY --from=baselayer /usr/local/lib/s2/include /usr/local/include
COPY --from=baselayer /usr/local/lib/s2/lib /usr/local/lib

# CMAKE>=3.5, through apt-get just get version=2.8. Note version 3.6 fails
#RUN cd /tmp \
#    && wget https://cmake.org/files/v3.7/cmake-3.7.2.tar.gz \
#    && tar -xzvf cmake-3.7.2.tar.gz \
#    && cd cmake-3.7.2/ \
#    && ./bootstrap \
#    && make \
#    && make install \
#    && cmake --version

# MONGODB directory for database
RUN mkdir /data
RUN mkdir /data/db
RUN mkdir /data/configdb
# VOLUME /data/db /data/configdb

# MONGODB
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
    --recv 9DA31620334BD75D9DCB49F368818C72E52529D4 \
    && echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu/ bionic/mongodb-org/4.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-4.0.list
RUN apt-get update -y \
    && apt-get install -y \
        mongodb-org \
    && python -m pip install pymongo

# LOCAL USER
ENV USER des
ENV HOME /home/des

# SUDO for running MONGDB
RUN useradd --create-home --shell /bin/bash ${USER} --uid 1001 \
    && echo "des:des" | chpasswd \
    && adduser ${USER} sudo
# ADD mongod.conf /etc/init/mongod.conf

WORKDIR ${HOME}
RUN mkdir ${HOME}/s2des
RUN mkdir ${HOME}/s2des/external
RUN chown -R ${USER}:${USER} ${HOME}
USER ${USER}
ENV SHELL /bin/bash
ENV TERM xterm

CMD ["sleep", "3600"]
