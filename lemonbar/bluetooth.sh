# Get Bluetooth info
bluetooth() {
	bl_name=$(hcitool dev | grep $bluetooth)

	if [ -z "${bl_name}" ]; then
		bl_color=$red
		bl_icon=$bluetooth_off_icon
	else
		bl_color=$blue
		bl_icon=$bluetooth_on_icon
	fi

	bl='F'$bl_color'}'$left'%{F'$white' B'$bl_color'} '$bl_icon' %{F'$white'}'$left_light'%{B'$bl_color' '
}