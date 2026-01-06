pipeline {
    agent any
    environment {
        REGISTRY = 'edmon2106/diplom-django'
	IMAGE_TAG = "${GIT_TAG_NAME}"
        KUBE_MASTER = 'ubuntu@89.169.187.139' //zamena IP k8s-master
    }
    triggers {  // ← ТРИГГЕР ПО ТЕГАМ
        pollSCM('H/5 * * * *')
    }
    stages {
        stage('Build Docker') {
            when { tag pattern: "v.*", comparator: "REGEXP" }
            steps {
                script {
                    def image = docker.build("${REGISTRY}:${BUILD_NUMBER}")
                    docker.withRegistry('https://registry.hub.docker.com', 'dockerhub') {
                        image.push("${IMAGE_TAG}")
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
			    cd ~/Diplom_infrastructure
                            git pull origin feature/k8s-deploy	
                            microk8s helm repo add bitnami https://charts.bitnami.com/bitnami || true
                            microk8s helm repo update
                            microk8s helm upgrade --install diplom-app ./helm --namespace diplom-app --create-namespace \\
                                --set image.repository='${REGISTRY}' \\
                                --set image.tag='${IMAGE_TAG}'
				--wait --timeout 5m
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
}
