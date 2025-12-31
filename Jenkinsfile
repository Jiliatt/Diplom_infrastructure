pipeline {
    agent any
    environment {
        REGISTRY = 'edmon2106/diplom-django'
        KUBE_MASTER = 'ubuntu@84.252.143.154'
    }
    stages {
        stage('Build Docker') {
            steps {
                script {
                    def image = docker.build("${REGISTRY}:${BUILD_NUMBER}")
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub') {
                        image.push("${BUILD_NUMBER}")
                        image.push('latest')
                    }
                }
            }
        }
        stage('Deploy to K8s') {
            steps {
                sshagent(credentials: ['k8s-master-ssh']) {
                    sh '''
                        ssh ${KUBE_MASTER} "
                            microk8s helm repo add bitnami https://charts.bitnami.com/bitnami || true
                            microk8s helm repo update
                            microk8s helm upgrade --install diplom-app ./helm --namespace default --create-namespace \\
                                --set image.repository=edmon2106/diplom-django \\
                                --set image.tag=${BUILD_NUMBER}
                        "
                    '''
                }
            }
        }
    }
    post {
        always {
            sh 'docker image prune -f'
        }
    }
}
