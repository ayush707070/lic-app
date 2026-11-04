pipeline {
   
   agent any

   tools {
       maven 'Maven-3.9.12'
   }

   triggers{
      githubPush()
   }

  options {
      disableConcurrentBuilds()
      timeout(5)
      buildDiscarder logRotator(daysToKeepStr: '5', numToKeepStr: '10')
   }


    environment {
        SONARQUBE_TOKEN = credentials('SonarQubeToken')
        SONARQUBE_HOST_URL = 'http://172.31.6.94:9000'
    }

    stages {
      
        stage('Maven Build') {
            steps {
                sh "mvn clean package"
            }
        }
        stage('SonarQube Analysis') {
            steps {
               sh "mvn sonar:sonar -Dsonar.url=${SONARQUBE_HOST_URL} -Dsonar.token=${SONARQUBE_TOKEN}"
            }
        }
        stage('Upload War to Nexus') {
            steps {
                sh "mvn clean deploy"
            }
        }

        stage('Deploy to Tomcat') {
            environment {
                 TOMCAT_SERVER_IP = "172.31.11.157"
            }
            steps {
               sshagent (credentials: ['Tomcat_SSH_Cred']) {
                    sh "ssh -o StrictHostKeyChecking=no ec2-user@${TOMCAT_SERVER_IP} sudo systemctl stop tomcat"
                    sh "ssh -o StrictHostKeyChecking=no ec2-user@${TOMCAT_SERVER_IP} rm -f /opt/tomcat/webapps/student-reg-webapp.war"
                    sh "sleep 10"
                    sh "scp -o StrictHostKeyChecking=no target/student-reg-webapp.war ec2-user@${TOMCAT_SERVER_IP}:/opt/tomcat/webapps/student-reg-webapp.war"
                    sh "ssh -o StrictHostKeyChecking=no ec2-user@${TOMCAT_SERVER_IP} sudo systemctl start tomcat"
                }
            }
       }
   }
  
   post {
    always {
       cleanWs()
    }
    success {
       slackSend channel: 'lic-app-team', color: "good"  , message: "Jenkins Job ${env.JOB_NAME} - ${env.BUILD_NUMBER} - SUCCESS. Please check the Jenkins console output for details. ${env.BUILD_URL}"
       sendEmail("SUCCESS")
    }
    failure {
      slackSend channel: 'lic-app-team', color: "danager"  , message: "Jenkins Job ${env.JOB_NAME} - ${env.BUILD_NUMBER} - FAILURE. Please check the Jenkins console output for details. ${env.BUILD_URL}"
      sendEmail("FAILED")
    }

   }
}

def sendEmail(String buildStatus){
    emailext body:  """
                    <html>
                    <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px;">
                        <h2 style="color: #2d87f0;">Jenkins Build Notification</h2>
                        <p><strong>Build Result:</strong> ${buildStatus}</p>
                        <p><strong>Build Number:</strong> ${env.BUILD_NUMBER}</p>
                        <p><strong>Project:</strong> ${env.JOB_NAME}</p>
                        <p><strong>Build URL:</strong> <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                        <p>For more details, please visit the Jenkins job page.</p>
                    </body>
                    </html>
                    """, 
        subject: "${env.JOB_NAME} - ${env.BUILD_NUMBER} - ${buildStatus}", 
        to: 'balajireddy.urs@gmail.com,rushitechnologiesbanglore@gmail.com',
        mimeType: 'text/html'
}