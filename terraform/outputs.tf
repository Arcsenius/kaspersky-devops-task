output "external_ip" {
  description = "External IP address of the VM"
  value       = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i ${var.ssh_private_key_path} almalinux@${yandex_compute_instance.vm-1.network_interface.0.nat_ip_address}"
}

output "metrics_url" {
  description = "URL to access Prometheus metrics"
  value       = "http://${yandex_compute_instance.vm-1.network_interface.0.nat_ip_address}:8080/metrics"
}
