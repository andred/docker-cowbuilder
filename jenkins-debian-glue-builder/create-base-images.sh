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

        HOST_ARCH="$(dpkg-architecture -qDEB_HOST_ARCH)"

        for distribution in sid ; do
            for architecture in amd64 armel ; do
                debootstrap=qemu-debootstrap
                if [ "${architecture}" = "${HOST_ARCH}" ] || [ "${architecture}" = "all" ] ; then
                    debootstrap=debootstrap
                elif [ "${HOST_ARCH}" = "amd64" ] && [ "${architecture}" = "i386" ] ; then
                    debootstrap=debootstrap
                fi
                DIST=${distribution} ARCH=${architecture} cowbuilder --create \
                    --basepath /var/cache/pbuilder/base-${distribution}-${architecture}.cow \
                    --distribution ${distribution} --architecture ${architecture} \
                    --debootstrap ${debootstrap} \
                        --debootstrapopts --arch \
                        --debootstrapopts ${architecture} \
                        --debootstrapopts --variant=buildd \
                    --hookdir /usr/share/jenkins-debian-glue/pbuilder-hookdir
                tar -C /var/cache/pbuilder --use-compress-program "xz -T0" -cf base-${distribution}-${architecture}.cow.tar.xz base-${distribution}-${architecture}.cow
            done
        done'

for distribution in sid ; do
    for architecture in amd64 armel ; do
        docker cp ${name}:/base-${distribution}-${architecture}.cow.tar.xz ../jenkins-debian-glue/
    done
done
