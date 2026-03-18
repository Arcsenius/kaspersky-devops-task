#!/bin/bash
set -e

# Настройки ВМ
VM_NAME="metrics-vm"
VM_MEMORY=1024
VM_CPUS=1
VM_DISK_SIZE=10
NETWORK_BRIDGE="virbr0"
IMAGE_URL="https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
IMAGE_PATH="/tmp/rocky9-base.qcow2"
VM_DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"

echo "=== Создание виртуальной машины Rocky Linux 9 ==="

if ! systemctl is-active --quiet libvirtd; then
    echo "Ошибка: libvirtd не запущен. Сначала выполните setup-ubuntu-simple.sh"
    exit 1
fi

if sudo virsh list --all | grep -q "$VM_NAME"; then
    echo "Удаление существующей ВМ $VM_NAME..."
    sudo virsh destroy "$VM_NAME" 2>/dev/null || true
    sudo virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Скачивание образа Rocky Linux 9..."
    wget -O "$IMAGE_PATH" "$IMAGE_URL"
else
    echo "Образ уже скачан: $IMAGE_PATH"
fi

echo "Создание диска ВМ..."
sudo rm -f "$VM_DISK_PATH"
sudo qemu-img create -f qcow2 -F qcow2 -b "$IMAGE_PATH" "$VM_DISK_PATH" "${VM_DISK_SIZE}G"

echo "Создание cloud-init конфигурации..."
CLOUD_INIT_DIR="/tmp/cloud-init-${VM_NAME}"
mkdir -p "$CLOUD_INIT_DIR"

# meta-data
cat > "$CLOUD_INIT_DIR/meta-data" << EOF
instance-id: ${VM_NAME}
local-hostname: ${VM_NAME}
EOF

cat > "$CLOUD_INIT_DIR/user-data" << 'EOF'
#cloud-config
users:
  - name: rocky
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDH vagrant-generated-key

# Установка пароля для пользователя rocky (пароль: rocky)
chpasswd:
  list: |
    rocky:rocky
  expire: false

ssh_pwauth: true

package_update: true
package_upgrade: false

runcmd:
  - systemctl enable --now firewalld || true
  - firewall-cmd --permanent --add-port=8080/tcp || true
  - firewall-cmd --reload || true
  - echo "VM is ready" > /var/log/cloud-init-done.log
EOF

# network-config (DHCP)
cat > "$CLOUD_INIT_DIR/network-config" << EOF
version: 2
ethernets:
  eth0:
    dhcp4: true
EOF

# Создание cloud-init ISO
CLOUD_INIT_ISO="/tmp/cloud-init-${VM_NAME}.iso"
sudo genisoimage -output "$CLOUD_INIT_ISO" \
    -volid cidata -joliet -rock \
    "$CLOUD_INIT_DIR/user-data" \
    "$CLOUD_INIT_DIR/meta-data" \
    "$CLOUD_INIT_DIR/network-config"

# Создание ВМ
echo "Создание виртуальной машины..."
sudo virt-install \
    --name "$VM_NAME" \
    --memory "$VM_MEMORY" \
    --vcpus "$VM_CPUS" \
    --disk path="$VM_DISK_PATH",format=qcow2 \
    --disk path="$CLOUD_INIT_ISO",device=cdrom \
    --os-variant rhel9.0 \
    --network network=default \
    --graphics none \
    --console pty,target_type=serial \
    --import \
    --noautoconsole

echo ""
echo "=== ВМ создана и запускается ==="
echo ""
echo "Ожидание загрузки ВМ (30 секунд)..."
sleep 30

echo "Получение IP адреса ВМ..."
VM_IP=""
for i in {1..10}; do
    VM_IP=$(sudo virsh domifaddr "$VM_NAME" | grep -oP '(\d+\.){3}\d+' | head -1 || true)
    if [ -n "$VM_IP" ]; then
        break
    fi
    echo "Попытка $i/10..."
    sleep 5
done

if [ -z "$VM_IP" ]; then
    echo "Не удалось получить IP адрес автоматически"
    echo "Попробуйте вручную: sudo virsh domifaddr $VM_NAME"
    echo "Или подключитесь к консоли: sudo virsh console $VM_NAME"
    VM_IP="<UNKNOWN>"
else
    echo "IP адрес ВМ: $VM_IP"
fi

# Обновление Ansible inventory
echo ""
echo "Обновление Ansible inventory..."
INVENTORY_FILE="$(dirname "$0")/ansible/inventory/hosts.ini"
cat > "$INVENTORY_FILE" << EOF
[metrics_servers]
$VM_IP ansible_user=rocky ansible_password=rocky ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo ""
echo "=== Настройка завершена! ==="
echo ""
echo "Информация о ВМ:"
echo "  Название: $VM_NAME"
echo "  IP адрес: $VM_IP"
echo "  Пользователь: rocky"
echo "  Пароль: rocky"
echo ""
echo "Управление ВМ:"
echo "  sudo virsh list --all              # Список ВМ"
echo "  sudo virsh console $VM_NAME        # Подключение к консоли"
echo "  sudo virsh shutdown $VM_NAME       # Остановка ВМ"
echo "  sudo virsh start $VM_NAME          # Запуск ВМ"
echo "  sudo virsh destroy $VM_NAME        # Принудительная остановка"
echo "  sudo virsh undefine $VM_NAME --remove-all-storage  # Удаление ВМ"
echo ""
echo "Следующий шаг - развёртывание микросервиса:"
echo "  cd ansible"
echo "  ansible-playbook playbook.yml"
echo ""
echo "Если IP адрес не определился, проверьте вручную:"
echo "  sudo virsh domifaddr $VM_NAME"
echo "  или подключитесь к консоли: sudo virsh console $VM_NAME"
echo "  (для выхода из консоли: Ctrl+] )"
echo ""
