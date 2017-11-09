#!/bin/bash
# example: sh run_note.sh ec2-34-215-13-164.us-west-2.compute.amazonaws.com 2CX4Y3FAS
# Usage: run_note.sh "<zeppelin_host>" "<note_id>"

#   http://[zeppelin-server]:[zeppelin-port]/api/notebook/job/[noteId]
if [ $# -ne 2 ]; then
    echo "=== Missing arguments ===: \nUSAGE: run_note.sh <zeppelin_host> <note_id>"
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


RESULT=`curl -X POST http://$HOST:8890/api/notebook/job/$2 | jq -r '.status'`
STATUS_URL="http://$HOST:8890/api/notebook/job/$2"
NOTE_URL="http://$HOST:8890/#/notebook/$2"

# curl -X GET http://ec2-34-215-13-164.us-west-2.compute.amazonaws.com:8890/api/notebook | jq '.body[] | select (.id == "2CX4Y3FAS") | .name'
NOTE=`curl -X GET http://$HOST:8890/api/notebook | jq -r --arg id $2 '.body[] | select (.id==$id) | .name'`
echo "---$NOTE"

if [ "$RESULT" == "OK" ] ; then
	sh slackpost.sh https://hooks.slack.com/services/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 "#test_rx" zeppelin_chronos "Zeppelin Note $2 (name=$NOTE) has been successully started, please check $STATUS_URL for job status\n\nfor details of the notebook, please check $NOTE_URL"
	sh wait_for_completion.sh $HOST $2 $NOTE
else
	echo "Note $2  failed"
fi