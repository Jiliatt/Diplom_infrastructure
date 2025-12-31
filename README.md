#Должен сначала в докере сделать свой образ (через build), затем поменять в файле Jenkinsfile айпи на свой и идти дальше уже в эту машину где будет jenkins!!

# 🎯 DevOps Диплом: CI/CD → K8s Deploy (Шаг 2)

## ✅ ГОТОВАЯ ИНФРА (из прошлого спринта)
🔥 JENKINS: 89.169.184.175:8080
☸️ K8s Master: 84.252.143.154
☸️ K8s Worker: 51.250.106.129



## 🚀 ШАГ 2: Django App + Helm (СДЕЛАНО)

### 1. Репозиторий приложения

mkdir ~/proj/terraf/diplom_v1_app
cd ~/proj/terraf/diplom_v1_app
git clone https://github.com/vinhlee95/django-pg-docker-tutorial.git .
git checkout -b feature/k8s-deploy
git remote add origin https://github.com/Jiliatt/Diplom_app.git


###2. Docker образ (739MB) 

docker build -t edmon2106/diplom-django:test .
docker login  # edmon2106
docker tag edmon2106/diplom-django:test edmon2106/diplom-django:latest
docker push edmon2106/diplom-django:latest
Проверь: hub.docker.com/u/edmon2106/diplom-django

###3. Helm Chart (Django + Postgres)

diplom_v1_app/
├── app/                 # Django код
├── Dockerfile           # Alpine + non-root user
├── helm/
│   ├── Chart.yaml       # + Bitnami PostgreSQL dependency
│   ├── values.yaml      # edmon2106/diplom-django + vinhle/password
│   └── templates/
│       ├── deployment.yaml  # port:3003, probes, resources
│       └── service.yaml     # NodePort
└── Jenkinsfile          # Build → Push → Helm Deploy
4. Git Push
git add .
git commit -m "Complete CI/CD: Docker+Helm+Jenkins"
git push origin feature/k8s-deploy

###🔄 СЛЕДУЮЩИЙ ШАГ: JENKINS (5 мин)
Идёшь в http://89.169.184.175:8080:

1. New Item → Pipeline → "diplom-django-deploy"
2. GitHub project: https://github.com/Jiliatt/Diplom_app
3. Branch: feature/k8s-deploy
4. Pipeline → SCM → Git → Jenkinsfile
5. Credentials: 
   - dockerhub (Docker Hub edmon2106)
   - k8s-master-ssh (SSH для 84.252.143.154)
6. Build Now → PROFIT!


####🧪 ПРОВЕРКА (после Jenkins)
ssh ubuntu@84.252.143.154 "
    microk8s kubectl get pods
    microk8s kubectl get svc
"
