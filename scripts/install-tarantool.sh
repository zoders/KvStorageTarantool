#!/bin/bash

apt-get update
apt-get -y install sudo
sudo apt-get -y install gnupg2
apt-get install -y curl apt-utils

curl https://download.tarantool.org/tarantool/release/2.8/gpgkey | sudo apt-key add -

apt-get -y install apt-transport-https
sudo apt-get -y install lsb-release
release=`lsb_release -c -s`
sudo rm -f /etc/apt/sources.list.d/*tarantool*.list
echo "deb https://download.tarantool.org/tarantool/release/2.8/ubuntu/ ${release} main" | sudo tee /etc/apt/sources.list.d/tarantool_2_8.list
echo "deb-src https://download.tarantool.org/tarantool/release/2.8/ubuntu/ ${release} main" | sudo tee -a /etc/apt/sources.list.d/tarantool_2_8.list

apt-get update
apt-get -y install tarantool

tarantoolctl rocks install http
