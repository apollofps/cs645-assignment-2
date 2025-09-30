import jenkins.model.*
import hudson.security.*
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

// Set authorization strategy
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Save the configuration
instance.save()

// Install basic plugins
def pluginManager = instance.getPluginManager()
def updateCenter = instance.getUpdateCenter()

def plugins = [
    "git",
    "github",
    "pipeline-stage-view", 
    "workflow-aggregator",
    "docker-workflow",
    "kubernetes",
    "google-kubernetes-engine"
]

plugins.each { plugin ->
    if (!pluginManager.getPlugin(plugin)) {
        def deployment = updateCenter.getPlugin(plugin).deploy()
        deployment.get()
    }
}

println "Jenkins admin user created successfully!"
println "Username: admin"
println "Password: admin123"