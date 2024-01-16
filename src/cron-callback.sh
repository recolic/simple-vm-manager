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

function download_cloud_img_if_not_exist () {
    local cloudimg="$1"
    [[ "$1" != "focal-server-cloudimg-amd64.img" ]] && echo "ERROR: cloudimg not supported"
    [[ -f "base/$cloudimg" ]] || aria2c -o "base/$cloudimg" https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img || ! echo "Failed to download ubuntu cloudimg" || return $?
}

function create_vm_if_not_exist () {
    # TODO: support create VM from existing qcow2 snapshot
    local name=$1
    local cloudimg=$2
    local disk=$3
    local username=$4
    local password="$5"

    if [[ -f "vm/$name/disk.img" ]]; then
        # already exists
        :
    else
        download_cloud_img_if_not_exist "$cloudimg" || return $?
        rm -rf "vm/$name" ; mkdir -p "vm/$name"
        # create it
        generate_metadata "$name" > "vm/$name/meta-data" || return $?
        generate_userdata "$username" "$password" "$name" > "vm/$name/user-data" || return $?
        ( cd "vm/$name" ; genisoimage  -output initimg.iso -volid cidata -joliet -rock user-data meta-data ) || return $?
        qemu-img create -f qcow2 -F qcow2 -o backing_file="../../base/focal-server-cloudimg-amd64.img" "vm/$name/disk.img" || return $?
        qemu-img resize "vm/$name/disk.img" "$disk" || return $?
    fi
}

function start_vm_if_not_running () {
    local name=$1
    local options="$2"

    # For tracking started instance
    local uuid=`uuidgen --namespace @oid --name "qemu.$name" --sha1`

    # Check if qemu already running for this instance.
    ps aux | grep -F "--uuid $uuid" | grep qemu && return 0

    # start it
    nohup qemu-system-x86_64 --uuid "$uuid" -drive file="vm/$name/disk.img",if=virtio -cdrom "vm/$name/initimg.iso" -cpu host --enable-kvm -bios /usr/share/edk2-ovmf/x64/OVMF.fd -net nic,model=rtl8139 "${options[@]}" & disown
}

# [[ $2 = "" ]] && echo "Temp script to create VM. Usage: $0 MY_GOOD_VM11 :11" && exit 1
# create_vm_from "$1" 2 4G 50G __hardcoded__ r 1 "$2" __hardcoded__ || exit $?
# echo "DEBUG: sshpass -p 1 ssh -p 30472 r@localhost"

while IFS= read -r line; do
    # Ignore lines starting with #
    if [[ "$line" =~ ^\# ]]; then
        continue
    fi

    # Trim leading and trailing whitespaces
    line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # Check if the line is non-empty
    if [ -n "$line" ]; then
        # Parse the line as "name;cloudimg;disk;username;password"
        IFS=';' read -r name cloudimg disk username password <<< "$line"

        # Print the parsed values
        echo "Name: $name"
        echo "Cloud Image: $cloudimg"
        echo "Disk: $disk"
        echo "Username: $username"
        echo "Password: $password"
        echo "---------------------"
    fi
done < ./init.settings


