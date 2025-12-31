# Получаем конфигурацию клиента
data "yandex_client_config" "client" {}


# Сеть
resource "yandex_vpc_network" "network" {
  name = var.network_name
  labels = {
    environment = "devops"
  }
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "${var.network_name}-subnet"
  zone           = var.default_zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = var.subnet_cidr
}



# ВМ через модуль
module "k8s_master" {
  source = "./modules"
  folder_id = var.yc_folder_id
  subnet_id      = yandex_vpc_subnet.subnet.id
  zone           = var.default_zone
  vm_name        = "k8s-master"
  cores          = 4
  memory         = 8
  disk_size      = 50
  image_family   = "ubuntu-2004-lts"
  nat            = true

  ssh_credentials = {
    user    = "ubuntu"
    pub_key = "~/.ssh/id_ed25519.pub"
  }

  labels = {
    role = "k8s-master"
  }
}

module "k8s_app" {
  source = "./modules"
  folder_id = var.yc_folder_id
  subnet_id      = yandex_vpc_subnet.subnet.id
  zone           = var.default_zone
  vm_name        = "k8s-app"
  cores          = 4
  memory         = 8
  disk_size      = 50
  image_family   = "ubuntu-2004-lts"
  nat            = true
  
  ssh_credentials = {
    user    = "ubuntu"
    pub_key = "~/.ssh/id_ed25519.pub"
  }

  labels = {
    role = "k8s-app"
  }
}

module "srv_monitoring" {
  source = "./modules"
  folder_id = var.yc_folder_id
  subnet_id      = yandex_vpc_subnet.subnet.id
  zone           = var.default_zone
  vm_name        = "srv-monitoring"
  cores          = 4
  memory         = 16
  disk_size      = 50
  image_family   = "ubuntu-2004-lts"
  nat            = true
  
  ssh_credentials = {
    user    = "ubuntu"
    pub_key = "~/.ssh/id_ed25519.pub"
  }

  labels = {
    role = "monitoring-builds"
  }
}

