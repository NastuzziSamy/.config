# Initialisation
v_jacked=0

# Get Master Volume
volume() {
	v_level=$(pulsemixer --get-volume | awk '{ print $1 }')
	v_muted=$(pulsemixer --get-mute)

	if [ $v_muted == '1' ]; then
		v_bcolor=$red
		v_fcolor=$white
		v_icon=$volume_muted_icon
	elif [ $v_level -eq 150 ]; then
		v_bcolor=$violet
		v_fcolor=$white
		v_icon=$volume_high_icon
	elif [ $v_level -ge 100 ]; then
		v_bcolor=$white
		v_fcolor=$black
		v_icon=$volume_high_icon
	elif [ $v_level -ge 50 ]; then
		v_bcolor=$white
		v_fcolor=$black
		v_icon=$volume_normal_icon
	elif [ $v_level -gt 0 ]; then
		v_bcolor=$white
		v_fcolor=$black
		v_icon=$volume_low_icon
	else
		v_bcolor=$brown
		v_fcolor=$white
		v_icon=$volume_muted_icon
	fi

	if [ $v_jacked -eq 1 ]; then
		v_icon=$headphones_icon
	fi

	v='F'$v_bcolor'}%{A:pulsemixer --change-volume +5 && echo "v" > '$fifo_bar':}%{A3:pulsemixer --change-volume -5 && echo "v" > '$fifo_bar':}'$left'%{F'$v_fcolor' B'$v_bcolor'} '$v_icon' '$v_level'% %{F'$v_fcolor'}'$left_light'%{A}%{A}%{B'$v_bcolor' '
}