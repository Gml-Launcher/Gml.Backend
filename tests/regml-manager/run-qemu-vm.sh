#!/bin/sh

set -eu

VM_DISTRO="${VM_DISTRO:?VM_DISTRO is required}"
VM_ARCH="${VM_ARCH:?VM_ARCH is required}"
INSTALL_VERSION="${INSTALL_VERSION:-v2025.3.1}"
UPDATE_VERSION="${UPDATE_VERSION:-v2025.3.2}"
REPO_DIR="${REPO_DIR:-$(pwd)}"
VM_IMAGE_CACHE="${VM_IMAGE_CACHE:-/tmp/regml-manager-vm-image-cache}"
RUN_DIR="${RUN_DIR:-${RUNNER_TEMP:-/tmp}/regml-manager-vm-${VM_DISTRO}-${VM_ARCH}-$$}"
DIAGNOSTICS_DIR="${DIAGNOSTICS_DIR:-${RUNNER_TEMP:-/tmp}/regml-manager-vm-diagnostics-${VM_DISTRO}-${VM_ARCH}}"
SSH_PORT="${SSH_PORT:-$((2200 + ($$ % 2000)))}"
GUEST_INSTALL_DIR="${GUEST_INSTALL_DIR:-/tmp/regml-manager-ci-${VM_DISTRO}-${VM_ARCH}}"
SSH_USER="${SSH_USER:-root}"
GUEST_REPO_DIR="/root/repo"
QEMU_PID=""

mkdir -p "$VM_IMAGE_CACHE" "$RUN_DIR" "$DIAGNOSTICS_DIR"

log() {
    printf '%s\n' "[vm:$VM_DISTRO/$VM_ARCH] $*"
}

fail() {
    printf '%s\n' "[vm:$VM_DISTRO/$VM_ARCH] Error: $*" >&2
    exit 1
}

single_quote() {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

ssh_base() {
    ssh \
        -i "$SSH_KEY" \
        -p "$SSH_PORT" \
        -o BatchMode=yes \
        -o ConnectTimeout=10 \
        -o ServerAliveInterval=15 \
        -o ServerAliveCountMax=4 \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "$SSH_USER@127.0.0.1" "$@"
}

scp_from_vm() {
    scp \
        -i "$SSH_KEY" \
        -P "$SSH_PORT" \
        -o BatchMode=yes \
        -o ConnectTimeout=10 \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -r "$SSH_USER@127.0.0.1:$1" "$2"
}

install_host_dependencies() {
    if ! command -v apt-get >/dev/null 2>&1; then
        fail "host runner must provide apt-get"
    fi

    packages="curl openssh-client tar qemu-utils cloud-image-utils"

    case "$VM_ARCH" in
        amd64|x86_64)
            packages="$packages qemu-system-x86"
            ;;
        arm64|aarch64)
            packages="$packages qemu-system-arm qemu-efi-aarch64"
            ;;
        *)
            fail "unsupported VM_ARCH: $VM_ARCH"
            ;;
    esac

    log "Installing host QEMU dependencies"
    sudo apt-get update
    sudo apt-get install -y $packages
}

resolve_image() {
    case "$VM_DISTRO:$VM_ARCH" in
        debian-13:amd64|debian-13:x86_64)
            IMAGE_FILE="debian-13-generic-amd64.qcow2"
            IMAGE_URL="https://cloud.debian.org/images/cloud/trixie/latest/$IMAGE_FILE"
            CHECKSUM_URL="https://cloud.debian.org/images/cloud/trixie/latest/SHA512SUMS"
            CHECKSUM_KIND="debian"
            ;;
        debian-13:arm64|debian-13:aarch64)
            IMAGE_FILE="debian-13-generic-arm64.qcow2"
            IMAGE_URL="https://cloud.debian.org/images/cloud/trixie/latest/$IMAGE_FILE"
            CHECKSUM_URL="https://cloud.debian.org/images/cloud/trixie/latest/SHA512SUMS"
            CHECKSUM_KIND="debian"
            ;;
        alpine-3.23:x86_64|alpine-3.23:amd64)
            IMAGE_FILE="oci_alpine-3.23.4-x86_64-bios-cloudinit-r0.qcow2"
            IMAGE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/cloud/$IMAGE_FILE"
            CHECKSUM_URL="$IMAGE_URL.sha512"
            CHECKSUM_KIND="alpine"
            ;;
        alpine-3.23:aarch64|alpine-3.23:arm64)
            IMAGE_FILE="oci_alpine-3.23.4-aarch64-uefi-cloudinit-r0.qcow2"
            IMAGE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/cloud/$IMAGE_FILE"
            CHECKSUM_URL="$IMAGE_URL.sha512"
            CHECKSUM_KIND="alpine"
            ;;
        *)
            fail "unsupported VM image tuple: $VM_DISTRO/$VM_ARCH"
            ;;
    esac

    BASE_IMAGE="$VM_IMAGE_CACHE/$IMAGE_FILE"
    CHECKSUM_FILE="$VM_IMAGE_CACHE/$IMAGE_FILE.sha512"
}

