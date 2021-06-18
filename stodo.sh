#!/bin/sh

# vim: foldmethod=marker

# Important and global variables {{{

SLEEP_TIME=2
ERRORS_FILE="/tmp/stodo_Errors.log"

# }}}

#COLORS {{{
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
ITALIC_GREEN="\033[1;92m"
UNDER_LINE_RED="\033[4;31m"
END="\033[0m"
# }}}

# main function {{{
main(){
	COUNTER=1
	for i in $(seq 1 $(wc -l "$TODO_FILE" 2>&- | awk '{print $1}')  );do

		local TODO_INFO=$(awk -v VAR1=${COUNTER} 'NR==VAR1 {print $0}' "$TODO_FILE")
		local TODO_NAME=$(awk -v VAR2=${COUNTER} 'NR==VAR2 {print $2}' "$TODO_FILE")
		local START_TIME=$(awk -v VAR3=${COUNTER} 'NR==VAR3 {print $3 }' "$TODO_FILE")
		local START_TIME=$(printf "$START_TIME" | sed "s/\-//g ; s/\://g ; s/\///g")
		local SYSTEM_DATE=$(date +%Y%m%d%H%M)
		IS_DONE_CHECK=$(awk -v VAR4=${COUNTER} 'NR==VAR4 {print $4}' "$TODO_FILE")
		if [ -n "$IS_DONE_CHECK" ];then
			let COUNTER+=1 > /dev/null
			test "$QUIET_MODE" != 1 && \
			printf "${CYAN}%s: %s -- %s: %s\n${END}" \
			"Is Done" "${IS_DONE_CHECK}" "Todo Name" "${TODO_NAME}"
			continue
		elif [ -z "$IS_DONE_CHECK" ];then
			test "$QUIET_MODE" != 1 && \
			printf "${CYAN}%s -- %s: %s\n${END}" \
			"Is Done: no" "Todo Name" "${TODO_NAME}"
		fi
		test "$QUIET_MODE" != 1 &&  {

		printf "${PURPLE}%s: %s${END}\n${YELLOW}%s: %s${END}\n" "Start Time" "${START_TIME}" "Todo Name" "${TODO_NAME}"
		printf "${BLUE}%s: %s${END}\n${GREEN}%s: %s${END}\n" "Todo Info" "${TODO_INFO}" "System Date" "${SYSTEM_DATE}"
		}
		TEMP_GREP=$(printf "$START_TIME" | grep -iE "^[0-9]")
		test "$?" != 0 && { printf "${RED}non-integer value entered\n${END}";exit 1; }
		TEMP_CONDITION=$(printf "$START_TIME" | wc -c)
		test "$TEMP_CONDITION" -lt 12 && exit 1
		unset TEMP_GREP TEMP_CONDITION
		if [ "$SYSTEM_DATE" -gt "$START_TIME" ];then
			if [ "$QUIET_MODE" != 1 ];then
				printf "%s: ${RED}%s.${END}\n" "Error" "System time is bigger."
				exit 1
			elif [ "$QUIET_MODE" == 1 ];then
				printf "$(date +%Y-%m-%d\ %H:%M) %s: ${RED}%s.${END}\n" \
					"Error" "System time is bigger" >> "$ERRORS_FILE"
				exit 1
			fi
		elif [ "$SYSTEM_DATE" -eq "$START_TIME" ];then
			if [ "$QUIET_MODE" != 1 ];then
				printf "%s: ${YELLOW}%s${END}\n" "Warning" "Times are equal."
				continue
			elif [ "$QUIET_MODE" == 1 ];then
				printf "$(date +%Y-%m-%d\ %H:%M) %s: ${YELLOW}%s${END}\n" \
					"Warning" "Times are equal." >> "$ERRORS_FILE"
				continue

			fi
		fi

		while [ ! "$SYSTEM_DATE" -eq "$START_TIME" ];do
			local SYSTEM_DATE=$(date +%Y%m%d%H%M)
			sleep $SLEEP_TIME
		done

		printf "${ITALIC_GREEN}%s %s${END}\n" "Ended" "${TODO_NAME}"

		for _ in $(seq 1 $ALERT_SOUND_REPEAT);do # i used underline(_) instead of i
			aplay "$ALERT_SOUND_FILE" 2> /dev/null
		done

		let COUNTER+=1 > /dev/null
		sed -i "" "s|$TODO_INFO|$TODO_INFO DONE|g" "$TODO_FILE" 2>> "$ERRORS_FILE"
		if [ "$?" != 0 ];then
			printf "^ $(date)\n" >> "$ERRORS_FILE"
			sed -i "s|$TODO_INFO|$TODO_INFO DONE|g" "$TODO_FILE"
		fi
		if [ "$ASK_MODE" == "y" ];then
			COUNT_LINE=$(wc -l "$TODO_FILE" | awk '{print $1}')
			test "$COUNT_LINE" -eq 1 && exit 1
			printf "Go to the next todo? "
			read REPLY
			case "$REPLY" in
				[Yy][Ee][Ss]|Y|y)
					printf "${GREEN}passed\n${END}"
					;;
				[Nn][Oo]|N|n)
					printf "${RED}exited\n${END}"
					exit 1
					;;
			esac
		fi

