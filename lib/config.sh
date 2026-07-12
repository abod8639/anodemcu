#!/bin/bash

# Arduino CLI Manager - Configuration Module
# This file contains all configuration variables and constants

# --- Version ---
VERSION="3.0.0"

# --- Default Configuration ---
DEFAULT_FQBN="esp32:esp32:esp32"
DEFAULT_PORT="/dev/ttyACM1"
DEFAULT_BAUD="115200"
DEFAULT_PROJECT="Not Selected"

# --- Directories ---
SKETCH_DIR="$HOME/Arduino"
CONFIG_FILE="$HOME/.anodemcu.conf"
HISTORY_FILE="$HOME/.anodemcu.history"
BACKUP_DIR="$HOME/.anodemcu/backups"
LOG_DIR="$HOME/.anodemcu/logs"
LOG_FILE="$LOG_DIR/anodemcu.log"

# --- Colors ---
C_RESET='\033[0m'
C_RED='\033[38;2;243;139;168m'      # Catppuccin Red
C_GREEN='\033[38;2;166;227;161m'    # Catppuccin Green
C_YELLOW='\033[38;2;249;226;175m'   # Catppuccin Yellow
C_BLUE='\033[38;2;137;180;250m'     # Catppuccin Blue
C_PURPLE='\033[38;2;203;166;247m'   # Catppuccin Mauve
C_CYAN='\033[38;2;137;220;235m'     # Catppuccin Sky
C_LOGO='\033[38;2;203;166;247m'     # Catppuccin Mauve
C_SHORTCUT='\033[38;2;180;190;254m' # Catppuccin Lavender

# --- State Variables ---
FQBN=""
PORT=""
BAUD=""
PROJECT=""
LATEST_VERSION=""
