#!/bin/bash

# Detect if it's already launched. Restart i3 and itself if detected
if [ $(pgrep -cx $(basename $0)) -gt 1 ] ; then
	killall -g /bin/bash
fi

trap 'trap - TERM; kill 0' INT TERM QUIT EXIT

# Variables
fifo="/tmp/lemonbar"

. ~/ressources/colors
. ~/ressources/devices
. ~/ressources/paths
. ~/ressources/separators
. ~/ressources/icons
. ~/ressources/workspaces


# Creation of the fifo file
[ -e "${fifo}" ] && rm -Rf "${fifo}"
mkfifo "${fifo}"


acpi_entry() {
	while read -r line ; do
		case $line in
			button/*)
				if [ $line == "button/wlan" ]; then
					echo 'n' > "${fifo}"
				else
					echo 'v' > "${fifo}"
				fi
			;;

			video*)
				echo 'l' > "${fifo}"
			;;

			ac_adapter*)
				echo 'b_Discharging' > "${fifo}"
			;;
			battery*)
				echo 'b_Charging' > "${fifo}"
			;;

			jack*)
				if [ $(echo $line | sed 's/.* //') == "plug" ]; then
					echo "v_jack" > "${fifo}"
				else
					echo "v_normal" > "${fifo}"
				fi
			;;

		esac &
	done
}

dmesg_entry() {
	while read -r line ; do
		case $line in
			*$wifi*by*)
				echo 'n' > "${fifo}"
			;;
			*$ethernet*)
				echo 'n' > "${fifo}"
			;;

			Restarting*) # Reload everything when the system restart
				echo 'reload' > "${fifo}"
			;;

			"usb "*) # Detect the usb key
				echo $line | sed 's/usb \(.\)-.*number \([0-9]*\).*/u_\1 \2/' > "${fifo}"
			;;

		esac &
	done
}


# Spy window changement
xprop -spy -root _NET_ACTIVE_WINDOW | sed -un 's/.*/w/p' > "${fifo}" &
#w_ID=$(xprop -root _NET_ACTIVE_WINDOW | sed -un 's/.* //p')
acpi_listen | acpi_entry &

# Avoid dmesg log and spy it
sudo dmesg -C && dmesg -wt | dmesg_entry &

# Get program title
window() {
	#title=$(xprop -id $w_ID WM_NAME | sed 's/.*= "//' | sed 's/"//')
	title=$(xdotool getactivewindow getwindowname || echo "ArchCuber")
}

# Get clock
clock() {
	c_date=$(date +'%a %d %b' | sed -e "s/\b\(.\)/\u\1/g")
	if [ $c_mode == "time" ]; then
		c_time=$(date +'%H:%M')
		c_bcolor="${white}"
		c_fcolor="${black}"
	else
		c_time="$(echo 0$((c_chrono/60%60)) | sed 's/0\(..\)/\1/'):$(echo 0$((c_chrono%60)) | sed 's/0\(..\)/\1/')"
		c_chrono=$((c_chrono+1))
		c_bcolor="${black}"
		c_fcolor="${white}"
	fi
	c="F${orange}}${left}%{B${orange} F${black}} ${date_icon} ${c_date} %{F${c_fcolor}}${left_light}%{B${orange} F${c_bcolor}}%{A:echo 'c_' > ${fifo}:}${left}%{B${c_bcolor} F${c_fcolor}} ${time_icon} ${c_time}%{A}"
}