done
}
# }}}

# ADD_TODO function {{{

ADD_TODO(){
	printf "${BLUE}Given file: $GET_INPUT\n${END}"
	if [ -f "$GET_INPUT" ];then
		CHECK_FILE_CONTENT=$(cat "$GET_INPUT")
		if [ -z "$CHECK_FILE_CONTENT" ];then
			if [ "$NUMBER" != 1 ];then
				NUMBER="1."
			fi
			printf "%d. %s %s\n" "$NUMBER" "$NAME" "$DATE" > "$GET_INPUT"
			printf "${GREEN}Added.${END}\n"
			let NUMBER+=1 > /dev/null
			exit 0
		fi

		GET_FIRST_PARAM_FILE=$(awk 'END{gsub("\\\.", "") ; print $1}' "$GET_INPUT" 2>&- )
		GET_FIRST_PARAM_INPUT=$(printf "$NUMBER"  | awk '{gsub("\\\.", "") ; print $1 }' 2>&- )

		if [ "$GET_FIRST_PARAM_INPUT" -gt "$GET_FIRST_PARAM_FILE" ];then
			printf "%d. %s %s\n" "$NUMBER" "$NAME" "$DATE" >> "$GET_INPUT"
			let NUMBER+=1 > /dev/null
		else
			while [ true ];do

				if [ "$GET_FIRST_PARAM_INPUT" == "$GET_FIRST_PARAM_FILE" ];then
					let GET_FIRST_PARAM_INPUT+=1 > /dev/null
					printf "%d. %s %s\n" "$GET_FIRST_PARAM_INPUT" "$NAME" "$DATE" >> "$GET_INPUT"
					exit 0
				else
					let GET_FIRST_PARAM_INPUT+=1 > /dev/null
				fi

			done

		fi

	elif [ ! -f "$GET_INPUT" ];then
		printf "${GREEN}%s{$END}\n" "File created."
		touch "$GET_INPUT"
		printf "%d. %s %s\n" "$NUMBER" "$NAME" "$DATE" | sort > "$GET_INPUT"
		printf "${GREEN}Added.${END}\n"
		let NUMBER+=1 > /dev/null
	fi

}
#}}}

#LIST_TODO function {{{
LIST_TODO(){
	IFS=$'\n'
	COUNTER=1;

	for _ in $(seq 1 $(wc -l "$FILE_FOR_LIST" 2>&- | awk '{print $1}')  )  ;do
		TODO_NAME=$(awk -v VAR1=${COUNTER} 'NR==VAR1 {print $2}' "$FILE_FOR_LIST")
		IS_DONE_CHECK=$(awk -v VAR2=${COUNTER} 'NR==VAR2 {print $4}' "$FILE_FOR_LIST")

		if [ -n "$IS_DONE_CHECK" ];then
			let COUNTER+=1 > /dev/null
			printf "${CYAN}%s: ${GREEN}%s${END} -- " "Is Done" "${IS_DONE_CHECK}"
			printf "${CYAN}%s: ${GREEN} %s${END}\n" "Todo Name" "${TODO_NAME}"
			continue

		else
			printf "${CYAN}%s: ${END}${RED}%s${END}" "Is Done" "no"
			printf " -- ${CYAN}%s: ${END}${GREEN}%s${END}\n" "Todo Name" "${TODO_NAME}"

		fi

		let COUNTER+=1 > /dev/null

	done
	exit 0
}
# }}}

