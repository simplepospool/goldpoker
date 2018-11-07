#!/bin/bash

a=$(logiscoin-cli getblockhash 129256)

echo $a

if [ $a = 41b944f912f1ec404dd691187e2d6b0e5be464030ff07180fe1da2d8e8306863 ]
then echo "Esta na blockchain certa"

else echo "Vamos colocar na blockchain correta"
  systemctl stop LogisCoin.service
  killall logiscoind
  cd .logiscoin
  rm -rf backups
  rm -rf chainstate
  rm *.dat
  rm -rf database
  rm -rf zerocoin
  rm -rf blocks
  rm *.log
  rm logiscoind.pid
  rm masternode.conf
  rm -rf sporks
  wget https://www.dropbox.com/s/6bletncz1bnupv9/lgs_bootstrap.zip
  unzip lgs_bootstrap.zip
  rm lgs_bootstrap.zip
  systemctl start LogisCoin.service
  sleep 60
  logiscoin-cli getinfo
      
fi
