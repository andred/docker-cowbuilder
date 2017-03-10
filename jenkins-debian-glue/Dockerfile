FROM ad/jenkins-debian-glue-builder:latest
MAINTAINER André Draszik "git@andred.net"

# add prebuilt cowbuilder/pbuilder chroots
ADD base-xenial-amd64.cow.tar.xz /var/cache/pbuilder/
ADD base-xenial-i386.cow.tar.xz /var/cache/pbuilder/
ADD base-trusty-amd64.cow.tar.xz /var/cache/pbuilder/
ADD base-trusty-i386.cow.tar.xz /var/cache/pbuilder/

ADD base-sid-amd64.cow.tar.xz /var/cache/pbuilder/
ADD base-sid-i386.cow.tar.xz /var/cache/pbuilder/
ADD base-stretch-amd64.cow.tar.xz /var/cache/pbuilder/
ADD base-stretch-i386.cow.tar.xz /var/cache/pbuilder/
ADD base-jessie-amd64.cow.tar.xz /var/cache/pbuilder/
ADD base-jessie-i386.cow.tar.xz /var/cache/pbuilder/
ADD base-jessie-armhf.cow.tar.xz /var/cache/pbuilder/

#USER user
