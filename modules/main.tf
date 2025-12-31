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
      "  grafana:",
      "    image: grafana/grafana",
      "    ports:",
      "      - '3000:3000'",
      "    environment:",
      "      - GF_SECURITY_ADMIN_PASSWORD=admin",
      "volumes:",
      "  jenkins_home:",
      "HEREDOC",
      "cd /opt/monitoring && sudo docker-compose up -d &&",
      "echo 'Jenkins ready: http://$(curl -s ifconfig.me):8080'; fi",
      "echo 'Setup complete!'"
    ]
  }
}

