#!/bin/bash

GIT_REPO="https://github.com/richardxin/test"
if [ $# -ne 2 ]; then
	echo "=== Missing arguments ===: \nUSAGE: deploy_note.sh <zeppelin_env> <note_name>"
	exit 1
fi

# replace / with -
file_name="${2/\//-}.json"

echo $file_name

# git fetch
# git checkout FETCH_HEAD -- $file_name

if [ ! -f $file_name ]; then
	echo "file $file_name(for notebook $2) does not exist, please check your file name!"
	exit 1
fi

HOST=""
case "$1" in
   "dev" | "dev_snapshot") HOST="ec2-34-215-13-164.us-west-2.compute.amazonaws.com"
   ;;
   "prod") HOST="[prod]"
   ;;
   "staging") HOST="[dev-snapshot]"
   ;;
   *) 	HOST="ec2-34-215-13-164.us-west-2.compute.amazonaws.com"
   ;;
esac

# get first matching id for give friendly name
# curl -X GET http://ec2-34-215-13-164.us-west-2.compute.amazonaws.com:8890/api/notebook | jq  -r '[.body[] | select (.name=="test1/presto-test")][1] | .id'
NOTE_ID=`curl -X GET http://$HOST:8890/api/notebook | jq -r --arg name $2 '[.body[] | select (.name==$name)][0] | .id'`

if [ -n $NOTE_ID ]; then
	echo "removing notebook $2 $NOTE_ID ..."
	curl -X DELETE http://$HOST:8890/api/notebook/$NOTE_ID | jq -r '.status'	
else
	echo "importing new notebook $2 ..."
fi

NEW_ID=`curl -X POST -H "Content-Type: application/json" -d @$file_name http://$HOST:8890/api/notebook/import | jq -r '.body'`
echo $NEW_ID 

if [ -z $NEW_ID ] ; then
	echo "ERROR while importing notebook $2 ..."
	exit 1
fi

sh run_note.sh $1 $NEW_ID
