pipelineJob('Admin/sample') {
    definition {
        cps {
            script(readFileFromWorkspace('jenkins/pipelines/sample.Jenkinsfile'))
            sandbox()
        }
    }
}
