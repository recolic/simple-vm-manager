#!/bin/bash
# pacman -S cdrkit qemu-base

workdir=./data
mkdir -p "$workdir"
cd "$workdir"
mkdir -p base vm tmp

function generate_metadata () {
    local name=$1
    echo "local-hostname: $name"
}
function generate_userdata () {
    local username=$1
    local password=$2
    local name=$3
    # TODO: allow public key?
    echo "#cloud-config
system_info:
  default_user:
    name: $username
    home: /home/$username

password: $password
chpasswd: { expire: False }
hostname: $name

# configure sshd to allow users logging in using password 
# rather than just keys
ssh_pwauth: True
"
}

function create_vm_from () {
    local name=$1
    local cores=$2
    local ram=$3
    local disk=$4
    local cloudimg=$5
    local username=$6
    local password=$7
    local vnc=$8
    local ports="$9"

    [[ -f "base/focal-server-cloudimg-amd64.img" ]] || aria2c -o "base/focal-server-cloudimg-amd64.img" https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img || ! echo "Failed to download ubuntu cloudimg" || return $?

    if [[ -f "vm/$name/disk.img" ]]; then
        # simply start it
        :
    else
        rm -rf "vm/$name" ; mkdir -p "vm/$name"
        # create and start it
        generate_metadata "$name" > "vm/$name/meta-data" || return $?
        generate_userdata "$username" "$password" "$name" > "vm/$name/user-data" || return $?
        ( cd "vm/$name" ; genisoimage  -output initimg.iso -volid cidata -joliet -rock user-data meta-data ) || return $?
        qemu-img create -f qcow2 -F qcow2 -o backing_file="../../base/focal-server-cloudimg-amd64.img" "vm/$name/disk.img" || return $?
        qemu-img resize "vm/$name/disk.img" "$disk" || return $?
    fi
    # start it
    qemu-system-x86_64 -drive file="vm/$name/disk.img",if=virtio -cdrom "vm/$name/initimg.iso" -m "$ram" -cpu host -smp "$cores" -vnc "$vnc" --enable-kvm -bios /usr/share/edk2-ovmf/x64/OVMF.fd -net nic,model=rtl8139 -net user,hostfwd=tcp::30472-:22 &
    pid=$!
    echo PID=$pid
    # TODO
}

[[ $2 = "" ]] && echo "Temp script to create VM. Usage: $0 MY_GOOD_VM11 :11" && exit 1
create_vm_from "$1" 2 4G 50G __hardcoded__ r 1 "$2" __hardcoded__ || exit $?
echo "DEBUG: sshpass -p 1 ssh -p 30472 r@localhost"

