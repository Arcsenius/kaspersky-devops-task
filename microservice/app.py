

import os
import platform
import socket
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler

from prometheus_client import (
    CollectorRegistry,
    Gauge,
    Info,
    generate_latest,
)

REGISTRY = CollectorRegistry()

host_info = Info("host", "Host information", registry=REGISTRY)
host_type_gauge = Gauge(
    "host_type_info",
    "Host type indicator (1 = active)",
    ["type"],
    registry=REGISTRY,
)


def detect_host_type():
    if os.path.exists("/.dockerenv"):
        return "container"

    try:
        result = subprocess.run(
            ["systemd-detect-virt"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        virt = result.stdout.strip()
        if result.returncode == 0 and virt and virt != "none":
            return "virtual_machine"
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass

    for dmi_path in [
        "/sys/class/dmi/id/product_name",
        "/sys/class/dmi/id/sys_vendor",
    ]:
        try:
            with open(dmi_path) as f:
                value = f.read().strip().lower()
            if any(
                kw in value
                for kw in ["virtualbox", "vmware", "kvm", "qemu", "xen", "hyper-v"]
            ):
                return "virtual_machine"
        except (FileNotFoundError, PermissionError):
            pass

    return "physical"


def setup_metrics():
    """Заполняет метрики информацией о хосте."""
    host_type = detect_host_type()

    host_info.info(
        {
            "type": host_type,
            "hostname": socket.gethostname(),
            "os": platform.system(),
        }
    )

    for t in ("container", "virtual_machine", "physical"):
        host_type_gauge.labels(type=t).set(1 if t == host_type else 0)


class MetricsHandler(BaseHTTPRequestHandler):
    """Обрабатывает HTTP-запросы, отдаёт Prometheus-метрики."""

    def do_GET(self):
        if self.path in ("/", "/metrics"):
            body = generate_latest(REGISTRY)
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        print(f"[{self.log_date_time_string()}] {args[0]}")


def main():
    setup_metrics()
    server = HTTPServer(("0.0.0.0", 8080), MetricsHandler)
    print("Metrics server listening on :8080")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    server.server_close()


if __name__ == "__main__":
    main()