# Get battery
battery() {
	b_level=$(cat /sys/class/power_supply/BAT0/capacity)
	
	if [ $b_level -le 20 ]; then
		b_bcolor="${red}"
		b_fcolor="${white}"
	elif [ $b_level -le 40 ]; then
		b_bcolor="${brown}"
		b_fcolor="${white}"
	elif [ $b_level -le 60 ]; then
		b_bcolor="${yellow}"
		b_fcolor="${black}"
	elif [ $b_level -le 80 ]; then
		b_bcolor="${green}"
		b_fcolor="${black}"
	elif [ $b_level -lt 100 ]; then
		b_bcolor="${blue}"
		b_fcolor="${white}"
	fi

	if [ $b_status == "Charging" ]; then
		b_icon="${charging_icon}"
	elif [ $b_status == "Full" ]; then
		b_bcolor="${violet}"
		b_fcolor="${white}"
		b_icon="${battery_full_icon}"
	elif [ $b_level -le 5 ]; then
		b_icon="${warning_icon}"
		systemctl suspend
	elif [ $b_level -le 10 ]; then
		b_icon="${warning_icon}"
	elif [ $b_level -le 25 ]; then
		b_icon="${battery_0_icon}"
	elif [ $b_level -le 50 ]; then
		b_icon="${battery_25_icon}"
	elif [ $b_level -le 75 ]; then
		b_icon="${battery_50_icon}"
	elif [ $b_level -lt 100 ]; then
		b_icon="${battery_75_icon}"
	else
		b_icon="${warning_icon}"
		b_bcolor="${black}"
		b_fcolor="${red}"
	fi

	b="F${b_bcolor}}${left}%{F${b_fcolor} B${b_bcolor}} ${b_icon} ${b_level}% %{F${b_fcolor}}${left_light}%{B${b_bcolor}"
}

# Get network
network() {
	ethernet_status=$(nmcli d | grep "ethernet" | awk '{ print $3 }')
	wifi_status=$(nmcli d | grep "wifi" | awk '{ print $3 }')
	wifi_ESSID=$(nmcli d | grep "wifi" | awk '{ print $NF }')
	wifi_quality=0
	ethernet_disconnected="0"
	n_bcolor="${red}"
	n_fcolor="${black}"
	n_icon=""

	if [ $wifi_status == "indisponible" ]; then
		n_bcolor="${white}"
		n_icon="${airplane_icon}"
		if [ $ethernet_status == "déconnecté" ]; then
			nmcli dev connect "${ethernet}" &
		fi
	
	elif [ $wifi_status == "déconnecté" ]; then
		n_bcolor="${black}"
		n_fcolor="${white}"
		if [ $ethernet_status != "connecté" ]; then
			n_icon="${disconnected_icon}"
		fi

		if [ $ethernet_status == "déconnecté" ]; then
			nmcli dev connect "${ethernet}" &
		fi

	elif [ $wifi_status == "connexion" ]; then
		n_bcolor="${orange}"
		n_icon="${wifi_icon}"
		if [ $ethernet_status == "connecté" ]; then
			nmcli dev disconnect "${ethernet}" &
		fi
		ethernet_disconnected="1"	

	elif [ $wifi_status == "connecté" ]; then
		n_icon="${wifi_icon}"
		wifi_quality=$((100*$(iwconfig "${wifi}" | grep "Link Quality" | sed "s/.*Link Quality=//" | sed "s/ .*//")))
		if [ $wifi_quality -ge 65 ]; then
			n_bcolor="${blue}"
			n_fcolor="${white}"
		elif [ $wifi_quality -ge 35 ]; then
			n_bcolor="${green}"
		else
			n_bcolor="${yellow}"
		fi

		if [ -z $n_ping ]; then
			n_ping="${warning_icon}"
		fi
	fi

	if [ $ethernet_status == "indisponible" ]; then
		if [ $wifi_status == "déconnecté" ]; then
			nmcli dev connect "${wifi}" &
		fi

		if [ $ethernet_disconnected == "1" ]; then
			ethernet_disconnected="2"
		fi

	elif [ $ethernet_status == "déconnecté" ]; then
		n_icon="${n_icon}${disconnected_icon}"
		if [ $wifi_status == "déconnecté" ]; then
			nmcli dev connect "${wifi}" &
		fi

		if [ $ethernet_disconnected == "2" ]; then
			nmcli dev connect "${ethernet}" &
			ethernet_disconnected="0"
		fi
	elif [ $ethernet_status == "connexion" ]; then
		n_bcolor="${orange}"
		n_icon="${n_icon}${ethernet_icon}"
	
	elif [ $ethernet_status == "connecté" ]; then
		n_bcolor="${blue}"
		n_fcolor="${white}"
		n_icon="${n_icon}${ethernet_icon}"
		if [ $wifi_status == "connecté" ]; then
			nmcli dev disconnect "${wifi}" &
		fi

		if [ -z $n_ping ]; then
			n_ping="${warning_icon}"
		fi
	else
		n_bcolor="${red}"
	fi

	n="F${n_bcolor}}${left}%{F${n_fcolor} B${n_bcolor}} ${n_icon}${n_ping} %{F${n_fcolor}}${left_light}%{B${n_bcolor}"
}


