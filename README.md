# virt-up

A small script automate booting a set of virtual machines with an attached
cloud-init image.

# Requirements

- libvirt
- genisoimage
- qemu-imag
- a qcow base image to boot

# Usage

1. Edit `cloud-init/meta-data` and `cloud-init/user-data` as desired.
2. Create a symbolic link from `base.qcow2` to your distributions cloud/nocloud
   qcow2 image.
3. Launch the VMs with:
  - `./virt-up.sh --named app db ingress` for "named" instances. `libvirt`
    should automatically make these machines available by the names given (so
    `ping app` should work). You can also use `-w` (w for "words").
  - `./virt-up.sh --number 3` to launch 3 machines with randomised
    alpha-numeric names.
4. Wait for the machines to spin up, it can take some time for the network
   interfaces to come online.
5. Press enter to automatically tear down and delete the VMs.

# Trouble shooting

Make sure you've started libvirt and the default network before use:

```
sudo systemctl start libvirtd
sudo virsh net-start default
```
