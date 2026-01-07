pipeline {
    agent any
    environment {
        REGISTRY = 'edmon2106/diplom-django'
	IMAGE_TAG = "${env.BUILD_NUMBER}"
        KUBE_MASTER = 'ubuntu@158.160.31.208' //zamena IP k8s-master
	DOCKER_PASSWORD = 'Linck0ut_putt%27'
    }
    triggers {  // ← ТРИГГЕР ПО ТЕГАМ
        pollSCM('H/1 * * * *')
    }
    stages {
        stage('Build Docker') {
            steps {
                script {
                    echo '\${DOCKER_PASSWORD}' | docker login -u edmon2106 --password-stdin &&
                    # Build & Push
                    docker build -t \${REGISTRY}:\${IMAGE_TAG} . &&
                    docker tag \${REGISTRY}:\${IMAGE_TAG} \${REGISTRY}:latest &&
                    docker push \${REGISTRY}:\${IMAGE_TAG} &&
                    docker push \${REGISTRY}:latest
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
	    echo 'Pipeline completed'
        }
    }
}

