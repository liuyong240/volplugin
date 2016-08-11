#!/bin/bash

set -e

# cleanup the older container
docker rm -f "$1" &>/dev/null || :

## test for shared mount capability
if ! grep "MountFlags" /lib/systemd/system/docker.service | grep shared &>/dev/null
then
  echo 1>&2 "Docker cannot run volplugin in its current state."
  echo 1>&2 "You must change docker's systemd MountFlags to equal 'shared'"
  echo 1>&2 'Then: `systemctl daemon-reload` and `systemctl restart docker`'
  echo 1>&2 "Otherwise volplugin will not be able to run effectively."
  exit 1
fi

set -x

case "$1" in
"apiserver" )
    docker run --net host --name apiserver \
        --privileged -i -d \
        -v /dev:/dev \
        -v /etc/ceph:/etc/ceph \
        -v /var/lib/ceph:/var/lib/ceph \
        -v /lib/modules:/lib/modules:ro \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /mnt:/mnt:shared \
        contiv/volplugin apiserver
    ;;

"volsupervisor" )
    docker run --net host --name volsupervisor \
        -id --privileged \
        -v /lib/modules:/lib/modules:ro \
        -v /etc/ceph:/etc/ceph \
        -v /var/lib/ceph:/var/lib/ceph \
        contiv/volplugin volsupervisor
    ;;

"volplugin" )
    docker run --net host --name volplugin \
        --privileged -i -d \
        -v /dev:/dev \
        -v /lib/modules:/lib/modules:ro \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /run/docker/plugins:/run/docker/plugins \
        -v /mnt:/mnt:shared \
        -v /etc/ceph:/etc/ceph \
        -v /var/lib/ceph:/var/lib/ceph \
        -v /var/run/ceph:/var/run/ceph \
        -v /sys/fs/cgroup:/sys/fs/cgroup \
        contiv/volplugin volplugin
    ;;

* )
    echo "Unknown option:" "$1"
    ;;
esac