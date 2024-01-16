# Super-Simple QEMU manager script

> Designed for single user desktop / home server.

Turn your server/desktop to DigitalOcean / Linode / Vultr with a super-simple script.

- Easy setup: No dependency, no libvirt, no user/group/pool config.

- Easy configuration: Simple list your VMs in config file.

- Easy management: Everything in one single directory.

- Easy customization: Just a naive bash script. Everyone knows how to customize.

## Dependency

qemu, bash, sed

> ArchLinux user: simply run `pacman -S cdrkit qemu-base`

## Usage

1. Download this repo to anywhere.
2. Modify `init.settings` and `runtime.settings`.
3. Add `*/2 * * * * cd /path/to/my/repo && ./cron-callback.sh` into your crontab.

## FAQ

## My desired OS is not supported yet...

You can still create a VM in other way (like plain qemu), and put the disk image into `data/vm/VM_NAME/disk.img`. Everything will work perfectly.

