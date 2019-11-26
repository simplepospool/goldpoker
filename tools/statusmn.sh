#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


echo -e "${GREEN}Please tell me what coin you want${NC}"
read -e COIN
echo -e "${GREEN}This is the coin${RED} $COIN${NC}"
dupmn list $COIN -a | grep status
