#DevOps: GitOps K8s + Monitoring (Terraform → Ansible → ArgoCD)
## 🚀 Развертывание nолный стек: IaC + CI/CD + Monitoring = Senior-level

==============================================================================
## 1. Terraform (инфраструктура)
cd terraform/
##------меняешь в provider.tf на свой токен !!! (перед terraform apply)
export TF_VAR_yc_token="$(yc iam create-token)"
export TF_VAR_yc_cloud_id="$(yc config list | grep cloud-id | cut -d'"' -f4)"
export TF_VAR_yc_folder_id="$(yc config list | grep folder-id | cut -d'"' -f4)"

terraform init
terraform plan
terraform apply -auto-approve

## 2. КОМАНДЫ ДЕПЛОЯ (копипаст)
cd ansible (перед этим меняем хосты (айпи адреса) в ансибл-файле - eсли используешь нединамичный файл то да, если как ниже написано – ниче не меняешь)
ansible-playbook -i inventory/dynamic-inventory.py playbook.yml
==============================================================================


==============================================================================
### 3. ПРОВЕРКА
ssh ubuntu@IP-master-node 

####GitOps deploy: 
git clone -b feature/k8s-deploy git@github.com:Jilliat/Diplom_infrastructure.git
cd ~/Diplom_infrastructure
git checkout feature/k8s-deploy
git push origin feature/k8s-deploy  #ArgoCD auto-detect → Sync → Deploy

####Kогда зашел на мастер-ноду и проверяешь все -- 
!!TOP!! microk8s kubectl get applications -n argocd    # должно Healthy
!!TOP!! microk8s kubectl get all -n diplom             # ArgoCD GitOps
!!TOP!! microk8s kubectl get all -n diplom-app         # Jenkins CI/CD (Helm + тег)
microk8s kubectl get ns                                # diplom-app & diplom & argocd &
microk8s kubectl describe application diplom-app -n argocd
microk8s kubectl get pods -n argocd                    # argocd-server Running
microk8s kubectl logs deployment/diplom-app -n diplom  # Django логи
microk8s kubectl get svc -n diplom -o wide


microk8s kubectl get all -n diplom        # ArgoCD app
microk8s kubectl get all -n diplom-app    # Jenkins app

Тест обоих сценариев CI/CD:
# Jenkins and GitHub Actions - release v1.0 ->
git tag v1.0.1
git push origin v1.0.1           #Jenkins auto-start 

####То есть четыре namespace: diplom & diplom-app & argocd & (ingress ->useless; diplom for argocd + diplom-app for jenkins (helm))
####Доступ извне сто проц заработает джанго сервер: ssh -R 80:localhost:30080 serveo.net
==============================================================================


==============================================================================
###Что делают файлы небольшое пояснение: 

deployment.yaml ✅
replicas: 2 ← 2 poda django
image: edmon2106/diplom-django:latest
namespace: diplom (из Argo Application)

diplom-app.yaml ✅
ArgoCD Application → следит за GitHub:feature/k8s-deploy/k8s-manifests
auto-sync: true ← git push = auto-deploy 2 Pod'ов!

service.yaml ✅
порт
==============================================================================


==============================================================================
###ИТОГОВАЯ ИНФРАСТРУКТУРА

***
"У меня 3 CI/CD подхода:
1. GitOps  (ArgoCD + k8s-manifests): namespace "diplom" (:latest) (for use git push → ArgoCD)
2. CI/CD (Jenkins + Helm): namespace "diplom-app" (:v1.0.1 + Postgres PVC) (for use git tag v1.0 → Jenkins or GitHub Actions (demo))
3. GitHub Actions — cloud-native (file in app-directory .github/workflows/cicd.yml") (для этого use нужно почитать файл readme.md в директории приложения, там еще секреты добавить на гит-репо нужно)
==============================================================================



==============================================================================
Aрхитектура:
1 VM (мастер-нода) IP: 89.169.187.139
    ↓ Ansible устанавливает:
2 MicroK8s кластер (single-node = 1 нода = сама себя)
    ↓ ArgoCD GitOps читает GitHub
3 Deployment diplom-app (this name for type of Deployment in K8s, not for label of namespace) → **1 реплика** (1 Pod Django)
    ↓ Service NodePort 30080
4 Доступ: 158.160.95.216:30080 → 1 Django под
Сколько реплик? 2 Pod (из deployment.yaml replicas: 2)
==============================================================================



==============================================================================
###у меня реализовано три подхода -
1. ArgoCD GitOps (уже работает): namespace diplom!!
Использует:
├── k8s-manifests/
│   ├── deployment.yaml  ← replicas: 2, image: edmon2106/diplom-django:latest
│   ├── service.yaml     ← NodePort
│   └── diplom-app.yaml  ← Argo Application (auto-sync)
└── tmp/diplom-app.yaml (Argo Application):
    ├── Контроллер: namespace argocd
    ├── Источник: k8s-manifests/ (git push → sync)
    └── Destination: namespace "diplom" ← твои поды!
Логика: git push → ArgoCD → kubectl apply k8s-manifests → namespace "diplom"

2. Jenkins CI/CD (тут два в одном + GitHub Actions): namespace diplom-app!!
Использует:
├── Jenkinsfile                ← Docker build + helm deploy
└── helm/                      ← Helm-чарт (тут и github Actions)
    ├── deployment.yaml           → diplom-app-diplom-app (image: :v1.0.1)
    ├── postgres-statefulset.yaml → diplom-app-postgres (PVC!)
    └── service.yaml              → diplom-app NodePort          

Логика: git tag v1.0.1 → Jenkins → Docker:v1.0.1 → helm upgrade image.tag=v1.0.1 → namespace "diplom-app"
==============================================================================


🔥srv-monitoring:
  • Jenkins: http://ip:8080 (CI/CD)
  • Grafana: http://ip:3000 (admin/admin)
  • Prometheus: http://ip:9090
