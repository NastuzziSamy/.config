#!/bin/bash

# Detect if it's already launched. Stop lemonbar if launched
if [ $(pgrep -cx $(basename $0)) -gt 1 ] ; then
	killall -g /bin/bash
fi


# Variables
. ~/Documents/ressources/colors
. ~/Documents/ressources/devices
. ~/Documents/ressources/paths
. ~/Documents/ressources/separators
. ~/Documents/ressources/icons
. ~/Documents/ressources/workspaces

fifo_bar='/tmp/lemonbar'
max_title=100


# Creation of the fifo_bar file
[ -e $fifo_bar ] && rm -Rf $fifo_bar
mkfifo $fifo_bar


# Moduls
. $(dirname $0)/clock.sh
. $(dirname $0)/network.sh
. $(dirname $0)/workspace.sh
. $(dirname $0)/volume.sh
. $(dirname $0)/battery.sh
. $(dirname $0)/usb.sh
. $(dirname $0)/light.sh
. $(dirname $0)/bluetooth.sh


# Manage ACPI information
acpi_entry() {
	while read -r info ; do
		case $info in
			button/wlan*)
				echo 'n_' > $fifo_bar
			;;

			button/*)
				echo 'v' > $fifo_bar
			;;

			video*)
				echo 'l' > $fifo_bar
			;;

			ac_adapter*)
				sleep 1;
				echo 'b' > $fifo_bar
			;;
			battery*)
				sleep 1;
				echo 'b' > $fifo_bar
			;;

			jack/headphone*)
				if [ $(echo $info | sed 's/.* //') == 'plug' ]; then
					echo 'v_1' > $fifo_bar
				else
					echo 'v_0' > $fifo_bar
				fi
			;;

		esac
	done
}


# Manage dmesg information
dmesg_entry() {
	while read -r info ; do
		case $info in
			*$wifi*by*)
				echo 'n' > $fifo_bar
			;;
			*$ethernet*)
				echo 'n' > $fifo_bar
			;;

			Restarting*) # Reload everything when the system restart
				echo 'reload' > $fifo_bar
			;;

			'usb '*) # Detect the usb key
				if [[ $info != *'full-speed'* && $info != 'usb 1'* ]]; then
					echo $info | sed 's/usb \(.\)-[0-9]*: .*number \([0-9]*\).*/u_\1 \2/' > $fifo_bar
				fi
			;;

		esac
	done
}


# Spy changement
# Spy windows - Useless because lemonbar is all time reloaded
#xprop -spy -root _NET_ACTIVE_WINDOW | sed -un 's/.*/t/p' > $fifo_bar &
# Listen ACPI
acpi_listen | acpi_entry &
# Avoid dmesg log and spy it
sudo dmesg -C && dmesg -wt | dmesg_entry &


while :; do
	echo 'c_w' > $fifo_bar

	sleep 1
done &

while :; do
	if [ $n_ping -eq 0 ]; then
		n_info=''
	else
		n_info=$(fping -e www.google.com | tail -n 1 | sed 's/.*\((.*)\)/\1/' | sed 's/(\(.*\))/\1/' | sed "s/.*www.google.com.*//")
		#n_info=$(ping -W 500 -c 1 www.google.com | grep 'time=' | sed 's/.*time=//')
	fi

	echo 'n_'$n_info > $fifo_bar

	sleep 2.5
done &

while :; do
	echo 'reload' > $fifo_bar

	sleep 60
done &


load() {
	workspace &
	network &
	battery
	clock
	bluetooth
	light
	volume
}


parser() {
	load

	while read -r info ; do
		title=$(xdotool getactivewindow getwindowname || echo 'ArchCuber')

		case $info in
			c_w)
				clock
				workspace &
			;;

			info_w_*)
				w=$(echo $info | sed 's/info_w_//')' '
			;;

			w)
				workspace &
			;;

			w_)
				w_mode=''
				workspace &
			;;

			w_*)
				w_mode=$(echo $info | sed 's/w_//')
				workspace &
			;;

			n_toogle)
				if [ $n_ping -eq 0 ]; then
					n_ping=1
				else 
					n_ping=0
				fi
				network &
			;;

			n_*)
				n_info=$(echo $info | sed 's/n_/ /')
				network &
			;;

			info_n_*)
				n=$(echo $info | sed 's/info_n_//')' '
			;;

			n_)
				n_info=''
				network &
			;;

			n) 
				network &
			;;

			bl) 
				bluetooth
			;;

			l) 
				light
			;;

			v)
				volume
			;;

			v_1)
				v_jacked=1
				volume
			;;

			v_0)
				v_jacked=0
				volume
			;;

			reload)
				load
			;;

			u) 
				usb
			;;

			u_*) 
				u_speed=$(echo $info | sed 's/u_\(.\).*/\1/')
				u_id=$(echo $info | sed 's/.* \(.*\)/\1/')
				usb
			;;

			usb*error*)
				u_id=$(echo $info | sed 's/.* \(.*\)/\1/')
				title=$warning_icon' Erreur USB détectée (numéro '$id')'
			;;

			b)
				battery
			;;
			b_toogle)
				if [ $b_time -eq 0 ]; then
					b_time=1
				else 
					b_time=0
				fi

				battery
			;;

			c_format) 
				if [ $c_format -eq 0 ]; then
					c_format=1
				else
					c_format=0
				fi

				clock
			;;

			c_toogle) 
				if [ $c_mode -eq 0 ]; then
					c_mode=1
				else
					c_mode=0
				fi

				clock
			;;

			c_reset) 
				c_chrono=0
			;;

			info_)
				title=$(echo $info | sed 's/info_//')
			;;

			error_)
				title=$(echo $error | sed 's/info_/'$warning_icon' /')
			;;

			*)
				title='Erreur: '$info
			;;
		esac

		if [ ${#title} -gt $max_title ]; then
			title=$(echo $title | cut -c 1-$max_title | sed 's/[ -]* [^ ]*$//')
		fi

		echo '%{+u}%{c}%{F'$white' B'$black'} %{A3:i3-msg kill:}'$title'%{A} %{-u}%{l}%{B'$white' F'$black'}%{A:oblogout:}  %{B- F-}%{A}'$w' B#FF383C4A}'$right'%{O2}%{F#FF383C4A B-}'$right$right_light' %{r}%{F#FF383C4A}'$left_light$left'%{B#FF383C4A}%{O2}%{'$v$l$n$b$c' %{B- F-}'
	done
}


tail -f $fifo_bar | parser | lemonbar -p -F $white -B $black -U '#FF383C4A' -u 2 -f 'Source Code Pro-9' -f 'Source Code Pro-10' -f 'FontAwesome-11' | bash

wait
