# DevOps Test Assignment — Metrics Microservice

HTTP-микросервис с Prometheus-метриками (порт 8080), развёртываемый на ВМ через Ansible.

## Структура проекта

```
microservice/     — Python-сервер с метриками + Dockerfile
ansible/          — Роль и плейбук для деплоя (bare / container)
vagrant/          — Локальная ВМ (VirtualBox / QEMU)
terraform/        — Yandex Cloud ВМ
```

## Метрики

- `host_info` — hostname, OS, тип хоста (container / virtual_machine / physical)
- `host_type_info{type="..."}` — gauge (1 для активного типа)

---

## Пререквизиты (macOS)

```bash
brew install ansible vagrant
# Intel Mac: VirtualBox
# Apple Silicon: brew install qemu && vagrant plugin install vagrant-qemu
```

## Запуск через Vagrant (локально)

```bash
cd vagrant
vagrant up                              # bare-режим по умолчанию
curl http://localhost:8080/metrics
```

Для контейнерного режима:

```bash
cd vagrant
ANSIBLE_ARGS='{"deploy_mode":"container"}' vagrant up
# или при уже запущенной ВМ:
cd ../ansible
ansible-playbook playbook.yml -i ../vagrant/.vagrant/provisioners/ansible/inventory -e deploy_mode=container
```

## Запуск через Terraform (Yandex Cloud)

```bash
cd terraform
terraform init
terraform apply \
  -var="yc_token=YOUR_TOKEN" \
  -var="yc_cloud_id=YOUR_CLOUD_ID" \
  -var="yc_folder_id=YOUR_FOLDER_ID"
```

Terraform автоматически создаст `ansible/inventory/hosts.ini`. Затем:

```bash
cd ../ansible
ansible-playbook playbook.yml
curl http://<EXTERNAL_IP>:8080/metrics
```

## Ручной запуск Ansible

```bash
cd ansible
# Заполнить inventory/hosts.ini вручную, затем:
ansible-playbook playbook.yml                          # bare-режим
ansible-playbook playbook.yml -e deploy_mode=container # контейнер
```

## Переключение режимов деплоя

| Переменная    | Значение    | Описание                          |
|---------------|-------------|-----------------------------------|
| `deploy_mode` | `bare`      | Прямой запуск через systemd       |
| `deploy_mode` | `container` | Запуск в Docker-контейнере        |
