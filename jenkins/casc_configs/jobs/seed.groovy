job('Admin/seed') {
    parameters {
        gitParameter {
            name('GIT_REVISION')
            type('BRANCH_TAG')
            branch('master')
            branchFilter('^origin/(.*)$')
            defaultValue('master')
            description('Branch/Tag to build')
            listSize("0")
            quickFilterEnabled(true)
            selectedValue('DEFAULT')
            sortMode('ASCENDING_SMART')
            tagFilter('v*')
            useRepository('')
        }
    }
    scm {
        git {
            branch('${GIT_REVISION}')
            browser {
                githubWeb {
                repoUrl('https://github.com/bdellegrazie/jenkins-bootstrap/')
                }
            }
            remote {
                credentials('jenkins_bootstrap_deploy_key')
                github('bdellegrazie/jenkins-bootstrap', 'ssh')
                name('origin')
            }
            extensions {
                cleanBeforeCheckout()
                cleanAfterCheckout()
                cloneOptions {
                    noTags(false)
                    shallow(false)
                }
                pathRestriction {
                    includedRegions('jenkins/jobsDSL/.*')
                    excludedRegions('')
                }
                pruneBranches()
                sparseCheckoutPaths {
                    sparseCheckoutPaths {
                        sparseCheckoutPath {
                            path('jenkins/jobsDSL')
                        }
                    }
                }
            }
        }
    }
    label('built-in')
    logRotator {
        numToKeep(20)
    }
    properties {
        disableConcurrentBuilds()
    }
    triggers {
        githubPush()
    }
    wrappers {
        colorizeOutput()
    }
    steps {
        jobDsl {
            failOnMissingPlugin(true)
            failOnSeedCollision(true)
            ignoreMissingFiles(true)
            lookupStrategy('JENKINS_ROOT')
            removedConfigFilesAction('DELETE')
            removedJobAction('DISABLE')
            removedViewAction('DELETE')
            sandbox(true)
            targets('jenkins/jobsDSL/**/*.groovy')
            unstableOnDeprecation(true)
        }
    }
}
