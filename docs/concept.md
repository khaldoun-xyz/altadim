# Altadim is an AI dev setup for your Linux laptop

Altadim is a developer setup for AI technologists that you set up with one command.
If you need customisations, we provide a simple way to expand your setup.

## What you need

- A fresh 24.04.2 Ubuntu LTS install


```bash
# You can check your Ubuntu version typing the following command in your terminal.
lsb_release -a
```
- An internet connection

## What you always get

- a basic lazyvim setup with some customisation for AI development in Python
- a basic vscode setup with some customisation for AI development in Python
- tools: Alacritty, Zellij, Docker, Tmux, Sqlite, psql, Flameshot
- code assistants: Aider

## What you can optionally install

- Khaldoun's open-source projects to work on

## Set up a virtual machine to test Altadim
This guide explains how to set up a testing environment using VirtualBox and Vagrant to efficiently create and manage virtual machines.

### Required Tools

### Pre-Installation Steps

Before installing the required tools, update your system packages:

```bash
sudo apt update && sudo apt upgrade
```

1. **VirtualBox** - A virtualization platform
   - Installation: [https://www.virtualbox.org/](https://www.virtualbox.org/)

2. **Vagrant** - A tool for building and managing virtual machine environments
```bash
 wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
```


### Why Use Vagrant with VirtualBox

Vagrant with VirtualBox allows you to:
- Create local virtual machines using simple commands
- Set up environments without needing ISO files
- Test setups across different operating system versions
- Define machine configurations in code (Infrastructure as Code)

### Setting Up Your Testing Environment

#### 1. Create a Directory for Your Virtual Machine

Create a dedicated folder for each VM environment:

```bash
mkdir vm-altadim
cd vm-altadim
```

#### 2. Initialize Git (Optional)

If you want to track changes to your setup:

```bash
git init
```

#### 3. Set Up Vagrant Environment

You have multiple options to set up your Vagrant environment, we've chosen this approach:

##### Automatic Initialization with Vagrant

Initialize a Vagrant environment with a specific box (OS image):

```bash
# For Ubuntu 14.04
vagrant init ubuntu/trusty64

# For Mac users (if facing trouble)
vagrant init  perk/ubuntu-2204-arm64

# OR for Ubuntu 22.04
vagrant init ubuntu/jammy64
```


This creates a basic Vagrantfile that you can modify by uncommenting the needed sections or adding to the file.



#### 4. Starting Your Virtual Machine

Once your Vagrantfile is configured:

```bash
vagrant up
```

```Ruby
# For Mac users (if error: No image virtual size specified for box)
 # alter this part inside your Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "perk/ubuntu-2204-arm64"

  config.vm.provider "virtualbox" do |vb|
    # You can add VirtualBox specific configurations here if needed
  end
end
# Make sure to precise VirtualBox as a provider
```

#### 5. Accessing Your Virtual Machine

Connect to your running VM:

```bash
vagrant ssh
```

#### 6. Moving Files to Your VM and running the setup

Transfer files between host and VM:
- Files placed in the project directory are automatically accessible in the VM at `/vagrant` ==>
      Place Altadim setup file in the vm-alatdim directory and run it once in your Vm
- For other directories, configure synced folders in your Vagrantfile


```bash
# Place the file Khaldoun-setup.sh inside vm-altadim directory 
cp khaldoun_setup.sh vm-altadim/
```

Inside the Virtual Machine run:


```bash
# Place the file Khaldoun-setup.sh inside vm-altadim directory 
bash khaldoun_setup.sh
```

## Further info

- We will document how to use your new setup at <https://books.khaldoun.xyz/2/altadim>.
- [Omakub](https://omakub.org/) is the original inspiration for Altadim.
