#!/bin/bash

VERSION=$(hostname | cut -d\- -f2)
echo "RAW VERSION = ${VERSION}"
if [[ $VERSION != "latest"  && $VERSION != "dev" ]]; then
    # use python to set a stable branch name compatible version
    VERSION=$(echo $VERSION | python -c 'import sys; vs = sys.stdin.read(); print(vs[0] + "." + vs[1])')
fi
echo "PROCESSED VERSION = $VERSION"

SRC=/home/vagrant/src
mkdir -p $SRC

if [[ ! -d $SRC/galaxy_ng ]]; then
    git clone https://github.com/ansible/galaxy_ng /home/vagrant/src/galaxy_ng
    if [[ $VERSION != "latest"  && $VERSION != "dev" ]]; then
        cd $SRC/galaxy_ng
        git checkout stable-$VERSION
    fi
fi
if [[ ! -d $SRC/ansible-hub-ui ]]; then
    git clone https://github.com/ansible/ansible-hub-ui /home/vagrant/src/ansible-hub-ui
    if [[ $VERSION != "latest"  && $VERSION != "dev" ]]; then
        cd $SRC/ansible-hub-ui
        git checkout stable-$VERSION
    fi
fi

cd $SRC/galaxy_ng
rm -f .compose.env; cp .compose.env.example .compose.env
echo "ANSIBLE_HUB_UI_PATH='${SRC}/ansible-hub-ui'" >> .compose.env
sed -i.bak 's/PULP_GALAXY_REQUIRE_CONTENT_APPROVAL/#PULP_GALAXY_REQUIRE_CONTENT_APPROVAL/' dev/standalone/galaxy_ng.env

# we can't use newest docker-compose =(
file /usr/local/bin/docker-compose | fgrep ASCII
RC=$?
if [[ RC != 0 ]]; then
    sudo rm -f /usr/local/bin/docker-compose
    sudo pip uninstall -y docker-compose
    sudo pip install docker-compose==1.29.2
fi
if [ ! -f /usr/local/bin/docker-compose ]; then
    echo "DOCKER COMPOSE CMD NOT FOUND!!!"
    exit 1
fi

# cleanup first ..
/vagrant/docker-killall
/vagrant/docker-rmall

cd $SRC/galaxy_ng
make docker/all

if [[ $VERSION != "4.2" ]]; then
    make docker/loadtoken
fi
