# Altadim is an AI dev setup for your Linux laptop

Altadim is a developer setup for AI technologists that you set up with one command.
If you need customisations, we provide a simple way to expand your setup.

## What you need

- a fresh 24.04.2 Ubuntu LTS install
- an internet connection

## What you always get

- a basic lazyvim setup with some customisation for AI development in Python
- a basic vscode setup with some customisation for AI development in Python
- tools: Alacritty, Zellij, Docker, Tmux, Sqlite, psql, Flameshot
- code assistants: Aider

## What you can optionally install

- Khaldoun's open-source projects to work on

## Testing Environment Setup Manual
This guide explains how to set up a testing environment using VirtualBox and Vagrant to efficiently create and manage virtual machines.

### Required Tools

1. **VirtualBox** - A virtualization platform
   - Installation: [https://www.virtualbox.org/](https://www.virtualbox.org/)

2. **Vagrant** - A tool for building and managing virtual machine environments
   - Installation: [https://developer.hashicorp.com/vagrant/install](https://developer.hashicorp.com/vagrant/install?product_intent=vagrant)

### Pre-Installation Steps

Before installing the required tools, update your system packages:

```bash
sudo apt update && sudo apt upgrade
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
mkdir VMAltadim
cd VMAltadim
```

#### 2. Initialize Git (Optional)

If you want to track changes to your setup:

```bash
git init
```

#### 3. Set Up Vagrant Environment

You have three options to set up your Vagrant environment:

##### Option 1: Automatic Initialization with Vagrant

Initialize a Vagrant environment with a specific box (OS image):

```bash
# For Ubuntu 14.04
vagrant init ubuntu/trusty64

# OR for Ubuntu 22.04
vagrant init ubuntu/jammy64
```

This creates a basic Vagrantfile that you can modify by uncommenting the needed sections.

##### Option 2: Manual Configuration

Create a Vagrantfile manually with your custom configurations:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  
  # Configure VM settings
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
    vb.name = "Altadim_Testing_Environment"
  end
  
  # Network settings
  config.vm.network "private_network", ip: "192.168.56.10"
  
  # Shared folders
  config.vm.synced_folder "./", "/vagrant_data"
  
  # Provisioning
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y git
  SHELL
end
```

##### Option 3: Direct VirtualBox Management

Create and manage your VMs directly through the VirtualBox interface instead of using Vagrant.

#### 4. Starting Your Virtual Machine

Once your Vagrantfile is configured:

```bash
vagrant up
```

#### 5. Accessing Your Virtual Machine

Connect to your running VM:

```bash
vagrant ssh
```

#### 6. Moving Files to Your VM

Transfer files between host and VM:
- Files placed in the project directory are automatically accessible in the VM at `/vagrant`
- For other directories, configure synced folders in your Vagrantfile





## Further info

- We will document how to use your new setup at <https://books.khaldoun.xyz/2/altadim>.
- [Omakub](https://omakub.org/) is the original inspiration for Altadim.
