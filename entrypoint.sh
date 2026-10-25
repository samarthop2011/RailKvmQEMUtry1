
#!/usr/bin/env bash
set -Eeuo pipefail

export HOME=/root
export SHELL=/bin/bash
PORT="${PORT:-7860}"

if [[ -z "${LAB_PASSWORD:-}" ]]; then
    echo "ERROR: Set LAB_PASSWORD in Railway Variables."
    exit 1
fi

mkdir -p /workspace/isos /workspace/vms \
    /root/.config/code-server
chmod 700 /root/.config/code-server

{
    echo "SAM Cloud Lab"
    date -Is
    id
    echo
    echo "KVM device:"
    if [[ -c /dev/kvm ]]; then
        ls -l /dev/kvm
        [[ -r /dev/kvm && -w /dev/kvm ]] \
            && echo "Device permissions appear accessible." \
            || echo "KVM device permissions deny access."
    else
        echo "/dev/kvm unavailable; QEMU may need software emulation."
    fi
    echo
    qemu-system-x86_64 --version | head -n 1 || true
} > /workspace/KVM-STATUS.txt 2>&1

export PORT LAB_PASSWORD

python3 <<'PY'
import json
import os
from pathlib import Path

port = int(os.environ.get("PORT", "7860"))
if not 1 <= port <= 65535:
    raise SystemExit("PORT must be between 1 and 65535")

password = os.environ["LAB_PASSWORD"]
config = Path("/root/.config/code-server/config.yaml")

config.write_text(
    f"bind-addr: 0.0.0.0:{port}\n"
    "auth: password\n"
    f"password: {json.dumps(password)}\n"
    "cert: false\n"
    "disable-telemetry: true\n",
    encoding="utf-8",
)
config.chmod(0o600)
PY

echo "Starting SAM Cloud Lab on port $PORT"
exec code-server /workspace \
    --config /root/.config/code-server/config.yaml