download_and_verify_image() {
    resolve_image

    if [ ! -f "$BASE_IMAGE" ]; then
        log "Downloading $IMAGE_URL"
        curl -fL --retry 5 --retry-delay 5 "$IMAGE_URL" -o "$BASE_IMAGE"
    else
        log "Using cached image $BASE_IMAGE"
    fi

    log "Downloading checksum $CHECKSUM_URL"
    curl -fL --retry 5 --retry-delay 5 "$CHECKSUM_URL" -o "$CHECKSUM_FILE"

    case "$CHECKSUM_KIND" in
        debian)
            expected="$(awk -v file="$IMAGE_FILE" '$2 == file { print $1; exit }' "$CHECKSUM_FILE")"
            ;;
        alpine)
            expected="$(awk 'NF { print $1; exit }' "$CHECKSUM_FILE")"
            ;;
        *)
            fail "unknown checksum kind: $CHECKSUM_KIND"
            ;;
    esac

    if [ -z "$expected" ]; then
        fail "unable to find checksum for $IMAGE_FILE"
    fi

    actual="$(sha512sum "$BASE_IMAGE" | awk '{ print $1 }')"

    if [ "$actual" != "$expected" ]; then
        fail "checksum mismatch for $IMAGE_FILE"
    fi

    log "Image checksum verified"
}

write_cloud_init_seed() {
    SSH_KEY="$RUN_DIR/id_ed25519"
    ssh-keygen -t ed25519 -N "" -f "$SSH_KEY" >/dev/null

    public_key="$(cat "$SSH_KEY.pub")"
    user_data="$RUN_DIR/user-data"
    meta_data="$RUN_DIR/meta-data"
    SEED_ISO="$RUN_DIR/seed.iso"

    cat > "$user_data" <<EOF
#cloud-config
users:
  - default
  - name: root
    lock_passwd: true
    ssh_authorized_keys:
      - $public_key
ssh_pwauth: false
disable_root: false
EOF

    cat > "$meta_data" <<EOF
instance-id: regml-manager-$VM_DISTRO-$VM_ARCH-$$
local-hostname: regml-manager-ci
EOF

    cloud-localds "$SEED_ISO" "$user_data" "$meta_data"
}

prepare_disks() {
    VM_DISK="$RUN_DIR/root.qcow2"
    DOCKER_DISK="$RUN_DIR/docker-data.qcow2"

    qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMAGE" "$VM_DISK" 40G
    qemu-img create -f qcow2 "$DOCKER_DISK" 30G
}

start_vm() {
    SERIAL_LOG="$DIAGNOSTICS_DIR/serial.log"
    QEMU_STDOUT="$DIAGNOSTICS_DIR/qemu.stdout.log"
    QEMU_STDERR="$DIAGNOSTICS_DIR/qemu.stderr.log"

    if [ ! -e /dev/kvm ]; then
        fail "/dev/kvm is not available on this runner"
    fi

    log "Starting QEMU on localhost SSH port $SSH_PORT"

    case "$VM_ARCH" in
        amd64|x86_64)
            qemu-system-x86_64 \
                -enable-kvm \
                -m 8192 \
                -smp 4 \
                -cpu host \
                -drive "file=$VM_DISK,if=virtio,format=qcow2" \
                -drive "file=$DOCKER_DISK,if=virtio,format=qcow2" \
                -drive "file=$SEED_ISO,media=cdrom,readonly=on" \
                -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22" \
                -device virtio-net-pci,netdev=net0 \
                -display none \
                -monitor none \
                -serial "file:$SERIAL_LOG" \
                >"$QEMU_STDOUT" 2>"$QEMU_STDERR" &
            ;;
        arm64|aarch64)
            firmware=""

            for candidate in /usr/share/AAVMF/AAVMF_CODE.fd /usr/share/qemu-efi-aarch64/QEMU_EFI.fd; do
                if [ -f "$candidate" ]; then
                    firmware="$candidate"
                    break
                fi
            done

            if [ -z "$firmware" ]; then
                fail "AArch64 UEFI firmware was not found"
            fi

            qemu-system-aarch64 \
                -machine virt,accel=kvm \
                -m 8192 \
                -smp 4 \
                -cpu host \
                -bios "$firmware" \
                -drive "file=$VM_DISK,if=virtio,format=qcow2" \
                -drive "file=$DOCKER_DISK,if=virtio,format=qcow2" \
                -drive "file=$SEED_ISO,media=cdrom,readonly=on" \
                -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22" \
                -device virtio-net-pci,netdev=net0 \
                -display none \
                -monitor none \
                -serial "file:$SERIAL_LOG" \
                >"$QEMU_STDOUT" 2>"$QEMU_STDERR" &
            ;;
        *)
            fail "unsupported VM_ARCH: $VM_ARCH"
            ;;
    esac

    QEMU_PID="$!"
    echo "$QEMU_PID" > "$DIAGNOSTICS_DIR/qemu.pid"
}

