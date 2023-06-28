pipelineJob('Admin/dependency-check-update') {
    description('Dependency Check Update')
    properties {
        buildDiscarder {
            strategy {
                logRotator {
                    numToKeepStr('7')
                    daysToKeepStr('7')
                    artifactDaysToKeepStr('7')
                    artifactNumToKeepStr('5')
                    disableConcurrentBuilds {
                        abortPrevious(true)
                    }
                }
            }
        }
        definition {
            cpsScm {
                lightweight(true)
                scm {
                    scmGit {
                        userRemoteConfigs {
                            userRemoteConfig {
                                url('https://github.com/bdellegrazie/jenkins-bootstrap.git')
                                name('origin')
                                credentialsId('jenkins_bootstrap_deploy_key')
                                refspec('')
                            }
                        }
                        branches {
                            branchSpec {
                                name('refs/heads/master')
                            }
                        }
                        browser {
                            github {
                                repoUrl('https://github.com/bdellegrazie/jenkins-bootstrap')
                            }
                        }
                        extensions {
                            cleanAfterCheckout {
                            }
                            cleanBeforeCheckout {
                            }
                            submodule {
                              depth(3)
                              disableSubmodules(false)
                              parentCredentials(false)
                              recursiveSubmodules(false)
                              shallow(true)
                              trackingSubmodules(true)
                            }
                        }
                        gitTool('Default')
                    }

                }
                scriptPath('jenkins/pipelines/Admin/dependency-check-update.Jenkinsfile')
            }
        }
        pipelineTriggers {
            triggers {
                cron {
                    spec('@daily')
                }
            }
        }
    }
}
