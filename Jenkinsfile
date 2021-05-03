properties([pipelineTriggers([githubPush()])])

pipeline {

    environment {
        AMBIENTE = "prod"
        COMPONENTE = "caoba-test"
        REGION="us-east-2"
        registry = "955218286471.dkr.ecr.${REGION}.amazonaws.com/${AMBIENTE}/${COMPONENTE}"
        registryCredential = 'AWS-Jenkins-Caoba'
        dockerImage = ''
    }
    
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

stages {

    // stage('Preparation') {

    //     steps
    //     {
    //         script 
    //         {
    //             if (params.Emisores == '') { 
    //                 currentBuild.result = 'ABORTED'
    //                 error('No se ha seleccionado ningun Emisor para el deploy del pipeline')
    //             }
    //         }
    //     }
    // }

    // stage('Slack started'){
    //         environment {
    //             COMMIT_INFO = sh (script: 'git --no-pager show -s --format=\'%aN in commit "%s"\'',returnStdout: true).trim()
    //         }
    //         steps {
    //             slackSend channel: "#jenkins-${AMBIENTE}",
    //                       message: "${COMPONENTE} » ${BRANCH_NAME} #${BUILD_ID} - #${BUILD_ID} Started compilation\n📣 Compilation #${BUILD_ID} Started by ${COMMIT_INFO}"
    //         }
    //     }

    stage('SonarQube Analysis') {
          steps{
              sh '''
docker run --rm -v /root/.m2:/root/.m2 -v $WORKSPACE:/app -w /app \
                    maven:3-alpine mvn sonar:sonar \
                        -Dsonar.projectKey=$COMPONENTE \
                        -Dsonar.host.url=http://sonarqube.qa.cobre.co \
                        -Dsonar.login=d3f4b3583131da7da2430ea151ba73ae9b109821 \
                        -Dsonar.java.binaries=./src

                    docker run \
                    --rm \
                    -e SONAR_HOST_URL="http://3.18.49.92" \
                    -e SONAR_LOGIN="e6bc5f00416ba0d792aa60e2df0ddffd6811d63c" \
                    -v "./public-html" \
                    -Dsonar.projectName='caoba-test' \
                    sonarsource/sonar-scanner-cli

                    docker run --rm -v $(pwd):/usr/src  newtmitch/sonar-scanner:4-alpine \
                    -D sonar.host.url=http://3.18.49.92 \
                    -D sonar.login=d3f4b3583131da7da2430ea151ba73ae9b109821 \
                    -D sonar.projectBaseDir=./public-html \
                    -D sonar.sources=. \
                    -D sonar.projectKey=$COMPONENTE \
                    -D sonar.projectName='caoba-test'
                '''
          }
    }

    //  stage("Quality Gate") {
    //         steps {
    //             sh '''
    //                 echo "Sonar Gate"
    //             '''
    //         //     timeout(time: 1, unit: 'HOURS') {
    //         //         // Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
    //         //         // true = set pipeline to UNSTABLE, false = don't
    //         //         waitForQualityGate abortPipeline: true
    //         //     }
    //         }
    //     }


    stage("Build ") {
        steps {
                sh '''
                    echo "Compilando imagen"
                '''
        
                script {
                        dockerImage = docker.build registry + ":${GIT_COMMIT}"
                        dockerImageLatest = docker.build registry + ":latest"
                }
        }
    }
  
    stage('Push ECR') {
          steps{
              script{
                  docker.withRegistry("https://" + registry, "ecr:" + REGION + ":" + registryCredential) {
                      dockerImage.push()
                  }
                  docker.withRegistry("https://" + registry, "ecr:us-east-2:" + registryCredential) {
                      dockerImageLatest.push()
                  }
              }
          }
    }

    stage('Scanning Image') {
        steps{
            sh '''
                    echo  "Ejecutando escaneo de vulnerabilidades en imagen"
                    sleep 15
                    aws ecr describe-image-scan-findings \
                      --repository-name $AMBIENTE/$COMPONENTE \
                      --image-id imageTag=latest \
                      --region $REGION | \
                      egrep "severity" | tr "/" " " | awk '{print $2}' | sed 's/"$//' > escaneo.txt
                      export VulAltas=`grep -o -i HIGH escaneo.txt | wc -l`
                      export VulMedias=`grep -o -i MEDIUM escaneo.txt | wc -l`
                      echo "Vulnerabilidades ALTAS =======> "$VulAltas
                      echo "Vulnerabilidades MEDIAS =======> "$VulMedias
            '''
        }
    }

    stage('Deploy for production') {
        steps {
            sh '''
                sh ./deployPrd.sh
            '''
        }
    }
}
    
    post {
        always
            {
                // make sure that the Docker image is removed
                sh """
                    docker image rm ${env.registry}:${GIT_COMMIT}
                    docker image rm ${env.registry}:latest
                """
            }
        // failure
        //     {
        //             slackSend channel: "#jenkins-${AMBIENTE}",
        //                     message: "${COMPONENTE} » ${BRANCH_NAME} #${BUILD_ID} - #${BUILD_ID} LLORINDEL compilation\n❌ Compilation #${BUILD_ID} LLORINDEL"
        //     }
        // success
        //     {
        //             slackSend channel: "#jenkins-${AMBIENTE}",
        //                     message: "${COMPONENTE} » ${BRANCH_NAME} #${BUILD_ID} - #${BUILD_ID} Finish compilation\n✔ Compilation #${BUILD_ID} - Emisores Desplegados:\n${EMISORESOK}"
        //     }

        }

}
