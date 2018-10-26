#!/bin/sh

if [ -f /etc/systemd/system/pacd.service ]; then 
    echo "servico pac" 
elif [ -f /etc/systemd/system/Paccoin.service ]; then 
    echo "Paccoin.service" 
else 
    echo "same" 
fi