# Get Bluetooth info
bluetooth() {
	bl_name=$(hcitool dev | grep "${bluetooth}")

	if [ -z $bl_name ]; then
		bl_color="${red}"
		blight_icon="${bluetooth_off_icon}"
	else
		bl_color="${blue}"
		blight_icon="${bluetooth_on_icon}"
	fi

	bl="F${bl_color}}${left}%{F${white} B${bl_color}} ${blight_icon} %{F${white}}${left_light}%{B${bl_color}"
}


# Get brightness
light() {
	l_maxlevel=$(cat ${max_brightness_path})
	l_curlevel=$(cat ${brightness_path})
	l_level=$((100*$l_curlevel/$l_maxlevel))

	if [ $l_level -le 10 ]; then
		l_bcolor="${brown}"
		l_fcolor="${white}"
	elif [ $l_level -ge 90 ]; then
		l_bcolor="${violet}"
		l_fcolor="${white}"
	else
		l_bcolor="${white}"
		l_fcolor="${black}"
	fi

	l="F${l_bcolor}}%{A:${more_brightness} && echo 'l' > ${fifo}:}%{A3:${less_brightness} && echo 'l' > ${fifo}:}${left}%{F${l_fcolor} B${l_bcolor}} ${light_icon} ${l_level}% %{F${l_fcolor}}${left_light}%{A}%{A}%{B${l_bcolor}"
}


# Get Master Volume
volume() {
	v_level=$(pulsemixer --get-volume | awk '{ print $1 }')
	v_mute=$(pulsemixer --get-mute)

	if [ $v_mute == "1" ]; then
		v_bcolor="${red}"
		v_fcolor="${white}"
		v_icon="${volume_muted_icon}"
	elif [ $v_level -eq 150 ]; then
		v_bcolor="${violet}"
		v_fcolor="${white}"
		v_icon="${volume_high_icon}"
	elif [ $v_level -ge 100 ]; then
		v_bcolor="${white}"
		v_fcolor="${black}"
		v_icon="${volume_high_icon}"
	elif [ $v_level -ge 50 ]; then
		v_bcolor="${white}"
		v_fcolor="${black}"
		v_icon="${volume_normal_icon}"
	elif [ $v_level -gt 0 ]; then
		v_bcolor="${white}"
		v_fcolor="${black}"
		v_icon="${volume_low_icon}"
	else
		v_bcolor="${brown}"
		v_fcolor="${white}"
		v_icon="${volume_muted_icon}"
	fi

	if [ $v_status == "jack" ]; then
		v_icon="${headphones_icon}"
	fi

	v="F${v_bcolor}}%{A:pulsemixer --change-volume +5 && echo 'v' > ${fifo}:}%{A3:pulsemixer --change-volume -5 && echo 'v' > ${fifo}:}${left}%{F${v_fcolor} B${v_bcolor}} ${v_icon} ${v_level}% %{F${v_fcolor}}${left_light}%{A}%{A}%{B${v_bcolor}"
}

