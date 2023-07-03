pipeline {
  agent any
  options {
    ansiColor('xterm')
  }
  stages {
    stage("Update Dependency Check Database") {
      environment {
        DB_DC=credentials('dependency_check_db_admin')
      }
      steps {
        configFileProvider([configFile(fileId: 'dependency-check-props', replaceTokens: true, targetLocation: 'db.properties', variable: 'DB_DC_FILE')]) {
          dependencyCheck additionalArguments: "--updateonly --propertyfile '${env.DB_DC_FILE}'", odcInstallation: 'v8'
        }
      }
    }
  }
}
