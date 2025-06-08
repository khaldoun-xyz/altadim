# How to test Altadim in a virtual machine

This section explains how to set up a virtual machine to test Altadim
using VirtualBox and Vagrant.

- Vagrant lets you specify & manage virtual Linux distributions.
- VirtualBox lets you run virtual machines.

## Prepare your setup

- First, update your system packages: `sudo apt update && sudo apt upgrade`
- Install Virtualbox: `sudo apt install virtualbox`
- Install Vagrant: `sudo apt install vagrant`

## Set up your Virtual Machine (VM)

- Create a directory for your VM & initialise git:
  `mkdir ~/vm-altadim && cd ~/vm-altadim && git init`
- Create a `Vagrantfile` with Ubuntu 24.04:
  `vagrant init bento/ubuntu-24.04 --box-version 202502.21.0`
- Start your VM with `vagrant up`
- Enter your VM with `vagrant ssh` and leave it with `exit` (or `ctrl + d`)

## Copy Altadim's install file to your VM

- Files in the project directory (the same directory where the `Vagrantfile` sits)
  are automatically accessible in the VM at `/vagrant`.
  - Copy Altadim's install script to the project directory:
    `wget https://raw.githubusercontent.com/khaldoun-xyz/altadim/main/install_altadim.sh`
- Connect to your VM: `vagrant ssh`
- Navigate to the `/vagrant` directory: `cd /vagrant`
- Run the install script: `sudo bash install.sh`
