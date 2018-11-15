#!/bin/bash

a=$(gpkr-cli getblockhash 187452)

echo $a

if [ $a = 3e60021b09174b682b213ca962405ef0c88ebb3fdf86393a3cedf19890504acd ]
  then echo "You´re on the right chain"
  gpkr-cli masternode status
 

else
  echo "You´re on the wrong chain"
 
fi
