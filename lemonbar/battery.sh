# Initialisation
b_status=$(cat $battery_path'/status')	
b_time=0

# Get battery
battery() {
	b_info=$(cat $battery_path'/capacity')

	if [ $b_info -le 20 ]; then
		b_bcolor=$red
		b_fcolor=$white
	elif [ $b_info -le 40 ]; then
		b_bcolor=$brown
		b_fcolor=$white
	elif [ $b_info -le 60 ]; then
		b_bcolor=$yellow
		b_fcolor=$black
	elif [ $b_info -le 80 ]; then
		b_bcolor=$green
		b_fcolor=$black
	elif [ $b_info -lt 100 ]; then
		b_bcolor=$blue
		b_fcolor=$white
	else
		b_bcolor=$violet
		b_fcolor=$white
	fi

	if [ $b_info -eq 100 ]; then
		b_icon=$battery_full_icon
		b_time=$0
	elif [ $b_status == 'Charging' ]; then
		b_icon=$charging_icon
	elif [ $b_info -le 5 ]; then
		b_icon=$warning_icon
		systemctl suspend
	elif [ $b_info -le 10 ]; then
		b_icon=$warning_icon
	elif [ $b_info -le 25 ]; then
		b_icon=$battery_0_icon
	elif [ $b_info -le 50 ]; then
		b_icon=$battery_25_icon
	elif [ $b_info -le 75 ]; then
		b_icon=$battery_50_icon
	elif [ $b_info -lt 100 ]; then
		b_icon=$battery_75_icon
	else
		b_icon=$warning_icon
		b_bcolor=$black
		b_fcolor=$red
	fi

	if [ $b_time -eq 1 ]; then
		b_info=$(acpi -b | sed 's/.* \(.*\):.*/\1/')
	else
		b_info+='%'
	fi

	b='F'$b_bcolor'}%{A:echo "b_toogle" > '$fifo_bar':}'$left'%{F'$b_fcolor' B'$b_bcolor'} '$b_icon' '$b_info' %{F'$b_fcolor'}'$left_light'%{A}%{B'$b_bcolor' '
}