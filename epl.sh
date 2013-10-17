#!/usr/bin/env bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:$PATH

#****************************************************************************
#*   Easy Process Locker (epl)                                              *
#*   Easily create and manage a lockfile for any script or program          *
#*                                                                          *
#*   Copyright (C) 2013 by Jeremy Falling except where noted.               *
#*                                                                          *
#*   This program is free software: you can redistribute it and/or modify   *
#*   it under the terms of the GNU General Public License as published by   *
#*   the Free Software Foundation, either version 3 of the License, or      *
#*   (at your option) any later version.                                    *
#*                                                                          *
#*   This program is distributed in the hope that it will be useful,        *
#*   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
#*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
#*   GNU General Public License for more details.                           *
#*                                                                          *
#*   You should have received a copy of the GNU General Public License      *
#*   along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
#****************************************************************************
OPT_C=""
OPT_E=0


usage()
{
cat << EOF

Usage: $0  [-e] -c 'command you want to run with arguments'
Example: $0 -e -c '/usr/bin/who -a'

options:

    -e	exit when there is an orphaned pid found
    -c  command to run (required)
    -h	display this message

EOF
 
}

while getopts ":ec:" FLAG
do
	case $FLAG in
        c)
            OPT_C=${OPTARG}
            ;;
        e)
            OPT_E=1
            ;;
        *  )
        	usage 
        	exit 1
        	;;
    esac
done



##if there is no $1 or if > 1 args, throw error
if [ "$OPT_C" == "" ]; then
	echo ""
	echo "ERROR: You must supply -c with the command(s) to run in quotes!"
	echo ""
	usage
	exit 1
	
#elif [ "$#" -gt 1 ]; then
#	echo ""
#	echo "ERROR: You must only supply one argument and it must be in quotes!"
#	echo ""
#	echo "Usage: $0 'command you want to run with arguments'"
#	echo "Example: $0 '/usr/bin/who -a'"
#	echo ""
#	exit 1

fi


#get the full and short command names, and the arguments, 
fullcommand=`echo $OPT_C | awk -F" " '{print $1}'`
command=`echo $fullcommand | rev | cut -d/ -f1 | rev`
arguments=`echo ${OPT_C#${fullcommand}}`

#now generate a unique name based on the command and arguments (alpha-numeric plus _ - = . only) as to prevent some nasty things
uniqueName=`echo "$command _ $arguments" | sed 's/[^a-zA-Z0-9_.=-]//g'`


if [ -f "/tmp/$uniqueName.lock" ];then

	#the lock file already exists, so check to see if the pid is valid
	if [ "$(ps -p `cat /tmp/$uniqueName.lock` | wc -l)" -gt 1 ];then

		#the another instance of the requested job is running, throw error
		echo "$0: ERROR the backup script is already running and I cannot run another copy! lingering process `cat /tmp/$uniqueName.lock`"
		exit 1

	else

		#process not running, but lock file not deleted.
		
		#did user want us to exit on this condition? yes, exit
		if [ "$OPT_E" -ne 0 ]; then
			echo " $0: ERROR orphan lock was found! Exiting per flags given..."
			exit 1

		#no, print an message, delete the lock, and continue
		else
		
			echo " $0: WARNING: orphan lock file has been deleted."
			rm -f "/tmp/$uniqueName.lock"
			if [ "$?" -ne 0 ]; then
			{
				echo "ERROR: Could not remove orphaned lockfile /tmp/$uniqueName.lock"
				exit 1
			}
			fi
		fi


	fi

fi


#create lock file
echo $$ > "/tmp/$uniqueName.lock"
if [ "$?" -ne 0 ]; then
{
	echo "ERROR: Could not create lockfile /tmp/$uniqueName.lock"
	exit 1
}
fi

#run the requested command here. Using eval to allow ; and &&
eval $OPT_C

#remove the lock file
rm "/tmp/$uniqueName.lock"
if [ "$?" -ne 0 ]; then
{
	echo "ERROR: Could not remove lockfile /tmp/$uniqueName.lock"
	exit 1
}
fi
