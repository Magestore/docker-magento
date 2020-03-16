pipeline {
    agent {
        docker {
            image 'magestore/compose'
            args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock -v $JENKINS_DATA:$JENKINS_DATA -e JENKINS_DATA=$JENKINS_DATA'
            label 'docker-magento'
        }
    }
    parameters {
        choice(name: 'HTTP_SERVER', choices: ['apache-2.4', 'nginx-1.8', 'apache-2.2'], description: 'HTTP Server')
        choice(name: 'PHP_VERSION', choices: ['7.2', '7.1', '7.0', '5.6'], description: 'PHP Version')
        choice(name: 'MAGENTO_VERSION', choices: ['2.3.4', '2.3.3', '2.3.2', '2.3.1', '2.3.0', '2.2.11', '2.2.10', '2.2.9', '2.2.8', '2.2.7', '2.2.6', '2.1.17', 'ee-2.3.4', 'ee-2.3.3'], description: 'Magento Version')
        choice(name: 'GITHUB_REPO', choices: ['magestore-shark/pos-standard', 'magestore-shark/pos-enterprise', 'magestore-shark/pos-pro', 'abel274/pos-enterprise-commerce', 'Magestore/pos-standard', 'Magestore/pos-pro', 'Magestore/pos-enterprise', 'Magestore/pos-enterprise-commerce'], description: 'Github repository')
        string(name: 'GITHUB_BRANCH', defaultValue: '4-develop', description: 'Github branch or pull request. Example: 3-develop, pull/3')
        choice(name: 'TIME_TO_LIVE', choices: ['4h', '1d', '7d'], description: 'Server living time')
        credentials(name: 'GITHUB_USER', description: 'Github username and password', defaultValue: 'bc94c750-da7f-45f6-ade2-51eeade5ad3b', credentialType: "Username with password", required: true)
    }
    environment {
        CI = 'true'
    }
    stages {
        stage('Build') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.GITHUB_USER, usernameVariable: 'GITHUB_USERNAME', passwordVariable: 'GITHUB_PASSWORD')])
                {
                    sh './bin/build.sh'
                }
            }
        }
        stage('Running') {
            steps {
                sh './bin/run.sh'
            }
        }
    }
    post {
        always {
            sh './bin/finish.sh'
        }
    }
}
