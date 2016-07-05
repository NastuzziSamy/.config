# Initialisation
u='B'$black'}'$right'%{F'$white'}'$right_light
u_id='null'
# Know if the device is mounted
usb_mounted() {
	if [ -z $(pmount | grep $u_name) ]; then
		if [ $u_status == 'Mounted' ]; then
			title='USB démontée'
		else
			title='USB connectée'
		fi

		u_status='Connected'
		if [ $u_speed == 3 ]; then
			u_bcolor=$orange
			u_fcolor=$black
		else
			u_bcolor=$yellow
			u_fcolor=$black
		fi

		if [ -z $(lsblk | grep $u_name'[0-9]') ]; then
			u_command='pmount '$dev_path'/'$u_name' && echo "u" > '$fifo_bar
		else
			u_command='pmount -D '$dev_path'/'$u_name' && echo "u" > '$fifo_bar
		fi
	else		
		u_status='Mounted'
		if [ $u_speed == 3 ]; then
			u_bcolor=$violet
		else
			u_bcolor=$blue
		fi

		if [ -z $(lsblk | grep $u_name'[0-9]') ]; then
			u_command='pumount '$dev_path'/'$u_name' && echo "u" > '$fifo_bar
		else
			u_command='pumount -D '$dev_path'/'$u_name' && echo "u" > '$fifo_bar
		fi

		title='USB montée'
	fi

	u='B'$u_bcolor'}'$right'%{F'$u_fcolor'}'$right_light' %{B'$u_bcolor'}%{A:'$u_command':}'$usb_icon' %{B'$black' F'$u_bcolor'}'$right'%{B- F-}'$right_light' %{A}'
}

# Get USB information /!\ Work only with one USB key
usb() {
	u_bcolor=$black
	u_fcolor=$white

	sleep 0.5

	if [ $u_id == 'null' ]; then
		sleep 0
	elif [ -z "${u_id}" ]; then
		usb_mounted
	elif [ -z $(lsusb -s $u_id) ]; then
		if [ $u_status == Mounted ]; then
			u_bcolor=$red
			u='B'$u_bcolor'}'$right'%{F'$u_fcolor'}'$right_light' %{B'$u_bcolor'}%{A:echo "u" > '$fifo_bar':}'$usb_icon' %{B'$black' F'$u_bcolor'}'$right'%{B- F-}'$right_light' %{A}'
			title=$warning_icon' USB déconnectée sans avoir été démontée'
		else
			u='B'$u_bcolor'}'$right'%{F'$u_fcolor'}'$right_light
			title='USB déconnectée'
		fi
		u_status='Disconnected'
	else
		sleep 1.5
		u_info=$(lsblk | grep 'sd. ' | tail -n -1)
		u_name=$(echo $u_info | awk '{ print $1 }')
		usb_mounted
	fi
}