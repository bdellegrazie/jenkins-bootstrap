pipeline {
  agent any
  options {
    ansiColor('xterm')
  }
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
        sleep time: Math.abs(new Random().nextInt() % (2 - 7)) + 2
      }
    }
    stage("Test") {
      steps {
        echo "Testing..."
        sh script: '''#!/usr/bin/env bash
          rm -rf reports/*
          tests/bats-core/bin/bats tests --formatter pretty --report-formatter junit --output reports || true
        '''
      }
      post {
        always {
          junit allowEmptyResults: true, skipPublishingChecks: true, testResults: 'reports/*.xml'
        }
      }
    }
    stage("Deploy") {
      steps {
        echo "Deploying..."
        sleep time: Math.abs(new Random().nextInt() % (2 - 7)) + 2
      }
    }
  }
}
