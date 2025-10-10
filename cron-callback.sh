#!/bin/bash

# You may change this directory
svm_workdir="${svm_workdir:-./data}"
ver=1.0.63

_self_bin_name="$0"
function where_is_him () {
    SOURCE="$1"
    while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
        DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    echo -n "$DIR"
}
function where_am_i () {
    _my_path=`type -p ${_self_bin_name}`
    [[ "$_my_path" = "" ]] && where_is_him "$_self_bin_name" || where_is_him "$_my_path"
}
_script_path=`where_am_i`

function echo2 () {
    echo "$@" 1>&2
}
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

# allow password login
ssh_pwauth: True
"
}

function download_cloud_img_if_not_exist () {
    local cloudimg="$1"
    [[ -f "base/$cloudimg" ]] && return

    declare -A knowledge
    # old naming, deprecated
    knowledge["focal-server-cloudimg-amd64.img"]=https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
    knowledge["ubuntu-22.04-server-cloudimg-amd64.img"]=https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
    knowledge["ubuntu-24.04-server-cloudimg-amd64.img"]=https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img
    knowledge["Arch-Linux-x86_64-cloudimg.qcow2"]=https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2
    # new naming
    knowledge["ubuntu-18.04-server.img"]=https://cloud-images.ubuntu.com/releases/18.04/release/ubuntu-18.04-server-cloudimg-amd64.img
    knowledge["ubuntu-20.04-server.img"]=https://cloud-images.ubuntu.com/releases/20.04/release/ubuntu-20.04-server-cloudimg-amd64.img
    knowledge["ubuntu-22.04-server.img"]=https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
    knowledge["ubuntu-24.04-server.img"]=https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img
    knowledge["ubuntu-24.04-server-arm64.img"]=https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-arm64.img
    knowledge["archlinux.img"]=https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2
    # windows baseimg, username r, password 1
    knowledge["win10pro-22h2-virtio-uefi.qcow2"]=https://recolic.net/hms.php?/systems/win10pro-22h2-virtio-uefi.qcow2
    knowledge["win10-tiny10-virtio-uefi.qcow2"]=https://recolic.net/hms.php?/systems/win10-tiny10-virtio-uefi.qcow2
    [ ! "${knowledge[$cloudimg]+abc}" ] && echo2 "Unknown cloudimg $cloudimg. cannot download it." && return 1

    echo2 "+ Downloading cloudimg $cloudimg..."
    if aria2c --version >/dev/null; then
        aria2c  -o "base/$cloudimg" "${knowledge[$cloudimg]}" || ! echo2 "Failed to download ubuntu cloudimg" || return $?
    elif wget --version >/dev/null; then
        wget    -O "base/$cloudimg" "${knowledge[$cloudimg]}" || ! echo2 "Failed to download ubuntu cloudimg" || return $?
    elif curl --version >/dev/null; then
        curl -L -o "base/$cloudimg" "${knowledge[$cloudimg]}" || ! echo2 "Failed to download ubuntu cloudimg" || return $?
    fi
}

function create_vm_if_not_exist () {
    # TODO: support create VM from existing qcow2 snapshot
    local name=$1
    local cloudimg=$2
    local disk=$3
    local username=$4
    local password="$5"

    # Check if disk img already exists.
    [[ -f "vm/$name/disk.img" ]] && return
    [[ -e "vm/$name" ]] && mv "vm/$name" "vm/$name.backup_$RANDOM" ; mkdir -p "vm/$name"

    echo2 "+ Creating VM image $name with options $@..."
    if [ "$disk" != "" ]; then
        # create from cloudimg
        download_cloud_img_if_not_exist "$cloudimg" || return $?
        generate_metadata "$name" > "vm/$name/meta-data" || return $?
        generate_userdata "$username" "$password" "$name" > "vm/$name/user-data" || return $?
        ( cd "vm/$name" ; genisoimage  -output initimg.iso -volid cidata -joliet -rock user-data meta-data ) || return $?
        qemu-img create -f qcow2 -F qcow2 -b "../../base/$cloudimg" "vm/$name/disk.img" || return $?
        qemu-img resize "vm/$name/disk.img" "$disk" || return $?
    else
        # create from baseimg
        download_cloud_img_if_not_exist "$cloudimg" || return $?
        qemu-img create -f qcow2 -F qcow2 -b "../../base/$cloudimg" "vm/$name/disk.img" || return $?
    fi
}

