# Jenkins Master Docker Container

Useful for testing automation processes and linting pipelines

# Configuration

*admin* Password is set in the jcasc configuration, use a "secrets" implementation in a real situation.

* Default HTTP port: 8081
* Default JNLP port: 50000
* Default SSH port: 50001

# Plugins

Plugins are loaded automatically from plugins.txt

All versions have been set to latest to simplify use in the container
This is easy to change if desired

# Bootstrapping

[Using CasC Plugin](https://github.com/jenkinsci/configuration-as-code-plugin)

[Using Groovy](https://github.com/edx/jenkins-configuration)
