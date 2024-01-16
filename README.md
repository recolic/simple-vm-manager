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
3. Add ``

## If you want to modify the configuration...

If you need to do some customization, modify `vps-provider.conf`. The default config usually works fine.

