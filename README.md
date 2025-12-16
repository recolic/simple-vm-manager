# Super-Simple QEMU manager script

> Designed for single user desktop / home server.

Turn your server/desktop to DigitalOcean / Linode / Vultr with a super-simple script.

- Easy setup: No dependency, no libvirt, no user/group/pool config.

- Easy configuration: Simple list your VMs in config file.

- Easy management: Everything in one single directory.

- Easy customization: Just a naive bash script. Everyone knows how to customize.

## Dependency

qemu, bash, sed

Any of: aria2c / wget / curl

> ArchLinux user: simply run `pacman -S cdrkit qemu-system-x86 qemu-base edk2-ovmf aria2`

## Usage

1. Download this repo to anywhere.
2. Modify `init.settings` and `runtime.settings`.
3. Add `* * * * * bash /path/to/your/cron-callback.sh` into your crontab.

## Built-in cloudimg

> Add more cloudimg into cron-callback.sh.

|                  |name for init.settings    |
| ---              | ---                      |
|Ubuntu 1804 LTS   |`ubuntu-18.04-server.img` |
|Ubuntu 2004 LTS   |`ubuntu-20.04-server.img` |
|Ubuntu 2204 LTS   |`ubuntu-22.04-server.img` |
|Ubuntu 2404 LTS   |`ubuntu-24.04-server.img` |
|Debian 10         |`debian-10.img` |
|Debian 11         |`debian-11.img` |
|Debian 12         |`debian-12.img` |
|Arch Linux Rolling|`archlinux.img`           |

## Built-in back image (virtio support)

**Warning**: This is unofficial back image built by myself. Default login `recolic` password `1`. **USE IT AT YOUR OWN RISK!!!**.

|                    |name for init.settings            |
| ---                | ---                              |
|Windows 10 Pro 22H2 |`win10pro-22h2-virtio-uefi.qcow2` |
|Tiny10 21H2(no RDP) |`win10-tiny10-virtio-uefi.qcow2`  |
|Windows 10 LTSC 2021|`win10ltsc-2021-virtio-uefi.qcow2`|

> Download from my NAS is slow. [Click here](https://recolic.net/blog/post/qemukvm-create-windows-1011-vm-with-tpm-and-secure-boot) to learn how to make win+virtio image by yourself.

## FAQ

### SSH not working for my new VM

Please wait for at least 3 minutes and try again. cloud-init is slow.

### My desired OS is not supported yet...

You can still create a VM in other way (like plain qemu), and put the disk image into `data/vm/VM_NAME/disk.img`. Everything will work perfectly.

Or you can also use an existing qcow2 image as base image. Put it into `data/base/` and use it in init.settings.

## Thanks

ChatGPT