# DELETE_TODO function {{{
DELETE_TODO(){
	printf "$(cat "$FILE")\n"
	printf  "Enter line number: "
	read SELECT_LINE_INPUT
	TEMP_CHECK=$(printf "$SELECT_LINE_INPUT" | grep -iE "^[0-9]")
	if [ "$?" == 0 ];then
		sed -i "" "${SELECT_LINE_INPUT}d" "$FILE" 2>> "$ERRORS_FILE"
		test "$?" != 0 && { printf "^ $(date)\n" >> "$ERRORS_FILE" ; sed -i "${SELECT_LINE_INPUT}d" "$FILE" ; }
	fi
	IFS=$'\n'
	local COUNTER=1
	local CHECK_FOR_SORT=$(awk 'NR==1 {print $1}' "$FILE")
	local CHECK_FOR_SORT=$(printf "$CHECK_FOR_SORT" | awk 'NR==1 gsub("\\\.", "") ; {print $1}')
	for i in $(seq 1 $(wc -l "$FILE" | awk '{print $1}') );do
		local GET_LINE_FIRST_PARAM=$(awk -v VAR=$COUNTER 'NR==VAR {print $1}' "$FILE")
		local GET_CURRENT_LINE=$(awk -v VAR2=$COUNTER 'NR==VAR2 {print $0}' "$FILE")
		local GET_LINE_CONITNUE=$(awk -v VAR2=$COUNTER 'NR==VAR2 {print $2" "$3" "$4}' "$FILE")
		sed -i "" "s|$GET_CURRENT_LINE|$COUNTER.\ $GET_LINE_CONITNUE|" "$FILE" 2>> "$ERRORS_FILE"
		if [ "$?" != 0 ];then
			printf "^ $(date)\n" >> "$ERRORS_FILE"
			sed -i "s|$GET_CURRENT_LINE|$COUNTER.\ $GET_LINE_CONITNUE|" "$FILE"
		fi
		let COUNTER+=1 > /dev/null
	done
	unset IFS FILE
}
# }}}

# Sort function {{{
Sort(){
	local FILE="$1"
	IFS=$'\n'
	local CHECK_FOR_SORT=$(awk 'NR==1 {print $1}' "$FILE" 2>&- )
	local CHECK_FOR_SORT=$(printf "$CHECK_FOR_SORT" | awk 'NR==1 gsub("\\\.", "") ; {print $1}' 2>&- )
	local COUNTER=1;
	for i in $(seq 1 $(wc -l "$FILE" | awk '{print $1}') );do
		local GET_LINE_FIRST_PARAM=$(awk -v VAR=$COUNTER 'NR==VAR {print $1}' "$FILE" 2>&- )
		local GET_CURRENT_LINE=$(awk -v VAR2=$COUNTER 'NR==VAR2 {print $0}' "$FILE" 2>&- )
		local GET_LINE_CONITNUE=$(awk -v VAR2=$COUNTER 'NR==VAR2 {print $2" "$3" "$4}' "$FILE" 2>&- )
		sed -i "" "s|$GET_CURRENT_LINE|$COUNTER.\ $GET_LINE_CONITNUE|" "$FILE" 2>&-
		if [ "$?" != 0 ];then
			printf "^ $(date)\n" >> "$ERRORS_FILE"
			sed -i "s|$GET_CURRENT_LINE|$COUNTER.\ $GET_LINE_CONITNUE|" "$FILE"
		fi
		let COUNTER+=1 > /dev/null
	done
	printf "${GREEN}Done.${END}\n"
	unset IFS
}
# }}}

