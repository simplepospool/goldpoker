#!/bin/bash

cd
bifrost-cli stop
sleep 30
rm -f /usr/local/bin/bifros*
rm -rf .bifrost
wget -N https://raw.githubusercontent.com/simplepospool/goldpoker/master/frost_install.sh
bash frost_install.sh
rm frost_install.sh
rm update_3_frost.sh
