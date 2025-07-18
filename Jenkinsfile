pipeline {
  agent any

  environment {
    TF_VAR_vsphere_user     = credentials('vsphere-creds').username
    TF_VAR_vsphere_password = credentials('vsphere-creds').password
    TF_VAR_vsphere_server   = credentials('vsphere-server')
  }

  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/pkanderi-abio/TF-VMware', branch: 'main'  # Replace with your repo
      }
    }

    stage('Terraform Init') {
      steps {
        sh 'terraform init'
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
        sh 'terraform apply -auto-approve plan.tfout'
      }
    }
  }

  post {
    always {
      cleanWs()  # Clean workspace
    }
  }
}