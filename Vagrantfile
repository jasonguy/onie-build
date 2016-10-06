# -*- mode: ruby -*-
# vi: set ft=ruby :

# Device settings
VM_NAME   = "onie-build"
VM_CPUS   =  4
VM_MEMORY =  4 * 1024 # in MB
VM_DISK   = 60        # in GB
NEW_DISK  = "big-disk2.vdi"

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Configuration of new VM..
  # 
  config.vm.define :device do |device|
    # Box name
    #
    device.vm.box = "debian/jessie64"

    device.vm.hostname = VM_NAME

    # Domain Specific Options
    #
    # See README for more info.
    #
    device.vm.provider :libvirt do |kvm|
      kvm.memory = VM_MEMORY
      kvm.cpus = VM_CPUS
      kvm.storage :file, :size => VM_DISK # Second disk
    end

    device.vm.provider :virtualbox do |vb|
      vb.gui = false
      vb.name = VM_NAME
      vb.cpus = VM_CPUS
      vb.memory = VM_MEMORY
      vb.customize ["modifyvm", :id, '--audiocontroller', 'AC97', '--audio', 'Null']

      # Increase the disk size
      vb.customize [
        "storagectl", :id,
        "--name", "SATA Controller",
        "--controller", "IntelAHCI",
        "--portcount", "1",
        "--hostiocache", "on"
      ]
      
      file_to_disk = "#{ENV["HOME"]}/VirtualBox VMs/#{vb.name}/#{NEW_DISK}"
      if ARGV[0] == "up" && ! File.exist?(file_to_disk)
        vb.customize [
          'createhd',
          '--filename', file_to_disk,
          '--format', 'VDI',
          '--size', VM_DISK * 1024  # Size in MB
        ]
        vb.customize [
          'storageattach', :id,
          '--storagectl', 'SATA Controller', # The name may vary
          '--port', 1, '--device', 0,
          '--type', 'hdd', '--medium',
          file_to_disk
        ]
      
      end
        
    end

    # Shared Folder
    device.vm.synced_folder ".", "/vagrant", disabled: true

  end

  # Options for libvirt vagrant provider.
  config.vm.provider :libvirt do |libvirt|

    # A hypervisor name to access. Different drivers can be specified, but
    # this version of provider creates KVM machines only. Some examples of
    # drivers are kvm (qemu hardware accelerated), qemu (qemu emulated),
    # xen (Xen hypervisor), lxc (Linux Containers),
    # esx (VMware ESX), vmwarews (VMware Workstation) and more. Refer to
    # documentation for available drivers (http://libvirt.org/drivers.html).
    libvirt.driver = "kvm"

    # The name of the server, where libvirtd is running.
    # libvirt.host = "localhost"

    # If use ssh tunnel to connect to Libvirt.
    libvirt.connect_via_ssh = false

    # The username and password to access Libvirt. Password is not used when
    # connecting via ssh.
    libvirt.username = "root"
    #libvirt.password = "secret"

    # Libvirt storage pool name, where box image and instance snapshots will
    # be stored.
    libvirt.storage_pool_name = "default"

    # Set a prefix for the machines that's different than the project dir name.
    #libvirt.default_prefix = ''
  end


  if ARGV[0] == "up" || (ARGV.include?("reload") && ARGV.include?("--provision"))
      # Copy files to vagrant home
      config.vm.provision "file", source: Dir.getwd + "/00-header", destination: "~/00-header"
      config.vm.provision "file", source: Dir.getwd + "/10-sysinfo", destination: "~/10-sysinfo"
      config.vm.provision "file", source: Dir.getwd + "/50-oniehelp", destination: "~/50-oniehelp"
      config.vm.provision "file", source: Dir.getwd + "/90-footer", destination: "~/90-footer"
      config.vm.provision "file", source: Dir.getwd + "/oniehelp", destination: "~/oniehelp"
  end
  # Fix for https://github.com/mitchellh/vagrant/issues/1673
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  # Provision admin-level things
  config.vm.provision "shell", privileged: true, inline: <<-ROOTSHELL
    # update apt if cache is older than 10 minutes
    if [ "$[$(date +%s) - $(stat -c %Z /var/lib/apt/periodic/update-success-stamp)]" -ge 600000 ]; then
      apt-get update
    fi

    # install git, build tools, certs, and pkg-config for onie building
    # install parted for partitioning second disk
    # install lsb-release and figlet for motd enhancement
    apt-get install -y vim git build-essential ca-certificates pkg-config parted lsb-release figlet tree
    
    # MOTD upgrade
    # create directory
    mkdir /etc/update-motd.d/
    # change to new directory
    cd /etc/update-motd.d/
    # move dynamic files
    cp ~vagrant/00-header .
    cp ~vagrant/10-sysinfo .
    cp ~vagrant/50-oniehelp .
    cp ~vagrant/90-footer .
    rm ~vagrant/*-*
    # make files executable
    chmod +x /etc/update-motd.d/*
    # remove MOTD file
    rm /etc/motd
    # symlink dynamic MOTD file
    ln -s /var/run/motd /etc/motd

    # Install onie helper
    cp ~vagrant/oniehelp /usr/local/bin
    rm ~vagrant/oniehelp
    chmod +x /usr/local/bin/oniehelp
  ROOTSHELL


  config.vm.provision "shell", privileged: true, path: 'data_disk_setup.sh'

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    echo "Getting ONIE source and setting up environment"
    cd /data
    git clone https://github.com/opencomputeproject/onie.git
    cd onie/build-config
    make debian-prepare-build-host
    echo "export PATH='/sbin:/usr/sbin:$PATH'" >> $HOME/.bashrc
    git config --global user.email "you@example.com"
    git config --global user.name "Your Name"
  SHELL

 
  # Setup git environment 
  if ARGV[0] == "up" && ! File.exist?("#{Dir.home}/.gitconfig")
    # Local user does not use git, so populte with dummy values
    config.vm.provision "shell", privileged: false, inline: <<-GIT
      git config --global user.email "onie-build@`grep domain /etc/resolv.conf | awk '{ print $2 }'`"
      git config --global user.name 'vagrant onie-build'
    GIT
  else
    # Propagate git config to vagrant guest
    gitconfig = Pathname.new("#{Dir.home}/.gitconfig")
    config.vm.provision :shell, :inline => "echo -e '#{gitconfig.read()}' > '/home/vagrant/.gitconfig'", privileged: false if gitconfig.exist?
  end

end
