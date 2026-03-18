#!/bin/bash
set -e


if [ ! -f /etc/lsb-release ]; then
    echo "Ошибка: Этот скрипт предназначен для Ubuntu/Debian систем"
    exit 1
fi

echo ""
echo "1. Удаление старого Vagrant из apt (если установлен)..."
sudo apt remove --purge -y vagrant 2>/dev/null || true

echo ""
echo "2. Установка libvirt и KVM..."
sudo apt update
sudo apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    ansible \
    python3 \
    python3-pip \
    build-essential \
    libxslt-dev \
    libxml2-dev \
    libvirt-dev \
    zlib1g-dev \
    ruby-dev \
    wget \
    gpg

echo ""
echo "3. Установка Vagrant из официального репозитория HashiCorp..."
sudo rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg

wget -O- https://apt.releases.hashicorp.com/gpg 2>/dev/null | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install -y vagrant

echo ""
echo "4. Установка плагина vagrant-libvirt..."
vagrant plugin install vagrant-libvirt

echo ""
echo "5. Добавление пользователя $USER в группы libvirt и kvm..."
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

echo ""
echo "6. Запуск и включение сервиса libvirtd..."
sudo systemctl enable --now libvirtd
sudo systemctl start libvirtd

echo ""
echo "=== Установка завершена! ==="
echo ""
echo "ВАЖНО: Необходимо перелогиниться или выполнить команду:"
echo "  newgrp libvirt"
echo ""
echo "После этого можно запускать:"
echo "  cd vagrant"
echo "  vagrant up --provider=libvirt"
echo ""
