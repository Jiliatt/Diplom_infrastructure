

output "k8s_master_ip" {
  value = module.k8s_master.external_ip
}

output "k8s_app_ip" {
  value = module.k8s_app.external_ip
}

output "srv_monitoring_ip" {
  value = module.srv_monitoring.external_ip
}



output "network_id" {
  value = yandex_vpc_network.network.id
}

