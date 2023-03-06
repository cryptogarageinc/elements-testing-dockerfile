#!/bin/sh
if [ $# -eq 0 ]; then
  echo "[usage] check.sh <targetName>"
  exit 1
fi

TARGET="$1"
echo "$TARGET check start."
while :
do
  pidof $TARGET >/dev/null || break
  echo "$TARGET running"
  sleep 1
done
echo "$TARGET check finish."
