#!/bin/bash
SERVICE_NAME=${COMPONENTE}"-service"
TASK_FAMILY=${COMPONENTE}"-task"
DESIRED_COUNT="1"

# Create a new task definition for this build
sed -e "s;%TAGBUILDECS%;${TAGBUILDECS};g" template-task.json > template-task-tmp-${BUILD_NUMBER}.json
sed -e "s;%COMPONENTE%;${COMPONENTE};g" template-task-tmp-${BUILD_NUMBER}.json > template-task-${BUILD_NUMBER}.json
sed -e "s;%AMBIENTE%;${AMBIENTE};g" template-task.json > template-task-tmp-${BUILD_NUMBER}.json
sed -e "s;%REGION%;${REGION};g" template-task-tmp-${BUILD_NUMBER}.json > template-task-${BUILD_NUMBER}.json
sed -e "s;%GIT_COMMIT%;${GIT_COMMIT};g" template-task.json > template-task-tmp-${BUILD_NUMBER}.json
aws ecs register-task-definition \
--family $TASK_FAMILY \
--execution-role-arn "arn:aws:iam::955218286471:role/ecsTaskExecutionRole" \
--task-role-arn "arn:aws:iam::955218286471:role/ecsTaskExecutionRole" \
--network-mode "awsvpc" \
--cpu 512 \
--memory 1024 \
--requires-compatibilities "FARGATE" \
--cli-input-json file://template-task-tmp-${BUILD_NUMBER}.json 

TASK_REVISION=`aws ecs describe-task-definition --task-definition $TASK_FAMILY | egrep "revision" | tr "/" " " | awk '{print $2}' | sed 's/"$//'`

aws ecs update-service --cluster cluster-caoba-prod --service ${SERVICE_NAME} --task-definition ${TASK_FAMILY} --desired-count ${DESIRED_COUNT} --force-new-deployment 



