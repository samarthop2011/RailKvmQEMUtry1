
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -lt 2 || $# -gt 4 ]]; then
    echo "Usage: start-vm <ISO> <DISK.qcow2> [RAM_MiB] [VCPUS]"
    exit 2
fi

ISO="$1"
DISK="$2"
RAM="${3:-2048}"
CPUS="${4:-2}"

[[ -f "$ISO" ]] || {
    echo "ISO not found: $ISO"
    exit 1
}

[[ "$RAM" =~ ^[0-9]+$ ]] &&
    (( RAM >= 512 && RAM <= 32768 )) || {
    echo "RAM must be 512-32768 MiB"
    exit 2
}

[[ "$CPUS" =~ ^[0-9]+$ ]] &&
    (( CPUS >= 1 && CPUS <= 16 )) || {
    echo "CPU count must be 1-16"
    exit 2
}

mkdir -p "$(dirname "$DISK")"

if [[ ! -e "$DISK" ]]; then
    qemu-img create -f qcow2 "$DISK" 20G
fi

if [[ -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
    ACCEL="kvm"
    CPU="host"
    echo "Using KVM acceleration."
else
    ACCEL="tcg"
    CPU="max"
    echo "KVM unavailable; falling back to software emulation."
    echo "Expect substantially lower performance."
fi

exec qemu-system-x86_64 \
    -name sam-cloud-lab-vm \
    -machine "q35,accel=$ACCEL" \
    -cpu "$CPU" \
    -smp "$CPUS" \
    -m "$RAM" \
    -drive "file=$DISK,if=virtio,format=qcow2" \
    -cdrom "$ISO" \
    -boot order=d \
    -display none \
    -serial mon:stdio \
    -monitor none \
    -no-reboot