# Get workspace information
space() {
	s_workspaces=$(i3-msg -t get_workspaces | tr "," "\n" | grep '"name":"' | sed 's/"name":"\(.*\)"/\1/g')
	s_focused=$(i3-msg -t get_workspaces | tr "," "\n" | grep '"focused":' | sed 's/"focused":\(.*\)/\1/g' | tail)
	s_urgent=$(i3-msg -t get_workspaces | tr "," "\n" | grep '"urgent":' | sed 's/"urgent":\(.*\)}.*/\1/g' | tail)
	s_status=$(xrandr | grep ${hdmi} | sed "s/${hdmi} \(\w*\).*/\1/")
	index=0
	s_bcolor="${white}"

	echo "${s_workspaces}" > /tmp/w
	echo "${s_focused}" > /tmp/f
	echo "${s_urgent}" > /tmp/u

	for workspace_name in ${workspace_names[@]}; do
		s_bcolor_last=$s_bcolor
		s_fcolor="${white}"
		s_bcolor="${blue}"
		echo "${workspace_name}" > /tmp/t

		if [[ $s_workspaces == *$workspace_name* ]]; then
			if [[ $s_urgent == "true"* ]]; then
				s_fcolor="${black}"
				s_bcolor="${red}"
				s_urgent=$(echo ${s_urgent} | sed 's/true //')
			else
				s_fcolor="${black}"
				s_bcolor="${yellow}"
				s_urgent=$(echo ${s_urgent} | sed 's/false //')
			fi

			if [[ $s_focused == "true"* ]]; then
				s_fcolor="${black}"
				s_bcolor="${orange}"

				if [ $s_mode == "" ]; then
					workspace_name="${s_mode}"
					s_fcolor="${black}"
					s_bcolor="${red}"
				fi

				s_focused=$(echo ${s_focused} | sed 's/true //')
			else
				s_focused=$(echo ${s_focused} | sed 's/false //')
			fi
		fi

		if [ $index -eq 0 ]; then
			s="%{B${s_bcolor} F${s_fcolor}}%{A:i3-msg workspace '${workspace_name}' && echo 's' > ${fifo}:}%{F${s_bcolor_last}}${right}${right_light} %{F${s_fcolor}}${workspaces[${index}]} %{A}"
		elif [ $index -eq 10 ]; then
			if [ $s_status == "disconnected" ]; then
				s_fcolor="${red}"
				if [ $s_bcolor != $orange ]; then
					s_bcolor="${black}"
				fi
			elif [ $s_bcolor == $blue ]; then
				s_bcolor="${green}"
			fi	
			s="${s}%{B${s_bcolor} F${s_fcolor}}%{A:i3-msg workspace '${workspace_name}' && echo 's' > ${fifo}:}%{F${s_bcolor_last}}${right} %{F${s_fcolor}}${workspaces[${index}]} %{A}"
		else
			s="${s}%{B${s_bcolor} F${s_fcolor}}%{A:i3-msg workspace '${workspace_name}' && echo 's' > ${fifo}:}%{F${s_bcolor_last}}${right} %{F${s_fcolor}}${workspaces[${index}]} %{A}"
		fi
		index=$((${index}+1))
	done
	s="${s}%{F${s_bcolor}"
	echo "${s}" > /tmp/test
}

usb_mounted() {
	if [ -z $(pmount | grep "${u_name}") ]; then
		if [ $u_status == "Mounted" ]; then
			title="USB démontée"
		else
			title="USB connectée"
		fi

		u_status="Connected"
		if [ $u_speed == 3 ]; then
			u_bcolor="${orange}"
			u_fcolor="${black}"
		else
			u_bcolor="${yellow}"
			u_fcolor="${black}"
		fi

		if [ -z $(lsblk | grep "${u_name}[0-9]") ]; then
			u_command="pmount ${dev_path}/${u_name} && echo 'u' > ${fifo}"
		else
			u_command="pmount -D ${dev_path}/${u_name} && echo 'u' > ${fifo}"
		fi
	else		
		u_status="Mounted"
		if [ $u_speed == 3 ]; then
			u_bcolor="${violet}"
		else
			u_bcolor="${blue}"
		fi

		if [ -z $(lsblk | grep "${u_name}[0-9]") ]; then
			u_command="pumount ${dev_path}/${u_name} && echo 'u' > ${fifo}"
		else
			u_command="pumount -D ${dev_path}/${u_name} && echo 'u' > ${fifo}"
		fi

		title="USB montée"
	fi

	u="B${u_bcolor}}${right}%{F${u_fcolor}}${right_light} %{B${u_bcolor}}%{A:${u_command}:}${usb_icon} %{B${black} F${u_bcolor}}${right}%{B- F-}${right_light} %{A}"
}

