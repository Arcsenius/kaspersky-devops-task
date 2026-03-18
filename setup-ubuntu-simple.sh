#!/bin/bash
set -e

echo "=== Настройка Ubuntu для создания KVM виртуальных машин ==="

if [ ! -f /etc/lsb-release ]; then
    echo "Ошибка: Этот скрипт предназначен для Ubuntu/Debian систем"
    exit 1
fi

echo ""
echo "Установка необходимых пакетов..."
sudo apt update
sudo apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    virtinst \
    bridge-utils \
    genisoimage \
    ansible \
    sshpass \
    python3 \
    python3-pip \
    wget \
    curl

echo ""
echo "Добавление пользователя $USER в группы libvirt и kvm..."
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

echo ""
echo "Запуск и включение сервиса libvirtd..."
sudo systemctl enable --now libvirtd
sudo systemctl start libvirtd

echo ""
echo "Проверка сети по умолчанию..."
if ! sudo virsh net-list --all | grep -q "default"; then
    echo "Создание сети по умолчанию..."
    sudo virsh net-define /usr/share/libvirt/networks/default.xml
fi

if ! sudo virsh net-list | grep -q "default.*active"; then
    echo "Запуск сети по умолчанию..."
    sudo virsh net-start default
    sudo virsh net-autostart default
fi

echo ""
echo "=== Установка завершена! ==="
echo ""
echo "Установленные версии:"
echo "  KVM: $(kvm --version 2>/dev/null || qemu-system-x86_64 --version | head -1)"
echo "  Ansible: $(ansible --version | head -1)"
echo ""
echo "ВАЖНО: Необходимо перелогиниться или выполнить команду:"
echo "  newgrp libvirt"
echo ""
echo "После этого можно создать ВМ:"
echo "  ./create-vm.sh"
echo ""
