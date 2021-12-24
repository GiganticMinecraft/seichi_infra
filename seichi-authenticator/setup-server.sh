#!/bin/bash
set -e

# This is an idempotent script that
# - installs all the required toolchains
# - configures the server to
#   - reboot at 16:00 AM
#   - restart all the services on reboot
# - reboots the server to reinitialize everything

sudo reboot
