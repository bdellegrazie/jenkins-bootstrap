# Jenkins Bootstrap

An integrated CI system based on Jenkins, including monitoring.
Useful for testing automation processes against Jenkins, linting pipelines and general experimentation.

Intended to be reasonably close to optimal in terms of configuration-as-code, even if some elements are incomplete.

This sample uses Ngrok (for TLS tunnel) with an Auth0 tenant and configures Auth0 to act as an OIDC provider
for Jenkins.

## Jenkins

### Overview

A custom Docker Jenkins controller image is built, using Jenkins LTS, pre-installing the plugins and bundling
the Configuration-as-Code (CasC). This image is the one run subsequently as part of docker compose.
Custom configuration copied to the image disables the configuration wizard and configures the logger to be
more cloud friendly.

At this point, it is assumed docker compose is executed.

The Jenkins controller starts and executes the following:

1. Internal startup, environment variables and secrets managers are configured.
2. CASC configuration is applied (`jenkins/casc_configs`) - authentication, authorisation and all the other CASC elements.
   In this sample, Docker is also configured as a "cloud" to run builds.
3. As part of CASC, an initial seed job (`jenkins/casc_configs/jobs/seed.groovy`) is configured and queued to run.
   This is a Jenkins Job-DSL script that creates the `Admin/Seed` job, it then queues the job to be executed.
   Jenkins is now up and running.
4. `Admin/Seed` Job executes - it:
   1. retrieves the source repository, targetting the primary branch.
   2. executes all Job-DSL scripts in `jenkins/jobsDSL/*.groovy`. Typically the Job DSL scripts configure a job to invoke a
      Jenkins Pipeline. In this example, an `Admin/Sample` job is created which, when executed, will run
     `jenkins/pipelines/sample.Jenkinsfile`
5. Once the seed job completes, Jenkins should be fully provisioned with all jobs present.
   If build / workspace volumes are configured, the jobs will show their prior history (if any).

### TODO

* `Admin/Seed` job should retrigger if there's a change in the source repository in the path (`jenkins/jobsDSL`). This can be via
webhook from version control (optimal) or the seed job could be configured to poll (slower). Neither solution is implemented in
this example.

This makes the job flow completely automatic from the source repository.

### Weaknesses

* The need to understand two different job configuration mechanisms (jobDSL, Pipelines) - and how they're typically chained to
achieve the end goal. The job configuration workflow for the sample looks like:

1. (Configuration) `Admin/Seed` is triggered, pulls repo, reads (`jenkins/jobsDSL/sample.groovy`) and creates (`Admin/Sample`)
2. (Execution) When (`Admin/Sample`) is triggered, pulls repo, invokes pipeline (`jenkins/pipelines/sample.Jenkinsfile`)

Some plugins, such as `github-branch-source-plugin`, can be leveraged to generate the equivalent Job DSL wrapper for each
repository discovered in an organisation, minimising the Job DSL work needed.

* CASC configuration is bundled into the controller container, changing it requires rebuilding the container.
  It is possible to have a job to reload CASC configuration on change but the update frequency isn't sufficient to warrant the effort.

### Building the Jenkins Controller

A simple Docker container build (`jenkins/Dockerfile`) based on Jenkins LTS upstream:

* During build, plugins are pre-installed from a list (`jenkins/plugins.txt`), dependencies are resolved automatically.
  It is possible to fixate the versions of the plugins here too.
* CASC configuration is copied into the container (`jenkins/casc_configs`)
* Logging configuration is added to make it more cloud friendly (`jenkins/logging.properties.override`)

### Configuration

* Can use ngrok to run on laptop for testing, particularly if testing SAML or OIDC integration
* Link to auth0 tenant (see below for auth0 config)

## Auth0 tenant

* Create a "Regular Web Application"
* Client ID and Client Secret are used by `run.sh` script to configure the Auth0 application
  correctly
* The Auth0 configuration will work with either the OIDC or SAML plugins in Jenkins.
* Specific points to note:
  * "Allowed Callback URLs": <domain>/securityRealm/finishLogin
  * "Application Login URI": <domain>/login
  * "Allowed Logout URLs": e.g. https://www.google.com/
  * Addons:
    * SAML2 WebApp:
      * logout:
        callback: <domain>/securityRealm/finishLogin
  * Need to use the Auth0 Authorisation Extension to configure groups (Auth0 Core isn't sufficient)

### SAML configuration

* Points to note:
  * Logout URL needs to be the Auth0 v2 logout, with a clientId and redirectTo parameter in order to
    actually logout. Can add a federated parameter too if you want the IdP to be completely logged out.

## Ngrok integration

* Default HTTP port: `8080`
* Default JNLP port: `50000` - this could be `-1` (disabled) if forcing websocket only
* Default SSH port: `-1` (disabled)

## References

[Using CasC Plugin](https://github.com/jenkinsci/configuration-as-code-plugin)
[Using Groovy](https://github.com/edx/jenkins-configuration)

## Usage

Run in order:

1. setup-ngrok.sh
2. setup-auth0.sh
3. setup-auth0-authz.sh (incomplete)
4. setup-jenkins.sh
5. docker compose -f compose.ci.yaml -f compose.monitoring.yaml up
