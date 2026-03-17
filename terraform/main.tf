terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# Сеть и подсеть
resource "yandex_vpc_network" "network-1" {
  name = "devops-network"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "devops-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

data "yandex_compute_image" "almalinux" {
  family = "almalinux-9"
}

resource "yandex_compute_instance" "vm-1" {
  name = "microservice-host"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.almalinux.id
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }

  metadata = {
    ssh-keys  = "almalinux:${file(var.ssh_public_key_path)}"
    user-data = file("${path.module}/cloud-init.yml")
  }
}

# Генерация Ansible inventory
resource "local_file" "ansible_inventory" {
  content = <<-DOC
    [metrics_servers]
    ${yandex_compute_instance.vm-1.network_interface.0.nat_ip_address} ansible_user=almalinux ansible_ssh_private_key_file=${var.ssh_private_key_path}
  DOC

  filename = "${path.module}/../ansible/inventory/hosts.ini"
}
