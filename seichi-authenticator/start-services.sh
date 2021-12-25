#!/bin/bash
set -e

# region configure next reboot

timedatectl set-timezone Asia/Tokyo
echo 'reboot' | at 4:00

# endregion
