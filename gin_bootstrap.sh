#!/bin/bash

systemctl stop Gincoin.service
sleep 60
cd .gincoincore
rm -rf blocks
rm -rf chainstate
rm peers.dat
wget -N https://www.dropbox.com/s/erh7q6z227xieb1/gin_bootstrap.zip
unzip gin_bootstrap.zip
rm gin_bootstrap.zip
systemctl start Gincoin.service
sleep 60
cd
