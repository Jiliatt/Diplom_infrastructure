variable "folder_id" { type = string }
variable "subnet_id" { type = string }
variable "zone" { type = string }
variable "vm_name" { type = string }
variable "cores" { type = number }
variable "memory" { type = number }
variable "disk_size" { type = number }
variable "image_family" { type = string }
variable "nat" { type = bool }
variable "labels" { type = map(string) }

variable "ssh_credentials" {
  type = object({
    user     = string
    pub_key  = string
  })
  default = {
    user    = "ubuntu"
    pub_key = "~/.ssh/id_ed25519.pub"
  }
}
