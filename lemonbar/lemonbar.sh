#!/bin/bash

# Detect if it's already launched. Stop lemonbar if launched
if [ $(pgrep -cx $(basename $0)) -gt 1 ] ; then
	killall -g /bin/bash
fi


# Variables
. ~/ressources/colors
. ~/ressources/devices
. ~/ressources/paths
. ~/ressources/separators
. ~/ressources/icons
. ~/ressources/workspaces

fifo_bar='/tmp/lemonbar'


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
	while read -r line ; do
		case $line in
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
				echo 'b_0' > $fifo_bar
			;;
			battery*)
				echo 'b_1' > $fifo_bar
			;;

			jack/headphone*)
				if [ $(echo $line | sed 's/.* //') == 'plug' ]; then
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
	while read -r line ; do
		case $line in
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
				if [[ $line != *'full-speed'* && $line != 'usb 1'* ]]; then
					echo $line | sed 's/usb \(.\)-[0-9]*: .*number \([0-9]*\).*/u_\1 \2/' > $fifo_bar
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
		n_info=$(fping -e www.google.com | tail -n 1 | sed 's/.*\((.*)\)/\1/' | sed 's/(\(.*\))/\1/')
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
	battery
	clock
	network &
	bluetooth
	light
	volume
}


parser() {
	load

	while read -r line ; do
		title=$(xdotool getactivewindow getwindowname || echo 'ArchCuber')

		case $line in
			c_w)
				clock
				workspace &
			;;

			info_w_*)
				w=$(echo $line | sed 's/info_w_//')' '
			;;

			w)
				workspace &
			;;

			w_)
				w_mode=''
				workspace &
			;;

			w_*)
				w_mode=$(echo $line | sed 's/w_//')
				workspace &
			;;

			n_toogle)
				if [ $n_ping -eq 0 ]; then
					n_ping=1
				else 
					n_ping=0
				fi
				network
			;;

			n_*)
				n_info=$(echo $line | sed 's/n_/ /')
				network &
			;;

			info_n_*)
				n=$(echo $line | sed 's/info_n_//')' '
			;;

			n_)
				n_info=''
				network
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

			b_1)
				b_status='Charging'
				battery
			;;

			b_0)
				b_status='Discharging'
				battery
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
				u_id=$(echo $line | sed 's/.* \(.*\)/\1/')
				title=$warning_icon' Erreur USB détectée (numéro '$id')'
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
					c_chrono=0
				else
					c_mode=0
				fi

				clock
			;;

			*)
				title='Erreur: '$line
			;;
		esac

		echo '%{c}%{F'$white' B'$black'} %{A3:i3-msg kill:}'$title'%{A} %{l}%{B'$white' F'$black'}%{A:oblogout:}  %{B- F-}%{A}'$w$u' %{r}'$left_light'%{B- '$v$l$bl$n$b$c' %{B- F-}'
	done
}


tail -f $fifo_bar | parser | lemonbar -p -F $white -B $black -f 'Source Code Pro-9' -f 'Source Code Pro-10' -f 'FontAwesome-11' | bash

wait
