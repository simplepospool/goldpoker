#!/bin/sh

if [ -f /etc/systemd/system/pacd.service ]; then 
    systemctl stop pacd.service
    killall paccoind
    sleep 20
    cd
    rm pacc*
    wget https://github.com/PACCommunity/PAC/releases/download/v0.12.5.0/PAC-v0.12.5.0-linux-x86_64.tar.gz
    tar -zvxf PAC-v0.12.5.0-linux-x86_64.tar.gz
    rm PAC-v0.12.5.0-linux-x86_64.tar.gz
    chmod +x pac*
    systemctl start pacd.service
    sleep 60
    ./paccoin-cli getinfo
    echo "Servico Pac geral atualizado" 
elif [ -f /etc/systemd/system/Paccoin.service ]; then 
    systemctl stop Paccoin.service
    killall paccoind
    sleep 20
    cd /usr/local/bin
    rm pacc*
    wget https://github.com/PACCommunity/PAC/releases/download/v0.12.5.0/PAC-v0.12.5.0-linux-x86_64.tar.gz
    tar -zvxf PAC-v0.12.5.0-linux-x86_64.tar.gz
    rm PAC-v0.12.5.0-linux-x86_64.tar.gz
    chmod +x pac*
    cd
    systemctl start Paccoin.service
    sleep 60
    paccoin-cli getinfo
    echo "Atualizado servico Pedro Pires" 
else 
    cd
    killall paccoind
    sleep 20
    rm pacco*
    wget https://github.com/PACCommunity/PAC/releases/download/v0.12.5.0/PAC-v0.12.5.0-linux-x86_64.tar.gz
    tar -zvxf PAC-v0.12.5.0-linux-x86_64.tar.gz
    rm PAC-v0.12.5.0-linux-x86_64.tar.gz
    chmod +x pac*
    ./paccoind -daemon
    sleep 10
    cd
    wget https://gist.githubusercontent.com/foxrtb/b703ae761472c5599c4d83ab0d3d62ae/raw/e8913deb9e1b7cc9c649febd2942930e4f6f5127/add-systemd-from-script
    chmod +x add-systemd-from-script
    ./add-systemd-from-script
    rm add-systemd-from-script
    sleep 60
    ./paccoin-cli getinfo
    echo "Atualizado e criado servio Geral" 
fi
