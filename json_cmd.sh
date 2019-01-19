#!/bin/bash

# Author: neo3587

cmd=""

function parse_str() {
	[[ "$1" =~ ^[0-9.]+$ ]] && echo $1 || echo \"$1\"
}
function json_finish() {
	local endc=$([[ -z "$2" ]] && echo "}" || echo "]")
	echo -e "$(echo $1 | rev | sed 's/,//' | rev) $endc"
}
function matrix_get() {
	local off=$([[ -z "$3" ]] && echo 0 || echo $3)
	echo -e "$cmd" | sed "$(($1+1+$off))q;d" | awk "{print \$$(($2+1+$off))}"
}

function cmd_top() {
	cmd=$(top -n 1 -b $@)
	# {
	#	"procs": [
	#		{ "pid": number, "user": "root", ...}
	#	],
	#   tasks: { "total": number, "running": number, "sleeping": number, ... },
	#   ...
	# }
}
function cmd_free() {
	cmd=$(free $@)
	local rows=($(sed "s/://g" <<< $(echo "$cmd" | awk '{print $1}' | tail -n +2)))
	local cols=($(echo "$cmd" | head -n 1))
	local js="{ "
	for (( i=0; i<${#rows[@]}; i++ )); do
		js+=" \"${rows[i]}\": { "
		for (( j=0; j<${#cols[@]}; j++ )); do
	                js+=" \"${cols[j]}\": "$(parse_str $(matrix_get $i $j 1))", "
		done
		js=$(json_finish "$js")", "
        done
	json_finish "$js"
}
function cmd_df() {
	cmd=$(df $@)
	local rows=($(sed "s/://g" <<< $(echo "$cmd" | awk '{print $1}' | tail -n +2)))
        local cols=($(sed "s/Mounted on/Mounted_on/g" <<< $(echo "$cmd" | head -n 1)))
        local js="{ \"data\": [ "
	for (( i=0; i<${#rows[@]}; i++ )); do
                js+="{ "
                for (( j=0; j<${#cols[@]}; j++ )); do
                        js+=" \"${cols[j]}\": "$(parse_str $(matrix_get $(($i+1)) $j))", "
                done
                js=$(json_finish "$js")", "
        done
        echo -e $(json_finish "$js" "]")" }"
}


if [[ -z "$1" ]]; then
	echo -e "No command inserted"
	exit
fi

case "$1" in
	"top")
		cmd_top ${@:2}
		;;
	"free")
		cmd_free ${@:2}
		;;
	"df")
		cmd_df ${@:2}
		;;
	*)
		echo -e "Unrecognized parameter: $1"
		echo -e "Currently accepted commands: free, top, df"
		;;
esac

