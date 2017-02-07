#!groovy

import groovy.json.JsonSlurperClassic

notifyBuildDetails = ""
snapAppName = ""

try {
  notifyBuild('STARTED')
  node("snapcraft") {
    deleteDir()

    stage("Checkout source")
    /* Checkout snap repository */
    notifyBuildDetails = "\nFailed on Stage - Checkout source"

    checkout scm

    stage("Generate snapcraft.yaml")

    switch (env.BRANCH_NAME) {
      case ~/master/: snapAppName = "subutai-stage"; break;
      case ~/dev/: snapAppName = "subutai-dev"; break;
      default: assert false
    }    

    sh """
    cp snapcraft.yaml.templ snapcraft.yaml
    sed -e 's/(BRANCH)/${env.BRANCH_NAME}/g' -i snapcraft.yaml
    sed -e 's/(SUBUTAI)/${snapAppName}/g' -i snapcraft.yaml
    """

    stage("Build snap")
    notifyBuildDetails = "\nFailed on Stage - Build snap"
    sh """
      snapcraft
    """

    stage("Upload to Ubuntu Store")
    notifyBuildDetails = "\nFailed on Stage - Upload to Ubuntu Store"
    sh """
      snapcraft push \$(ls subutai_*_amd64.snap) --release beta
    """
  }
} catch (e) { 
  currentBuild.result = "FAILED"
  throw e
} finally {
  // Success or failure, always send notifications
  notifyBuild(currentBuild.result, notifyBuildDetails)
}

// https://jenkins.io/blog/2016/07/18/pipline-notifications/
def notifyBuild(String buildStatus = 'STARTED', String details = '') {
  // build status of null means successful
  buildStatus = buildStatus ?: 'SUCCESSFUL'

  // Default values
  def colorName = 'RED'
  def colorCode = '#FF0000'
  def subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"   
  def summary = "${subject} (${env.BUILD_URL})"

  // Override default values based on build status
  if (buildStatus == 'STARTED') {
    color = 'YELLOW'
    colorCode = '#FFFF00'  
  } else if (buildStatus == 'SUCCESSFUL') {
    color = 'GREEN'
    colorCode = '#00FF00'
  } else {
    color = 'RED'
    colorCode = '#FF0000'
  summary = "${subject} (${env.BUILD_URL})${details}"
  }
  // Get token
  def slackToken = getSlackToken('sysnet-bots-slack-token')
  // Send notifications
  slackSend (color: colorCode, message: summary, teamDomain: 'subutai-io', token: "${slackToken}")
}

// get slack token from global jenkins credentials store
@NonCPS
def getSlackToken(String slackCredentialsId){
  // id is ID of creadentials
  def jenkins_creds = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0]

  String found_slack_token = jenkins_creds.getStore().getDomains().findResult { domain ->
    jenkins_creds.getCredentials(domain).findResult { credential ->
      if(slackCredentialsId.equals(credential.id)) {
        credential.getSecret()
      }
    }
  }
  return found_slack_token
}