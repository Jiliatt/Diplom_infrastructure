--------------------------------
#on server srv-monitoring  
http://IP-srv-monitoring:8080 # ON JENKINS UI
sudo cat /var/lib/docker/volumes/monitoring_jenkins_home/_data/secrets/initialAdminPassword  
Dashboard → New Item → "Diplom_infrastructure" → Pipeline → OK
меняю айпи в jenkinsfile 
Зайти в Jenkins → Manage Jenkins → Manage Plugins → Available.
Найти “SSH Agent Plugin” и установить
делаешь pipeline from SCM и там указываешь твой созданный глобальны credential и что берешь из jenkinsfile сам скрипт (который в репо удаленном) 

добавить dockerhub (id=dockerhub) and ubuntu-ssh-to-master-node  в credential global!
Configure:
├── General → GitHub project → Project url: https://github.com/Jiliatt/Diplom_infrastructure (Branch: feature/k8s-deploy)
├── Build Triggers → 
│   ✓ GitHub hook trigger for GITScm polling
│   ✓ Poll SCM (H/1 * * * *)  # Каждyu 1 мин
├── Pipeline → 
│   Definition: Pipeline script from SCM
│     делаешь pipeline from SCM и там указываешь твой созданный глобальны credential и что берешь из jenkinsfile сам скрипт (который в репо удаленном) 
└── Save
Build Now → #1 → Console Output → смотри логи
-------------------------------


========================
###Kак должно работать Infrastructure in all:
1. git tag v1.0.1 && git push origin v1.0.1
2. GitHub webhook → Jenkins (89.169.184.175)
3. Jenkins читает Jenkinsfile → Docker build :v1.0.1
4. Jenkins SSH → K8s master (89.169.187.139)
5. microk8s helm upgrade --set image.tag=v1.0.1
6. App обновлён в diplom-app namespace  (microk8s kubectl get all -n diplom-app && microk8s kubectl get pvc -n diplom-app) - master-нода !!! 
========================


---------------------------
Логика: "перед деплоем убедиться, что чарт не сломан" on master noda
cd ~/proj/terraf/diplom_v1_app/helm
helm lint .
helm dependency update  # Скачает Bitnami postgres
helm template myapp . | grep -A5 "volumeClaimTemplates"
---------------------------

========================
#Если оставляешь GitHub Actions то ко всему прочему последний шаг для релиза сделай
GitHub Repository Secrets
GitHub → твой репо → Settings → Secrets and variables → Actions

New repository secret:
DOCKERHUB_USERNAME = emdon2106
DOCKERHUB_TOKEN = Docker Hub Personal Access Token
KUBECONFIG = kubectl config view --raw (скопируй с сервера)
========================

