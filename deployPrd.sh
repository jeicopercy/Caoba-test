#!/bin/bash
SERVICE_NAME=${COMPONENTE}"-service"
export TAGBUILDECS=`cat /etc/version.txt`
TASK_FAMILY=${COMPONENTE}"-task"
DESIRED_COUNT="2"
export AWS_PROFILE=cobre-prd

# Create a new task definition for this build
sed -e "s;%TAGBUILDECS%;${TAGBUILDECS};g" template-task.json > template-task-tmp-${BUILD_NUMBER}.json
sed -e "s;%COMPONENTE%;${COMPONENTE};g" template-task-tmp-${BUILD_NUMBER}.json > template-task-${BUILD_NUMBER}.json
aws ecs register-task-definition \
--family $TASK_FAMILY \
--execution-role-arn "arn:aws:iam::489231195332:role/ecsTaskExecutionRole" \
--task-role-arn "arn:aws:iam::489231195332:role/ecsTaskExecutionRole" \
--network-mode "awsvpc" \
--cpu 1024 \
--memory 2048 \
--requires-compatibilities "FARGATE" \
--cli-input-json file://template-task-${BUILD_NUMBER}.json 

TASK_REVISION=`aws ecs describe-task-definition --task-definition $TASK_FAMILY | egrep "revision" | tr "/" " " | awk '{print $2}' | sed 's/"$//'`
echo "" > /etc/deployok.txt

for i in $(echo $Emisores | sed "s/,/ /g"); do

        if [ "$i" = "GMT" ]; then
            aws ecs update-service --cluster Cluster-gematours --service ${SERVICE_NAME} --task-definition ${TASK_FAMILY} --desired-count ${DESIRED_COUNT} --force-new-deployment 
            echo "Despliegue hecho sobre infra $i"
            echo ":this-is-fine-fire: "$i >> /etc/deployok.txt
        elif [ "$i" = "BMT" ]; then
            aws ecs update-service --cluster Cluster-barumotors --service ${SERVICE_NAME} --task-definition ${TASK_FAMILY} --desired-count ${DESIRED_COUNT} --force-new-deployment 
            echo "Despliegue hecho sobre infra $i"
            echo ":this-is-fine-fire: "$i >> /etc/deployok.txt
        elif [ "$i" = "FCF" ]; then
            aws ecs update-service --cluster Cluster-foncomfenalco --service ${SERVICE_NAME} --task-definition ${TASK_FAMILY} --desired-count ${DESIRED_COUNT} --force-new-deployment 
            echo "Despliegue hecho sobre infra $i"
            echo ":this-is-fine-fire: "$i >> /etc/deployok.txt
        else
            echo "No se realizo Deploy para $i"
        fi

done


