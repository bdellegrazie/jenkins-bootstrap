pipeline {
    agent { label 'master' }
    stages {
        stage('build') {
            steps {
                sh 'echo "Hello World!"'
            }
        }
    }
}
