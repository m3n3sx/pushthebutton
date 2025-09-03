#!/bin/bash

# Fedora System Backup Tool - Build Script
# Simple script for building the application during development

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Fedora System Backup Tool - Build Script${NC}"
echo ""

# Check if meson is available
if ! command -v meson &> /dev/null; then
    echo -e "${RED}Error: meson is not installed${NC}"
    echo "Install with: sudo dnf install meson ninja-build"
    exit 1
fi

# Check if ninja is available
if ! command -v ninja &> /dev/null; then
    echo -e "${RED}Error: ninja is not installed${NC}"
    echo "Install with: sudo dnf install ninja-build"
    exit 1
fi

# Check if valac is available
if ! command -v valac &> /dev/null; then
    echo -e "${RED}Error: valac is not installed${NC}"
    echo "Install with: sudo dnf install vala"
    exit 1
fi

echo -e "${GREEN}All build tools are available${NC}"
echo ""

# Setup build directory if it doesn't exist
if [[ ! -d "builddir" ]]; then
    echo -e "${YELLOW}Setting up build directory...${NC}"
    meson setup builddir
    echo -e "${GREEN}Build directory created${NC}"
fi

# Compile the application
echo -e "${YELLOW}Compiling application...${NC}"
meson compile -C builddir

echo -e "${GREEN}Build completed successfully!${NC}"
echo ""
echo "You can now run the application with:"
echo "  ./builddir/fedora-backup-tool"
echo ""
echo "Or install it with:"
echo "  sudo meson install -C builddir"
