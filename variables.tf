
variable "default_zone" {
  description = "Default zone"
  type        = string
  default     = "ru-central1-b"
}

variable "network_name" {
  type    = string
  default = "devops-v1-network"
}

variable "subnet_cidr" {
  type    = list(string)
  default = ["192.168.10.0/24"]
}

variable "yc_folder_id" { type = string }

variable "yc_cloud_id" { type = string }

variable "yc_token" { type = string }


#variable "vm_params" {
#  description = "Параметры ВМ"
#  type = map(object({
#    cores        = number
#    memory       = number
#    disk_size    = number
#    image_family = string
#    nat          = bool
#    labels       = optional(map(string), {})
#  }))
#  
#  default = {}
#}

