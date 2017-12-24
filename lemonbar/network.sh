n_ping=1

# Get network
network() {
#	ethernet_status=$(nmcli d | grep 'ethernet' | awk '{ print $3 }')
	wifi_status=$(iwconfig | grep "Tx-Power" | sed 's/.*Tx-Power=\(.*\)/\1/')
	wifi_ESSID=$(iwgetid | grep $wifi | sed 's/.*ESSID:"\(.*\)".*/\1/')
	wifi_quality=0
	vpn_status=$(/home/geometrum/utc/vpn-utc.sh status)
	ethernet_disconnected=0
	n_bcolor=$red
	n_fcolor=$black
	n_icon=''

	if [ $wifi_status == 'off' ]; then
		n_bcolor=$white
		n_icon=$airplane_icon
		n_info=''
#		if [ $ethernet_status == 'déconnecté' ]; then
#			nmcli dev connect $ethernet &
#		fi
	
	elif [[ -z $wifi_ESSID ]]; then
		n_bcolor=$black
		n_fcolor=$white
		n_info=''
#		if [ $ethernet_status != 'connecté' ]; then
#			n_icon=$disconnected_icon
#		fi
#
#		if [ $ethernet_status == 'déconnecté' ]; then
#			nmcli dev connect $ethernet &
#		fi
#
	elif [[ -z n_info ]]; then
		n_bcolor=$orange
		n_icon=$wifi_icon
#		if [ $ethernet_status == 'connecté' ]; then
#			nmcli dev disconnect $ethernet &
#		fi
#		ethernet_disconnected=1

#	elif [ $wifi_status == 'connecté' ]; then
	else
		n_icon=$wifi_icon
		wifi_quality=$((100*$(iwconfig $wifi | grep 'Link Quality' | sed 's/.*Link Quality=//' | sed 's/ .*//')))
		if [ $wifi_quality -ge 65 ]; then
			n_bcolor=$blue
			n_fcolor=$white
		elif [ $wifi_quality -ge 35 ]; then
			n_bcolor=$green
		else
			n_bcolor=$yellow
		fi
		if [ -z $n_info ]; then
			n_info=$warning_icon
		fi
	fi

#	if [ $ethernet_status == 'indisponible' ]; then
#		if [ $wifi_status == 'déconnecté' ]; then
#			nmcli dev connect $wifi &
#		fi
#
#		if [ $ethernet_disconnected -eq 1 ]; then
#			ethernet_disconnected=2
#		fi
#
#	elif [ $ethernet_status == 'déconnecté' ]; then
#		n_icon+=$disconnected_icon
#		if [ $wifi_status == 'déconnecté' ]; then
#			nmcli dev connect $wifi &
#		fi
#
#		if [ $ethernet_disconnected -eq 2 ]; then
#			nmcli dev connect $ethernet &
#			ethernet_disconnected=0
#		fi
#	elif [ $ethernet_status == 'connexion' ]; then
#		n_bcolor=$orange
#		n_icon+=$ethernet_icon
#	
#	elif [ $ethernet_status == 'connecté' ]; then
#		n_bcolor=$blue
#		n_fcolor=$white
#		n_icon+=$ethernet_icon
#		if [ $wifi_status == 'connecté' ]; then
#			nmcli dev disconnect $wifi &
#		fi
#		if [ -z "${n_info}" ]; then
#			n_info=$warning_icon
#		fi
#	else
#		n_bcolor=$red
#	fi

	if [ $n_ping -eq 0 ]; then
		n_info=''
	fi

	if [ $vpn_status -eq 1 ]; then
		n_icon+=$vpn_icon
	fi

	echo 'info_n_F'$n_bcolor'}%{A:echo "n_toogle" > '$fifo_bar':}'$left'%{F'$n_fcolor' B'$n_bcolor'} '$n_icon$n_info' %{F'$n_fcolor'}'$left_light'%{A}%{B'$n_bcolor > $fifo_bar
}

