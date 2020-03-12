#!/bin/bash

while getopts f:c:v:e: option
do
case "${option}"
in
f) EXECUTE_FILE=${OPTARG};;
c) EXECUTE_COMMAND=${OPTARG};;
v) VERBOSE=${OPTARG};;
e) ENV+=("$OPTARG");;
esac
done

if [[ $VERBOSE != '' ]]; then
  export XXH_VERBOSE=$VERBOSE
fi

for env in "${ENV[@]}"; do
  name="$( cut -d '=' -f 1 <<< "$env" )";
  val="$( cut -d '=' -f 2- <<< "$env" )";
  val=`echo $val | base64 -d`

  if [[ $XXH_VERBOSE == '1' ]]; then
    echo Environment variable "$env": name=$name, value=$val
  fi

  export $name="$val"
done

if [[ $EXECUTE_COMMAND ]]; then
  echo 'Xonsh entrypoint is not support command execution.'
  echo 'Wait for xonsh release with fix: https://github.com/xonssh/xxh/issues/36'
  exit 1
fi

EXECUTE_FILE=`[ $EXECUTE_FILE ] && echo -n "-- $EXECUTE_FILE" || echo -n ""`

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd $CURRENT_DIR

# Check FUSE support
check_result=`./xonsh --no-script-cache -i --rc xonshrc.xsh -- $CURRENT_DIR/../../../package/settings.py 2>&1`
if [[ ! -f xonsh-check-done ]]; then
  if [[ $check_result == *"FUSE"* ]]; then
    #echo "Extract AppImage" 1>&2  # TODO: verbose mode
    ./xonsh --appimage-extract > /dev/null # TODO: verbose mode
    mv squashfs-root xonsh-squashfs
    mv xonsh xonsh-disabled
    ln -s ./xonsh-squashfs/usr/bin/python3 xonsh
  fi
  echo $check_result > xonsh-check-done
fi

./xonsh --no-script-cache -i --rc xonshrc.xsh $EXECUTE_FILE
