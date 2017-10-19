#!/bin/bash -eux

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

ruby hostswitcher.rb
