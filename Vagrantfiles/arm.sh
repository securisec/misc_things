#!/bin/bash -ex

##### Install qemu #####

find_latest_qemu_version() {
    git ls-remote --tags git://git.qemu.org/qemu.git \
        | grep -v '\-rc' \
        | grep -oh 'v[0-9]\{1,2\}\.[0-9]\{1,2\}\.[0-9]\{1,2\}\(\.[0-9]\{0,2\}\)\?' \
        | sort --version-sort -r \
        | head -n 1
}

#VERSION=v2.10.1
VERSION=$(find_latest_qemu_version)
mkdir /home/ubuntu/tools
cd /home/ubuntu/tools
git clone --depth=1 -b "$VERSION" git://git.qemu-project.org/qemu.git

# source bin/activate
sudo apt update
sudo apt -y install python gcc pkg-config zlib1g-dev libglib2.0-dev libpixman-1-dev

prefix="--prefix=$(pwd)"
python="--python=$(which python)"

cd /home/ubuntu/tools/qemu
if ! ./configure "$prefix" "$python"; then
    echo "Updating QEMU submodules in case dependencies are missing"
    git submodule init
    git submodule update --recursive
    ./configure "$prefix" "$python"
fi
./configure --target-list=arm-softmmu,arm-linux-user
sudo make -j $(nproc)
sudo make install

##### Install radare2 #####
cd /home/ubuntu/tools
git clone https://github.com/radare/radare2.git
cd radare2
sys/user.sh

##### Install gdb-multiarch #####
sudo apt -y install gdb-multiarch

##### Install ARM Libs #####
sudo apt -y install 'binfmt*'
sudo apt -y install libc6-armhf-armel-cross
sudo apt -y install gcc-arm-linux-gnueabihf
sudo mkdir /etc/qemu-binfmt
sudo ln -s /usr/arm-linux-gnueabihf /etc/qemu-binfmt/arm
sudo mkdir -p /lib/arm-linux-gnueabihf/
sudo ln -s /usr/arm-linux-gnueabihf/lib/libc.so.6 /lib/arm-linux-gnueabihf/libc.so.6
sudo ln -s /usr/arm-linux-gnueabihf/lib/ld-linux-armhf.so.3 /lib/ld-linux-armhf.so.3
sudo bash -c 'echo ":arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm-static:" > /proc/sys/fs/binfmt_misc/register'
