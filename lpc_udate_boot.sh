#!/bin/bash

systemctl stop LightPayCoin.service
sleep 60
cd .lightpaycoin
rm -f peers.dat
rm -rf blocks
rm -rf chainstate
wget https://www.dropbox.com/s/qj9eanp05g5p35b/lpc_bootstrap.zip
unzip lpc_bootstrap.zip
rm lpc_bootstrap.zip
systemctl start LightPayCoin.service
sleep 60
watch lightpaycoin-cli getinfo