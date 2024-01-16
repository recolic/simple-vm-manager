# simple-vps-provider

Turn your server/desktop to DigitalOcean / Linode / Vultr with a super-simple script.

No complex configuration, no fancy dependency, no management cost. This project is designed for single user home server. It allows you to easily get a server for testing and dev.

## Dependency

qemu, bash

## Usage

1. Download release and put it in any directory you love.
2. Run `./vps-provider-daemon` in background. (Optional: run it on system startup)
3. Access `http://localhost:6083` and enjoy.

## If you want to modify the configuration...

If you need to do some customization, modify `vps-provider.conf`. The default config usually works fine.

