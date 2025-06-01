# Concept for Altadim - a Linux setup for AI technologists

Altadim is a developer setup for AI technologists that you set up with one command.
If you need customisations, we provide a simple way to expand your setup.

[Omakub](https://omakub.org/) is the original inspiration for Altadim.

## For Altadim users

### What you need

- a fresh Ubuntu install
  - we recommend a Ubuntu 22.04 LTS install (e.g. [Pop!_OS](https://system76.com/pop/download/))
  - you can check your Ubuntu version with `lsb_release -a`
- an internet connection

### What you get

- a basic lazyvim setup with some customisation for AI development in Python
- a basic vscode setup with some customisation for AI development in Python
- tools: Alacritty, Zellij, Docker, Tmux, Sqlite, psql

## For Altadim maintainers

This section explains how to set up a virtual machine to test Altadim
using VirtualBox and Vagrant.

- Vagrant lets you specify & manage virtual Linux distributions.
- VirtualBox runs your virtual machines.

### Prepare your setup

- First, update your system packages: `sudo apt update && sudo apt upgrade`
- Install Virtualbox: `sudo apt install virtualbox`
- Install Vagrant: `sudo apt install vagrant`

### Set up your Virtual Machine (VM)

- Create a directory for your VM & initialise git:
  `mkdir ~/vm-altadim && cd ~/vm-altadim && git init`
- Create a `Vagrantfile` with Ubuntu 22.04: `vagrant init ubuntu/jammy64`
- Start your VM with `vagrant up`
- Enter your VM with `vagrant ssh` and leave it with `exit` (or `ctrl + d`)

### Copy Altadim's install file to your VM

- Files in the project directory (the same directory where the `Vagrantfile` sits)
  are automatically accessible in the VM at `/vagrant`.
  - Copy Altadim's install script to the project directory:
    `wget https://raw.githubusercontent.com/khaldoun-xyz/core_skills/main/setup/khaldoun-setup.sh`
- Connect to your VM: `vagrant ssh`
- Navigate to the `/vagrant` directory: `cd /vagrant`
- Run the install script: `bash khaldoun-setup.sh`