function start_vm_if_not_running () {
    local name=$1
    local options_txt="$2"
    read -a options <<< "$options_txt"

    # For tracking started instance
    local uuid=`uuidgen --namespace @oid --name "qemu.$name" --sha1`

    # Check if qemu already running for this instance.
    ps aux | grep -F "uuid $uuid" | grep qemu > /dev/null 2>&1 && return 0

    # start it
    [[ ! -f "vm/$name/disk.img" ]] && echo2 "In start_vm, disk image vm/$name/disk.img doesn't exist. Did init_vm fail?" && return 1
    echo2 "+ Starting VM $name with options_txt '$options_txt' and uuid $uuid..."
    [[ -f "vm/$name/initimg.iso" ]] && options+=(-cdrom "vm/$name/initimg.iso")
    nohup qemu-system-x86_64 --uuid "$uuid" -drive file="vm/$name/disk.img",if=virtio -cpu host --enable-kvm -net nic,model=virtio-net-pci "${options[@]}" >> tmp/qemu.log 2>&1 & disown
}

function do_init () {
    while IFS= read -r line; do
        # Ignore lines starting with #
        if [[ "$line" =~ ^\# ]]; then
            continue
        fi
        # Trim leading and trailing whitespaces
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        # Check if the line is non-empty
        if [ -n "$line" ]; then
            # Parse the line as "name;cloudimg;disk;username;password", trim space
            IFS=';' read -r name cloudimg disk username password <<< "$(echo "$line" | tr -s '[:space:]' ';')"

            # 2 options or 5 options allowed, otherwise bad config line.
            if [ -n "$name" ] && [ -n "$cloudimg" ] && [ -n "$disk" ] && [ -n "$username" ] && [ -n "$password" ]; then
                create_vm_if_not_exist "$name" "$cloudimg" "$disk" "$username" "$password" || echo2 "Failed to create_vm_if_not_exist. $?"
            elif [ -n "$name" ] && [ -n "$cloudimg" ] && [ ! -n "$disk" ] && [ ! -n "$username" ] && [ ! -n "$password" ]; then
                create_vm_if_not_exist "$name" "$cloudimg" || echo2 "Failed to create_vm_if_not_exist. $?"
            else
                echo2 "Error: Bad configuration line: $line"
            fi
        fi
    done < "$_script_path/init.settings"
}

function do_start () {
    while IFS= read -r line; do
        # Ignore lines starting with #
        if [[ "$line" =~ ^\# ]]; then
            continue
        fi
        # Trim leading and trailing whitespaces
        line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        # Check if the line is non-empty
        if [ -n "$line" ]; then
            # Parse the line as "name;options", only trim space in name, options can contain ;
            name=$(echo "$line" | sed -e 's/[[:space:]]*;.*$//' -e 's/^[[:space:]]*//')
            options=$(echo "$line" | sed 's/^[^;]*;//')
    
            # Check if the name is empty
            if [ -n "$name" ]; then
                start_vm_if_not_running "$name" "$options" || echo2 "Failed to start_vm_if_not_running. $?"
            else
                echo2 "Error: Bad configuration line: $line"
            fi
        fi
    done < "$_script_path/runtime.settings"
}

# Check if current script is already running. Stupid flock is very unreliable.
for pid in $(pidof -x "$0"); do
    if [ $pid != $$ ]; then
        echo "$0 : Process is already running with PID $pid"
        exit 1
    fi
done

mkdir -p "$svm_workdir"
cd "$svm_workdir" || exit $?
mkdir -p base vm tmp

do_init
do_start
