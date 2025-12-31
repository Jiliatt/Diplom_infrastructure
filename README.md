# DevOps диплом: K8s + Monitoring

## 🚀 Развертывание (5 минут)

### 1. Terraform (инфраструктура)
cd terraform/
export YC_TOKEN=$(yc iam create-token)
terraform init
terraform apply

### 2. КОМАНДЫ ДЕПЛОЯ (копипаст)
export TF_VAR_yc_token="$(yc iam create-token)"
export TF_VAR_yc_cloud_id="$(yc config list | grep cloud-id | cut -d'"' -f4)"
export TF_VAR_yc_folder_id="$(yc config list | grep folder-id | cut -d'"' -f4)"

cd ansible (перед этим меняем хосты (айпи адреса) в ансибл-файле)
ansible-playbook -i inventory.yml playbook.yml

### 3. ПРОВЕРКА
ssh ubuntu@84.252.143.154 "sudo microk8s kubectl get nodes"
curl http://89.169.184.175:8080 / :3000



ИТОГОВАЯ ИНФРАСТРУКТУРА (15 минут)
text
🔥 JENKINS + MONITORING SERVER (89.169.184.175):
  • Jenkins: http://89.169.184.175:8080 (CI/CD)
  • Grafana: http://89.169.184.175:3000 (admin/admin)
  • Prometheus: http://89.169.184.175:9090

☸️  MICOK8s КЛАСТЕР (2 ноды):
  • Master: 84.252.143.154 (Ready 15m, v1.28.15)
  • Worker: 51.250.106.129 (Ready 13m, v1.28.15)
  • kubectl get nodes → 2/2 Ready!

🌐 TERRAFORM:
  • 3 VM + VPC diplom-net + NAT
  • Docker + docker-compose на всех
