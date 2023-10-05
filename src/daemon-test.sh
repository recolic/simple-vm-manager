# aria2c 'https://cloud-images.ubuntu.com/focal/20231003/focal-server-cloudimg-amd64.img' -x2
# https://medium.com/@art.vasilyev/use-ubuntu-cloud-image-with-kvm-1f28c19f82f8

cp template/*-data .
genisoimage  -output initimg.iso -volid cidata -joliet -rock user-data meta-data
qemu-img create -f qcow2 -F qcow2 -o backing_file=base/focal-server-cloudimg-amd64.img instance-1.qcow2
qemu-img resize instance-1.qcow2 60G
qemu-system-x86_64 -drive file=instance-1.qcow2,if=virtio -cdrom initimg.iso -m 8G -cpu host -smp 4 -vnc :5 --enable-kvm -bios /usr/share/edk2-ovmf/x64/OVMF.fd

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

workdir=./data
mkdir -p "$workdir/base" "$workdir/vm" "$workdir/tmp"
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

    if [[ -f "$workdir/vm/$name/disk.img" ]]; then
        # simply start it
        return
    else
        # create and start it
        generate_metadata "$name" > "$workdir/vm/$name/meta-data"
        generate_userdata "$username" "$password" "$name" > "$workdir/vm/$name/user-data"
        ( cd "$workdir/vm/$name" ; genisoimage  -output initimg.iso -volid cidata -joliet -rock user-data meta-data )
        qemu-img create -f qcow2 -F qcow2 -o backing_file=base/focal-server-cloudimg-amd64.img "$workdir/vm/$name/disk.img"
        qemu-img resize "$workdir/vm/$name/disk.img" "$disk"
        qemu-system-x86_64 -drive file="$workdir/vm/$name/disk.img",if=virtio -cdrom "$workdir/vm/$name/initimg.iso" -m "$ram" -cpu host -smp "$cores" -vnc "$vnc" --enable-kvm -bios /usr/share/edk2-ovmf/x64/OVMF.fd -net nic,model=rtl8139 -net user,hostfwd=tcp::30472-:22 &
        pid=$!
        echo PID=$pid
        # TODO
    fi
}


