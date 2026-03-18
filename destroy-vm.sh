#!/bin/bash

VM_NAME="metrics-vm"

echo "=== Удаление виртуальной машины $VM_NAME ==="

# Проверка что ВМ существует
if ! sudo virsh list --all | grep -q "$VM_NAME"; then
    echo "ВМ $VM_NAME не найдена"
    exit 0
fi

# Остановка ВМ
echo "Остановка ВМ..."
sudo virsh destroy "$VM_NAME" 2>/dev/null || true

# Удаление ВМ и дисков
echo "Удаление ВМ и дисков..."
sudo virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true

# Удаление cloud-init ISO
echo "Удаление временных файлов..."
sudo rm -f "/tmp/cloud-init-${VM_NAME}.iso"
sudo rm -rf "/tmp/cloud-init-${VM_NAME}"

echo ""
echo "=== ВМ $VM_NAME успешно удалена ==="
echo ""
