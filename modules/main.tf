terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.149.0"
    }
  }
}




data "yandex_compute_image" "vm_image" {
  family = var.image_family
}



resource "yandex_compute_instance" "vm" {
  name     = var.vm_name
  zone     = var.zone
  hostname = var.vm_name

  resources {
    cores         = var.cores
    memory        = var.memory
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      size      = var.disk_size
      image_id  = data.yandex_compute_image.vm_image.id
      type      = "network-ssd"
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = var.nat
  }

  metadata = {
    serial-port-enable = "1"
    ssh-keys           = "${var.ssh_credentials.user}:${file(var.ssh_credentials.pub_key)}"
  }

  labels = var.labels

  scheduling_policy {
    preemptible = false
  }
}




resource "null_resource" "vm_setup" {
  depends_on = [yandex_compute_instance.vm]

  connection {
    type     = "ssh"
    user     = var.ssh_credentials.user
    private_key = file(replace(var.ssh_credentials.pub_key, ".pub", ""))
    host     = yandex_compute_instance.vm.network_interface[0].nat_ip_address
    timeout  = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '=== VM ${var.vm_name} READY ==='",
      "sudo apt-get update -qq",
      "sudo apt-get install -y docker.io curl",
      "sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo usermod -aG docker ubuntu",
      
      "if [ '${var.vm_name}' = 'srv-monitoring' ]; then echo 'Installing Jenkins + Monitoring';",
      "sudo mkdir -p /opt/monitoring &&",
      "sudo tee /opt/monitoring/docker-compose.yml << 'HEREDOC'",
      "version: '3.8'",
      "services:",
      "  node-exporter:",
      "    image: prom/node-exporter:v1.7.0",
      "    ports:",
      "      - 9100:9100",
      "    volumes:",
      "      - /proc:/host/proc:ro",
      "      - /sys:/host/sys:ro",
      "      - /:/rootfs:ro",
      "     command:",
      "      - --path.procfs=/host/proc",
      "      - --path.rootfs=/rootfs",
      "      - --path.sysfs=/host/sys",
      "  jenkins:",
      "    image: jenkins/jenkins:lts-jdk17",
      "    ports:",
      "      - '8080:8080'",
      "      - '50000:50000'",
      "    volumes:",
      "      - jenkins_home:/var/jenkins_home",
      "  prometheus:",
      "    image: prom/prometheus",
      "    ports:",
      "      - '9090:9090'",
      "    volumes:",
      "      - ./configs:/etc/prometheus:ro",
      "  loki:",
      "    image: grafana/loki:3.1.1",
      "    ports:",
      "      - '3100:3100'",
      "    volumes:",
      "      - loki_data:/loki",
      "    command: -config.file=/etc/loki/local-config.yaml",
      "    restart: always",
      "  grafana:",
      "    image: grafana/grafana",
      "    ports:",
      "      - '3000:3000'",
      "    environment:",
      "      - GF_SECURITY_ADMIN_PASSWORD=admin",
      "volumes:",
      "  loki_data:",
      "  jenkins_home:",
      "HEREDOC",
      
      "sudo mkdir -p /opt/monitoring/configs &&",
      "sudo tee /opt/monitoring/configs/prometheus.yml << 'PROM'",
      "global:",
      "  scrape_interval: 15s",
      "rule_files:",
      "  - alerts.yml",
      "scrape_configs:",
      "  - job_name: prometheus",
      "    static_configs:",
      "      - targets: ['localhost:9090']",
      "  - job_name: diplom-app",
      "    static_configs:",
      "      - targets: [ '10.1.235.215:3003', '10.1.235.216:3003' ]", #ZAMENI NA SVOI na master-node microk8s kubectl get endpoints diplom-app -n diplom-app
      "    metrics_path: '/metrics'",
      "  - job_name: node",
      "    static_configs:",
      "      - targets: ['node-exporter:9100']",
      "PROM",
      "sudo tee /opt/monitoring/configs/alerts.yml << 'ALERTS'",
      "groups:",
      "- name: diplom-app",
      "  rules:",
      "  - alert: AppDown",
      "    expr: up{job=\"diplom-app\"} == 0",
      "    for: 1m",
      "    labels:",
      "      severity: critical",
      "    annotations:",
      "      summary: \"diplom-app DOWN\"",
      "ALERTS",
      "cd /opt/monitoring && sudo docker-compose down && sudo docker-compose up -d &&",
      "echo 'Prometheus targets: http://$(curl -s ifconfig.me):9090/targets'",
      "echo 'Setup complete!'"
    ]
  }
}

