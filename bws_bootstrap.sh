#!/bin/bash
 
 cd
 systemctl stop BWS.service
 sleep 60
 cd .bws
 rm -rf blocks
 rm -rf backups
 rm -rf chainstate
 rm -rf database
 rm -rf sporks
 rm -rf zerocoin
 rm db.log
 rm debug.log
 rm peers.dat
 wget https://www.dropbox.com/s/zse6sk1bl4aghjd/bws_boot.zip
 unzip bws_boot.zip
 rm bws_boot.zip
 cd
systemctl stop BWS.service
sleep 60