# Move function {{{
Move(){

	if [ ! -f "$FILE_TEMP" ];then
		printf "${RED}%s${END}\n" "File does not exists!"
		exit 1

	elif [ -d "$FILE_TEMP" ];then
		printf "${RED}%s${END}\n" "Your entered input is not a file, it is a directory!"
		exit 1
	fi

	FIRST_NUM_TEMP=$(printf "%s" "$FIRST_NUM_TEMP" | sed "s/\-\-//")
	if [ -z "$FIRST_NUM_TEMP" ] && [ -z "$SECOND_NUM_TEMP" ];then
		if [ "$ACTION_TEMP" == "--" ];then
			ACTION_TEMP=$(printf "%s" "$ACTION_TEMP" | sed "s/\-\-//")
			printf "${RED}%s${END}\n" "Failed, because action type did not entered."
			exit 1
		fi
		printf "${CYAN}Action: ${ACTION_TEMP} ${END}\n"
		local ASK=""
		while [ "$ASK" != ":quit" ];do
			printf "Enter First Number: "
			read FIRST_NUM_TEMP
			printf "Enter Second Number: "
			read SECOND_NUM_TEMP
			case "$ACTION_TEMP" in
				[Uu][Pp])
					printf "${FIRST_NUM_TEMP}m-${SECOND_NUM_TEMP}\nwq\n" | ed -s "$FILE_TEMP"
					printf "${GREEN}Done.${END}\n"
					local FILE_CONTENTS=$(cat "$FILE_TEMP")
					printf "File contents:\n$FILE_CONTENTS\n"
					;;
				[Dd][Oo][Ww][Nn])
					printf "${FIRST_NUM_TEMP}m${SECOND_NUM_TEMP}\nwq\n" | ed -s "$FILE_TEMP"
					printf "${GREEN}Done.${END}\n"
					local FILE_CONTENTS=$(cat "$FILE_TEMP")
					printf "File contents:\n$FILE_CONTENTS\n"
					;;
				*)
					printf "${RED}Unkown${END}\n"
					exit 1
					;;

			esac

			printf "Enter(${UNDER_LINE_RED}:quit${END} for ending moving, Press ${UNDER_LINE_RED}Enter/Return${END} key for passing) "
			read ASK

		done

	elif [ -z "$FIRST_NUM_TEMP" ] && [ -n "$SECOND_NUM_TEMP" ];then
		printf "${RED}Failed!\nplease read manual page.\n${END}"

	elif [ -n "$FIRST_NUM_TEMP" ] && [ -z "$SECOND_NUM_TEMP" ];then
		printf "${RED}Failed!\nplease read manual page.\n${END}"

	else
		case "$ACTION_TEMP" in

			[Uu][Pp])
				printf "${FIRST_NUM_TEMP}m-${SECOND_NUM_TEMP}\nwq\n" | ed -s "$FILE_TEMP"
				printf "${GREEN}Done.${END}\n"
				local FILE_CONTENTS=$(cat "$FILE_TEMP")
				printf "File contents:\n$FILE_CONTENTS\n"
				;;

			[Dd][Oo][Ww][Nn])
				printf "${FIRST_NUM_TEMP}m${SECOND_NUM_TEMP}\nwq\n" | ed -s "$FILE_TEMP"
				printf "${GREEN}Done.${END}\n"
				local FILE_CONTENTS=$(cat "$FILE_TEMP")
				printf "File contents:\n$FILE_CONTENTS\n"
				;;
			*)
				printf "${RED}Unkown${END}\n"
				exit 1
				;;

		esac

	fi
}
# }}}

