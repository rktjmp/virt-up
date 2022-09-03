#!/usr/bin/bash
#
# Generates a cloud vm with a random id, then destroys it when
# execution continues.
#

cidata_image_name() {
  echo "vms/$1-cidata.iso"
}

vm_disk_image_name() {
  echo "vms/$1-disk.img"
}

build_images() {
  vm_disk_image=$1
  cidata_image=$2
  cidata_path=$3

  genisoimage -output $cidata_image \
    -volid cidata -joliet -rock \
    $cidata_path/user-data $cidata_path/meta-data

  qemu-img create \
    -f qcow2 \
    -b $(pwd)/base.qcow2 \
    -F qcow2 \
    $(pwd)/$vm_disk_image 10G
}

install_vm() {
  vm_name=$1
  vm_disk_image=$2
  ci_data_image=$3
  autoconsole=$4

  virt-install --name=$vm_name \
    --ram=1024 --vcpus=1 \
    --import \
    --disk path=$vm_disk_image,format=qcow2 \
    --disk path=$ci_data_image \
    --os-variant=debian11 \
    --network bridge=virbr0,model=virtio \
    --qemu-commandline="-smbios type=1,serial=ds=nocloud;h=$vm_name" \
    --autoconsole $autoconsole
}

# we want a list of id's (for unique files) and names (for dns/hostnames)
vm_ids=""
vm_names=""

case "$1" in
  "-w" | "--named")
    shift
    for i in $*; do
      # "unique enough"
      uuid=$(uuidgen | cut -c 1-8)
      name=$i
      vm_id="$name-$uuid"
      vm_names="${vm_names} $name"
      vm_ids="${vm_ids} $vm_id"
    done
    ;;
  "-n" | "--number")
    shift
    for i in $(seq $1); do
      # "unique enough"
      uuid=$(uuidgen | cut -c 1-4)
      name=$uuid
      vm_id="$uuid"
      vm_names="${vm_names} $name"
      vm_ids="${vm_ids} $vm_id"
    done
    ;;
  *)
    echo "Spawn N vms:     ${0} --number N"
    echo "                 ${0} -n N"
    echo "Spawn named vms: ${0} --named app_1 app_2 bastion"
    echo "                 ${0} -w app_1 app_2 bastion"
    echo ""
    echo "Keep your names simple, alpha-numeric with - or _."
    exit 0;;
esac

vm_ids_list=($vm_ids)
vm_names_list=($vm_names)

# boot the vms with associated images and hostname
count=${#vm_ids_list[@]}
for i in $(seq 1 $count); do
  vm_id=${vm_ids_list[$i-1]}
  vm_name=${vm_names_list[$i-1]}

  cidata_path="cloud-init"
  cidata_image=$(cidata_image_name $vm_id)
  vm_disk_image=$(vm_disk_image_name $vm_id)

  build_images "$vm_disk_image" "$cidata_image" "$cidata_path"
  install_vm "$vm_name" "$vm_disk_image" "$cidata_image" "none"
done

echo ""
echo "Probably created the following VMs:"
echo ""
for i in $(seq 1 $count); do
  vm_name=${vm_names_list[$i-1]}
  echo "  $vm_name"
done
echo ""
echo "(It may take a moment for their NICs to come up.)"
echo ""

read -r -p "Press return to destroy all..." key

for i in $(seq 1 $count); do
  vm_id=${vm_ids_list[$i-1]}
  vm_name=${vm_names_list[$i-1]}

  cidata_image=$(cidata_image_name $vm_id)
  vm_disk_image=$(vm_disk_image_name $vm_id)

  virsh destroy $vm_name && virsh undefine $vm_name
  rm $cidata_image
  rm $vm_disk_image
done
