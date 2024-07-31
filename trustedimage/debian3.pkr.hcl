# Copyright 2024 Signal Messenger, LLC
# SPDX-License-Identifier: AGPL-3.0-only

# This builder currently does nothing, but it allows us to test that
# the disk image we created in 'debian2' (now in the 'build2' directory)
# is functioning as expected.

packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

source "qemu" "debian3" {
  format       = "raw"
  headless     = "false"
  communicator = "ssh"
  disk_size    = "3G"
  memory       = 4096

  # Boot in UEFI, and use default vars again to make sure we can be
  # found without modifying UEFI vars.  This does require us to do
  # the MSFT UEFI 'bcfg' magic again in `boot_steps`.
  efi_boot          = "true"
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.ms.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.ms.fd"
  machine_type      = "q35"

  accelerator      = "kvm"
  disk_interface   = "virtio"
  net_device       = "virtio-net"
  output_directory = "build/debian3.out"
  shutdown_command = "sudo halt"
  vm_name          = "disk.raw"

  # TODO: eventually shut off SSH entirely.
  ssh_timeout          = "15m"
  ssh_username         = "svr3"
  ssh_private_key_file = "/home/gram/.ssh/id_rsa"

  # Use the additional disk created by 'debian2'.
  iso_url      = "build/debian2.out/disk.raw-1"
  iso_checksum = "none"
  disk_image   = true

}

build {
  sources = ["source.qemu.debian3"]

  provisioner "shell" {
    # Make sure we can run commands as root, then sleep for a long time
    # so that the user can log in via the console and poke around to make
    # sure everything is working as intended.
    inline = [
      "sudo echo 'Boot and sudo successful'",
      "mkfifo /tmp/wait", "echo \"#!/bin/bash\necho done > /tmp/wait\n\" > ./done.sh",
      "chmod u+x ./done.sh",
      "echo 'Log in with user/pwd \"svr3:svr3\", then run the \"./done.sh\" script after confirming that things look good",
      "cat /tmp/wait"
    ]
  }
}