# Edit_Todos function {{{
Edit_Todos(){
	HELP="
p for print
a for add
d for delete
m for move
r for replace
s for sort
h for help
q for quit
c for clear screen
";
	while [ "$ASK" != ":quit" ];do
		printf "${PURPLE}%s\n${END}" "$HELP"
		printf "%s" "Enter command: "
		read ACTION
		case "$ACTION" in
			'p')
				cat "$FILE"
				;;
			'a')
				Todo_File="$FILE"
				printf "Given File: $Todo_File\n"
				local NUMBER=1
				printf "Enter Todo: "
				read Todo_Name
				printf "Enter Date: "
				read Todo_Date

				if [ -z "$Todo_Name" ];then
					exit 1
				fi

				if [ -z "$Todo_Date" ];then
					exit 1
				fi

				if [ ! -f "$Todo_File" ];then
					printf "File does not exists!\n"
					touch "$Todo_File"
					if [ "$?" == 0 ];then
						printf "Created\n"
						printf "%d. %s %s\n" "$NUMBER" "$Todo_Name" "$Todo_Date" > "$Todo_File"
					else
						printf "${RED}can not create file.\n${END}"
						exit 1
					fi
				elif [ -f "$Todo_File" ];then
					TEMP_CHECK=$(cat "$Todo_File")
					COUNTER=1
					GET_END_LINE_NUMBER=$(awk 'END{print $1}' "$Todo_File" 2>&-)
					TEMP_CHECK=$(printf "$GET_END_LINE_NUMBER" | grep "^[0-9]" 2>&-)
					TEMP_CHECK=$(printf "$GET_END_LINE_NUMBER" | awk '{gsub("\\\.", "") ; print $1}' 2>&-)
					if [ -z "$TEMP_CHECK" ];then
						printf "${RED}non-integer value entered.\n${END}"
						exit 1
					fi
					let COUNTER+=$TEMP_CHECK > /dev/null
					printf "%d. %s %s\n" "$COUNTER" "$Todo_Name" "$Todo_Date" >> "$Todo_File"

				fi
				unset NUMBER Todo_Name Todo_Date Todo_File COUNTER
				;;
			'd')
				while [ true ];do
					printf "%s" "Which line do you want to delete? "
					read REPLY
					local CHECK_STATUS=$(printf "$REPLY" | grep -iE "^[0-9]")
					if [ -n "$CHECK_STATUS" ];then
						printf "${REPLY}d\nwq\n" | ed -s "$FILE"
						break
					else
						printf "${RED}%s${END}\n" "You Entered non-integer value."
						break
					fi
				done
				;;
			'm')
				while [ true ];do
					printf "%s" "You want to move line to down or up? "
					read REPLY
					case "$REPLY" in
						[Uu][Pp])
							printf "%s" "Which line do you want to move it? "
							read FIRST
							printf "%s" "Move it to which line? "
							read SECOND
							CHECK_STATUS=$(printf "$FIRST" | grep "^[0-9]")
							if [ -z "$CHECK_STATUS" ];then
								printf "${RED}non-integer value entered.\n${END}"
								break
							fi
							CHECK_STATUS=$(printf "$SECOND" | grep -iE "^[0-9]")
							if [ ! -z "$CHECK_STATUS" ];then
								printf "%dm-%d \nwq\n" "${FIRST}" "${SECOND}" | ed -s "$FILE"
								printf "${GREEN}%s${END}\n" "moved."
								cat "$FILE"
								break
							else
								printf "${RED}%s${END}\n" "You entered non-integer value."
								break
							fi
							;;
						[Dd][Oo][Ww][Nn])
							printf "%s" "Which line do you want to move it? "
							read FIRST
							printf "%s" "Move it to which line? "
							read SECOND
							CHECK_STATUS=$(printf "$FIRST" | grep "^[0-9]")
							if [ -z "$CHECK_STATUS" ];then
								printf "${RED}non-integer value entered.\n${END}"
								break
							fi
							CHECK_STATUS=$(printf "$SECOND" | grep -iE "^[0-9]")
							if [ ! -z "$CHECK_STATUS" ];then
								printf "%dm%d \nwq\n" "${FIRST}" "${SECOND}" | ed -s "$FILE"
								printf "${GREEN}%s${END}\n" "moved."
								cat "$FILE"
								break
							else
								printf "${RED}%s${END}\n" "You entered non-integer value."
								break
							fi
						;;
					*)
						printf "${RED}Failed. just down or up.\n${END}"
						break
						;;
				esac
			done
				;;
					'r')
						IFS=$'\n'
						COUNTER=1
						for i in $(cat "$FILE");do
							printf "${PURPLE}%d)${END} %s\n" "$COUNTER" "$i"
							let COUNTER+=1 > /dev/null
						done
						unset IFS
						printf "%s" "Enter number line: "
						read REPLY
						printf "%s" "Enter your pattern: "
						read PATTERN
						printf "%s" "Enter your new pattern: "
						read NEW_PATTERN
						CHECK_STATUS=$(printf "%s" "$REPLY" | grep "\\\^[0-9]")
						if [ "$?" == 0 ];then
							printf "${RED}%s${END}\n" "You entered non-integer value."
							exit 1
						fi
						printf "%ds/%s/%s\nwq\n" "${REPLY}" "${PATTERN}" "${NEW_PATTERN}" | ed -s "$FILE"
						;;
					'c')
						clear
						;;
					's')
						Sort "$FILE"
						;;
					'h')
						printf "%s\n" "$HELP"
						;;
					'q')
						exit 0
						;;
		esac
		printf "Enter(${UNDER_LINE_RED}:quit${END} for end moving, Press ${UNDER_LINE_RED}Enter/Return${END} key for passing) "
		read ASK
		test "$ASK" == "clear" && clear;
	done
}
# }}}

