exec &>> creation.log

echo "start"
echo $(date -u)

echo "|================ RUN ================="
echo "|================ RUN ================="
echo "|================ RUN ================="
echo "|================ RUN ================="
echo "|================ RUN ================="
echo "|================ RUN ================="

#input
SERVER='server-linux-x64-web'
COMMIT_ID='3d5b2fecf2e6788cb9877d7d868d964fbc3ecd53'
UUID='3d5b2fecf2e6788cb9877d7d868d964fbc3ecd53'
QUALITY='insider'
EXTENSIONS=''
echo "|================ vscode-install.sh Arguments ================="
echo "|     SERVER: $SERVER"
echo "|  COMMIT_ID: $COMMIT_ID"
echo "|       UUID: $UUID"
echo "|    QUALITY: $QUALITY"
echo "| EXTENSIONS: $EXTENSIONS"
echo "|=============================================================="
#setup
VSCH_HOME="$HOME"
VCSH_TAR="vscode-$SERVER.tar.gz"
VSCH_BIN_DIR="$VSCH_HOME/.vscode-remote/bin"
VSCH_DIR="$VSCH_BIN_DIR/$COMMIT_ID"
VSCH_LOGFILE="$VSCH_HOME/.vscode-remote/.$COMMIT_ID.log"
if [ ! -d "$VSCH_DIR" ]; then
	mkdir -p $VSCH_DIR
fi

## Copyright (C) 2009 Przemyslaw Pawelczyk <przemoc@gmail.com>
## This script is licensed under the terms of the MIT license.
## https://opensource.org/licenses/MIT

get_lockfile() {
	echo "$VSCH_DIR/vscode-remote-lock.$1"
}

# PRIVATE
_lock()             { flock -$1 $2; }
_no_more_locking()  { _lock u $2; _lock xn $2 && rm -f $(get_lockfile $1); }
_prepare_locking()  { eval "exec $2>\\"$(get_lockfile $1)\\""; trap "_no_more_locking $1 $2" EXIT; }
# PUBLIC - all take lock FD
exlock_now()        { _lock xn $1; }  # obtain an exclusive lock immediately or fail
exlock()            { _lock x $1; }   # obtain an exclusive lock
shlock()            { _lock s $1; }   # obtain a shared lock
unlock()            { _lock u $1; }   # drop a lock

LOCKFD=99
CLEANUP_LOCKFD=98
_prepare_locking $COMMIT_ID $LOCKFD

if (( $? > 0 ))
then
	echo "Installation already in progress..."
	echo "$UUID##24##$UUID"
	exit 0
fi

# Keep the newest 5 servers
TO_DELETE=$(ls -1 --sort=time $VSCH_BIN_DIR | tail -n +6)
for COMMIT_TO_DELETE in $TO_DELETE; do
	echo "Found old VS Code install $COMMIT_TO_DELETE, attempting to clean up"

	_prepare_locking $COMMIT_TO_DELETE $CLEANUP_LOCKFD
	exlock_now $CLEANUP_LOCKFD
	if (( $? == 0 )); then
		RUNNING="`ps ax | grep $COMMIT_TO_DELETE | grep -v grep | wc -l | tr -d '[:space:]'`"
		if [ "$RUNNING" = "0" ]; then
			echo "Deleting old install from $VSCH_BIN_DIR/$COMMIT_TO_DELETE"
			rm -rf $VSCH_BIN_DIR/$COMMIT_TO_DELETE
		else
			echo "Install still has running processes, not deleting: $COMMIT_TO_DELETE"
 		fi
	else
		echo "Failed to acquire lock for install, not deleting: $COMMIT_TO_DELETE"
	fi
done

echo "before download"
echo $(date -u)

# install if needed
if [ ! -f "$VSCH_DIR/server.sh" ]
then
	echo "Installing..."
	STASHED_WORKING_DIR="`pwd`"
	cd $VSCH_DIR
	which wget &> /dev/null
	if [ $? == 0 ]
	then
		echo "Downloading with wget"
		WGET_ERRORS=$(2>&1 wget -nv -O $VCSH_TAR https://update.code.visualstudio.com/commit:$COMMIT_ID/$SERVER/$QUALITY)
		if [ $? -ne 0 ]; then
			echo $WGET_ERRORS
			echo "$UUID##25##$UUID"
			exit 0
		fi
	else
		which curl &> /dev/null
		if [ $? == 0 ]
		then
			echo "Downloading with curl"
			CURL_OUTPUT=$(2>&1 curl -L -s -S https://update.code.visualstudio.com/commit:$COMMIT_ID/$SERVER/$QUALITY --output $VCSH_TAR -w "%{http_code}")
			if [[ ($? -ne 0) || ($CURL_OUTPUT != 2??) ]]; then
				echo $CURL_OUTPUT
				echo "$UUID##25##$UUID"
				exit 0
			fi
		else
			echo "Neither wget nor curl is installed"
			echo "$UUID##26##$UUID"
			exit 0
		fi
	fi
	tar -xf $VCSH_TAR --strip-components 1
	if [ $? -gt 0 ]
       	then
		echo "WARNING: tar exited with non-0 exit code"
	fi

	# cheap sanity check
	if [ ! -f $VSCH_DIR/node ]
	then
		echo "WARNING: $VSCH_DIR/node doesn't exist. Download/untar may have failed."
	fi
    if [ ! -f "$VSCH_DIR/server.sh" ]
	then
		echo "WARNING: "$VSCH_DIR/server.sh" doesn't exist. Download/untar may have failed."
	fi
	rm $VCSH_TAR
	cd $STASHED_WORKING_DIR
else
	echo "Found existing installation..."
fi

# if [ ! -z "$EXTENSIONS" ]
# 	then
# 		echo "Installing extensions..."
# 		$VSCH_DIR/server.sh $EXTENSIONS
# fi

echo "after download"
echo $(date -u)

echo "$UUID==$PORT==$UUID"

echo "end"
echo $(date -u)

unlock $LOCKFD

echo "after lock release"
echo date -u
