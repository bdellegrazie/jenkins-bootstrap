multibranchPipelineJob('gradle-java-sample') {
    description('Gradle Java Sample Pipeline')
    branchSources {
        github {
            id('b6d5d8a7-89c3-4bc0-8bc6-0487d9d0bc0d')
            checkoutCredentialsId('gradle_java_sample_deploy_key')
            repoOwner('bdellegrazie')
            repository('gradle-java-sample')
            scanCredentialsId('gradle_java_sample_deploy_key')
        }
    }
    orphanedItemStrategy {
        discardOldItems {
            daysToKeep(7)
            numToKeep(5)
        }
    }
}
