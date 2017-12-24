# Get brightness
light() {
	l_maxlevel=$(cat $max_brightness_path)
	l_curlevel=$(cat $brightness_path)
	l_level=$((100*$l_curlevel/$l_maxlevel))

	if [ $l_level -eq 0 ]; then
		l_bcolor=$brown
		l_fcolor=$white
		# xgamma -rgamma 0.1 ?
	elif [ $l_level -eq 100 ]; then
		l_bcolor=$violet
		l_fcolor=$white
	else
		l_bcolor=$white
		l_fcolor=$black
	fi

	l='F'$l_bcolor'}%{A:'$more_brightness' && echo "l" > '$fifo_bar':}%{A3:'$less_brightness' && echo "l" > '$fifo_bar':}'$left'%{F'$l_fcolor' B'$l_bcolor'} '$light_icon' '$l_level'% %{F'$l_fcolor'}'$left_light'%{A}%{A}%{B'$l_bcolor' '
}