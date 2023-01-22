pipeline {
  agent any
  stages {
    stage("Prepare") {
      steps {
        echo "Preparing..."
        sleep time: 5
      }
    }
    stage("Build") {
      steps {
        echo "Building..."
        sleep time: 7
      }
    }
    stage("Test") {
      steps {
        echo "Testing..."
        sh script: '''#!/usr/bin/env bash
          rm -f report.xml
          tests/bats-core/bin/bats tests --report-formatter junit
        '''
        slep time: 10
      }
      post {
        always {
          junit testResults: 'report.xml', allowEmptyResults: false
        }
      }
    }
    stage("Deploy") {
      steps {
        echo "Deploying..."
        sleep time: 6
      }
    }
  }
}
