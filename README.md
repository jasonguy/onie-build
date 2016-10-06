# onie-build
Vagrant guest which creates the proper build environment to enable users build ONIE images.


## Installation
This vagrantfile supports the libvirt/kvm and virtualbox providers.

This assumes you have already set up your host for vagrant.

Simply clone this repo, and run 'vagrant up'.

## Quick Start

This vagrant guest is based on the official Debian Jessie 64-bit box. 

To support building onie images, it automatically creates and mounts a second (60GB), due 
to the space requirements for the compiled dependencies.

It proceeds to clone the git repository for onie, sets up the build environment in the /data/onie
directory. 

Included is a small utility 'oniehelp' to display the 'make' commands from all available machines. 