# Get USB information /!\ Work only with one USB key
usb() {
	u_bcolor="${black}"
	u_fcolor="${white}"

	sleep 0.5

	if [ -z $u_id ]; then
		usb_mounted
	elif [ -z $(lsusb -s ${u_id}) ]; then
		if [ $u_status == "Mounted" ]; then
			u_bcolor="${red}"
			u="B${u_bcolor}}${right}%{F${u_fcolor}}${right_light} %{B${u_bcolor}}%{A:echo 'u' > ${fifo}:}${usb_icon} %{B${black} F${u_bcolor}}${right}%{B- F-}${right_light} %{A}"
			title="${warning_icon} USB déconnectée sans avoir été démontée"
		else
			u="B${u_bcolor}}${right}%{F${u_fcolor}}${right_light}"
			title="USB déconnectée"
		fi
		u_status="Disconnected"
	else
		sleep 1.5
		u_info=$(lsblk | grep "sd. " | tail -n -1)
		u_name=$(echo $u_info | awk '{ print $1 }')
		usb_mounted
	fi

}


while :; do
	echo "c_s" > "${fifo}"

	sleep 1
done &

while :; do
	n_ping=$(fping -e www.google.com | sed 's/.*(\(.*\))/\1/')
	if [ $n_ping == *"not known" ]; then
		n_ping=""
	fi

	echo "n_${n_ping}" > "${fifo}"
	echo "bl" > "${fifo}"

	sleep 2
done &

while :; do
	echo "reload" > "${fifo}"

	sleep 30
done &

u_id=""
u_speed=""
u="B${black}}${right}%{F${white}}${right_light}"

load() {
	b_status=$(cat /sys/class/power_supply/BAT0/status)
	n_ping=""
	c_mode="time"

	window
	battery
	clock
	network
	bluetooth
	light
	volume
	space
}

parser() {
	load

	while read -r line ; do
		case $line in
			c_s)
				clock
				space
			;;

			s)
				space
			;;

			s_)
				s_mode="normal"
				space
			;;

			s_*)
				s_mode=$(echo $line | sed 's/s_//')
				space
			;;

			w) 
				window
			;;

			b_Charging)
				b_status="Charging"
				battery
			;;

			b_Discharging)
				b_status="Discharging"
				battery
			;;

			b)
				battery
			;;

			c) 
				clock
			;;

			c_) 
				if [ $c_mode == "time" ]; then
					c_mode="chrono"
					c_chrono=0
				else
					c_mode="time"
				fi

				clock
			;;

			n_*)
				n_ping=$(echo $line | sed 's/n_/ /')
				network
			;;

			n) 
				network
			;;

			bl) 
				bluetooth
			;;

			l) 
				light
			;;

			v_jack)
				v_status="jack"
				volume
			;;

			v_normal)
				v_status="normal"
				volume
			;;

			v)
				volume
			;;

			reload)
				load
			;;

			u) 
				usb
			;;

			u_*) 
				u_speed=$(echo $line | sed 's/u_\(.\).*/\1/')
				u_id=$(echo $line | sed 's/.* \(.*\)/\1/')
				usb
			;;

			usb*error*)
				u_id=$(echo $line | sed 's/.*\([0-9]*\),.*/\1/')
				title="${warning_icon} Erreur USB détectée (numéro ${id})"
			;;

			*)
				title="Erreur"
			;;
		esac
		echo -e "%{c}%{F${white} B${black}} %{A3:i3-msg kill:}${title}%{A} %{l}%{B${white} F${black}}%{A:oblogout:}  %{B- F-}%{A}${s} ${u} %{r}${left_light}%{B- ${v} ${l} ${bl} ${n} ${b} ${c}  %{B- F-}"
	done
}


cat "${fifo}" | parser | lemonbar -p -F "${white}" -B "${black}" -f 'Source Code Pro-9' -f 'Source Code Pro-10' -f 'FontAwesome-11' | bash

wait
