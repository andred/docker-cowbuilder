#!/bin/sh -xe

name=jenkins-debian-glue-base-builder

my_cleanup() {
    if running=$(docker inspect --format "{{.State.Running}}" ${name} 2> /dev/null) ; then
        if [ "${running}" = "true" ] ; then
            docker kill ${name}
        fi
    fi
    if running=$(docker inspect --format "{{.State.Running}}" ${name} 2> /dev/null) \
            && [ "${running}" = "false" ] ; then
        docker rm -v ${name}
    fi
}
trap "my_cleanup" EXIT
for sig in INT TERM ; do
    trap "my_cleanup ; trap - EXIT ; trap - ${sig} ; kill -s ${sig} $$" ${sig}
done

my_cleanup

# docker 1.8:
#   --cap-add SYS_ADMIN works by itself
# docker 1.10.3 1.11.2:
#   --cap-add SYS_ADMIN doesn't work
#   --cap-add SYS_CHROOT --security-opt seccomp:unconfined doesn't work
#   --privileged works
docker run \
    --name ${name} \
    -t \
    -u root \
    --privileged \
    -v /etc/localtime:/etc/localtime:ro \
    ad/jenkins-debian-glue-builder \
    \
    /bin/sh -c '
        set -xe
        cd /
        for dist in xenial trusty sid jessie ; do
            for arch in amd64 i386 ; do
                DIST=${dist} ARCH=${arch} cowbuilder --create \
                    --basepath /var/cache/pbuilder/base-${dist}-${arch}.cow \
                    --distribution ${dist} \
                    --debootstrap debootstrap \
                        --architecture ${arch} --debootstrapopts --arch \
                                               --debootstrapopts ${arch} \
                                               --debootstrapopts --variant=buildd \
                    --configfile=/etc/pbuilderrc.${dist} \
                    --hookdir /usr/share/jenkins-debian-glue/pbuilder-hookdir/
                tar -C /var/cache/pbuilder --use-compress-program pxz -cf base-${dist}-${arch}.cow.tar.xz base-${dist}-${arch}.cow
            done
        done

        for dist in jessie ; do
            for arch in armhf ; do
                DIST=${dist} ARCH=${arch} cowbuilder --create \
                    --basepath /var/cache/pbuilder/base-${dist}-${arch}.cow \
                    --distribution ${dist} \
                    --debootstrap qemu-debootstrap \
                        --architecture ${arch} --debootstrapopts --arch \
                                               --debootstrapopts ${arch} \
                                               --debootstrapopts --variant=buildd \
                    --configfile=/etc/pbuilderrc.${dist}.raspbian \
                    --hookdir /usr/share/jenkins-debian-glue/pbuilder-hookdir/
                tar -C /var/cache/pbuilder --use-compress-program pxz -cf base-${dist}-${arch}.cow.tar.xz base-${dist}-${arch}.cow
            done
        done'

for dist in xenial trusty sid jessie ; do
    for arch in amd64 i386 ; do
        docker cp ${name}:/base-${dist}-${arch}.cow.tar.xz ../jenkins-debian-glue/
    done
done
docker cp ${name}:/base-jessie-armhf.cow.tar.xz ../jenkins-debian-glue/
