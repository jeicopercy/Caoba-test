properties([
    pipelineTriggers([cron('')]),

])

pipeline {

    environment {
        AMBIENTE = "prod"
        COMPONENTE = "core-movil-operacion"
        registry = "891899566293.dkr.ecr.us-east-2.amazonaws.com/${AMBIENTE}/${COMPONENTE}"
        registryCredential = 'jenkins-aws-cobre'
        dockerImage = ''
        CODEARTIFACT_AUTH_TOKEN=""
        EMISORESOK="FCF"
    }
    
    agent any

    parameters{
      checkboxParameter name:'Emisores', format:'JSON', uri:'https://cobre-utils.s3.us-east-2.amazonaws.com/emisores.json'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }

stages {

    stage('Preparation') {

        steps
        {
            script 
            {
                if (params.Emisores == '') { 
                    currentBuild.result = 'ABORTED'
                    error('No se ha seleccionado ningun Emisor para el deploy del pipeline')
                }
            }
        }
    }

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
                '''
          }
    }

     stage("Quality Gate") {
            steps {
                sh '''
                    echo "Sonar Gate"
                '''
            //     timeout(time: 1, unit: 'HOURS') {
            //         // Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
            //         // true = set pipeline to UNSTABLE, false = don't
            //         waitForQualityGate abortPipeline: true
            //     }
            }
        }


    stage("Build ") {
        environment {
            TAGBUILD='0.0'
        }
        steps {
                sh '''
                    echo "Compilando imagen"
                    CODEARTIFACT_AUTH_TOKEN=`aws codeartifact get-authorization-token --domain cobre-domain --domain-owner 891899566293 --query authorizationToken --output text`
                    cp ./settings.xml /root/.m2/settings.xml
                '''
                script {
                    TAGBUILD = sh (script: 'sh buildMaven.sh -v', returnStdout: true).trim()
                }
                sh """
                    echo "${TAGBUILD}" > /etc/version.txt
                """
        }
        post {
            success {
                script {
                        dockerImage = docker.build registry + ":${TAGBUILD}"
                        dockerImageLatest = docker.build registry + ":latest"
                }
            }
        }
    }
  
    stage('Push ECR') {
          steps{
              script{
                  docker.withRegistry("https://" + registry, "ecr:us-east-2:" + registryCredential) {
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
                      --image-id imageTag=$TAGBUILD \
                      --region us-east-2 | \
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
            print params['Emisores']

            sh '''
                aws s3 cp  s3://cobre-utils/deployPrd.sh .
                sh ./deployPrd.sh
                EMISORESOK=`cat /etc/deployok.txt`
            '''
            sh """
                    ${EMISORESOK}=`cat /etc/deployok.txt`
            """

        }
    }
}
    
    post {
        always
            {
                // make sure that the Docker image is removed
                sh """
                    echo "${TAGBUILD}" > /etc/version.txt
                    docker image rm ${env.registry}:${TAGBUILD}
                    docker image rm ${env.registry}:latest
                """
            }
        // failure
        //     {
        //             slackSend channel: "#jenkins-${AMBIENTE}",
        //                     message: "${COMPONENTE} » ${BRANCH_NAME} #${BUILD_ID} - #${BUILD_ID} LLORINDEL compilation\n❌ Compilation #${BUILD_ID} LLORINDEL"
        //     }
        success
            {
                    slackSend channel: "#jenkins-${AMBIENTE}",
                            message: "${COMPONENTE} » ${BRANCH_NAME} #${BUILD_ID} - #${BUILD_ID} Finish compilation\n✔ Compilation #${BUILD_ID} - Emisores Desplegados:\n${EMISORESOK}"
            }

        }

}
