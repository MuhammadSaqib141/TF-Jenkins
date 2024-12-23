pipeline {
    agent any

    parameters {
        password(name: 'admin_password', description: 'EnterVM password')
    }

    environment {
        ARM_CLIENT_ID      = credentials('AZURE_CLIENT_ID') 
        ARM_CLIENT_SECRET  = credentials('AZURE_CLIENT_SECRET') 
        ARM_TENANT_ID      = credentials('AZURE_TENANT_ID') 
        ARM_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
        TF_VAR_admin_password = "${params.admin_password}"
    }

    stages {
        stage('Clone Repository') {
            steps {
                script {
                    git url: 'https://github.com/MuhammadSaqib141/TF-Jenkins.git', branch: 'main'
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {

                    script {
                        sh '''
                        terraform init -upgrade
                        terraform apply -auto-approve \
                            -var="client_id=$ARM_CLIENT_ID" \
                            -var="client_secret=$ARM_CLIENT_SECRET" \
                            -var="tenant_id=$ARM_TENANT_ID" \
                            -var="subscription_id=$ARM_SUBSCRIPTION_ID"
                            '''
                    }
            }
        }
    }

    post {
        success {
            echo 'Resource Group And Vnet created successfully using Terraform!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
