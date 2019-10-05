#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


function add_ip() { 
echo -e "${RED}Enter your ${GREEN} IPv6 ${RED}and press enter${NC}" 
read -e IPv6

dupmn ipadd $IPv6:0000:0000:0000:0002 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:0003 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:0004 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:0005 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:0006 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:0007 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:0008 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:0009 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:000a 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:000b 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:000c 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:000d 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:000e 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:000f 64 eth0
dupmn ipadd $IPv6:0000:0000:0000:0010 64 eth0


}

add_ip
