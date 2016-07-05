# Initialisation
c_mode=0
c_format=0

# Get clock
clock() {
	if [ $c_format -eq 0 ]; then
		c_date=$(date +'%a %d %b' | sed -e 's/\b\(.\)/\u\1/g')
	else
		c_date=$(date +'%W/%m/%Y')
	fi

	if [ $c_mode -eq 0 ]; then
		c_time=$(date +'%R')
		#c_time=$(date +'%I:%M')
		c_bcolor=$white
		c_fcolor=$black
	else
		c_time=$(echo 0$((c_chrono/60%60)) | sed 's/0\(..\)/\1/'):$(echo 0$((c_chrono%60)) | sed 's/0\(..\)/\1/')
		c_chrono=$((c_chrono+1))
		c_bcolor=$black
		c_fcolor=$white
	fi

	#if [ $(date +'%H') -lt 12 ]; then
	#	c='F'$orange'}%{A:echo "c_format" > '$fifo_bar':}'$left'%{B'$orange' F'$black'} '$date_icon' '$c_date' %{A}%{F'$c_fcolor'}'$left_light'%{B'$orange' F'$c_bcolor'}%{A:echo "c_toogle" > '$fifo_bar':}'$left'%{B'$c_bcolor' F'$c_fcolor'} '$time_AM_icon' '$c_time' %{A}'
	#else
		c='F'$orange'}%{A:echo "c_format" > '$fifo_bar':}'$left'%{B'$orange' F'$black'} '$date_icon' '$c_date' %{A}%{F'$c_fcolor'}'$left_light'%{B'$orange' F'$c_bcolor'}%{A:echo "c_toogle" > '$fifo_bar':}'$left'%{B'$c_bcolor' F'$c_fcolor'} '$time_icon' '$c_time' %{A}'
	#fi
}