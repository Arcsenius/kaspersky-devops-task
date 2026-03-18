# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# инициализация terraform init 
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# выравнивание пробелов terraform fmt 
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
# применить конфигурацию terraform apply
 ##### ## ###### ##### #### ### ## # ###### #######

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = "y0__xCFqsijBhjB3RMguIqX3xYw7s6siQie5cJQGAQz4F61CIfIPV5f4211xA"
  cloud_id  = "b1gam2thhlk8cko5dai2"
  folder_id = "b1g7v74lp97tfa5dfkmb"
  zone      = "default-ru-central1-a"
}

# 2. Создаем сеть и подсеть
resource "yandex_vpc_network" "network-1" {
  name = "devops-network"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "devops-subnet"
  zone           = "ru-central1-a"
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
    nat       = true # Даем публичный IP, чтобы можно было зайти из интернета!
  }

  metadata = {
    # Передаем публичный ключ, чтобы Ansible мог зайти по SSH
    ssh-keys = "almalinux:${file("~/.ssh/yc_key.pub")}"
  }
}

# 5. МАГИЯ: Заставляем Terraform создать файл inventory.ini для Ansible
resource "local_file" "ansible_inventory" {
  content  = <<-DOC
    [webservers]
    ${yandex_compute_instance.vm-1.network_interface.0.nat_ip_address} ansible_user=almalinux ansible_ssh_private_key_file=~/.ssh/yc_key
  DOC
  filename = "../ansible/inventory.ini"
}

# Выводим IP-адрес в консоль после создания
output "external_ip_address_vm" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}