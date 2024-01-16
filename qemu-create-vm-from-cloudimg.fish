# aria2c 'https://cloud-images.ubuntu.com/focal/20231003/focal-server-cloudimg-amd64.img' -x2
# https://medium.com/@art.vasilyev/use-ubuntu-cloud-image-with-kvm-1f28c19f82f8

cp template/*-data .
genisoimage  -output initimg.iso -volid cidata -joliet -rock user-data meta-data
qemu-img create -f qcow2 -F qcow2 -o backing_file=base/focal-server-cloudimg-amd64.img instance-1.qcow2
qemu-img resize instance-1.qcow2 60G
qemu-system-x86_64 -drive file=instance-1.qcow2,if=virtio -cdrom initimg.iso -m 8G -cpu host -smp 4 -vnc :5 --enable-kvm -bios /usr/share/edk2-ovmf/x64/OVMF.fd



