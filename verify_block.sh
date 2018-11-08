#!/bin/bash

a=$(logiscoin-cli getblockhash 131168)

echo $a

if [ $a = ab64e01e59d4f3e0174a50f474ef5ef61277348c78fdd276dd04fe7984474be5 ]
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
