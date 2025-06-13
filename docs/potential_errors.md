# Potential errors you might encounter

- When trying to run `vagrant up` and get:
  "Bringing machine 'default' up with 'libvirt' provider...
  Error while connecting to Libvirt: Error making a connection to libvirt URI qemu:///system:
  Call to virConnectOpen failed: Failed to connect socket
  to '/var/run/libvirt/libvirt-sock': No such file or directory":
  - `sudo apt install libvirt-daemon-system libvirt-clients qemu-kvm`
- If LazyGit crashes with this error msg:
  `stat /home/USER/.config/lazygit/config.yml: no such file or directory`,
  simply create an empty config.yml file in the requested location.
