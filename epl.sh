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


#check for help flags
if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "?" ] || [ "$1" == "--h" ]|| [ "$1" == "-help" ]; then
	echo ""
	echo "Usage: $0 'command you want to run with arguments'"
	echo "Example: $0 /usr/bin/who -a"
	echo ""
	exit 0
	
fi

#if there is no $1 or if > 1 args, throw error
if [ -z "$1" ]; then
	echo ""
	echo "ERROR: You must supply one argument in quotes with the command to run!"
	echo ""
	echo "Usage: $0 'command you want to run with arguments'"
	echo "Example: $0 /usr/bin/who -a"
	echo ""
	exit 1
	
elif [ "$#" -gt 1 ]; then
	echo ""
	echo "ERROR: You must only supply one argument and it must be in quotes!"
	echo ""
	echo "Usage: $0 'command you want to run with arguments'"
	echo "Example: $0 '/usr/bin/who -a'"
	echo ""
	exit 1
	
fi


#get the full and short command names, and the arguments, 
fullcommand=`echo $1 | awk -F" " '{print $1}'`
command=`echo $fullcommand | rev | cut -d/ -f1 | rev`
arguments=`echo ${1#${fullcommand}}`

#now generate a unique name based on the command and arguments (alpha-numeric plus _ - = . only) as to prevent some nasty things
uniqueName=`echo "$command _ $arguments" | sed 's/[^a-zA-Z0-9_.=-]//g'`


if [ -f "/tmp/$uniqueName.lock" ];then

	#the lock file already exists, so check to see if the pid is valid
	if [ "$(ps -p `cat /tmp/$uniqueName.lock` | wc -l)" -gt 1 ];then

		#the another instance of the requested job is running, throw error
		echo "$0: ERROR the backup script is already running and I cannot run another copy! lingering process `cat /tmp/$uniqueName.lock`"
		exit 1

	else

		#process not running, but lock file not deleted? print an message, delete the lock, and continue
		echo " $0: orphan lock file warning. Lock file deleted."
		rm -f "/tmp/$uniqueName.lock"
		if [ "$?" -ne 0 ]; then
		{
			echo "ERROR: Could not remove orphaned lockfile /tmp/$uniqueName.lock"
			exit 1
		}
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

#run the requested command here
$1

#remove the lock file
rm "/tmp/$uniqueName.lock"
if [ "$?" -ne 0 ]; then
{
	echo "ERROR: Could not remove lockfile /tmp/$uniqueName.lock"
	exit 1
}
fi
