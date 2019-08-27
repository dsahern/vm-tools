# convert NICs to new model

. /etc/vm-tools.conf

function update_profile
{
	local file=$1
	local filenew=$file.new

	. $file
	p=${file##*/}
	p=${p/\.dat/}

	if [ -n "$NICS" ]
	then
		echo "Nothing to do for $p"
		return
	fi

	NETORDER=${NETORDER:="main none host"}
	local model=${VMNICMODEL:=$NICMODEL}

	local NICS
	for n in $NETORDER
	do
    	if [ "$n" = "main" -a "$VMMAINBR" != "no" ]
		then
			NICS="$NICS main,$VMMAINBR,$model"
    	elif [ "$n" = "host" -a "$VMHOSTBR" != "no" ]
		then
			NICS="$NICS host,$VMHOSTBR,$model"
    	elif [ "$n" = "none" -a "$VMNOBR" != "no" ]
		then
			NICS="$NICS ,$VMNOBR,$model"
		fi
	done

	if [ -z "$NICS" ]
	then
		echo "No network devices for $p"
		return
	fi


	local line
	local tok
	while read line
	do
		tok=${line//=*}
		if [ "$tok" = "VMNICMODEL" -o \
		     "$tok" = "VMMAINBR"   -o \
		     "$tok" = "VMHOSTBR"   -o \
		     "$tok" = "VMNOBR"     -o \
		     "$tok" = "NETORDER" ]
		then
			continue
		fi

		if [ "$tok" = "VMDISKMODEL" ]
		then
			echo "VMNICS=\"${NICS/^ /}\""
			echo
		fi

		echo "$line"

	done < $file > $filenew

	grep -q "VMNICS=" $filenew
	if [ $? -ne 0 ]
	then
		echo "VMNICS=\"${NICS/^ /}\"" >> $filenew
	fi

	chown --reference=$file $filenew
	mv $filenew $file

	echo "$p updated"
}

################################################################################
#
# main

for p in $VM_DIR/*.dat
do
	unset VMNICMODEL
	unset VMMAINBR
	unset MHOSTBR
	unset VMNOBR
	unset NETORDER
	unset NICS

	update_profile $p
done

