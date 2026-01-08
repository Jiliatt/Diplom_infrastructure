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
## сначала терраформ, ансибл, дженкинс, затем добавляешь дашборды в графане

## В скрипт ансибла добавить своего ТГ-бота!!

cd ansible 
ansible-playbook -i inventory/dynamic-inventory.py playbook.yml
## Скопировать вывод id_ed25519.pub и добавить в GitHub → Settings → SSH and GPG keys → New SSH key → вставить
ansible-playbook -i inventory/dynamic-inventory.py playbook.yml --start-at-task="Clone repo"

в модуле терраформа (функция remote-exec) изменить на свои айпи внутренние после дженкинса, полсе того как появится diplom-app 
(там есть подсказка где конкретно)

==============================================================================


==============================================================================
### 3. ПРОВЕРКА
ssh ubuntu@IP-master-node 

####GitOps deploy: 

####Kогда зашел на мастер-ноду и проверяешь все -- 
git push origin feature/k8s-deploy  #ArgoCD auto-detect → Sync → Deploy

!!TOP!! microk8s kubectl get applications -n argocd    # должно Healthy
!!TOP!! microk8s kubectl get all -n diplom             # ArgoCD GitOps
!!TOP!! microk8s kubectl get all -n diplom-app         # Jenkins CI/CD (Helm + тег)
microk8s kubectl logs deployment/diplom-app -n diplom  # Django логи

  проверка после ансибл скрипта (мониторинг-сервер)
curl SRV-monitoring _IP:9090/targets  # node/blackbox/prometheus UP
curl SRV-monitoring _IP:3000          # Grafana login
curl SRV-monitoring_IP:3100/ready    # Loki ready

 (ЭТО НА МАСТЕР НОДЕ snizy)
microk8s kubectl get pods -n logging  # loki-0 promtail-daemonset UP 
microk8s kubectl logs -n logging -l app.kubernetes.io/name=promtail  # видит srv:3100? 
   Алерты:
microk8s kubectl delete pod -l app=diplom-app  # recreate
curl localhost:9090/api/v1/alerts  # AppDown firing
Telegram → "App diplom-app DOWN" <2min!

Затем настраиваешь графану (дашборды) на мониторинг-сервере:
Grafana (ip:3000 admin/admin):
Add Prometheus datasource Prometheus (http://prometheus:9090) Loki (http://loki:3100).
Import dashboards 1860 Node Exporter Full && 6417 K8s Cluster && 12019 Loki Logs (фильтр {app="diplom-app"})


microk8s kubectl get all -n diplom        # ArgoCD app
microk8s kubectl get all -n diplom-app    # Jenkins app

Тест обоих сценариев CI/CD:
# Jenkins and GitHub Actions - release v1.0 ->
git tag v1.0.1
git push origin v1.0.1           #Jenkins auto-start 

####То есть четыре namespace: diplom & diplom-app & argocd & (ingress ->useless; diplom for argocd + diplom-app for jenkins (helm))
####Доступ извне сто проц заработает джанго сервер: ssh -R 80:localhost:31195 serveo.net
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
