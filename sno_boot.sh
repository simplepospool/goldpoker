#!/bin/bash

systemctl stop savenode.service
sleep 60
cd .savenode
rm -rf blocks
rm -rf chainstate
rm peers.dat
wget -N https://www.dropbox.com/s/72fmjfjfgwsjjby/save_bootstrap.zip
unzip save_bootstrap.zip
rm save_bootstrap.zip
cd
systemctl start savenode.service