# getopt conditional statements {{{
TEMP_ARGS=$(getopt "f:F:t:a:l:d:q:D:Es:m:e:A:" "$*")
if [ "$?" != 0 ];then
	printf "${RED}Failed! From setting getopt\n${END}"
	exit 1
fi
eval set -- "$TEMP_ARGS"
unset TEMP_ARGS

while [ true ];do

	case "$1" in
		'-f')
			ARG_COUNTS="$*"
			ARG_COUNTS=$(printf "%s" "$ARG_COUNTS" | wc -w | awk '{print $1}')
			GETOPT_ARGS=$(printf "%s\n" "$*" | grep -iE "\-F|\-t")
			test "$ARG_COUNTS" == 3 && { printf "\-f flag can not used alone.\nuse it with \-F and \-t flags.\n" ; exit 1; }
			if [ -z "$GETOPT_ARGS" ];then
				printf "\-f can not used alone.\nUse \-f flag with \-t and \-F flags.\n"
				exit 1
			fi
			TODO_FILE="$2"
			HOME_PATH="/home/$(logname)/"
			TEMP_STATUS=$(printf "$TODO_FILE"  | grep -iE "^\~" )
			if [ "$?" == 0 ];then
				TODO_FILE=$(printf "$TODO_FILE" | sed "s|\~|$HOME_PATH|")
			fi
			if [ ! -f "$TODO_FILE" ];then
				printf "Error: ${RED}File does not exist!\n${END}"
				exit 1
			fi
			shift 2
			continue
			unset HOME_PATH TEMP_STATUS
			;;
		'-F')
			if [ -z "$GETOPT_ARGS" ];then
				printf "\-F can not used alone.\nUse \-F flag with \-t and \-f flags.\n"
				exit 1
			fi
			ALERT_SOUND_FILE="$2"
			HOME_PATH="/home/$(logname)/"
			TEMP_STATUS=$(printf "$ALERT_SOUND_FILE" | grep -iE "^\~")
			if [ "$?" == 0 ];then
				ALERT_SOUND_FILE=$(printf "$ALERT_SOUND_FILE" | sed "s|\~|$HOME_PATH|")
			fi
			if [ ! -f "$ALERT_SOUND_FILE" ];then
				printf "Error: ${RED}File does not exist!\n${END}"
				exit 1
			fi
			shift 2
			continue
			unset HOME_PATH TEMP_STATUS
			;;
		'-t')
			if [ -z "$GETOPT_ARGS" ];then
				printf "\-t can not used alone.\nUse \-t flag with \-F and \-f flags.\n"
				exit 1
			fi
			ALERT_SOUND_REPEAT="$2"

			if [ "$ALERT_SOUND_REPEAT" -gt 5 ];then
				printf "Error: ${RED}Please enter a number equal with 5 or little than 5.\n${END}"
				exit 1
			fi
			shift 2
			continue
			;;
		'-a')
			OUTPUT=$(printf "%s\n" "$*" | sed "s/\-a// ; s/\-\-//" | wc -w)
			OUTPUT=$(printf "%s\n" "$OUTPUT" | awk '{print $1}')
			if [ "$OUTPUT" == 3 ];then
				NUMBER=1; NAME="$2"; DATE="$3"; GET_INPUT="$4"
				test ! -f "$GET_INPUT" && { printf "Warning: ${YELLOW}File does not exists!\nFile Created.${END}\n" ; \
					touch "$GET_INPUT" ; }
				TEMP_STATUS=$(printf "$GET_INPUT" | grep -iE "^\~")
				HOME_PATH="/home/$(logname)/"
				if [ "$?" == 0 ];then
					GET_INPUT=$(printf "$GET_INPUT" | sed "s|\~|$HOME_PATH|")
				fi
				ADD_TODO
			else
				printf "${RED}File name lost.${END}\n"
			fi
			unset TEMP_CHECK USER NUMBER NAME DATE GET_INPUT OUTPUT
			exit 0
			;;
		'-l')
			FILE_FOR_LIST="$2"
			FILE_FOR_LIST2="$(\cat $2)"
			test -z "$FILE_FOR_LIST2" && { \cat /dev/null > "${FILE_FOR_LIST}" && exit 1 ; }
			HOME_PATH="/home/$(logname)/"
			TEMP_STATUS=$(printf "$FILE_FOR_LIST" | grep -iE "^\~")
			if [ "$?" == 0 ];then
				FILE_FOR_LIST=$(printf "$FILE_FOR_LIST" | sed "s|\~|$HOME_PATH")
			fi
			LIST_TODO
			unset TEMP_STATUS HOME_PATH
			break
			exit 1
			;;
		'-d')
			FILE="$2"
			HOME_PATH="/home/$(logname)/"
			TEMP_STATUS=$(printf "$FILE" | grep -iE "^\~")
			if [ "$?" == 0 ];then
				FILE=$(printf "$FILE" | sed "s|\~|$HOME_PATH")
			fi
			DELETE_TODO
			unset TEMP_STATUS HOME_PATH
			exit 0
			;;
		'-q')
			QUIET_MODE=1
			shift 1
			;;
		'-A')
			ASK_MODE="y"
			shift 1
			;;
		'-D')
			FILE="$2"
			test ! -f "$FILE" && { printf "${RED}File does not exists!\n${END}";exit 1;}
			CHECK_FOR_DONE=$(grep "DONE" "$FILE")
			if [ "$?" != 0 ];then
				printf "${RED}Can not find any DONE keyword.${END}\n"
				exit 1
			fi
			sed -i "" "s|DONE||g" "$FILE" 2>> "$ERRORS_FILE"
			if [ "$?" != 0 ];then
				printf "^ $(date)\n" >> "$ERRORS_FILE"
				sed -i "s|DONE||g" "$FILE"
			fi
			printf "${GREEN}Removed.${END}\n"
			unset FILE
			exit 0
			;;
		'-E')
			cat "$ERRORS_FILE"
			exit 0
			;;
		'-s')
			FILE_TEMP="$2"
			Sort "$FILE_TEMP"
			exit 0
			;;
		'-m')
			FILE_TEMP="$2"
			ACTION_TEMP="$3"
			FIRST_NUM_TEMP="$4"
			SECOND_NUM_TEMP="$5"
			if [ -z "$FIRST_NUM_TEMP" ] && [ -z "$SECOND_NUM_TEMP" ];then
				Move "$FILE_TEMP" "$ACTION_TEMP"
			else
				Move "$FILE_TEMP" "$ACTION_TEMP" "$FIRST_NUM_TEMP" "$SECOND_NUM_TEMP"
			fi
			unset FILE_TEMP ACTION_TEMP FIRST_NUM_TEMP SECOND_NUM_TEMP
			exit 0
			;;
		'-e')
			FILE="$2"
			USER_TEMP=$(logname)
			CHECK_STATUS=$(printf "$FILE" | grep -iE "^\~")
			if [ "$?" == 0 ];then
				FILE=$(printf "$FILE" |  sed "s|\~|\/home\/$USER_TEMP|")
			fi

			Edit_Todos
			unset FILE
			exit 0;
			;;
		'--')
			break
			continue
			;;
		*)
			printf "Failed\n"
			exit 1
			;;
	esac
done
# }}}

main
