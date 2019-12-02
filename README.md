# Jenkins Master Docker Container

Useful for testing automation processes and linting pipelines

# Configuration

* Can use ngrok to run on laptop for testing, particularly if testing SAML integration
* Link to auth0 tenant (see below for auth0 config)

## Auth0 tenant
* Create a "Regular Web Application"
* Client ID and Client Secret are used by `run.sh` script to configure the Auth0 application
  correctly
* Specific points to note:
  - "Allowed Callback URLs": <domain>/securityRealm/finishLogin
  - "Application Login URI": <domain>/login
  - "Allowed Logout URLs": e.g. https://www.google.com/
  - Addons:
    - SAML2 WebApp:
      - logout:
        callback: <domain>/securityRealm/finishLogin
  - Need to use the Auth0 Authorisation Extension to configure groups (Auth0 Core doesn't work at the moment)

## Jenkins SAML configuration
* Points to note:
  - Logout URL needs to be the Auth0 v2 logout, with a clientId and redirectTo parameter in order to
    actually logout. Can add a federated parameter too if you want the IdP to be completely logged out.

## Ngrok integration
* Default HTTP port: 8081
* Default JNLP port: 50000
* Default SSH port: -1 (disabled)

# Plugins

Plugins are loaded automatically from plugins.txt during the container build. The script resolves
dependencies.

# Bootstrapping

[Using CasC Plugin](https://github.com/jenkinsci/configuration-as-code-plugin)
[Using Groovy](https://github.com/edx/jenkins-configuration)
