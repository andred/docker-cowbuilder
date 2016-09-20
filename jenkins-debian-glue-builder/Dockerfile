FROM debian:sid
MAINTAINER André Draszik "git@andred.net"

ENV HOME /home/user
RUN set -x && \
    useradd --create-home --home-dir $HOME user && \
    chown -R user:user ${HOME}

# we don't need an apt cache in a container
RUN set -x && \
    echo "Acquire::http {No-Cache=True;};" >> /etc/apt/apt.conf.d/docker-no-cache

# make the "en_US.UTF-8" locale so we'll be utf-8 enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# We need a pbuilder workaround for Ubuntu problem, as cowdancer is available
# only in universe :(
#   https://bugs.launchpad.net/ubuntu/+source/cowdancer/+bug/237591
#   https://bugs.launchpad.net/ubuntu/+source/cowdancer/+bug/747053
COPY pbuilderrc /etc/pbuilderrc

# add needed packages
RUN set -x && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        jenkins-debian-glue \
        git dpkg-dev git-buildpackage libdistro-info-perl gcc \
      && \
    apt-get install -y cowbuilder \
                       curl ca-certificates \
                       pristine-tar quilt \
                       qemu-user-static && \
    apt-get install -y pxz && \
    \
    wget -P /usr/share/keyrings http://archive.ubuntu.com/ubuntu/project/ubuntu-archive-keyring.gpg && \
    wd=$(mktemp -d --tmpdir) && \
    cd ${wd} && \
    curl -O -fSL https://archive.raspbian.org/raspbian/pool/main/r/raspbian-archive-keyring/raspbian-archive-keyring_20120528.2_all.deb && \
    dpkg -x raspbian-archive-keyring_20120528.2_all.deb . && \
    mv usr/share/keyrings/raspbian-archive-keyring.gpg /usr/share/keyrings/ && \
    cd - && \
    rm -rf ${wd} && \
    \
    echo 'user ALL=NOPASSWD: /usr/sbin/cowbuilder, /usr/sbin/chroot' > /etc/sudoers.d/user && \
    echo 'Defaults env_keep+="DEB_* DIST ARCH ADT"' >> /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user && \
    \
    rm -rf /var/lib/apt/lists/*

COPY jdg.patch /root
RUN set -x && \
    cd /usr/bin && patch -p2 < /root/jdg.patch

#    apt-get install -y jenkins-debian-glue jenkins-debian-glue-buildenv
#    echo 'MIRRORSITE=http://archive.ubuntu.com/ubuntu' > /etc/pbuilderrc.ubuntu.trusty && \
#    echo 'COMPONENTS="main universe"' >> /etc/pbuilderrc.ubuntu.trusty && \
#    echo 'OTHERMIRROR="deb http://ppa.launchpad.net/george-edison55/cmake-3.x/ubuntu trusty main|deb http://ppa.launchpad.net/mosquitto-dev/mosquitto-ppa/ubuntu trusty main"' >> /etc/pbuilderrc.ubuntu.trusty && \
#    \
#    echo 'MIRRORSITE=http://archive.ubuntu.com/ubuntu' > /etc/pbuilderrc.ubuntu.xenial && \
#    echo 'COMPONENTS="main universe"' >> /etc/pbuilderrc.ubuntu.xenial && 
