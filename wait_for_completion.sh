#!/bin/bash

STATUS_URL="http://$1:8890/api/notebook/job/$2"

# curl -X GET http://ec2-34-215-13-164.us-west-2.compute.amazonaws.com:8890/api/notebook | jq '.body[] | select (.id == "2CX4Y3FAS") | .name'
while true
do
        STATUS=`curl -X GET $STATUS_URL | jq -cr '.body[] | .status'`
        echo $STATUS

        IFS=' ' read -r -a array <<< $STATUS

        #
        #  READY,FINISHED,ABORT,ERROR,PENDING,RUNNING
        #

        JOB_STATUS="FINISHED"
        for element in "${array[@]}"
        do
                echo "--$element"
                if [ "$element" != "FINISHED" ] ; then
                        JOB_STATUS=$element
                        echo "$JOB_STATUS $element"
                        break
                else
                        continue
                fi
        done
        echo $JOB_STATUS
        if [ "$JOB_STATUS" = "FINISHED" ]; then
                sh slackpost.sh https://hooks.slack.com/services/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 "#test_rx" zeppelin_chronos "Zeppelin Note $2 (Name=$3) has been successully completed"
                break
        elif ([ "$JOB_STATUS" = "ABORT" ] || [ "$JOB_STATUS" = "ERROR" ]); then
                sh slackpost.sh https://hooks.slack.com/services/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 "#test_rx" zeppelin_chronos "Zeppelin Note $2 (Name=$3) has been completed with status $JOB_STATUS"
                break
        fi

        sleep 120
done
