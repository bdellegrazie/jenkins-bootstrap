pipeline {
    agent { master }
    stages {
        stage('build') {
            steps {
                sh 'echo "Hello World!"'
            }
        }
    }
}
