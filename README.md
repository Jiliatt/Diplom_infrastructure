#DevOps: GitOps K8s + Monitoring (Terraform → Ansible → ArgoCD)
## 🚀 Развертывание nолный стек: IaC + CI/CD + Monitoring = Senior-level

## 1. Terraform (инфраструктура)
cd terraform/
terraform init
terraform plan
terraform apply -auto-approve

## 2. КОМАНДЫ ДЕПЛОЯ (копипаст)
export TF_VAR_yc_token="$(yc iam create-token)"
export TF_VAR_yc_cloud_id="$(yc config list | grep cloud-id | cut -d'"' -f4)"
export TF_VAR_yc_folder_id="$(yc config list | grep folder-id | cut -d'"' -f4)"
##------меняешь в provider.tf на свой токен !!! (перед terraform apply)

cd ansible (перед этим меняем хосты (айпи адреса) в ансибл-файле - eсли используешь нединамичный файл то да, если как ниже написано – ниче не меняешь)
ansible-playbook -i inventory/dynamic-inventory.py playbook.yml

### 3. ПРОВЕРКА
ssh ubuntu@IP-master-node 

####GitOps deploy: 
git clone -b feature/k8s-deploy git@github.com:Jilliat/Diplom_infrastructure.git
cd ~/Diplom_infrastructure
git checkout feature/k8s-deploy
git push origin feature/k8s-deploy  #ArgoCD auto-detect → Sync → Deploy

####Kогда зашел на мастер-ноду и проверяешь все -- 
microk8s kubectl get pods -n argocd  # argocd-server Running
!!TOP!! microk8s kubectl get applications -n argocd  # должно Healthy
!!TOP!! microk8s kubectl get all -n diplom -w (2/2 Running ✅)
microk8s kubectl describe application diplom-app -n argocd
microk8s kubectl logs deployment/diplom-app -n diplom  # Django логи
microk8s kubectl get svc -n diplom -o wide

####Т.Е. ТРИ namespace: diplom argocd (ingress ->useless)
####Доступ извне сто проц заработает джанго сервер: ssh -R 80:localhost:30080 serveo.net

###Что делают файлы:

deployment.yaml ✅
replicas: 2 ← 2 poda django
image: edmon2106/diplom-django:latest
namespace: diplom (из Argo Application)

diplom-app.yaml ✅
ArgoCD Application → следит за GitHub:feature/k8s-deploy/k8s-manifests
auto-sync: true ← git push = auto-deploy 2 Pod'ов!

service.yaml ✅
порт


ИТОГОВАЯ ИНФРАСТРУКТУРА (15 минут)
Aрхитектура (сейчас):
1 VM (мастер-нода) IP: 89.169.187.139
    ↓ Ansible устанавливает:
2 MicroK8s кластер (single-node = 1 нода = сама себя)
    ↓ ArgoCD GitOps читает GitHub
3 Deployment diplom-app → **1 реплика** (1 Pod Django)
    ↓ Service NodePort 30080
4 Доступ: 158.160.95.216:30080 → 1 Django под
Сколько реплик? 2 Pod (из deployment.yaml replicas: 2)

🔥 JENKINS + MONITORING SERVER (89.169.184.175):
  • Jenkins: http://89.169.184.175:8080 (CI/CD)
  • Grafana: http://89.169.184.175:3000 (admin/admin)
  • Prometheus: http://89.169.184.175:9090
