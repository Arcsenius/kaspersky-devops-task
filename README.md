# Metrics Microservice - Linux Runbook

Инструкция для человека, который впервые видит проект.
ОС хоста: Linux (Ubuntu/Debian).

Проект поднимает ВМ с Rocky Linux 9 и разворачивает микросервис через Ansible.
Микросервис отдает Prometheus-метрики на `:8080` (`/metrics`).

## Что в репозитории

```text
microservice/             # Python сервис + Dockerfile
ansible/                  # playbook и role для деплоя
vagrant/                  # Vagrant-конфиг
setup-ubuntu-host.sh      # подготовка Linux-хоста для Vagrant + libvirt
setup-ubuntu-simple.sh    # подготовка Linux-хоста для create-vm.sh
create-vm.sh              # создание VM через libvirt/KVM
destroy-vm.sh             # удаление VM через libvirt/KVM
```

## Быстрый старт (рекомендуемый путь): libvirt + KVM

Этот путь самый прямой и не зависит от Vagrant.

1. Подготовить Linux-хост:
```bash
chmod +x setup-ubuntu-simple.sh create-vm.sh destroy-vm.sh
./setup-ubuntu-simple.sh
newgrp libvirt
```

2. Создать ВМ:
```bash
./create-vm.sh
```

3. Развернуть сервис Ansible-ом (bare-режим, по умолчанию):
```bash
cd ansible
ansible-playbook playbook.yml
```

4. Проверить метрики с хоста:
```bash
VM_IP=$(awk 'NR==2{print $1}' inventory/hosts.ini)
curl "http://$VM_IP:8080/metrics"
```

5. Удалить ВМ после проверки:
```bash
cd ..
./destroy-vm.sh
```

## Альтернативный путь: Vagrant (через libvirt provider)

1. Подготовить Linux-хост:
```bash
chmod +x setup-ubuntu-host.sh
./setup-ubuntu-host.sh
newgrp libvirt
```

2. Поднять ВМ и применить Ansible:
```bash
cd vagrant
vagrant up --provider=libvirt
```

3. Проверить метрики:
```bash
curl http://localhost:8080/metrics
```

4. Остановить/удалить ВМ:
```bash
vagrant halt
vagrant destroy -f
```

## Контейнерный режим (опционально)

Если нужно проверить бонусный сценарий с Docker:

1. Установить Ansible коллекции:
```bash
ansible-galaxy collection install community.docker ansible.posix
```

2. Запустить playbook в контейнерном режиме:
```bash
cd ansible
ansible-playbook playbook.yml -e deploy_mode=container
```

## Что проверить после деплоя

1. Сервис слушает `8080`.
2. Открывается endpoint `http://<VM_IP>:8080/metrics`.
3. В ответе есть метрики `host_info` и `host_type_info`.

## Частые проблемы

1. После установки `libvirt` нет доступа без `sudo`:
нужно выполнить `newgrp libvirt` или перелогиниться.

2. `create-vm.sh` не определил IP:
выполнить `sudo virsh domifaddr metrics-vm` и вручную поправить `ansible/inventory/hosts.ini`.

3. Ошибка Docker/collections в container-режиме:
установить `community.docker` и `ansible.posix` (команда выше).
