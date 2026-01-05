##ФИНАЛЬНЫЙ статус:
Django Deployment (2 реплики) + Service NodePort
PostgreSQL StatefulSet (1 реплика) + headless Service + PVC 5Gi
DATABASE_URL связывает app ↔ БД
---------------------------
cd ~/proj/terraf/diplom_v1_app/helm
helm lint .
helm dependency update  # Скачает Bitnami postgres
helm template myapp . | grep -A5 "volumeClaimTemplates"
---------------------------


GitHub Repository Secrets
GitHub → твой репо → Settings → Secrets and variables → Actions

New repository secret:
DOCKERHUB_USERNAME = emdon2106
DOCKERHUB_TOKEN = Docker Hub Personal Access Token
KUBECONFIG = kubectl config view --raw (скопируй с сервера)




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


