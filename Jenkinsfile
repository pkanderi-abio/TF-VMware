pipeline {
  agent any

  environment {
    TF_VAR_vsphere_user     = "${credentials('vsphere-creds').username}"
    TF_VAR_vsphere_password = "${credentials('vsphere-creds').password}"
    TF_VAR_vsphere_server   = "${credentials('vsphere-server')}" 
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/pkanderi-abio/TF-VMware'
      }
    }

    stage('Terraform Init') {
      steps {
        sh 'terraform init -upgrade'
      }
    }

    stage('Terraform Plan') {
      steps {
        sh 'terraform plan -out=plan.tfout'
      }
    }

    stage('Approval') {
      steps {
        input message: 'Approve Terraform apply?', ok: 'Apply'
      }
    }

    stage('Terraform Apply') {
      steps {
        sh 'terraform apply plan.tfout'
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}