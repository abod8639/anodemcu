#!/bin/bash
# DEPRECATED: This script has been renamed to anodemcu.
# Forwarding to the new script...
echo -e "\033[0;33m[Warning] arduino-cli-manager.sh is deprecated. Please use anodemcu instead.\033[0m" >&2
exec "$(dirname "$0")/anodemcu" "$@"