wait_for_ssh() {
    log "Waiting for SSH"

    for attempt in $(seq 1 180); do
        if ssh_base true >/dev/null 2>&1; then
            log "SSH is ready"
            return 0
        fi

        if [ -n "$QEMU_PID" ] && ! kill -0 "$QEMU_PID" 2>/dev/null; then
            fail "QEMU exited before SSH became ready"
        fi

        sleep 5
    done

    fail "timed out waiting for SSH"
}

prepare_guest() {
    log "Preparing guest storage"

    ssh_base 'sh -s' <<'EOF'
        set -eu

        if command -v apk >/dev/null 2>&1; then
            apk add --no-cache e2fsprogs
        elif command -v apt-get >/dev/null 2>&1; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get update
            apt-get install -y e2fsprogs
        fi

        if [ -b /dev/vdb ]; then
            mkdir -p /var/lib/docker

            if ! blkid /dev/vdb >/dev/null 2>&1; then
                mkfs.ext4 -F /dev/vdb
            fi

            if ! grep -q "^/dev/vdb /var/lib/docker " /etc/fstab 2>/dev/null; then
                echo "/dev/vdb /var/lib/docker ext4 defaults,nofail 0 2" >> /etc/fstab
            fi

            mount /var/lib/docker || true
        fi

        id
        uname -a
        cat /etc/os-release
        df -h
EOF
}

sync_repo_to_guest() {
    log "Syncing repository into guest"

    ssh_base "rm -rf $(single_quote "$GUEST_REPO_DIR") && mkdir -p $(single_quote "$GUEST_REPO_DIR")"

    tar \
        --exclude=.git \
        --exclude=.vm-cache \
        --exclude=bin \
        --exclude=obj \
        -C "$REPO_DIR" \
        -cf - . \
        | ssh \
            -i "$SSH_KEY" \
            -p "$SSH_PORT" \
            -o BatchMode=yes \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            "$SSH_USER@127.0.0.1" "tar -C $(single_quote "$GUEST_REPO_DIR") -xf -"
}

run_guest_scenario() {
    log "Running guest scenario"

    remote_env="INSTALL_DIR=$(single_quote "$GUEST_INSTALL_DIR") INSTALL_VERSION=$(single_quote "$INSTALL_VERSION") UPDATE_VERSION=$(single_quote "$UPDATE_VERSION") REPO_DIR=$(single_quote "$GUEST_REPO_DIR")"
    ssh_base "cd $(single_quote "$GUEST_REPO_DIR") && env $remote_env sh tests/regml-manager/scenario.sh"
}

collect_guest_diagnostics() {
    set +eu

    if [ -z "${SSH_KEY:-}" ]; then
        return 0
    fi

    log "Collecting guest diagnostics"

    remote_install_dir="$(single_quote "$GUEST_INSTALL_DIR")"
    ssh_base "INSTALL_DIR=$remote_install_dir sh -s" <<'EOF'
        set +e

        diagnostics_dir=/tmp/regml-manager-diagnostics
        install_dir="$INSTALL_DIR"
        mkdir -p "$diagnostics_dir"

        id > "$diagnostics_dir/id.txt" 2>&1
        uname -a > "$diagnostics_dir/uname.txt" 2>&1
        cat /etc/os-release > "$diagnostics_dir/os-release.txt" 2>&1
        df -h > "$diagnostics_dir/df.txt" 2>&1
        mount > "$diagnostics_dir/mount.txt" 2>&1
        cloud-init status --long > "$diagnostics_dir/cloud-init-status.txt" 2>&1
        cp /var/log/cloud-init.log "$diagnostics_dir/cloud-init.log" 2>/dev/null
        cp /var/log/cloud-init-output.log "$diagnostics_dir/cloud-init-output.log" 2>/dev/null

        docker version > "$diagnostics_dir/docker-version.txt" 2>&1
        docker compose version > "$diagnostics_dir/docker-compose-version.txt" 2>&1
        docker ps -a > "$diagnostics_dir/docker-ps.txt" 2>&1
        docker images > "$diagnostics_dir/docker-images.txt" 2>&1

        if [ -d "$install_dir" ]; then
            (
                cd "$install_dir" &&
                docker compose ps &&
                docker compose images &&
                docker compose logs --tail=200
            ) > "$diagnostics_dir/docker-compose.txt" 2>&1
        fi

        find /tmp -maxdepth 1 -type d -name "regml-manager-ci-*" -print > "$diagnostics_dir/tmp-regml-dirs.txt" 2>&1
EOF

    scp_from_vm /tmp/regml-manager-diagnostics "$DIAGNOSTICS_DIR/guest"
}

cleanup() {
    result="$?"
    set +eu

    collect_guest_diagnostics

    if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
        log "Stopping QEMU"
        kill "$QEMU_PID"
        wait "$QEMU_PID"
    fi

    exit "$result"
}

trap cleanup EXIT INT TERM

install_host_dependencies
download_and_verify_image
write_cloud_init_seed
prepare_disks
start_vm
wait_for_ssh
prepare_guest
sync_repo_to_guest
run_guest_scenario

log "VM scenario completed successfully"
