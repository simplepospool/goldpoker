#!/bin/bash

function load_profile() {
	# <$1 = profile_name>

	readonly RED='\e[1;31m'
	readonly GREEN='\e[1;32m'
	readonly YELLOW='\e[1;33m'
	readonly BLUE='\e[1;34m'
	readonly MAGENTA='\e[1;35m'
	readonly CYAN='\e[1;36m'
	readonly UNDERLINE='\e[1;4m'
	readonly NC='\e[0m'

	function get_conf() {
        	# <$1 = conf_file>
	        local str_map="";
	        for line in `sed '/^$/d' $1`; do
        	        str_map+="[${line%=*}]=${line#*=} "
	        done
        	echo -e "( $str_map )"
	}
	function is_number() {
	        # <$1 = number>
        	[[ $1 =~ ^[0-9]+$ ]] && echo "1"
	}

	if [[ ! -f ".dupmn/$1" ]]; then
		echo -e "${BLUE}$1${NC} profile hasn't been added"
		exit
	fi

	local -A prof=$(get_conf .dupmn/$1)
	local -A conf=$(get_conf .dupmn/dupmn.conf)

	local CMD_ARRAY=(COIN_NAME COIN_PATH COIN_DAEMON COIN_CLI COIN_FOLDER COIN_CONFIG)
	for var in "${CMD_ARRAY[@]}"; do
		if [[ ! "${!prof[@]}" =~ "$var" || -z "${prof[$var]}" ]]; then
			echo -e "Seems like you modified something that was supposed to remain unmodified: ${MAGENTA}$var${NC} parameter should exists and have a assigned value in ${GREEN}.dupmn/$1${NC} file"
			echo -e "You can fix it by adding the ${BLUE}$1${NC} profile again"
			exit
		fi
	done
	if [[ ! "${!conf[@]}" =~ "$1" || -z "${conf[$1]}" || ! $(is_number "${conf[$1]}") ]]; then
		echo -e "Seems like you modified something that was supposed to remain unmodified: ${MAGENTA}$1${NC} parameter should exists and have a assigned number in ${GREEN}.dupmn/dupmn.conf${NC} file"
		echo -e "You can fix it by adding ${MAGENTA}$1=0${NC} to the .dupmn/dupmn.conf file (replace the number 0 for the number of nodes installed with dupmn using the ${BLUE}$1${NC} profile)"
		exit
	fi

	coin_name="${prof[COIN_NAME]}"
	coin_path="${prof[COIN_PATH]}"
	coin_daemon="${prof[COIN_DAEMON]}"
	coin_cli="${prof[COIN_CLI]}"
	coin_folder="${prof[COIN_FOLDER]}"
	coin_config="${prof[COIN_CONFIG]}"
	rpc_port="${prof[RPC_PORT]}"
	dup_count=$((${conf[$1]}))
}

function apply_cmd() {
	# <$1 = folder | <${@:2} = cmd>
	local cmds="${@:2}"
	${cmds//DUPFOLDER/$1}
}

# <$1 = profile_name> | <${@:2} = cmd>

load_profile "$1"

apply_cmd $coin_folder ${@:2}
for (( i=1; i<=$dup_count; i++ )); do
	apply_cmd $coin_folder$i ${@:2}
done
