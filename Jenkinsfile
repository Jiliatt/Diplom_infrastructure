pipeline {
    agent any
    environment {
        REGISTRY = 'edmon2106/diplom-django'
	IMAGE_TAG = "${env.BUILD_NUMBER}"
        KUBE_MASTER = 'ubuntu@158.160.80.129' //zamena IP k8s-master
    }
    triggers {  // ← ТРИГГЕР ПО ТЕГАМ
        pollSCM('H/1 * * * *')
    }
    stages {
        stage('Build Docker') {
            when { tag pattern: "v.*", comparator: "REGEXP" }
            steps {
                script {
		    def tag = env.BUILD_NUMBER
		    def image = docker.build("edmon2106/diplom-django:${tag}")
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
			    cd ~/Diplom_infrastructure &&
                            git pull origin feature/k8s-deploy &&	
                            microk8s helm upgrade --install diplom-app ./helm --namespace diplom-app --create-namespace --reuse-values \\
                                --set image.repository='${REGISTRY}' \\
                                --set image.tag='${IMAGE_TAG}' \\
				--wait --timeout 5m
                        "
                    '''
                }
            }
        }
    }
    post {
        always {
	    echo 'Cleanup skipped - no Docker in Jenkins agent'
        }
    }
}

