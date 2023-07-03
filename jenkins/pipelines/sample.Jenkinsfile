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
    stage("Security") {
      environment {
        DB_DC=credentials('dependency_check_db_user')
      }
      steps {
        configFileProvider([configFile(fileId: 'dependency-check-props', replaceTokens: true, targetLocation: 'db.properties', variable: 'DB_DC_FILE')]) {
          dependencyCheck additionalArguments: "--propertyfile '${env.DB_DC_FILE}' --noupdate --scan .", odcInstallation: 'v8'
        }
      }
      post {
        always {
          dependencyCheckPublisher failedNewCritical: 1, 
            failedTotalCritical: 1, 
            stopBuild: true, 
            newThresholdAnalysisExploitable: true, 
            totalThresholdAnalysisExploitable: true, 
            unstableNewCritical: 1, 
            unstableTotalCritical: 1
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
