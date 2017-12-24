# Initialisation
w_mode='normal'

# Get workspace information
workspace() {
	w_i3=$(i3-msg -t get_workspaces)
	w_workspaces=$(echo $w_i3 | tr ',' '\n' | grep '"name":"' | sed 's/"name":"\(.*\)"/\1/g')
	w_focused=$(echo $w_i3 | tr ',' '\n' | tr ',' '\n' | grep '"focused":' | sed 's/"focused":\(.*\)/\1/g' | tail)
	w_urgent=$(echo $w_i3 | tr ',' '\n' | tr ',' '\n' | grep '"urgent":' | sed 's/"urgent":\(.*\)}.*/\1/g' | tail)
	w_status=$(xrandr | grep HDMI-1 | sed 's/HDMI-1 \(\w*\).*/\1/')
	w_sound=$(pacmd list-sink-inputs | grep 'state\|application.name =' | tr '\n' ' ' | sed 's/\s*state: \(\S*\)\s*application.name = "\([a-zA-Z]*\)[" ]\s*/(\2 \1)/g')
	if [ $w_status != 'connected' ]; then
		w_status=$(xrandr | grep HDMI-1 | sed 's/HDMI-1 \(\w*\).*/\1/')
	fi

	index=0
	w_bcolor=$white

	for workspace_name in ${workspace_names[@]}; do
		w_bcolor_last=$w_bcolor
		w_fcolor=$white
		w_bcolor=$blue

		w_icon="%{O7}${workspaces[${index}]}%{O7}"

		if [[ $w_workspaces == *$workspace_name* ]]; then
			if [[ $w_urgent == 'true'* ]]; then
				w_fcolor=$white
				w_bcolor=$red
				w_urgent=$(echo $w_urgent | sed 's/true //')
			else
				w_fcolor=$black
				w_bcolor=$yellow
				w_urgent=$(echo $w_urgent | sed 's/false //')
			fi

			if [[ $w_focused == 'true'* ]]; then
				w_fcolor=$black
				w_bcolor=$orange

				if [ $w_mode == '' ]; then
					w_icon='%{O15}%{O15}'
					w_fcolor=$white
					w_bcolor=$red
				fi

				w_focused=$(echo $w_focused | sed 's/true //')
				w_ws_focused=$workspace_name
			else
				w_focused=$(echo $w_focused | sed 's/false //')
			fi
		fi

		if [ $index -eq 0 ]; then
			w='%{B'$w_bcolor' F'$w_fcolor'}%{A:i3-msg workspace "'$workspace_name'" && echo "w" > '$fifo_bar':}%{F'$w_bcolor_last'}'$right$right_light'%{F'$w_fcolor'}'$w_icon'%{A}'
		elif [ $index -eq 10 ]; then
			if [ "$w_status" == 'disconnected' ]; then
				if [ $w_bcolor != $orange ]; then
					w_bcolor=$red
					w_fcolor=$white
				else
					w_fcolor=$red
				fi
			elif [[ $w_workspaces == *'out'* ]]; then
				w_bcolor=$orange
				xrandr --output HDMI-1 --primary --pos 136x30 --rotate normal --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal && xinput --map-to-output 11 eDP-1
			elif [ $w_bcolor == $yellow ]; then
				w_bcolor=$blue
				w_color=$white
				xrandr --output HDMI-1 --pos 1920x30 --rotate normal --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal && xinput --map-to-output 11 eDP-1
				feh --bg-scale ~/images/background.png
			else
				i3-msg workspace out
				xrandr --output HDMI-1 --primary --pos 136x30 --rotate normal --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal && xinput --map-to-output 11 eDP-1
				i3-msg workspace +
			fi	
			w+='%{B'$w_bcolor' F'$w_fcolor'}%{A:i3-msg workspace "'$workspace_name'" && echo "w" > '$fifo_bar':}%{F'$w_bcolor_last'}'$right'%{F'$w_fcolor'}'$w_icon'%{A}'
		else
			if [ $index -eq 2 ]; then
				if [[ $w_sound == *'(CubebUtils RUNNING)'* ]]; then
					if [ $w_bcolor == $orange ]; then
						w_bcolor=$brown
					else
						w_bcolor=$violet
					fi
				fi
			elif [ $index -eq 7 ]; then
				if [[ $w_sound == *'(VLC RUNNING)'* ]]; then
					if [ $w_bcolor == $orange ]; then
						w_bcolor=$brown
					else
						w_bcolor=$violet
					fi
				fi
			elif [ $index -eq 8 ]; then
				if [[ $w_sound == *'(Audacious RUNNING)'* ]]; then
					if [ $w_bcolor == $orange ]; then
						w_bcolor=$brown
					else
						w_bcolor=$violet
					fi
				fi
			fi
			w+='%{B'$w_bcolor' F'$w_fcolor'}%{A:i3-msg workspace "'$workspace_name'" && echo "w" > '$fifo_bar':}%{F'$w_bcolor_last'}'$right'%{F'$w_fcolor'}'$w_icon'%{A}'
		fi
		index=$((${index}+1))
	done
	echo 'info_w_'$w'%{F'$w_bcolor > $fifo_bar
}
