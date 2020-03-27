#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Please tell me what coin you want${NC}"
read -e COIN

echo -e "${GREEN}How many do you want?${NC}"
read -e AMOUNT

echo -e "${GREEN}How long should I wait?${NC}"
read -e TIME

for ((n=0;n<$AMOUNT;n++))
do
 dupmn install $COIN --bootstrap
 sleep $TIME
done
